#include <iostream>
#include <mutex>
#include "simdjson.h"
#define PERL_NO_GET_CONTEXT
#include "simdjson_wrapper.h"
#include "ppport.h"

using namespace simdjson;

// global simdjson parser instance to be used in for all decodes
// (we initialize this at module load time and keep it around because
//  initializing the parser is expensive)
static ondemand::parser *global_parser_instance;
// we protect it with a mutex, because using Perl's thread-local storage
// would be slower - at the cost of making this module effectively single-threaded
static std::mutex global_mutex;

// 256 errors ought to be enough for anybody - Bill Gates
#define CUSTOM_ERROR_BASE 256

#define CUSTOM_ERROR_LIST \
	ENTRY(0, CERR_PATH_IN_SCALAR,       "only the empty path is allowed for scalar documents") \
	ENTRY(1, CERR_NUMBER_LEADING_ZERO,  "malformed number (leading zero must not be followed by another digit)") \
	ENTRY(2, CERR_NUMBER_INITIAL_MINUS, "malformed number (no digits after initial minus)") \
	ENTRY(3, CERR_NUMBER_DECIMAL,       "malformed number (no digits after decimal point)") \
	ENTRY(4, CERR_NUMBER_EXP,           "malformed number (no digits after exp sign)")

enum {
#define ENTRY(a,b,c) b = a + CUSTOM_ERROR_BASE,
CUSTOM_ERROR_LIST
#undef ENTRY
	NUM_CUSTOM_ERRORS
};

typedef struct {
	int code;
	const char *message;
} custom_error_message_t;

const custom_error_message_t custom_error_messages[] {
#define ENTRY(a,b,c) {b, c},
CUSTOM_ERROR_LIST
#undef ENTRY
};

static inline const char* custom_error_message(int code) {
	if (code >= CUSTOM_ERROR_BASE && code < NUM_CUSTOM_ERRORS && custom_error_messages[code - CUSTOM_ERROR_BASE].code == code) {
		return custom_error_messages[code - CUSTOM_ERROR_BASE].message;
	} else if (code < NUM_ERROR_CODES) {
		return error_message((simdjson::error_code) code);
	} 
	return "Something went wrong, you should never see this message";
}

// nonsense required because raw_json_token() behaves differently for values and documents
static std::string_view get_raw_json_token_from(ondemand::document& doc) {
  std::string_view str;
  if (doc.raw_json_token().get(str)) { /* error ignored */ }
  return str;
}

static std::string_view get_raw_json_token_from(ondemand::value val) {
  return val.raw_json_token();
}

// Check if a string encodes a number, that is,
// it matches /[+-]?[1-9][0-9]*\.?[0-9]*(?:[eE][+-]?[0-9]+)?/, clumsily and slowly.
// Returns an error code, or 0 if it appears to be a valid number.
// This should be a rare special case.
static inline int validate_large_number(std::string_view& s) {
  if (s.size() == 0)
    return (int)NUMBER_ERROR;

  unsigned long i = 0;
  if (s[0] == '-')
    i = 1;

  bool got_decimal = false;
  bool got_exp = false;

  if (s[0] == '-' && (1 == s.size() || ! isdigit(s[i])))
    return CERR_NUMBER_INITIAL_MINUS;
  if (s[i] == '0' && (i+1 == s.size() || isdigit(s[i+1])))
    return CERR_NUMBER_LEADING_ZERO;

  for (; i < s.size(); i++) {
    if ( !( isdigit(s[i]) || (!got_decimal && s[i] == '.') || (!got_exp && (s[i] == 'e' || s[i] == 'E') ) ) )
      return NUMBER_ERROR;
    if (s[i] == '.') {
      got_decimal = true;
      if (i+1 == s.length())
        return CERR_NUMBER_DECIMAL;
    }
    if (s[i] == 'e' || s[i] == 'E') {
      got_exp = true;
      got_decimal = true; // dot also not allowed after exponent
      if (i+1 == s.length())
        return CERR_NUMBER_EXP;
      // peek ahead and consume exponent sign if present
      if (s[i+1] == '-' || s[i+1] == '+') {
        i++;
        if (i+1 == s.length())
          return CERR_NUMBER_INITIAL_MINUS;
      }
    }
  }
  return 0;
}

// taken from simdutf8
static inline bool validate_ascii(const char *buf, size_t len) noexcept {
    const uint8_t *data = reinterpret_cast<const uint8_t *>(buf);
    uint64_t pos = 0;
    // process in blocks of 16 bytes when possible
    for (;pos + 16 < len; pos += 16) {
        uint64_t v1;
        std::memcpy(&v1, data + pos, sizeof(uint64_t));
        uint64_t v2;
        std::memcpy(&v2, data + pos + sizeof(uint64_t), sizeof(uint64_t));
        uint64_t v{v1 | v2};
        if ((v & 0x8080808080808080) != 0) { return false; }
    }
    // process the tail byte-by-byte
    for (;pos < len; pos ++) {
        if (data[pos] >= 0b10000000) { return false; }
    }
    return true;
}

