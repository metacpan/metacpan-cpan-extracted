#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <tracker.h>


/* SERVICE_ definitions */
#define  SERVICE_MIN                    0
#define  SERVICE_FILES                  0
#define  SERVICE_FOLDERS                1
#define  SERVICE_DOCUMENTS              2
#define  SERVICE_IMAGES                 3
#define  SERVICE_MUSIC                  4
#define  SERVICE_VIDEOS                 5
#define  SERVICE_TEXT_FILES             6
#define  SERVICE_DEVELOPMENT_FILES      7
#define  SERVICE_OTHER_FILES            8
#define  SERVICE_VFS_FILES              9
#define  SERVICE_VFS_FOLDERS           10
#define  SERVICE_VFS_DOCUMENTS         11
#define  SERVICE_VFS_IMAGES            12
#define  SERVICE_VFS_MUSIC             13
#define  SERVICE_VFS_VIDEOS            14
#define  SERVICE_VFS_TEXT_FILES        15
#define  SERVICE_VFS_DEVELOPMENT_FILES 16
#define  SERVICE_VFS_OTHER_FILES       17
#define  SERVICE_CONVERSATIONS         18
#define  SERVICE_PLAYLISTS             19
#define  SERVICE_APPLICATIONS          20
#define  SERVICE_CONTACTS              21
#define  SERVICE_EMAILS                22
#define  SERVICE_EMAILATTACHMENTS      23
#define  SERVICE_APPOINTMENTS          24
#define  SERVICE_TASKS                 25
#define  SERVICE_BOOKMARKS             26
#define  SERVICE_HISTORY               27
#define  SERVICE_PROJECTS              28
#define  SERVICE_MAX                   28

/* MetasataTypes definitions */
#define DATA_MIN                        0
#define DATA_STRING_INDEXABLE           0
#define DATA_STRING                     1
#define DATA_NUMERIC                    2
#define DATA_DATE                       3
#define DATA_MAX                        4

#include "const-c.inc"

SV* get_instance(char* class)
{
	TrackerClient* 	client = NULL;
	SV*		obj_ref = newSViv(0);
	SV*		obj = newSVrv(obj_ref, class);

	client = tracker_connect(FALSE);
	if(!client)
		return &PL_sv_undef;

	sv_setiv(obj, (IV)client);
	SvREADONLY_on(obj);
	return obj_ref;
}


void assert_valid_servicetype(int servicetype)
{
	if( (servicetype < SERVICE_MIN) || (servicetype > SERVICE_MAX) )
		croak("Invalid service type : %d\n", servicetype);
}


void assert_valid_mdtype(int mdtype)
{
	if( (mdtype < DATA_MIN) || (mdtype > DATA_MAX) )
		croak("Invalid metadata type : %d\n", mdtype);
}


char* service_name(char* class, int type)
{
	assert_valid_servicetype(type);
	return tracker_type_to_service_name(type);
}


int service_type(char* class, const char* name)
{
	return tracker_service_name_to_type(name);
}


void store_in_hash_and_free(gpointer key, gpointer value, gpointer perlhash)
{
	hv_store(perlhash, key, strlen(key), newSVpvn(value, strlen(value)), 0);
	free(key);
	free(value);
}

void store_in_array(gpointer data, gpointer perlarray)
{
	/* inspired from tracker-tag.c's get_meta_table_data */
	char **meta, **meta_p;
	int i = 0;

	meta = (char **) data;
	for(meta_p = meta; *meta_p; meta_p++) {
		if( i == 0 )
			av_push((AV *)perlarray, newSVpv(*meta_p, 0));
		i++;
	}
}

void DESTROY(SV* obj) {
	TrackerClient* client = (TrackerClient*) SvIV(SvRV(obj));
	tracker_disconnect(client);
}


MODULE = LibTracker::Client		PACKAGE = LibTracker::Client		
PROTOTYPES: DISABLE

INCLUDE: const-xs.inc

SV*
get_instance (class)
	char* class


char*
service_name (class, type)
	char* class;
	int type;


int
service_type (class, name)
	char* class;
	const char* name;


