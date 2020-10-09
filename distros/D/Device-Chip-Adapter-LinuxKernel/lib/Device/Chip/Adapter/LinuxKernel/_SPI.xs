#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <unistd.h>
#include <fcntl.h>
#include <linux/spi/spidev.h>
#include <stdio.h>

MODULE = Device::Chip::Adapter::LinuxKernel::_SPI		PACKAGE = Device::Chip::Adapter::LinuxKernel::_SPI

int
_spidev_open(devnode)
    char *devnode
  CODE:
    int fd = open(devnode, O_RDWR);
    if (fd < 0)
      RETVAL = -1;
    else
      RETVAL = fd;
  OUTPUT:
    RETVAL

void
_spidev_close(fd)
    int fd
  CODE:
    close(fd);

void
_spidev_set_mode(fd, mode)
    int fd
    int mode
  CODE:
    ioctl(fd, SPI_IOC_WR_MODE, &mode);

void
_spidev_set_speed(fd, speed)
    int fd
    int speed
  CODE:
    ioctl(fd, SPI_IOC_WR_MAX_SPEED_HZ, &speed);

SV*
_spidev_transfer(fd, txdata)
    int fd
    SV *txdata
  CODE:
    STRLEN txlen;
    unsigned char *txdata_buf = SvPVbyte(txdata, txlen);
    unsigned char *rxdata = malloc(txlen);
    struct spi_ioc_transfer xfer = {
        .tx_buf = (unsigned long)txdata_buf,
        .rx_buf = (unsigned long)rxdata,
        .len = txlen };
    int ret = ioctl(fd, SPI_IOC_MESSAGE(1), &xfer);
    if (ret < 1)
        RETVAL = &PL_sv_undef;
    else
        RETVAL = newSVpvn(rxdata, txlen);
    free(rxdata);
  OUTPUT:
    RETVAL
