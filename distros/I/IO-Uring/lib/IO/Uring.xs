#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <liburing.h>
#include <linux/wait.h>
#include <sys/mman.h>


typedef struct ring {
	struct io_uring uring;
} *IO__Uring;

static int uring_destroy(pTHX_ SV* sv, MAGIC* magic) {
	struct ring* self = (struct ring*)magic->mg_ptr;
	io_uring_queue_exit(&self->uring);
	safefree(self);
	return 0;
}

static const MGVTBL IO__Uring_magic = {
	.svt_free = uring_destroy,
};

static struct io_uring_sqe* S_get_sqe(pTHX_ struct ring* ring) {
	struct io_uring_sqe* sqe = io_uring_get_sqe(&ring->uring);

	if (!sqe) {
		io_uring_submit(&ring->uring);
		sqe = io_uring_get_sqe(&ring->uring);
		if (!sqe)
			Perl_croak(aTHX_ "Could not get SQE");
	}

	return sqe;
}
#define get_sqe(ring) S_get_sqe(aTHX_ ring)

typedef int FileDescriptor;
typedef int DirDescriptor;
typedef siginfo_t* Signal__Info;
typedef struct __kernel_timespec* Time__Spec;

typedef struct {
	const char* value;
	size_t length;
} op_entry;

static op_entry methods[] = {
	{ STR_WITH_LEN("nop") },
	{ STR_WITH_LEN("readv") },
	{ STR_WITH_LEN("writev") },
	{ STR_WITH_LEN("fsync") },
	{ STR_WITH_LEN("read_fixed") },
	{ STR_WITH_LEN("write_fixed") },
	{ STR_WITH_LEN("poll_add") },
	{ STR_WITH_LEN("poll_remove") },
	{ STR_WITH_LEN("sync_file_range") },
	{ STR_WITH_LEN("sendmsg") },
	{ STR_WITH_LEN("recvmsg") },
	{ STR_WITH_LEN("timeout") },
	{ STR_WITH_LEN("timeout_remove") },
	{ STR_WITH_LEN("accept") },
	{ STR_WITH_LEN("cancel") },
	{ STR_WITH_LEN("link_timeout") },
	{ STR_WITH_LEN("connect") },
	{ STR_WITH_LEN("fallocate") },
	{ STR_WITH_LEN("openat") },
	{ STR_WITH_LEN("close") },
	{ STR_WITH_LEN("files_update") },
	{ STR_WITH_LEN("statx") },
	{ STR_WITH_LEN("read") },
	{ STR_WITH_LEN("write") },
	{ STR_WITH_LEN("fadvise") },
	{ STR_WITH_LEN("madvise") },
	{ STR_WITH_LEN("send") },
	{ STR_WITH_LEN("recv") },
	{ STR_WITH_LEN("openat2") },
	{ STR_WITH_LEN("epoll_ctl") },
	{ STR_WITH_LEN("splice") },
	{ STR_WITH_LEN("provide_buffers") },
	{ STR_WITH_LEN("remove_buffers") },
	{ STR_WITH_LEN("tee") },
	{ STR_WITH_LEN("shutdown") },
	{ STR_WITH_LEN("renameat") },
	{ STR_WITH_LEN("unlinkat") },
	{ STR_WITH_LEN("mkdirat") },
	{ STR_WITH_LEN("symlinkat") },
	{ STR_WITH_LEN("linkat") },
	{ STR_WITH_LEN("msg_ring") },
	{ STR_WITH_LEN("fsetxattr") },
	{ STR_WITH_LEN("setxattr") },
	{ STR_WITH_LEN("fgetxattr") },
	{ STR_WITH_LEN("getxattr") },
	{ STR_WITH_LEN("socket") },
	{ STR_WITH_LEN("uring_cmd") },
	{ STR_WITH_LEN("send_zc") },
	{ STR_WITH_LEN("sendmsg_zc") },
	{ STR_WITH_LEN("read_multishot") },
	{ STR_WITH_LEN("waitid") },
	{ STR_WITH_LEN("futex_wait") },
	{ STR_WITH_LEN("futex_wake") },
	{ STR_WITH_LEN("futex_waitv") },
	{ STR_WITH_LEN("fixed_fd_install") },
	{ STR_WITH_LEN("ftruncate") },
	{ STR_WITH_LEN("bind") },
	{ STR_WITH_LEN("listen") },
	{ STR_WITH_LEN("recv_zc") },
	{ STR_WITH_LEN("epoll_wait") },
	{ STR_WITH_LEN("readv_fixed") },
	{ STR_WITH_LEN("writev_fixed") },
	{ STR_WITH_LEN("pipe") },
};

