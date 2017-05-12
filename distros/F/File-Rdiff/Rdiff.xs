#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "librsync.h"

/* try to be compatible with older perls */
/* SvPV_nolen() macro first defined in 5.005_55 */
/* this is slow, not threadsafe, but works */
#include "patchlevel.h"
#if (PATCHLEVEL == 4) || ((PATCHLEVEL == 5) && (SUBVERSION < 55))
static STRLEN nolen_na;
# define SvPV_nolen(sv) SvPV ((sv), nolen_na)
#endif

static SV *trace_cb_sv;

typedef rs_stats_t *	File__Rdiff__Stats;
typedef rs_signature_t *File__Rdiff__Signature;

typedef struct File__Rdiff__Buffers {
  rs_buffers_t rs;
  SV *in;
  STRLEN in_ofs;
  SV *out;
  STRLEN outsize;
} *File__Rdiff__Buffers;

typedef struct File__Rdiff__Job {
  rs_job_t *rs;
  SV *sig;
} *File__Rdiff__Job;

static SV *new_sig (File__Rdiff__Signature sig)
{
  SV *sv = NEWSV (0, 0);
  sv_setref_pv (sv, "File::Rdiff::Signature", (void *)sig);

  return sv;
}

static File__Rdiff__Signature
old_sig (SV *sv)
{
  if (sv_derived_from(sv, "File::Rdiff::Signature"))
    {
      IV tmp = SvIV((SV*)SvRV(sv));
      return INT2PTR(rs_signature_t *,tmp);
    }
  else
    Perl_croak(aTHX_ "Object of type File::Rdiff::Signature expected");
}

static void
trace_cb (int level, char const *msg)
{
  if (SvOK (trace_cb_sv))
    {
      dSP;
      
      SAVETMPS; PUSHMARK(SP); EXTEND(SP,2);

      PUSHs(sv_2mortal(newSViv(level)));
      PUSHs(sv_2mortal(newSVpv(msg,0)));

      PUTBACK; perl_call_sv (trace_cb_sv, G_VOID|G_DISCARD); SPAGAIN;

      PUTBACK; FREETMPS;
    }
  else
    rs_trace_stderr (level, msg);
}

/**
 * \brief Callback used to retrieve parts of the basis file.
 *
 * \param pos Position where copying should begin.
 *
 * \param len On input, the amount of data that should be retrieved.
 * Updated to show how much is actually available.
 *
 * \param buf On input, a buffer of at least \p *len bytes.  May be
 * updated to point to a buffer allocated by the callback if it
 * prefers.
 */
static rs_result
copy_cb (void *cb, rs_long_t pos, size_t *len, void **buf)
{
  dSP;
  SV *rbuf;
  
  PUSHMARK(SP); EXTEND(SP,2);

  PUSHs(sv_2mortal(newSViv(pos)));
  PUSHs(sv_2mortal(newSViv(*len)));

  PUTBACK; perl_call_sv ((SV *)cb, G_SCALAR); SPAGAIN;

  rbuf = POPs;

  PUTBACK;

  if (SvIOKp (rbuf) && !SvPOKp (rbuf))
    {
      /* assume error code */
      return SvIVX (rbuf);
    }
  else
    {
      /* assume data. we are not copying because we assume
       * that the data will be consumed before the next FREETMPS,
       * which should be just outside ther rs_job_iter call.
       */
      STRLEN slen;

      *buf = SvPV (rbuf, slen);
      *len = slen;

      return RS_DONE;
    }
}

MODULE = File::Rdiff		PACKAGE = File::Rdiff

PROTOTYPES: ENABLE

