#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef WIN32
#include <time.h>
#else
#include <sys/time.h>
#endif

#include "ringbuffer.h"

#ifdef __cplusplus
}
#endif

/*
 *	kiped from Time::HiRes; only works for Win32 and POSIX
 */
#ifdef WIN32

typedef union {
    unsigned __int64	ft_i64;
    FILETIME		ft_val;
} FT_t;

/* Number of 100 nanosecond units from 1/1/1601 to 1/1/1970 */
#ifdef __GNUC__
#define Const64(x)	x##LL
#else
#define Const64(x)	x##i64
#endif
# define EPOCH_BIAS Const64(116444736000000000)
/*
 *	we don't give a damn about all the fancy drift and skew...
 *	just give us a reasonable hires timestamp
 */
double
_hires_time()
{
    FT_t ft;
    unsigned long tv_sec;
    unsigned long tv_usec;
    double retval;

	GetSystemTimeAsFileTime(&ft.ft_val);

    /* seconds since epoch */
    tv_sec = (long) ( (ft.ft_i64 - EPOCH_BIAS) / Const64(10000000) );

    /* microseconds remaining */
    tv_usec = (long)( (ft.ft_i64 / Const64(10)) % Const64(1000000) );

	retval = tv_sec + (tv_usec / 1000000.);
	return retval;
}
#else
double _hires_time() {
	struct timeval Tp;
	int status = gettimeofday (&Tp, NULL);
	double retval = -1.0;

	if (! status)
		retval = Tp.tv_sec + (Tp.tv_usec / 1000000.);
	return retval;
}
#endif

MODULE = Devel::RingBuffer		PACKAGE = Devel::RingBuffer

#
# computes single ring buffer size based on struct sizes,
# buffer and slot counts, and msg area size
#
void
_get_ring_size(slots, slotsz, msgarea_size)
	int slots
	int slotsz
	int msgarea_size
    PROTOTYPE: $$
    PPCODE:
    	int ringsz = sizeof(ring_header_t) +
    		(slots * (slotsz + sizeof(ring_slothdr_t))) +
    		msgarea_size;
		ST(0) = sv_2mortal(newSViv(ringsz));
		XSRETURN(1);

#
# computes total ring size based on struct sizes,
# buffer and slot counts, msg area size, and global area size
#
void
_get_total_size(count, slots, slotsz, msgarea_size, global_size)
	int count
	int slots
	int slotsz
	int msgarea_size
	int global_size
    PROTOTYPE: $$$$
    PPCODE:
    	int ringsz = sizeof(ring_header_t) +
    		(slots * (slotsz + sizeof(ring_slothdr_t))) +
    		msgarea_size;
    	int total = sizeof(ring_buffers_t) + global_size + count + (ringsz * count);
		ST(0) = sv_2mortal(newSViv(total));
		XSRETURN(1);

#
# returns base address of the rings area
#
void
_get_rings_addr(addr, count, global_size)
	SV * addr
	int count
	int global_size
	PROTOTYPE: $$$
	PPCODE:
        UV tmp = SvUV(addr);
        tmp += sizeof(ring_bufhdr_t) + count + global_size;
		ST(0) = sv_2mortal(newSVuv(tmp));
		XSRETURN(1);

#
# returns base address of a specific ring; assumes addr is base of rings area
#
void
_get_ring_addr(addr, ringnum, slots, slotsz, msgarea_size)
	SV * addr
	UV ringnum
	int slots
	int slotsz
	int msgarea_size
	PROTOTYPE: $$$$
	PPCODE:
        UV tmp = SvUV(addr);
#
#	computation needs to account for dynamic sized
#	fields
#
    	UV ringsz = sizeof(ring_header_t) +
    		(slots * (slotsz + sizeof(ring_slothdr_t))) +
    		msgarea_size;
    	tmp += (ringsz * ringnum);

		ST(0) = sv_2mortal(newSVuv(tmp));
		XSRETURN(1);

#
# scans the free map for an entry
# returns the index of the ring, or undef
#
void
_alloc_ring(mapaddr, count)
	SV * mapaddr
	int count
	PROTOTYPE: $$
	PPCODE:
        IV tmp = SvIV(mapaddr);
		char * freemap = INT2PTR(caddr_t,tmp);
		int i = 0;

		for (; ((i < count) && (! *freemap)); i++, freemap++);
		if (i < count) {
			*freemap = 0;
			ST(0) = sv_2mortal(newSViv(i));
		}
		else
			ST(0) = &PL_sv_undef;
		XSRETURN(1);

