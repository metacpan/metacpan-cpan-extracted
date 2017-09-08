#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <vxi11.h>

#include "const-c.inc"

typedef CLIENT *Lab__VXI11;

static void
do_not_warn_unused(void *x __attribute__((__unused__)))
{
}

static void
set_clnt_timeout(CLIENT *client, u_long timeout)
{
    struct timeval tv;
    tv.tv_sec = timeout / 1000;
    tv.tv_usec = (timeout % 1000) * 1000;
    clnt_control(client, CLSET_TIMEOUT, (char *) &tv);
}

static void
check_resp(CLIENT *client, void *resp)
{
    if (resp == NULL) {
            struct rpc_err err;
            clnt_geterr(client, &err);
            char *msg = clnt_sperrno(err.re_status);
            croak("RPC client failure: %s", msg);
    }
}


MODULE = Lab::VXI11		PACKAGE = Lab::VXI11		

INCLUDE: const-xs.inc

Lab::VXI11
new(char *class, char *host, unsigned long prog, unsigned long vers, char *proto)
CODE:
    do_not_warn_unused(class);
    RETVAL = clnt_create(host, prog, vers, proto);
    if (RETVAL == NULL)
        clnt_pcreateerror("Failed to create RPC client:");
OUTPUT:
    RETVAL


void
DESTROY(Lab::VXI11 client)
CODE:
    clnt_destroy(client);


void
create_link(Lab::VXI11 client, long clientId, bool_t lockDevice, u_long lock_timeout, char *device)
PPCODE:
    Create_LinkParms link_parms = {clientId, lockDevice, lock_timeout, device};
    
    Create_LinkResp *link_resp;
    link_resp = create_link_1(&link_parms, client);
    check_resp(client, link_resp);
    mXPUSHi(link_resp->error);
    mXPUSHi(link_resp->lid);
    mXPUSHu(link_resp->abortPort);
    mXPUSHu(link_resp->maxRecvSize);



void
device_write(Lab::VXI11 client, Device_Link lid, u_long io_timeout, u_long lock_timeout, Device_Flags flags, SV *data)
PPCODE:
    const char *bytes;
    STRLEN len;
    bytes = SvPV(data, len);
    Device_WriteParms write_parms = {lid, io_timeout, lock_timeout, flags, {len, (char *) bytes}};

    Device_WriteResp *write_resp;
    set_clnt_timeout(client, io_timeout);
    write_resp = device_write_1(&write_parms, client);
    check_resp(client, write_resp);
    mXPUSHi(write_resp->error);
    mXPUSHu(write_resp->size);


void
device_read(Lab::VXI11 client, Device_Link lid, u_long requestSize, u_long io_timeout, u_long lock_timeout, Device_Flags flags, char termChar)
PPCODE:
    Device_ReadParms read_parms = {lid, requestSize, io_timeout, lock_timeout, flags, termChar};

    Device_ReadResp *read_resp;
    set_clnt_timeout(client, io_timeout);
    read_resp = device_read_1(&read_parms, client);
    check_resp(client, read_resp);
    mXPUSHi(read_resp->error);
    mXPUSHi(read_resp->reason);
    mXPUSHp(read_resp->data.data_val, read_resp->data.data_len);
    
    

   
void
device_readstb(Lab::VXI11 client, Device_Link lid, Device_Flags flags, u_long lock_timeout, u_long io_timeout)
PPCODE:
    Device_GenericParms parms = {lid, flags, lock_timeout, io_timeout};
    Device_ReadStbResp *resp;
    set_clnt_timeout(client, io_timeout);
    resp = device_readstb_1(&parms, client);
    check_resp(client, resp);
    mXPUSHi(resp->error);
    mXPUSHu(resp->stb);


void
device_trigger(Lab::VXI11 client, Device_Link lid, Device_Flags flags, u_long lock_timeout, u_long io_timeout)
PPCODE:
    Device_GenericParms parms = {lid, flags, lock_timeout, io_timeout};
    Device_Error *resp;
    set_clnt_timeout(client, io_timeout);
    resp = device_trigger_1(&parms, client);
    check_resp(client, resp);
    mXPUSHi(resp->error);


