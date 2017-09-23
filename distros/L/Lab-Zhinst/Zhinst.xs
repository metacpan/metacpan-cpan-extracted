#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <ziAPI.h>

#include "const-c.inc"

typedef ZIConnection Lab__Zhinst;
typedef ZIEvent      *Lab__Zhinst__ZIEvent;

#define ALLOC_START_SIZE 100

# define ZHINST_UNUSED __attribute__((__unused__))

static SV *
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
    return newRV_noinc((SV *) hash);
}

static SV *
dio_sample_to_hash(pTHX_ ZIDIOSample *sample)
{
    HV *hash = newHV();
    hv_stores(hash, "timeStamp", newSVuv(sample->timeStamp));
    hv_stores(hash, "bits",      newSVuv(sample->bits));
    hv_stores(hash, "reserved",  newSVuv(sample->reserved));
    return newRV_noinc((SV *) hash);        
}

static SV *
aux_in_sample_to_hash(pTHX_ ZIAuxInSample *sample)
{
    HV *hash = newHV();
    hv_stores(hash, "timeStamp", newSVuv(sample->timeStamp));
    hv_stores(hash, "ch0",       newSVnv(sample->ch0));
    hv_stores(hash, "ch1",       newSVnv(sample->ch1));
    return newRV_noinc((SV *) hash);
}

static SV *
impedance_sample_to_hash(pTHX_ ZIImpedanceSample *sample)
{
    HV *hash = newHV();
    hv_stores(hash, "timeStamp", newSVuv(sample->timeStamp));
    hv_stores(hash, "realz", newSVnv(sample->realz));
    hv_stores(hash, "imagz", newSVnv(sample->imagz));
    hv_stores(hash, "frequency", newSVnv(sample->frequency));
    hv_stores(hash, "phase", newSVnv(sample->phase));
    hv_stores(hash, "flags", newSVuv(sample->flags));
    hv_stores(hash, "trigger", newSVuv(sample->trigger));
    hv_stores(hash, "param0", newSVnv(sample->param0));
    hv_stores(hash, "param1", newSVnv(sample->param1));
    hv_stores(hash, "drive", newSVnv(sample->drive));
    hv_stores(hash, "bias", newSVnv(sample->bias));
    return newRV_noinc((SV *) hash);
}

static SV *
zievent_value(pTHX_ ZIEvent *ev, uint32_t index)
{
    uint32_t type = ev->valueType;
    switch (type) {
    case ZI_VALUE_TYPE_NONE:
        croak("ZI_VALUE_TYPE_NONE in zievent_value");
    case ZI_VALUE_TYPE_DOUBLE_DATA:
        return newSVnv(ev->value.doubleData[index]);
    case ZI_VALUE_TYPE_INTEGER_DATA:
        return newSViv(ev->value.integerData[index]);
    case ZI_VALUE_TYPE_DEMOD_SAMPLE:
        return demod_sample_to_hash(aTHX_ &ev->value.demodSample[index]);
    case ZI_VALUE_TYPE_AUXIN_SAMPLE:
        return aux_in_sample_to_hash(aTHX_ &ev->value.auxInSample[index]);
    case ZI_VALUE_TYPE_DIO_SAMPLE:
        return dio_sample_to_hash(aTHX_ &ev->value.dioSample[index]);
    case ZI_VALUE_TYPE_IMPEDANCE_SAMPLE:
        return impedance_sample_to_hash(aTHX_ &ev->value.impedanceSample[index]);
    default:
        croak("not yet implemented ZIEvent value type %u", type);
    }
}

static SV *
zievent_to_hash(pTHX_ ZIEvent *ev)
{
    HV *hash = newHV();
    hv_stores(hash, "valueType", newSVuv(ev->valueType));
    uint32_t count = ev->count;
    hv_stores(hash, "count", newSVuv(count));
    hv_stores(hash, "path", newSVpv((const char *) ev->path, 0));
    
    AV *values = newAV();
    uint32_t i;
    for (i = 0; i < count; ++i)
        av_push(values, zievent_value(aTHX_ ev, i));
    hv_stores(hash, "values", newRV_noinc((SV *) values));
    
    return newRV_noinc((SV *) hash);
}