BOOT:
{
	HV * stash = gv_stashpv ("File::Rdiff", 0);

        trace_cb_sv = newSVsv (&PL_sv_undef);

        rs_trace_to (trace_cb);
        rs_trace_set_level (RS_LOG_WARNING);

	newCONSTSUB (stash, "LIBRSYNC_VERSION",  newSVpv (rs_librsync_version, 0));

	newCONSTSUB (stash, "LOG_EMERG", newSViv (RS_LOG_EMERG));
	newCONSTSUB (stash, "LOG_ALERT", newSViv (RS_LOG_ALERT));
	newCONSTSUB (stash, "LOG_CRIT", newSViv (RS_LOG_CRIT));
	newCONSTSUB (stash, "LOG_ERR", newSViv (RS_LOG_ERR));
	newCONSTSUB (stash, "LOG_WARNING", newSViv (RS_LOG_WARNING));
	newCONSTSUB (stash, "LOG_NOTICE", newSViv (RS_LOG_NOTICE));
	newCONSTSUB (stash, "LOG_INFO", newSViv (RS_LOG_INFO));
	newCONSTSUB (stash, "LOG_DEBUG", newSViv (RS_LOG_DEBUG));
	newCONSTSUB (stash, "DONE", newSViv (RS_DONE));
	newCONSTSUB (stash, "BLOCKED", newSViv (RS_BLOCKED));
	newCONSTSUB (stash, "RUNNING", newSViv (RS_RUNNING));
	newCONSTSUB (stash, "TEST_SKIPPED", newSViv (RS_TEST_SKIPPED));
	newCONSTSUB (stash, "IO_ERROR", newSViv (RS_IO_ERROR));
	newCONSTSUB (stash, "SYNTAX_ERROR", newSViv (RS_SYNTAX_ERROR));
	newCONSTSUB (stash, "MEM_ERROR", newSViv (RS_MEM_ERROR));
	newCONSTSUB (stash, "INPUT_ENDED", newSViv (RS_INPUT_ENDED));
	newCONSTSUB (stash, "BAD_MAGIC", newSViv (RS_BAD_MAGIC));
	newCONSTSUB (stash, "UNIMPLEMENTED", newSViv (RS_UNIMPLEMENTED));
	newCONSTSUB (stash, "CORRUPT", newSViv (RS_CORRUPT));
	newCONSTSUB (stash, "INTERNAL_ERROR", newSViv (RS_INTERNAL_ERROR));
	newCONSTSUB (stash, "PARAM_ERROR", newSViv (RS_PARAM_ERROR));
}

int
trace_level(level)
	int	level
        PROTOTYPE: ;$
        CODE:
        static int oldlevel = RS_LOG_WARNING; /* see BOOT: */

        RETVAL = oldlevel;
        if (items)
          {
            oldlevel = level;
            rs_trace_set_level (level);
          }
	OUTPUT:
        RETVAL

SV *
trace_to(cb)
	SV *	cb
        PROTOTYPE: ;&
        CODE:
        RETVAL = sv_2mortal (newSVsv (trace_cb_sv));
        if (items)
          sv_setsv (trace_cb_sv, cb);
	OUTPUT:
        RETVAL
  
void
supports_trace()
	PROTOTYPE:
	CODE:
        if (rs_supports_trace())
          XSRETURN_YES;
        else
          XSRETURN_NO;

SV *
strerror (resultcode)
	int	resultcode
        CODE:
        RETVAL = newSVpv (rs_strerror (resultcode), 0);
	OUTPUT:
        RETVAL

MODULE = File::Rdiff		PACKAGE = File::Rdiff::Signature

int
build_hash_table(self)
	File::Rdiff::Signature	self
        CODE:
        RETVAL = rs_build_hash_table (self);
	OUTPUT:
        RETVAL

void
DESTROY(self)
	File::Rdiff::Signature	self
        CODE:
        rs_free_sumset (self);

void
dump(self)
	File::Rdiff::Signature	self
        CODE:
        rs_sumset_dump (self);

MODULE = File::Rdiff		PACKAGE = File::Rdiff::Buffers

File::Rdiff::Buffers
new(class, outsize = 65536)
        SV *	class
        STRLEN	outsize
        PROTOTYPE: $;$$
        CODE:
        Newz (0, RETVAL, 1, struct File__Rdiff__Buffers);
        RETVAL->outsize = outsize;
        OUTPUT:
        RETVAL