#
# sets the free map entry for the input index
#
void
_free_ring(mapaddr, ringaddr, ringbufsz, ringnum)
	SV * mapaddr
	SV * ringaddr
	int ringbufsz
	int ringnum
	PROTOTYPE: $$$$
	PPCODE:
        UV tmp = SvUV(mapaddr);
		char * freemap = INT2PTR(caddr_t,tmp);
		ring_bufptr_t ring;

        tmp = SvUV(ringaddr);
        tmp += (ringnum * ringbufsz);
		ring = INT2PTR(ring_bufptr_t, tmp);

		freemap[ringnum] = 1;
		ring->hdr.pid = 0;
		ring->hdr.tid = 0;
		ring->hdr.currSlot = -1;
		ring->hdr.depth = 0;
		ST(0) = &PL_sv_yes;
		XSRETURN(1);

#
# find ring buffer with matching pid/tid
#
void
_find_ring(ringaddr, ringbufsz, count, pid, tid)
	SV * ringaddr
	int ringbufsz
	int count
	int pid
	int tid
	PROTOTYPE: $$$$$
	PPCODE:
        UV tmp = SvUV(ringaddr);
		ring_bufptr_t ring = INT2PTR(ring_bufptr_t,tmp);
		int i = 0;

		while ((i < count) &&
			((ring->hdr.pid != pid) || (ring->hdr.tid != tid))) {
			i++;
			tmp += ringbufsz;
			ring = INT2PTR(ring_bufptr_t,tmp);
		}
		ST(0) = (i < count) ? sv_2mortal(newSViv(i)) : &PL_sv_undef;
		XSRETURN(1);

MODULE = Devel::RingBuffer		PACKAGE = Devel::RingBuffer::Ring

#
# loads pid, itd, resets all other fields; returns addr of slots
#
void
_init_ring(addr, pid, tid, baseaddr)
	SV * addr
	int pid
	int tid
	SV * baseaddr
	PROTOTYPE: $$$$
	PPCODE:
        UV tmp = SvUV(addr);
        UV basetmp = SvUV(baseaddr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
        ringbuf_hdrptr_t ringbuf = INT2PTR(ringbuf_hdrptr_t, basetmp);
        UV slotsaddr = tmp + sizeof(ring_header_t) + ringbuf->msgarea_sz;
        int i;

        ring->hdr.pid = pid;
        ring->hdr.tid = tid;
        ring->hdr.currSlot = -1;
        ring->hdr.depth = 0;
        ring->hdr.trace = ringbuf->trace_on_create;
        ring->hdr.signal = ringbuf->stop_on_create;
        ring->hdr.baseoff = tmp - basetmp;
        ring->hdr.cmdready = 0;
        memset(&ring->hdr.command, ' ', 4);

        for (i = 0; i < STRACE_WATCH_CNT; i++)
        	ring->hdr.watches[i].inuse = 0;

		ST(0) = &PL_sv_yes;
		XSRETURN(1);

#
# compute ptr to slots
#
void
_get_slots_addr(addr)
	SV * addr
	PROTOTYPE: $
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
        ringbuf_hdrptr_t ringbuf = INT2PTR(ringbuf_hdrptr_t, (tmp - ring->hdr.baseoff));
        UV slotsaddr = tmp + sizeof(ring_header_t) + ringbuf->msgarea_sz;
		ST(0) = sv_2mortal(newSVuv(slotsaddr));
		XSRETURN(1);

#
# get pid, tid, current slot, and depth
#
void
_get_header(addr)
	SV * addr
	PROTOTYPE: $
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);

		EXTEND(SP, 4);
		PUSHs(sv_2mortal(newSViv(ring->hdr.pid)));
		PUSHs(sv_2mortal(newSViv(ring->hdr.tid)));
		PUSHs(sv_2mortal(newSViv(ring->hdr.currSlot)));
		PUSHs(sv_2mortal(newSViv(ring->hdr.depth)));

#
# writes linenumber, timestamp to current slot header
#
void
updateSlot(addr, lineno)
	SV * addr
	int lineno
	PPCODE:
        UV tmp;
        ring_bufptr_t ring;
        ringbuf_hdrptr_t ringbuf;
        UV slotsaddr;
        ring_slotptr_t slot;
        AV *self;
