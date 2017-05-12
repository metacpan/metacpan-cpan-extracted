#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include "saleaeinterface.h"

volatile int saleaeinterface_internal_verbosity = 0;

void saleaeinterface_internal_on_connect(saleaeinterface_t *obj, unsigned int id)
{
    if (!obj || !obj->perl)
        return;
    PERL_SET_CONTEXT(obj->perl);
    if (SvOK((SV *)obj->parent) && SvOK((SV *)obj->on_connect)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs((SV *)obj->parent);
        XPUSHs(sv_2mortal(newSVuv(id)));
        PUTBACK;
        call_sv((SV *)obj->on_connect, G_DISCARD);
        FREETMPS;
        LEAVE;
    }
}
void saleaeinterface_internal_on_disconnect(saleaeinterface_t *obj, unsigned int id)
{
    if (!obj || !obj->perl)
        return;
    PERL_SET_CONTEXT(obj->perl);
    if (SvOK((SV *)obj->parent) && SvOK((SV *)obj->on_disconnect)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs((SV *)obj->parent);
        XPUSHs(sv_2mortal(newSVuv(id)));
        PUTBACK;
        call_sv((SV *)obj->on_disconnect, G_DISCARD);
        FREETMPS;
        LEAVE;
    }
}
void saleaeinterface_internal_on_error(saleaeinterface_t *obj, unsigned int id)
{
    if (!obj || !obj->perl)
        return;
    PERL_SET_CONTEXT(obj->perl);
    if (SvOK((SV *)obj->parent) && SvOK((SV *)obj->on_error)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs((SV *)obj->parent);
        XPUSHs(sv_2mortal(newSVuv(id)));
        PUTBACK;
        call_sv((SV *)obj->on_error, G_DISCARD);
        FREETMPS;
        LEAVE;
    }
}
void saleaeinterface_internal_on_readdata(saleaeinterface_t *obj, unsigned int id,
                    unsigned char *data, unsigned int len)
{
    if (!obj || !obj->perl)
        return;
    PERL_SET_CONTEXT(obj->perl);
    if (SvOK((SV *)obj->parent) && SvOK((SV *)obj->on_readdata)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs((SV *)obj->parent);
        XPUSHs(sv_2mortal(newSVuv(id)));
        XPUSHs(sv_2mortal(newSVpvn(data, len)));
        XPUSHs(sv_2mortal(newSVuv(len)));
        PUTBACK;
        call_sv((SV *)obj->on_readdata, G_DISCARD);
        FREETMPS;
        LEAVE;
    }
}
void saleaeinterface_internal_on_writedata(saleaeinterface_t *obj, unsigned int id,
                    unsigned char *data, unsigned int len)
{
    if (!obj || !obj->perl)
        return;
    PERL_SET_CONTEXT(obj->perl);
    if (SvOK((SV *)obj->parent) && SvOK((SV *)obj->on_writedata)) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        /* FIXME: this is a wrong implementation */
        SV *psv = newSV(0);
        SvPVX(psv) = data;
        SvCUR(psv) = len;
        SvLEN(psv) = 0;
        XPUSHs((SV *)obj->parent);
        XPUSHs(sv_2mortal(newSVuv(id)));
        XPUSHs(psv);
        XPUSHs(sv_2mortal(newSVuv(len)));
        PUTBACK;
        call_sv((SV *)obj->on_writedata, G_DISCARD);
        FREETMPS;
        LEAVE;
    }
}

MODULE = Device::SaleaeLogic		PACKAGE = Device::SaleaeLogic		

PROTOTYPES: ENABLE

void
saleaeinterface_begin_connect(obj)
    saleaeinterface_t *obj

void
saleaeinterface_register_on_connect(obj, cb)
    saleaeinterface_t *obj
    SV* cb
        CODE:
            /* save a copy of the callback */
            IAMHERE_ENTRY;
            if (obj && !obj->on_connect) {
                obj->on_connect = newSVsv(cb);
            } else {
                SvSetSV((SV *)obj->on_connect, cb);
            }
            IAMHERE_EXIT;

void
saleaeinterface_register_on_disconnect(obj, cb)
    saleaeinterface_t *obj
    SV* cb
        CODE:
            /* save a copy of the callback */
            IAMHERE_ENTRY;
            if (obj && !obj->on_disconnect) {
                obj->on_disconnect = newSVsv(cb);
            } else if (obj) {
                SvSetSV((SV *)obj->on_disconnect, cb);
            }
            IAMHERE_EXIT;

void
saleaeinterface_register_on_readdata(obj, cb)
    saleaeinterface_t *obj
    SV* cb
        CODE:
            /* save a copy of the callback */
            if (obj && !obj->on_readdata) {
                obj->on_readdata = newSVsv(cb);
            } else if (obj) {
                SvSetSV((SV *)obj->on_readdata, cb);
            }