struct callback {
	SV* callback;
};

static void* S_set_callback(pTHX_ struct io_uring_sqe* sqe, SV* callback) {
	struct callback* callback_data = safecalloc(1, sizeof(struct callback));
	callback_data->callback = callback ? SvREFCNT_inc(callback) : NULL;
	io_uring_sqe_set_data(sqe, callback_data);
	return callback_data;
}
#define set_callback(sqe, callback) S_set_callback(aTHX_ sqe, callback)

typedef struct io_uring_buffergroup {
	struct ring* ring;
	struct io_uring_buf_ring* buf_ring;
	char *buffer_base;
	unsigned buffer_count;
	size_t buffer_size;
	size_t buf_ring_size;
	int id;
} *IO__Uring__BufferGroup;

static int buffergroup_free(pTHX_ SV* sv, MAGIC* magic) {
	struct io_uring_buffergroup* self = (struct io_uring_buffergroup*)magic->mg_ptr;
	int ret = io_uring_free_buf_ring(&self->ring->uring, self->buf_ring, self->buffer_count, self->id);
	if (ret < 0)
		warn("Could not remove buffer group %d", self->id);

	if (munmap(self->buf_ring, self->buf_ring_size) < 0)
		warn("Could not unmap buffer group");
	safefree(self);

	return 0;
}

static const MGVTBL IO__Uring__BufferGroup_magic = {
	.svt_free = buffergroup_free,
};

#define CLONE_SKIP(sv) 1

#undef SvPV
#define SvPV(sv, len) SvPVbyte(sv, len)
#undef SvPV_nolen
#define SvPV_nolen(sv) SvPVbyte_nolen(sv)

#define CONSTANT(cons) newCONSTSUB(stash, #cons, newSVuv(cons)); av_push(export_ok, newSVpvs(#cons))
#define URING_CONSTANT(cons) CONSTANT(IORING_##cons)
#define SQE_CONSTANT(cons) CONSTANT(IOSQE_##cons)

#define undef &PL_sv_undef

MODULE = IO::Uring				PACKAGE = IO::Uring

PROTOTYPES: DISABLE

TYPEMAP: <<END
	IO::Uring	T_MAGICEXT
	IO::Uring::BufferGroup	T_MAGICEXT
	Signal::Info	T_OPAQUEOBJ
	Time::Spec	T_OPAQUEOBJ
	FileDescriptor	T_FILE_DESCRIPTOR
	DirDescriptor T_DIR_DESCRIPTOR
	const struct sockaddr* T_PV

INPUT
T_FILE_DESCRIPTOR
	{
		PerlIO* ${var}_io = IoIFP(sv_2io($arg));
		$var = ${var}_io ? PerlIO_fileno(${var}_io) : -1;
	}
T_DIR_DESCRIPTOR
	if (SvOK($arg)) {
		IO* ${var}_io = sv_2io($arg);
		if (IoDIRP(${var}_io)) {
			$var = dirfd(IoDIRP(${var}_io));
		} else
			$var = -1;
	} else
		$var = AT_FDCWD;
END