#
#	we support both object and class method
#
        if (SvROK(addr)) {
        	self = (AV *)(SvRV(addr));
        	tmp = SvUV(*(av_fetch(self, 2, 0)));
        }
        else {
	        tmp = SvUV(addr);
	    }
        ring = INT2PTR(ring_bufptr_t, tmp);

		if (!  ring->hdr.trace) {
			ST(0) = &PL_sv_yes;
		}
		else {
        	ringbuf = INT2PTR(ringbuf_hdrptr_t, (tmp - ring->hdr.baseoff));
        	slotsaddr = tmp + sizeof(ring_header_t) + ringbuf->msgarea_sz;
        	slot = NULL;

			if (ring->hdr.currSlot < 0) {
				ST(0) = &PL_sv_undef;
			}
			else {
        		slotsaddr += (ring->hdr.currSlot * (ringbuf->slot_sz + sizeof(ring_slothdr_t)));
	    	    slot = INT2PTR(ring_slotptr_t, slotsaddr);
				slot->hdr.linenumber = lineno;
				slot->hdr.timestamp = _hires_time();
				ST(0) = &PL_sv_yes;
			}
		}
		XSRETURN(1);

#
# advances to next slot and sets it
# in future we should return the current entry, so it can
# be restored on de-wrapping
#
void
nextSlot(addr, entry)
	SV * addr
	SV * entry
	PPCODE:
        UV tmp;
        ring_bufptr_t ring;
        ringbuf_hdrptr_t ringbuf;
        UV slotsaddr;
        ring_slotptr_t slot = NULL;
        int currslot;
        int entrylen;
       	AV *self;
#
#	we support both object and class method
#
        if (SvROK(addr)) {
        	self = (AV *)(SvRV(addr));
        	tmp = SvUV(*(av_fetch(self, 2, 0)));
        }
        else {
	        tmp = SvUV(addr);
	    }
        ring = INT2PTR(ring_bufptr_t, tmp);
        ringbuf = INT2PTR(ringbuf_hdrptr_t, (tmp - ring->hdr.baseoff));
        slotsaddr = tmp + sizeof(ring_header_t) + ringbuf->msgarea_sz;
        currslot = ring->hdr.currSlot + 1;
        entrylen = SvCUR(entry);

        if (entrylen >= ringbuf->slot_sz)
        	entrylen = ringbuf->slot_sz - 1;
#
#	only advance when a valid slot is used
#
       	if (currslot >= 0)
        	ring->hdr.depth++;

		if (currslot >= ringbuf->slots)
	    	currslot = 0;

		ring->hdr.currSlot = currslot;

       	slotsaddr += (currslot * (ringbuf->slot_sz + sizeof(ring_slothdr_t)));
        slot = INT2PTR(ring_slotptr_t, slotsaddr);
		slot->hdr.linenumber = 0;
		slot->hdr.timestamp = _hires_time();
		memcpy(slot->subroutine, SvPV_nolen(entry), entrylen);
		slot->subroutine[entrylen] = '\0';

		ST(0) = sv_2mortal(newSViv(ring->hdr.depth));
		XSRETURN(1);

#
# backs up one slot
#
void
freeSlot(addr)
	SV * addr
	PPCODE:
        UV tmp;
        ring_bufptr_t ring;
        ringbuf_hdrptr_t ringbuf;
        UV slotsaddr;
        ring_slotptr_t slots = NULL;
        int currslot;
       	AV *self;
#
#	we support both object and class method
#
        if (SvROK(addr)) {
        	self = (AV *)(SvRV(addr));
        	tmp = SvUV(*(av_fetch(self, 2, 0)));
        }
        else {
	        tmp = SvUV(addr);
	    }
        ring = INT2PTR(ring_bufptr_t, tmp);
        ringbuf = INT2PTR(ringbuf_hdrptr_t, (tmp - ring->hdr.baseoff));
        slotsaddr = tmp + sizeof(ring_header_t) + ringbuf->msgarea_sz;
        currslot = ring->hdr.currSlot;
        ring->hdr.depth--;

        if (ring->hdr.depth < 0) {
        	printf("ring for %i underflow with slot %i\n", ring->hdr.tid, currslot);
        	ring->hdr.depth = 0;
        }
#
#	invalidate current slot
#
       	slotsaddr += (currslot * (ringbuf->slot_sz + sizeof(ring_slothdr_t)));
        slots = INT2PTR(ring_slotptr_t, slotsaddr);

		strcpy(slots->subroutine, "(Invalid slot due to prior wrap)");
		slots->hdr.linenumber = -1;
		slots->hdr.timestamp = 0.0;

		currslot--;
		if ((currslot < 0) && (ring->hdr.depth > 0))
			currslot = ringbuf->slots - 1;
		ring->hdr.currSlot = currslot;

		ST(0) = sv_2mortal(newSViv(ring->hdr.depth));
		XSRETURN(1);

