
int my_send_fd(int clifd, int fd);
int my_recv_fd(int servfd);
int my_serv_accept(int listenfd, uid_t *uidptr);
int my_bind_to_fs(int fd,const char *name);
