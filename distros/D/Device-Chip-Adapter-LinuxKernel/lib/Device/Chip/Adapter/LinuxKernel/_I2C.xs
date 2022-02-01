#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <unistd.h>
#include <fcntl.h>
#include <linux/i2c.h>
#include <linux/i2c-dev.h>

MODULE = Device::Chip::Adapter::LinuxKernel::_I2C		PACKAGE = Device::Chip::Adapter::LinuxKernel::_I2C

unsigned long
_i2cdev_get_funcs(fd)
    int fd
  CODE:
    unsigned long funcs;
    ioctl(fd, I2C_FUNCS, &funcs);
    RETVAL = funcs;
  OUTPUT:
    RETVAL

SV*
_i2cdev_read(fd, addr, rxlen)
    int fd
    int addr
    int rxlen
  CODE:
    // make a buffer for the data to receive
    unsigned char *rxdata_buf = malloc(rxlen);
    int ret;

    // populate the i2c message structure
    struct i2c_rdwr_ioctl_data rdwr_data;
    struct i2c_msg rx_msg;

    rx_msg.addr = addr;
    rx_msg.flags = I2C_M_RD;
    rx_msg.len = (uint16_t)rxlen;
    rx_msg.buf = rxdata_buf;

    rdwr_data.msgs = &rx_msg;
    rdwr_data.nmsgs = 1;

    // run the i2c transaction
    ret = ioctl(fd, I2C_RDWR, &rdwr_data);

    if (ret < 1)
        RETVAL = &PL_sv_undef;
    else
        // put the received data in a scalar and return it
        RETVAL = newSVpvn(rxdata_buf, rxlen);
    free(rxdata_buf);
  OUTPUT:
    RETVAL

int _i2cdev_write(fd, addr, txdata)
    int fd
    int addr
    SV* txdata
  CODE:
    // get the data to transmit
    STRLEN txlen;
    unsigned char *txdata_buf = SvPVbyte(txdata, txlen);

    // populate the i2c message structure
    struct i2c_rdwr_ioctl_data rdwr_data;
    struct i2c_msg tx_msg;

    tx_msg.addr = addr;
    tx_msg.flags = 0;
    tx_msg.len = (uint16_t)txlen;
    tx_msg.buf = txdata_buf;

    rdwr_data.msgs = &tx_msg;
    rdwr_data.nmsgs = 1;

    // run the i2c transaction
    RETVAL = ioctl(fd, I2C_RDWR, &rdwr_data);

  OUTPUT:
    RETVAL

SV* _i2cdev_write_read(fd, addr, txdata, rxlen)
    int fd
    int addr
    SV* txdata
    int rxlen
  CODE:
    // get the data to transmit
    STRLEN txlen;
    unsigned char *txdata_buf = SvPVbyte(txdata, txlen);
    // make a buffer for the received data
    unsigned char *rxdata_buf = malloc(rxlen);
    int ret;

    // populate the i2c message structure
    struct i2c_rdwr_ioctl_data rdwr_data;
    struct i2c_msg msgs[2];

    // first message for the transmitted data
    msgs[0].addr = addr;
    msgs[0].flags = 0;
    msgs[0].len = txlen;
    msgs[0].buf = txdata_buf;

   // second message for receive data
    msgs[1].addr = addr;
    msgs[1].flags = I2C_M_RD;
    msgs[1].len = rxlen;
    msgs[1].buf = rxdata_buf;

    rdwr_data.msgs = msgs;
    rdwr_data.nmsgs = 2;

    // get the data to transmit
    ret = ioctl(fd, I2C_RDWR, &rdwr_data);

    // check for error
    if (ret < 2)
        RETVAL = &PL_sv_undef;
    else
        RETVAL = newSVpvn(rxdata_buf, rxlen);

    // clean up
    free(rxdata_buf);
  OUTPUT:
    RETVAL
