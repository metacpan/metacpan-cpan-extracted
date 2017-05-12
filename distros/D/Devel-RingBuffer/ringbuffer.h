#ifndef __DEVEL_RINGBUF_RINGS

typedef struct {
	I32 linenumber;             /* current execution linenumber in subroutine */
	double timestamp;           /* Time::HiRes::time() timestamp of the execution */
} ring_slothdr_t, *ring_slothdrptr_t;

typedef struct {
	ring_slothdr_t hdr;
	char subroutine[1];         /* name of subroutine (as reported by $DB::sub) */
} ring_slot_t, *ring_slotptr_t;

#define STRACE_WATCH_EXPRLEN (256)
#define STRACE_WATCH_RESLEN (512)

typedef struct {
	I32 inuse;                 /* 1 => in use, -2 => freeing, 0 => freed */
	I32 exprlength;            /* length of expr text */
	char expr[STRACE_WATCH_EXPRLEN];  /* expr text */
	I32 resready;              /* 0 => monitor has read last result */
	I32 reslength;             /* result length before truncation;
                                  length < 0 the expression eval failed, with
                                  error text in the result area;
                                  length == 0 means result was undef */
	char result[STRACE_WATCH_RESLEN]; /* result text */
} watch_expr_t;

#define STRACE_WATCH_CNT (4)

typedef struct {
	I32 single;                  /* tied to $DB::single (global) */
	I32 msgarea_sz;              /* size of RingBuffer.msgarea */
	I32 max_buffers;             /* max number of buffers available */
	I32 slots;                   /* number of slots per buffer */
	I32 slot_sz;                 /* size of each slot */
	I32 stop_on_create;          /* 1 => new threads created with hdr.signal = 1 */
	I32 trace_on_create;         /* 1 => new threads created with hdr.trace = 1 */
	I32 global_sz;               /* size of RingBuffers.global_buffer */
	I32 globmsg_total;           /* size of complete global msg contents */
	I32 globmsg_sz;              /* size of current global msg fragment */
} ring_bufhdr_t, *ringbuf_hdrptr_t;

typedef struct {
	I32 pid;                    /* pid of slot buffer owner */
	I32 tid;                    /* tid of slot buffer owner */
	I32 currSlot;               /* current slot */
	I32 depth;                  /* current stack depth */
	I32 trace;                  /* tied to $DB::trace (per-thread/proc) */
	I32 signal;                 /* tied to $DB::signal (per-thread/proc) */
	I32 baseoff;                /* offset from our address to ring buffer base */
	watch_expr_t watches[STRACE_WATCH_CNT]; /* watch expressions */
	I32 cmdready;               /* 1 => command sent; -2 => response ready; 0 => empty */
	char command[4];            /* ext. command entry */
	I32 msglen;                 /* length of msg */
} ring_header_t;

typedef struct {
	ring_header_t hdr;			/* fixed size header */
	char msgarea[1];            /* ext. message area */
	ring_slot_t slots[1];       /* slots */
} ring_buffer_t, *ring_bufptr_t;

typedef struct {
	ring_bufhdr_t hdr;
	char global_buffer[1];        /* global message buffer (large, >16K) */
	char free_map[1];             /* booleans to indicate if the
                                    buffer of same index is free */
	ring_buffer_t rings[1];       /* the ringbuffers */
} ring_buffers_t, *ringbuf_ptr_t;

#define __DEVEL_RINGBUF_RINGS 1
#endif