SV*
get_version (obj)
		SV* obj;
	PREINIT:
		int ret;
		GError *error = NULL;
		TrackerClient* client;
	CODE:
		client = (TrackerClient*) SvIV(SvRV(obj));
		ST(0) = sv_newmortal();
		ret = tracker_get_version(client, &error);
		if(error)
			ST(0) = &PL_sv_undef;
		else
			sv_setiv( ST(0), ret );


SV*
get_status (obj)
		SV* obj;
	PREINIT:
		char* ret;
		GError *error = NULL;
		TrackerClient* client;
	CODE:
		client = (TrackerClient*) SvIV(SvRV(obj));
		ST(0) = sv_newmortal();
		ret = tracker_get_status(client, &error);
		if(error)
			ST(0) = &PL_sv_undef;
		else
			sv_setpv( ST(0), ret );
		free(ret);


SV*
get_services (obj, main_only)
		SV* obj;
		bool main_only;
	PREINIT:
		GHashTable* ret;
		GError *error = NULL;
		TrackerClient* client;
	INIT:
		HV* rh;
	CODE:
		main_only = (!!main_only);	/* either 0 or 1 */
		client = (TrackerClient*) SvIV(SvRV(obj));
		ret = tracker_get_services(client, main_only, &error);
		rh = (HV *) sv_2mortal( (SV *) newHV() );
		if(error)
			RETVAL = &PL_sv_undef;
		else {
			g_hash_table_foreach( ret, store_in_hash_and_free, (gpointer) rh );
			RETVAL = newRV( (SV *) rh);
		}
	OUTPUT:
		RETVAL


SV*
get_metadata (obj, servicetype, id, keys)
		SV* obj;
		int servicetype;
		const char* id;
		SV* keys;
	PREINIT:
		char** ret;
		char** _keys;
		char* placeholder;
		STRLEN length;
		GError *error = NULL;
		TrackerClient* client;
	INIT:
		HV* rh;
		I32 numkeys = 0;
		int i;
		SV **current_val;
		if( (!SvROK(keys))
			|| ( SvTYPE( SvRV(keys) ) != SVt_PVAV )
			|| ( (numkeys = av_len( (AV *) SvRV(keys))) < 0 ) ) {
			XSRETURN_UNDEF;
		}
		assert_valid_servicetype(servicetype);
		/* convert keys to a char** - this is inspired from the
		 * avref2charptrptr function from perldap
		 */
		Newxz(_keys, numkeys + 2, char *);
		for (i = 0; i <= numkeys; i++) {
			current_val = av_fetch( (AV *) SvRV(keys), i, 0 );
			placeholder = SvPV(*current_val, length);
			/* store a copy in _keys */
			Newxz(_keys[i], length+1, char);
			Copy(placeholder, _keys[i], length+1, char);
		}
		_keys[i] = NULL;
	CODE:
		client = (TrackerClient*) SvIV(SvRV(obj));
		ret = tracker_metadata_get(client, servicetype, id, _keys, &error);
		rh = (HV *) sv_2mortal( (SV *) newHV() );
		if(error)
			RETVAL = &PL_sv_undef;
		else {
			for(i = 0; _keys[i] && ret[i]; i++)
				hv_store(rh, _keys[i], strlen(_keys[i]), newSVpv(ret[i], 0), 0);
			g_strfreev(ret);	/* don't leak anything */
			RETVAL = newRV( (SV *) rh);
		}
	OUTPUT:
		RETVAL


