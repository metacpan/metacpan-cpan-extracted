/*
 * Simple unit to save the native read and ioctl function pointers before Perl headers redefine the symbol names
 */
# include <unistd.h>
# include <sys/ioctl.h>
# include <linux/rtc.h>

#include "IoctlNative.h"

int (*linux_rtc_native_ioctl)(int fd, unsigned long reqest, ...) = ioctl;		    /* POSIX ioctl() */
ssize_t (*linux_rtc_native_read)(int fd, void *buffer, size_t size) = read;		    /* POSIX read() */
