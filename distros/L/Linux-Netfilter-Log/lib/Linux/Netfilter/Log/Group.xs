#include <arpa/inet.h>
#include <errno.h>
#include <stdint.h>
#include <string.h>
#include <sys/types.h>
#include <libnetfilter_log/libnetfilter_log.h>

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "linux_netfilter_log.h"

static void _packet_copy_dev(HV *packet, const char *key, struct nflog_data *nfad, uint32_t (*func)(struct nflog_data*))
{
	u_int32_t dev = func(nfad);
	if(dev > 0)
	{
		hv_store(packet, key, strlen(key), newSVuv(dev), 0);
	}
}

static void _packet_copy_u32_buf(HV *packet, const char *key, struct nflog_data *nfad, int (*func)(struct nflog_data*, u_int32_t *buf))
{
	u_int32_t buf;
	if(func(nfad, &buf) == 0)
	{
		hv_store(packet, key, strlen(key), newSVuv(buf), 0);
	}
}

/* Build a Linux::Netfilter::Log::Packet object to pass to the callback.
 *
 * We copy all the data out of nfad rather than wrapping it so the object can
 * remain valid beyond the life of the callback.
*/
static SV *_make_packet_obj(struct nflog_data *nfad)
{
	HV *packet    = newHV();
	SV *packet_sv = sv_bless(newRV_noinc((SV*)(packet)), gv_stashpv("Linux::Netfilter::Log::Packet", 0));

	{
		struct nfulnl_msg_packet_hdr *hdr = nflog_get_msg_packet_hdr(nfad);
		if(hdr != NULL)
		{
			hv_store(packet, "hw_protocol", strlen("hw_protocol"), newSVuv(ntohs(hdr->hw_protocol)), 0);
			hv_store(packet, "hook",        strlen("hook"),        newSVuv(hdr->hook),               0);
		}
	}

	hv_store(packet, "hw_type", strlen("hw_type"), newSVuv(nflog_get_hwtype(nfad)), 0);

	{
		u_int16_t len = nflog_get_msg_packet_hwhdrlen(nfad);
		char *header  = nflog_get_msg_packet_hwhdr(nfad);

		if(len > 0 && header != NULL)
		{
			hv_store(packet, "hw_header", strlen("hw_header"), newSVpvn(header, len), 0);
		}
	}

	hv_store(packet, "mark", strlen("mark"), newSVuv(nflog_get_nfmark(nfad)), 0);

	{
		struct timeval tv;
		if(nflog_get_timestamp(nfad, &tv) == 0)
		{
			hv_store(packet, "timestamp.sec",  strlen("timestamp.sec"),  newSViv(tv.tv_sec),  0);
			hv_store(packet, "timestamp.usec", strlen("timestamp.usec"), newSViv(tv.tv_usec), 0);
		}
	}

	_packet_copy_dev(packet, "indev",      nfad, &nflog_get_indev);
	_packet_copy_dev(packet, "physindev",  nfad, &nflog_get_physindev);
	_packet_copy_dev(packet, "outdev",     nfad, &nflog_get_outdev);
	_packet_copy_dev(packet, "physoutdev", nfad, &nflog_get_physoutdev);

	{
		struct nfulnl_msg_packet_hw *hw = nflog_get_packet_hw(nfad);
		if(hw != NULL)
		{
			hv_store(packet, "hw_addr", strlen("hw_addr"), newSVpvn(hw->hw_addr, sizeof(hw->hw_addr)), 0);
		}
	}

	{
		char *payload;
		int payload_len = nflog_get_payload(nfad, &payload);

		if(payload_len > 0 && payload != NULL)
		{
			hv_store(packet, "payload", strlen("payload"), newSVpvn(payload, payload_len), 0);
		}
	}

	{
		char *prefix = nflog_get_prefix(nfad);
		if(prefix != NULL)
		{
			hv_store(packet, "prefix", strlen("prefix"), newSVpv(prefix, 0), 0);
		}
	}

	_packet_copy_u32_buf(packet, "uid", nfad, &nflog_get_uid);
	_packet_copy_u32_buf(packet, "gid", nfad, &nflog_get_gid);

	_packet_copy_u32_buf(packet, "seq",        nfad, &nflog_get_seq);
	_packet_copy_u32_buf(packet, "seq_global", nfad, &nflog_get_seq_global);

	return packet_sv;
}

static int _callback_proxy(struct nflog_g_handle *gh, struct nfgenmsg *nfmsg, struct nflog_data *nfad, void *data)
{
	SV *callback_func = (SV*)(data);

	dSP;

	ENTER;
	SAVETMPS;

	SV *packet_sv = sv_2mortal(_make_packet_obj(nfad));

	PUSHMARK(SP);
	XPUSHs(packet_sv);
	PUTBACK;

	call_sv(callback_func, G_SCALAR);

	SPAGAIN;

	PUTBACK;
	FREETMPS;
	LEAVE;

	return 0; /* Success */
}

MODULE = Linux::Netfilter::Log::Group	PACKAGE = Linux::Netfilter::Log::Group

void DESTROY(struct perl_nflog_group *self)
	CODE:
		if(nflog_unbind_group(self->g_handle) == -1)
		{
			warn("nflog_unbind_group: %s", strerror(errno));
		}

		if(self->callback != NULL)
		{
			SvREFCNT_dec(self->callback);
		}

		SvREFCNT_dec(self->handle);

		Safefree(self);

void callback_register(struct perl_nflog_group *self, CV *cb)
	CODE:
		if(nflog_callback_register(self->g_handle, &_callback_proxy, (void*)(cb)) == -1)
		{
			croak("nflog_callback_register: %s", strerror(errno));
		}

		if(self->callback != NULL)
		{
			SvREFCNT_dec(self->callback);
		}

		SvREFCNT_inc(cb);
		self->callback = cb;

void set_mode(struct perl_nflog_group *self, uint8_t mode, uint32_t range)
	CODE:
		if(nflog_set_mode(self->g_handle, mode, range) == -1)
		{
			croak("nflog_set_mode: %s", strerror(errno));
		}

void set_nlbufsiz(struct perl_nflog_group *self, uint32_t nlbufsiz)
	CODE:
		if(nflog_set_nlbufsiz(self->g_handle, nlbufsiz) == -1)
		{
			croak("nflog_set_nlbufsiz: %s", strerror(errno));
		}

void set_qthresh(struct perl_nflog_group *self, uint32_t qthresh)
	CODE:
		if(nflog_set_qthresh(self->g_handle, qthresh) == -1)
		{
			croak("nflog_set_qthresh: %s", strerror(errno));
		}

void set_timeout(struct perl_nflog_group *self, uint32_t timeout)
	CODE:
		if(nflog_set_timeout(self->g_handle, timeout) == -1)
		{
			croak("nflog_set_timeout: %s", strerror(errno));
		}

void set_flags(struct perl_nflog_group *self, uint16_t flags)
	CODE:
		if(nflog_set_flags(self->g_handle, flags) == -1)
		{
			croak("nflog_set_flags: %s", strerror(errno));
		}
