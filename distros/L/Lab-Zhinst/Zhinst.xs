#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <ziAPI.h>

#include "const-c.inc"

typedef ZIConnection Lab__Zhinst;

#define ALLOC_START_SIZE 100

# define ZHINST_UNUSED __attribute__((__unused__))

static void
do_not_warn_unused(void *x ZHINST_UNUSED)
{
}

#define CROAK(arg1, ...) \
    call_va_list(aTHX_ "Carp::croak", arg1, ## __VA_ARGS__, NULL)
#define CARP(arg1, ...) \
    call_va_list(aTHX_ "Carp::carp", arg1, ## __VA_ARGS__, NULL)

static void
call_va_list(pTHX_ char *func, char *arg1, ...)
{
    va_list ap;
    va_start(ap, arg1);
    
    /* See perlcall.  */
    dSP;
    
    ENTER;
    SAVETMPS;
    
    PUSHMARK(SP);
    mXPUSHp(arg1, strlen(arg1));
    while (1) {
        char *arg = va_arg(ap, char *);
        if (arg == NULL)
            break;
        mXPUSHp(arg, strlen(arg));
    }
    PUTBACK;

    call_pv(func, G_DISCARD);

    FREETMPS;
    LEAVE;
}


static void
handle_zi_api_error(pTHX_ ZIResult_enum number, const char *function)
{
  if (number == ZI_INFO_SUCCESS)
    return;

  char *buffer;
  ziAPIGetError(number, &buffer, NULL);
  CROAK("Error in ", function, ": ", buffer);
}


static void
handle_error(pTHX_ ZIConnection conn, ZIResult_enum number, const char *function)
{
  if (number == ZI_INFO_SUCCESS)
    return;

  if (number != ZI_ERROR_GENERAL) {
    handle_zi_api_error(aTHX_ number, function);
  }

  char *buffer = NULL;
  size_t buffer_len = ALLOC_START_SIZE;

  while (1) {
      Renew(buffer, buffer_len, char);
      int rv = ziAPIGetLastError(conn, buffer, buffer_len);

      if (rv == 0)
        break;

      if (rv == ZI_ERROR_CONNECTION)
        CROAK("Invalid connection in error handler");

      if (rv == ZI_ERROR_LENGTH)
        buffer_len = (buffer_len * 3) / 2;
      else
        CROAK("Unknown error returned from ziAPIGetLastError");
  }
  CROAK("Error in ", function, ". Details: ", buffer);
}

static HV *
demod_sample_to_hash(pTHX_ ZIDemodSample *sample)
{
  HV *hash = newHV();
  hv_stores(hash, "timeStamp", newSVuv(sample->timeStamp));
  hv_stores(hash, "x",         newSVnv(sample->x));
  hv_stores(hash, "y",         newSVnv(sample->y));
  hv_stores(hash, "frequency", newSVnv(sample->frequency));
  hv_stores(hash, "phase",     newSVnv(sample->phase));
  hv_stores(hash, "dioBits",   newSVuv(sample->dioBits));
  hv_stores(hash, "trigger",   newSVuv(sample->trigger));
  hv_stores(hash, "auxIn0",    newSVnv(sample->auxIn0));
  hv_stores(hash, "auxIn1",    newSVnv(sample->auxIn1));
  return hash;
}

static HV *
dio_sample_to_hash(pTHX_ ZIDIOSample *sample)
{
  HV *hash = newHV();
  hv_stores(hash, "timeStamp", newSVuv(sample->timeStamp));
  hv_stores(hash, "bits",      newSVuv(sample->bits));
  hv_stores(hash, "reserved",  newSVuv(sample->reserved));
  return hash;
}

static HV *
aux_in_sample_to_hash(pTHX_ ZIAuxInSample *sample)
{
  HV *hash = newHV();
  hv_stores(hash, "timeStamp", newSVuv(sample->timeStamp));
  hv_stores(hash, "ch0",       newSVnv(sample->ch0));
  hv_stores(hash, "ch1",       newSVnv(sample->ch1));
  return hash;
}


MODULE = Lab::Zhinst		PACKAGE = Lab::Zhinst		PREFIX = ziAPI

INCLUDE: const-xs.inc

#####################################################################
#
# Important:
# If a method or function throws, add it to the @modify_methods array in
# Zhinst.pm
#
#####################################################################

Lab::Zhinst
new(const char *class, const char *hostname, U16 port)
CODE:
    do_not_warn_unused((void *) class);
    ZIConnection conn;
    int rv = ziAPIInit(&conn);
    handle_zi_api_error(aTHX_ rv, "ziAPIInit");
    rv = ziAPIConnect(conn, hostname, port);
    handle_zi_api_error(aTHX_ rv, "ziAPIConnect");
    RETVAL = conn;
OUTPUT:
    RETVAL


void
DESTROY(Lab::Zhinst conn)
CODE:
    ziAPIDisconnect(conn);
    ziAPIDestroy(conn);



char *
ListImplementations()
CODE:
    size_t buffer_len = 100;
    char *buffer;
    New(0, buffer, buffer_len, char);
    int rv = ziAPIListImplementations(buffer, buffer_len);
    handle_zi_api_error(aTHX_ rv, "ziAPIListImplementations");
    RETVAL = buffer;
OUTPUT:
    RETVAL
CLEANUP:
    Safefree(buffer);



unsigned
GetConnectionAPILevel(Lab::Zhinst conn)
CODE:
    ZIAPIVersion_enum version;
    int rv = ziAPIGetConnectionAPILevel(conn, &version);
    handle_error(aTHX_ conn, rv, "ziAPIGetConnectionAPILevel");
    RETVAL = version;
OUTPUT:
    RETVAL



char *
ListNodes(Lab::Zhinst conn, const char *path, U32 flags)
CODE:
    char *nodes = NULL;
    size_t nodes_len = ALLOC_START_SIZE;

    while (1) {
        Renew(nodes, nodes_len, char);
        int rv = ziAPIListNodes(conn, path, nodes, nodes_len, flags);
        if (rv == 0)
            break;
        if (rv != ZI_ERROR_LENGTH)
            handle_error(aTHX_ conn, rv, "ziAPIListNodes");

        nodes_len = (nodes_len * 3) / 2;
    }
    RETVAL = nodes;
OUTPUT:
    RETVAL
CLEANUP:
    Safefree(nodes);


double
GetValueD(Lab::Zhinst conn, const char *path)
CODE:
    double result;
    int rv = ziAPIGetValueD(conn, path, &result);
    handle_error(aTHX_ conn, rv, "ziAPIGetValueD");
    RETVAL = result;
OUTPUT:
    RETVAL

IV
GetValueI(Lab::Zhinst conn, const char *path)
CODE:
    IV result;
    int rv = ziAPIGetValueI(conn, path, &result);
    handle_error(aTHX_ conn, rv, "ziAPIGetValueI");
    RETVAL = result;
OUTPUT:
    RETVAL


HV *
GetDemodSample(Lab::Zhinst conn, const char *path)
CODE:
    ZIDemodSample sample;
    int rv = ziAPIGetDemodSample(conn, path, &sample);
    handle_error(aTHX_ conn, rv, "ziAPIGetDemodSample");
    RETVAL = demod_sample_to_hash(aTHX_ &sample);
OUTPUT:
    RETVAL


HV *
GetDIOSample(Lab::Zhinst conn, const char *path)
CODE:
    ZIDIOSample sample;
    int rv = ziAPIGetDIOSample(conn, path, &sample);
    handle_error(aTHX_ conn, rv, "ziAPIGetDIOSample");
    RETVAL = dio_sample_to_hash(aTHX_ &sample);
OUTPUT:
    RETVAL


HV *
GetAuxInSample(Lab::Zhinst conn, const char *path)
CODE:
    ZIAuxInSample sample;
    int rv = ziAPIGetAuxInSample(conn, path, &sample);
    handle_error(aTHX_ conn, rv, "ziAPIGetAuxInSample");
    RETVAL = aux_in_sample_to_hash(aTHX_ &sample);
OUTPUT:
    RETVAL



SV *
GetValueB(Lab::Zhinst conn, const char *path)
CODE:
    char *result = NULL;
    size_t result_avail = ALLOC_START_SIZE;
    unsigned length;

    while (1) {
        Renew(result, result_avail, char);
        int rv = ziAPIGetValueB(conn, path, (unsigned char*) result, &length,
                                result_avail);
        if (rv == 0)
            break;
        if (rv != ZI_ERROR_LENGTH)
          {
            Safefree(result);
            handle_error(aTHX_ conn, rv, "ziAPIGetValueB");
          }
        result_avail = (result_avail * 3) / 2;
    }
    RETVAL = newSVpvn(result, length);
    Safefree(result);
OUTPUT:
    RETVAL


void
SetValueD(Lab::Zhinst conn, const char *path, double value)
CODE:
    int rv = ziAPISetValueD(conn, path, value);
    handle_error(aTHX_ conn, rv, "ziAPISetValueD");

void
SetValueI(Lab::Zhinst conn, const char *path, IV value)
CODE:
    int rv = ziAPISetValueI(conn, path, value);
    handle_error(aTHX_ conn, rv, "ziAPISetValueI");

void
SetValueB(Lab::Zhinst conn, const char *path, SV *value)
CODE:
    if (!SvOK(value)) {
       croak("value is not a valid scalar");
    }
    char *bytes;
    STRLEN len;
    bytes = SvPV(value, len);
    int rv = ziAPISetValueB(conn, path, (unsigned char *) bytes, len);
    handle_error(aTHX_ conn, rv, "ziAPISetValueB");


double
SyncSetValueD(Lab::Zhinst conn, const char *path, double value)
CODE:
    double result = value;
    int rv = ziAPISyncSetValueD(conn, path, &result);
    handle_error(aTHX_ conn, rv, "ziAPISyncSetValueD");
    RETVAL = result;
OUTPUT:
    RETVAL

IV
SyncSetValueI(Lab::Zhinst conn, const char *path, IV value)
CODE:
    IV result = value;
    int rv = ziAPISyncSetValueI(conn, path, &result);
    handle_error(aTHX_ conn, rv, "ziAPISyncSetValueI");
    RETVAL = result;
OUTPUT:
    RETVAL

SV *
SyncSetValueB(Lab::Zhinst conn, const char *path, SV *value)
CODE:
    if (!SvOK(value)) {
       croak("value is not a valid scalar");
    }
    char *original;
    STRLEN len;
    original = SvPV(value, len);

    char *new_string;
    New(0, new_string, len, char);
    Copy(original, new_string, len, char);
    int rv = ziAPISyncSetValueB(conn,  path, (uint8_t *) new_string,
                                (uint32_t *) &len, len);
    handle_error(aTHX_ conn, rv, "ziAPISyncSetValueB");
    RETVAL = newSVpvn(new_string, len);
    Safefree(new_string);
OUTPUT:
    RETVAL


void
Sync(Lab::Zhinst conn)
CODE:
    int rv = ziAPISync(conn);
    handle_error(aTHX_ conn, rv, "ziAPISync");

void
EchoDevice(Lab::Zhinst conn, const char *device_serial)
CODE:
    int rv = ziAPIEchoDevice(conn, device_serial);
    handle_error(aTHX_ conn, rv, "ziAPIEchoDevice");

void
ziAPISetDebugLevel(I32 level)

void
ziAPIWriteDebugLog(I32 level, const char *message)


const char *
DiscoveryFind(Lab::Zhinst conn, const char *device_address)
CODE:
    const char *device_id;
    int rv = ziAPIDiscoveryFind(conn, device_address, &device_id);
    handle_error(aTHX_ conn, rv, "ziAPIDiscoveryFind");
    RETVAL = device_id;
OUTPUT:
    RETVAL


const char *
DiscoveryGet(Lab::Zhinst conn, const char *device_id)
CODE:
    const char *props_json;
    int rv = ziAPIDiscoveryGet(conn, device_id, &props_json);
    handle_error(aTHX_ conn, rv, "ziAPIDiscoveryGet");
    RETVAL = props_json;
OUTPUT:
    RETVAL
