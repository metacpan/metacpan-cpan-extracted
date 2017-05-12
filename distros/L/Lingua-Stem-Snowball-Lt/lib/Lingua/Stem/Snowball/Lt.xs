#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define NEED_sv_2pv_flags
#define NEED_sv_2pv_nolen
#include "../ppport.h"

#define NUMLANG 1
#define NUMSTEM 1

#include "include/libstemmer.h"

/* All Lingua::Stem::Snowball::Lt objects and all calls to stem(),
 * stem_in_place(), etc, reference the same set of Snowball struct
 * sb_stemmers, all held in the singleton object
 * $Lingua::Stem::Snowball::Lt::stemmifier, of class
 * Lingua::Stem::Snowball::Lt::Stemmifier.  Each sb_stemmer is created lazily, as
 * soon as there is a need for its unique combination of language and
 * encoding.  They are destroyed during global cleanup, when
 * $Lingua::Stem::Snowball::Lt::stemmifier is reclaimed.
 */

typedef struct Stemmifier {
    struct sb_stemmer **stemmers;
} Stemmifier;

typedef struct LangEnc {
    char *lang;
    char *encoding; /* the real name of the encoding */
    char *snowenc;  /* the variant that libstemmer_c needs */
} LangEnc;

LangEnc lang_encs[] = {
    { "lt", "UTF-8",      "UTF_8"      },
};

MODULE = Lingua::Stem::Snowball::Lt  PACKAGE = Lingua::Stem::Snowball::Lt

PROTOTYPES: disable 

BOOT:
{
    SV *sb_stemmer_list_sv   = newSViv(PTR2IV(sb_stemmer_list));
    SV *sb_stemmer_new_sv    = newSViv(PTR2IV(sb_stemmer_new));
    SV *sb_stemmer_delete_sv = newSViv(PTR2IV(sb_stemmer_delete));
    SV *sb_stemmer_stem_sv   = newSViv(PTR2IV(sb_stemmer_stem));
    SV *sb_stemmer_length_sv = newSViv(PTR2IV(sb_stemmer_length));
    hv_store(PL_modglobal, "Lingua::Stem::Snowball::Lt::sb_stemmer_list", 39,
        sb_stemmer_list_sv, 0);
    hv_store(PL_modglobal, "Lingua::Stem::Snowball::Lt::sb_stemmer_new", 38,
        sb_stemmer_new_sv, 0);
    hv_store(PL_modglobal, "Lingua::Stem::Snowball::Lt::sb_stemmer_delete", 41,
        sb_stemmer_delete_sv, 0);
    hv_store(PL_modglobal, "Lingua::Stem::Snowball::Lt::sb_stemmer_stem", 39,
        sb_stemmer_stem_sv, 0);
    hv_store(PL_modglobal, "Lingua::Stem::Snowball::Lt::sb_stemmer_length", 41,
        sb_stemmer_length_sv, 0);
}

void
_derive_stemmer(self_hash)
    HV *self_hash;
PPCODE:
{
    SV   **sv_ptr;
    char  *lang;
    char  *encoding;
    int    i;
    int    stemmer_id = -1;

    /* Extract lang and encoding member variables. */
    sv_ptr = hv_fetch(self_hash, "lang", 4, 0);
    if (!sv_ptr)
        croak("Couldn't find member variable 'lang'");
    lang = SvPV_nolen(*sv_ptr);
    sv_ptr = hv_fetch(self_hash, "encoding", 8, 0);
    if (!sv_ptr)
        croak("Couldn't find member variable 'encoding'");
    encoding = SvPV_nolen(*sv_ptr);

    /* See if the combo of lang and encoding is supported. */
    for(i = 0; i < NUMSTEM; i++) {
        if (   strcmp(lang,     lang_encs[i].lang)     == 0 
            && strcmp(encoding, lang_encs[i].encoding) == 0 
        ) {
            Stemmifier *stemmifier;
            SV         *stemmifier_sv;

            /* We have a match, so we know the stemmer id now. */
            stemmer_id = i;

            /* Retrieve communal Stemmifier. */
            stemmifier_sv = get_sv("Lingua::Stem::Snowball::Lt::stemmifier", TRUE);
            if (   sv_isobject(stemmifier_sv)
                && sv_derived_from(stemmifier_sv, 
                    "Lingua::Stem::Snowball::Lt::Stemmifier")
            ) {
                IV tmp = SvIV(SvRV(stemmifier_sv));
                stemmifier = INT2PTR(Stemmifier*, tmp);
            }
            else {
                croak("$L::S::S::stemmifier isn't a Stemmifier");
            }

            /* Construct a stemmer for lang/enc if there isn't one yet. */
            if ( ! stemmifier->stemmers[stemmer_id] ) {
                stemmifier->stemmers[stemmer_id] 
                    = sb_stemmer_new(lang, lang_encs[stemmer_id].snowenc);
                if ( ! stemmifier->stemmers[stemmer_id]  ) {
                    croak("Failed to allocate an sb_stemmer for %s %s", lang,
                        encoding);
                }
            } 

            break;
        }
    }

    /* Set the value of $self->{stemmer_id}. */
    sv_ptr = hv_fetch(self_hash, "stemmer_id", 10, 0);
    if (!sv_ptr)
        croak("Couldn't access $self->{stemmer_id}");
    sv_setiv(*sv_ptr, stemmer_id);
}