#define DEC_INC_DEPTH \
  do { \
    if (++dec->depth > dec->json.max_depth) { \
      err = DEPTH_ERROR; \
      --dec->depth; \
    } \
  } while (0)

#define DEC_DEC_DEPTH --dec->depth

#define ERROR_RETURN \
  do { \
    if (simdjson_unlikely(err)) { \
      dec->error_code = err; \
      dec->error_line_number = __LINE__; \
      return NULL; \
    } \
  } while (0)

#define ERROR_RETURN_IF(expected_err) \
  do { \
    if (simdjson_unlikely(err == expected_err)) { \
      dec->error_code = err; \
      dec->error_line_number = __LINE__; \
      return NULL; \
    } \
  } while (0)

#define ERROR_RETURN_CLEANUP(var) \
  do { \
    if (simdjson_unlikely(err)) { \
      dec->error_code = err; \
      dec->error_line_number = __LINE__; \
      SvREFCNT_dec (var); \
      return NULL; \
    } \
  } while (0)

#define NULL_RETURN_CLEANUP(sv, var) \
  do { \
    if (simdjson_unlikely(!sv)) { \
      SvREFCNT_dec (var); \
      return NULL; \
    } \
  } while (0)

// XXX keep in sync w XS.xs
#define F_HOOK           0x00008000UL // some hooks exist, so slow-path processing

// There is some special kind of perversion going on that both C++'s advanced template magic
// and threaded Perl's THX_ voodoo are present, yet the whole thing still works.
template<typename T>
static SV* recursive_parse_json(pTHX_ dec_t *dec, T element) {
  SV* res = NULL;

  ondemand::json_type t;
  auto err = element.type().get(t);
  ERROR_RETURN;

  switch (t) {
  case ondemand::json_type::array: 
    {
      DEC_INC_DEPTH;
      ERROR_RETURN;

      AV *av = newAV();

      for (auto child : element.get_array()) {
        ondemand::value val;
        auto err = child.get(val);
        ERROR_RETURN_CLEANUP(av);

        SV *elem = recursive_parse_json(aTHX_ dec, val);
        NULL_RETURN_CLEANUP(elem, av);

        av_push(av, elem);
      }

      DEC_DEC_DEPTH;
      res = newRV_noinc ((SV *)av);
      break;
    }
  case ondemand::json_type::object:
    {
      DEC_INC_DEPTH;
      ERROR_RETURN;

      HV *hv = newHV();

      for (auto field : element.get_object()) {
        U32 flags = 0;
        std::string_view key;
        auto err = field.unescaped_key().get(key);
        ERROR_RETURN_CLEANUP(hv);

        ondemand::value val;
        err = field.value().get(val);
        ERROR_RETURN_CLEANUP(hv);

        SV *sv_value = recursive_parse_json(aTHX_ dec, val);
        NULL_RETURN_CLEANUP(sv_value, hv);

        // simdjson always returns the key as an UTF-8-encoded string
        // (it has already checked and unescaped it).
        // However, for Perl hash keys we have to specify whether they are UTF-8.
        // If yes, we have to supply the appropriate flag.
        // This is necessary to avoid double-encoded mojibake keys.
        // The downside: UTF-8 keys are terribly slow, they are reallocated,
        // scanned and downgraded in a very inefficient way.
        // Always passing the key as UTF-8 would in fact eat all the speedups we would gain by using simdjson.
        // Most real-life hash keys are expected to be short ASCII strings,
        // so we try to salvage the situation by scanning the key for non-ASCII characters
        // and pass the key as UTF-8 only when necessary.
        flags = HVhek_UTF8 * !validate_ascii(key.data(), key.size());
        hv_common(hv, NULL, key.data(), key.size(), flags, HV_FETCH_ISSTORE|HV_FETCH_JUST_SV, sv_value, 0);
      }

      DEC_DEC_DEPTH;
      res = newRV_noinc ((SV *)hv);

      if (simdjson_unlikely(dec->json.flags & F_HOOK)) {
        res = filter_object(dec, res, hv);
      }

      break;
    }
  case ondemand::json_type::number:
    {
      ondemand::number num;
      int err = element.get_number().get(num);
      if (simdjson_unlikely(err)) {
        // for scalar documents it can detect trailing content
        ERROR_RETURN_IF(TRAILING_CONTENT);

        // handle case of large numbers:
        // we save it as a string, but try to validate if it looks like a number at least
        // (and if it is a small but invalid number, get a more precise error code)
        auto str = get_raw_json_token_from(element);
        err = validate_large_number(str);
        ERROR_RETURN;

        res = newSVpvn_utf8(str.data(), str.size(), 1);
        break;
      }

      ondemand::number_type nt = num.get_number_type();
      switch (nt) {
      case ondemand::number_type::floating_point_number:
        {
#if defined(USE_LONG_DOUBLE) || defined(USE_QUADMATH)
          // simdjson only gets us IEEE-754 doubles, which is fine if Perl's
          // NV happens to be a double (which is the most common case),
          // but we'd lose precision if Perl was compiled with a larger numeric type.
          // So in this case we fall back to the slower but tried and true
          // legacy number parser.
          auto str = get_raw_json_token_from(element);
          const char *s = str.data();
          NV nv = json_atof(s);
          res = newSVnv(nv);
#else
          double d = 0.0;
          auto err = element.get_double().get(d);
          ERROR_RETURN;

          res = newSVnv((NV) d);
#endif

          break;
        }
      case ondemand::number_type::signed_integer:
        {
          int64_t i = 0;
          auto err = element.get_int64().get(i);
          ERROR_RETURN;

          res = newSViv((IV)i);
          break;
        }
      case ondemand::number_type::unsigned_integer:
        {
          uint64_t u = 0;
          auto err = element.get_uint64().get(u);
          ERROR_RETURN;

          res = newSVuv((UV)u);
          break;
        }
      }
      break;
    }
  case ondemand::json_type::string:
    {
      std::string_view str;
      auto err = element.get_string().get(str);
      ERROR_RETURN;

      res = newSVpvn_utf8(str.data(), str.size(), 1);
      break;
    }
  case ondemand::json_type::boolean:
    {
      bool b = false;
      auto err = element.get_bool().get(b);
      if (err) {
        // for scalar documents it can detect trailing content
        ERROR_RETURN_IF(TRAILING_CONTENT);

        // try to forge a more informative error message
        auto str = get_raw_json_token_from(element);
        if (str.size() && str[0]) {
          err = (str[0] == 't') ? T_ATOM_ERROR : (str[0] == 'f') ? F_ATOM_ERROR : err;
        }
        ERROR_RETURN;
      }

      res = newSVsv(b ? dec->json.v_true : dec->json.v_false);
      break;
    }
  case ondemand::json_type::null:
    bool is_null;
    auto err = element.is_null().get(is_null);
    if(simdjson_unlikely(!is_null || err)) {
      // we falsify the error, it would be either nothing or INCORRECT_TYPE, which is less informative
      if (err == 0 || err == INCORRECT_TYPE) {
        dec->error_code = N_ATOM_ERROR;
      } else {
        // for scalar documents it can detect trailing content
        dec->error_code = err;
      }
      dec->error_line_number = __LINE__;
      return NULL;
    }
    res = newSVsv (&PL_sv_undef);
    break;
  }
  return res;
}

