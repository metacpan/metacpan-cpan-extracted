
/* Simple interface routines to read/write PC parallel port */

int linux_opendev(char *device);

extern int linux_read(int base, int offset);
extern void linux_write(int base, int offset, int val);