void
saleaeinterface_register_on_writedata(obj, cb)
    saleaeinterface_t *obj
    SV* cb
        CODE:
            /* save a copy of the callback */
            if (obj && !obj->on_writedata) {
                obj->on_writedata = newSVsv(cb);
            } else if (obj) {
                SvSetSV((SV *)obj->on_writedata, cb);
            }

void
saleaeinterface_register_on_error(obj, cb)
    saleaeinterface_t *obj
    SV* cb
        CODE:
            /* save a copy of the callback */
            if (obj && !obj->on_error) {
                obj->on_error = newSVsv(cb);
            } else if (obj) {
                SvSetSV((SV *)obj->on_error, cb);
            }

saleaeinterface_t *
saleaeinterface_new(parent)
    SV *parent
    CODE:
        RETVAL = (saleaeinterface_t *)malloc(sizeof(saleaeinterface_t));
        if (RETVAL) {
            memset(RETVAL, 0, sizeof(saleaeinterface_t));
            RETVAL->begun = 0;
            RETVAL->perl = Perl_get_context();
            RETVAL->interface_count = 0;
            RETVAL->interface_map = saleaeinterface_map_create();
            RETVAL->id_map = saleaeinterface_id_map_create();
            /* make a reference to the parent calling object */
            RETVAL->parent = (void *)SvREFCNT_inc(parent);
        } else {
            Perl_croak(aTHX_ "No memory to allocate saleaeinterface_t object\n");
        }
    OUTPUT:
        RETVAL

void
saleaeinterface_DESTROY(obj)
    saleaeinterface_t *obj
    CODE:
        IAMHERE_ENTRY;
        if (obj) {
            SV* parent = obj->parent;
            SvREFCNT_dec(parent);
            saleaeinterface_map_delete(obj->interface_map);
            saleaeinterface_id_map_delete(obj->id_map);
            free(obj);
            obj = NULL;
        }
        IAMHERE_EXIT;

unsigned int
saleaeinterface_is_usb2(obj, id)
    saleaeinterface_t *obj
    unsigned int id
    CODE:
        RETVAL = saleaeinterface_isusb2(obj, id);
    OUTPUT:
        RETVAL

unsigned int
saleaeinterface_is_streaming(obj, id)
    saleaeinterface_t *obj
    unsigned int id
    CODE:
        RETVAL = saleaeinterface_isstreaming(obj, id);
    OUTPUT:
        RETVAL

unsigned int
saleaeinterface_get_channel_count(obj, id)
    saleaeinterface_t *obj
    unsigned int id
    CODE:
        RETVAL = saleaeinterface_getchannelcount(obj, id);
    OUTPUT:
        RETVAL

unsigned int
saleaeinterface_get_sample_rate(obj, id)
    saleaeinterface_t *obj
    unsigned int id
    CODE:
        RETVAL = saleaeinterface_getsamplerate(obj, id);
    OUTPUT:
        RETVAL

void saleaeinterface_set_sample_rate(obj, id, hz)
    saleaeinterface_t *obj
    unsigned int id
    unsigned int hz
    CODE:
        if (hz > 0) {
            saleaeinterface_setsamplerate(obj, id, hz);
        }

SV *
saleaeinterface_get_supported_sample_rates(obj, id)
    saleaeinterface_t *obj
    unsigned int id
    PREINIT:
        AV *results;
        unsigned int *buf = NULL;
        unsigned int blen = 32;
        int outlen = 0;
        int i = 0;
    CODE:
        buf = malloc(blen * sizeof(unsigned int));
        if (!buf) {
            Perl_croak(aTHX_ "No memory to allocate 32 array of integers\n");
            XSRETURN_UNDEF;
        } else {
            memset(buf, 0, blen * sizeof(unsigned int));
        }
        results = newAV();
        outlen = saleaeinterface_getsupportedsamplerates(obj, id, buf, blen);
        if (outlen > 0) {
            for (i = 0; i < outlen && i < blen; ++i) {
                if (saleaeinterface_internal_verbosity)
                    fprintf(stderr, "[%s:%d] sample[%d]: %u\n", __func__, __LINE__, i, buf[i]);
                av_push(results, newSVuv(buf[i]));
            }
        }
        RETVAL = newRV_noinc((SV *)results);
        if (buf) {
            free(buf);
        }
    OUTPUT:
       RETVAL

unsigned int
saleaeinterface_is_logic16(obj, id)
    saleaeinterface_t *obj
    unsigned int id
    CODE:
        RETVAL = saleaeinterface_islogic16(obj, id);
    OUTPUT:
        RETVAL

