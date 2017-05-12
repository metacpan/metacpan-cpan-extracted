#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <sane/sane.h>

#include "const-c.inc"

typedef SANE_Handle Graphics_SANE_Handle;

SV **hash_store(HV* hash, const char *key, SV *val)
{
    return hv_store(hash, key, strlen(key), val, 0);
}

void set_error(int sts)
{
    SV *err;
    err = perl_get_sv("Graphics::SANE::err", 1);
    sv_setiv(err, sts);
    err = perl_get_sv("Graphics::SANE::errstr", 1);
    sv_setpv(err, sane_strstatus(sts));
}

MODULE = Graphics::SANE		PACKAGE = Graphics::SANE		

INCLUDE: const-xs.inc

# init(SANE_Int *version_code, SANE_Auth_Callback authorize)
# void exit()
# get_devices(const SANE_Device ***device_list, SANE_Bool local_only)
# SANE_String_Const sane_strstatus (SANE_Status status)

#Handle Functions:
# open(SANE_String_Const devicename, SANE_HANDLE *handle)
# void close(SANE_Handle handle)
# SANE_Option_Descriptor *get_option_descriptor(SANE_Handle,SANE_Int option)
# sane_control_option (SANE_Handle handle, SANE_Int option,
#		       SANE_Action action, void *value, SANE_Int * info)
# sane_get_parameters (SANE_Handle handle, SANE_Parameters *params)
# sane_start (SANE_Handle handle)
# sane_read (SANE_Handle handle, SANE_Byte *data, SANE_Int max_length,
#	     SANE_Int * length)
# void sane_cancel (SANE_Handle handle)
# sane_set_io_mode (SANE_Handle handle, SANE_Bool non_blocking)
# sane_get_select_fd (SANE_Handle handle, SANE_Int * fd)

SV *
init()
  CODE:
    SANE_Word vers;
    SANE_Status sts;
    int major, minor, build;
    HV *hv = newHV();
    sts = sane_init(&vers, NULL);
    if (sts)
    {
	set_error(sts);
	XSRETURN_EMPTY;
    }
    hash_store(hv, "major", newSViv(SANE_VERSION_MAJOR(vers)));
    hash_store(hv, "minor", newSViv(SANE_VERSION_MINOR(vers)));
    hash_store(hv, "build", newSViv(SANE_VERSION_BUILD(vers)));
    RETVAL = newRV_noinc((SV *) hv);
  OUTPUT:
    RETVAL

void
exit()
  CODE:
    sane_exit();

void
get_devices()
  PPCODE:
    SANE_Status sts;
    const SANE_Device **list,*dev;
    int cnt;
    sts = sane_get_devices(&list,0);
    if (sts)
    {
	set_error(sts);
	XSRETURN_EMPTY;
    }
    for (cnt=0;dev=list[cnt];cnt++)
    {
	HV *hv = newHV();
	hash_store(hv, "name", newSVpv(dev->name, 0));
	hash_store(hv, "vendor", newSVpv(dev->vendor, 0));
	hash_store(hv, "model", newSVpv(dev->model, 0));
	hash_store(hv, "type", newSVpv(dev->type, 0));
	EXTEND(SP, 1);
	PUSHs(newRV_noinc((SV *) hv));
    }

SV *
strstatus(sts)
int sts
  PREINIT:
    SANE_String_Const s;
  CODE:
    s = sane_strstatus(sts);
    RETVAL = newSVpv(s, 0);
  OUTPUT:
    RETVAL

Graphics_SANE_Handle
open(name)
char *name
  CODE:
    SANE_Status sts;
    SANE_Handle handle;
    sts = sane_open(name, &handle);
    if (sts != 0)
    {
	set_error(sts);
	XSRETURN_EMPTY;
    }
    RETVAL = handle;
  OUTPUT:
    RETVAL

MODULE = Graphics::SANE PACKAGE = Graphics::SANE::Handle

void
close(h)
Graphics_SANE_Handle h
  CODE:
    sane_close(h);

