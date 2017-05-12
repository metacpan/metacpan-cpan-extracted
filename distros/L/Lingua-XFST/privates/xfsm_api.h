/* $Id: xfsm_api.h $ */
/* Copyright (c) 2009 by the Palo Alto Research Center.
   All rights reserved */

/*********************************************************************
 **
 **                          XFSM_API.H
 **                       Lauri Karttunen
 **                   Palo Alto Research Center
 **                         July 2009
 **
 *********************************************************************/

/* This header file documents the data structures, constants and
   function prototypes that are made available in libxfst. libxfst
   is a C or C++ programmers interface to the operations that are
   provided on the xfst application's command line. It does not
   contain the features that are in fst, the more powerful "big 
   sister" of xfst, such as size and speed optimizations and
   pattern matching. libxfst is a subset of a larger libcfsm library.

   This is the only header file needed for the xfst library. The order
   of presentation of structure and function definitions is fixed by
   the needs of a C compiler that must have a definition for every
   constant and data type before it is used in another definition. A
   human reader might find it useful to skip the beginning and jump
   right into the section on FUNCTION PROTOTYPES. */

#ifndef XFSM_API
#define XFSM_API


#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#include <stdio.h>

#ifndef _WIN32
#include <stdint.h>
#else
#include "win_stdint.h"
#endif

#ifdef _WIN32
#include <limits.h>
#define UINTMAX_MAX UINT_MAX
#define INT32_MAX   _I32_MAX
#endif

  /*****************************************************
   *         DATA STRUCTURES and DEFINITIONS
   *****************************************************/

#ifndef BIT_DEFINED
#define BIT_DEFINED
  typedef uint32_t bit;
#endif
#ifndef BYTE_DEFINED
#define BYTE_DEFINED
  typedef unsigned char byte;
#endif

#ifndef TRUE
#define TRUE 1
#endif

#ifndef FALSE
#define FALSE 0
#endif

#ifndef EPSILON
#define EPSILON 0  /* The symbol ID of the epsilon symbol. */
#endif

#ifndef OTHER
#define OTHER 1    /* The symbol ID for an unknown symbol. */
#endif

  /********************
   * CONSTANTS
   *******************/

  enum symbol_pair {UPPER=0, LOWER=1, BOTH_SIDES=2};
  enum visit_marks {NOT_VISITED=0, IN_PROCESS=1, DONE=2};
  enum escape_p {DONT_ESCAPE=0, ESCAPE=1};
  enum obey_flags_p {DONT_OBEY=0, OBEY=1};
  enum keep_p {DONT_KEEP=0, KEEP=1};
  enum char_encoding {CHAR_ENC_UNKNOWN=0,  CHAR_ENC_UTF_8=1,
                      CHAR_ENC_ISO_8859_1=2};
  enum alph_types {BINARY_VECTOR=0, LABEL_VECTOR=1};
  enum watch_rm {DONT_WATCH_RM=0, WATCH_RM=1};
  enum record_byte_pos {DONT_RECORD, RECORD};
  enum flag_action {NO_ACTION=0, CLEAR_SETTING=1, POSITIVE_SETTING=2,
                    NEGATIVE_SETTING=3, UNIFY_TEST=4, DISALLOW_TEST=5,
                    REQUIRE_TEST=6, FAIL_ACTION=7, INSERT_SUBNET=8,
                    SET_TO_ATTR=9, EQUAL_ATTR_TEST=10, LIST_MEMBER=11,
                    APPLY_TRANSDUCER=12, APPLY_FUNCTION=13,
                    EXCLUDE_LIST=14};
  enum data_types {Unknown=0, Network=1, Alphabet=2, Integer=3, Other=4};
  enum bytes_or_chars {NUM_BYTES, NUM_CHARS};

  /**************
   * SIZES
   **************/

#define int16   short
#define uint16  unsigned short
#define int32   int
#define uint32  unsigned int

  typedef long           LONG;
  typedef unsigned long  ULONG;
  typedef unsigned int   UTF32;
  typedef uint32         id_type;

#define MAX_LV 24 /*  -- maximum number of bits in a label ID */

#define ID_EOS ((unsigned) (1 << MAX_LV) -1)
  /* Id symbol denoting the end of a symbol ID sequence. */

#define ID_NO_SYMBOL ((unsigned) (1 << MAX_LV) -1)
  /* Special Id symbol meaning "no symbol" or "uninitialized id
     value" */

  /************************
   * CFSM LIBRARY VERSION *
   ************************/

  char *libcfsm_version(void);
  /* Returns an unmodifiable string constant such as
     "libcfsm-2.12.10 (svn 24693) 2008-08-14"
     where 2.12.10 is the release number for the cfsm library,
     (svn 24693) identifies  the subversion repository update for
     the library and 2008-08-14 is its creation date. */

  char *libcfsm_build(void);
  /* Returns the latest subversion repository update number
     as an unmodifiable string, for example "24693". */

  /*************
   * HEAP
   *************/

  typedef struct HEAP HEAPtype, *HEAPptr;

  /*************
   * HASH TABLE
   *************/

  typedef struct HASH_TABLE HASH_TABLEtype, *HASH_TABLEptr;

  /****************
   * STACK
   ****************/

  typedef struct STACK STACKtype, *STACKptr;

  /****************
   * INPUT BUFFER
   ****************/

  typedef struct INPUT_BUFFER IN_BUFERtype, *IN_BUFFERptr;

  /******************
   * UNICODE STRINGS
   *****************/
  typedef UTF32 FAT_CHAR;
  typedef FAT_CHAR *FAT_STR;

  /* Unicode strings are represented as null-terminated sequences of
     32 bit integers, called "fat strings." Standard C strings are
     called "thin strings." This API allows the user to work with
     ordinary C strings either in UTF-8 or LATIN-1 mode. The
     conversion from thin strings to fat strings and, vice versa, is
     handled automatically. Nevertheless, a few functions are provided
     for the unlikely case that they are needed. */

  FAT_STR make_fat_string(int length);
  /* Makes a new fat string of the given length. */

  FAT_STR fat_strcpy(FAT_STR s1, FAT_STR s2);
  /* Analogue of strcpy. Copies s2 to s1 including the terminating 0.
     Returns s1. The caller must verify that s1 has enough space. */

  FAT_STR copy_fat_string(FAT_STR fs);
  /* Returns a copy of fs. */

  FAT_STR fat_strcat(FAT_STR s1, FAT_STR s2);
  /* Analogue of strcat. Appends s2 to the end of s1 including the
     terminating 0. Returns s1. The caller must verify that s1 has
     enough space for the result. */

  char *fat_to_thin_str(FAT_STR fat_str, char *thin_str, int with_esc);
  /* Converts a fat string to a thin string conforming to the current
     character encoding mode. If thin_str is NULL, a new string is
     allocated. If thin_str is non-NULL, it is up to the caller to
     verify that it is long enough for the result. */

  int fprint_fat_string (FILE *outfile, FAT_STR fs);
  /* Prints fs into outfile. See also the functions below for writing
     fat strings to a string buffer or a page. */

  /******************
   * STRING BUFFER
   ******************/

  typedef struct STRING_BUFFER {
    int char_size;
    int length;
    int pos;
    int lines;
    void *string;
  } STRING_BUFFERtype, *STRING_BUFFERptr;

  /* String buffers are used to store both types of strings, fat
     strings or thin strings. The char_size is either 4 or 1 bytes.
     Some of the apply functions store the output into a string
     buffer. */

#define STRING_BUFFER_char_size(X)  (X)->char_size
#define STRING_BUFFER_length(X)     (X)->length
#define STRING_BUFFER_pos(X)        (X)->pos
#define STRING_BUFFER_lines(X)      (X)->lines
#define STRING_BUFFER_string(X)     (X)->string

  STRING_BUFFERptr make_string_buffer(int length);
  /* Makes a new thin string buffer */

  STRING_BUFFERptr make_fat_str_buffer(int length);
  /* Makes a new fat string buffer. */

  void free_string_buffer(STRING_BUFFERptr str_buf);
  /* Frees a string buffer of either type. */

  void initialize_string_buffer(STRING_BUFFERptr str_buf);
  /* Initializes a string buffer of either type. */

  int append_string_to_buffer(const char *str, STRING_BUFFERptr str_buf);
  /* Appends a thin string to a thin string buffer. Returns
     the length of the string in the buffer. */

  int append_label_to_buffer(id_type id, int escape_p, STRING_BUFFERptr str_buf);
  /* Appends the label of the id to a thin string buffer. Returns the
     length of the string in the buffer. If escape_p is ESCAPE,
     special symbols such as newline symbols and tabs are escaped using
     standard Unix conventions. */

  int append_fat_str_to_buffer(FAT_STR fs, STRING_BUFFERptr str_buf);
  /* Appends a fat string to a fat string buffer. Returns the
     length of the fat string in the buffer. */

  void assure_buffer_space(int length, STRING_BUFFERptr str_buf);
  /* Makes sure that the string buffer has length amount of space
     left. */

  int print_string_buffer(STRING_BUFFERptr str_buf, FILE *stream);
  /* Prints the string of the string buffer into the stream.  If the
     string is a fat string, it will be printed as a a UTF-8 or
     Latin-1 encoded C string depending on the character encoding
     mode. Returns the length of the printed string. */

  /******************
   * LAB_VECTOR
   *****************/

  typedef struct LAB_VECTOR {
    int length;
    int pos;
    id_type *array;
  } LAB_VECTORtype, *LAB_VECTORptr;

#define LAB_VECTOR_length(X)     (X)->length
#define LAB_VECTOR_pos(X)        (X)->pos
#define LAB_VECTOR_array(X)      (X)->array

  /* Label vectors are used to store sequences of label IDs */

  LAB_VECTORptr make_lab_vector(int length);
  /* Creates a label vector of the given length. */

  void reclaim_lab_vector(LAB_VECTORptr lab_vect);

  int append_to_lab_vector(id_type lab, LAB_VECTORptr lab_vect);
  /* Appends a label to the next position in the label vector and
     increments the position counter. The length of the vector is
     adjusted if needed. Returns the new value of the position counter. */

  int set_lab_vector_element_at(id_type lab, int pos, LAB_VECTORptr lab_vect);
  /* Stores the label in the given position in the label vector. The
     length of the label vector is adjusted if needed. Returns the
     value of the position counter. */

  int lab_vector_element_at(id_type *lab, int pos, LAB_VECTORptr lab_vect);
  /* Sets *lab to the label in the given position. Returns 0 on success,
     1 if the position is outside the filled part of the vector. */

  void increment_lab_vector(LAB_VECTORptr lab_vect);
  /* Increments the position counter of the label vector. */

  int decrement_lab_vector(LAB_VECTORptr lab_vect);
  /* Decrements the position counter of the label vector.
     Return 0 on success, 1 if the new position would be less than 0. */

  void reset_lab_vector(LAB_VECTORptr lab_vect);
  /* Resets the position counter of lab_vect to 0. */

  typedef struct LAB_VECTOR_TABLE LAB_VECTOR_TABLEtype, *LAB_VECTOR_TABLEptr;

  /******************
   *  VECTOR *
   ******************/
  typedef struct VECTOR {
    int length;
    int pos;
    void **array;
  } VECTORtype, *VECTORptr;

  /* Vectors are for storing sequences of objects of any kind. */

#define VECTOR_length(X)        (X)->length
#define VECTOR_pos(X)           (X)->pos
#define VECTOR_array(X)         (X)->array

  typedef struct VECTOR_ENUMERATOR VECT_ENUMtype, *VECT_ENUMptr;

  typedef struct VECTOR_TABLE VECTOR_TABLEtype, *VECTOR_TABLEptr;

  VECTORptr make_vector(int length);
  /* Makes a vector of the given length. */

  void free_vector(VECTORptr vector);

  int append_to_vector(void *object, VECTORptr vector);
  /* Appends object to the next position in the vector and increments
     the position counter. Allocates more vector space if needed.
     Returns the new value of the position counter. */

  int vector_element_at(void **element, int pos, VECTORptr *vector);
  /* Sets *element to the object in the given position. Returns 0
     on success, 1 if pos is greater or equal to the value of the
     vector's position counter. */

  int set_vector_element_at(void *element, int pos, VECTORptr vector);
  /* Stores the element in the given position in the vector. The
     length of the vector is adjusted if needed. Returns the value of
     the position counter. */

  void reset_vector(VECTORptr vector);
  /* Sets the position counter of vector to 0. */

  typedef struct LAB_RING LAB_RINGtype, *LAB_RINGptr;

  /*************************
   *  LABEL
   ***************************/

  typedef struct TUPLE {
    id_type *labels; /* a pair of label IDs */
    id_type inverse; /* it is equal to ID_NO_SYMBOL for labels
                        of arity 1 and for tuples whose inverse
                        has not been computed; otherwise it contains
                        the unique ID of the inverse tuple. */
  } TUPLEtype, *TUPLEptr;

#define TUPLE_labels(X)       (X)->labels

  typedef struct FLAG_DIACRITIC {
    int action;
    id_type attribute;
    id_type value;
  } FLAG_DIACRtype, *FLAG_DIACRptr;