SV*
set_metadata (obj, servicetype, id, data)
		SV* obj;
		int servicetype;
		const char* id;
		SV* data;
	PREINIT:
		char** _keys;
		char** _values;
		char* placeholder;
		STRLEN length;
		I32 keylen;
		GError *error = NULL;
		TrackerClient* client;
	INIT:
		I32 numkeys = 0;
		int i;
		SV* current_val;
		HV* datahash;
		/* the iter_init prepares the hash iterator and gives us
		 * the number of keys in the hash
		 */
		if( (!SvROK(data))
			|| ( SvTYPE( SvRV(data) ) != SVt_PVHV )
			|| ( (numkeys = hv_iterinit((HV *)SvRV(data))) < 1 ) ) {
			XSRETURN_UNDEF;
		}
		else {
			datahash = (HV *) SvRV(data);
		}
		assert_valid_servicetype(servicetype);
		/* convert keys to a char** - this is inspired from the
		 * avref2charptrptr function from perldap
		 */
		Newxz(_keys, numkeys + 1, char *);
		Newxz(_values, numkeys + 1, char *);
		for (i = 0; i < numkeys; i++) {
			current_val = hv_iternextsv(datahash, &placeholder, &keylen);
			/* store the copy of the key in _keys */
			Newxz(_keys[i], keylen + 1, char);
			Copy(placeholder, _keys[i], keylen + 1, char);
			/* store the copy of the value in _values */
			placeholder = SvPV(current_val, length);
			Newxz(_values[i], length + 1, char);
			Copy(placeholder, _values[i], length + 1, char);
		}
		_keys[i] = NULL;
		_values[i] = NULL;
	CODE:
		client = (TrackerClient*) SvIV(SvRV(obj));
		tracker_metadata_set(client, servicetype, id, _keys, _values, &error);
		ST(0) = sv_newmortal();
		if(error)
			ST(0) = &PL_sv_undef;
		else
			sv_setiv( ST(0), numkeys );


void
register_metadata_type (obj, name, type)
		SV* obj;
		const char* name;
		int type;
	PREINIT:
		GError *error = NULL;
		TrackerClient* client;
	CODE:
		assert_valid_mdtype(type);
		client = (TrackerClient*) SvIV(SvRV(obj));
		tracker_metadata_register_type(client, name, type, &error);
		if(error)
			croak("tracker_metadata_register_type failed with code %d (%s)", error->code, error->message);


SV*
get_metadata_type_details (obj, name)
		SV* obj;
		const char* name;
	PREINIT:
		HV* args;
		I32 count;
		MetaDataTypeDetails* ret;
		GError *error = NULL;
		TrackerClient* client;
	CODE:
		client = (TrackerClient*) SvIV(SvRV(obj));
		ret = tracker_metadata_get_type_details(client, name, &error);
		if(error)
			RETVAL = &PL_sv_undef;
		else {
			ENTER;
			SAVETMPS;
			/* set up a hashref for args to "new" */
			args = (HV *) sv_2mortal( (SV *) newHV() );
			hv_store(args, "type", 4, newSVpv(ret->type, 0), 0);
			hv_store(args, "is_embedded", 11, newSViv(ret->is_embedded), 0);
			hv_store(args, "is_writeable", 12, newSViv(ret->is_writeable), 0);
			free(ret);
			/* instantiate new MetadataTypeDetails object */
			PUSHMARK(SP);
			XPUSHs(sv_2mortal(newSVpv("LibTracker::Client::MetaDataTypeDetails", 0)));
			XPUSHs(sv_2mortal(newRV((SV*)args)));
			PUTBACK;
			count = call_method("new", G_SCALAR);
			SPAGAIN;
			if(count != 1)
				croak("LibTracker::Client::MetaDataTypeDetails->new returned unexpected number of args. Expected 1, got %d", count);
			RETVAL = newSVsv((SV *)POPs);
			PUTBACK;
			FREETMPS;
			LEAVE;
		}
	OUTPUT:
		RETVAL


SV*
get_registered_metadata_classes (obj)
		SV* obj;
	PREINIT:
		char** ret;
		I32 i;
		GError *error = NULL;
		TrackerClient* client;
		AV* ra;
	CODE:
		client = (TrackerClient*) SvIV(SvRV(obj));
		ret = tracker_metadata_get_registered_classes(client, &error);
		ra = (AV *) sv_2mortal( (SV *) newAV() );
		if(error)
			RETVAL = &PL_sv_undef;
		else {
			for(i = 0; ret[i]; i++)
				av_push(ra, newSVpv(ret[i], 0));
			RETVAL = newRV( (SV *) ra);
			g_strfreev(ret);	/* don't leak */
		}
	OUTPUT:
		RETVAL