static SV *
pointer_object(pTHX_ const char *class_name, void *pv)
{
    SV *rv = newSV(0);
    sv_setref_pv(rv, class_name, pv);
    return rv;
}

MODULE = Lab::Zhinst		PACKAGE = Lab::Zhinst		PREFIX = ziAPI

INCLUDE: const-xs.inc


#
# Connecting to Data Server
#


void
ziAPIInit(const char *class)
PPCODE:
    ZIConnection conn;
    int rv = ziAPIInit(&conn);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHs(pointer_object(aTHX_ class, conn));


void
DESTROY(Lab::Zhinst conn)
CODE:
    ziAPIDestroy(conn);


IV
ziAPIConnect(Lab::Zhinst conn, const char *hostname, uint16_t port)


IV
ziAPIDisconnect(Lab::Zhinst conn)


MODULE = Lab::Zhinst		PACKAGE = Lab::Zhinst

void
ziAPIListImplementations()
PPCODE:
    size_t buffer_len = 100;
    char *buffer;
    Newx(buffer, buffer_len, char);
    int rv = ziAPIListImplementations(buffer, buffer_len);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHp(buffer, strlen(buffer));
    Safefree(buffer);

MODULE = Lab::Zhinst		PACKAGE = Lab::Zhinst		PREFIX = ziAPI

# FIXME: ziAPIConnectEx not needed?
  
void
ziAPIGetConnectionAPILevel(Lab::Zhinst conn)
PPCODE:
    ZIAPIVersion_enum apiLevel;
    int rv = ziAPIGetConnectionAPILevel(conn, &apiLevel);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHi(apiLevel);

# FIXME: ziAPIGetRevision


#
# Tree
#


void
ziAPIListNodes(Lab::Zhinst conn, const char *path, uint32_t bufferSize, uint32_t flags)
PPCODE:
    char *nodes;
    Newx(nodes, bufferSize, char);
    int rv = ziAPIListNodes(conn, path, nodes, bufferSize, flags);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHp(nodes, strlen(nodes));
    Safefree(nodes);


#
# Set and Get Parameters
#


void
ziAPIGetValueD(Lab::Zhinst conn, const char *path)
PPCODE:
    ZIDoubleData result;
    int rv = ziAPIGetValueD(conn, path, &result);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHn(result);

void
ziAPIGetValueI(Lab::Zhinst conn, const char *path)
PPCODE:
    IV result;
    int rv = ziAPIGetValueI(conn, path, &result);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHi(result);


void
ziAPIGetDemodSample(Lab::Zhinst conn, const char *path)
PPCODE:
    ZIDemodSample sample;
    int rv = ziAPIGetDemodSample(conn, path, &sample);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHs(demod_sample_to_hash(aTHX_ &sample));


void
ziAPIGetDIOSample(Lab::Zhinst conn, const char *path)
PPCODE:
    ZIDIOSample sample;
    int rv = ziAPIGetDIOSample(conn, path, &sample);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHs(dio_sample_to_hash(aTHX_ &sample));

void
ziAPIGetAuxInSample(Lab::Zhinst conn, const char *path)
PPCODE:
    ZIAuxInSample sample;
    int rv = ziAPIGetAuxInSample(conn, path, &sample);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHs(aux_in_sample_to_hash(aTHX_ &sample));



void
ziAPIGetValueB(Lab::Zhinst conn, const char *path, unsigned int bufferSize)
PPCODE:
    char *buffer;
    Newx(buffer, bufferSize, char);
    unsigned int length;
    int rv = ziAPIGetValueB(conn, path, (unsigned char *) buffer, &length, bufferSize);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHp(buffer, length);
    Safefree(buffer);


IV
ziAPISetValueD(Lab::Zhinst conn, const char *path, ZIDoubleData value)


IV
ziAPISetValueI(Lab::Zhinst conn, const char *path, IV value)


void
ziAPISetValueB(Lab::Zhinst conn, const char *path, SV *value)
PPCODE:
    if (!SvOK(value)) {
       croak("value is not a valid scalar");
    }
    const char *bytes;
    STRLEN len;
    bytes = SvPV(value, len);
    int rv = ziAPISetValueB(conn, path, (unsigned char *) bytes, len);
    mXPUSHi(rv);