void
DESTROY(self)
	File::Rdiff::Buffers	self
        CODE:
        if (self->in ) SvREFCNT_dec (self->in );
        if (self->out) SvREFCNT_dec (self->out);
        Safefree (self);

void
in(self,in)
	File::Rdiff::Buffers	self
        SV *	in
        CODE:
        if (self->in)
          SvREFCNT_dec (self->in);
        self->in = SvREFCNT_inc (in);
        self->in_ofs = 0;

void
eof(self)
	File::Rdiff::Buffers	self
        CODE:
        self->rs.eof_in = 1;

SV *
out(self)
	File::Rdiff::Buffers	self
        CODE:
        RETVAL = self->out;
        self->out = 0;
        OUTPUT:
        RETVAL

int
avail_in(self)
	File::Rdiff::Buffers	self
        CODE:
        RETVAL = self->in ? SvCUR (self->in) - self->in_ofs
                          : self->rs.eof_in ? -1
                                            : 0;
        OUTPUT:
        RETVAL

int
avail_out(self)
	File::Rdiff::Buffers	self
        CODE:
        RETVAL = self->outsize - (self->out ? SvCUR (self->out) : 0);
        OUTPUT:
        RETVAL

int
size(self)
	File::Rdiff::Buffers	self
        CODE:
        RETVAL = self->out ? SvCUR (self->out) : 0;
        OUTPUT:
        RETVAL

MODULE = File::Rdiff		PACKAGE = File::Rdiff::Job

File::Rdiff::Job
new_sig(class, new_block_len = RS_DEFAULT_BLOCK_LEN, strong_sum_len = RS_DEFAULT_STRONG_LEN)
        SV *	class
        size_t	new_block_len
        size_t	strong_sum_len
        PROTOTYPE: $;$$
        CODE:
        Newz (0, RETVAL, 1, struct File__Rdiff__Job);
        RETVAL->rs = rs_sig_begin (new_block_len, strong_sum_len);
        OUTPUT:
        RETVAL

File::Rdiff::Job
new_loadsig(class)
	SV *	class
        CODE:
        rs_signature_t *sig;
        Newz (0, RETVAL, 1, struct File__Rdiff__Job);
        RETVAL->rs = rs_loadsig_begin (&sig);
        RETVAL->sig = new_sig (sig);
	OUTPUT:
        RETVAL

File::Rdiff::Job
new_delta(class, signature)
	SV *	class
	SV *	signature
        CODE:
        Newz (0, RETVAL, 1, struct File__Rdiff__Job);
        RETVAL->rs = rs_delta_begin (old_sig (signature));
        RETVAL->sig = newSVsv (signature);
	OUTPUT:
        RETVAL

File::Rdiff::Job
new_patch(class, cb_or_fh)
	SV *	class
	SV *	cb_or_fh
        CODE:
        rs_copy_cb *cb;
        void *cb_arg;

        if (SvROK (cb_or_fh) && SvTYPE (SvRV (cb_or_fh)) == SVt_PVCV)
          {
            cb = copy_cb;
            cb_arg = (void *)cb_or_fh;
          }
        else
          {
            cb = rs_file_copy_cb;
            cb_arg = (void *)IoIFP (sv_2io (cb_or_fh));
          }
        
        Newz (0, RETVAL, 1, struct File__Rdiff__Job);
        RETVAL->rs = rs_patch_begin (cb, cb_arg);
	OUTPUT:
        RETVAL

void
DESTROY(self)
	File::Rdiff::Job	self
        CODE:
        if (self->sig)
          SvREFCNT_dec (self->sig);
        rs_job_free (self->rs);
        Safefree (self);

SV *
signature(self)
	File::Rdiff::Job	self
        CODE:
        RETVAL = SvREFCNT_inc (self->sig);
	OUTPUT:
        RETVAL

