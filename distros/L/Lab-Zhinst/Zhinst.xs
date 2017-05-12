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

#define HANDLE_ERROR(conn, func, ...) \
  handle_error(conn, func(conn, ## __VA_ARGS__), #func)

#define HANDLE_ZI_API_ERROR(func, ...) \
  handle_zi_api_error(func(__VA_ARGS__), #func)

static void
handle_zi_api_error(ZIResult_enum number, const char *function)
{
  if (number == ZI_INFO_SUCCESS)
    return;

  char *buffer;
  ziAPIGetError(number, &buffer, NULL);
  croak("Error in %s: %s", function, buffer);
}


static void
handle_error(ZIConnection conn, ZIResult_enum number, const char *function)
{
  if (number == ZI_INFO_SUCCESS)
    return;

  if (number != ZI_ERROR_GENERAL) {
    handle_zi_api_error(number, function);
  }

  char *buffer = NULL;
  size_t buffer_len = ALLOC_START_SIZE;

  while (1) {
      Renew(buffer, buffer_len, char);
      int rv = ziAPIGetLastError(conn, buffer, buffer_len);

      if (rv == 0)
        break;

      if (rv == ZI_ERROR_CONNECTION)
        croak("Invalid connection in error handler");

      if (rv == ZI_ERROR_LENGTH)
        buffer_len = (buffer_len * 3) / 2;
      else
        croak("Unknown error %d returned from ziAPIGetLastError", rv);
  }

  croak("Error in %s. Details: %s", function, buffer);
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


Lab::Zhinst
new(const char *class, const char *hostname, U16 port)
CODE:
    do_not_warn_unused((void *) class);
    ZIConnection conn;
    HANDLE_ZI_API_ERROR(ziAPIInit, &conn);
    HANDLE_ZI_API_ERROR(ziAPIConnect, conn, hostname, port);
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
    HANDLE_ZI_API_ERROR(ziAPIListImplementations, buffer, buffer_len);
    RETVAL = buffer;
OUTPUT:
    RETVAL
CLEANUP:
    Safefree(buffer);



unsigned
GetConnectionAPILevel(Lab::Zhinst conn)
CODE:
    ZIAPIVersion_enum version;
    HANDLE_ERROR(conn, ziAPIGetConnectionAPILevel, &version);
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
            handle_error(conn, rv, "ziAPIListNodes");

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
    HANDLE_ERROR(conn, ziAPIGetValueD, path, &result);
    RETVAL = result;
OUTPUT:
    RETVAL

IV
GetValueI(Lab::Zhinst conn, const char *path)
CODE:
    IV result;
    HANDLE_ERROR(conn, ziAPIGetValueI, path, &result);
    RETVAL = result;
OUTPUT:
    RETVAL


HV *
GetDemodSample(Lab::Zhinst conn, const char *path)
CODE:
    ZIDemodSample sample;
    HANDLE_ERROR(conn, ziAPIGetDemodSample, path, &sample);
    RETVAL = demod_sample_to_hash(aTHX_ &sample);
OUTPUT:
    RETVAL


HV *
GetDIOSample(Lab::Zhinst conn, const char *path)
CODE:
    ZIDIOSample sample;
    HANDLE_ERROR(conn, ziAPIGetDIOSample, path, &sample);
    RETVAL = dio_sample_to_hash(aTHX_ &sample);
OUTPUT:
    RETVAL


HV *
GetAuxInSample(Lab::Zhinst conn, const char *path)
CODE:
    ZIAuxInSample sample;
    HANDLE_ERROR(conn, ziAPIGetAuxInSample, path, &sample);
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
            handle_error(conn, rv, "ziAPIGetValueB");

        result_avail = (result_avail * 3) / 2;
    }
    RETVAL = newSVpvn(result, length);
    Safefree(result);
OUTPUT:
    RETVAL


void
SetValueD(Lab::Zhinst conn, const char *path, double value)
CODE:
    HANDLE_ERROR(conn, ziAPISetValueD, path, value);

void
SetValueI(Lab::Zhinst conn, const char *path, IV value)
CODE:
    HANDLE_ERROR(conn, ziAPISetValueI, path, value);


void
SetValueB(Lab::Zhinst conn, const char *path, SV *value)
CODE:
    if (!SvOK(value)) {
       croak("value is not a valid scalar");
    }
    char *bytes;
    STRLEN len;
    bytes = SvPV(value, len);
    HANDLE_ERROR(conn, ziAPISetValueB, path, (unsigned char *) bytes, len);


double
SyncSetValueD(Lab::Zhinst conn, const char *path, double value)
CODE:
    double result = value;
    HANDLE_ERROR(conn, ziAPISyncSetValueD, path, &result);
    RETVAL = result;
OUTPUT:
    RETVAL

IV
SyncSetValueI(Lab::Zhinst conn, const char *path, IV value)
CODE:
    IV result = value;
    HANDLE_ERROR(conn, ziAPISyncSetValueI, path, &result);
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
    HANDLE_ERROR(conn, ziAPISyncSetValueB, path, (uint8_t *) new_string,
                 (uint32_t *) &len, len);
    RETVAL = newSVpvn(new_string, len);
    Safefree(new_string);
OUTPUT:
    RETVAL


void
Sync(Lab::Zhinst conn)
CODE:
    HANDLE_ERROR(conn, ziAPISync);

void
EchoDevice(Lab::Zhinst conn, const char *device_serial)
CODE:
    HANDLE_ERROR(conn, ziAPIEchoDevice, device_serial);

void
ziAPISetDebugLevel(I32 level)

void
ziAPIWriteDebugLog(I32 level, const char *message)


const char *
DiscoveryFind(Lab::Zhinst conn, const char *device_address)
CODE:
    const char *device_id;
    HANDLE_ERROR(conn, ziAPIDiscoveryFind, device_address, &device_id);
    RETVAL = device_id;
OUTPUT:
    RETVAL


const char *
DiscoveryGet(Lab::Zhinst conn, const char *device_id)
CODE:
    const char *props_json;
    HANDLE_ERROR(conn, ziAPIDiscoveryGet, device_id, &props_json);
    RETVAL = props_json;
OUTPUT:
    RETVAL