void
ziAPISyncSetValueD(Lab::Zhinst conn, const char *path, ZIDoubleData value)
PPCODE:
    ZIDoubleData result = value;
    int rv = ziAPISyncSetValueD(conn, path, &result);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHn(result);


void
ziAPISyncSetValueI(Lab::Zhinst conn, const char *path, ZIIntegerData value)
PPCODE:
    ZIIntegerData result = value;
    int rv = ziAPISyncSetValueI(conn, path, &result);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHi(result);

void
ziAPISyncSetValueB(Lab::Zhinst conn, const char *path, SV *value)
PPCODE:
    if (!SvOK(value)) {
       croak("value is not a valid scalar");
    }
    const char *original;
    STRLEN len;
    original = SvPV(value, len);

    char *new_string;
    Newx(new_string, len, char);
    Copy(original, new_string, len, char);
    uint32_t length = len;
    int rv = ziAPISyncSetValueB(conn,  path, (uint8_t *) new_string, &length, len);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHp(new_string, length);
    Safefree(new_string);


IV
ziAPISync(Lab::Zhinst conn)

IV
ziAPIEchoDevice(Lab::Zhinst conn, const char *device_serial)

#
# Data Streaming
#

MODULE = Lab::Zhinst		PACKAGE = Lab::Zhinst

void
ziAPIAllocateEventEx()
PPCODE:
    ZIEvent *event = ziAPIAllocateEventEx();
    mXPUSHs(pointer_object(aTHX_ "Lab::Zhinst::ZIEvent", event));


MODULE = Lab::Zhinst        PACKAGE = Lab::Zhinst::ZIEvent

void
DESTROY(Lab::Zhinst::ZIEvent ev)
CODE:
    ziAPIDeallocateEventEx(ev);

MODULE = Lab::Zhinst		PACKAGE = Lab::Zhinst		PREFIX = ziAPI

IV
ziAPISubscribe(Lab::Zhinst conn, const char *path)

IV
ziAPIUnSubscribe(Lab::Zhinst conn, const char *path)

void
ziAPIPollDataEx(Lab::Zhinst conn, Lab::Zhinst::ZIEvent ev, uint32_t timeOutMilliseconds)
PPCODE:
    int rv = ziAPIPollDataEx(conn, ev, timeOutMilliseconds);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHs(zievent_to_hash(aTHX_ ev));


IV
ziAPIGetValueAsPollData(Lab::Zhinst conn, const char *path)


#
# Error Handling and Logging in the LabOne C API
#


MODULE = Lab::Zhinst		PACKAGE = Lab::Zhinst

void
ziAPIGetError(ZIResult_enum result)
PPCODE:
    int base;
    char *buffer;
    int rv = ziAPIGetError(result, &buffer, &base);
    mXPUSHi(rv);
    if (rv == 0) {
        mXPUSHp(buffer, strlen(buffer));
        mXPUSHi(base);
    }


MODULE = Lab::Zhinst		PACKAGE = Lab::Zhinst		PREFIX = ziAPI

void
ziAPIGetLastError(Lab::Zhinst conn, uint32_t bufferSize)
PPCODE:
    char *buffer;
    Newx(buffer, bufferSize, char);
    int rv = ziAPIGetLastError(conn, buffer, bufferSize);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHp(buffer, strlen(buffer));
    Safefree(buffer);


MODULE = Lab::Zhinst		PACKAGE = Lab::Zhinst

void
ziAPISetDebugLevel(I32 level)

void
ziAPIWriteDebugLog(I32 level, const char *message)


#
# Device discovery
#


MODULE = Lab::Zhinst		PACKAGE = Lab::Zhinst		PREFIX = ziAPI


void
ziAPIDiscoveryFind(Lab::Zhinst conn, const char *device_address)
PPCODE:
    const char *device_id;
    int rv = ziAPIDiscoveryFind(conn, device_address, &device_id);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHp(device_id, strlen(device_id));


void
ziAPIDiscoveryGet(Lab::Zhinst conn, const char *device_id)
PPCODE:
    const char *props_json;
    int rv = ziAPIDiscoveryGet(conn, device_id, &props_json);
    mXPUSHi(rv);
    if (rv == 0)
        mXPUSHp(props_json, strlen(props_json));
