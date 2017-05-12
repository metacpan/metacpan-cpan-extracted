#ifdef WIN32
    #include <windows.h>
    #ifndef __func__
        #define __func__ __FUNCTION__
    #endif
    #ifndef _CRT_SECURE_NO_WARNINGS
        #define _CRT_SECURE_NO_WARNINGS
    #endif
	#ifndef WIN32_LEAN_AND_MEAN
		#define WIN32_LEAN_AND_MEAN
	#endif
#else
    #include <unistd.h>
#endif
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include <typeinfo>
#include <map>
#include <sstream>

#include "SaleaeDeviceApi.h"
#include "saleaeinterface.h"

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

typedef std::map <U64, GenericInterface *> SIMap;
typedef std::pair <U64, GenericInterface *> SIPair;
typedef std::map <U64, unsigned int> SIDMap;
typedef std::pair <U64, unsigned int> SIDPair;

static volatile unsigned int saleaeinterface_runtime_device_count = 0;
/* interface for XS to call */
void *saleaeinterface_map_create()
{
    SIMap *p = new SIMap;
    return (void *)p;
}

void *saleaeinterface_id_map_create()
{
    SIDMap *p = new SIDMap;
    return (void *)p;
}

void saleaeinterface_map_delete(void *p)
{
    if (p) {
        SIMap *m = (SIMap *)p;
        delete m;
    }
}

void saleaeinterface_id_map_delete(void *p)
{
    if (p) {
        SIDMap *m = (SIDMap *)p;
        delete m;
    }
}

static void saleaeinterface_map_insert(void *p, U64 id, GenericInterface *iface)
{
    if (p) {
        SIMap *m = (SIMap *)p;
        SIMap::iterator mi = m->find(id);
        /* force insertion */
        if (mi != m->end()) {
            m->erase(mi);
        }
        m->insert(SIPair(id, iface));
    }
}

static void saleaeinterface_id_map_insert(void *p, U64 id, unsigned int val)
{
    if (p) {
        SIDMap *m = (SIDMap *)p;
        SIDMap::iterator mi = m->find(id);
        /* force insertion */
        if (mi != m->end()) {
            m->erase(mi);
        }
        m->insert(SIDPair(id, val));
    }
}

static void saleaeinterface_map_erase(void *p, U64 id)
{
    if (p) {
        SIMap *m = (SIMap *)p;
        SIMap::iterator mi = m->find(id);
        if (mi != m->end()) {
            m->erase(mi);
        }
    }
}

static void saleaeinterface_id_map_erase(void *p, U64 id)
{
    if (p) {
        SIDMap *m = (SIDMap *)p;
        SIDMap::iterator mi = m->find(id);
        if (mi != m->end()) {
            m->erase(mi);
        }
    }
}

static size_t saleaeinterface_map_size(void *p)
{
    if (p) {
        SIMap *m = (SIMap *)p;
        return m->size();
    }
    return 0;
}

static size_t saleaeinterface_id_map_size(void *p)
{
    if (p) {
        SIDMap *m = (SIDMap *)p;
        return m->size();
    }
    return 0;
}

static GenericInterface *saleaeinterface_map_get(void *p, U64 id)
{
    if (p) {
        SIMap *m = (SIMap *)p;
        SIMap::iterator mi = m->find(id);
        if (mi != m->end())
            return mi->second;
    }
    return NULL;
}

static unsigned int saleaeinterface_id_map_get(void *p, U64 id)
{
    if (p) {
        SIDMap *m = (SIDMap *)p;
        SIDMap::iterator mi = m->find(id);
        if (mi != m->end())
            return mi->second;
    }
    return 0;
}

static U64 saleaeinterface_id_map_get_id(void *p, unsigned int val)
{
    if (p) {
        SIDMap *m = (SIDMap *)p;
        SIDMap::iterator mi;
        for (mi = m->begin(); mi != m->end(); mi++) {
            if (mi->second == val)
                return mi->first;
        }
    }
    return 0;
}