// Try to find the end of a potentially valid scalar value that is followed by trailing garbage, clumsily and slowly.
// This should be a rare special case.
static size_t find_end_of_scalar(char *s) {
  if (!s) {
    return 0;
  }
  char *start = s;
  while (*s == 0x20 || *s == 0x0d ||*s == 0x0a ||*s == 0x09) {
    s++;
  }

  bool in_quotes = false;
  bool in_escape = false;
  while (*s) {
    switch (*s) {
      case '\\':
        in_escape = !in_escape;
        break;
      case '"':
        if (in_escape) {
          in_escape = false;
        } else {
          in_quotes = !in_quotes;
        }
        break;
      case 0x20:
      case 0x0d:
      case 0x0a:
      case 0x09:
      case '}':
      case '{':
      case '[':
      case ']':
        if (!in_quotes) {
            return s - start;
        }
        break;
      default:
        if (in_escape) {
          in_escape = false;
        }
        if (*s < 0x20) {
          return s - start;
        }
    }
    s++;
  }
  return s - start;
}

static char *get_location(ondemand::document& doc) {
  const char *location = NULL;
  auto err = doc.current_location().get(location);
  if (err) { // out of bounds, i.e. end of document
    return NULL;
  } else {
    return const_cast<char*>(location);
  }
}

static void save_errormsg_location(dec_t *dec, char *location) {
  if (dec->error_code) {
    dec->err = custom_error_message(dec->error_code);
  }
  if (location) {
    dec->cur = location;
  } else {
    dec->cur = SvEND(dec->input);
  }
  // std::cerr << "DEBUG error " << dec->err << " at line " << dec->error_line_number << " near " << dec->cur << std::endl;

  dec->end = SvEND(dec->input);
}

void simdjson_global_init() {
  global_parser_instance = new ondemand::parser;
}

#define ERROR_RETURN_SAVE_MSG \
  do { \
    if (simdjson_unlikely(err)) { \
      dec->error_code = err; \
      dec->error_line_number = __LINE__; \
      save_errormsg_location(dec, location); \
      return NULL; \
    } \
  } while (0)


