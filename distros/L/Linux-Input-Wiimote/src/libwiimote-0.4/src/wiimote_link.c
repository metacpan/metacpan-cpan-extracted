/* $Id: wiimote_link.c 31 2007-02-07 23:51:07Z bja $ 
 *
 * Copyright (C) 2007, Joel Andersson <bja@kth.se>
 * Copyright (C) 2007, Krishna Gadepalli
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <bluetooth/bluetooth.h>
#include <bluetooth/l2cap.h>
#include <bluetooth/hci.h>
#include <bluetooth/hci_lib.h>
#include <arpa/inet.h>
#include <errno.h>
#include <limits.h>
#include <fcntl.h>
#include <sys/ioctl.h>

#include "bthid.h"
#include "wiimote.h"
#include "wiimote_report.h"
#include "wiimote_error.h"
#include "wiimote_io.h"

#define WIIMOTE_NAME    "Nintendo RVL-CNT-01"
#define WIIMOTE_CMP_LEN sizeof(WIIMOTE_NAME)

/*
 * Wiimote magic numbers used for identifying
 * controllers during inquiry.
 */
static uint8_t WIIMOTE_DEV_CLASS[] = { 0x04, 0x25, 0x00 };

static int l2cap_connect(wiimote_t *wiimote, uint16_t psm)
{
    struct sockaddr_l2 addr = { 0 };
    int sock = 0;

    sock = socket(AF_BLUETOOTH, SOCK_SEQPACKET, BTPROTO_L2CAP);
    if (!sock) {
	wiimote_error("l2cap_connect(): socket");
	return WIIMOTE_ERROR;
    }

    addr.l2_family = AF_BLUETOOTH;
    str2ba(wiimote->link.l_addr, &addr.l2_bdaddr);

    if (bind(sock, (struct sockaddr *) &addr, sizeof(addr)) < 0) {
	wiimote_error("l2cap_connect(): bind");
	return WIIMOTE_ERROR;
    }

    memset(&addr, 0, sizeof(addr));
    addr.l2_family = AF_BLUETOOTH;
    addr.l2_psm = htobs(psm);
    str2ba(wiimote->link.r_addr, &addr.l2_bdaddr);

    if (connect(sock, (struct sockaddr *)&addr, sizeof (addr)) < 0) {
	wiimote_error("l2cap_connect(): connect");
	return WIIMOTE_ERROR;
    }

    return sock;
}

static void wiimote_calibrate(wiimote_t *wiimote)
{
    uint8_t buf[16];
    memset(buf,0,16);
    wiimote_read(wiimote, 0x20, buf, 16);
    memcpy(&wiimote->cal, buf, sizeof (wiimote_cal_t));
}

static int is_wiimote(int hci_sock, inquiry_info *dev)
{
    char dev_name[WIIMOTE_CMP_LEN];

    if (memcmp(dev->dev_class, WIIMOTE_DEV_CLASS, sizeof (WIIMOTE_DEV_CLASS))) {
	return 0;
    }

    if (hci_remote_name(hci_sock, &dev->bdaddr, WIIMOTE_CMP_LEN, dev_name, 5000)) {
	wiimote_error("is_wiimote(): Error reading device name: %m");
	return 0;
    }

    if (strncmp(dev_name, WIIMOTE_NAME, WIIMOTE_CMP_LEN)) {
	return 0;
    }

    return 1;
}

