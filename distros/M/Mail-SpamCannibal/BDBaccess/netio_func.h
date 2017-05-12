/* netio_func.h	*/
int write_msg(int fd, u_char * bptr, size_t n);
int writen(int fd, u_char * bptr, size_t n);
int read_msg(int fd);
int init_socket();
int accept_client(int fd);
