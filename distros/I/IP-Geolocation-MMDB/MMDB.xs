#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <maxminddb.h>

#ifdef MULTIPLICITY
#  define storeTHX(var)  (var) = aTHX
#  define dTHXfield(var) tTHX var;
#else
#  define storeTHX(var)  dNOOP
#  define dTHXfield(var)
#endif

typedef struct IP__Geolocation__MMDB {
  MMDB_s *mmdb;
  SV *selfrv;
  dTHXfield(perl)
} *IP__Geolocation__MMDB;

#define NEW_IP__Geolocation__MMDB(var, type) \
  Newxc(var, sizeof(*var) + sizeof(type), char, void); \
  Zero(var, sizeof(*var) + sizeof(type), char); \
  var->mmdb = (type *)((char *)var + sizeof(*var));

static SV *
to_bigint(IP__Geolocation__MMDB self, const char *bytes, size_t size)
{
  dTHXa(self->perl);
  dSP;
  int count;
  char buf[16];
  SV *err_tmp;
  SV *retval;
  size_t n;

  if (size > sizeof(buf)) {
    return newSVpvn(bytes, size);
  }

  switch (BYTEORDER) {
  case 0x1234:
  case 0x12345678:
#if MMDB_UINT128_IS_BYTE_ARRAY
    if (16 == size) {
      Copy(bytes, buf, size, char);
    }
    else {
      for (n = 0; n < size; ++n) {
        buf[n] = bytes[size - n - 1];
      }
    }
#else
    for (n = 0; n < size; ++n) {
      buf[n] = bytes[size - n - 1];
    }
#endif
    break;
  case 0x4321:
  case 0x87654321:
    Copy(bytes, buf, size, char);
    break;
  default:
    return newSVpvn(bytes, size);
  }

  ENTER;
  SAVETMPS;
  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHs(newRV_inc(self->selfrv));
  mPUSHp(buf, size);
  PUTBACK;
  count = call_method("_to_bigint", G_SCALAR | G_EVAL);
  SPAGAIN;
  err_tmp = ERRSV;
  if (SvTRUE(err_tmp)) {
    (void) POPs;
    retval = newSVpvn(bytes, size);
  }
  else {
    if (1 == count) {
      retval = newSVsv(POPs);
    }
    else {
      retval = newSVpvn(bytes, size);
    }
  }
  PUTBACK;
  FREETMPS;
  LEAVE;

  return retval;
}

static MMDB_entry_data_list_s *
decode_entry_data_list(IP__Geolocation__MMDB self, MMDB_entry_data_list_s *entry_data_list, SV **sv, int *mmdb_error)
{
  dTHXa(self->perl);
  MMDB_entry_data_s *entry_data = &entry_data_list->entry_data;
  switch (entry_data->type) {
  case MMDB_DATA_TYPE_MAP: {
    uint32_t size = entry_data->data_size;
    HV *hv = newHV();
    hv_ksplit(hv, size);
    for (entry_data_list = entry_data_list->next;
         size > 0 && NULL != entry_data_list;
         size--) {
      if (MMDB_DATA_TYPE_UTF8_STRING != entry_data_list->entry_data.type) {
        *mmdb_error = MMDB_INVALID_DATA_ERROR;
        return NULL;
      }
      const char *key = entry_data_list->entry_data.utf8_string;
      uint32_t key_size = entry_data_list->entry_data.data_size;
      entry_data_list = entry_data_list->next;
      if (NULL == entry_data_list) {
        *mmdb_error = MMDB_INVALID_DATA_ERROR;
        return NULL;
      }
      SV *val = &PL_sv_undef;
      entry_data_list = decode_entry_data_list(self, entry_data_list, &val, mmdb_error);
      if (MMDB_SUCCESS != *mmdb_error) {
        return NULL;
      }
      (void) hv_store(hv, key, key_size, val, 0);
    }
    *sv = newRV_noinc((SV *) hv);
    }
    break;

  case MMDB_DATA_TYPE_ARRAY: {
    uint32_t size = entry_data->data_size;
    AV *av = newAV();
    av_extend(av, size);
    for (entry_data_list = entry_data_list->next;
         size > 0 && NULL != entry_data_list;
         size--) {
      SV *val = &PL_sv_undef;
      entry_data_list = decode_entry_data_list(self, entry_data_list, &val, mmdb_error);
      if (MMDB_SUCCESS != *mmdb_error) {
        return NULL;
      }
      av_push(av, val);
    }
    *sv = newRV_noinc((SV *) av);
    }
    break;

  case MMDB_DATA_TYPE_UTF8_STRING:
    *sv = newSVpvn_utf8(entry_data->utf8_string, entry_data->data_size, 1);
    entry_data_list = entry_data_list->next;
    break;

  case MMDB_DATA_TYPE_BYTES:
    *sv = newSVpvn((const char *) entry_data->bytes, entry_data->data_size);
    entry_data_list = entry_data_list->next;
    break;

 case MMDB_DATA_TYPE_DOUBLE:
    *sv = newSVnv(entry_data->double_value);
    entry_data_list = entry_data_list->next;
     break;

  case MMDB_DATA_TYPE_FLOAT:
    *sv = newSVnv(entry_data->float_value);
    entry_data_list = entry_data_list->next;
    break;

  case MMDB_DATA_TYPE_UINT16:
    *sv = newSVuv(entry_data->uint16);
    entry_data_list = entry_data_list->next;
    break;

  case MMDB_DATA_TYPE_UINT32:
    *sv = newSVuv(entry_data->uint32);
    entry_data_list = entry_data_list->next;
    break;

  case MMDB_DATA_TYPE_BOOLEAN:
    *sv = newSViv(entry_data->boolean);
    entry_data_list = entry_data_list->next;
    break;

  case MMDB_DATA_TYPE_UINT64:
#if UVSIZE < 8
    *sv = to_bigint(self, (const char *) &entry_data->uint64, sizeof(entry_data->uint64));
#else
    *sv = newSVuv(entry_data->uint64);
#endif
    entry_data_list = entry_data_list->next;
    break;

  case MMDB_DATA_TYPE_UINT128:
    *sv = to_bigint(self, (const char *) &entry_data->uint128, sizeof(entry_data->uint128));
    entry_data_list = entry_data_list->next;
    break;

  case MMDB_DATA_TYPE_INT32:
    *sv = newSViv(entry_data->int32);
    entry_data_list = entry_data_list->next;
    break;

  default:
    *mmdb_error = MMDB_INVALID_DATA_ERROR;
    return NULL;
  }

  *mmdb_error = MMDB_SUCCESS;
  return entry_data_list;
}