SV*
get_registered_metadata_types (obj, classname)
		SV* obj;
		const char* classname;
	PREINIT:
		char** ret;
		I32 i;
		GError *error = NULL;
		TrackerClient* client;
		AV* ra;
	CODE:
		client = (TrackerClient*) SvIV(SvRV(obj));
		ret = tracker_metadata_get_registered_types(client, classname, &error);
		ra = (AV *) sv_2mortal( (SV *) newAV() );
		if(error)
			RETVAL = &PL_sv_undef;
		else {
			for(i = 0; ret[i]; i++)
				av_push(ra, newSVpv(ret[i], 0));
			RETVAL = newRV( (SV *) ra);
			g_strfreev(ret);	/* don't leak */
		}
	OUTPUT:
		RETVAL


SV*
get_writeable_metadata_types (obj, classname)
		SV* obj;
		const char* classname;
	PREINIT:
		char** ret;
		I32 i;
		GError *error = NULL;
		TrackerClient* client;
		AV* ra;
	CODE:
		client = (TrackerClient*) SvIV(SvRV(obj));
		ret = tracker_metadata_get_writeable_types(client, classname, &error);
		ra = (AV *) sv_2mortal( (SV *) newAV() );
		if(error)
			RETVAL = &PL_sv_undef;
		else {
			for(i = 0; ret[i]; i++)
				av_push(ra, newSVpv(ret[i], 0));
			RETVAL = newRV( (SV *) ra);
			g_strfreev(ret);	/* don't leak */
		}
	OUTPUT:
		RETVAL


SV*
get_all_keywords (obj, servicetype)
		SV* obj;
		int servicetype;
	PREINIT:
		GPtrArray* ret;
		GError *error = NULL;
		TrackerClient* client;
		AV* ra;
	CODE:
		assert_valid_servicetype(servicetype);
		client = (TrackerClient*) SvIV(SvRV(obj));
		ret = tracker_keywords_get_list(client, servicetype, &error);
		ra = (AV *) sv_2mortal( (SV *) newAV() );
		if(error)
			RETVAL = &PL_sv_undef;
		else {
			g_ptr_array_foreach(ret, store_in_array, (gpointer)ra);
			RETVAL = newRV( (SV *) ra);
			g_ptr_array_free(ret, TRUE);	/* don't leak */
		}
	OUTPUT:
		RETVAL


SV*
get_keywords (obj, servicetype, id)
		SV* obj;
		int servicetype;
		const char* id;
	PREINIT:
		char** ret;
		I32 i;
		GError *error = NULL;
		TrackerClient* client;
		AV* ra;
	CODE:
		assert_valid_servicetype(servicetype);
		client = (TrackerClient*) SvIV(SvRV(obj));
		ret = tracker_keywords_get(client, servicetype, id, &error);
		ra = (AV *) sv_2mortal( (SV *) newAV() );
		if(error)
			RETVAL = &PL_sv_undef;
		else {
			for(i = 0; ret[i]; i++)
				av_push(ra, newSVpv(ret[i], 0));
			RETVAL = newRV( (SV *) ra);
			g_strfreev(ret);	/* don't leak */
		}
	OUTPUT:
		RETVAL


SV*
add_keywords (obj, servicetype, id, values)
		SV* obj;
		int servicetype;
		const char* id;
		SV* values;
	PREINIT:
		char** _values;
		char* placeholder;
		STRLEN length;
		GError *error = NULL;
		TrackerClient* client;
	INIT:
		I32 num = 0;
		I32 i;
		SV **current_val;
		if( (!SvROK(values))
			|| ( SvTYPE( SvRV(values) ) != SVt_PVAV )
			|| ( (num = av_len( (AV *) SvRV(values))) < 0 ) ) {
			XSRETURN_UNDEF;
		}
		assert_valid_servicetype(servicetype);
		/* convert keys to a char** - this is inspired from the
		 * avref2charptrptr function from perldap
		 */
		Newxz(_values, num + 2, char *); /* av_len returns elem-1 */
		for (i = 0; i <= num; i++) {
			current_val = av_fetch( (AV *) SvRV(values), i, 0 );
			placeholder = SvPV(*current_val, length);
			/* store a copy in _values */
			Newxz(_values[i], length+1, char);
			Copy(placeholder, _values[i], length+1, char);
		}
		_values[i] = NULL;
	CODE:
		client = (TrackerClient*) SvIV(SvRV(obj));
		tracker_keywords_add(client, servicetype, id, _values, &error);
		ST(0) = sv_newmortal();
		if(error)
			ST(0) = &PL_sv_undef;
		else
			sv_setiv( ST(0), num + 1);