SV * simdjson_decode(dec_t *dec) {
  SV *sv = NULL;

  dTHX;

  SvGROW(dec->input, SvCUR (dec->input) + SIMDJSON_PADDING);

  std::lock_guard<std::mutex> guard(global_mutex);
  ondemand::parser* parser = global_parser_instance;
  char *location = NULL;
  bool is_scalar = false;
  bool problem_retry = false;

  {
    // doc will be destroyed at the end of the scope, so that we can call parser->iterate again
    // if we have to retry (to catch certain error cases)
    ondemand::document doc;

    auto err = parser->iterate(SvPVX(dec->input), SvCUR(dec->input), SvLEN(dec->input)).get(doc);
    ERROR_RETURN_SAVE_MSG;

    err = doc.is_scalar().get(is_scalar);
    ERROR_RETURN_SAVE_MSG;

    if (simdjson_unlikely(is_scalar)) {
      if (dec->path && *(dec->path)) {
        // don't parse anything, non-root path doesn't make sense with scalar values
        dec->error_code = CERR_PATH_IN_SCALAR;
        dec->error_line_number = __LINE__;
        ERROR_RETURN_SAVE_MSG;
      } else {
        sv = recursive_parse_json<ondemand::document&>(aTHX_ dec, doc);

        if (simdjson_unlikely(dec->error_code)) {
          problem_retry = true;
        } else {
          location = get_location(doc);
        }
      }
    } else {
      ondemand::value val;
      if (simdjson_unlikely(dec->path)) {
        err = doc.at_pointer(dec->path).get(val);
      } else {
        err = doc.get_value().get(val);
      }
      if (simdjson_unlikely(err == INCOMPLETE_ARRAY_OR_OBJECT)) {
        problem_retry = 1;
      } else {
        ERROR_RETURN_SAVE_MSG;

        sv = recursive_parse_json<ondemand::value>(aTHX_ dec, val);
        location = get_location(doc);
      }
    }
  }

  if (simdjson_unlikely(problem_retry)) {
    if (is_scalar) {
      // For scalar documents it can detect trailing content _most of the time_,
      // but re-parsing the content with iterate_many doesn't work for some reason,
      // and even if it worked, there are cases where iterate_many fails (e.g. '1111 }', it says empty json (as of simdjson 3.1.6).
      // So we have to find the end of the valid content ourselves and re-parse a truncated document, yet another desperate hack.
      ondemand::document doc2;
      size_t size = find_end_of_scalar(SvPVX(dec->input));

      auto err = parser->iterate(SvPVX(dec->input), size, SvLEN(dec->input)).get(doc2);
      ERROR_RETURN_SAVE_MSG;
      sv = recursive_parse_json<ondemand::document&>(aTHX_ dec, doc2);
      location = SvPVX(dec->input) + size;
    } else {
      // desperate, gnarly hack:
      // simdjson has fundamental limitations, because parse.iterate (in on demand mode)
      // can not distinguish between an incomplete document and a valid document with trailing garbage.
      // So try to re-parse with iterate_many to decide.
      ondemand::document_stream stream;
      auto err = parser->iterate_many(SvPVX(dec->input), SvCUR(dec->input), SvLEN(dec->input)).get(stream);
      ERROR_RETURN_SAVE_MSG;

      ondemand::document_reference doc_ref;
      auto iter = stream.begin();
      err = (*iter).get(doc_ref);
      if (err == EMPTY) {
        // iterate_many hasn't found a valid document, so we go with truncated
        err = INCOMPLETE_ARRAY_OR_OBJECT;
        ERROR_RETURN_SAVE_MSG;
      }

      ondemand::value val;
      if (dec->path) {
        err = doc_ref.at_pointer(dec->path).get(val);
      } else {
        err = doc_ref.get_value().get(val);
      }
      ERROR_RETURN_SAVE_MSG;

      sv = recursive_parse_json<ondemand::value>(aTHX_ dec, val);
      location = get_location(doc_ref);

      // doc_ref.current_location may be null
      // (if we parsed a complete first document, and the trailing garbage looks like a (partial) valid document)
      // so we need to ask the stream
      if (location == NULL) {
        location = SvEND(dec->input) - stream.truncated_bytes();
      }
    }
  }

  save_errormsg_location(dec, location);
  return sv;
}

SV * simdjson_get_version() {
  dTHX;

  SV *version_info = newSVpvs("v" SIMDJSON_VERSION " ");
  sv_catpv(version_info, simdjson::get_active_implementation()->name().c_str());
  sv_catpv(version_info, "(");
  sv_catpv(version_info, simdjson::get_active_implementation()->description().c_str());
  sv_catpv(version_info, ")");
  return version_info;
}