#
#	returns contents of specified slot using ring base addr
#
void
_get_slot(addr, slotnum)
	SV * addr
	int slotnum
	PROTOTYPE: $$
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
        ringbuf_hdrptr_t ringbuf = INT2PTR(ringbuf_hdrptr_t, (tmp - ring->hdr.baseoff));
        UV slotsaddr = tmp + sizeof(ring_header_t) + ringbuf->msgarea_sz +
        	(slotnum * (ringbuf->slot_sz + sizeof(ring_slothdr_t)));
        ring_slotptr_t slots = INT2PTR(ring_slotptr_t, slotsaddr);

		EXTEND(SP, 2);
		PUSHs(sv_2mortal(newSViv(slots->hdr.linenumber)));
		PUSHs(sv_2mortal(newSVnv(slots->hdr.timestamp)));
		PUSHs(sv_2mortal(newSVpv(slots->subroutine, strlen(slots->subroutine))));

#
#	accessors/mutators for per-thread tied
#	DB control variables
#
void
getFlags(addr)
	SV *   addr
    PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
        ringbuf_hdrptr_t ringbuf = INT2PTR(ringbuf_hdrptr_t, (tmp - ring->hdr.baseoff));
		int retval = (ringbuf->single ? 1 : 0) | (ring->hdr.trace ? 2 : 0) | (ring->hdr.signal ? 4 : 0);
		ST(0) = sv_2mortal(newSViv(retval));
		XSRETURN(1);

void
_get_trace(addr)
	SV * addr
	PROTOTYPE: $
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
        ST(0) = sv_2mortal(newSViv(ring->hdr.trace));
		XSRETURN(1);

#
#	returns prior value of trace
#
void
_set_trace(addr, val)
	SV * addr
	int val
	PROTOTYPE: $$
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
        ST(0) = sv_2mortal(newSViv(ring->hdr.trace));
        ring->hdr.trace = val;
		XSRETURN(1);

void
_get_signal(addr)
	SV * addr
	PROTOTYPE: $
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
        ST(0) = sv_2mortal(newSViv(ring->hdr.signal));
		XSRETURN(1);

#
#	returns prior value of signal
#
void
_set_signal(addr, val)
	SV * addr
	int val
	PROTOTYPE: $$
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
        ST(0) = sv_2mortal(newSViv(ring->hdr.signal));
        ring->hdr.signal = val;
		XSRETURN(1);

#
# posts a response + msg to command area
#
void
_post_cmd_msg(addr, resp, msg, state)
	SV * addr
	SV * resp
	SV * msg
	int state
	PROTOTYPE: $$$$
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
        ringbuf_hdrptr_t ringbuf = INT2PTR(ringbuf_hdrptr_t, (tmp - ring->hdr.baseoff));

		int resplen = SvCUR(resp);
		int msglen = SvCUR(msg);

		if (resplen > 4)
			resplen = 4;

		if (msglen > ringbuf->msgarea_sz)
			msglen = ringbuf->msgarea_sz;

		ring->hdr.msglen = msglen;

		memset(ring->hdr.command, '\0', 4);
		memset(ring->msgarea, '\0', ringbuf->msgarea_sz);
		memcpy(ring->hdr.command, SvPV_nolen(resp), resplen);
		memcpy(ring->msgarea, SvPV_nolen(msg), msglen);

		ring->hdr.cmdready = state;
		ST(0) = &PL_sv_yes;
		XSRETURN(1);

#
# tests if command is available and returns it if it is
#
void
_check_for_cmd_msg(addr, state)
	SV * addr
	int state
	PROTOTYPE: $$
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
		int msglen = ring->hdr.msglen;
		char lclcmd[5];

		EXTEND(SP, 2);
		if (ring->hdr.cmdready != state) {
			PUSHs(&PL_sv_undef);
			PUSHs(&PL_sv_undef);
		}
		else {
			strncpy(lclcmd, ring->hdr.command, 4);
			lclcmd[4] = '\0';
			PUSHs(sv_2mortal(newSVpvn(lclcmd, strlen(lclcmd))));
			PUSHs(sv_2mortal(newSVpvn(ring->msgarea, ring->hdr.msglen)));
		}

#
# gets the specified watchlist expression
#
void
_get_watch_expr(addr, watch)
	SV * addr
	int watch
	PROTOTYPE: $$
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);

		ST(0) = &PL_sv_undef;

		if ((watch >= 0) && (watch < STRACE_WATCH_CNT) &&
			ring->hdr.watches[watch].inuse &&
			(!ring->hdr.watches[watch].resready)) {

			if (ring->hdr.watches[watch].inuse < 0)
				ring->hdr.watches[watch].inuse = 0;
			else
				ST(0) = sv_2mortal(newSVpv(ring->hdr.watches[watch].expr, ring->hdr.watches[watch].exprlength));
		}
		XSRETURN(1);

