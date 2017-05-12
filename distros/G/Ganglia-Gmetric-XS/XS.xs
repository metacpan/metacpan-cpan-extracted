#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#include "ppport.h"

#include "ganglia.h"

#ifdef GANGLIA30
#  define Ganglia_metric          Ganglia_gmetric
#  define Ganglia_metric_create   Ganglia_gmetric_create
#  define Ganglia_metric_set      Ganglia_gmetric_set
#  define Ganglia_metric_send     Ganglia_gmetric_send
#  define Ganglia_metric_destroy  Ganglia_gmetric_destroy
#endif

#define XS_STATE(type, x) \
  INT2PTR(type, SvROK(x) ? SvIV(SvRV(x)) : SvIV(x))

typedef struct ganglia_t {
  Ganglia_pool              context;
  Ganglia_metric            gmetric;
  Ganglia_udp_send_channels channel;
  Ganglia_gmond_config      gconfig;
  char*                     spoof;
} ganglia;

MODULE = Ganglia::Gmetric::XS    PACKAGE = Ganglia::Gmetric::XS

SV *
_ganglia_initialize(class, config, spoof)
    SV   *class;
    char *config;
    char *spoof;
  PREINIT:
    ganglia *gang;
    SV *sv;
  CODE:
    if (SvROK(class))
      croak("Cannot call new() on a reference");
    Newxz(gang, 1, ganglia);
#ifdef DIAG
    PerlIO_printf(PerlIO_stderr(), "config:%s\n", config);
#endif

    gang->context = Ganglia_pool_create(NULL);
    if (! gang->context)
      croak("failed to Ganglia_pool_create");

    gang->gconfig = Ganglia_gmond_config_create(config, 0);
    if (! gang->gconfig)
      croak("failed to Ganglia_gmond_config_create");

    gang->channel = Ganglia_udp_send_channels_create(gang->context, gang->gconfig);
    if (! gang->channel)
      croak("failed to Ganglia_udp_send_channels_create");

    gang->spoof = spoof;

    RETVAL = sv_setref_iv(newSV(0), SvPV_nolen(class), PTR2IV(gang));
  OUTPUT:
    RETVAL

int
_ganglia_send(self, name, value, type, units, group, desc, title, slope, tmax, dmax, spoof)
    SV   *self;
    char *name;
    char *value;
    char *type;
    char *units;
    char *group;
    char *desc;
    char *title;
    unsigned int slope;
    unsigned int tmax;
    unsigned int dmax;
    char *spoof;
  PREINIT:
    ganglia *gang;
    char *spf;
  CODE:
    int   r;
    gang = XS_STATE(ganglia *, self);

    gang->gmetric = Ganglia_metric_create(gang->context);
    if (! gang->gmetric)
      croak("failed to Ganglia_metric_create");
#ifdef DIAG
    PerlIO_printf(PerlIO_stderr(), "send:%s=%s\n", name,value);
#endif
    r = Ganglia_metric_set(gang->gmetric, name, value, type, units, slope, tmax, dmax);
    switch(r) {
    case 1:
      croak("gmetric parameters invalid. exiting.\n");
    case 2:
      croak("one of your parameters has an invalid character '\"'. exiting.\n");
    case 3:
      croak("the type parameter \"%s\" is not a valid type. exiting.\n", type);
    case 4:
      croak("the value parameter \"%s\" does not represent a number. exiting.\n", value);
    }

    if (*group != '\0')
        Ganglia_metadata_add(gang->gmetric, "GROUP", group);
    if (*desc  != '\0')
        Ganglia_metadata_add(gang->gmetric, "DESC", desc);
    if (*title != '\0')
        Ganglia_metadata_add(gang->gmetric, "TITLE", title);

    if (gang->spoof)
        spf = gang->spoof;
    if (spoof && *spoof != '\0')
        spf = spoof;
    if (spf)
        Ganglia_metadata_add(gang->gmetric, SPOOF_HOST, spf);

    RETVAL = ! Ganglia_metric_send(gang->gmetric, gang->channel);
    Ganglia_metric_destroy(gang->gmetric);
  OUTPUT:
    RETVAL

int
_ganglia_heartbeat(self, spoof)
    SV   *self;
    char *spoof;
  PREINIT:
    ganglia *gang;
  CODE:
    int   r;
    char *spf;
    gang = XS_STATE(ganglia *, self);

    gang->gmetric = Ganglia_metric_create(gang->context);
    if (! gang->gmetric)
      croak("failed to Ganglia_metric_create");
#ifdef DIAG
    PerlIO_printf(PerlIO_stderr(), "heartbeat\n");
#endif
    r = Ganglia_metric_set(gang->gmetric, "heartbeat", "0", "uint32", "", 0, 0, 0);
    switch(r) {
    case 1:
      croak("gmetric parameters invalid. exiting.\n");
    case 2:
      croak("one of your parameters has an invalid character '\"'. exiting.\n");
    }
    if (gang->spoof)
        spf = gang->spoof;
    if (spoof && *spoof != '\0')
        spf = spoof;
    if (spf)
      Ganglia_metadata_add(gang->gmetric, SPOOF_HOST, spf);
    Ganglia_metadata_add(gang->gmetric, SPOOF_HEARTBEAT, "yes");
#ifdef DIAG
    PerlIO_printf(PerlIO_stderr(), "spoof: %s\n", spoof);
#endif
    RETVAL = ! Ganglia_metric_send(gang->gmetric, gang->channel);
    Ganglia_metric_destroy(gang->gmetric);
  OUTPUT:
    RETVAL

void
DESTROY(self)
    SV *self;
  PREINIT:
    ganglia *gang;
  CODE:
#ifdef DIAG
    PerlIO_printf(PerlIO_stderr(), "DESTROY: called\n" );
    PerlIO_printf(PerlIO_stderr(), "REFCNT:self=%d\n", SvREFCNT(self));
#endif
    gang = XS_STATE(ganglia *, self);
    if (gang == NULL) {
#ifdef DIAG
      PerlIO_printf(PerlIO_stderr(), "DESTROY: gang is null\n" );
#endif
      return;
    }

    if (gang->context != NULL)
      Ganglia_pool_destroy(gang->context);
    cfg_free(gang->gconfig);
    Safefree(gang);
#ifdef DIAG
    PerlIO_printf(PerlIO_stderr(), "DESTROY: done\n" );
#endif
