#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <libnetfilter_log/libnetfilter_log.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "linux_netfilter_log.h"

/* Size of recv() buffer used to read Netlink messages.
 *
 * I haven't managed to find any concrete max size for how big this can be, but
 * 64k seems significantly bigger than any suggestion or reasonable guesses I've
 * read. I haven't (quite) managed to overflow this using any sensible
 * parameters, but if you want to copy large ranges of the packet payload AND
 * queue many in the kernel at once, you may run into issues.
*/
#define RECV_BUFSIZE 65536

MODULE = Linux::Netfilter::Log	PACKAGE = Linux::Netfilter::Log

struct nflog_handle* open(const char *class)
	CODE:
		RETVAL = nflog_open();
		if(RETVAL == NULL)
		{
			croak("nflog_open: %s", strerror(errno));
		}

	OUTPUT:
		RETVAL

void DESTROY(struct nflog_handle *self)
	CODE:
		if(nflog_close(self) == -1)
		{
			warn("nflog_close: %s", strerror(errno));
		}

void bind_pf(struct nflog_handle *self, uint16_t pf)
	CODE:
		if(nflog_bind_pf(self, pf) < 0)
		{
			croak("nflog_bind_pf: %s", strerror(errno));
		}

void unbind_pf(struct nflog_handle *self, uint16_t pf)
	CODE:
		if(nflog_unbind_pf(self, pf) < 0)
		{
			croak("nflog_unbind_pf: %s", strerror(errno));
		}

struct perl_nflog_group* bind_group(SV *self, uint16_t group)
	CODE:
		/* Need to do the typemap's job here as we need access to the
		 * actual SV to create a reference further down...
		*/
		if(!(sv_isobject(self)
			&& sv_derived_from(self, "Linux::Netfilter::Log")
			&& SvTYPE(SvRV(self)) == SVt_PVMG))
		{
			croak("Linux::Netfilter::Log->bind_group() -- self is not a Linux::Netfilter::Log");
		}

		struct nflog_handle *log_h = (struct nflog_handle*)(SvIV((SV*)SvRV(self)));

		Newxz(RETVAL, 1, struct perl_nflog_group*);

		RETVAL->g_handle = nflog_bind_group(log_h, group);
		if(RETVAL->g_handle == NULL)
		{
			int err = errno;
			Safefree(RETVAL);

			croak("nflog_bind_group: %s", strerror(err));
		}

		/* Stash a reference to us within the Group object so we can't
		 * be destroyed before it.
		*/
		SvREFCNT_inc(self);
		RETVAL->handle = self;

	OUTPUT:
		RETVAL

int fileno(struct nflog_handle *self)
	CODE:
		RETVAL = nflog_fd(self);

	OUTPUT:
		RETVAL

SV *recv_and_process_one(struct nflog_handle *self)
	CODE:
		/* Use of SAVEFREEPV() will implicitly Safefree() the buffer
		 * when the XSUB returns.
		*/
		void *buf;
		Newxz(buf, RECV_BUFSIZE, char);
		SAVEFREEPV(buf);

		ssize_t len = recv(nflog_fd(self), buf, RECV_BUFSIZE, 0);
		if(len < 0)
		{
			if(errno == ENOBUFS)
			{
				XSRETURN_NO;
			}

			croak("recv: %s", strerror(errno));
		}
		else if(len == RECV_BUFSIZE)
		{
			warn("recv() returned the buffer size (%u), the message may have been truncated!",
				(unsigned int)(RECV_BUFSIZE));
		}

		/* nflog_handle_packet() defers to the old nfnl_handle_packet()
		 * API which has poor error handling; errno isn't initialised
		 * for any internal errors.
		 *
		 * On top of that, all NFLOG messages seem to cause an error
		 * after the packets have been processsed - perhaps a malformed
		 * trailer or bad length?
		 *
		 * So... ignore the return value, assume everything was fine.
		 * ugh.
		*/

		nflog_handle_packet(self, buf, len);
		RETVAL = &PL_sv_yes;

	OUTPUT:
		RETVAL
