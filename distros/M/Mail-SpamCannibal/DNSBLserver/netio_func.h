/* netio_func.h	*/
int writen(int fd, u_char * bptr, size_t n, int is_tcp);
int read_msg(int fd, int is_tcp);
int init_socket(int type);
int accept_tcp(int fd);
