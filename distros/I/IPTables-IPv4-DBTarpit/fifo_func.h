/* fifo_func.h	*/
int make_fifo(char * fifo_path);
int open_fifo(int * fd, char * fifo_path);
int write_fifo(int fd, char * message);