static int saleaeinterface_get_type(GenericInterface *iface)
{
    if (!iface)
        return SALEAEINTERFACE_UNKNOWN;
    std::string iface_name = typeid(*iface).name();
    if (saleaeinterface_internal_verbosity)
        fprintf(stderr, "[%s:%d] Interface name: %s\n",
            __func__, __LINE__, iface_name.c_str());
    if (iface_name.find("Logic16Interface") != std::string::npos) {
        return SALEAEINTERFACE_LOGIC16;
    } else if (iface_name.find("LogicInterface") != std::string::npos) {
        return SALEAEINTERFACE_LOGIC;
    }
    return SALEAEINTERFACE_UNKNOWN;
}

static void cb_onreaddata(U64 id, U8 *data, U32 len, void *udata)
{
    saleaeinterface_t *obj = (saleaeinterface_t *)udata;
    if (obj) {
        unsigned int val = saleaeinterface_id_map_get(obj->id_map, id);
        saleaeinterface_internal_on_readdata(obj, val, data, len);
    }
    if (data)
        DevicesManagerInterface::DeleteU8ArrayPtr(data);
}
static void cb_onwritedata(U64 id, U8 *data, U32 len, void *udata)
{
    saleaeinterface_t *obj = (saleaeinterface_t *)udata;
    /* FIXME: maybe wrong implementation */
    if (obj) {
        unsigned int val = saleaeinterface_id_map_get(obj->id_map, id);
        saleaeinterface_internal_on_writedata(obj, val, data, len);
    }
}
static void cb_onerror(U64 id, void *udata)
{
    saleaeinterface_t *obj = (saleaeinterface_t *)udata;
    if (obj) {
        unsigned int val = saleaeinterface_id_map_get(obj->id_map, id);
        saleaeinterface_internal_on_error(obj, val);
    }
}
void cb_onconnect(U64 id, GenericInterface *iface, void *udata)
{
    saleaeinterface_t *obj = (saleaeinterface_t *)udata;
    IAMHERE_ENTRY;
    if (obj && iface) {
        int type = saleaeinterface_get_type(iface);
        /* setup the interface and device id */
        saleaeinterface_map_insert(obj->interface_map, id, iface);
        saleaeinterface_runtime_device_count++;
        saleaeinterface_id_map_insert(obj->id_map, id,
                saleaeinterface_runtime_device_count);
        obj->interface_count = saleaeinterface_map_size(obj->interface_map);
        if (saleaeinterface_internal_verbosity)
            fprintf(stderr, "[%s:%d] Device id from SDK: %X from XS: %u\n",
                __func__, __LINE__, id, saleaeinterface_runtime_device_count);
        if (type == SALEAEINTERFACE_LOGIC16) {
            Logic16Interface *l16 = dynamic_cast<Logic16Interface *>(iface);
            l16->RegisterOnReadData(cb_onreaddata, udata);
            l16->RegisterOnWriteData(cb_onwritedata, udata);
            l16->RegisterOnError(cb_onerror, udata);
        } else if (type == SALEAEINTERFACE_LOGIC) {
            LogicInterface *l8 = dynamic_cast<LogicInterface *>(iface);
            l8->RegisterOnReadData(cb_onreaddata, udata);
            l8->RegisterOnWriteData(cb_onwritedata, udata);
            l8->RegisterOnError(cb_onerror, udata);
        } else {
            if (saleaeinterface_internal_verbosity)
                fprintf(stderr, "[%s:%d] This is an unsupported device\n",
                    __func__, __LINE__);
            IAMHERE_EXIT;
            return;
        }
        unsigned int val = saleaeinterface_id_map_get(obj->id_map, id);
        if (saleaeinterface_internal_verbosity)
            fprintf(stderr, "[%s:%d] Device id from SDK: %X from XS: %u\n",
                __func__, __LINE__, id, val);
        saleaeinterface_internal_on_connect(obj, val);
    }
    IAMHERE_EXIT;
}
static void cb_ondisconnect(U64 id, void *udata)
{
    saleaeinterface_t *obj = (saleaeinterface_t *)udata;
    IAMHERE_ENTRY;
    saleaeinterface_map_erase(obj->interface_map, id);
    saleaeinterface_id_map_erase(obj->interface_map, id);
    obj->interface_count = saleaeinterface_map_size(obj->interface_map);
    unsigned int val = saleaeinterface_id_map_get(obj->id_map, id);
    saleaeinterface_internal_on_disconnect(obj, val);
    IAMHERE_EXIT;
}

