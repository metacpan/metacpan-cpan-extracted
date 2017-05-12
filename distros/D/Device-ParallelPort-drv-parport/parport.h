
/* Simple interface routines to read/write PC parallel port */

extern int parport_opendev(char *device);
extern void parport_closedev(int base);

extern int parport_rd_data(int base);
extern void parport_wr_data(int base, int val);

extern int parport_rd_ctrl(int base);
extern void parport_wr_ctrl(int base, int val);
extern int parport_rd_status(int base);