bool
_validate_language(language)
    char *language;
CODE:
{
    int i;
    RETVAL = FALSE;
    for (i = 0; i < NUMLANG; i++) {
        if ( strcmp(language, lang_encs[i].lang) == 0 ) RETVAL = TRUE;
    }
}
OUTPUT: RETVAL

void
stem_in_place(self_hash, words_av)
    HV  *self_hash;
    AV  *words_av;
PPCODE:
{
    IV stemmer_id;
    SV **sv_ptr;
    Stemmifier *stemmifier;
    SV *stemmifier_sv;
    
    /* Retrieve the stemmifier. */
    stemmifier_sv = get_sv("Lingua::Stem::Snowball::Lt::stemmifier", TRUE);
    if (   sv_isobject(stemmifier_sv)
        && sv_derived_from(stemmifier_sv, "Lingua::Stem::Snowball::Lt::Stemmifier")
    ) {
        IV tmp = SvIV(SvRV(stemmifier_sv));
        stemmifier = INT2PTR(Stemmifier*, tmp);
    }
    else {
        croak("$Lingua::Stem::Snowball::Lt::stemmifier isn't a Stemmifier");
    }

    /* Figure out which sb_stemmer to use. */
    sv_ptr = hv_fetch(self_hash, "stemmer_id", 10, 0);
    if (!sv_ptr)
        croak("Couldn't access stemmer_id");
    stemmer_id = SvIV(*sv_ptr);
    if (   stemmer_id < 0 
        || stemmer_id >= NUMSTEM 
        || stemmifier->stemmers[stemmer_id] == NULL
    ) {
        dSP;
        ENTER;
        SAVETMPS;
        PUSHMARK(SP);
        XPUSHs(ST(0));
        PUTBACK;
        call_method("_derive_stemmer", G_DISCARD);
        FREETMPS;
        LEAVE;
    
        /* Extract what should now be a valid stemmer_id. */
        sv_ptr = hv_fetch(self_hash, "stemmer_id", 10, 0);
        stemmer_id = SvIV(*sv_ptr);
    }
	if (stemmer_id != -1) {
		struct sb_stemmer *stemmer = stemmifier->stemmers[stemmer_id];
        IV i, max;

		for (i = 0, max = av_len(words_av); i <= max; i++) {
			sv_ptr = av_fetch(words_av, i, 0);
			if (SvOK(*sv_ptr)) {
                STRLEN len;
                sb_symbol *input_text = (sb_symbol*)SvPV(*sv_ptr, len);
                const sb_symbol *stemmed_output 
                    = sb_stemmer_stem(stemmer, input_text, (int)len);
                len = sb_stemmer_length(stemmer);
                sv_setpvn(*sv_ptr, (char*)stemmed_output, len);
            }
		}
	}
}

MODULE = Lingua::Stem::Snowball::Lt PACKAGE = Lingua::Stem::Snowball::Lt::Stemmifier

SV*
new(class_name)
    char* class_name;
CODE:
{
    Stemmifier *stemmifier;
    New(0, stemmifier, 1, Stemmifier);
    Newz(0, stemmifier->stemmers, NUMSTEM, struct sb_stemmer*);
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, class_name, (void*)stemmifier);
}
OUTPUT: RETVAL

void
DESTROY(self_sv)
    SV *self_sv;
PPCODE:
{
    int i;
    IV temp = SvIV( SvRV(self_sv) );
    Stemmifier *stemmifier = INT2PTR(Stemmifier*, temp);
    for (i = 0; i < NUMSTEM; i++) {
        if (stemmifier->stemmers[i] != NULL)
            sb_stemmer_delete(stemmifier->stemmers[i]);
    }
    Safefree(stemmifier);
}