SV*
remove_keywords (obj, servicetype, id, values)
		SV* obj;
		int servicetype;
		const char* id;
		SV* values;
	PREINIT:
		char** _values;
		char* placeholder;
		STRLEN length;
		GError *error = NULL;
		TrackerClient* client;
	INIT:
		I32 num = 0;
		I32 i;
		SV **current_val;
		if( (!SvROK(values))
			|| ( SvTYPE( SvRV(values) ) != SVt_PVAV )
			|| ( (num = av_len( (AV *) SvRV(values))) < 0 ) ) {
			XSRETURN_UNDEF;
		}
		assert_valid_servicetype(servicetype);
		/* convert keys to a char** - this is inspired from the
		 * avref2charptrptr function from perldap
		 */
		Newxz(_values, num + 2, char *); /* av_len returns elem+1 */
		for (i = 0; i <= num; i++) {
			current_val = av_fetch( (AV *) SvRV(values), i, 0 );
			placeholder = SvPV(*current_val, length);
			/* store a copy in _values */
			Newxz(_values[i], length+1, char);
			Copy(placeholder, _values[i], length+1, char);
		}
		_values[i] = NULL;
	CODE:
		client = (TrackerClient*) SvIV(SvRV(obj));
		tracker_keywords_remove(client, servicetype, id, _values, &error);
		ST(0) = sv_newmortal();
		if(error)
			ST(0) = &PL_sv_undef;
		else
			sv_setiv( ST(0), num + 1);


SV*
remove_all_keywords (obj, servicetype, id)
		SV* obj;
		int servicetype;
		const char* id;
	PREINIT:
		GError *error = NULL;
		TrackerClient* client;
	CODE:
		assert_valid_servicetype(servicetype);
		client = (TrackerClient*) SvIV(SvRV(obj));
		tracker_keywords_remove_all(client, servicetype, id, &error);
		ST(0) = sv_newmortal();
		if(error)
			ST(0) = &PL_sv_undef;
		else
			ST(0) = &PL_sv_yes;


SV*
search_keywords (obj, lqi, servicetype, keywords, offset, maxhits)
		SV* obj;
		int lqi;
		int servicetype;
		SV* keywords;
		int offset;
		int maxhits;
	PREINIT:
		char** ret;
		char** _keywords;
		char* placeholder;
		STRLEN length;
		GError *error = NULL;
		TrackerClient* client;
		AV* ra;
	INIT:
		I32 num = 0;
		I32 i;
		SV **current_val;
		if( (!SvROK(keywords))
			|| ( SvTYPE( SvRV(keywords) ) != SVt_PVAV )
			|| ( (num = av_len( (AV *) SvRV(keywords))) < 0 ) ) {
			XSRETURN_UNDEF;
		}
		assert_valid_servicetype(servicetype);
		/* convert keywords to a char** - this is inspired from the
		 * avref2charptrptr function from perldap
		 */
		Newxz(_keywords, num + 2, char *);
		for (i = 0; i <= num; i++) {
			current_val = av_fetch( (AV *) SvRV(keywords), i, 0 );
			placeholder = SvPV(*current_val, length);
			/* store a copy in _keywords */
			Newxz(_keywords[i], length+1, char);
			Copy(placeholder, _keywords[i], length+1, char);
		}
		_keywords[i] = NULL;
	CODE:
		client = (TrackerClient*) SvIV(SvRV(obj));
		ret = tracker_keywords_search(client, lqi, servicetype, _keywords, offset, maxhits, &error);
		ra = (AV *) sv_2mortal( (SV *) newAV() );
		if(error)
			RETVAL = &PL_sv_undef;
		else {
			for(i = 0; ret[i]; i++)
				av_push(ra, newSVpv(ret[i], 0));
			RETVAL = newRV( (SV *) ra);
			g_strfreev(ret);	/* don't leak */
		}
	OUTPUT:
		RETVAL


