#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <seccomp.h>
#include <stdio.h>

#include "const-c.inc"

#define die_check_errno if(RETVAL < 0) \
		croak("Failed with error %d (%s)\n", RETVAL, strerror(RETVAL))

#define die_if_error if(RETVAL == __NR_SCMP_ERROR) \
		croak("Failed to resolve system call %s", name);

MODULE = Linux::Seccomp		PACKAGE = Linux::Seccomp		PREFIX = seccomp_

INCLUDE: const-xs.inc
PROTOTYPES: ENABLE

struct scmp_arg_cmp
seccomp_make_arg_cmp(arg, op, datum_a, datum_b = (scmp_datum_t) 0)
	unsigned int arg;
	enum scmp_compare op;
	scmp_datum_t datum_a;
	scmp_datum_t datum_b;
PROTOTYPE: DISABLE
CODE:
  RETVAL = SCMP_CMP(arg, op, datum_a, datum_b);
OUTPUT:
  RETVAL

U32 SCMP_ACT_ERRNO(I16 errno1)

U32 SCMP_ACT_TRACE(I16 msg_num)


NO_OUTPUT int
seccomp_arch_add(ctx, arch_token)
	scmp_filter_ctx ctx
	U32             arch_token
POSTCALL:
  die_check_errno;

bool
seccomp_arch_exist(ctx, arch_token)
	scmp_filter_ctx ctx
	U32             arch_token
PREINIT:
  int ret;
CODE:
  ret = seccomp_arch_exist(ctx, arch_token);
  if(ret != -EEXIST)
    die_check_errno;
  RETVAL = (ret != -EEXIST);
OUTPUT:
  RETVAL

U32
seccomp_arch_native()

NO_OUTPUT int
seccomp_arch_remove(ctx, arch_token)
	scmp_filter_ctx ctx
	U32             arch_token
POSTCALL:
  die_check_errno;

U32
seccomp_arch_resolve_name(arch_name)
	const char *arch_name
POSTCALL:
  die_check_errno;

NO_OUTPUT int
seccomp_attr_get(ctx, attr, OUTLIST value)
	scmp_filter_ctx       ctx
	enum scmp_filter_attr attr
	U32                   value
POSTCALL:
  die_check_errno;

NO_OUTPUT int
seccomp_attr_set(ctx, attr, value)
	scmp_filter_ctx       ctx
	enum scmp_filter_attr attr
	U32                   value
POSTCALL:
  die_check_errno;

NO_OUTPUT int
seccomp_export_bpf(ctx, fd)
	scmp_filter_ctx ctx
	FILE           *fd
INTERFACE:
  seccomp_export_bpf seccomp_export_pfc
C_ARGS:
  ctx, fileno(fd)
POSTCALL:
  die_check_errno;

scmp_filter_ctx
seccomp_init(def_action)
	U32      def_action

int
seccomp_load(ctx)
	scmp_filter_ctx ctx

NO_OUTPUT int
seccomp_merge(ctx_dst, ctx_src)
	scmp_filter_ctx ctx_dst
	scmp_filter_ctx ctx_src
POSTCALL:
  die_check_errno;

void
seccomp_release(ctx)
	scmp_filter_ctx  ctx

NO_OUTPUT int
seccomp_reset(ctx, def_action)
	scmp_filter_ctx ctx
	U32             def_action
POSTCALL:
  die_check_errno;

NO_OUTPUT int
seccomp_rule_add_array(ctx, action, syscall, args)
	scmp_filter_ctx ctx
	U32             action
	int             syscall
	AV*             args
PREINIT:
  unsigned int arg_cnt, i;
  struct scmp_arg_cmp *arg_array;
  SV **sv;
  char *intermediate;
INIT:
  arg_cnt = av_len(args) + 1;
  Newx(arg_array, arg_cnt, struct scmp_arg_cmp);
  for(i = 0 ; i < arg_cnt ; i++){
    sv = av_fetch(args, i, 0);
    if(sv == NULL)
      croak("Bad input array (av_fetch returned NULL)");
    arg_array[i] = *((struct scmp_arg_cmp*) SvPV_nolen(*sv));
  }
C_ARGS:
  ctx, action, syscall, arg_cnt, arg_array
INTERFACE:
  seccomp_rule_add_array seccomp_rule_add_exact_array
POSTCALL:
  Safefree(arg_array);
  die_check_errno;


NO_OUTPUT int
seccomp_syscall_priority(ctx, syscall, priority)
	scmp_filter_ctx ctx
	int             syscall
	I8              priority
POSTCALL:
  die_check_errno;

int
seccomp_syscall_resolve_name(name)
	const char *name
POSTCALL:
  die_if_error;

int
seccomp_syscall_resolve_name_arch(arch_token, name)
	U32         arch_token
	const char *name
POSTCALL:
  die_if_error;

int
seccomp_syscall_resolve_name_rewrite(arch_token, name)
	U32         arch_token
	const char *name
POSTCALL:
  die_if_error;

char *
seccomp_syscall_resolve_num_arch(arch_token, num)
	U32      arch_token
	int      num

AV*
seccomp_version()
  PREINIT:
    const struct scmp_version* ver;
  CODE:
    ver = seccomp_version();
    if(ver == NULL)
        croak("seccomp_version() returned NULL");
    RETVAL = newAV();
    av_push(RETVAL, newSViv(ver->major));
    av_push(RETVAL, newSViv(ver->minor));
    av_push(RETVAL, newSViv(ver->micro));
  OUTPUT:
    RETVAL
