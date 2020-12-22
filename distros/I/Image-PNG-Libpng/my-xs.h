/* Fetch a value "field" from a hash. */

#define HASH_FETCH(hash,field)     {                            \
	SV ** field_sv_ptr = hv_fetch (hash, #field,		\
				       strlen (#field), 0);	\
	if (! field_sv_ptr) {					\
	    croak ("Required key '%s' not in '%s'",		\
		   #field, #hash);				\
	}							\
	field_sv = * field_sv_ptr;				\
    }								\

#define HASH_FETCH_IV(hash,field) {                             \
        SV * field_sv;                                          \
        HASH_FETCH (hash, field);                               \
        field = SvIV (field_sv);                                \
    }

/* If "hash" does not contain "field", do not complain but just skip
   that field. */

#define HASH_FETCH_IV_MEMBER(hash,field,str) {                  \
        SV ** field_sv_ptr = hv_fetch (hash, #field,            \
                                       strlen (#field), 0);     \
        if (field_sv_ptr) {                                     \
            SV * field_sv;                                      \
            field_sv = * field_sv_ptr;                          \
            str->field = SvIV (field_sv);                       \
        }                                                       \
    }

#define HASH_FETCH_PV(hash,field) {                             \
        SV * field_sv;                                          \
        HASH_FETCH (hash, field);                               \
        field = SvPV (field_sv, field ## _length);              \
    }

#define HASH_FETCH_PV_MEMBER(hash,field,str) {			\
        SV * field_sv;                                          \
        HASH_FETCH (hash, field);                               \
        str->field = SvPV (field_sv, field ## _length);		\
    }

#define HASH_FETCH_AV(hash,field) {			\
	SV * field_sv;					\
	HASH_FETCH (hash, field);			\
	if (SvROK (field_sv) &&				\
	    SvTYPE (SvRV (field_sv)) == SVt_PVAV) {	\
	    field = (AV *) SvRV (field_sv);		\
	}						\
	else {						\
	    field = 0;					\
	}						\
    }

#define HASH_STORE(hash,field,something)				\
    (void) hv_store (hash, #field, strlen (#field), something, 0)

#define HASH_STORE_PV(hash,field)                                       \
    (void) hv_store (hash, #field, strlen (#field),			\
		     newSVpv (field, strlen (field)), 0)

#define HASH_STORE_PV_MEMBER(hash,field,str)				\
    (void) hv_store (hash, #field, strlen (#field),			\
		     newSVpv (str->field, strlen (str->field)), 0)

#define HASH_STORE_AV(hash,field)                                       \
    (void) hv_store (hash, #field, strlen (#field), \
		     newRV_inc ((SV *) field), 0)

#define HASH_STORE_IV(hash,field)                            \
    (void) hv_store (hash, #field, strlen (#field),			\
		     newSViv (field), 0)

#define HASH_STORE_IV_MEMBER(hash,field,str)                            \
    (void) hv_store (hash, #field, strlen (#field),			\
		     newSViv (str->field), 0)

/* TODO: Dereferencing the av_fetch pointer like this is dangerous,
   these macros need to be changed. */

#define ARRAY_FETCH_PV(array,n,value,length)	\
    {						\
	SV * sv;				\
	sv = * av_fetch (array, n, 0);		\
	value = SvPV (sv, length);		\
    }

#define ARRAY_FETCH_IV(array,n,value)		\
    {						\
	SV * sv;				\
	sv = * av_fetch (array, n, 0);		\
	value = SvIV (sv);			\
    }

#define ARRAY_STORE_PV(array,value)		\
    {						\
	SV * sv;				\
	sv = newSVpv (value, strlen (value));	\
	av_push (array, sv);			\
    }