#define FLAG_DIACR_action(X)       (X)->action
#define FLAG_DIACR_attribute(X)    (X)->attribute
#define FLAG_DIACR_value(X)        (X)->value

  typedef struct LABEL {
    id_type id;          /* Unique ID for a symbol or symbol pair. */
    id_type other_id;    /* Place to store some related label ID. */
    void *data;          /* a cache for storing some information about
                            the label such as type or print name */
    FLAG_DIACRptr flag;  /* NULL for labels that are not flag diacritics. */
    unsigned short arity;         /* 1 for atomic label, 2 for pairs */
    unsigned short expands_other;   /* TRUE if covered by OTHER */
    unsigned short consumes_input;   /* Not an epsilon transition */
    unsigned short convertible;     /* TRUE if case conversion makes sense. */
    unsigned short closing_xml_tag;  /* Is of the form </....> */
    unsigned short data_type;       /* The type of data stored in the data field:
                            0 = CFSMUnknown, 1 = Network, 2 = Alphabet,
                            3 = Integer, 4 = Other */
    union {
      FAT_STR name;      /* Name of an atomic label. */
      TUPLEptr tuple;    /* The tuple of an fstpair. */
    } content;
  } LABELtype, *LABELptr;

  /* There are two types of labels. Atomic labels have arity 1 and tuple labels
     have arity 2. The content field of an atomic label is its name represented
     as a fat string. The content field of a tuple label consists of a pair of
     label IDs for its stomic components. */

#define LABEL_id(X)            (X)->id
#define LABEL_other_id(X)      (X)->other_id
#define LABEL_arity(X)         (X)->arity
#define LABEL_data(X)          (X)->data
#define LABEL_flag(X)          (X)->flag
#define LABEL_name(X)          (X)->content.name
#define LABEL_tuple(X)         (X)->content.tuple
#define LABEL_convertible(X)   (X)->convertible
#define LABEL_expands_other(X) (X)->expands_other
#define LABEL_consumes_input(X)(X)->consumes_input
#define LABEL_closing_xml_tag(X)(X)->closing_xml_tag
#define LABEL_data_type(X)     (X)->data_type

  int print_label(id_type id, FILE *stream, int escape_p);
  /* Prints label correspondig to the ID to a stream. If escape_p is DONT_ESCAPE,
     the label is printed literally. If escape_p is ESCAPE, special symbols such
     as newline symbols and tabs are printed in double quotes. In UTF8 mode
     (default), non-ASCII symbols are printed as UTF8 strings, in Latin-1 mode
     symbols outside the Latin-1 region are printed in the format "\uXXXX" where
     XXXX is the hex value of the Unicode code point. */

#define fstpair_upper(X)        TUPLE_labels(LABEL_tuple(X))[UPPER]
#define fstpair_lower(X)        TUPLE_labels(LABEL_tuple(X))[LOWER]

  /*************************
   *  LABEL ID MAP
   ***************************/

  typedef struct LABEL_ID_MAP LABEL_ID_MAPtype, *LABEL_ID_MAPptr;
  /* A data structure structure for associating label names (fat
     strings) and the corresponding integer IDs. It contains a hash
     table that maps label names to their IDs and an array of
     labels. The label for an ID, for example 321, is located at the
     position 321 in the label array. The maximum number of label IDs
     used to be 65535, it is now 16777214 (2^24 -2).  When the default
     label map is initialized, all the printable ASCII characters get
     a label and an ID that is the same as the integer value of the
     character. For example, the symbol 'A' has the ID 65. Labels for
     other symbols and symbol pairs are created on demand.  Special
     symbols that have fixed label IDs include EPSILON (ID 0) and
     OTHER (ID 1), the unknown symbol. Because symbol names are
     recorded as fat strings, they do not depend on the character
     encoding mode (utf-8 or iso-8859-1). */


  id_type single_to_id(const char *name);
  /* Converts the name string into a fat string and returns the
     corresponding symbol ID for the atomic label. Creates a new label
     and a new label ID, if the label does not already exist. Returns
     the label ID. In UTF-8 mode, it is assumed that the name is a
     UTF8-coded string. Generates a warning message if the string is
     not a valid UTF8-string. In Latin-1 mode the name is processed as
     a Latin-1 string. Any Unicode character may be represented in the
     format "\uXXXX" where X is a hex character. For example,
     single_to_id("\u20AC") returns an ID for the Euro symbol. */

  id_type pair_to_id(const char *upper, const char *lower);
  /* Returns the ID of the tuple label with upper and lower as the two
     components.  The names are processed as either UTF8 strings or
     Latin-1 strings depending on the mode. If the names are equal
     strings, the result is a single label because A:A is treated as
     equivalent to A. */

  id_type id_pair_to_id(id_type upper_id, id_type lower_id);
  /* Returns the ID of the tuple label upper_id and lower_id as the
     two components.  The names are processed as either UTF8 strings or
     Latin-1 strings depending on the mode. If upper_id and lower id are
     identical, the result is identical to them as well. */

  LABELptr id_to_label(id_type id);
  /* Returns the label corresponding to the id. */

  id_type upper_id(id_type id);
  /* Returns the upper id of a tuple label or the id itself if id
     refers to an atomic label. */

  id_type lower_id(id_type id);
  /* Returns the lower id of a tuple label or the id itself if id
     is an atomic label. */

  /*******************
   * RANGE
   *******************/

  typedef struct RANGE_RECORD RANGEtype, *RANGEptr;

  /*******************
   * MATCH_TABLE
   *******************/

  typedef struct MATCH_TABLE MATCH_TABLEtype, *MATCH_TABLEptr;

  /**********************
   *  ALPHABET
   *********************/

  typedef struct ALPHABET {
    int len;               /* # of ALPH_items positions in use */
    int max;             /* actual size of ALPH_items */
    id_type *items;      /* Label IDs (LABEL VECTOR), 0s and 1s (BINARY_VECTOR)*/
    bit type:8;          /* 0 = BINARY_VECTOR, 1 = LABEL_VECTOR */
    bit in_use:8;        /* 0 = not in use, 1 = in use */
  } ALPHABETtype, *ALPHABETptr;

  /* An alphabet is a list of label IDs. The list can be represented
     in two ways, as a binary vector or as list of label IDs. A binary
     vector is a list of zeros and ones where ones indicate that the
     ID corresponding to the position in the vector is a member of the
     alphabet. For example, if the position 65 in the vector contains 1,
     then symbol with the ID 65 (the letter 'A') is a member of the
     alphabet. The sigma alphabet of a network is kept in binary
     format for quick membership checking. The label alphabet of a
     network is maintained as a label vector. */

#define ALPH_type(X)       (X)->type
#define ALPH_items(X)      (X)->items
#define ALPH_item(X,Y)     (X)->items[(Y)]
#define ALPH_len(X)        (X)->len
#define ALPH_max(X)        (X)->max
#define ALPH_in_use(X)     (X)->in_use

  ALPHABETptr make_alph(int len, int type);
  /* Returns an alphabet of the specified length and type (either LABEL_VECTOR
     or BINARY_VECTOR). */
  ALPHABETptr copy_alphabet(ALPHABETptr alph);
  /* Returns a copy of the alphabet. */

  void free_alph(ALPHABETptr alph);
  /* Reclaims the alphabet. */

  void print_alph(ALPHABETptr alph, FILE *stream);
  /* Prints the alphabet into the stream. */

  /**********************
   *  ALPHABET ITERATOR
   *********************/

  typedef struct ALPH_ITERATOR {
    int pos;
    int len;
    int type;
    id_type *items;
  } ALPH_ITtype, *ALPH_ITptr;

  /* An alphabet iterator returns the members of an alphabet one after
     an another. The alphabet may be in BINARY or LABEL format. */

#define ALPH_IT_pos(X)        (X)->pos
#define ALPH_IT_type(X)       (X)->type
#define ALPH_IT_items(X)      (X)->items
#define ALPH_IT_len(X)        (X)->len

  ALPH_ITptr start_alph_iterator(ALPH_ITptr alph_it, ALPHABETptr alph);
  /* Returns an initialized alphabet iterator for the given alphabet.
     If the first argument is NULL, a new alphabet iterator is created. */

  id_type next_alph_id(ALPH_ITptr alph_it);
  /* Returns the next member of the alphabet. If there are no more unseen
     IDs in the iterator, the return value is ID_NO_SYMBOL (16777215). */

  void reset_alph_iterator(ALPH_ITptr alph_it);
  /* Resets the alphabet iterator to the first symbol ID. */

  void free_alph_iterator(ALPH_ITptr alph_it);
  /* Frees the alphabet iterator only, not the alphabet that it iterates on.
     You need not call this function if the iterator has been statically
     allocated. */

  /***********************
   *  ARC_VECTOR
   ***********************/
  typedef struct ARC_VECTOR AVtype, *AVptr;

  /*********************
   *  CH_NODE
   *********************/

  typedef struct CH_NODE CH_NODEtype, *CH_NODEptr;

  /*********************
   *  PARSE_TABLE  object  *
   *********************/

  typedef struct PARSE_TABLE PARSE_TBLtype, *PARSE_TBL;

  /*******************
   *  PROPERTY LIST  *
   *******************/

  /* The property list of a network is a list of attribute-value pairs.
     The attributes are represented as fat strings, the values may
     be diffent types of objects including strings, integers and lists.
     The property list is used to store the regular expression that
     was used to define the network. It also stores the defined list
     symbols that the network refers to. For example, the following
     sequence of commands
     define_regex_list("Vowel", "a e i o u");
     define_regex_list("VoicelessStop", "k p t");
     define_regex_net("Test","\"@L.VoicelessStop@\" \"@L.Vowel@\"");
     save(net("Test"), "test.net")
     causes the test net to be saved with the following property list:
     DEFINITION: "%"@L.VoicelessStop@%" %"@L.Vowel@%""
     DEFINED_LISTS: ( ( "VoicelessStop" "k" "p" "t" )
     ( "Vowel" "a" "e" "i" "o" "u" ) )
     when the saved net is loaded from a file, the list definitions are
     restored from the property list. */

  typedef struct IO_SYMBOL IO_SYMBOLtype, *IO_SYMBOLptr;

  typedef struct IO_SYMBOL_PACKAGE IO_SYMBOL_PACKAGEtype, *IO_SYMBOL_PACKAGEptr;

  typedef struct BYTE_BLOCK BYTE_BLOCKtype, *BYTE_BLOCKptr;

  typedef struct SEQUENCE SEQUENCEtype, *SEQUENCEptr;

  typedef struct OBJECT  OBJECTtype, *OBJECTptr;

  typedef struct PROP {
    FAT_STR attribute;
    OBJECTptr value;
    struct PROP *next;
  } PROPtype, *PROPptr;

#define PROP_attr(X)    (X)->attribute
#define PROP_val(X)     (X)->value
#define next_prop(X)    (X)->next

  /*****************
   *  ARC
   *****************/

  typedef struct ARC {
    struct STATE *destination;     /* Destination state */
    bit type_bit : 1;
    bit userflag1 : 1;
    bit visit_mark : 2;
    bit big_arc_flag : 1;
    bit userflag2 : 2;
    bit in_use: 1;
    id_type label : MAX_LV;        /* Label ID */
    struct ARC *next;              /* Pointer to the next arc */
  } ARCtype, *ARCptr;

  /* An arc consists of a pointer to a destination state, a label ID,
     a pointer to the next arc and various bit flags. Arcs are
     allocated from a global arc heap. When an arc is freed, it
     is put on the freelist of the heap. The in_use bit is 1 when
     the arc is in use, 0 when it has been freed. */


#define ARC_type_bit(X)                 (X)->type_bit
#define ARC_userflag1(X)                (X)->userflag1
#define ARC_visit_mark(X)               (X)->visit_mark
#define ARC_big_arc_flag(X)             (X)->big_arc_flag
#define ARC_userflag2(X)                (X)->userflag2
#define ARC_in_use(X)                   (X)->in_use
#define ARC_label(X)                    (X)->label
#define ARC_destination(X)              (X)->destination
#define ARC_next(X)                     (X)->next

  typedef struct BIG_ARC {
    struct STATE *destination;
    bit type_bit : 1;
    bit userflag1 : 1;
    bit visit_mark : 2;
    bit big_arc_flag : 1;
    bit userflag2: 2;
    bit in_use: 1;
    id_type label: MAX_LV;
    struct BIG_ARC *next;
    void *user_pointer;
  } BIG_ARCtype, *BIG_ARCptr;

  /*  A "big arc" is an arc with an extra user_pointer field. If the
      big_arc_flag is 1 instead of 0, the arc has that extra field. A
      common use for big arcs is to record for each symbol in a
      network its starting byte position in a text file. */

#define ARC_user_pointer(X)             (X)->user_pointer

  void free_arc(ARCptr arc);
  /* Returns the arc to the global arc or big-arc heap. */

  /******************
   *  STATE
   ******************/
  typedef struct STATE {
    union {
      struct ARC *set;              /* First arc of the state */
      struct ARC_VECTOR *vector;    /* Vector of destination states */
    } arc;
    bit type_bit : 1;
    bit final : 1;
    bit deterministic : 1;
    bit vector_p : 1;               /* 0 = normal state, 1 = vectorized state */
    bit visit_mark : 8;
    bit userflag2 : 2;
    bit is_virtual: 1;
    bit in_use : 1;
    struct STATE *next;             /* Pointer to the next state */
    void *client_cell;
  } STATEtype, *STATEptr;

  /* A state contains a set of arcs leading other other states, a
     pointer to the next state, a set of bit flags, a client_cell
     pointer that is used by various algorithms to store temporary
     information. The arc set of a state may be in one of two
     formats. The standard format that most cfsm algorithms expect is
     a list of arcs. In this case, state->arc points to the first arc
     of the state and each arc points to its successor, or to NULL in
     the case of the last arc. Alternatively, the arc set is represented
     by a structure that contains a vector of destination states. The
     vector format takes up more space than the standard format but
     it is faster to process because it provides random access to
     destination states by label IDs. States are allocated from a
     global state heap. The in_use flag is 1 when a state is in use
     and 0 when a state is returned to the heap. */

  void free_state(STATEptr state);
  /* Returns the state to the global state heap. */

