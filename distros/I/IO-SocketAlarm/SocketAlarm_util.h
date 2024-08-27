static int parse_signal(SV *name);
static int fileno_from_sv(SV *sv);
static int snprint_sockaddr(char *buffer, size_t buflen, struct sockaddr *addr);
static int snprint_fd_table(char *buf, size_t sizeof_buf, int max_fd);
static bool lazy_build_now_ts(struct timespec *now_ts);