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
  MMDB_s mmdb;
  SV *selfrv;
  dTHXfield(perl)
} *IP__Geolocation__MMDB;

static IP__Geolocation__MMDB
new_IP__Geolocation__MMDB(void)
{
  IP__Geolocation__MMDB self;

  Newxz(self, 1, struct IP__Geolocation__MMDB);
  return self;
}

typedef struct {
  IP__Geolocation__MMDB self;
  SV *data_callback;
  SV *node_callback;
  int max_depth;
} iterate_data;

static void
init_iterate_data(iterate_data *data, IP__Geolocation__MMDB self,
                  SV *data_callback, SV *node_callback)
{
  data->self = self;
  data->data_callback = data_callback;
  data->node_callback = node_callback;
  data->max_depth = (6 == self->mmdb.metadata.ip_version) ? 128 : 32;
}

static SV *
to_bigint(IP__Geolocation__MMDB self, const char *bytes, size_t size)
{
  dTHXa(self->perl);

  dSP;
  int count;
  SV *err_tmp;
  SV *retval;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 2);
  mPUSHs(newRV_inc(self->selfrv));
  mPUSHp(bytes, size);
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

typedef struct {
  char bytes[16];
} numeric_ip;

static void
init_numeric_ip(numeric_ip *ipnum)
{
  Zero(ipnum, sizeof(*ipnum), char);
}

static void
numeric_ip_set_bit(numeric_ip *ipnum, int bit)
{
  int quot = bit / (8 * sizeof(char));
  int rem = bit % (8 * sizeof(char));
  ipnum->bytes[15 - quot] |= (128 >> (7 - rem));
}

static SV *
numeric_ip_to_bigint(IP__Geolocation__MMDB self, const numeric_ip *ipnum)
{
  return to_bigint(self, ipnum->bytes, sizeof(ipnum->bytes));
}

#if MMDB_UINT128_IS_BYTE_ARRAY
static SV *
createSVu128(IP__Geolocation__MMDB self, uint8_t u[16])
{
  char bytes[16];
  size_t n;
  for (n = 0; n < 16; ++n) {
    bytes[n] = (char) u[n];
  }
  return to_bigint(self, bytes, sizeof(bytes));
}
#else
static SV *
createSVu128(IP__Geolocation__MMDB self, mmdb_uint128_t u)
{
#if BYTEORDER == 0x4321 || BYTEORDER == 0x87654321
  return to_bigint(self, (const char *) &u, sizeof(u));
#elif BYTEORDER == 0x1234 || BYTEORDER == 0x12345678
  char bytes[sizeof(u)];
  size_t n;
  for (n = 0; n < sizeof(u); ++n) {
    bytes[n] = ((const char *) &u)[sizeof(u) - n - 1];
  }
  return to_bigint(self, bytes, sizeof(bytes));
#else
#error "Unknown BYTEORDER"
#endif
}
#endif

#if UVSIZE >= 8
#define createSVu64(self, u) newSVuv(u)
#else
static SV *
createSVu64(IP__Geolocation__MMDB self, uint64_t u)
{
#if BYTEORDER == 0x4321 || BYTEORDER == 0x87654321
  return to_bigint(self, (const char *) &u, sizeof(u));
#elif BYTEORDER == 0x1234 || BYTEORDER == 0x12345678
  char bytes[sizeof(u)];
  size_t n;
  for (n = 0; n < sizeof(u); ++n) {
    bytes[n] = ((const char *) &u)[sizeof(u) - n - 1];
  }
  return to_bigint(self, bytes, sizeof(bytes));
#else
#error "Unknown BYTEORDER"
#endif
}
#endif

static MMDB_entry_data_list_s *
decode_entry_data_list(IP__Geolocation__MMDB self,
                       MMDB_entry_data_list_s *entry_data_list,
                       SV **sv, int *mmdb_error)
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
      entry_data_list =
        decode_entry_data_list(self, entry_data_list, &val, mmdb_error);
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
      entry_data_list =
        decode_entry_data_list(self, entry_data_list, &val, mmdb_error);
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
    *sv = createSVu64(self, entry_data->uint64);
    entry_data_list = entry_data_list->next;
    break;

  case MMDB_DATA_TYPE_UINT128:
    *sv = createSVu128(self, entry_data->uint128);
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

static void
call_node_callback(iterate_data *data, uint32_t node_num,
                   MMDB_search_node_s *node)
{
  IP__Geolocation__MMDB self = data->self;
  dTHXa(self->perl);

  if (!SvOK(data->node_callback)) {
    return;
  }

  dSP;
  SV *left_record = createSVu64(self, node->left_record);
  SV *right_record = createSVu64(self, node->right_record);

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 3);
  mPUSHu(node_num);
  mPUSHs(left_record);
  mPUSHs(right_record);
  PUTBACK;
  (void) call_sv(data->node_callback, G_VOID);

  FREETMPS;
  LEAVE;
}

static void
call_data_callback(iterate_data *data, numeric_ip ipnum, int depth,
                   MMDB_entry_s *record_entry)
{
  IP__Geolocation__MMDB self = data->self;
  dTHXa(self->perl);

  if (!SvOK(data->data_callback)) {
    return;
  }

  SV *decoded_entry = &PL_sv_undef;
  MMDB_entry_data_list_s *entry_data_list = NULL;
  int mmdb_error = MMDB_get_entry_data_list(record_entry, &entry_data_list);
  if (MMDB_SUCCESS == mmdb_error) {
    (void) decode_entry_data_list(self, entry_data_list,
                                  &decoded_entry, &mmdb_error);
  }
  MMDB_free_entry_data_list(entry_data_list);
  if (MMDB_SUCCESS != mmdb_error) {
    const char *error = MMDB_strerror(mmdb_error);
    croak("Entry data error looking at offset %u: %s",
          (unsigned int) record_entry->offset, error);
  }

  SV *ip = numeric_ip_to_bigint(self, &ipnum);

  dSP;

  ENTER;
  SAVETMPS;

  PUSHMARK(SP);
  EXTEND(SP, 3);
  mPUSHs(ip);
  mPUSHi(depth);
  mPUSHs(decoded_entry);
  PUTBACK;

  (void) call_sv(data->data_callback, G_VOID);

  FREETMPS;
  LEAVE;
}