BOOT:
	HV* stash = get_hv("IO::Uring::", FALSE);
	AV* export_ok = get_av("IO::Uring::EXPORT_OK", TRUE);

	URING_CONSTANT(CQE_F_MORE);
	URING_CONSTANT(CQE_F_SOCK_NONEMPTY);

	SQE_CONSTANT(ASYNC);
	SQE_CONSTANT(IO_LINK);
	SQE_CONSTANT(IO_HARDLINK);
	SQE_CONSTANT(IO_DRAIN);

	URING_CONSTANT(ASYNC_CANCEL_ALL);
	URING_CONSTANT(ASYNC_CANCEL_FD);
	URING_CONSTANT(ASYNC_CANCEL_ANY);

	URING_CONSTANT(FSYNC_DATASYNC);

	URING_CONSTANT(RECVSEND_POLL_FIRST);

	URING_CONSTANT(TIMEOUT_ABS);
	URING_CONSTANT(TIMEOUT_BOOTTIME);
	URING_CONSTANT(TIMEOUT_REALTIME);
	URING_CONSTANT(TIMEOUT_ETIME_SUCCESS);
	URING_CONSTANT(TIMEOUT_MULTISHOT);

	CONSTANT(RENAME_EXCHANGE);
	CONSTANT(RENAME_NOREPLACE);

	CONSTANT(AT_SYMLINK_FOLLOW);
	CONSTANT(AT_REMOVEDIR);

	URING_CONSTANT(POLL_UPDATE_EVENTS);
	URING_CONSTANT(POLL_UPDATE_USER_DATA);
	URING_CONSTANT(POLL_ADD_MULTI);

	CONSTANT(P_PID);
	CONSTANT(P_PGID);
	CONSTANT(P_PIDFD);
	CONSTANT(P_ALL);
	CONSTANT(WEXITED);
	CONSTANT(WSTOPPED);
	CONSTANT(WCONTINUED);
	CONSTANT(WNOWAIT);

IO::Uring new(class, UV entries, ...)
CODE:
	RETVAL = safecalloc(1, sizeof(struct ring));
	struct io_uring_params params = {};
	params.flags = IORING_SETUP_SINGLE_ISSUER | IORING_SETUP_COOP_TASKRUN | IORING_SETUP_DEFER_TASKRUN | IORING_SETUP_SUBMIT_ALL;
	for (int current = 2; current + 1 < items; items += 2) {
		STRLEN key_length;
		const char* key = SvPV(ST(current), key_length);
		if (key_length == 11 && strEQ(key, "cqe_entries")) {
			params.flags |= IORING_SETUP_CQSIZE;
			params.cq_entries = SvIV(ST(current+1));
		} else if (key_length == 6 && strEQ(key, "sqpoll")) {
			params.flags |= IORING_SETUP_SQPOLL;
			params.sq_thread_idle = SvIV(ST(current + 1));
		} else
			warn("Unknown named argument '%s'", key);
	}
	int ret = io_uring_queue_init_params(entries, &RETVAL->uring, &params);

	if (ret) {
		safefree(RETVAL);
		Perl_croak(aTHX_ "Could not create ring: %s", strerror(-ret));
	}
OUTPUT:
	RETVAL


IV CLONE_SKIP(sv)


void run_once(IO::Uring self, unsigned min_events = 1, Time::Spec timeout = NULL, sigset_t* sigmask = NULL)
PPCODE:
	struct io_uring_cqe *cqe;
	int result = io_uring_submit_and_wait_timeout(&self->uring, &cqe, min_events, timeout, sigmask);

	if (result == -1 && errno == EINTR)
		PERL_ASYNC_CHECK();

	unsigned head;

	ENTER;
	SAVETMPS;
	EXTEND(SP, 2);
	io_uring_for_each_cqe(&self->uring, head, cqe) {
		struct callback* callback_data = (struct callback*)io_uring_cqe_get_data(cqe);
		io_uring_cqe_seen(&self->uring, cqe);
		if (callback_data->callback) {
			PUSHMARK(SP);
			mPUSHi(cqe->res);
			mPUSHu(cqe->flags);
			PUTBACK;
			call_sv(callback_data->callback,  G_VOID);
			if (!(cqe->flags & IORING_CQE_F_MORE)) {
				SvREFCNT_dec(callback_data->callback);
				Safefree(callback_data);
			}
			SPAGAIN;
			FREETMPS;
		}
		else if (!(cqe->flags & IORING_CQE_F_MORE))
			Safefree(callback_data);
	}
	LEAVE;
	if (result >= 0)
		mPUSHi(result);
	else {
		errno = -result;
		PUSHs(&PL_sv_undef);
	}


SV* submit(IO::Uring self)
CODE:
	int result = io_uring_submit(&self->uring);
	if (result >= 0)
		RETVAL = newSViv(result);
	else {
		errno = -result;
		RETVAL = &PL_sv_undef;
	}
OUTPUT:
	RETVAL


SV* probe(IO::Uring self)
CODE:
	struct io_uring_probe* probe = io_uring_get_probe_ring(&self->uring);
	HV* operations = newHV();
    for (int i = 0; i < probe->ops_len; ++i) {
		int op = probe->ops[i].op;
		if (op >= sizeof methods / sizeof *methods)
			continue;
		SV* value = probe->ops[i].flags & IO_URING_OP_SUPPORTED ? &PL_sv_yes : &PL_sv_no;
		hv_store(operations, methods[i].value, methods[i].length, value, 0);
	}
	io_uring_free_probe(probe);
	RETVAL = newRV_noinc((SV*)operations);
