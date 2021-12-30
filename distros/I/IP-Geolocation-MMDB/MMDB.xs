#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <maxminddb.h>

typedef struct IP__Geolocation__MMDB {
  MMDB_s *mmdb;
} *IP__Geolocation__MMDB;

#define NEW_IP__Geolocation__MMDB(var, type) \
  Newxc(var, sizeof(*var) + sizeof(type), char, void); \
  Zero(var, sizeof(*var) + sizeof(type), char); \
  var->mmdb = (type *)((char *)var + sizeof(*var));

static MMDB_entry_data_list_s *
decode_entry_data_list(MMDB_entry_data_list_s *entry_data_list, SV **sv, int *mmdb_error)
{
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
      entry_data_list = decode_entry_data_list(entry_data_list, &val, mmdb_error);
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
      entry_data_list = decode_entry_data_list(entry_data_list, &val, mmdb_error);
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
    *sv = newSVuv(entry_data->uint64);
    entry_data_list = entry_data_list->next;
    break;

  case MMDB_DATA_TYPE_UINT128:
    /* XXX Handle 128-bit integers */
    *sv = newSVpvn((const char *) &entry_data->uint128, sizeof(entry_data->uint128));
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

    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, "IP::Geolocation::MMDB", self);
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
        (void) decode_entry_data_list(entry_data_list, &RETVAL, &mmdb_error);
      }
      MMDB_free_entry_data_list(entry_data_list);
      if (MMDB_SUCCESS != mmdb_error) {
        error = MMDB_strerror(mmdb_error);
        croak("Couldn't read data for IP address \"%s\": %s", ip_address, error);
      }
    }
  OUTPUT:
    RETVAL

const char *
version(class)
  CODE:
    RETVAL = MMDB_lib_version();
  OUTPUT:
    RETVAL