void saleaeinterface_begin_connect(saleaeinterface_t *obj)
{
    IAMHERE_ENTRY;
    if (obj && !obj->begun) {
        obj->begun = 1;
        DevicesManagerInterface::RegisterOnConnect(cb_onconnect, (void *)obj);
        DevicesManagerInterface::RegisterOnDisconnect(cb_ondisconnect, (void *)obj);
        DevicesManagerInterface::BeginConnect();
    }
    IAMHERE_EXIT;
}

unsigned int saleaeinterface_isusb2(saleaeinterface_t *obj, unsigned int id)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            LogicAnalyzerInterface *lai = dynamic_cast<LogicAnalyzerInterface *>(gi);
            return lai->IsUsb2pt0() ? 1 : 0;
        }
    }
    return 0;
}

unsigned int saleaeinterface_isstreaming(saleaeinterface_t *obj, unsigned int id)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            LogicAnalyzerInterface *lai = dynamic_cast<LogicAnalyzerInterface *>(gi);
            return lai->IsStreaming() ? 1 : 0;
        }
    }
    return 0;
}

unsigned int saleaeinterface_getchannelcount(saleaeinterface_t *obj, unsigned int id)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            LogicAnalyzerInterface *lai = dynamic_cast<LogicAnalyzerInterface *>(gi);
            return lai->GetChannelCount();
        }
    }
    return 0;
}

unsigned int saleaeinterface_getsamplerate(saleaeinterface_t *obj, unsigned int id)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            LogicAnalyzerInterface *lai = dynamic_cast<LogicAnalyzerInterface *>(gi);
            return lai->GetSampleRateHz();
        }
    }
    return 0;
}

void saleaeinterface_setsamplerate(saleaeinterface_t *obj, unsigned int id, unsigned int rate)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            LogicAnalyzerInterface *lai = dynamic_cast<LogicAnalyzerInterface *>(gi);
            lai->SetSampleRateHz(rate);
        }
    }
}

int saleaeinterface_getsupportedsamplerates(saleaeinterface_t *obj, unsigned int id,
                            unsigned int *ptr, unsigned int len)
{
    if (obj && ptr) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            LogicAnalyzerInterface *lai = dynamic_cast<LogicAnalyzerInterface *>(gi);
            S32 rc = lai->GetSupportedSampleRates(ptr, (U32)len);
            return (int)rc;
        }
    }
    return 0;
}

unsigned int saleaeinterface_islogic16(saleaeinterface_t *obj, unsigned int id)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            int type = saleaeinterface_get_type(gi);
            return (type == SALEAEINTERFACE_LOGIC16) ? 1 : 0;
        }
    }
    return 0;
}

unsigned int saleaeinterface_islogic(saleaeinterface_t *obj, unsigned int id)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            int type = saleaeinterface_get_type(gi);
            return (type == SALEAEINTERFACE_LOGIC) ? 1 : 0;
        }
    }
    return 0;
}

/* pass in an array of channel indexes and the number of channels */
void saleaeinterface_setactivechannels(saleaeinterface_t *obj, unsigned int id,
                                unsigned int *channels, unsigned int count)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            int type = saleaeinterface_get_type(gi);
            if (type == SALEAEINTERFACE_LOGIC16) {
                Logic16Interface *l16 = dynamic_cast<Logic16Interface *>(gi);
                if (channels && count > 0) {
                    l16->SetActiveChannels(channels, count);
                }
            } else {
                if (saleaeinterface_internal_verbosity) {
                    fprintf(stderr, "[%s:%d] SetActiveChannels() only works for Logic16\n",
                            __func__, __LINE__);
                }
            }
        }
    }
}
/* user has to pass in an array of at least 16 elements */
unsigned int saleaeinterface_getactivechannels(saleaeinterface_t *obj, unsigned int id,
                                unsigned int *channels, unsigned int count)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            int type = saleaeinterface_get_type(gi);
            if (type == SALEAEINTERFACE_LOGIC16) {
                Logic16Interface *l16 = dynamic_cast<Logic16Interface *>(gi);
                if (count < 16) {
                    if (saleaeinterface_internal_verbosity) {
                        fprintf(stderr, "[%s:%d] GetActiveChannels() needs an "
                                "array of minimum 16 elements\n",
                                __func__, __LINE__);
                    }
                    return 0;
                } else {
                    return l16->GetActiveChannels(channels);
                }
            } else {
                if (saleaeinterface_internal_verbosity) {
                    fprintf(stderr, "[%s:%d] GetActiveChannels() only works for Logic16\n",
                            __func__, __LINE__);
                }
            }
        }
    }
    return 0;
}
void saleaeinterface_setuse5volts(saleaeinterface_t *obj, unsigned int id, int flag)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            int type = saleaeinterface_get_type(gi);
            if (type == SALEAEINTERFACE_LOGIC16) {
                Logic16Interface *l16 = dynamic_cast<Logic16Interface *>(gi);
                l16->SetUse5Volts(flag ? true : false);
            } else {
                if (saleaeinterface_internal_verbosity) {
                    fprintf(stderr, "[%s:%d] SetUse5Volts() only works for Logic16\n",
                            __func__, __LINE__);
                }
            }
        }
    }
}
int saleaeinterface_getuse5volts(saleaeinterface_t *obj, unsigned int id)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            int type = saleaeinterface_get_type(gi);
            if (type == SALEAEINTERFACE_LOGIC16) {
                Logic16Interface *l16 = dynamic_cast<Logic16Interface *>(gi);
                return l16->GetUse5Volts() ? 1 : 0;
            } else {
                if (saleaeinterface_internal_verbosity) {
                    fprintf(stderr, "[%s:%d] GetUse5Volts() only works for Logic16\n",
                            __func__, __LINE__);
                }
            }
        }
    }
    return 0;
}