SV*
search_text (obj, lqi, servicetype, searchtext, offset, maxhits)
		SV* obj;
		int lqi;
		int servicetype;
		const char* searchtext;
		int offset;
		int maxhits;
	PREINIT:
		I32 i;
		char** ret;
		GError *error = NULL;
		TrackerClient* client;
		AV* ra;
	CODE:
		assert_valid_servicetype(servicetype);
		client = (TrackerClient*) SvIV(SvRV(obj));
		ret = tracker_search_text(client, lqi, servicetype, searchtext, offset, maxhits, &error);
		ra = (AV *) sv_2mortal( (SV *) newAV() );
		if(error)
			RETVAL = &PL_sv_undef;
		else {
			for(i = 0; ret[i]; i++)
				av_push(ra, newSVpv(ret[i], 0));
			RETVAL = newRV( (SV *) ra);
			g_strfreev(ret);	/* don't leak */
		}
	OUTPUT:
		RETVAL


SV*
get_snippet (obj, servicetype, path, searchtext)
		SV* obj;
		int servicetype;
		const char* path;
		const char* searchtext;
	PREINIT:
		char* ret;
		GError *error = NULL;
		TrackerClient* client;
	CODE:
		assert_valid_servicetype(servicetype);
		client = (TrackerClient*) SvIV(SvRV(obj));
		ST(0) = sv_newmortal();
		ret = tracker_search_get_snippet(client, servicetype, path, searchtext, &error);
		if(error)
			ST(0) = &PL_sv_undef;
		else
			sv_setpv( ST(0), ret );
		free(ret);


SV*
search_metadata (obj, servicetype, field, searchtext, offset, maxhits)
		SV* obj;
		int servicetype;
		const char* field;
		const char* searchtext;
		int offset;
		int maxhits;
	PREINIT:
		I32 i;
		char** ret;
		GError *error = NULL;
		TrackerClient* client;
		AV* ra;
	CODE:
		assert_valid_servicetype(servicetype);
		client = (TrackerClient*) SvIV(SvRV(obj));
		ret = tracker_search_metadata(client, servicetype, field, searchtext, offset, maxhits, &error);
		ra = (AV *) sv_2mortal( (SV *) newAV() );
		if(error)
			RETVAL = &PL_sv_undef;
		else {
			for(i = 0; ret[i]; i++)
				av_push(ra, newSVpv(ret[i], 0));
			RETVAL = newRV( (SV *) ra);
			g_strfreev(ret);	/* don't leak */
		}
	OUTPUT:
		RETVAL


SV*
get_suggestion (obj, searchtext, maxdist)
		SV* obj;
		const char* searchtext;
		int maxdist;
	PREINIT:
		char* ret;
		GError *error = NULL;
		TrackerClient* client;
	CODE:
		client = (TrackerClient*) SvIV(SvRV(obj));
		ST(0) = sv_newmortal();
		ret = tracker_search_suggest(client,searchtext, maxdist, &error);
		if(error)
			ST(0) = &PL_sv_undef;
		else
			sv_setpv( ST(0), ret );
		free(ret);


SV*
get_files_by_service (obj, lqi, servicetype, offset, maxhits)
		SV* obj;
		int lqi;
		int servicetype;
		int offset;
		int maxhits;
	PREINIT:
		I32 i;
		char** ret;
		GError *error = NULL;
		TrackerClient* client;
		AV* ra;
	CODE:
		assert_valid_servicetype(servicetype);
		client = (TrackerClient*) SvIV(SvRV(obj));
		ret = tracker_files_get_by_service_type(client, lqi, servicetype, offset, maxhits, &error);
		ra = (AV *) sv_2mortal( (SV *) newAV() );
		if(error)
			RETVAL = &PL_sv_undef;
		else {
			for(i = 0; ret[i]; i++)
				av_push(ra, newSVpv(ret[i], 0));
			RETVAL = newRV( (SV *) ra);
			g_strfreev(ret);	/* don't leak */
		}
	OUTPUT:
		RETVAL


void
DESTROY (obj)
		SV* obj
	PREINIT:
		I32* temp;
	PPCODE:
		/* this is stolen from Inline::C documentation */
		temp = PL_markstack_ptr++;
		DESTROY(obj);
		if(PL_markstack_ptr != temp) {
			/* truly void, because dXSARGS not invoked */
			PL_markstack_ptr = temp;
			XSRETURN_EMPTY;
		}
		/* must have used dXSARGS; list context implied */
		return;	/* assume stack size is correct */


