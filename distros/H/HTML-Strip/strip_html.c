#include <stdio.h>
#include <ctype.h>
#include <string.h>

#include "strip_html.h"

#ifdef _MSC_VER
#define strcasecmp(a,b) stricmp(a,b)
#endif

static int utf8_char_width(unsigned char * string);

void
_strip_html( Stripper * stripper, char * raw, char * output, int is_utf8_p ) {
  char * p_raw = raw;
  char * raw_end = raw + strlen(raw);
  char * p_output = output;
  int width;

  if( stripper->o_debug ) {
      printf( "[DEBUG] input string: %s\n", p_raw );
  }

  while( p_raw < raw_end ) {
    width = is_utf8_p ? utf8_char_width(p_raw) : 1;
    // either a single char or a set of unicode code points

    if( stripper->o_debug ) {
      printf( "[DEBUG] char:%C w%i state:%c%c%c tag:%5s last:%c%c%c%c in:%c%c%c quote:%c ",
        *p_raw,
        width,
        (stripper->f_closing ? 'C' : ' '),
        (stripper->f_in_tag ? 'T' : ' '),
        (stripper->f_full_tagname ? 'F' : ' '),
        stripper->tagname,
        (stripper->f_just_seen_tag ? 'T' : ' '),
        (stripper->f_outputted_space ? 'S' : ' '),
        (stripper->f_lastchar_slash ? '/' : ' '),
        (stripper->f_lastchar_minus ? '-' : ' '),
        (stripper->f_in_decl ? 'D' : ' '),
        (stripper->f_in_comment ? 'C' : ' '),
        (stripper->f_in_striptag ? 'X' : ' '),
        (stripper->f_in_quote ? stripper->quote : ' ')
      );
    }

    if( stripper->f_in_tag ) {
      /* inside a tag */
      /* check we don't know either the tagname, or that we're in a declaration */
      if( !stripper->f_full_tagname && !stripper->f_in_decl ) {
        /* if this is the first character, check if it's a '!'; if so, we're in a declaration */
        if( stripper->p_tagname == stripper->tagname && *p_raw == '!' ) {
          stripper->f_in_decl = 1;
        }
        /* then check if the first character is a '/', in which case, this is a closing tag */
        else if( stripper->p_tagname == stripper->tagname && *p_raw == '/' ) {
          stripper->f_closing = 1;
        }
        /* if the first character wasn't a '/', and we're in a stripped block,
         * assume any previous '<' was a mathematical operator and reset */
        else if( !stripper->f_closing && stripper->f_in_striptag && stripper->p_tagname == stripper->tagname && *p_raw != '/' ) {
          stripper->f_in_tag = 0;
          stripper->f_closing = 0;
        /* within a stripped tags block (e.g. scripts), we only care about closing tags
         * within normal tags, we care about both opening and closing tags */
        } else if( !stripper->f_in_striptag || stripper->f_closing ) {
          /* if we don't have the full tag name yet, add p_raw character unless it's whitespace, a '/', or a '>';
             otherwise null pad the string and set the full tagname flag, and check the tagname against stripped ones.
             also sanity check we haven't reached the array bounds, and truncate the tagname here if we have */
          if( (!isspace( *p_raw ) && *p_raw != '/' && *p_raw != '>') &&
              !( (stripper->p_tagname - stripper->tagname) == MAX_TAGNAMELENGTH ) ) {
            *stripper->p_tagname++ = *p_raw;
          } else {
            *stripper->p_tagname = 0;
            stripper->f_full_tagname = 1;
            /* if we're in a stripped tag block, and this is a closing tag, check to see if it ends the stripped block */
            if( stripper->f_in_striptag && stripper->f_closing ) {
              if( strcasecmp( stripper->tagname, stripper->striptag ) == 0 ) {
                stripper->f_in_striptag = 0;
              }
              /* if we're outside a stripped tag block, check if tagname represents a newline,
               * then check tagname against stripped tag list */
            } else if( !stripper->f_in_striptag && !stripper->f_closing ) {
              if( strcasecmp( stripper->tagname, "p" ) ||
                  strcasecmp( stripper->tagname, "br" ) ) {
                if( stripper->o_emit_newlines ) {
                  if( stripper->o_debug ) {
                    printf("NEWLINE ");
                  }
                  *p_output++ = '\n';
                  stripper->f_outputted_space = 1;
                }
              }
              int i;
              for( i = 0; i < stripper->numstriptags; i++ ) {
                if( strcasecmp( stripper->tagname, stripper->o_striptags[i] ) == 0 ) {
                  stripper->f_in_striptag = 1;
                  strcpy( stripper->striptag, stripper->tagname );
                  break;
                }
              }
            }
            check_end( stripper, *p_raw );
          }
        }
      }
      /* we know the tagname, or that we're in a decl */
      else {
        if( stripper->f_in_quote ) {
          /* inside a quote */
          /* end of quote if p_raw character matches the opening quote character */
          if( *p_raw == stripper->quote ) {
            stripper->quote = 0;
            stripper->f_in_quote = 0;
          }
        } else {
          /* not in a quote */
          /* check for quote characters, but not in a comment */
          if( !stripper->f_in_comment &&
              ( *p_raw == '\'' || *p_raw == '\"' ) ) {
            stripper->f_in_quote = 1;
            stripper->quote = *p_raw;
            /* reset lastchar_* flags in case we have something perverse like '-"' or '/"' */
            stripper->f_lastchar_minus = 0;
            stripper->f_lastchar_slash = 0;
          } else {
            if( stripper->f_in_decl ) {
              /* inside a declaration */
              if( stripper->f_lastchar_minus ) {
                /* last character was a minus, so if p_raw one is, then we're either entering or leaving a comment */
                if( *p_raw == '-' ) {
                  stripper->f_in_comment = !stripper->f_in_comment;
                }
                stripper->f_lastchar_minus = 0;
              } else {
                /* if p_raw character is a minus, we might be starting a comment marker */
                if( *p_raw == '-' ) {
                  stripper->f_lastchar_minus = 1;
                }
              }
              if( !stripper->f_in_comment ) {
                check_end( stripper, *p_raw );
              }
            } else {
              check_end( stripper, *p_raw );
            }
          } /* quote character check */
        } /* in quote check */
      } /* full tagname check */
    }
    else {
      /* not in a tag */
      /* check for tag opening, and reset parameters if one has */
      if( *p_raw == '<' ) {
        stripper->f_in_tag = 1;
        stripper->tagname[0] = 0;
        stripper->p_tagname = stripper->tagname;
        stripper->f_full_tagname = 0;
        stripper->f_closing = 0;
        stripper->f_just_seen_tag = 1;
      }
      else {
        /* copy to stripped provided we're not in a stripped block */
        if( !stripper->f_in_striptag ) {
          /* only emit spaces if we're configured to do so (on by default) */
          if( stripper->o_emit_spaces ){
            /* output a space in place of tags we have previously parsed,
               and set a flag so we only do this once for every group of tags.
               done here to prevent unnecessary trailing spaces */
            if( !isspace(*p_raw) &&
              /* don't output a space if this character is one anyway */
                !stripper->f_outputted_space &&
                stripper->f_just_seen_tag ) {
              if( stripper->o_debug ) {
                printf("SPACE ");
              }
              *p_output++ = ' ';
              stripper->f_outputted_space = 1;
            }
          }
          strncpy(p_output, p_raw, width);
          if( stripper->o_debug ) {
              printf("CHAR %c", *p_raw);
          }
          p_output += width;

          /* reset 'just seen tag' flag */
          stripper->f_just_seen_tag = 0;
          /* reset 'outputted space' flag if character is not one */
          if (!isspace(*p_raw)) {
            stripper->f_outputted_space = 0;
          } else {
            stripper->f_outputted_space = 1;
          }
        }
      }
    } /* in tag check */
    p_raw += width;
    if( stripper->o_debug ) {
      printf("\n");
    }
  } /* while loop */

  *p_output = 0;

  if (stripper->o_auto_reset) {
    _reset( stripper );
  }
}