OUTPUT:
	RETVAL


UV sq_space_left(IO::Uring ring)
CODE:
	RETVAL = io_uring_sq_space_left(&ring->uring);
OUTPUT:
	RETVAL


UV accept(IO::Uring self, FileDescriptor fd, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_accept(sqe, fd, NULL, NULL, SOCK_CLOEXEC);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV accept_multishot(IO::Uring self, FileDescriptor fd, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_multishot_accept(sqe, fd, NULL, NULL, SOCK_CLOEXEC);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV bind(IO::Uring self, FileDescriptor fd, const char* sockaddr, size_t length(sockaddr), UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_bind(sqe, fd, (struct sockaddr*)sockaddr, XSauto_length_of_sockaddr);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV cancel(IO::Uring self, UV user_data, UV flags, UV iflags, SV* callback = undef)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_cancel(sqe, NUM2PTR(void*, user_data), flags);
	io_uring_sqe_set_flags(sqe, iflags);
	void* cancel_data = set_callback(sqe, SvOK(callback) ? callback : NULL);
	RETVAL = PTR2UV(cancel_data);
OUTPUT:
	RETVAL


UV connect(IO::Uring self, FileDescriptor fd, const char* sockaddr, size_t length(sockaddr), UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_connect(sqe, fd, (struct sockaddr*)sockaddr, XSauto_length_of_sockaddr);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV close(IO::Uring self, FileDescriptor fd, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_close(sqe, fd);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV fallocate(IO::Uring self, FileDescriptor fd, UV offset, UV length, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_fallocate(sqe, fd, 0, offset, length);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV fsync(IO::Uring self, FileDescriptor fd, UV flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_fsync(sqe, fd, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV ftruncate(IO::Uring self, FileDescriptor fd, UV length, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_ftruncate(sqe, fd, length);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV link(IO::Uring self, const char* oldpath, const char* newpath, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_link(sqe, oldpath, newpath, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV linkat(IO::Uring self, DirDescriptor olddir, const char* oldpath, DirDescriptor newdir, const char* newpath, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_linkat(sqe, olddir, oldpath, newdir, newpath, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV link_timeout(IO::Uring self, Time::Spec ts, UV flags, UV iflags, SV* callback = undef)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_link_timeout(sqe, ts, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	void* cancel_data = set_callback(sqe, SvOK(callback) ? callback : NULL);
	RETVAL = PTR2UV(cancel_data);
OUTPUT:
	RETVAL


UV listen(IO::Uring self, FileDescriptor fd, UV backlog, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_listen(sqe, fd, backlog);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV mkdir(IO::Uring self, const char* path, UV mode, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_mkdir(sqe, path, mode);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV mkdirat(IO::Uring self, DirDescriptor dir_fd, const char* path, UV mode, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_mkdirat(sqe, dir_fd, path, mode);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV nop(IO::Uring self, UV iflags, SV* callback = undef)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_nop(sqe);
	io_uring_sqe_set_flags(sqe, iflags);
	void* cancel_data = set_callback(sqe, SvOK(callback) ? callback : NULL);
	RETVAL = PTR2UV(cancel_data);
OUTPUT:
	RETVAL


UV open(IO::Uring self, const char* path, int flags, UV mode, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_open(sqe, path, flags, mode);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV openat(IO::Uring self, DirDescriptor dir_fd, const char* path, int flags, UV mode, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_openat(sqe, dir_fd, path, flags, mode);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV poll(IO::Uring self, FileDescriptor fd, UV poll_mask, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_poll_add(sqe, fd, poll_mask);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV poll_multishot(IO::Uring self, FileDescriptor fd, UV poll_mask, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_poll_multishot(sqe, fd, poll_mask);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV poll_update(IO::Uring self, UV old_userdata, new_userdata, UV poll_mask, UV flags, UV iflags, SV* callback = undef)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_poll_update(sqe, old_userdata, 0, poll_mask, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	void* cancel_data = set_callback(sqe, SvOK(callback) ? callback : NULL);
	RETVAL = PTR2UV(cancel_data);
OUTPUT:
	RETVAL


UV poll_remove(IO::Uring self, UV old_userdata, UV iflags, SV* callback = undef)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_poll_remove(sqe, old_userdata);
	io_uring_sqe_set_flags(sqe, iflags);
	void* cancel_data = set_callback(sqe, SvOK(callback) ? callback : NULL);
	RETVAL = PTR2UV(cancel_data);
OUTPUT:
	RETVAL


UV read(IO::Uring self, FileDescriptor fd, char* buffer, size_t length(buffer), UV offset, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_read(sqe, fd, buffer, XSauto_length_of_buffer, offset);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV read_multishot(IO::Uring self, FileDescriptor fd, UV nbytes, UV offset, IV buffergroup, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_read_multishot(sqe, fd, nbytes, offset, buffergroup);
	io_uring_sqe_set_flags(sqe, iflags | IOSQE_BUFFER_SELECT);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV recv(IO::Uring self, FileDescriptor fd, char* buffer, size_t length(buffer), IV rflags, UV pflags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_recv(sqe, fd, buffer, XSauto_length_of_buffer, rflags);
	io_uring_sqe_set_flags(sqe, iflags);
	sqe->ioprio |= pflags;
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV recv_multishot(IO::Uring self, FileDescriptor fd, IV rflags, IV pflags, UV buffergroup, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_recv_multishot(sqe, fd, NULL, 0, rflags);
	sqe->buf_group = buffergroup;
	io_uring_sqe_set_flags(sqe, iflags | IOSQE_BUFFER_SELECT);
	sqe->ioprio |= pflags;
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV rename(IO::Uring self, const char* oldpath, const char* newpath, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_renameat(sqe, AT_FDCWD, oldpath, AT_FDCWD, newpath, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV renameat(IO::Uring self, DirDescriptor olddir, const char* oldpath, DirDescriptor newdir, const char* newpath, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_renameat(sqe, olddir, oldpath, newdir, newpath, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV send(IO::Uring self, FileDescriptor fd, char* buffer, size_t length(buffer), IV sflags, UV pflags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_send(sqe, fd, buffer, XSauto_length_of_buffer, sflags);
	io_uring_sqe_set_flags(sqe, iflags);
	sqe->ioprio = pflags;
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV sendto(IO::Uring self, FileDescriptor fd, char* buffer, size_t length(buffer), IV sflags, const struct sockaddr* name, size_t length(name), UV pflags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_sendto(sqe, fd, buffer, XSauto_length_of_buffer, sflags, name, XSauto_length_of_name);
	io_uring_sqe_set_flags(sqe, iflags);
	sqe->ioprio = pflags;
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV socket(IO::Uring self, int domain, int type, int protocols, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_socket(sqe, domain, type, protocols, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV shutdown(IO::Uring self, FileDescriptor fd, IV how, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_shutdown(sqe, fd, how);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV splice(IO::Uring self, FileDescriptor in, IV off_in, FileDescriptor out, IV off_out, UV nbytes, UV flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_splice(sqe, in, off_in, out, off_out, nbytes, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV sync_file_range(IO::Uring self, FileDescriptor fd, UV length, UV offset, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_sync_file_range(sqe, fd, length, offset, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV tee(IO::Uring self, FileDescriptor in, FileDescriptor out, UV nbytes, UV flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_tee(sqe, in, out, nbytes, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV timeout(IO::Uring self, Time::Spec ts, UV count, UV flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_timeout(sqe, ts, count, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV timeout_remove(IO::Uring self, UV user_data, UV flags, UV iflags, SV* callback = undef)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_timeout_remove(sqe, user_data, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	void* cancel_data = set_callback(sqe, SvOK(callback) ? callback : NULL);
	RETVAL = PTR2UV(cancel_data);
OUTPUT:
	RETVAL


UV timeout_update(IO::Uring self, Time::Spec ts, UV user_data, UV flags, UV iflags, SV* callback = undef)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_timeout_update(sqe, ts, user_data, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	void* cancel_data = set_callback(sqe, SvOK(callback) ? callback : NULL);
	RETVAL = PTR2UV(cancel_data);
OUTPUT:
	RETVAL


UV unlink(IO::Uring self, const char* path, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_unlink(sqe, path, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV unlinkat(IO::Uring self, DirDescriptor dir_fd, const char* path, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_unlinkat(sqe, dir_fd, path, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV waitid(IO::Uring self, IV idtype, IV id, Signal::Info info, IV options, UV flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_waitid(sqe, idtype, id, info, options, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


UV write(IO::Uring self, FileDescriptor fd, char* buffer, size_t length(buffer), UV offset, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_write(sqe, fd, buffer, XSauto_length_of_buffer, offset);
	io_uring_sqe_set_flags(sqe, iflags);
	RETVAL = PTR2UV(set_callback(sqe, callback));
OUTPUT:
	RETVAL


IO::Uring::BufferGroup add_buffer_group(IO::Uring ring, UV size, UV count, int id = 0, unsigned flags = 0)
CODE:
	RETVAL = safecalloc(1, sizeof(struct io_uring_buffergroup));
	RETVAL->ring = ring;
	RETVAL->buffer_size = size;
	RETVAL->buffer_count = count;
	RETVAL->id = id;
	SV* ring_object = ST(0);

	RETVAL->buf_ring_size = count * (sizeof(struct io_uring_buf) + size);
	void* mapped = mmap(NULL, RETVAL->buf_ring_size, PROT_READ | PROT_WRITE, MAP_ANONYMOUS | MAP_PRIVATE, 0, 0);
	if (mapped == MAP_FAILED) {
		safefree(RETVAL);
		die("buf_ring mmap: %s\n", strerror(errno));
	}
	RETVAL->buf_ring = (struct io_uring_buf_ring *)mapped;
	io_uring_buf_ring_init(RETVAL->buf_ring);

	struct io_uring_buf_reg reg = { 0 };
	reg.ring_addr = (unsigned long)mapped;
	reg.ring_entries = count;
	reg.bgid = id;
	int ret = io_uring_register_buf_ring(&ring->uring, &reg, flags);
	if (ret) {
		munmap(mapped, RETVAL->buf_ring_size);
		safefree(RETVAL);
		croak("buf_ring init failed: %s\n", strerror(-ret));
	}

	RETVAL->buffer_base = (char *)RETVAL->buf_ring + count * sizeof(struct io_uring_buf);
	for (int i = 0; i < count; i++)
		io_uring_buf_ring_add(RETVAL->buf_ring, RETVAL->buffer_base + i * size, size, i, io_uring_buf_ring_mask(count), i);
	io_uring_buf_ring_advance(RETVAL->buf_ring, count);
OUTPUT:
	RETVAL
CLEANUP:
	MAGIC* magic = mg_findext(SvRV(ST(0)), PERL_MAGIC_ext, &IO__Uring__BufferGroup_magic);
	magic->mg_obj = SvREFCNT_inc(ring_object);
	magic->mg_flags |= MGf_REFCOUNTED;


MODULE = IO::Uring				PACKAGE = IO::Uring::BufferGroup


IV CLONE_SKIP(sv)


SV* get(IO::Uring::BufferGroup self, UV index, size_t size)
CODE:
	if (index >= self->buffer_count || size > self->buffer_size)
		XSRETURN_UNDEF;

	char* ptr = self->buffer_base + index * self->buffer_size;
	RETVAL = newSV_type(SVt_PV);
	SvPVX(RETVAL) = ptr;
	SvCUR(RETVAL) = size;
	SvLEN(RETVAL) = 0;
	SvPOK_only(RETVAL);
OUTPUT:
	RETVAL


void release(IO::Uring::BufferGroup self, UV index)
CODE:
	char* ptr = self->buffer_base + index * self->buffer_size;
	io_uring_buf_ring_add(self->buf_ring, ptr, self->buffer_size, index, io_uring_buf_ring_mask(self->buffer_count), 0);
	io_uring_buf_ring_advance(self->buf_ring, 1);


SV* consume(IO::Uring::BufferGroup self, UV index, size_t size)
CODE:
	if (index >= self->buffer_count || size > self->buffer_size)
		XSRETURN_UNDEF;

	char* ptr = self->buffer_base + index * self->buffer_size;
	RETVAL = newSVpvn(ptr, size);
	io_uring_buf_ring_add(self->buf_ring, ptr, self->buffer_size, index, io_uring_buf_ring_mask(self->buffer_count), 0);
	io_uring_buf_ring_advance(self->buf_ring, 1);
OUTPUT:
	RETVAL