SV *
get_option_descriptor(h, idx)
Graphics_SANE_Handle h
int idx
  PREINIT:
    int i;
    const SANE_Option_Descriptor *opt;
    char *p;
    const int *s;
    HV *hv = newHV();
  CODE:
    opt = sane_get_option_descriptor(h, idx);
    hash_store(hv, "index", newSViv(idx));
    hash_store(hv, "name", newSVpv((opt->name ? opt->name : ""), 0));
    hash_store(hv, "title", newSVpv(opt->title, 0));
    hash_store(hv, "desc", newSVpv(opt->desc, 0));
    switch (opt->unit) {
      case SANE_UNIT_NONE:
	p = "none";
	break;
      case SANE_UNIT_PIXEL:
	p = "pixel";
	break;
      case SANE_UNIT_BIT:
	p = "bit";
	break;
      case SANE_UNIT_MM:
	p = "mm";
	break;
      case SANE_UNIT_DPI:
	p = "dpi";
	break;
      case SANE_UNIT_PERCENT:
	p = "percent";
	break;
      case SANE_UNIT_MICROSECOND:
	p = "microsecond";
	break;
      default:
	p = "unknown";
	break;
    }
    hash_store(hv, "unit", newSVpv(p, 0));
    switch (opt->type) {
      case SANE_TYPE_BOOL:
	p = "bool";
	s = &opt->size;
	break;
      case SANE_TYPE_INT:
	p = "int";
	s = &opt->size;
	break;
      case SANE_TYPE_FIXED:
	p = "fixed";
	s = &opt->size;
	break;
      case SANE_TYPE_STRING:
	p = "string";
	s = &opt->size;
	break;
      case SANE_TYPE_BUTTON:
	p = "button";
	s = NULL;
	break;
      case SANE_TYPE_GROUP:
	p = "group";
	s = NULL;
	break;
      default:
	p = "unknown";
	break;
    }
    hash_store(hv, "type", newSVpv(p, 0));
    if (s)
	hash_store(hv, "size", newSViv(*s));
    hash_store(hv, "soft_select",
	     newSViv((opt->cap & SANE_CAP_SOFT_SELECT) != 0));
    hash_store(hv, "hard_select",
	       newSViv((opt->cap & SANE_CAP_HARD_SELECT) != 0));
    hash_store(hv, "emulated", newSViv((opt->cap & SANE_CAP_EMULATED) != 0));
    hash_store(hv, "automatic", newSViv((opt->cap & SANE_CAP_AUTOMATIC) != 0));
    hash_store(hv, "inactive", newSViv((opt->cap & SANE_CAP_INACTIVE) != 0));
    hash_store(hv, "advanced", newSViv((opt->cap & SANE_CAP_ADVANCED) != 0));
    switch (opt->constraint_type) {
      case SANE_CONSTRAINT_NONE:
	p = "none";
	break;
      case SANE_CONSTRAINT_RANGE:
	p = "range";
	if (opt->type == SANE_TYPE_FIXED)
	{
	    hash_store(hv, "min",
		     newSVnv(SANE_UNFIX(opt->constraint.range->min)));
	    hash_store(hv, "max",
		     newSViv(SANE_UNFIX(opt->constraint.range->max)));
	    hash_store(hv, "quant",
		     newSViv(SANE_UNFIX(opt->constraint.range->quant)));
	} else {
	    hash_store(hv, "min", newSViv(opt->constraint.range->min));
	    hash_store(hv, "max", newSViv(opt->constraint.range->max));
	    hash_store(hv, "quant", newSViv(opt->constraint.range->quant));
	}
	break;
      case SANE_CONSTRAINT_WORD_LIST:
	{
	    AV *avl = newAV();
	    const SANE_Word *pp;
	    int cnt, i;
	    pp = opt->constraint.word_list;
	    cnt = *pp++;
	    for (i=0; i<cnt; i++)
	    {
		if (opt->type == SANE_TYPE_FIXED)
		    av_push(avl, newSVnv(SANE_UNFIX(*pp++)));
		else
		    av_push(avl, newSViv(*pp++));
	    }
	    hash_store(hv, "word_list", newRV_noinc((SV *) avl));
	}
	p = "word_list";
	break;
      case SANE_CONSTRAINT_STRING_LIST:
	{
	    AV *avl = newAV();
	    const SANE_String_Const *pp;
	    pp = opt->constraint.string_list;
	    while (*pp)
		av_push(avl, newSVpv(*pp++, 0));
	    hash_store(hv, "string_list", newRV_noinc((SV *) avl));
	}
	p = "string_list";
	break;
      default:
	p = "unknown";
	break;
    }
    hash_store(hv, "constraint", newSVpv(p, 0));
    RETVAL = newRV_noinc((SV *) hv);
  OUTPUT:
    RETVAL

