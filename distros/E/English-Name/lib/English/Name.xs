#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

typedef struct { const char* pointer; size_t length; } string;
typedef struct { string key; string value; bool autovivify; } entry;
typedef entry map[];

#define MAP(key, value, autovivify) { { key, sizeof(key) - 1 }, { value, sizeof(value) - 1 }, autovivify }

#define hv_exists_no_uvar(hv, key, klen) cBOOL(hv_common_key_len((hv), (key), (klen), HV_FETCH_ISEXISTS | HV_DISABLE_UVAR_XKEY, NULL, 0))

static map aliases = {
	MAP("\1RG", "_", 0),
	MAP("\14IST_SEPARATOR", "\"", 1),
	MAP("\20ID", "$", 1),
	MAP("\20ROCESS_ID", "$", 1),
	MAP("\20ROGRAM_NAME", "0", 1),
	MAP("\22EAL_GROUP_ID", "(", 1),
	MAP("\7ID", "(", 1),
	MAP("\5FFECTIVE_GROUP_ID", ")", 1),
	MAP("\5GID", ")", 1),
	MAP("\22EAL_USER_ID", "<", 1),
	MAP("\25ID", "<", 1),
	MAP("\5FFECTIVE_USER_ID", ">", 1),
	MAP("\5UID", ">", 1),
	MAP("\23UBSCRIPT_SEPARATOR", ";", 1),
	MAP("\23UBSEP", ";", 1),
	MAP("\17LD_PERL_VERSION", "]", 1),
	MAP("\23YSTEM_FD_MAX", "\6", 1),
	MAP("\11NPLACE_EDIT", "\11", 1),
	MAP("\17SNAME", "\17", 1),
	MAP("\20ERL_VERSION", "\26", 1),
	MAP("\5XECUTABLE_NAME", "\30", 1),
	MAP("\20ERLDB", "\20", 1),
	MAP("\14AST_PAREN_MATCH", "+", 1),
	MAP("\14AST_SUBMATCH_RESULT", "\16", 1),
	MAP("\14AST_MATCH_END", "+", 1),
	MAP("\14AST_MATCH_START", "-", 1),
	MAP("\14AST_REGEXP_CODE_RESULT", "\22", 1),
	MAP("\11NPUT_LINE_NUMBER", ".", 1),
	MAP("\11NPUT_RECORD_SEPARATOR", "/", 1),
	MAP("\22S", "/", 1),
	MAP("\16R", ".", 1),
	MAP("\17UTPUT_FIELD_SEPARATOR", ",", 1),
	MAP("\17FS", ",", 1),
	MAP("\17UTPUT_RECORD_SEPARATOR", "\\", 1),
	MAP("\17RS", "\\", 1),
	MAP("\17UTPUT_AUTOFLUSH", "|", 1),
	MAP("\17S_ERROR", "!", 1),
	MAP("\5RRNO", "!", 1),
	MAP("\5XTENDED_OS_ERROR", "\5", 1),
	MAP("\5XCEPTIONS_BEING_CAUGHT", "\22", 1),
	MAP("\27ARNING", "\27", 1),
	MAP("\5VAL_ERROR", "@", 0),
	MAP("\3HILD_ERROR", "?", 1),
	MAP("\3OMPILING", "\3", 1),
	MAP("\4EBUGGING", "\4", 1),
};

static I32 hash_name_filter(pTHX_ IV action, SV* value) {
	MAGIC* magic = mg_find(value, PERL_MAGIC_uvar);
	STRLEN len;
	const char* name = SvPV(magic->mg_obj, len);
	if (name[0] <= 26) {
		size_t i;
		for (i = 0; i < sizeof aliases / sizeof *aliases; ++i) {
			if (aliases[i].key.length == len && strEQ(aliases[i].key.pointer, name)) {
				if (aliases[i].autovivify && !hv_exists_no_uvar(PL_defstash, aliases[i].key.pointer, aliases[i].key.length))
					gv_fetchpvn(aliases[i].value.pointer, aliases[i].value.length, GV_ADD, SVt_PV);
				magic->mg_obj = newSVpvn(aliases[i].value.pointer, aliases[i].value.length);
				return 0;
			}
		}
	}
	return 0;
}

static const struct ufuncs hash_filter = { hash_name_filter, NULL, 0 };

MODULE = English::Name				PACKAGE = English::Name

PROTOTYPES: DISABLED

BOOT:
	sv_magic((SV*)PL_defstash, NULL, PERL_MAGIC_uvar, (const char*)&hash_filter, sizeof hash_filter);
