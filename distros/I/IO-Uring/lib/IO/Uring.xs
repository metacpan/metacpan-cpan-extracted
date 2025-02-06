#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <liburing.h>


typedef struct ring {
	struct io_uring uring;
	unsigned cqe_count;
} *IO__Uring;

static struct io_uring_sqe* S_get_sqe(pTHX_ struct ring* ring) {
	struct io_uring_sqe* sqe = io_uring_get_sqe(&ring->uring);

	if (!sqe) {
		io_uring_cq_advance(&ring->uring, ring->cqe_count);
		ring->cqe_count = 0;
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

#undef SvPV
#define SvPV(sv, len) SvPVbyte(sv, len)
#undef SvPV_nolen
#define SvPV_nolen(sv) SvPVbyte_nolen(sv)

#define CONSTANT(cons) newCONSTSUB(stash, #cons, newSVuv(cons)); av_push(export_ok, newSVpvs(#cons))
#define URING_CONSTANT(cons) CONSTANT(IORING_##cons)
#define SQE_CONSTANT(cons) CONSTANT(IOSQE_##cons)

MODULE = IO::Uring				PACKAGE = IO::Uring

PROTOTYPES: DISABLED

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

	URING_CONSTANT(TIMEOUT_ABS);
	URING_CONSTANT(TIMEOUT_BOOTTIME);
	URING_CONSTANT(TIMEOUT_REALTIME);
	URING_CONSTANT(TIMEOUT_ETIME_SUCCESS);
	URING_CONSTANT(TIMEOUT_MULTISHOT);

	CONSTANT(RENAME_EXCHANGE);
	CONSTANT(RENAME_NOREPLACE);

	CONSTANT(AT_REMOVEDIR);

	CONSTANT(P_PID);
	CONSTANT(P_PGID);
	CONSTANT(P_PIDFD);
	CONSTANT(P_ALL);
	CONSTANT(WEXITED);
	CONSTANT(WSTOPPED);
	CONSTANT(WCONTINUED);
	CONSTANT(WNOWAIT);

IO::Uring new(class, UV entries)
CODE:
	RETVAL = safecalloc(1, sizeof(struct ring));
	RETVAL->cqe_count = 0;
	struct io_uring_params params = {};
	params.flags = IORING_SETUP_SINGLE_ISSUER | IORING_SETUP_COOP_TASKRUN | IORING_SETUP_DEFER_TASKRUN;
	io_uring_queue_init_params(entries, &RETVAL->uring, &params);
OUTPUT:
	RETVAL


void DESTROY(IO::Uring self)
	CODE:
	io_uring_queue_exit(&self->uring);
	safefree(self);


void run_once(IO::Uring self, unsigned min_events = 1)
	PPCODE:
	int result = io_uring_submit_and_wait(&self->uring, min_events);

	if (result == -1 && errno == EINTR)
		PERL_ASYNC_CHECK();

	struct io_uring_cqe *cqe;
	unsigned head;

	EXTEND(SP, 2);
	io_uring_for_each_cqe(&self->uring, head, cqe) {
		++self->cqe_count;
		SV* callback = (SV*)io_uring_cqe_get_data(cqe);
		if (callback) {
			PUSHMARK(SP);
			mPUSHi(cqe->res);
			mPUSHu(cqe->flags);
			PUTBACK;
			call_sv(callback,  G_VOID | G_DISCARD | G_EVAL);
			if (!(cqe->flags & IORING_CQE_F_MORE))
				SvREFCNT_dec(callback);

			if (SvTRUE(ERRSV)) {
				io_uring_cq_advance(&self->uring, self->cqe_count);
				self->cqe_count = 0;
				Perl_croak(aTHX_ NULL);
			}

			SPAGAIN;
		}
	}

	io_uring_cq_advance(&self->uring, self->cqe_count);
	self->cqe_count = 0;


UV accept(IO::Uring self, FileDescriptor fd, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_accept(sqe, fd, NULL, NULL, SOCK_CLOEXEC);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV cancel(IO::Uring self, UV user_data, UV flags, UV iflags, SV* callback = &PL_sv_undef)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_cancel(sqe, NUM2PTR(void*, user_data), flags);
	io_uring_sqe_set_flags(sqe, iflags);
	void* cancel_data = SvOK(callback) ? SvREFCNT_inc(callback) : NULL;
	io_uring_sqe_set_data(sqe, cancel_data);
	RETVAL = PTR2UV(cancel_data);
OUTPUT:
	RETVAL


UV connect(IO::Uring self, FileDescriptor fd, const char* sockaddr, size_t length(sockaddr), UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_connect(sqe, fd, (struct sockaddr*)sockaddr, STRLEN_length_of_sockaddr);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV close(IO::Uring self, FileDescriptor fd, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_close(sqe, fd);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV fallocate(IO::Uring self, FileDescriptor fd, UV offset, UV length, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_fallocate(sqe, fd, 0, offset, length);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV fsync(IO::Uring self, FileDescriptor fd, UV flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_fsync(sqe, fd, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV ftruncate(IO::Uring self, FileDescriptor fd, UV length, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_ftruncate(sqe, fd, length);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV link(IO::Uring self, const char* oldpath, const char* newpath, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_link(sqe, oldpath, newpath, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV linkat(IO::Uring self, DirDescriptor olddir, const char* oldpath, DirDescriptor newdir, const char* newpath, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_linkat(sqe, olddir, oldpath, newdir, newpath, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV link_timeout(IO::Uring self, Time::Spec ts, UV flags, UV iflags, SV* callback = &PL_sv_undef)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_link_timeout(sqe, ts, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	void* cancel_data = SvOK(callback) ? SvREFCNT_inc(callback) : NULL;
	io_uring_sqe_set_data(sqe, cancel_data);
	RETVAL = PTR2UV(cancel_data);
OUTPUT:
	RETVAL


UV mkdir(IO::Uring self, const char* path, UV mode, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_mkdir(sqe, path, mode);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV mkdirat(IO::Uring self, DirDescriptor dir_fd, const char* path, UV mode, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_mkdirat(sqe, dir_fd, path, mode);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV nop(IO::Uring self, const char* path, int flags, UV mode, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_nop(sqe);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV open(IO::Uring self, const char* path, int flags, UV mode, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_open(sqe, path, flags, mode);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV openat(IO::Uring self, DirDescriptor dir_fd, const char* path, int flags, UV mode, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_openat(sqe, dir_fd, path, flags, mode);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV poll(IO::Uring self, FileDescriptor fd, UV poll_mask, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_poll_add(sqe, fd, poll_mask);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV poll_multishot(IO::Uring self, FileDescriptor fd, UV poll_mask, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_poll_multishot(sqe, fd, poll_mask);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV read(IO::Uring self, FileDescriptor fd, char* buffer, size_t length(buffer), UV offset, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_read(sqe, fd, buffer, STRLEN_length_of_buffer, offset);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV recv(IO::Uring self, FileDescriptor fd, char* buffer, size_t length(buffer), IV rflags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_recv(sqe, fd, buffer, STRLEN_length_of_buffer, rflags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV rename(IO::Uring self, const char* oldpath, const char* newpath, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_renameat(sqe, AT_FDCWD, oldpath, AT_FDCWD, newpath, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV renameat(IO::Uring self, DirDescriptor olddir, const char* oldpath, DirDescriptor newdir, const char* newpath, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_renameat(sqe, olddir, oldpath, newdir, newpath, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV send(IO::Uring self, FileDescriptor fd, char* buffer, size_t length(buffer), IV sflags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_send(sqe, fd, buffer, STRLEN_length_of_buffer, sflags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV shutdown(IO::Uring self, FileDescriptor fd, IV how, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_shutdown(sqe, fd, how);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV splice(IO::Uring self, FileDescriptor in, IV off_in, FileDescriptor out, IV off_out, UV nbytes, UV flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_splice(sqe, in, off_in, out, off_out, nbytes, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV sync_file_range(IO::Uring self, FileDescriptor fd, UV length, UV offset, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_sync_file_range(sqe, fd, length, offset, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV tee(IO::Uring self, FileDescriptor in, FileDescriptor out, UV nbytes, UV flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_tee(sqe, in, out, nbytes, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV timeout(IO::Uring self, Time::Spec ts, UV count, UV flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_timeout(sqe, ts, count, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV timeout_remove(IO::Uring self, UV user_data, UV flags, UV iflags, SV* callback = &PL_sv_undef)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_timeout_remove(sqe, user_data, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	void* cancel_data = SvOK(callback) ? SvREFCNT_inc(callback) : NULL;
	io_uring_sqe_set_data(sqe, cancel_data);
	RETVAL = PTR2UV(cancel_data);
OUTPUT:
	RETVAL


UV timeout_update(IO::Uring self, Time::Spec ts, UV user_data, UV flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_timeout_update(sqe, ts, user_data, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV unlink(IO::Uring self, const char* path, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_unlink(sqe, path, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV unlinkat(IO::Uring self, DirDescriptor dir_fd, const char* path, int flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_unlinkat(sqe, dir_fd, path, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV waitid(IO::Uring self, IV idtype, IV id, Signal::Info info, IV options, UV flags, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_waitid(sqe, idtype, id, info, options, flags);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL


UV write(IO::Uring self, FileDescriptor fd, char* buffer, size_t length(buffer), UV offset, UV iflags, SV* callback)
CODE:
	struct io_uring_sqe* sqe = get_sqe(self);
	io_uring_prep_write(sqe, fd, buffer, STRLEN_length_of_buffer, offset);
	io_uring_sqe_set_flags(sqe, iflags);
	io_uring_sqe_set_data(sqe, SvREFCNT_inc(callback));
	RETVAL = PTR2UV(callback);
OUTPUT:
	RETVAL