void saleaeinterface_read_start(saleaeinterface_t *obj, unsigned int id)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            int type = saleaeinterface_get_type(gi);
            if (type == SALEAEINTERFACE_LOGIC16) {
                Logic16Interface *l16 = dynamic_cast<Logic16Interface *>(gi);
                l16->ReadStart();
            } else if (type == SALEAEINTERFACE_LOGIC) {
                LogicInterface *l8 = dynamic_cast<LogicInterface *>(gi);
                l8->ReadStart();
            } else {
                if (saleaeinterface_internal_verbosity) {
                    fprintf(stderr, "[%s:%d] Device is neither Logic16 or Logic.\n",
                            __func__, __LINE__);
                }
            }
        }
    }
}

void saleaeinterface_stop(saleaeinterface_t *obj, unsigned int id)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            int type = saleaeinterface_get_type(gi);
            if (type == SALEAEINTERFACE_LOGIC16) {
                Logic16Interface *l16 = dynamic_cast<Logic16Interface *>(gi);
                l16->Stop();
            } else if (type == SALEAEINTERFACE_LOGIC) {
                LogicInterface *l8 = dynamic_cast<LogicInterface *>(gi);
                l8->Stop();
            } else {
                if (saleaeinterface_internal_verbosity) {
                    fprintf(stderr, "[%s:%d] Device is neither Logic16 or Logic.\n",
                            __func__, __LINE__);
                }
            }
        }
    }
}

void saleaeinterface_write_start(saleaeinterface_t *obj, unsigned int id)
{
    if (obj) {
        U64 did = saleaeinterface_id_map_get_id(obj->id_map, id);
        GenericInterface *gi = saleaeinterface_map_get(obj->interface_map, did);
        if (gi) {
            int type = saleaeinterface_get_type(gi);
            if (type == SALEAEINTERFACE_LOGIC) {
                LogicInterface *l8 = dynamic_cast<LogicInterface *>(gi);
                l8->WriteStart();
            } else {
                if (saleaeinterface_internal_verbosity) {
                    fprintf(stderr,
                            "[%s:%d] WriteStart() is supported only for Logic.\n",
                            __func__, __LINE__);
                }
            }
        }
    }
}

size_t saleaeinterface_get_sdk_id(saleaeinterface_t *obj, unsigned int id,
            char *buf, size_t buflen)
{
    U64 did = 0;
    if (obj) {
        did = saleaeinterface_id_map_get_id(obj->id_map, id);
    }
    std::stringstream ss;
    ss << std::hex << did;
    const std::string &str = ss.str();
    if (buf && buflen > 0) {
        const char *p = str.c_str();
        size_t len = str.length();
        if (len >= buflen)
            len = buflen;
        memset(buf, 0, buflen);
        memcpy(buf, p, len);
        return len;
    }
    return str.length();
}

#ifdef __cplusplus
} /* extern C end */
#endif /* __cplusplus */
