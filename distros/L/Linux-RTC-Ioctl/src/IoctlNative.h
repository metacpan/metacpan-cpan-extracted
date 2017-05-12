#ifndef LINUX_RTC_IOCTL_NATIVE
# define LINUX_RTC_IOCTL_NATIVE

extern int (*linux_rtc_native_ioctl)(int fd, unsigned long reqest, ...);
extern ssize_t (*linux_rtc_native_read)(int fd, void *buffer, size_t size);

#endif