SV *
get_option_value(h, idx)
Graphics_SANE_Handle h
int idx
  PREINIT:
    const SANE_Option_Descriptor *opt;
    SANE_Word w;
    SANE_String s;
    SV *rv;
  CODE:
    opt = sane_get_option_descriptor(h, idx);
    if (!SANE_OPTION_IS_ACTIVE(opt->cap))
        rv = &PL_sv_undef;
    else
    {
	switch (opt->type) {
	  case SANE_TYPE_BOOL:
	    sane_control_option(h, idx, SANE_ACTION_GET_VALUE, &w, 0);
	    rv = newSViv(w!=0);
	    break;
	  case SANE_TYPE_INT:
	    sane_control_option(h, idx, SANE_ACTION_GET_VALUE, &w, 0);
	    rv = newSViv(w);
	    break;
	  case SANE_TYPE_FIXED:
	    sane_control_option(h, idx, SANE_ACTION_GET_VALUE, &w, 0);
	    rv = newSVnv(SANE_UNFIX(w));
	    break;
	  case SANE_TYPE_STRING:
	    s = malloc(opt->size);
	    sane_control_option(h, idx, SANE_ACTION_GET_VALUE, s, 0);
	    rv = newSVpv(s, 0);
	    free(s);
	    break;
	  case SANE_TYPE_BUTTON:
	  case SANE_TYPE_GROUP:
	  default:
	    rv = &PL_sv_undef;
	    break;
        }
    }
    RETVAL = rv;
  OUTPUT:
    RETVAL

SV *
set_option_value(h,idx,v)
Graphics_SANE_Handle h
int idx
SV *v
  PREINIT:
    const SANE_Option_Descriptor *opt;
    SANE_Word w, i;
    SANE_String s;
    SANE_Status sts;
  CODE:
    opt = sane_get_option_descriptor(h, idx);
    switch (opt->type) {
      case SANE_TYPE_BOOL:
      case SANE_TYPE_INT:
	w = SvIVx(v);
	sts = sane_control_option(h, idx, SANE_ACTION_SET_VALUE, &w, &i);
	break;
      case SANE_TYPE_FIXED:
	w = SANE_FIX(SvNVx(v));
	sts = sane_control_option(h, idx, SANE_ACTION_SET_VALUE, &w, &i);
	break;
      case SANE_TYPE_STRING:
	s = SvPV_nolen(v);
	sts = sane_control_option(h, idx, SANE_ACTION_SET_VALUE, s, &i);
	break;
      default:
	sts = -1;
	break;
    }
    if (sts != 0)
    {
	set_error(sts);
	XSRETURN_EMPTY;
    }
    else
    {
	HV *hv = newHV();
	hash_store(hv, "INEXACT", newSViv((i & SANE_INFO_INEXACT) != 0));
	hash_store(hv, "RELOAD_OPTIONS",
		 newSViv((i & SANE_INFO_RELOAD_OPTIONS) != 0));
	hash_store(hv, "RELOAD_PARAMS",
		 newSViv((i & SANE_INFO_RELOAD_PARAMS) != 0));
	RETVAL = newRV_noinc((SV *) hv);
    }
  OUTPUT:
    RETVAL

SV *
get_parameters(h)
Graphics_SANE_Handle h
  PREINIT:
    SANE_Status sts;
    SANE_Parameters p;
    HV *hv = newHV();
    char *s;
  CODE:
    sts = sane_get_parameters(h, &p);
    if (sts)
    {
	set_error(sts);
	XSRETURN_EMPTY;
    }
    switch (p.format) {
      case SANE_FRAME_GRAY:
	s = "gray";
	break;
      case SANE_FRAME_RGB:
	s = "rgb";
	break;
      case SANE_FRAME_RED:
	s = "red";
	break;
      case SANE_FRAME_GREEN:
	s = "green";
	break;
      case SANE_FRAME_BLUE:
	s = "blue";
	break;
      default:
	s = "unknown";
	break;
     }
    hash_store(hv, "format", newSVpv(s, 0));
    hash_store(hv, "last_frame", newSViv(p.last_frame));
    hash_store(hv, "lines", newSViv(p.lines));
    hash_store(hv, "depth", newSViv(p.depth));
    hash_store(hv, "pixels_per_line", newSViv(p.pixels_per_line));
    hash_store(hv, "bytes_per_line", newSViv(p.bytes_per_line));
    RETVAL = newRV_noinc((SV *) hv);
  OUTPUT:
    RETVAL

SV *
start(h)
Graphics_SANE_Handle h
  PREINIT:
    int sts;
  CODE:
    sts = sane_start(h);
    if (sts)
    {
	set_error(sts);
	XSRETURN_EMPTY;
    }
    RETVAL = newSVpv("0e0", 3);
  OUTPUT:
    RETVAL

SV *
read(h, l)
Graphics_SANE_Handle h
int l
  PREINIT:
    int len;
    int sts;
    char *buf;
  CODE:
    buf = malloc(l);
    if (buf == NULL)
    {
	SET_ERROR(errno,errno);
	XSRETURN_EMPTY;
    }
    sts = sane_read(h, buf, l, &len);
    if (sts)
    {
	set_error(sts);
	free(buf);
	XSRETURN_EMPTY;
    }
    RETVAL = newSVpv(buf, len);
    free(buf);
  OUTPUT:
    RETVAL

void
cancel(h)
Graphics_SANE_Handle h
  CODE:
    sane_cancel(h);