#define STATE_type_bit(X)        (X)->type_bit
#define STATE_visit_mark(X)      (X)->visit_mark
#define STATE_final(X)           (X)->final
#define STATE_deterministic(X)   (X)->deterministic
#define STATE_vector_p(X)        (X)->vector_p
#define STATE_arc_set(X)         (X)->arc.set
#define STATE_arc_vector(X)      (X)->arc.vector
#define STATE_userflag2(X)       (X)->userflag2
#define STATE_is_virtual(X)      (X)->is_virtual
#define STATE_in_use(X)          (X)->in_use

  /*********************
   *  NETWORK
   *********************/

  typedef struct NETWORK {
    ALPHABETptr labels;             /* Label alphabet as LABEL_VECTOR */
    ALPHABETptr sigma;              /* Sigma alphabet as BINARY_VECTOR */
    struct {
      bit deterministic:1;
      bit pruned:1;
      bit completed:1;
      bit minimized:1;
      bit epsilon_free:1;
      bit sorted_states:1;
      bit loop_free:1;
      bit twol_net:1;
      bit visit_marks_dirty:1;
      bit names_matter:1;
      bit shared_arc_lists:1;
      bit has_arc_user_pointer:1;
      bit closed_sigma:1;
      bit start_state_final:1;
      bit lower_bound_checked:1;
      bit compacted:1;
      bit obsolete2:1;
      bit obsolete3:1;
      bit mark:1;
      bit u_flag_diacr:1;
      bit l_flag_diacr:1;
      bit obsolete4:1;
      bit obsolete5:1;
      bit sorted_arcs:1;
      bit reduced_labelset:1;
      bit obsolete6:1;
      bit is_virtual:1;
      bit is_arc_optimized:1;
      bit in_use:1;
      bit has_arc_vectors:1;
      bit linear_bounded_upper:1;
      bit linear_bounded_lower:1;
      bit upper_bound_checked:1;
    } flags;
    int16 arc_label_arity;
    id_type defined_as;
    id_type range_len;
    LABEL_ID_MAPptr label_map;
    RANGEptr uprange_map;
    RANGEptr downrange_map;
    MATCH_TABLEptr upmatch_table;
    MATCH_TABLEptr downmatch_table;
    ALPHABETptr recode_key;
    ALPHABETptr decode_key;
    ALPHABETptr unreduce_key;
    union {
      STATEptr state;
      unsigned char *loc;
    } start;
    union {
      STATEptr states;                 /* First state of a standard network */
      void *block;                     /* Arc block of a compacted network */
    } body;
    HEAPptr arc_vector_heap;
    int arc_vector_len;
    PROPptr networkprops;              /* First network property */
    PARSE_TBL upper_parse_table;
    PARSE_TBL lower_parse_table;
    uintptr_t num_states;                  /* Number of states */
    uintptr_t num_arcs;                    /* Number of arcs */
    uintptr_t block_size;
    ALPHABETptr flag_register;
    void *client_cell;
    void *mmap_handle;
    size_t mmap_size;
  } NETtype, *NETptr;

  /* A network is a large data structure. Many of the fields such as
     parse and match tables are used to cache data that is used by the
     apply routines. The body of a standard network is a pointer to
     the first state of a state list. Each state points to its
     successor on the list. The body of a compacted network is a
     pointer to the block of memory encoding the arcs and states in a
     space-efficient way. Most cfsm algorithms work only on standard
     networks. A network can be optimized in several ways either to
     save space or to increase the application speed. If the has_arc_vectors
     flag is 1, some of the states of the network are in the vectorized
     format. Other optimization flags are arc_optimized, reduced_labelset,
     and shared_arc_lists. A network has a unique start_state. The start
     state does not have to be the first state of the list pointed to
     by body.arcs. Networks are allocated from a global heap. The in_use
     flag indicates whether a network is in use or whether it has been
     freed. The num_arcs field contains the number of arcs; The num_states
     field keeps track of the number of states in the network. */

#define NET_deterministic(X)             (X)->flags.deterministic
#define NET_pruned(X)                    (X)->flags.pruned
#define NET_completed(X)                 (X)->flags.completed
#define NET_minimized(X)                 (X)->flags.minimized
#define NET_epsilon_free(X)              (X)->flags.epsilon_free
#define NET_sorted_states(X)             (X)->flags.sorted_states
#define NET_loop_free(X)                 (X)->flags.loop_free
#define NET_visit_marks_dirty(X)         (X)->flags.visit_marks_dirty
#define NET_names_matter(X)              (X)->flags.names_matter
#define NET_shared_arc_lists(X)          (X)->flags.shared_arc_lists
#define NET_has_arc_user_pointer(X)      (X)->flags.has_arc_user_pointer
#define NET_closed_sigma(X)              (X)->flags.closed_sigma
#define NET_start_state_final(X)         (X)->flags.start_state_final
#define NET_twol_net(X)                  (X)->flags.twol_net
#define NET_compacted(X)                 (X)->flags.compacted
#define NET_mark(X)                      (X)->flags.mark
#define NET_u_flag_diacr(X)              (X)->flags.u_flag_diacr
#define NET_l_flag_diacr(X)              (X)->flags.l_flag_diacr
#define NET_sorted_arcs(X)               (X)->flags.sorted_arcs
#define NET_reduced_labelset(X)          (X)->flags.reduced_labelset
#define NET_Kaplan_compressed(X)         (X)->flags.Kaplan_compressed
#define NET_is_virtual(X)                (X)->flags.is_virtual
#define NET_optimized(X)                 (X)->flags.is_arc_optimized
#define NET_in_use(X)                    (X)->flags.in_use
#define NET_has_arc_vectors(X)           (X)->flags.has_arc_vectors
#define NET_linear_bounded_upper(X)      (X)->flags.linear_bounded_upper
#define NET_linear_bounded_lower(X)      (X)->flags.linear_bounded_lower
#define NET_lower_bound_checked(X)       (X)->flags.lower_bound_checked
#define NET_upper_bound_checked(X)       (X)->flags.upper_bound_checked
#define NET_arc_label_arity(X)           (X)->arc_label_arity
#define NET_num_arcs(X)                  (X)->num_arcs
#define NET_num_states(X)                (X)->num_states
#define NET_labels(X)                    (X)->labels
#define NET_sigma(X)                     (X)->sigma
#define NET_recode_key(X)                (X)->recode_key
#define NET_decode_key(X)                (X)->decode_key
#define NET_unreduce_key(X)              (X)->unreduce_key
#define NET_start_state(X)               (X)->start.state
#define NET_start_loc(X)                 (X)->start.loc
#define NET_states(X)                    (X)->body.states
#define NET_arc_block(X)                 (X)->body.block
#define NET_arc_vector_heap(X)           (X)->arc_vector_heap
#define NET_arc_vector_len(X)            (X)->arc_vector_len
#define NET_range_len(X)                 (X)->range_len
#define NET_label_map(X)                 (X)->label_map
#define NET_properties(X)                (X)->networkprops
#define NET_upper_parse_table(X)         (X)->upper_parse_table
#define NET_lower_parse_table(X)         (X)->lower_parse_table
#define NET_uprange_map(X)               (X)->uprange_map
#define NET_downrange_map(X)             (X)->downrange_map
#define NET_upmatch_table(X)             (X)->upmatch_table
#define NET_downmatch_table(X)           (X)->downmatch_table
#define NET_mmap(X)                      (X)->mmap_handle
#define NET_mmap_size(X)                 (X)->mmap_size

  NETptr make_empty_net(void);
  /* Returns a skeleton network structure with an empty sigma and
     label_alphabets but without an initial state. Use either
     null_net() or epsilon_net() to create a minimal network
     with an initial state. */

  NETptr copy_net(NETptr net);
  /* Returns a copy of the network. */

  int minimize_net(NETptr net);
  /* Destructively minimizes the network using Hopcroft's algorithm.
     Returns 0 on success and 1 on error. As a prelimnary step
     to minimization, the network is first pruned, epsilons are
     removed and the network is determinized. Minimization can
     only be done on standard networks, not on networks that have
     been compacted or vectorized. */

  void free_network(NETptr net);
  /* Returns the network to the global network heap. */

  void print_net(NETptr net, FILE *stream);
  /* Prints the states and arcs of the network into the stream. */

  STATEptr add_state_to_net(NETptr net, int final_p);
  /* Adds a new state to the network. If final_p is non-zero, the
     state is final. Returns the new state on success, NULL on failure. */

  ARCptr add_arc_to_state(NETptr net, STATEptr start, id_type id, STATEptr dest,
                          void *user_pointer, int big_arc_p);
  /* Creates a new arc from start to dest with the label id unless it
     would duplicate an existing arc. Does not add a looping EPSILON
     arc.  The start and dest states must already exist in the
     network. The network must be a standard network, not vectorized
     or optimized. Updates the sigma and label alphabets of the
     network. If big_arc_p is non-zero, the new arc will have a
     user_pointer field. Returns the arc on success, NULL on failure. */

  int read_net_properties(NETptr net, char *file);
  /* Reads a list of attribute value pairs from the file and adds them
     to the networks property list. For example,
     NETWORKNAME: "Number-to-numeral converter"
     LARGEST_NUMBER: 99999
     If file is NULL, the input is obtained from stdin. */

  int write_net_properties(NETptr net, char *file);
  /* Writes the networks property list into a file or to stdout if
     file is NULL. */

  int add_string_property(NETptr net, char *attribute, char *value);
  /* Adds the attribute:value pair to the network's property list.
     Any previous value for the attribute is freed and replaced by
     the new value. Returns 0 on success, 1 on error.  Both the
     attribute and the value are copied and converted to fat
     strings, they can be freed by the calling function if they
     have been malloc'd. */

  char *get_string_property(NETptr net, char *attribute);
  /* Returns the value of the attribute on the property list of the
     net, or NULL if it is not found. The value is a freshly allocated
     C string. It should be freed by the calling function when it
     is not needed anymore. */

  int remove_string_property(NETptr net, char *attribute);
  /* Removes the attribute and its value from the property list of the
     network. Returns 0 on success, 1 or error. */

  /*****************
   *  NET VECTOR   *
   *****************/

  typedef struct NET_VECTOR {
    int len;
    NETptr *nets;
  } NVtype, *NVptr;

  /* A data structure for storing one or more networks. The positions
     in a net vector are counted starting from 0. Thus NV_net(nv, 0)
     refers to the first network in the net vector nv. */

#define NV_len(X)   (X)->len
#define NV_nets(X)  (X)->nets
#define NV_net(X,Y) (X)->nets[(Y)]

  NVptr make_nv(int len);
  /* Retuns a net vector of the specified length. */

  NVptr net2nv(NETptr net);
  /* Wraps the net inside a net vector of length 1 and returns the vector. */

  NETptr nv_get(NVptr nv, int pos);
  /* Returns the net in the given position in the net vector nv.
     Safer than the NV_net(nv,pos) macro because it makes sure that
     0 >= pos < NV_len(nv). Returns NULL on error. */

  void nv_push(NETptr net, NVptr nv);
  /* Pushes the net into the beginning of the net vector increasing its
     length by 1. */

  void nv_add(NETptr net, NVptr nv);
  /* Appends the net into the end of the net vector increasing its length
     by 1. */

  void free_nv_only(NVptr nv);
  /* Frees the net vector but not any of the nets it contains. */

  void free_nv_and_nets(NVptr nv);
  /* Frees both networks contained in the vector and the net vector itself. */

  typedef struct LOCATION_IN_NET LOCATIONtype, *LOCATIONptr;

  typedef struct LODATION_PATH LOCATION_PATHtype, *LOCATION_PATHptr;

  typedef struct IO_SEQUENCE IO_SEQtype, *IO_SEQptr;

  typedef struct IO_SEQUENCE_TABLE IO_SEQ_TABLEtype, *IO_SEQ_TABLEptr;

  /**************************
   *  STANDARD FILE HEADER  *
   **************************/

  /* Binary files created with save_net() start with a file header that
     records the creation date and other information in encrypted form.
     Some information is recorded as clear text: file date and a copyright
     string. */

  typedef struct STANDARD_HEADER STANDARD_HEADER, *STANDARD_HEADERptr;

  /*****************
   * FST_CONTEXT
   *****************/

  typedef struct INTERFACE_PARAMETERS
  {
    struct regex
    {
      int lex_errors;
      int lex_max_errors;
    } regex;
    struct command_line
    {
      int quiet;
      int obey_ctrl_c;
      int stop;
      int want_deps;
    } command_line;
    struct alphabet
    {
      int print_pairs;
      int print_left;
      int read_left;
      int unicode;
      int recode_cp1252;
    } alphabet;
    struct general
    {
      int sort_arcs;
      int verbose;
      int completion;
      int stack;
      int name_nets;
      int minimal;
      int quit_on_fail;
      int assert;
      int show_escape;
      int sq_final_arcs;
      int sq_intern_arcs;
      int recursive_define;
      int recursive_apply;
      int compose_flag_as_special;
      int need_separators;
      int max_context_length;
      int vectorize_n;
      int fail_safe_composition;
    } general;
    struct optimization
    {
      int in_order;
    } optimization;
    struct io_fudged
    {
      int print_sigma;
      int print_space;
      int obey_flags;
      int mark_version;
      int retokenize;
      int show_flags;
      int max_state_visits;
      int max_recursion;
      int count_patterns;
      int delete_patterns;
      int extract_patterns;
      int locate_patterns;
      int mark_patterns;
      int license_type;
      int char_encoding;
      int use_memory_map;
      int use_timer;
    } io;
    struct parameters
    {
      int interactive;
    } parameters;
    struct sequentialization
    {
      int final_strings_arcs ;
      int intern_strings_arcs ;
      int string_one;
    } seq ;
  } IntParType, *IntParPtr;

  /* Interface parameters control many aspects of the cfsm application.
     For example, setting general.verbose to 0 suppresses the printing
     of all messages except for those do to an error. Interface parameters
     are part of a the larger C_FSM_CONTEXT data structure. */

  typedef struct ERROR_STREAM {
#ifdef Linux /* Darwin and Solaris don't support open_memstream() */
    size_t buffer_size;
    char *buffer;
    FILE *memstream;
#else
    size_t dummy; /* To keep size of struct same in both systems */
    FILE *tempfile;
    char *buffer;
#endif
  } ERROR_STREAM, *ERROR_STREAMptr;

  /* The error stream is used to print messages when a runtime error occurs. */

  /*****************
   *  PAGE
   *****************/

  typedef struct PAGE_OBJECT {
    int line_pos;
    int cur_pos;
    int line_no;
    int indent;
    int rm;
    int size;
    char *string;
    char *eol_string;
    char indent_char;
  } PAGEtype, *PAGEptr;

  /* Page objects are for storing formatted output. They are conceived
     as a sequence of lines with indentation and a right margin. The
     page writing routines keep track of the line position and insert
     an eol_string before the right margin is exceeded. The default
     eol_string is the default eol_string of the CFSM_CONTEXT, "\n".
     The size of the page grows as needed. */