int wiimote_discover(wiimote_t *devices, uint8_t size)
{
    int dev_id, hci, dev_count;
    int i, numdevices = 0;
    inquiry_info *dev_list = NULL;

    if (size <= 0) {
        wiimote_error("wiimote_discover(): less than 0 devices specified");
        return WIIMOTE_ERROR;
    }

    if (devices == NULL) {
        wiimote_error("wiimote_discover(): Error allocating devices");
        return WIIMOTE_ERROR;
    }

    if ((dev_id = hci_get_route(NULL)) < 0) {
        wiimote_error("wiimote_discover(): no bluetooth devices found: %m");
        return WIIMOTE_ERROR;
    }
    
    /* Get device list. */

    if ((dev_count = hci_inquiry(dev_id, 2, 256, NULL, &dev_list, IREQ_CACHE_FLUSH)) < 0) {
        wiimote_error("wiimote_discover(): Error on device inquiry: %m");
        return WIIMOTE_ERROR;
    }

    if ((hci = hci_open_dev(dev_id)) < 0) {
        wiimote_error("wiimote_discover(): Error opening Bluetooth device: %m");
        return WIIMOTE_ERROR;
    }

    /* Check class and name for Wiimotes. */

    for (i=0; i<dev_count; i++) {
	inquiry_info *dev = &dev_list[i];
	if (is_wiimote(hci, dev)) {
	    ba2str(&dev->bdaddr, devices[numdevices].link.r_addr);
	    numdevices++;
	}
    }

    hci_close_dev(hci);

    if (dev_list) {
        free(dev_list);
    }

    if (numdevices <= 0) {
        wiimote_error("wiimote_discover(): No wiimotes found");
        return WIIMOTE_ERROR;
    }

    return numdevices;
}

static int wiimote_device_rank(int hci_sock, int dev_id)
{
    struct hci_conn_list_req *cl;
    struct hci_conn_info *ci;

    if (!(cl = alloca(10 * sizeof(*ci) + sizeof(*cl)))) {
	wiimote_error("conn_count(): alloca: %m");
	return WIIMOTE_ERROR;
    }

    cl->dev_id = dev_id;
    cl->conn_num = 10;
    ci = cl->conn_info;

    if (ioctl(hci_sock, HCIGETCONNLIST, (void*) cl)) {
	wiimote_error("conn_count(): conn_count: %m");
	return WIIMOTE_ERROR;
    }

    if (cl->conn_num == 0) {
	return 0;
    }

    if ((ci->link_mode & HCI_LM_MASTER) == 0) {
	return cl->conn_num;
    }

    return cl->conn_num + 100; 
}

static int wiimote_select_device(wiimote_t *wiimote)
{
    struct hci_dev_list_req *dl;
    struct hci_dev_req *dr;
    int dev_id = -1;
    int i, hci_sock, min_rank;

    hci_sock = socket(AF_BLUETOOTH, SOCK_RAW, BTPROTO_HCI);
    if (hci_sock < 0) {
	wiimote_error("wiimote_select_device(): socket: %m");
	return WIIMOTE_ERROR;
    }

    dl = alloca(HCI_MAX_DEV * sizeof(*dr) + sizeof(*dl));
    if (!dl) {
	wiimote_error("wiimote_select_device(): malloc: %m");
	close(hci_sock);
	return WIIMOTE_ERROR;
    }

    dl->dev_num = HCI_MAX_DEV;
    dr = dl->dev_req;

    if (ioctl(hci_sock, HCIGETDEVLIST, (void *) dl) < 0) {
	wiimote_error("wiimote_select_device(): ioctl: %m");
	close(hci_sock);
	return WIIMOTE_ERROR;
    }

    min_rank = INT_MAX;

    for (i=0; i<dl->dev_num; i++, dr++) {
	if (hci_test_bit(HCI_UP, &dr->dev_opt)) {

	    int rank = wiimote_device_rank(hci_sock, dr->dev_id);

	    //bdaddr_t bdaddr;
	    //hci_devba(dr->dev_id, &bdaddr);
	    //fprintf(stderr, "dev=%d bdaddr=%s rank=%d\n",
	    //	dr->dev_id, batostr(&bdaddr), rank);

	    if (rank == 0) {
		dev_id = dr->dev_id;
		break;
	    }

	    if (rank < min_rank) {
		dev_id = dr->dev_id;
		min_rank = rank;
	    }

	}
    }

    close(hci_sock);

    wiimote->link.device = dev_id + 1;

    return dev_id;
}