#
# sets the result of a watchlist expr
#
void
_set_watch_result(addr, watch, result, error)
	SV * addr
	int watch
	SV * result
	SV * error
	PROTOTYPE: $$$$
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
        int len;

		ST(0) = &PL_sv_undef;
		if ((watch >= 0) && (watch < STRACE_WATCH_CNT)) {
			len = SvCUR(result);
			if (len > STRACE_WATCH_RESLEN)
				len = STRACE_WATCH_RESLEN;

			if (SvOK(error) && SvCUR(error)) {
				ring->hdr.watches[watch].reslength = -len;
				memcpy(ring->hdr.watches[watch].result, SvPV_nolen(result), len);
			}
			else if (!SvOK(result)) {
				ring->hdr.watches[watch].reslength = 0;
			}
			else {
				ring->hdr.watches[watch].reslength = len;
				memcpy(ring->hdr.watches[watch].result, SvPV_nolen(result), len);
			}
			ring->hdr.watches[watch].resready = 1;
#
#	return offset of next watch, or 0 if end of list
#
			watch++;
			ST(0) = sv_2mortal(newSViv(((watch == STRACE_WATCH_CNT) ? 0 : watch)));
		}
		XSRETURN(1);

#
#	returns (truelen, result, error)
#
void
_get_watch_result(addr, watch)
	SV * addr
	int watch
	PROTOTYPE: $$
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
        int len;
        char *zerobuttrue = "0E0";

		EXTEND(SP, 3);
		if ((watch < 0) || (watch > STRACE_WATCH_CNT) ||
			(!ring->hdr.watches[watch].resready)) {
			PUSHs(&PL_sv_undef);
			PUSHs(&PL_sv_undef);
			PUSHs(&PL_sv_undef);
		}
		else if (!ring->hdr.watches[watch].reslength) {
#
#	expr resulted in undef
#
			ring->hdr.watches[watch].resready = 0;
			PUSHs(sv_2mortal(newSVpv(zerobuttrue, 3)));
			PUSHs(&PL_sv_undef);
			PUSHs(&PL_sv_undef);
		}
		else if (ring->hdr.watches[watch].reslength < 0) {
#
#	expr resulted in error
#
			len = -1 * ring->hdr.watches[watch].reslength;
			if (len > STRACE_WATCH_RESLEN)
				len = STRACE_WATCH_RESLEN;
			ring->hdr.watches[watch].resready = 0;
			PUSHs(sv_2mortal(newSViv(len)));
			PUSHs(&PL_sv_undef);
			PUSHs(sv_2mortal(newSVpv(ring->hdr.watches[watch].result, len)));
		}
		else {
#
#	do we need to set the ready flag ??
#
			len = ring->hdr.watches[watch].reslength;
			if (len > STRACE_WATCH_RESLEN)
				len = STRACE_WATCH_RESLEN;
			PUSHs(sv_2mortal(newSViv(len)));
			PUSHs(sv_2mortal(newSVpv(ring->hdr.watches[watch].result, len)));
			PUSHs(&PL_sv_undef);
		}

#
#	add a watch expression
#
void
_add_watch_expr(addr, expr)
	SV * addr
	SV * expr
	PROTOTYPE: $$
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
        int watch = 0;

		ST(0) = &PL_sv_undef;
		if (SvCUR(expr) <= STRACE_WATCH_EXPRLEN) {
			for (; (watch < STRACE_WATCH_CNT) && ring->hdr.watches[watch].inuse;
				watch++);

			if (watch < STRACE_WATCH_CNT) {
				memcpy(ring->hdr.watches[watch].expr, SvPV_nolen(expr), SvCUR(expr));
				ring->hdr.watches[watch].exprlength = SvCUR(expr);
				ring->hdr.watches[watch].inuse = 1;
				ST(0) = sv_2mortal(newSViv(watch));
			}
		}
		XSRETURN(1);

#
#	remove a watch expression
#
void
_free_watch_expr(addr, watch)
	SV * addr
	int watch
	PROTOTYPE: $$
	PPCODE:
        UV tmp = SvUV(addr);
        ring_bufptr_t ring = INT2PTR(ring_bufptr_t, tmp);
        ring->hdr.watches[watch].inuse = -2;
        ST(0) = &PL_sv_yes;
		XSRETURN(1);