#define PAGE_line_pos(X)            (X)->line_pos
#define PAGE_cur_pos(X)             (X)->cur_pos
#define PAGE_line_no(X)             (X)->line_no
#define PAGE_indent(X)              (X)->indent
  /* PAGE_rm is the width of the page in columns. If PAGE_rm is -1, the page
     has no right margin. */
#define PAGE_rm(X)                  (X)->rm
#define PAGE_size(X)                (X)->size
#define PAGE_string(X)              (X)->string
#define PAGE_eol_string(X)          (X)->eol_string
#define PAGE_indent_char(X)         (X)->indent_char

  int watch_margin(PAGEptr page, int next_size);
  /* Inserts an eol string, if adding next_size to the line position
     exceeds the right margin of the page. */

  int int_print_length(long i);
  /* Returns the number of digits in the print representation of an integer. */

  int label_length(LABELptr label, int escape_p, int bytes_or_chars);
  /* Returns the number of bytes or the number of characters in the print
     representation of the label. If bytes_or_chars is NUM_BYTES, the
     function returns the number of bytes. If the character encoding
     is UTF-8, NUM_BYTES may be larger than NUM_CHARS, the number of
     actual unicode characters of the label. If escape_p is ESCAPE,
     certain symbols such as newline characters are measured with
     surrounding double quotes. */

  PAGEptr new_page(void);
  /* Returns a new page with IY_INDENT indentation and IY_RIGHT_MARGIN
     as the right margin. The values of these macros are determined by
     the CFSM_CONTEXT. See below. */

  PAGEptr make_page(int size, int indent, int rm);
  /* Returns a new page with specified settings. */

  void free_page(PAGEptr page);
  /* Reclaims the page. */

  void reset_page(PAGEptr page);
  /* Resets the position and line coounters to zero. */

  void print_page(PAGEptr page, FILE * stream);
  /* Prints the page into the stream. */

  void new_page_line(PAGEptr page);
  /* Inserts the eol_string at the current position on the page. */

  void char_to_page(char c, PAGEptr page);
  /* Appends the character to the page. */

  void int_to_page(uintptr_t i, int watch_rm, PAGEptr page);
  /* Writes the integer to the page. If the second argument is WATCH_RM,
     an eol_string is inserted first if needed to avoid exceeding the
     right margin. If the second argument is DONT_WATCH_RM, the
     digits are written without watching the margin. */

  void float_to_page(float f, int watch_rm, PAGEptr page);
  /* Writes a floating point number to the page. */

  void spaces_to_page(int n, int watch_rm, PAGEptr page);
  /* Writes n spaces to the page. */

  void string_to_page(char *str, int watch_rm, PAGEptr page);
  /* Writes a C string to the page. */

  void fat_string_to_page(FAT_STR fs, PAGEptr page);
  /* Writes a fat string to the page. */

  void fat_string_to_page_esc(FAT_STR fs, const char *esc, PAGEptr page);
  /* Writes a fat string to the page. Characters on the esc list are
     printed with escapes. */

  void symbol_to_page(FAT_STR name, PAGEptr page);
  /* Writes a symbol name to the page with escapes for the following
     characters: '0' (literal zero), '?' (literal question mark), '%'
     (literal percent sign), ' ', '\t', '\n'. */

  void label_to_page(id_type id, int escape_p, int watch_rm, PAGEptr page);
  /* Writes a label to the page, either a single symbol or a pair of
     symbols separated fy a colon. */

  PAGEptr labels_to_page(NETptr net, PAGEptr page);
  /* Writes the label alphabet of the network to the page and returns
     the page. If the page argument is NULL, a new page created. */

  PAGEptr sigma_to_page(NETptr net, PAGEptr page);
  /* Writes the sigma alphabet of the network to the page and returns
     the page. In the verbose mode, the function of any flag diacritic
     in the sigma is described. If the page argument is NULL, a new page
     is created. */

  PAGEptr network_to_page(NETptr net, PAGEptr page);
  /* Writes the states and arcs of the network to the page and returns
     the page. If the page argument is NULL, a new page is created. */

  PAGEptr words_to_page(NETptr net, int side, int escape_p, PAGEptr page);
  /* Writes paths of the network to the page and returns the page. If
     the page argument is NULL, a new page is created. The side
     argument can be UPPER, LOWER, or BOTH. If the network is
     circular, a loop is traversed just once and the site of the loop
     is marked with three dots.  The output format is contolled by the
     macros IY_OBEY_FLAGS, IY_SHOW_FLAGS and IY_PRINT_SPACE, and
     IY_PRINT_PAIRS. See the explanations below. */

  PAGEptr random_words_to_page(NETptr net, int side, int n, PAGEptr page);
  /* Writes n random paths of the network to the page and returns the
     page. If the page argument is NULL, a new page is created. The
     side argument can be UPPER, LOWER, or BOTH. If the network is
     acyclic the algorithm counts the number of paths and picks one at
     random. If the network is cyclic, the algorithm chooses an
     outgoing arc at random and decides randomly to stop or to
     continue at a final state. The output format is contolled by the
     macros IY_OBEY_FLAGS, IY_SHOW_FLAGS and IY_PRINT_SPACE, and
     IY_PRINT_PAIRS. See the explanations below. */

  int alphabet_to_page(ALPHABETptr alph, PAGEptr page);
  /* Writes the alphabet to the page. Returns the number of items
     in the alphabet. */

  PAGEptr flags_to_page(NETptr net, PAGEptr page);
  /* Writes the network status flags to the page and returns the
     page. For example, Flags: deterministic, pruned, minimized,
     epsilon_free, loop_free. If the page argument is NULL, a new page
     is created. */

  PAGEptr properties_to_page(NETptr net, PAGEptr page);
  /* Writes the network property list to the page. and returns the
     page. If the page argument is NULL, a new page is created. */

  PAGEptr net_size_to_page(NETptr net, PAGEptr page);
  /* Writes the size of the network to the page and returns the
     page. For example, 660 bytes. 4 states, 3 arcs, 1 path. Label
     Map: Default. If the page argument is NULL, a new page is
     created. */

  PAGEptr time_to_page(intptr_t start, intptr_t end, PAGEptr page);
  /* Prints the difference between end and start times to the page in
     terms of seconds, minutes, and hours. and returns the page. If
     the page argument is NULL, a new page is created. */

  PAGEptr label_vector_to_page(LAB_VECTORptr lab_vect, PAGEptr page,
                               int escape_p, char *sep);
  /* Prints the labels corresponding to the label IDs in the label
     vector to the page and returns the page. If the page argument is
     NULL, a new page is created. */

  PAGEptr symbol_list_to_page(char *name, PAGEptr page);
  /* Writes the members of the list defined as name to the page and
     returns the page as the value, or NULL if an error occurs.
     If the page argument is NULL, a new page is creaed. */

  PAGEptr file_info_to_page(PAGEptr page);
  /* Writes the information to the page about the last network file
     that was either loaded or saved and returns the page. If the page
     argument is NULL a new page is created(). */

  PAGEptr storage_info_to_page(PAGEptr page);
  /* Writes the information to the page about the storage used
     for states, arcs, and other managed data structures.
     If the page argument is NULL a new page is created(). */

  int longest_string_to_page(NETptr net, int side, PAGEptr page);
  /* Writes to the page the longest string in the network, that is the
     string on the longest non-looping path from the start state to a
     final state. The side must be UPPER or LOWER.  Epsilons are
     ignored.  Returns the length of the string on success, -1 on
     error. Not implemented for vectorized or compacted networks. */

  int shortest_string_to_page(NETptr net, int side, PAGEptr page);
  /* Writes to the page the shortest string in the network, that is
     the string on the shortest path from a start state to a final
     state. The side must be UPPER or LOWER.  Epsilons are ignored.
     Returns the length of the string on success, -1 on error.  Not
     implemented for vectorized or compacted networks. */

  typedef struct TALLY TALLYcell, *TALLYptr;

  /* Label statistics */

  typedef struct LABEL_STATS {
    id_type max_label;
    int tally_size;
    TALLYptr tally;
  } LABEL_STATStype, *LABEL_STATSptr;

  typedef struct CFSM_CONTEXT {
    int mode ;
    int reclaimable;
    char *copyright_string ;          /* COPYRIGHT_OWNER */
    int compose_strategy ;
    int execution_error;
    int in_character_encoding ;  /* CHAR_ENC_UTF_8 or CHAR_ENC_ISO_8859_1 */
    int out_character_encoding ; /* CHAR_ENC_UTF_8 or CHAR_ENC_ISO_8859_1 */

    ERROR_STREAM errorstream;

    IntParPtr interface;

    struct LABEL_STATS label_stats;

    struct temporary_buffers {
      STRING_BUFFERptr string_buffer;
      STRING_BUFFERptr fat_str_buffer;
      PAGEptr page_buffer;
      LAB_VECTORptr lab_vector;
    } temp_bufs ;
    struct flag_parameters
    {
      int keep_p ;
      int determinize_p ;
      int minimize_p ;
      int prune_p ;
      int reclaim_p ;
      int embedded_command_p;
    } flags ;
    struct pretty_print_parameters
    {
      int cur_pos ;                    /* cur_pos */
      int indent ;
      int line_pos ;
      char *output_buffer ;            /* output_buffer */
      int output_buffer_size ;         /* OUTPUT_BUFFER_SIZE */
      int right_margin ;
      char *eol_string ;
    } pretty_print ;
    struct path_index_data
    {
      int max_path_index_pos ;         /* MAX_PATH_INDEX_POS */
      int path_index_incr ;            /* PATH_INDEX_INCR */
      int path_index_pos ;             /* PATH_INDEX_POS */
      intptr_t *path_index_vector ;    /* PATH_INDEX_VECTOR */
    } index ;
    struct parse_parameters_and_data
    {
      int ignore_white_space_p ;
      int zero_to_epsilon_p ;
      int input_seq_size ;              /* WORD_STRING_SIZE */
      id_type *input_seq ;              /* INPUT_SEQ */
      id_type *lower_match ;            /* LOWER_MATCH */
      id_type *match_table ;            /* MATCH_TABLE */
      id_type *upper_match ;            /* UPPER_MATCH */
      int obsolete_parse_tables ;       /* PTBL_OBSOLETE */
    } parse;
    struct bin_io_parameters_and_data
    {
      int altchain_p ;                /* ALTCHAIN_P */
      int status_bar_p ;              /* DISPLAY_READ_STATUS_BAR */
      int32 status_bar_increment ;    /* STATUS_BAR_INCREMENT */
      uint32 arc_count ;              /* ARC_COUNT */
      byte cur_byte ;                 /* CUR_BYTE */
      STANDARD_HEADERptr last_header; /* LAST_HEADER */
      STANDARD_HEADERptr next_header; /* NEXT_HEADER */
      STATEptr  cur_state ;           /* CUR_STATE */
      STATEptr  *state_stack ;        /* STATE_STACK */
      char **attributes ;             /* STANDARD_ATTRIBUTES */
      int attribute_count ;           /* STANDARD_ATTRIBUTE_COUNT */
    } bin_io ;
    struct define_data
    {
      HASH_TABLEptr net_table;        /* DEF_TABLE */
      HASH_TABLEptr set_table;
    } define;
  } FST_CNTXT, *FST_CNTXTptr;

  /* CFSM_CONTEXT is a large data structure that holds the interface
     parameters and many other types of data required by a cfsm
     application. An application based on this API should first
     call initialize_cfsm() to allocate a context structure. The
     structure is freed by reclaim_cfsm(). Many of the fields in
     the context data structure can be accessed using macros
     such as IY_PRINT_PAIRS and IY_EOL_STRING. See below for a
     complete list and explanations. In the fst application, many
     of these parameters can be reset from the command line with
     the 'set' command. */