int wiimote_connect(wiimote_t *wiimote, const char *host)
{
    bdaddr_t l_addr;
    wiimote_report_t r = WIIMOTE_REPORT_INIT;
	
    if (wiimote->link.status == WIIMOTE_STATUS_CONNECTED) {
	wiimote_error("wiimote_connect(): already connected");
	return WIIMOTE_ERROR;
    }

    /* Note, that the device number in wiimote structure starts
       with 1 rather than 0 like bluez. */

    if (wiimote->link.device == 0) {
#ifdef _DISABLE_AUTO_SELECT_DEVICE
	wiimote->link.device = hci_get_route(BDADDR_ANY) + 1;
	if (wiimote->link.device < 0) {
	    wiimote_error("wiimote_connect(): hci_get_route: %m");
	    return WIIMOTE_ERROR;
	}

#else
	wiimote_select_device(wiimote);
#endif
    }

    /* Fill in the bluetooth address of the local and remote devices. */

    if (hci_devba(wiimote->link.device - 1, &l_addr) < 0) {
	wiimote_error("wiimote_connect(): devba: %m");
	return WIIMOTE_ERROR;
    }

    if (ba2str(&l_addr, wiimote->link.l_addr) < 0) {
	wiimote_error("wiimote_connect(): ba2str: %m");
	return WIIMOTE_ERROR;
    }

    if (!strncpy(wiimote->link.r_addr, host, 19)) {
	wiimote_error("wiimote_connect(): strncpy: %m");
	return WIIMOTE_ERROR;
    }

    /* According to the BT-HID specification, the control channel should
       be opened first followed by the interrupt channel. */

    wiimote->link.s_ctrl = l2cap_connect(wiimote, BTHID_PSM_CTRL);
    if (wiimote->link.s_ctrl < 0) {
	wiimote_error("wiimote_connect(): l2cap_connect");
	return WIIMOTE_ERROR;
    }

    wiimote->link.status = WIIMOTE_STATUS_UNDEFINED;
    wiimote->link.s_intr = l2cap_connect(wiimote, BTHID_PSM_INTR);
    if (wiimote->link.s_intr < 0) {
	wiimote_error("wiimote_connect(): l2cap_connect");
	return WIIMOTE_ERROR;
    }

    wiimote->link.status = WIIMOTE_STATUS_CONNECTED;
    wiimote->mode.bits = WIIMOTE_MODE_DEFAULT;
    wiimote->old.mode.bits = 0;

    wiimote_calibrate(wiimote);
	
    /* Prepare and send a status report request. This will initialize the
       nunchuk if it is plugged in as a side effect. */

    r.channel = WIIMOTE_RID_STATUS;
    if (wiimote_report(wiimote, &r, sizeof (r.status)) < 0) {
	wiimote_error("wiimote_connect(): status report request failed");
    }

    return WIIMOTE_OK;
}

int wiimote_disconnect(wiimote_t *wiimote)
{
    struct req_raw_out r = { 0 };
	
    if (wiimote->link.status != WIIMOTE_STATUS_CONNECTED) {
	wiimote_set_error("wiimote_disconnect(): not connected");
	return WIIMOTE_OK;
    }
	
    /* Send a VIRTUAL_CABLE_UNPLUG HID_CONTROL request to the remote device. */
	
    r.header = BTHID_TYPE_HID_CONTROL | BTHID_PARAM_VIRTUAL_CABLE_UNPLUG;	
    r.channel = 0x01;
	
    if (send(wiimote->link.s_ctrl, (uint8_t *) &r, 2, 0) < 0) {
	wiimote_error("wiimote_disconnect(): send: %m");
	return WIIMOTE_ERROR;
    }

    /* BT-HID specification says HID_CONTROL requests should not generate
       any HANDSHAKE responses, but it seems like the wiimote generates a
       ERR_FATAL handshake response on a VIRTUAL_CABLE_UNPLUG request. */

    if (recv(wiimote->link.s_ctrl, (uint8_t *) &r, 2, 0) < 0) {
	wiimote_error("wiimote_disconnect(): recv: %m");
	return WIIMOTE_ERROR;
    }
		
    if (close(wiimote->link.s_intr) < 0) {
	wiimote_error("wiimote_disconnect(): close: %m");
	return WIIMOTE_ERROR;
    }
    
    if (close(wiimote->link.s_ctrl) < 0) {
	wiimote_error("wiimote_disconnect(): close: %m");
	return WIIMOTE_ERROR;
    }
    
    wiimote->link.status = WIIMOTE_STATUS_DISCONNECTED;
    
    ba2str(BDADDR_ANY, wiimote->link.l_addr);
    ba2str(BDADDR_ANY, wiimote->link.r_addr);
    
    return WIIMOTE_OK;
}