unsigned int
saleaeinterface_is_logic(obj, id)
    saleaeinterface_t *obj
    unsigned int id
    CODE:
        RETVAL = saleaeinterface_islogic(obj, id);
    OUTPUT:
        RETVAL

SV*
saleaeinterface_get_device_id(obj, id)
    saleaeinterface_t *obj
    unsigned int id
    PREINIT:
        size_t sdk_len;
    CODE:
        sdk_len = saleaeinterface_get_sdk_id(obj, id, NULL, 0);
        if (sdk_len > 0) {
            char *sdk_id = malloc((sdk_len + 1) * sizeof(unsigned char));
            if (sdk_id) {
                memset(sdk_id, 0, (sdk_len + 1) * sizeof(unsigned char));
                sdk_len = saleaeinterface_get_sdk_id(obj, id, sdk_id, sdk_len + 1);
                if (sdk_len > 0) {
                    RETVAL = newSVpv(sdk_id, (STRLEN)sdk_len);
                }
                free(sdk_id);
            } else {
                Perl_croak(aTHX_ "No memory to allocate string\n");
            }
        } else {
            XSRETURN_UNDEF;
        }
    OUTPUT:
        RETVAL

void
saleaeinterface_verbose()
    CODE:
        saleaeinterface_internal_verbosity = 1;

void
saleaeinterface_read_start(obj, id)
    saleaeinterface_t *obj
    unsigned int id
    CODE:
        saleaeinterface_read_start(obj, id);

void
saleaeinterface_write_start(obj, id)
    saleaeinterface_t *obj
    unsigned int id
    CODE:
        saleaeinterface_write_start(obj, id);

void
saleaeinterface_stop(obj, id)
    saleaeinterface_t *obj
    unsigned int id
    CODE:
        saleaeinterface_stop(obj, id);

void
saleaeinterface_set_use5volts(obj, id, flag)
    saleaeinterface_t *obj
    unsigned int id
    unsigned int flag
    CODE:
        saleaeinterface_setuse5volts(obj, id, flag);

int
saleaeinterface_get_use5volts(obj, id)
    saleaeinterface_t *obj
    unsigned int id
    CODE:
        RETVAL = saleaeinterface_getuse5volts(obj, id);
    OUTPUT:
        RETVAL

SV *
saleaeinterface_get_active_channels(obj, id)
    saleaeinterface_t *obj
    unsigned int id
    PREINIT:
        AV *results;
        unsigned int *buf = NULL;
        unsigned int blen = 16;
        int outlen = 0;
        int i = 0;
    CODE:
        buf = malloc(blen * sizeof(unsigned int));
        if (!buf) {
            Perl_croak(aTHX_ "No memory to allocate 16 array of integers\n");
            XSRETURN_UNDEF;
        } else {
            memset(buf, 0, blen * sizeof(unsigned int));
        }
        results = newAV();
        outlen = saleaeinterface_getactivechannels(obj, id, buf, blen);
        if (outlen > 0) {
            for (i = 0; i < outlen && i < blen; ++i) {
                if (saleaeinterface_internal_verbosity) {
                    fprintf(stderr, "[%s:%d] channel[%d]: %u\n",
                        __func__, __LINE__, i, buf[i]);
                }
                av_push(results, newSVuv(buf[i]));
            }
        }
        RETVAL = newRV_noinc((SV *)results);
        if (buf) {
            free(buf);
        }
    OUTPUT:
       RETVAL

void
saleaeinterface_set_active_channels(obj, id, chnls)
    saleaeinterface_t *obj
    unsigned int id
    SV* chnls
    PREINIT:
        AV *channels;
        unsigned int *buf = NULL;
        unsigned int blen = 0;
        int i = 0;
        if ((!SvROK(chnls)) || (SvTYPE(SvRV(chnls)) != SVt_PVAV) ||
            ((blen = av_len((AV *)SvRV(chnls)))) <= 0) {
            XSRETURN_UNDEF;
        }
    CODE:
        buf = malloc(blen * sizeof(unsigned int));
        if (!buf) {
            Perl_croak(aTHX_ "No memory to allocate %u array of integers\n", blen);
            XSRETURN_UNDEF;
        } else {
            memset(buf, 0, blen * sizeof(unsigned int));
        }
        for (i = 0; i < blen; ++i) {
            buf[i] = SvUV(*av_fetch((AV *)SvRV(chnls), i, 0));
            if (saleaeinterface_internal_verbosity) {
                fprintf(stderr, "[%s:%d] channel[%d]: %u\n",
                        __func__, __LINE__, i, buf[i]);
            }
        }
        saleaeinterface_setactivechannels(obj, id, buf, blen);
        if (buf) {
            free(buf);
        }
