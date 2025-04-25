/* File descriptor passing based on
 *   https://manned.org/man.c2c6968a/cmsg.3 */

static ssize_t fufdpass_send(int socket, int fd, const char *buf, size_t buflen) {
    union {
        char buf[CMSG_SPACE(sizeof(int))];
        struct cmsghdr align;
    } cmsgbuf = {};

    struct iovec iov;
    iov.iov_base = (char *)buf;
    iov.iov_len = buflen;

    struct msghdr msg;
    msg.msg_name = NULL;
    msg.msg_namelen = 0;
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;
    msg.msg_control = cmsgbuf.buf;
    msg.msg_controllen = sizeof(cmsgbuf.buf);
    msg.msg_flags = 0;

    struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
    cmsg->cmsg_level = SOL_SOCKET;
    cmsg->cmsg_type = SCM_RIGHTS;
    cmsg->cmsg_len = CMSG_LEN(sizeof(int));
    memcpy(CMSG_DATA(cmsg), &fd, sizeof(int));

    return sendmsg(socket, &msg, 0);
}

static int fufdpass_recv(pTHX_ I32 ax, int socket, size_t len) {
    if (GIMME_V != G_LIST)
        fu_confess("Invalid use of fdpass_recv() in scalar context");

    union {
        char buf[CMSG_SPACE(sizeof(int))];
        struct cmsghdr align;
    } cmsgbuf;

    SV *buf = sv_2mortal(newSV(len));
    SvPOK_only(buf);
    struct iovec iov;
    iov.iov_base = SvPVX(buf);
    iov.iov_len = len;

    struct msghdr msg;
    msg.msg_name = NULL;
    msg.msg_namelen = 0;
    msg.msg_iov = &iov;
    msg.msg_iovlen = 1;
    msg.msg_control = cmsgbuf.buf;
    msg.msg_controllen = sizeof(cmsgbuf.buf);
    msg.msg_flags = 0;

    ssize_t r = recvmsg(socket, &msg, MSG_CMSG_CLOEXEC);
    if (r < 0) {
        ST(0) = &PL_sv_undef;
        ST(1) = &PL_sv_undef;
        return 2;
    }

    struct cmsghdr *cmsg = CMSG_FIRSTHDR(&msg);
    if (cmsg == NULL || cmsg->cmsg_level != SOL_SOCKET
            || cmsg->cmsg_type != SCM_RIGHTS || cmsg->cmsg_len != CMSG_LEN(sizeof(int))) {
        ST(0) = &PL_sv_undef;
    } else {
        int fd;
        memcpy(&fd, CMSG_DATA(cmsg), sizeof(int));
        ST(0) = sv_2mortal(newSViv(fd));
    }

    SvCUR_set(buf, r);
    SvPVX(buf)[r] = 0;
    ST(1) = buf;
    return 2;
}
