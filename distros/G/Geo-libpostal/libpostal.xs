#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <string.h>
#include <libpostal/libpostal.h>

short LP_SETUP = 0,
      LP_SETUP_LANGCLASS = 0,
      LP_SETUP_PARSER = 0;

MODULE = Geo::libpostal PACKAGE = Geo::libpostal PREFIX = lp_
PROTOTYPES: ENABLED

void
lp__teardown()
  PPCODE:
  if (LP_SETUP) {
    libpostal_teardown();
    LP_SETUP = 0;
  }
  if (LP_SETUP_LANGCLASS) {
    libpostal_teardown_language_classifier();
    LP_SETUP_LANGCLASS  = 0;
  }
  if (LP_SETUP_PARSER) {
    libpostal_teardown_parser();
    LP_SETUP_PARSER  = 0;
  }
  /* return undef */
  EXTEND(SP, 1);
  PUSHs(sv_newmortal());

void
lp_expand_address(address, ...)
  SV *address
  PREINIT:
    char *src, *option_name;
    size_t src_len, option_len, i, j, num_expansions, num_langs, exp_len, lang_len, components;
    AV *languages_av;
    SV **lang;
    char **languages = NULL;
  PPCODE:
    /* lazy load libpostal */
    if (!LP_SETUP) {
      if (!libpostal_setup()) {
        croak("libpostal_setup() failed");
      }
      LP_SETUP = 1;
    }

    if (!LP_SETUP_LANGCLASS) {
      if(!libpostal_setup_language_classifier()) {
        croak("libpostal_setup_language_classifier failed");
      }
      LP_SETUP_LANGCLASS = 1;
    }

    /* call fetch() if a tied variable to populate the sv */
    SvGETMAGIC(address);

    /* check for undef */
    if (!SvOK(address) || !SvCUR(address))
    {
      croak("expand_address() requires a scalar argument to expand!");
    }

    /* copy the sv without the magic struct and populate src_len*/
    src = SvPV_nomg(address, src_len);

    libpostal_normalize_options_t options = libpostal_get_default_options();

    /* parse optional args */
    if (((items - 1) % 2) != 0)
      croak("Odd number of options in call to expand_address()");

    for (i = 1; i < items; i += 2) {
      if (!SvOK(ST(i)) || !SvCUR(ST(i)))
        croak("expand_address() option names cannot be empty");

      SvGETMAGIC(ST(i));
      option_name = SvPV_nomg(ST(i), option_len);
      SvGETMAGIC(ST(i+1));

      /* process arrayref of lang codes option */
      if (!strncmp("languages", option_name, option_len)) {

        /* check its an arrayref */
       if (!SvROK(ST(i+1)) || SvTYPE(SvRV(ST(i+1))) != SVt_PVAV)
         croak("expand_address() languages option must be an arrayref");

       /* dereference the arrayref */
       languages_av = (AV*)SvRV(ST(i+1));

       /* av_len returns the highest index, not the length */
       num_langs = av_len(languages_av) + 1;

       languages = malloc(sizeof(char *) * num_langs);

       /* loop through the array assigning the languages */
       for (j = 0; j < num_langs; j++) {
         lang = av_fetch(languages_av, j, 0);
         /* must check for null pointers */
         if (lang == NULL) {
           croak("expand_address() languages option value must not be undef");
         }
         else {
           languages[j] = strdup(SvPV_nomg(*lang, lang_len));
         }
       }
       options.languages = (char **)languages;
       options.num_languages = num_langs;
      }
      /* process address_components bitmask */
      else if (!strncmp("components", option_name, option_len)) {
        /* only extract the bottom 16bits */
        if (SvIOK(ST(i+1))) {
          components = SvIV(ST(i+1));
          options.address_components = (components >> 0) & 0x1298;
        }
        else {
          options.address_components = 0;
        }
      }
      /* process boolean options */
      else if (!strncmp("latin_ascii", option_name, option_len)) {
        options.latin_ascii = SvTRUE(ST(i+1));
      }
      else if (!strncmp("transliterate", option_name, option_len)) {
        options.transliterate = SvTRUE(ST(i+1));
      }
      else if (!strncmp("strip_accents", option_name, option_len)) {
        options.strip_accents = SvTRUE(ST(i+1));
      }
      else if (!strncmp("decompose", option_name, option_len)) {
        options.decompose = SvTRUE(ST(i+1));
      }
      else if (!strncmp("lowercase", option_name, option_len)) {
        options.lowercase = SvTRUE(ST(i+1));
      }
      else if (!strncmp("trim_string", option_name, option_len)) {
        options.trim_string = SvTRUE(ST(i+1));
      }
      else if (!strncmp("drop_parentheticals", option_name, option_len)) {
        options.drop_parentheticals = SvTRUE(ST(i+1));
      }
      else if (!strncmp("replace_numeric_hyphens", option_name, option_len)) {
        options.replace_numeric_hyphens = SvTRUE(ST(i+1));
      }
      else if (!strncmp("delete_numeric_hyphens", option_name, option_len)) {
        options.delete_numeric_hyphens = SvTRUE(ST(i+1));
      }
      else if (!strncmp("split_alpha_from_numeric", option_name, option_len)) {
        options.split_alpha_from_numeric = SvTRUE(ST(i+1));
      }
      else if (!strncmp("replace_word_hyphens", option_name, option_len)) {
        options.replace_word_hyphens = SvTRUE(ST(i+1));
      }
      else if (!strncmp("delete_word_hyphens", option_name, option_len)) {
        options.delete_word_hyphens = SvTRUE(ST(i+1));
      }
      else if (!strncmp("delete_final_periods", option_name, option_len)) {
        options.delete_final_periods = SvTRUE(ST(i+1));
      }
      else if (!strncmp("delete_acronym_periods", option_name, option_len)) {
        options.delete_acronym_periods = SvTRUE(ST(i+1));
      }
      else if (!strncmp("drop_english_possessives", option_name, option_len)) {
        options.drop_english_possessives = SvTRUE(ST(i+1));
      }
      else if (!strncmp("delete_apostrophes", option_name, option_len)) {
        options.delete_apostrophes = SvTRUE(ST(i+1));
      }
      else if (!strncmp("expand_numex", option_name, option_len)) {
        options.expand_numex = SvTRUE(ST(i+1));
      }
      else if (!strncmp("roman_numerals", option_name, option_len)) {
        options.roman_numerals = SvTRUE(ST(i+1));
      }
      else {
        croak("Unrecognised parameter: '%"SVf"'", ST(i));
      }
    }
    char **expansions = libpostal_expand_address(src, options, &num_expansions);

    /* extend stack pointer with num of return values */
    EXTEND(SP, num_expansions);

    /* push return values onto stack pointer */
    for (i = 0; i < num_expansions; i++) {
      exp_len = strlen(expansions[i]);
      PUSHs( sv_2mortal(newSVpvn(expansions[i], exp_len)) );
    }

    /* Free data */
    if (languages != NULL) {
      for (i = 0; i < num_langs; i++) {
        free(languages[i]);
      }
      free(languages);
    }
    libpostal_expansion_array_destroy(expansions, num_expansions);