#define FST_mode(X)                   (X)->mode
#define FST_reclaimable(X)            (X)->reclaimable
#define FST_copyright_string(X)       (X)->copyright_string
#define FST_execution_error(X)        (X)->execution_error

#define FST_compose_strategy(X)       (X)->compose_strategy

#define FST_string_buffer(X)          (X)->temp_bufs.string_buffer
#define FST_fat_str_buffer(X)         (X)->temp_bufs.fat_str_buffer
#define FST_page_buffer(X)            (X)->temp_bufs.page_buffer
#define FST_lab_vector(X)             (X)->temp_bufs.lab_vector

#define FST_keep_p(X)                 (X)->flags.keep_p
#define FST_determinize_p(X)          (X)->flags.determinize_p
#define FST_interactive_p(X)          (X)->flags.interactive_p
#define FST_last_errors_p(X)          (X)->flags.last_errors_p
#define FST_lex_errors_p(X)           (X)->flags.lex_errors_p
#define FST_minimize_p(X)             (X)->flags.minimize_p
#define FST_name_nets_p(X)            (X)->flags.name_nets_p
#define FST_obey_flags_p(X)           ((X)->interface).obey_flags_p
#define FST_prune_p(X)                (X)->flags.prune_p
#define FST_sq_final_strings_arcs(X)  (X)->flags.sq_final_strings_arcs
#define FST_sq_intern_strings_arcs(X) (X)->flags.sq_intern_strings_arcs
#define FST_sq_string_onelong(X)      (X)->flags.sq_string_onelong
#define FST_reclaim_p(X)              (X)->flags.reclaim_p
#define FST_recode_cp1252(X)          (X)->flags.recode_cp1252
#define FST_unicode_p(X)              (X)->flags.unicode_p
#define FST_verbose_p(X)              (X)->flags.verbose_p
#define FST_embedded_command_p(X)     (X)->flags.embedded_command_p

#define FST_cur_pos(X)                (X)->pretty_print.cur_pos
#define FST_indent(X)                 (X)->pretty_print.indent
#define FST_line_pos(X)               (X)->pretty_print.line_pos
#define FST_output_buffer(X)          (X)->pretty_print.output_buffer
#define FST_output_buffer_size(X)     (X)->pretty_print.output_buffer_size
#define FST_right_margin(X)           (X)->pretty_print.right_margin
#define FST_eol_string(X)             (X)->pretty_print.eol_string

#define FST_max_path_index_pos(X)     (X)->index.max_path_index_pos
#define FST_path_index_pos(X)         (X)->index.path_index_pos
#define FST_path_index_vector(X)      (X)->index.path_index_vector

#define FST_ignore_white_space_p(X)   (X)->parse.ignore_white_space_p
#define FST_zero_to_epsilon_p(X)      (X)->parse.zero_to_epsilon_p
#define FST_input_seq_size(X)         (X)->parse.input_seq_size
#define FST_input_seq(X)              (X)->parse.input_seq
#define FST_lower_match(X)            (X)->parse.lower_match
#define FST_match_table(X)            (X)->parse.match_table
#define FST_upper_match(X)            (X)->parse.upper_match
#define FST_pars_tbl_obsolete(X)      (X)->parse.obsolete_parse_tables

#define FST_altchain_p(X)             (X)->bin_io.altchain_p
#define FST_status_bar_p(X)           (X)->bin_io.status_bar_p
#define FST_status_bar_increment(X)   (X)->bin_io.status_bar_increment
#define FST_arc_count(X)              (X)->bin_io.arc_count
#define FST_cur_byte(X)               (X)->bin_io.cur_byte
#define FST_last_header(X)            (X)->bin_io.last_header
#define FST_next_header(X)            (X)->bin_io.next_header
#define FST_cur_state(X)              (X)->bin_io.cur_state
#define FST_state_stack(X)            (X)->bin_io.state_stack
#define FST_attributes(X)             (X)->bin_io.attributes
#define FST_attribute_count(X)        (X)->bin_io.attribute_count

#define FST_defined_nets(X)           (X)->define.net_table
#define FST_defined_sets(X)           (X)->define.set_table

  FST_CNTXTptr get_default_cfsm_context(void);
  /* Returns a pointer to the structure allocated and initialized by
     initialize_cfsm(). */

  int check_for_input_encoding(int *char_encoding, FILE *stream);
  /* Looks at the current position in the stream to see if it gives
     an indication of the character encoding for the file, that is,
     either a BOM (Byte Order Mark) or an Emacs-style character
     encoding declaration of the form
     # -*- coding: utf-8 -*-
     or
     # -*- coding: iso-8859-1 -*-
     If that is the case, the *char_encoding is set to either
     CHAR_ENC_UTF_8 or CHAR_ENC_ISO_8859_1 and the file position
     in the stream moves to the first byte beyond the character
     encoding indication. If no character encoding indication is
     found *char_encoding is set to CHAR_ENC_UNKNOWN and the file
     position in the stream remains unchanged. Returns 0 unless
     some unexpected error occurs. In that case the return value
     is 1. */

  int set_char_encoding(FST_CNTXTptr cntxt, int code);
  /* Sets the character encoding mode of the cntxt. The code must be
     either CHAR_ENC_UTF_8 or CHAR_ENC_ISO_8859_1. Returns 0 on
     success, 1 on error. */

#define IY_PRINT_PAIRS        (int_parameters())->alphabet.print_pairs
  /* If the value is 1, the apply routines display both the input and the
     output side of the labels matching the input. By default only the
     output side is shown. Default is 0. */

#define IY_PRINT_SIGMA        (int_parameters())->io.print_sigma
  /* If the value is 1, the sigma of a network is printed when the
     network is printed. Default is 1. */

#define IY_PRINT_SPACE        (int_parameters())->io.print_space
  /* If the value is 1, a space is printed to separate the symbols
     in the output of many display commands. Default is 0. */

#define IY_MAX_STATE_VISITS   (int_parameters())->io.max_state_visits
  /* The setting IY_MAX_STATE_VISITS determines the number of times the
     same state can be visited along a path. If the value is 1, loops
     are ignored. If the value is 2, a looping path is traversed just
     one time. Default is 1. */

#define IY_MINIMIZE_P         (int_parameters())->general.minimal
  /* The setting of IY_MINIMIZE_P is used by many network operations
     to decide whether the result should be minimized. If the value
     is 1, the function minimize_net() is called. If the value is 0,
     the result is not minimized. Default is 1. */

#define IY_RECURSIVE_DEFINE   (int_parameters())->general.recursive_define
  /* If the value is 1, definitions such as define_regex_net("A", "a | A b")
     yields a the left-recursive language a b* instead of the union of
     a and Ab. Default is 0. */

#define IY_VERBOSE            (int_parameters())->general.verbose
  /* If the value is 1, cfsm prints reports about its activities such
     as opening and closing of files. If the value is 0, no messages
     other than error messages are printed. Default is 1. */

#define IY_OBEY_FLAGS         (int_parameters())->io.obey_flags
  /* If the value is 1, flag diacritic constraints are enforced. If
     the value is 0, flag diacritic symbols are treated as epsilons.
     Default is 1. */

#define IY_SHOW_FLAGS         (int_parameters())->io.show_flags
  /* If the value is 1, flag diacritic symbols are displayed in the
     output. Default is 0. */

#define IY_MAX_CONTEXT_LENGTH (int_parameters())->general.max_context_length
  /* Specifies the maximum length of a left context in pattern matching.
     Default is 64. */

#define IY_QUIT_ON_FAIL       (int_parameters())->general.quit_on_fail
  /* If the value is 1, the cfsm application quits on error unless it is in
     an interactive mode. */

#define IY_VECTORIZE_N        (int_parameters())->general.vectorize_n
  /* This variable specifies the minimum number of arcs a state must
     have in order to be vectorized by vectorize_net(). Default is 50. */

#define IY_USE_TIMER          (int_parameters())->io.use_timer
  /* If the value is 1, a timer is started for operations that might take
     a while to complete. */

#define IY_CHAR_ENCODING      (int_parameters())->io.char_encoding
  /* Determines the character encoding. The value must be either
     CHAR_ENC_UTF_8 or CHAR_ENC_ISO_8859_1. In UTF8 mode, the string input
     functions read and the string output functions write strings in the
     UTF-8 format. In the ISO-8859-1 mode, the input functions assume that
     the input strings are Latin-1 strings except that the non-ISO-8859-1
     symbols in Microsoft's CP1252 ("Windows Latin-1") are tolerated and
     quietly mapped to the proper Unicode symbols. */

#define IY_EOL_STRING         (get_default_cfsm_context())->pretty_print.eol_string
  /* The end-of-line string for some printing applications. Default is "\n". */

#define IY_INDENT             (get_default_cfsm_context())->pretty_print.indent
  /* Indentation for new_page(). Default is 0. */
#define IY_RIGHT_MARGIN       (get_default_cfsm_context())->pretty_print.right_margin
  /* Right marging for new_page(). Default is 72. */

  /********************************
   *  COMPACT NETWORK CONFIGURATION *
   *********************************/

  typedef struct COMPACT_CONFIG COMP_CONFtype, *COMP_CONFptr;

  /*************************
   *  ARC_ITERATOR object  *
   *************************/

  typedef struct ARC_ITERATOR ARCITtype, *ARCITptr;

  ARCITptr init_arc_iterator(NETptr net, ARCITptr arc_it);
  /* Initializes an arc iterator suitable for the particular type of net.
     If the second argument is NULL, a new arc iterator is created. */

  void start_arc_iterator(ARCITptr arc_it, void *state, void** next, int *last_p);
  /* Initializes an arc iterator for a particular state. The last two arguments
     are needed to allow a single iterator to be used in a recursive descent
     through states. */

  ARCptr next_iterator_arc(ARCITptr arc_it, void ** next, int *last_p);
  /* Returns a standard arc even from a state that has been vectorized and
     thus has no standard arcs. */

  void free_arc_iterator(ARCITptr arc_it);
  /* Reclaims the memory allocated to the arc iterator. */

  /*****************
   * APPLY CONTEXT
   *****************/

  typedef struct APPLY_CONTEXT {
    int reclaimable;
    NETptr net1;             /* Net to be applied */
    NETptr net2;             /* Second network for bimachines -- not used now */
    NVptr net_vector;
    int side;                /* Input side: LOWER or UPPER */
    int out_side;            /* Output side: UPPER or LOWER */
    int obey_flags_p;        /* 1 = obey flag diacritics, 0 = don't obey */
    int print_space_p;       /* Separate output symbols by a space */
    int show_flags_p;        /* Show flag diacritics in the output */
    int flags_p;             /* 1 = Network has flag diacritics */
    int recursive_p;
    int eol_is_eof_p;
    int next_input_line_p;
    int need_separators_p;  
    int count_patterns_p; 
    int delete_patterns_p; 
    int extract_patterns_p;
    int locate_patterns_p;   
    int one_tag_per_line_p;
    int mark_patterns_p; 
    int max_context_length;
    int in_pos;  
    int end_pos; 
    int nv_pos;
    int level;
    int depth;
    int num_inputs;          /* number of processed inputs */
    const char *eol_string;  /* defaults to "\n" */
    int end_of_input;        /* end of input file or string */
    int longest_match;       /* longest pattern match found */
    int max_recursion_depth;
    PARSE_TBL parse_table;   /* Maps input symbol to a symbol ID */
    int (*next_symbol_fn)(id_type *, void *); /* fetches the next input ID */
    void (*write_buffer_fn)(void *);  /* Function to write into out_buffer */
    id_type (*in_fn)(id_type);        /* lower_id() or upper_id() */
    id_type (*out_fn)(id_type);       /* upper_id() or lower_id() */
    id_type prev_sym;
    MATCH_TABLEptr match_table;
    unsigned char *input;             /* current input string */
    unsigned char *remainder;         /* remaining part of the input string */
    FILE *in_stream;                  /* input stream */
    FILE *out_stream;                 /* output stream */
    void *in_data;
    void *out_data;
    int out_count;                    /* output counter */
    void (*output_fn)(void *cntxt);   /* output function */
    LAB_VECTORptr in_vector;          /* vector for storing input IDs */
    LAB_VECTORptr mid_vector;
    LAB_VECTORptr out_vector;         /* vector for storing output IDs */
    LAB_VECTOR_TABLEptr in_table;
    LAB_VECTOR_TABLEptr out_table;
    ALPHABETptr sigma;
    ALPHABETptr prev_sigma;
    VECTORptr host_net_vector;
    ALPHABETptr flag_register;
    LAB_VECTORptr flag_vector;
    LAB_VECTORptr tag_vector;
    VECTORptr arc_vector;
    VECTORptr state_vector;
    VECTORptr destination_vector;
    VECTORptr start_vector;
    VECTORptr task_vector;
    VECTOR_TABLEptr pos_table;
    IN_BUFFERptr in_buffer;
    STRING_BUFFERptr out_buffer;
    STRING_BUFFERptr save_buffer;
    void *hyper_unit;
    uintptr_t file_pos;

    LAB_VECTORptr other_than_vector;

    IO_SEQptr in_seq;
    IO_SEQptr out_seq;
    IO_SEQ_TABLEptr input_table;
    IO_SEQ_TABLEptr output_table;

    /* Net traversal call-back functions: */
    void* (*start_state_fn)(NETptr, void**, int*);
    id_type (*label_from_arc_fn)(NETptr, void**, int*, int*);
    void (*next_arc_fn)(NETptr, void**, int);
    void* (*destination_fn)(NETptr, void**);

    STATEptr solution_tree;  /* For storing the final result in a tree
                                instead of the table. */
    LAB_RINGptr input_ring;
    LOCATION_PATHptr location_path; /* Application path in a network. */
    int location_path_length;  /* Size of location path */
    HEAPptr task_heap;         /* Heap for iterative_apply_patterns() */
    STACKptr task_stack;       /* Stack for iterative apply_patterns() */
    STATEptr state;
    ARCITptr arc_it;
  } APPLYtype, *APPLYptr;

  /* An apply context is a very large data structure that is
     initialized for various types of apply operations such as
     apply_network(), apply_patterns(), and compose_apply(). The input
     to an apply operation is a string or a stream or a table of label
     vectors. The output is collected into a string buffer, into an
     array of label vectors or compiled into a network. The APPLY_CONTEXT
     data structure contains data fields for all the different flavors of
     apply. Any particular apply operation will only have use for some of
     them. */

