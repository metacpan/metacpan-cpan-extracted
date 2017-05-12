#define MAX_TAGNAMELENGTH 20
#define MAX_STRIPTAGS 20

typedef struct Stripper {
  int f_in_tag;
  int f_closing;
  int f_lastchar_slash;

  char tagname[MAX_TAGNAMELENGTH];
  char * p_tagname;
  char f_full_tagname;

  int f_outputted_space;
  int f_just_seen_tag;

  int f_in_quote;
  char quote;

  int f_in_decl;
  int f_in_comment;
  int f_lastchar_minus;

  int f_in_striptag;
  char striptag[MAX_TAGNAMELENGTH];
  char o_striptags[MAX_STRIPTAGS][MAX_TAGNAMELENGTH];
  int numstriptags;
  int o_emit_spaces;
  int o_decode_entities;

  int o_auto_reset;

  int o_debug;
} Stripper;

void _strip_html( Stripper * stripper, char * raw, char * clean, int is_utf8_p );
void _reset( Stripper * stripper );
void clear_striptags( Stripper * stripper );
void add_striptag( Stripper * stripper, char * tag );

void check_end( Stripper * stripper, char );