void
lp_parse_address(address, ...)
    SV *address
  PREINIT:
    char *src, *option_name;
    size_t src_len, option_len, i, label_len, component_len;
  PPCODE:
    /* lazy load libpostal */
    if (!LP_SETUP) {
      if (!libpostal_setup()) {
        croak("libpostal_setup() failed");
      }
      LP_SETUP = 1;
    }

    if (!LP_SETUP_PARSER) {
      if(!libpostal_setup_parser()) {
        croak("libpostal_setup_parser() failed");
      }
      LP_SETUP_PARSER = 1;
    }

    /* call fetch() if a tied variable to populate the sv */
    SvGETMAGIC(address);

    /* check for undef */
    if (!SvOK(address) || !SvCUR(address))
    {
      croak("parse_address() requires a scalar argument to parse!");
    }

    /* copy the sv without the magic struct and populate src_len*/
    src = SvPV_nomg(address, src_len);

    libpostal_address_parser_options_t options = libpostal_get_address_parser_default_options();

    /* parse optional args
     * N.B. These are ignored by libpostal
     * */
    if (((items - 1) % 2) != 0)
      croak("Odd number of options in call to parse_address()");

    for (i = 1; i < items; i += 2) {
      if (!SvOK(ST(i)))
        croak("parse_address() option names cannot be undef");

      SvGETMAGIC(ST(i));
      option_name = SvPV_nomg(ST(i), option_len);
      SvGETMAGIC(ST(i+1));

      if (option_len && !strncmp("language", option_name, option_len)) {
        options.language = SvPV_nomg(ST(i), option_len);
      }
      else if (option_len && !strncmp("country", option_name, option_len)) {
        options.country = SvPV_nomg(ST(i), option_len);
      }
      else {
        croak("Unrecognised parameter: '%"SVf"'", ST(i));
      }
    }

    libpostal_address_parser_response_t *parsed = libpostal_parse_address(src, options);

    /* extend stack pointer with num of return values */
    EXTEND(SP, parsed->num_components * 2);

    /* push return values onto stack pointer */
    for (i = 0; i < parsed->num_components; i++) {
      label_len = strlen(parsed->labels[i]);
      PUSHs( sv_2mortal(newSVpvn(parsed->labels[i], label_len)) );
      component_len = strlen(parsed->components[i]);
      PUSHs( sv_2mortal(newSVpvn(parsed->components[i], component_len)) );
    }

    /* Free parse result */
    libpostal_address_parser_response_destroy(parsed);