MODULE = IP::Geolocation::MMDB PACKAGE = IP::Geolocation::MMDB

PROTOTYPES: DISABLE

SV *
_new(class, file, flags)
  const char *file
  U32 flags
  INIT:
    IP__Geolocation__MMDB self;
    int mmdb_error;
    const char *error;
  CODE:
    NEW_IP__Geolocation__MMDB(self, MMDB_s);

    mmdb_error = MMDB_open(file, flags, self->mmdb);
    if (MMDB_SUCCESS != mmdb_error) {
      Safefree(self);
      error = MMDB_strerror(mmdb_error);
      croak("Couldn't open database file \"%s\": %s", file, error);
    }

    storeTHX(self->perl);

    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "IP::Geolocation::MMDB", self);
    self->selfrv = SvRV(RETVAL); /* no inc */
  OUTPUT:
    RETVAL

void
DESTROY(self)
  IP::Geolocation::MMDB self
  CODE:
    MMDB_close(self->mmdb);
    Safefree(self);

SV *
record_for_address(self, ip_address)
  IP::Geolocation::MMDB self
  const char *ip_address
  INIT:
    int gai_error, mmdb_error;
    const char *error;
    MMDB_lookup_result_s result;
    MMDB_entry_data_list_s *entry_data_list;
  CODE:
    result = MMDB_lookup_string(self->mmdb, ip_address, &gai_error, &mmdb_error);
    if (0 != gai_error) {
      croak("Couldn't parse IP address \"%s\"", ip_address);
    }
    if (MMDB_SUCCESS != mmdb_error) {
      error = MMDB_strerror(mmdb_error);
      croak("Couldn't look up IP address \"%s\": %s", ip_address, error);
    }
    RETVAL = &PL_sv_undef;
    if (result.found_entry) {
      entry_data_list = NULL;
      mmdb_error = MMDB_get_entry_data_list(&result.entry, &entry_data_list);
      if (MMDB_SUCCESS == mmdb_error) {
        (void) decode_entry_data_list(self, entry_data_list, &RETVAL, &mmdb_error);
      }
      MMDB_free_entry_data_list(entry_data_list);
      if (MMDB_SUCCESS != mmdb_error) {
        error = MMDB_strerror(mmdb_error);
        croak("Couldn't read data for IP address \"%s\": %s", ip_address, error);
      }
    }
  OUTPUT:
    RETVAL

SV *
_metadata(self)
  IP::Geolocation::MMDB self
  INIT:
    int mmdb_error;
    const char *error;
    MMDB_entry_data_list_s *entry_data_list;
  CODE:
    RETVAL = &PL_sv_undef;
    entry_data_list = NULL;
    mmdb_error = MMDB_get_metadata_as_entry_data_list(self->mmdb, &entry_data_list);
    if (MMDB_SUCCESS == mmdb_error) {
      (void) decode_entry_data_list(self, entry_data_list, &RETVAL, &mmdb_error);
    }
    MMDB_free_entry_data_list(entry_data_list);
    if (MMDB_SUCCESS != mmdb_error) {
      error = MMDB_strerror(mmdb_error);
      croak("Couldn't read metadata: %s", error);
    }
  OUTPUT:
    RETVAL

const char *
version(class)
  CODE:
    RETVAL = MMDB_lib_version();
  OUTPUT:
    RETVAL