static void iterate_search_nodes(iterate_data *, uint32_t, numeric_ip, int);

static void
iterate_record_entry(iterate_data *data, numeric_ip ipnum, int depth,
                     uint64_t record, uint8_t record_type,
                     MMDB_entry_s *record_entry)
{
  switch (record_type) {
    case MMDB_RECORD_TYPE_INVALID:
      croak("%s", "Invalid record when reading node");
      break;
    case MMDB_RECORD_TYPE_SEARCH_NODE:
      iterate_search_nodes(data, (uint32_t) record, ipnum, depth + 1);
      break;
    case MMDB_RECORD_TYPE_EMPTY:
      /* Empty branches are ignored. */
      break;
    case MMDB_RECORD_TYPE_DATA:
      call_data_callback(data, ipnum, depth, record_entry);
      break;
    default:
      croak("Unknown record type: %u", (unsigned int) record_type);
      break;
  }
}

static void
iterate_search_nodes(iterate_data *data, uint32_t node_num, numeric_ip ipnum,
                     int depth)
{
  MMDB_search_node_s node;
  int mmdb_error = MMDB_read_node(&data->self->mmdb, node_num, &node);
  if (MMDB_SUCCESS != mmdb_error) {
    const char *error = MMDB_strerror(mmdb_error);
    croak("Error reading node %u: %s", (unsigned int) node_num, error);
  }

  if (depth > data->max_depth) {
    croak("Invalid depth when reading node %u: %d", (unsigned int) node_num, depth);
  }

  call_node_callback(data, node_num, &node);

  iterate_record_entry(data, ipnum, depth, node.left_record,
                       node.left_record_type, &node.left_record_entry);

  numeric_ip_set_bit(&ipnum, data->max_depth - depth);

  iterate_record_entry(data, ipnum, depth, node.right_record,
                       node.right_record_type, &node.right_record_entry);
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
    self = new_IP__Geolocation__MMDB();

    mmdb_error = MMDB_open(file, flags, &self->mmdb);
    if (MMDB_SUCCESS != mmdb_error) {
      Safefree(self);
      error = MMDB_strerror(mmdb_error);
      croak("Error opening database file \"%s\": %s", file, error);
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
    MMDB_close(&self->mmdb);
    Safefree(self);

SV *
record_for_address(self, ...)
  IP::Geolocation::MMDB self
  INIT:
    const char *ip_address;
    int gai_error, mmdb_error;
    const char *error;
    MMDB_lookup_result_s result;
    MMDB_entry_data_list_s *entry_data_list;
  CODE:
    ip_address = NULL;
    if (items > 1) {
      ip_address = SvPVbyte_nolen(ST(1));
    }
    if (NULL == ip_address || '\0' == *ip_address) {
      croak("%s", "You must provide an IP address to look up");
    }
    result =
      MMDB_lookup_string(&self->mmdb, ip_address, &gai_error, &mmdb_error);
    if (0 != gai_error) {
      croak("The IP address you provided (%s) is not a valid IPv4 or IPv6 address",
            ip_address);
    }
    if (MMDB_SUCCESS != mmdb_error) {
      error = MMDB_strerror(mmdb_error);
      croak("Error looking up IP address \"%s\": %s", ip_address, error);
    }
    RETVAL = &PL_sv_undef;
    if (result.found_entry) {
      entry_data_list = NULL;
      mmdb_error = MMDB_get_entry_data_list(&result.entry, &entry_data_list);
      if (MMDB_SUCCESS == mmdb_error) {
        (void) decode_entry_data_list(self, entry_data_list,
                                      &RETVAL, &mmdb_error);
      }
      MMDB_free_entry_data_list(entry_data_list);
      if (MMDB_SUCCESS != mmdb_error) {
        error = MMDB_strerror(mmdb_error);
        croak("Entry data error looking up \"%s\": %s",
              ip_address, error);
      }
    }
  OUTPUT:
    RETVAL

void
iterate_search_tree(self, ...)
  IP::Geolocation::MMDB self
  INIT:
    SV *data_callback;
    SV *node_callback;
    iterate_data data;
    numeric_ip ipnum;
  CODE:
    data_callback = &PL_sv_undef;
    node_callback = &PL_sv_undef;
    if (items > 1) {
      data_callback = ST(1);
      if (items > 2) {
        node_callback = ST(2);
      }
    }
    init_iterate_data(&data, self, data_callback, node_callback);
    init_numeric_ip(&ipnum);
    iterate_search_nodes(&data, 0, ipnum, 1);

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
    mmdb_error =
      MMDB_get_metadata_as_entry_data_list(&self->mmdb, &entry_data_list);
    if (MMDB_SUCCESS == mmdb_error) {
      (void) decode_entry_data_list(self, entry_data_list,
                                    &RETVAL, &mmdb_error);
    }
    MMDB_free_entry_data_list(entry_data_list);
    if (MMDB_SUCCESS != mmdb_error) {
      error = MMDB_strerror(mmdb_error);
      croak("Error getting metadata: %s", error);
    }
  OUTPUT:
    RETVAL

const char *
libmaxminddb_version()
  CODE:
    RETVAL = MMDB_lib_version();
  OUTPUT:
    RETVAL