void
device_clear(Lab::VXI11 client, Device_Link lid, Device_Flags flags, u_long lock_timeout, u_long io_timeout)
PPCODE:
    Device_GenericParms parms = {lid, flags, lock_timeout, io_timeout};
    Device_Error *resp;
    set_clnt_timeout(client, io_timeout);
    resp = device_clear_1(&parms, client);
    check_resp(client, resp);
    mXPUSHi(resp->error);


void
device_remote(Lab::VXI11 client, Device_Link lid, Device_Flags flags, u_long lock_timeout, u_long io_timeout)
PPCODE:
    Device_GenericParms parms = {lid, flags, lock_timeout, io_timeout};
    Device_Error *resp;
    set_clnt_timeout(client, io_timeout);
    resp = device_remote_1(&parms, client);
    check_resp(client, resp);
    mXPUSHi(resp->error);



void
device_local(Lab::VXI11 client, Device_Link lid, Device_Flags flags, u_long lock_timeout, u_long io_timeout)
PPCODE:
    Device_GenericParms parms = {lid, flags, lock_timeout, io_timeout};
    Device_Error *resp;
    set_clnt_timeout(client, io_timeout);
    resp = device_local_1(&parms, client);
    check_resp(client, resp);
    mXPUSHi(resp->error);



void
device_lock(Lab::VXI11 client, Device_Link lid, Device_Flags flags, u_long lock_timeout)
PPCODE:
    Device_LockParms parms = {lid, flags, lock_timeout};
    Device_Error *resp;
    resp = device_lock_1(&parms, client);
    check_resp(client, resp);
    mXPUSHi(resp->error);



void
device_unlock(Lab::VXI11 client, Device_Link lid)
PPCODE:
    Device_Error *resp;
    resp = device_unlock_1(&lid, client);
    check_resp(client, resp);
    mXPUSHi(resp->error);  



void
device_enable_srq(Lab::VXI11 client, Device_Link lid, bool_t enable, SV *handle)
PPCODE:
    const char *bytes;
    STRLEN len;
    bytes = SvPV(handle, len);
    Device_EnableSrqParms parms = {lid, enable, {len, (char *) bytes}};
    Device_Error *resp;
    resp = device_enable_srq_1(&parms, client);
    check_resp(client, resp);
    mXPUSHi(resp->error);



void
device_docmd(Lab::VXI11 client, Device_Link lid, Device_Flags flags, u_long io_timeout, u_long lock_timeout, long cmd, bool_t network_order, long datasize, SV *data_in)
PPCODE:
    const char *bytes;
    STRLEN len;
    bytes = SvPV(data_in, len);
    Device_DocmdParms parms = {lid, flags, io_timeout, lock_timeout, cmd, network_order, datasize, {len, (char *) bytes}};
    Device_DocmdResp *resp;
    set_clnt_timeout(client, io_timeout);
    resp = device_docmd_1(&parms, client);
    check_resp(client, resp);
    mXPUSHi(resp->error);
    mXPUSHp(resp->data_out.data_out_val, resp->data_out.data_out_len);



void
destroy_link(Lab::VXI11 client, Device_Link lid)
PPCODE:
    Device_Error *resp;
    resp = destroy_link_1(&lid, client);
    check_resp(client, resp);
    mXPUSHi(resp->error);


void
create_intr_chan(Lab::VXI11 client, u_long hostAddr, u_short hostPort, u_long progNum, u_long progVers, Device_AddrFamily progFamily)
PPCODE:
    Device_RemoteFunc parms = {hostAddr, hostPort, progNum, progVers, progFamily};
    Device_Error *resp;
    resp = create_intr_chan_1(&parms, client);
    check_resp(client, resp);
    mXPUSHi(resp->error);


void
destroy_intr_chan(Lab::VXI11 client);
PPCODE:
    Device_Error *resp;
    resp = destroy_intr_chan_1(NULL, client);
    check_resp(client, resp);
    mXPUSHi(resp->error);