#define APPLY_reclaimable(X)            (X)->reclaimable
#define APPLY_net1(X)                   (X)->net1
#define APPLY_net2(X)                   (X)->net2
#define APPLY_net_vector(X)             (X)->net_vector
#define APPLY_end_of_input(X)           (X)->end_of_input
#define APPLY_side(X)                   (X)->side
#define APPLY_out_side(X)               (X)->out_side
#define APPLY_obey_flags_p(X)           (X)->obey_flags_p
#define APPLY_print_space_p(X)          (X)->print_space_p
#define APPLY_show_flags_p(X)           (X)->show_flags_p
#define APPLY_flags_p(X)                (X)->flags_p
#define APPLY_recursive_p(X)            (X)->recursive_p
#define APPLY_eol_is_eof_p(X)           (X)->eol_is_eof_p
#define APPLY_eol_string(X)             (X)->eol_string
#define APPLY_next_input_line_p(X)      (X)->next_input_line_p
#define APPLY_in_pos(X)                 (X)->in_pos
#define APPLY_end_pos(X)                (X)->end_pos
#define APPLY_nv_pos(X)                 (X)->nv_pos
#define APPLY_parse_table(X)            (X)->parse_table
#define APPLY_next_symbol_fn(X)         (X)->next_symbol_fn
#define APPLY_write_buffer_fn(X)        (X)->write_buffer_fn
#define APPLY_in_fn(X)                  (X)->in_fn
#define APPLY_out_fn(X)                 (X)->out_fn
#define APPLY_in_stream(X)              (X)->in_stream
#define APPLY_out_stream(X)             (X)->out_stream
#define APPLY_in_data(X)                (X)->in_data
#define APPLY_out_data(X)               (X)->out_data
#define APPLY_out_count(X)              (X)->out_count
#define APPLY_output_fn(X)              (X)->output_fn
#define APPLY_match_table(X)            (X)->match_table
#define APPLY_input(X)                  (X)->input
#define APPLY_remainder(X)              (X)->remainder
#define APPLY_in_vector(X)              (X)->in_vector
#define APPLY_sigma(X)                  (X)->sigma
#define APPLY_host_net_vector(X)        (X)->host_net_vector
#define APPLY_prev_sigma(X)             (X)->prev_sigma
#define APPLY_mid_vector(X)             (X)->mid_vector
#define APPLY_out_vector(X)             (X)->out_vector
#define APPLY_in_table(X)               (X)->in_table
#define APPLY_out_table(X)              (X)->out_table
#define APPLY_flag_register(X)          (X)->flag_register
#define APPLY_flag_vector(X)            (X)->flag_vector
#define APPLY_tag_vector(X)             (X)->tag_vector
#define APPLY_arc_vector(X)             (X)->arc_vector
#define APPLY_state_vector(X)           (X)->state_vector
#define APPLY_dest_vector(X)            (X)->destination_vector
#define APPLY_task_vector(X)            (X)->task_vector
#define APPLY_in_buffer(X)              (X)->in_buffer
#define APPLY_out_buffer(X)             (X)->out_buffer
#define APPLY_save_buffer(X)            (X)->save_buffer
#define APPLY_hyper_unit(X)             (X)->hyper_unit
#define APPLY_other_than_vector(X)      (X)->other_than_vector
#define APPLY_in_seq(X)                 (X)->in_seq
#define APPLY_out_seq(X)                (X)->out_seq
#define APPLY_input_table(X)            (X)->input_table
#define APPLY_output_table(X)           (X)->output_table
#define APPLY_start_state_fn(X)         (X)->start_state_fn
#define APPLY_label_from_arc_fn(X)      (X)->label_from_arc_fn
#define APPLY_next_arc_fn(X)            (X)->next_arc_fn
#define APPLY_destination_fn(X)         (X)->destination_fn
#define APPLY_solution_tree(X)          (X)->solution_tree
#define APPLY_need_separators_p(X)      (X)->need_separators_p
#define APPLY_max_context_length(X)     (X)->max_context_length
#define APPLY_input_ring(X)             (X)->input_ring
#define APPLY_location_heap(X)          (X)->location_heap
#define APPLY_count_patterns_p(X)       (X)->count_patterns_p
#define APPLY_delete_patterns_p(X)      (X)->delete_patterns_p
#define APPLY_extract_patterns_p(X)     (X)->extract_patterns_p
#define APPLY_locate_patterns_p(X)      (X)->locate_patterns_p
#define APPLY_one_tag_per_line_p(X)     (X)->one_tag_per_line_p
#define APPLY_mark_patterns_p(X)        (X)->mark_patterns_p
#define APPLY_file_pos(X)               (X)->file_pos
#define APPLY_level(X)                  (X)->level
#define APPLY_depth(X)                  (X)->depth
#define APPLY_num_inputs(X)             (X)->num_inputs
#define APPLY_max_recursion_depth(X)    (X)->max_recursion_depth
#define APPLY_start_vector(X)           (X)->start_vector
#define APPLY_pos_table(X)              (X)->pos_table
#define APPLY_task_heap(X)              (X)->task_heap
#define APPLY_task_stack(X)             (X)->task_stack
#define APPLY_state(X)                  (X)->state
#define APPLY_out_pos(X)                (X)->out_vector->pos
#define APPLY_arc_it(X)                 (X)->arc_it

  /*****************
   * TOKENIZER
   *****************/

  /* A tokenizer is an object that applies a tokenizing transducer to
     a string returning a network containing one or more possible
     tokenization of a section of the input string. For example, "Dr."
     could be a single token, an abbreviation of a title as in
     "Dr. No." It could also be another kind of single token, an
     abbreviaton "drive" as in "Mulholland Dr." A sentence final
     abbreviation adds to the ambiguity because it loses the final
     period in front of a sentence-terminating period, as in "We met
     at Mulholland Dr."  A tokenizer applies the tokenizer network to
     a string or a stream in breadth-first mode pursuing all
     alternatives in parallel.  At pinch points where all the
     alternative paths come together into single state, it returns a
     network representing all the possible tokenizations of the input
     string up to that point. */

  typedef struct TOKENIZER TOKtype, *TOKptr;
  /* The data structure for a tokenizer. */

  TOKptr new_tokenizer(NETptr token_fst, char *in_string, FILE *in_stream,
                       id_type token_boundary, id_type fail_token,
		       FST_CNTXTptr fst_cntxt);
  /* Returns a new tokenizer using token_fst either for the input in
     in_string or the file in_stream.One of the two arguments,
     in_string or in_stream, must be NULL, the other one must be
     specified. The tokens returned by the function are terminated
     by a token boundary or fail_token in the case the token_fst
     fails to accept some section of the input. This can only happen
     if he lower-side language of the tokenizer fst is not the
     universal sigma-star language.The token boundary symbol must
     appear only on the upper side of the tokenizing transducer
     unless it is "\n".Returns a new tokenizer or NULL if an error
     occurs. */

  TOKptr make_tokenizer(char *fst_file, char *in_string, char *in_file,
                        char *token_bound, char *fail_token,
			FST_CNTXTptr fst_cntxt);
  /* Returns a new tokenizer obtained by calling new_tokenizer() with
     the expected arguments. One of the two arguments, in_string or
     in_file, must be NULL, the other one must be a string.  The
     token_bound string is a token separator, such as "\n" or a
     special symbol such as "TB". The fail_token is a string such as
     "FAILED_TOKEN" to be used in extremis when all the alternative
     paths the tokenizer has pursued have failed. This can only happen
     if he lower-side language of the tokenizer fst is not the
     universal sigma-star language. Returns a new tokenizer or NULL if
     an error occurs. */

  NETptr next_token_net(TOKptr tok);
  /* Returns the next token network or NULL when the input has been
     exhausted. */

  /*Commenting as the definition was commented out*/
  /*int restart_tokenizer(TOKptr tok, char *string, FILE *stream);*/
  /* Restarts the tokenizer tok on a new input string. */

  void free_tokenizer(TOKptr tok);
  /* Frees the tokenizer tok and all its contents. */

  /*****************************************************
   *                FUNCTION PROTOTYPES
   *****************************************************/

  /* Initialization and reclamation of CFSM context */

  FST_CNTXTptr initialize_cfsm(void);
  /* Allocates and initializes the CFSM_CONTEXT structure. Any application
     using this API needs to call this function before calling any
     cfsm functions or macros. */

  void reclaim_cfsm(FST_CNTXTptr fst_cntxt);
  /* Releases all the memory allocated to the CFSM_CONTEXT and all other
     data structures declared within the context such as stacks, heaps,
     networks, states, arcs and alphabets. */

  FST_CNTXTptr get_default_cfsm_context(void);
  /* Returns a pointer to the structure allocated by initialize_cfsm().
     This function is called implicitly by macros such as IY_EOL_STRING. */

  IntParPtr int_parameters(void);
  /* Returns a pointer to the interface parameters component of the cfsm_context.
     This function is called implicitly by macros such as IY_CHAR_ENCODING. */

  /* Binary output functions */

  int save_net(NETptr net, char *filename, FST_CNTXTptr fst_cntxt);
  /* Saves a single net in the Xerox proprietary binary format. Returns
     0 on success and an error code if something goes wrong. */

  int save_nets(NVptr nv, char *filename, FST_CNTXTptr fst_cntxt);
  /* Saves any number of nets packaged into a net vector. Returns 0 on
     success and an error code if something goes wrong. A net vector
     is created calling make_nv(n) where n is the number of slots in
     the vector. The statement NV_net(nv, 0) = net; puts net into the
     first slot of the nv. */

  int save_defined_nets(char *filename, FST_CNTXTptr fst_cntxt);
  /* Saves all the networks that have been bound to a name using either the
     define_net() or define_regex_net() function. Return 0 on success and an
     error code on failure. When the nets are loaded
     with the load_defined_nets() command, the definitions are restored.
     The definitions are not restored if the networks are loaded with the
     load_nets() command instead. */

  /* Binary input functions */

  NETptr load_net(const char *filename, FST_CNTXTptr fst_cntxt);
  /* Loads a single network from the file. If the file contains more than
     one network, only the first one is loaded. Returns the network ono
     success and NULL on error. */

  NVptr load_nets(const char *filename, FST_CNTXTptr fst_cntxt);
  /* Loads any number of networks from the file. Returns a net vector on
     success and NULL on error. */

  int load_defined_nets(char *filename, FST_CNTXTptr fst_cntxt);
  /* Loads any number of networks saved by save_defined_nets(). Each
     network has on its property list the name it was defined as. The
     definitions are restored. Returns 0 on success, 1 on error. Prints
     a warning message if some of the networks have not been defined. */

  NETptr load_defined_net(char *name, char *filename, FST_CNTXTptr fst_cntxt);
  /* Loads any number of networks saved by save_defined_nets() and
     restores the definitions. Returns a copy of the network with the given
     name if it is one of the networks or NULL in case the file does not
     contain a defined network with that name. */

  /* Text input functions */

  NETptr string_to_net(char *str, int byte_pos_p);
  /* Compiles a network from a string. If the byte_pos_p is non-zero,
     the arcs of the network will be big arcs that have in their
     user_pointer field the byte position of the first symbol in its
     label. If byte_pos_p is zero, byte positions are not recorded and
     the arcs are normal arcs. */

  NETptr read_text(char *filename);
  /* Reads a text file line by line and converts each line to a path
     in a network. Returns the assembled network. For example, if the
     file consists of the two lines San Francisco London the resulting
     network is the same as compiled the one returned by
     read_regex("{San Francisco} | {London}); If the first line of the
     file is # -*- coding: iso-8859-1 -*- the file is processed as a
     Latin-1 file even in UTF-8 mode.  Similarly, if the file begins
     with # -*- coding: utf-8 -*- it is processed as a utf-8 file
     regardless of the prevailing mode. The exclamation point, !, may
     be used instead of #.  Any other lines starting with # or ! are
     ignored. */

  NETptr read_spaced_text(char *filename);
  /* Reads a transducer or a net with multicharacter symbols or both
     from the file line by line. Adjacent lines are read as a single
     path with the first one processed as the upper side of the path
     and the second one as the lower side of the path. For example,
     the following pair of lines
     l e a v e +Verb +Past
     l e f t
     will be compiled by read_spaced_text() into the same path as
     produced by
     read_regex("[l e a v e %+Verb %+Past]:{left}");
     Pairs of paths and single paths must be separated by an empty line:
     l e a v e +Verb +Past
     l e f t

     S a n %   F r a n c i s c o

     c i t y +Noun +Pl
     c i t i e s
     White space characters are interpreted as separators between
     non-white space symbols except when preceded by %. Thus the fourth
     line above gives the same result as
     read_regex({San Francisco}).
     The first line of the input line is checked for a possible character
     encoding declaration. See the comment on read_text() above. */

  NETptr read_regex(const char *regex_str);
  /* Compiles the regular expression string and returns the resulting
     network or a null fsm if an error occurs. See chapters 2 and 3 of
     the book Finite State Morphology by Kenneth R Beesley and Lauri
     Karttunen for a description of the Xerox regular expression
     formalism. */

  NETptr read_lexc(char *filename);
  /* Compiles a file written in the lexc formalism. See Chapter 4 of the
     Beesley & Karttunen book about the lexc language. Returns the network
     or a null fsm on error. */

  NETptr read_prolog(char *filename);
  /* Compiles a network expressed as Prolog style-clauses. For example,
     # -*- coding: utf-8 -*-
     network(net_1b10d0).
     symbol(net_1b10d0, "a").
     arc(net_1b10d0, 0, 1, "?").
     arc(net_1b10d0, 0, 1, "b").
     arc(net_1b10d0, 0, 1, "c").
     arc(net_1b10d0, 0, 1, "d").
     arc(net_1b10d0, 1, 2, "b":"c").
     arc(net_1b10d0, 2, 3, "d":"0").
     final(net_1b10d0, 3).
     is the Prolog-style representation of the network compiled with
     read_regex("\a b:c d:0"); The network(net_1b10d0) clause gives the
     network an arbitrary name that is the first component of every
     subsequent clause. The arc clauses are of the form
     arc(<net>, <start_state>, <destination_state>, <label>).
     A symbol such as "a" here that is part of the sigma alphabet of
     the network but does not appear as an arc label is declared
     explixitly as a symbol. State 3 is the only final state of
     the network. "?" denotes the unknown symbol, "0" stands for
     an epsilon. "%?" is the literal question mark, "%0" the digit
     xero. */

  /* Text output functions */

  int write_text(NETptr net, char *filename);
  /* Outputs a simple network in the text format expected by the
     read_text() function. (See above.) If the network is circular,
     the function aborts with an error message. If the network is a
     transducer or if it contains multicharacter symbols, the function
     aborts with and error message referring the user to the
     read_spaced_text() function. The return value is 0 on success, 1
     on error. If the second argument is NULL, the output goes to
     stdout. */

  int write_text_to_page(NETptr net, PAGEptr page);
  /*  Like write_text but outputs to a page rather than a file. */

  int write_spaced_text(NETptr net, char *filename);
  /* Outputs a simple network or a transducer in the text format
     expected by the read_spaced_text() function. (See above.) If
     the network is circular, the function aborts with an
     error message. Returns 0 on success, 1 on failure. If the
     second argument is NULL, the output goes to stdout. */

  int write_spaced_text_to_page(NETptr net, PAGEptr page);
  /* Like write_spaced_text but ouputs to a page rather than a file. */

  int write_prolog(NETptr net, char *filename);
  /* Outputs a network as Prolog-style clauses in the format expected
     by read_prolog. (See comment above.) Returns 0 on success 1 on
     failure. */

  /* Applying transducers to strings and streams */

  APPLYptr init_apply(NETptr net, int side, FST_CNTXTptr cfsm_cntxt);
  /* Returns a pointer to an apply context initialized for a the net
     and the given input side, or NULL if an error occurs. This is the
     simplest of several functions that return an "apply context"
     object.  The context it returns is not initialized for any
     input. To use it on a string, call apply_to_string(). */

  char *apply_to_string(const char *input, APPLYptr applyer);
  /* Returns the result of calling the applyer on the given string
     input, NULL on error. The applyer must have been initialized to
     work on a given side of a given network. A non-NULL result is
     terminated with the applyer's end-of-line string, "\n" by
     default. If the application results in an empty string, the
     return value consist of the end-of-line string. If the input
     string is not recognized, the return value is an empty string
     without the end-of-line marker.  The returned string is volatile
     memory. It will be overwritten by the next call. */

  void switch_input_side(APPLYptr cntxt);
  /* Switches the input side of an applyer object from UPPER to LOWER
     and from LOWER to UPPER. */

  APPLYptr new_applyer(NETptr net, char *string, FILE *stream,
                       int input_side, FST_CNTXTptr cfsm_cntxt);
  /* Returns a pointer to an apply context that is initialized for
     applying the net to either a given string or to a given
     stream. If the input is from a string, the stream argument must
     be NULL, and vice versa. One of the two arguments must be
     non-NULL. The input side must be UPPER or LOWER. If the last
     argument is NULL the default context, the one created by
     initialize_cfsm() is chosen.  Returns a pointer to the apply
     context, or NULL if an error occurs. */

  APPLYptr make_applyer(char *fst_file, char *in_string, char *in_file,
                        int input_side, FST_CNTXTptr cfsm_cntxt);
  /* Loads a network from the fst_file, opens the in_file if it is given,
     calls new_applyer() with these parameters and returns the apply
     context, or NULL if an error occurs. */

  int next_apply_output(APPLYptr applyer);
  /* Returns zero if successful, and an int error code if not.  
     If the input is from a string, the entire string is consumed. 
     If the output is from a stream, the input consists of the the 
     next line ignoring the final eol_string. Returns 1 if the
     input has been exhausted. Otherwise the output buffer of the applyer
     will contain any number of output strings, possibly none, for the
     last input, separated by the eol_string of the applyer (default =
     "\n"). The output can be displayed with print_string_buffer(). The
     next call to next_apply_output() will overwrite the previous
     output, so the calling function should either print the result
     immediately or keep it, for example, by calling
     string_to_page(STRING_BUFFER_string(next_apply_output(applyer)),
     page). */

  void  init_apply_to_string(const char *input, APPLYptr apply_context);
  /* Initializes an applyer object created by new_applyer() or
     new_pattern_applyer() for a new input string. */

  void init_apply_to_stream(FILE *stream, APPLYptr apply_context);
  /* Initializes an applyer object created by new_applyer() or
     new_pattern_applyer() for a new input stream. */

  void free_applyer(APPLYptr applyer);
  /* Reclaims the apply context created by new_applyer() or
     new_pattern_applyer(). Does not reclaim the network it contains. */

  void free_applyer_complete(APPLYptr applyer);
  /* Reclaims the apply context created by new_applyer() or
     new_pattern_applyer(). Reclaims the net vector that it contains. */

  /* Unary Tests */

  int test_lower_bounded(NETptr net);
  /* Returns 1 if the lower  side of the network has no epsilon loops,
     otherwise 0. */

  int test_upper_bounded(NETptr net);
  /* Returns 1 if the upper  side of the network has no epsilon loops,
     otherwise 0. */

  int test_non_null(NETptr net);
  /* Returns 1 if the network is not a null fsm, that is, a network that
     has no reachable final state, otherwise 0. */

  int test_upper_universal(NETptr net);
  /* Returns 1 if the upper side of the network is the universal (sigma-star)
     langugage that contains any string of any length, including the empty
     string, otherwise 0 */

  int test_lower_universal(NETptr net);
  /* Returns 1 if the upper side of the network is the universal (sigma-star)
     langugage that contains any string of any length, including the empty
     string, otherwise 0 */

  /* Binary network tests */

  int test_equivalent(NETptr net1, NETptr net2);
  /* Returns 1 if net1 and net2 are structurally equivalent, otherwise 0.
     Two networks are structurally equivalent just in case they, have the
     same arity, the same sigma and label alphabet, the same number of arcs
     and states and equivivalent paths. If the arity is 1 and the
     networks are structurally equivalent, they encode the same language.
     If net1 and net2 are structurally equivalent transducers, they encode
     the same relation. If two transducers are not structurally equivalent,
     they may nevertheless encode the same relation by having epsilons in
     different places. The equivalence of transducers is no decidable in
     the general case. */

  int test_sublanguage(NETptr net1, NETptr net2);
  /* Returns 1 if the language or relation of net1 is a subset of the
     language of relation of net2. The test is correct when net1 and
     net2 encode simple languages but it is not generally correct for
     transducers for the reason explained above. */

  int test_intersect(NETptr net1, NETptr net2);
  /* Returns 1 if the languages or relations encoded by net1 and net2
     have strings or pairs of strings in common. The test is correct
     for simple networks but not generally correct for transducers
     for the reason explained above. */

  /* Definitions */

  int define_net(char *name, NETptr net, int keep_p);
  /* Binds the name to network. If the keep_p flag is KEEP, the
     name is bound to the copy of the network. The name can be
     used in a regular expression to splice in a copy of the
     defined network. Returns 0 on success, 1 on error. */

  int define_regex_net(char *name, char *regex);
  /* Compiles the regular expression and binds the name to it
     by calling define_net(). Returns 0 on success, 1 on error. */

  int undefine_net(char *name);
  /* Frees the network the name is bound to and unbinds the name.
     Returns 0 on success, 1 on error. */

  NETptr get_net(char *name, int keep_p);
  /* Returns the network the name is bound to, or its copy if
     keep_p is KEEP. Returns NULL if the name is undefined. */

  NETptr net(char *name);
  /* Returns get_net(name, DONT_KEEP). */

  int define_regex_list(char *name, char *regex);
  /* Compiles the regular expression and binds the name to the sigma
     alphabet of the resulting network by calling
     define_symbol_list(). The rest of the network structure is
     reclaimed. Returns 0 on success, 1 on error.
     A list name can be used in a regular expression to
     refer to the union of the symbols it contains. For example,
     define_regex_list("Vowel", "a e i o u") binds Vowel to the
     alphabet containing the five vowels. Given this definition,
     read_regex("Vowel") is equivalent to read_regex("a|e|i|o|u").
     Names that are bound to a list may also be used in so-called
     "list flags", special symbols of the form @L.name@ and @X.name@
     where L means 'member of the list' and X means 'excluding members
     of the list'. The apply operations recognize an arc labeled
     "@L.Vowel@" as standing for any member of the list Vowel. In
     contrast, calculus operations do not currently assign any special
     interpretation to list flags. */

  int define_symbol_list(char *name, ALPHABETptr alph, int keep_p);
  /* Binds the name to the alphabet, or to its copy if keep_p is
     KEEP. Returns 0 on success, 1 on error. */

  ALPHABETptr get_symbol_list(char *name, int keep_p);
  /* Returns the alphabet the name is bound to, or its copy if
     keep_p is KEEP. Returns NULL if the name is not
     bound to an alphabet. */

  ALPHABETptr symbol_list(char *name);
  /* Returns get_symbol_list(name, DONT_KEEP). */

  int undefine_symbol_list(char *name);
  /* Unbinds the name and reclaims the alphabet it was bound to.
     Returns 0 on success and 1 on error. */

  int define_function(char *fn_call, char *regex);
  /* Compiles the regular expression and binds it to the function
     call. For example, define_function("Double(X)," "X X");
     creates a simple function that concatenates the argument
     to itself. Functions are used in regular expression. Given
     the definition of "Double(X)", read_regex("Double(a)");
     is equivalent to read_regex("a a"). See the piglatin
     application for examples of more interesting function
     definitions. */

  /* Primitive network constructors */

  NETptr null_net(void);
  /* Returns a network consisting of a single non-final state.  It
     encodes the null language, a language that contains nothing, not
     even the empty string. Equivalent to read_regex("\?"); */

  NETptr epsilon_net(void);
  /* Returns a network consisting of a single final state.
     It encodes the language consisting of the empty string.
     Equivalent to read_regex("[]"); */

  NETptr kleene_star_net(void);
  /* Returns a network consisting of a single final state
     with a looping arc for the unknown symbol. It encodes
     the universal ("sigma star") language.
     Equivalent to read_regex("?*"); */

  NETptr kleene_plus_net(void);
  /*  Returns a network that encodes the universal language
      minus the empty string. Equivalent to read_regex("?+"); */

  NETptr label_net(id_type id);
  /* Returns a network that encodes the string or a pair of strings
     represented by the id. */

  NETptr symbol_net(char *sym);
  /* Returns label_net(single_to_id(sym)); */

  NETptr pair_net(char *upper, char *lower);
  /* Returns label_net(pair_to_id(upper, lower)); */

  NETptr alphabet_net(ALPHABETptr alph);
  /* Returns the network that encodes the language of the union of the
     singleton languages or relations represented by the labels in the
     alphabet. */

  /* Sigma and  Label alphabets */

  /* The return values of net_sigma() and net_labels() are the actual
     alphabets of the network. They must not be modified directly, and
     they will not be up-to-date if the network is modified. */

  ALPHABETptr net_sigma(NETptr net);
  /* Returns the network's sigma alphabet. */

  ALPHABETptr net_labels(NETptr net);
  /* Returns the network's label alphabet. */

  void update_net_labels_and_sigma(NETptr net);
  /* Updates the label and the sigma alphabet of the network and
     the network arity (1 or 2). After the update, the label
     label alphabet contains all and only labels that appear
     on some arc of the network. Any missing symbols are
     added to the sigma alphabet. */

  /* Substitutions */

  /* If the keep_p argument is KEEP, the argument networks are
     preserved unchanged. If the keep_p argument is DONT_KEEP,
     the argument networks are reclaimed or destructively modified.
     The alphabet arguments are preserved unchanged. */

  NETptr substitute_symbol(id_type id, ALPHABETptr list, NETptr net,
                           int keep_p);
  /* Replaces every arc that has id in its label by a set of arcs
     labeled by symbols created by replacing id by a member of the
     list. All the new arcs have the same destination as the original
     arc. If id is itself a member of the list, the original arc is
     reconstituted in the process. If the list is NULL or has no
     members, then all arcs that have id in their label are
     eliminated. The label and sigma alphabets are updated.  If keep_p
     is KEEP, the operation is performed on a copy of the original
     network. Returns the modified network. */

  NETptr substitute_label(id_type id, ALPHABETptr labels, NETptr net,
                          int keep_p);
  /* Like substitute_symbol() except that id is treated as a label an
     not as a label component. For example, if id represents "a", then
     only arcs with "a" as the label are affected but arcs such as
     "a:b" do not get changed. If keep_p is KEEP, the operation is
     performed on a copy of the original network. Returns the modified
     network. */

  NETptr substitute_net(id_type id, NETptr insert, NETptr target,
                        int keep_insert_p, int keep_target_p);
  /* Replaces the arcs labeled with id in the target by splicing
     a keep of the insert network between the start state of
     the arc and its destination. If keep_insert_p is KEEP, the
     the insert network is not affected by the operation.
     If keep_p is DONT_KEEP, the insert network is reclaimed.
     The target network is destructively modified if keep_target_p
     is DONT_KEEP. If keep_target_p is KEEP, the operation is
     performed on a copy of the target network. Returns the
     resulting network. */

  NETptr close_net_alphabet(NETptr net);
  /*  Closes the alphabet of the network by removing all arcs
      with OTHER in their label. Returns the modified network. */

  NETptr eliminate_flag(NETptr net, char *name, int keep_p);
  /* Eliminates all arcs that have name as an attribute of a flag
     diacritic such as @U.Case.Acc@ or as a list symbol in a list flag
     such as @L.Vowel@ or as a defined network in an insert flag such
     as @I.FirstName@. In the case of a flag diacritic such as
     @U.Case.Acc@, the function constructs a constraint network and
     composes it with net (or a copy of it) to enforce the constraint.
     In the case of a list or an insert flag, the function eliminates
     the arcs in question by splicing in a network. Returns the
     modified network or the copy of it if keep_p is KEEP. */

  /* Alphabet operations */

  /* If the keep_p argument is KEEP, the argument alphabets are
     preserved unchanged. If the keep_p argument is DONT_KEEP, the
     argument alphabets are reclaimed or destructively modified. If
     there is no keep_p flag, the operation is non-destructive. The
     alphabets may be of either of the two types, binary vectors or
     label alphabets. */

  ALPHABETptr alph_add_to(ALPHABETptr alph, id_type new_id,
                          int keep_p);
  /* Adds new_id to the alphabet. If keep_p is KEEP, the
     operation is made on a copy of alph. Returns the
     modified alphabet. */

  ALPHABETptr alph_remove_from(ALPHABETptr alph, id_type id,
                               int keep_p);
  /* Removes id from the alphabet or from its copy if keep_p is
     KEEP. Returns the modified alphabet. */

  ALPHABETptr union_alph(ALPHABETptr alph1, ALPHABETptr alph2,
                         int keep_alph1_p, int keep_alph2_p);
  /* Returns the union of the two alphabets. If the keep_p
     arguments are DONT_KEEP the input alphabets are reclaimed. */

  ALPHABETptr intersect_alph(ALPHABETptr alph1, ALPHABETptr alph2,
                             int keep_alph1_p, int keep_alph2_p);
  /* Returns the intersection of the two alphabets. If the keep_p
     arguments are DONT_KEEP, the orignals are reclaimed. */

  ALPHABETptr minus_alph(ALPHABETptr alph1, ALPHABETptr alph2,
                         int keep_alph1_p, int keep_alph2_p);
  /* Returns a new binary alphabet containing all the IDs in alph1
     that are not in alph2. The input alphabets are reclaimed
     unless the keep_p flags are KEEP. */

  ALPHABETptr binary_to_label(ALPHABETptr alph);
  /* Converts the alphabet from binary to label format, if it is not
     in the label format already. */

  ALPHABETptr label_to_binary(ALPHABETptr alph);
  /* Converts the alphabet from label to binary format, if it is not
     in the label format already. */

  int test_equal_alphs(ALPHABETptr alph1, ALPHABETptr alph2);
  /* Returns 1 if alph1 and alph2 contain the same IDs, otherwise
     0. */

  int test_alph_member(ALPHABETptr alph, id_type id);
  /* Returns 1 if id is a member of the alphabet, otherwise 0. */

  /* Network operations */

  /* If the keep_X_p argument is KEEP, the corresponding network is
     preserved unchanged. If the keep_X_p argument is DONT_KEEP, the
     network X is reclaimed or destructively modified. Most
     network operations presuppose that the arguments are
     standard networks that have not been compacted, vectorized,
     or optimized. */

  /* Unary operations. */

  NETptr lower_side_net(NETptr net, int keep_p);
  /* Extracts the lower-side projection of the net. That is, every arc
     with a pair label is relabeled with the lower side id of the
     pair. Returns the modified network. The corresponding regular
     expression operator is .l. */

  NETptr upper_side_net(NETptr net, int keep_p);
  /* Extracts the upper-side projection of the net. That is, every arc
     with a pair label is relabeled with the upper side id of the
     pair. Returns the modified network. The corresponding regular
     expression operator is the suffix .u. */

  NETptr invert_net(NETptr net, int keep_p);
  /* Relabels every arc with a pair label by the inverted pair. For
     example, and x:y arc becomes a y:x arc. Returns the modified
     network. The corresponding regular expression
     operator is the suffix .i. */

  NETptr reverse_net(NETptr net, int keep_p);
  /* Returns a network that contains the mirror image of the language
     or relation encoded by the net. The corresponding regular
     expression operator is the suffix .r. */

  NETptr contains_net(NETptr net, int keep_p);
  /* Returns a network of all paths that include at least one
     path from the input net. The corresponding regular expression
     operator is $. */

  NETptr optional_net(NETptr net, int keep_p);
  /* Makes the start state of the net final thus adding the empty
     string to language of the network if it is not already there.
     Returns the modified network. The corresponding regular
     expression operator is ( ), round parentheses around the
     expression. */

  NETptr zero_plus_net(NETptr net, int keep_p);
  /* Concatenates the net with itself any number of times. The
     resulting network accepts the empty string. Returns the
     modified network. The corresponding regular expression
     operator is the suffix *. */

  NETptr one_plus_net(NETptr net, int keep_p);
  /* Like zero_plus_net except that the result does not accept
     the empty string unless the original net does. Returns the
     modified network. The corresponding regular expression
     operator is the suffix +. */

  NETptr negate_net(NETptr net, int keep_p);
  /* The negate operation is defined only for networks that encode a
     language, that is, for networks with arity 1. The corresponding
     regular expression operator is the prefix ~. */

  NETptr other_than_net(NETptr net, int keep_p);
  /* Returns the network that contains all the single symbol
     strings except the ones in the net. The correspoding
     regular expression operator is the prefix \. */

  NETptr shuffle_net(NETptr net1, NETptr net2, int keep_net1_p,
                     int keep_net2_p);
  /*  Returns a network that accepts every string formed by shuffling
      together (interdigitating) one string from each of the input
      languages. For example, if net1 accepts the string "ab" and net2
      accepts the string "xy", the shuffle net accepts "abxy", "axby",
      "axyb", "xaby", "xayb", "xyab". If keep_p is KEEP, the
      network is not affected. If keep_p is DONT_KEEP, the network
      is reclaimed. */

  NETptr substring_net(NETptr net, int keep_p);
  /* Returns a network that accepts every substring of the strings
     in the input network. For example, if net contains "cat",
     the substring net contains "cat", "ca", "c", "at", "a", "t"
     and the empty string "". If keep_p is DONT_KEEP, the input
     network is destructively modified, if keep_p is KEEP
     the operation is done on a copy of the input net. */

  NETptr repeat_net(NETptr net, int min, int max, int keep_p);
  /* Returns a network that accepts strings that consist of at least
     min and at most max concatenations of strings in the language of
     net. If max is less than zero, there is no upper limit. If keep_p
     is DONT_KEEP, the input network is destructively modified, if
     keep_p is KEEP the operation is done on a copy of the input
     net. */

  /* Binary network operations. */

  NETptr concat_net(NETptr net1, NETptr net2, int keep_net1_p,
                    int keep_net2_p);
  /* Returns the concatenation of net1 and net2, that is, a network in
     which every path in net1 is continued with every path in net2. If
     keep_net1_p is DONT_KEEP, net1 will be destructively modified and
     returned as the result. If keep_net2_p is DONT_KEEP, net2 will be
     used up and reclaimed. The corresponding regular expression for the
     concatenation operator is empty space between symbols. */

  NETptr union_net(NETptr net1, NETptr net2, int keep_net1_p,
                   int keep_net2_p);
  /* Returns the union of the two networks, that is, a network
     containg all the paths of the two networks. If keep_net1_p is
     DONT_KEEP, net1 will be destructively modified and returned as
     the result. If keep_net2_p is DONT_KEEP, net2 will be used up and
     reclaimed. The corresponding regular expression operator is |. */

  NETptr intersect_net(NETptr net1, NETptr net2, int reclaim_net1_p,
                       int reclaim_net_p);
  /* Returns a new network containing the paths that are both in net1
     and net2. Intersection is not well-defined for transducers that
     contain epsilon symbols in symbol pairs such as a:0. If
     reclaim_net1_p or reclaim_net2_p is DONT_KEEP, the network will
     be reclaimed, otherwise it will remain. The corresponding
     regular expression operator is &. */

  NETptr minus_net(NETptr net1, NETptr net2, int keep_net1_p,
                   int keep_net2_p);
  /* Returns a network that contains all the paths in net1 that are
     not in net2. The minus operation is not well-defined for
     transducers that contain epsilon symbols. The minus operation can
     be used to produce a complement of a simple relation. For
     example, minus_net(read_regex("?:?"), read_regex("a:b"),
     DONT_KEEP) that maps any symbol to itself and to any other symbol
     except that the pair a:b is missing. The correspoding regular
     expression operator is -. */

  NETptr compose_net(NETptr upper, NETptr lower, int keep_upper_p,
                     int keep_lower_p);
  /* Returns the composition of the two networks. The corresponding
     regular expression operator is .o. */

  NETptr crossproduct_net(NETptr upper, NETptr lower, int keep_upper_p,
                          int keep_lower_p);
  /* Returns a network that pairs all the strings in the languages of
     the two networks with each other. If keep_p is DONT_KEEP the
     network is reclaimed. The corresponding regular expression
     operators are .x. (low binding preference) and : (high binding
     preference. */

  NETptr ignore_net(NETptr target, NETptr noise, int keep_target_p,
                    int keep_noise_p);
  /* Returns a network that is like the target except that every state
     of the network contains a loop that contains all the paths of the
     noise network. For example, ignore_net(read_regex("a b c"),
     symbol_net("x"), DONT_KEEP, DONT_KEEP); returns a language that
     contains the string "abc" and an infinite number of strings such
     as "axbcxb" that contain bursts of noise. The correspoding
     regular expression operator is /. */

  NETptr priority_union_net(NETptr net1, NETptr net2, int side,
                            int keep_net1_p, int keep_net2_p);
  /* Returns a network that represents the union of net1 and net2 that
     gives net1 preference over net2 on the given side (UPPER or
     LOWER).  For example, if the side is UPPER and net1 consists of
     the pair a:b and net2 consists of the pairs a:c and d:e, the
     priority union of the two consists of the pairs a:b and d:e. The
     a:c pair from net2 is discarded because net1 has another pair
     with a on the upper side. The d:e pair from net2 is included
     because net1 has no competing mapping for the upper side d. The
     corresponding regular expression operators are .p. for priority
     union on the LOWER side and .P. for UPPER priority union. */

  NETptr lenient_compose_net(NETptr upper, NETptr lower, int keep_upper_p,
                             int keep_lower_p);
  /* A function for experimenting with optimality theory (OT).
     The lenient composition of upper and lower is defined as follows:
     upper .O. lower = [[upper .o. lower] .P. upper]
     where .0. is the lenient compose operator,. .o. is ordinary
     composition and .P. is priority union.
     To make sense of this, think of upper as a transducer that maps
     each of the strings of the input language into all of its
     possible realization. In other words, upper is the composition
     of the input language with GEN. The lower network represents
     a constraint language that rules out some, maybe all of the
     outputs. The result of the lenient composition is a network that
     maps each input string to the outputs that meet the constraint
     if there are any, eliminating the outputs that violate the
     constraint. However, if none of the outputs of a given input
     meet the constraint, all of them remain. That is, lenient
     composition guarantees that every input has outputs. A set
     of ranked OT constraints can be implemented as a cascade of
     lenient compositions with the most higly ranked constraint on
     the top of the cascade. */

  NETptr close_sigma(NETptr net, ALPHABETptr new_symbols,
  		     int copy_p, int minimize_p);
  /* Error handling */

  void set_error_function(void (*fn)(const char *message,
				     const char *function_name,
                                     int code));

  void set_warning_function(void (*fn)(const char *message,
				       const char *function_name,
                                       int code));

#ifdef __cplusplus
}
#endif /* __ cplusplus */

#endif /* XFSM_API */