static int
utf8_char_width(unsigned char * string) {
    if (~*string & 128) {                   // 0xxxxxxx
        return 1;
    } else if ((*string & 192) == 128) {      // 10xxxxxx
        /* latter bytes of a multibyte utf8 char
       XXX this should never happen in practice XXX
           but we account for it anyway */
        int width = 1;
        char * p = string;
        while ((*p++ & 192) == 128) {
            width++;
        }
        return width;
    } else if ((*string & 224) == 192) {      // 110xxxxx
        return 2;
    } else if ((*string & 240) == 224) {      // 1110xxxx
        return 3;
    } else if ((*string & 248) == 240) {      // 11110xxx
        return 4;
    /* part of original utf8 spec, but not used
    } else if ((*string & 252) == 248) {      // 111110xx
        return 5;
    } else if ((*string & 254) == 252) {      // 1111110x
        return 6;
    */
    } else {
        printf( "[WARN] invalid utf8 char ord=%i\n", *string );
        return 1;
    }
}

void
_reset( Stripper * stripper ) {
  stripper->f_in_tag = 0;
  stripper->f_closing = 0;
  stripper->f_lastchar_slash = 0;
  stripper->f_full_tagname = 0;
  /* hack to stop a space being output on strings starting with a tag */
  stripper->f_outputted_space = 1;
  stripper->f_just_seen_tag = 0;

  stripper->f_in_quote = 0;

  stripper->f_in_decl = 0;
  stripper->f_in_comment = 0;
  stripper->f_lastchar_minus = 0;

  stripper->f_in_striptag = 0;

  memset(stripper->tagname, 0, sizeof(stripper->tagname));
}

void
clear_striptags( Stripper * stripper ) {
  strcpy(stripper->o_striptags[0], "");
  stripper->numstriptags = 0;
}

void
add_striptag( Stripper * stripper, char * striptag ) {
  if( stripper->numstriptags < MAX_STRIPTAGS-1 ) {
    strcpy(stripper->o_striptags[stripper->numstriptags++], striptag);
  } else {
    fprintf( stderr, "Cannot have more than %i strip tags", MAX_STRIPTAGS );
  }
}

void
check_end( Stripper * stripper, char end ) {
  /* if p_raw character is a slash, may be a closed tag */
  if( end == '/' ) {
    stripper->f_lastchar_slash = 1;
  } else {
    /* if the p_raw character is a '>', then the tag has ended */
    /* slight hack to deal with mathematical characters in script tags:
     * if we're in a stripped block, and this is a closing tag, spaces
     * will also end the tag, since we only want it for comparison with
     * the opening one */
    if( (end == '>') ||
        (stripper->f_in_striptag && stripper->f_closing && isspace(end)) ) {
      stripper->f_in_quote = 0;
      stripper->f_in_comment = 0;
      stripper->f_in_decl = 0;
      stripper->f_in_tag = 0;
      stripper->f_closing = 0;
      /* Do not start a stripped tag block if the tag is a closed one, e.g. '<script src="foo" />' */
      if( stripper->f_lastchar_slash &&
          (strcasecmp( stripper->striptag, stripper->tagname ) == 0) ) {
        stripper->f_in_striptag = 0;
      }
    }
    stripper->f_lastchar_slash = 0;
  }
}