int
iter(self,buffers)
	File::Rdiff::Job	self
        File::Rdiff::Buffers	buffers
        CODE:
{
        STRLEN in_len;

        if (buffers->in)
          {
            buffers->rs.next_in = SvPV (buffers->in, in_len) + buffers->in_ofs;
            buffers->rs.avail_in = in_len - buffers->in_ofs;
          }
        else
          {
            buffers->rs.next_in = 0;
            buffers->rs.avail_in = 0;
          }

        if (buffers->outsize)
          {
            if (!buffers->out)
              {
                buffers->out = NEWSV (0, buffers->outsize);
                SvPOK_on (buffers->out);
              }

            buffers->rs.next_out = SvEND (buffers->out);
            buffers->rs.avail_out = buffers->outsize - SvCUR (buffers->out);
          }
        else
          {
            buffers->rs.next_out = 0;
            buffers->rs.avail_out = 0;
          }

        RETVAL = rs_job_iter (self->rs, &buffers->rs);

        buffers->in_ofs = in_len - buffers->rs.avail_in;

        if (buffers->out)
          SvCUR_set (buffers->out, buffers->outsize - buffers->rs.avail_out);
}
	OUTPUT:
        RETVAL

# void     rs_hexify(char *to_buf, void const *from_buf, int from_len);
# size_t rs_unbase64(char *s);
# void rs_base64(unsigned char const *buf, int n, char *out);
#  * \sa rs_format_stats(), rs_log_stats()
#  */
# typedef struct rs_stats {
#     char const     *op;     /**< Human-readable name of current
#                              * operation.  For example, "delta". */
#     int             lit_cmds;   /**< Number of literal commands. */
#     rs_long_t       lit_bytes;  /**< Number of literal bytes. */
#     rs_long_t       lit_cmdbytes; /**< Number of bytes used in literal
#                                    * command headers. */
#         
#     rs_long_t       copy_cmds, copy_bytes, copy_cmdbytes;
#     rs_long_t       sig_cmds, sig_bytes;
#     int             false_matches;
# 
#     rs_long_t       sig_blocks; /**< Number of blocks described by the
#                                    signature. */
# 
#     size_t          block_len;
# 
#     rs_long_t       in_bytes;   /**< Total bytes read from input. */
#     rs_long_t       out_bytes;  /**< Total bytes written to output. */
# } rs_stats_t;
# 
# char *rs_format_stats(rs_stats_t const *, char *, size_t);
# 
# int rs_log_stats(rs_stats_t const *stats);
# 
# const rs_stats_t * rs_job_statistics(rs_job_t *job);
# 
# int             rs_accum_value(rs_job_t *, char *sum, size_t sum_len);
# 

MODULE = File::Rdiff		PACKAGE = File::Rdiff

#ifndef RSYNC_NO_STDIO_INTERFACE

int
sig_file(old_file, sig_file, block_len = RS_DEFAULT_BLOCK_LEN, strong_len = RS_DEFAULT_STRONG_LEN)
	FILE *	old_file
        FILE *	sig_file
        size_t	block_len
        size_t	strong_len
        PROTOTYPE: $$;$$
        CODE:
        RETVAL = rs_sig_file(old_file, sig_file, block_len, strong_len, 0); 
        OUTPUT:
        RETVAL

File::Rdiff::Signature
loadsig_file(file)
	FILE *	file
	CODE:
        rs_result r = rs_loadsig_file(file, &RETVAL, 0);
        if (r != RS_DONE)
          XSRETURN_IV (r);
        OUTPUT:
        RETVAL

int
delta_file(signature, new_file, delta_file)
  	File::Rdiff::Signature	signature
	FILE *	new_file
        FILE *	delta_file
        CODE:
        RETVAL = rs_delta_file (signature, new_file, delta_file, 0);
        OUTPUT:
        RETVAL

int
patch_file(basis_file, delta_file, new_file)
	FILE *	basis_file
        FILE *	delta_file
        FILE *	new_file
        CODE:
        RETVAL = rs_patch_file (basis_file, delta_file, new_file, 0);
        OUTPUT:
        RETVAL

#endif






