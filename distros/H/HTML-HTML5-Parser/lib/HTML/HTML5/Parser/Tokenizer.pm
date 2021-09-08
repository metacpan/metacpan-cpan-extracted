package HTML::HTML5::Parser::Tokenizer; # -*- Perl -*-
## skip Test::Tabs
use strict;
use warnings;
our $VERSION='0.992';

## This module implements the tokenization phase of both HTML5 and
## XML5.  Notes like this are usually based on the latest HTML
## specification.  Since XML is different from HTML, and since XML5
## specification has not been maintained any more, there is a few
## differences from HTML's tokenization.  Such differences are marked
## by prefix "XML5:".

## Warnings that depend on the HTML/XML input stream, such as ones
## related to surrogate code positions, are not useful.
no warnings 'utf8';

## ------ Token types ------

BEGIN {
  require Exporter;
  push our @ISA, 'Exporter';

  our @EXPORT_OK = qw(
    DOCTYPE_TOKEN
    COMMENT_TOKEN
    START_TAG_TOKEN
    END_TAG_TOKEN
    END_OF_FILE_TOKEN
    CHARACTER_TOKEN
    PI_TOKEN
    ABORT_TOKEN
    END_OF_DOCTYPE_TOKEN
    ATTLIST_TOKEN
    ELEMENT_TOKEN
    GENERAL_ENTITY_TOKEN
    PARAMETER_ENTITY_TOKEN
    NOTATION_TOKEN
  );
  
  our %EXPORT_TAGS = (
    token => [qw(
      DOCTYPE_TOKEN
      COMMENT_TOKEN
      START_TAG_TOKEN
      END_TAG_TOKEN
      END_OF_FILE_TOKEN
      CHARACTER_TOKEN
      PI_TOKEN
      ABORT_TOKEN
      END_OF_DOCTYPE_TOKEN
      ATTLIST_TOKEN
      ELEMENT_TOKEN
      GENERAL_ENTITY_TOKEN
      PARAMETER_ENTITY_TOKEN
      NOTATION_TOKEN
    )],
  );
}

sub DOCTYPE_TOKEN () { 1 } ## XML5: No DOCTYPE token.
sub COMMENT_TOKEN () { 2 }
sub START_TAG_TOKEN () { 3 }
sub END_TAG_TOKEN () { 4 }
sub END_OF_FILE_TOKEN () { 5 }
sub CHARACTER_TOKEN () { 6 }
sub PI_TOKEN () { 7 } ## NOTE: XML only.
sub ABORT_TOKEN () { 8 } ## NOTE: For internal processing.
sub END_OF_DOCTYPE_TOKEN () { 9 } ## NOTE: XML only.
sub ATTLIST_TOKEN () { 10 } ## NOTE: XML only.
sub ELEMENT_TOKEN () { 11 } ## NOTE: XML only.
sub GENERAL_ENTITY_TOKEN () { 12 } ## NOTE: XML only.
sub PARAMETER_ENTITY_TOKEN () { 13 } ## NOTE: XML only.
sub NOTATION_TOKEN () { 14 } ## NOTE: XML only.

## XML5: XML5 has "empty tag token".  In this implementation, it is
## represented as a start tag token with $self->{self_closing} flag
## set to true.

## XML5: XML5 has "short end tag token".  In this implementation, it
## is represented as an end tag token with $token->{tag_name} flag set
## to an empty string.

package HTML::HTML5::Parser::TagSoupParser;

BEGIN { HTML::HTML5::Parser::Tokenizer->import (':token') }

use HTML::HTML5::Entities qw[%entity2char];

## ------ Tokenizer states ------

sub DATA_STATE () { 0 }
sub RCDATA_STATE () { 107 }
sub RAWTEXT_STATE () { 108 }
sub SCRIPT_DATA_STATE () { 109 }
sub PLAINTEXT_STATE () { 110 }
sub TAG_OPEN_STATE () { 2 }
sub RCDATA_LT_STATE () { 111 }
sub RAWTEXT_LT_STATE () { 112 }
sub SCRIPT_DATA_LT_STATE () { 113 }
sub CLOSE_TAG_OPEN_STATE () { 3 }
sub RCDATA_END_TAG_OPEN_STATE () { 114 }
sub RAWTEXT_END_TAG_OPEN_STATE () { 115 }
sub SCRIPT_DATA_END_TAG_OPEN_STATE () { 116 }
sub SCRIPT_DATA_ESCAPE_START_STATE () { 1 }
sub SCRIPT_DATA_ESCAPE_START_DASH_STATE () { 12 }
sub SCRIPT_DATA_ESCAPED_STATE () { 117 }
sub SCRIPT_DATA_ESCAPED_DASH_STATE () { 118 }
sub SCRIPT_DATA_ESCAPED_DASH_DASH_STATE () { 119 }
sub SCRIPT_DATA_ESCAPED_LT_STATE () { 120 }
sub SCRIPT_DATA_ESCAPED_END_TAG_OPEN_STATE () { 121 }
sub SCRIPT_DATA_DOUBLE_ESCAPE_START_STATE () { 122 }
sub SCRIPT_DATA_DOUBLE_ESCAPED_STATE () { 123 }
sub SCRIPT_DATA_DOUBLE_ESCAPED_DASH_STATE () { 124 }
sub SCRIPT_DATA_DOUBLE_ESCAPED_DASH_DASH_STATE () { 125 }
sub SCRIPT_DATA_DOUBLE_ESCAPED_LT_STATE () { 126 }
sub SCRIPT_DATA_DOUBLE_ESCAPE_END_STATE () { 127 }
sub TAG_NAME_STATE () { 4 }
sub BEFORE_ATTRIBUTE_NAME_STATE () { 5 }
sub ATTRIBUTE_NAME_STATE () { 6 }
sub AFTER_ATTRIBUTE_NAME_STATE () { 7 }
sub BEFORE_ATTRIBUTE_VALUE_STATE () { 8 }
sub ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE () { 9 }
sub ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE () { 10 }
sub ATTRIBUTE_VALUE_UNQUOTED_STATE () { 11 }
sub MARKUP_DECLARATION_OPEN_STATE () { 13 }
sub COMMENT_START_STATE () { 14 }
sub COMMENT_START_DASH_STATE () { 15 }
sub COMMENT_STATE () { 16 }
sub COMMENT_END_STATE () { 17 }
sub COMMENT_END_BANG_STATE () { 102 }
#sub COMMENT_END_SPACE_STATE () { 103 } ## REMOVED
sub COMMENT_END_DASH_STATE () { 18 }
sub BOGUS_COMMENT_STATE () { 19 }
sub DOCTYPE_STATE () { 20 }
sub BEFORE_DOCTYPE_NAME_STATE () { 21 }
sub DOCTYPE_NAME_STATE () { 22 }
sub AFTER_DOCTYPE_NAME_STATE () { 23 }
sub AFTER_DOCTYPE_PUBLIC_KEYWORD_STATE () { 104 }
sub BEFORE_DOCTYPE_PUBLIC_IDENTIFIER_STATE () { 24 }
sub DOCTYPE_PUBLIC_IDENTIFIER_DOUBLE_QUOTED_STATE () { 25 }
sub DOCTYPE_PUBLIC_IDENTIFIER_SINGLE_QUOTED_STATE () { 26 }
sub AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE () { 27 }
sub BEFORE_DOCTYPE_SYSTEM_IDENTIFIER_STATE () { 28 }
sub DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED_STATE () { 29 }
sub DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED_STATE () { 30 }
sub BETWEEN_DOCTYPE_PUBLIC_AND_SYSTEM_IDS_STATE () { 105 }
sub AFTER_DOCTYPE_SYSTEM_KEYWORD_STATE () { 106 }
sub AFTER_DOCTYPE_SYSTEM_IDENTIFIER_STATE () { 31 }
sub BOGUS_DOCTYPE_STATE () { 32 }
sub AFTER_ATTRIBUTE_VALUE_QUOTED_STATE () { 33 }
sub SELF_CLOSING_START_TAG_STATE () { 34 }
sub CDATA_SECTION_STATE () { 35 }
sub MD_HYPHEN_STATE () { 36 } # "markup declaration open state" in the spec
sub MD_DOCTYPE_STATE () { 37 } # "markup declaration open state" in the spec
sub MD_CDATA_STATE () { 38 } # "markup declaration open state" in the spec
#sub CDATA_RCDATA_CLOSE_TAG_STATE () { 39 } # "close tag open state" in the spec
sub CDATA_SECTION_MSE1_STATE () { 40 } # "CDATA section state" in the spec
sub CDATA_SECTION_MSE2_STATE () { 41 } # "CDATA section state" in the spec
sub PUBLIC_STATE () { 42 } # "after DOCTYPE name state" in the spec
sub SYSTEM_STATE () { 43 } # "after DOCTYPE name state" in the spec
##
## NOTE: "Entity data state", "entity in attribute value state", and
## the "consume a character reference" algorithm, are jointly
## implemented as the following six states:
sub ENTITY_STATE () { 44 }
sub ENTITY_HASH_STATE () { 45 }
sub NCR_NUM_STATE () { 46 }
sub HEXREF_X_STATE () { 47 }
sub HEXREF_HEX_STATE () { 48 }
sub ENTITY_NAME_STATE () { 49 }
##
## XML-only states
sub DATA_MSE1_STATE () { 50 }
sub DATA_MSE2_STATE () { 128 } # last
sub PI_STATE () { 51 }
sub PI_TARGET_STATE () { 52 }
sub PI_TARGET_AFTER_STATE () { 53 }
sub PI_DATA_STATE () { 54 }
sub PI_AFTER_STATE () { 55 }
sub PI_DATA_AFTER_STATE () { 56 }
sub DOCTYPE_INTERNAL_SUBSET_STATE () { 57 }
sub DOCTYPE_INTERNAL_SUBSET_AFTER_STATE () { 58 }
sub BOGUS_DOCTYPE_INTERNAL_SUBSET_AFTER_STATE () { 59 }
sub DOCTYPE_TAG_STATE () { 60 }
sub DOCTYPE_MARKUP_DECLARATION_OPEN_STATE () { 61 }
sub MD_ATTLIST_STATE () { 62 }
sub MD_E_STATE () { 63 }
sub MD_ELEMENT_STATE () { 64 }
sub MD_ENTITY_STATE () { 65 }
sub MD_NOTATION_STATE () { 66 }
sub DOCTYPE_MD_STATE () { 67 }
sub BEFORE_MD_NAME_STATE () { 68 }
sub MD_NAME_STATE () { 69 }
sub DOCTYPE_ENTITY_PARAMETER_BEFORE_STATE () { 70 }
sub DOCTYPE_ATTLIST_NAME_AFTER_STATE () { 71 }
sub DOCTYPE_ATTLIST_ATTRIBUTE_NAME_STATE () { 72 }
sub DOCTYPE_ATTLIST_ATTRIBUTE_NAME_AFTER_STATE () { 73 }
sub DOCTYPE_ATTLIST_ATTRIBUTE_TYPE_STATE () { 74 }
sub DOCTYPE_ATTLIST_ATTRIBUTE_TYPE_AFTER_STATE () { 75 }
sub BEFORE_ALLOWED_TOKEN_STATE () { 76 }
sub ALLOWED_TOKEN_STATE () { 77 }
sub AFTER_ALLOWED_TOKEN_STATE () { 78 }
sub AFTER_ALLOWED_TOKENS_STATE () { 79 }
sub BEFORE_ATTR_DEFAULT_STATE () { 80 }
sub DOCTYPE_ATTLIST_ATTRIBUTE_DECLARATION_BEFORE_STATE () { 81 }
sub DOCTYPE_ATTLIST_ATTRIBUTE_DECLARATION_STATE () { 82 }
sub DOCTYPE_ATTLIST_ATTRIBUTE_DECLARATION_AFTER_STATE () { 83 }
sub AFTER_ATTLIST_ATTR_VALUE_QUOTED_STATE () { 84 }
sub BEFORE_NDATA_STATE () { 85 }
sub NDATA_STATE () { 86 }
sub AFTER_NDATA_STATE () { 87 }
sub BEFORE_NOTATION_NAME_STATE () { 88 }
sub NOTATION_NAME_STATE () { 89 }
sub DOCTYPE_ENTITY_VALUE_DOUBLE_QUOTED_STATE () { 90 }
sub DOCTYPE_ENTITY_VALUE_SINGLE_QUOTED_STATE () { 91 }
sub ENTITY_VALUE_ENTITY_STATE () { 92 }
sub AFTER_ELEMENT_NAME_STATE () { 93 }
sub BEFORE_ELEMENT_CONTENT_STATE () { 94 }
sub CONTENT_KEYWORD_STATE () { 95 }
sub AFTER_CM_GROUP_OPEN_STATE () { 96 }
sub CM_ELEMENT_NAME_STATE () { 97 }
sub AFTER_CM_ELEMENT_NAME_STATE () { 98 }
sub AFTER_CM_GROUP_CLOSE_STATE () { 99 }
sub AFTER_MD_DEF_STATE () { 100 }
sub BOGUS_MD_STATE () { 101 }

## ------ Tree constructor state constants ------

## Whether the parsed string is in the foreign island or not affect
## how tokenization is done, unfortunately.  These are a copy of some
## of tokenization state constants.  See Whatpm::HTML for the full
## list and the descriptions for constants.

sub FOREIGN_EL () { 0b1_00000000000 }

## ------ Character reference mappings ------

my $charref_map = {
  0x00 => 0xFFFD, # REPLACEMENT CHARACTER
  0x0D => 0x000D, # CARRIAGE RETURN
  0x80 => 0x20AC,
  0x81 => 0x0081,
  0x82 => 0x201A,
  0x83 => 0x0192,
  0x84 => 0x201E,
  0x85 => 0x2026,
  0x86 => 0x2020,
  0x87 => 0x2021,
  0x88 => 0x02C6,
  0x89 => 0x2030,
  0x8A => 0x0160,
  0x8B => 0x2039,
  0x8C => 0x0152,
  0x8D => 0x008D,
  0x8E => 0x017D,
  0x8F => 0x008F,
  0x90 => 0x0090,
  0x91 => 0x2018,
  0x92 => 0x2019,
  0x93 => 0x201C,
  0x94 => 0x201D,
  0x95 => 0x2022,
  0x96 => 0x2013,
  0x97 => 0x2014,
  0x98 => 0x02DC,
  0x99 => 0x2122,
  0x9A => 0x0161,
  0x9B => 0x203A,
  0x9C => 0x0153,
  0x9D => 0x009D,
  0x9E => 0x017E,
  0x9F => 0x0178,
}; # $charref_map
$charref_map->{$_} = 0xFFFD # REPLACEMENT CHARACTER
    for 0xD800..0xDFFF;
$charref_map->{$_} = $_
    for 0x0001..0x0008, 0x000B, 0x000E..0x001F, 0x007F, 
        0xFDD0..0xFDEF,
        0xFFFE, 0xFFFF, 0x1FFFE, 0x1FFFF, 0x2FFFE, 0x2FFFF, 0x3FFFE, 0x3FFFF,
        0x4FFFE, 0x4FFFF, 0x5FFFE, 0x5FFFF, 0x6FFFE, 0x6FFFF, 0x7FFFE,
        0x7FFFF, 0x8FFFE, 0x8FFFF, 0x9FFFE, 0x9FFFF, 0xAFFFE, 0xAFFFF,
        0xBFFFE, 0xBFFFF, 0xCFFFE, 0xCFFFF, 0xDFFFE, 0xDFFFF, 0xEFFFE,
        0xEFFFF, 0xFFFFE, 0xFFFFF, 0x10FFFE, 0x10FFFF;

## ------ Special character-like constants ------

## The "EOF" pseudo-character in the HTML parsing algorithm.
sub EOF_CHAR () { -1 }

## A pseudo-character code that can never appear in the input stream.
sub NEVER_CHAR () { -2 }

## ------ The tokenizer ------

## Implementations MUST act as if state machine in the spec

sub _initialize_tokenizer ($) {
  my $self = shift;

  ## NOTE: Fields set by |new| constructor:
  #$self->{level}
  #$self->{set_nc}
  #$self->{parse_error}
  #$self->{is_xml} (if XML)

  $self->{state} = DATA_STATE; # MUST
  #$self->{kwd} = ''; # State-dependent keyword; initialized when used
  #$self->{entity__value}; # initialized when used
  #$self->{entity__match}; # initialized when used
  undef $self->{ct}; # current token
  undef $self->{ca}; # current attribute
  undef $self->{last_stag_name}; # last emitted start tag name
  #$self->{prev_state}; # initialized when used
  delete $self->{self_closing};
  $self->{char_buffer} = '';
  $self->{char_buffer_pos} = 0;
  $self->{nc} = -1; # next input character
  #$self->{next_nc}
  
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
  $self->{token} = [];
  # $self->{escape}
} # _initialize_tokenizer

## A token has:
##   ->{type} == DOCTYPE_TOKEN, START_TAG_TOKEN, END_TAG_TOKEN, COMMENT_TOKEN,
##       CHARACTER_TOKEN, END_OF_FILE_TOKEN, PI_TOKEN, or ABORT_TOKEN
##   ->{name} (DOCTYPE_TOKEN)
##   ->{tag_name} (START_TAG_TOKEN, END_TAG_TOKEN)
##   ->{target} (PI_TOKEN)
##   ->{pubid} (DOCTYPE_TOKEN)
##   ->{sysid} (DOCTYPE_TOKEN)
##   ->{quirks} == 1 or 0 (DOCTYPE_TOKEN): "force-quirks" flag
##   ->{attributes} isa HASH (START_TAG_TOKEN, END_TAG_TOKEN)
##        ->{name}
##        ->{value}
##        ->{has_reference} == 1 or 0
##        ->{index}: Index of the attribute in a tag.
##   ->{data} (COMMENT_TOKEN, CHARACTER_TOKEN, PI_TOKEN)
##   ->{has_reference} == 1 or 0 (CHARACTER_TOKEN)
##   ->{last_index} (ELEMENT_TOKEN): Next attribute's index - 1.
##   ->{has_internal_subset} = 1 or 0 (DOCTYPE_TOKEN)

## NOTE: The "self-closing flag" is hold as |$self->{self_closing}|.
##     |->{self_closing}| is used to save the value of |$self->{self_closing}|
##     while the token is pushed back to the stack.

## Emitted token MUST immediately be handled by the tree construction state.

## Before each step, UA MAY check to see if either one of the scripts in
## "list of scripts that will execute as soon as possible" or the first
## script in the "list of scripts that will execute asynchronously",
## has completed loading.  If one has, then it MUST be executed
## and removed from the list.

## TODO: Polytheistic slash SHOULD NOT be used. (Applied only to atheists.)
## (This requirement was dropped from HTML5 spec, unfortunately.)

my $is_space = {
  0x0009 => 1, # CHARACTER TABULATION (HT)
  0x000A => 1, # LINE FEED (LF)
  #0x000B => 0, # LINE TABULATION (VT)
  0x000C => 1, # FORM FEED (FF) ## XML5: Not a space character.
  0x000D => 1, # CARRIAGE RETURN (CR)
  0x0020 => 1, # SPACE (SP)
};

sub KEY_ELSE_CHAR () { 255 }
sub KEY_ULATIN_CHAR () { 254 }
sub KEY_LLATIN_CHAR () { 253 }
sub KEY_EOF_CHAR () { 252 }
sub KEY_SPACE_CHAR () { 251 }

my $Action;
my $XMLAction;
$Action->[DATA_STATE]->[0x0026] = {
  name => 'data &',
  state => ENTITY_STATE, # "entity data state" + "consume a character reference"
  state_set => {entity_add => -1, prev_state => DATA_STATE},
};
$Action->[DATA_STATE]->[0x003C] = {
  name => 'data <',
  state => TAG_OPEN_STATE,
};
$Action->[DATA_STATE]->[KEY_EOF_CHAR] = {
  name => 'data eof',
  emit => END_OF_FILE_TOKEN,
  reconsume => 1,
};
$Action->[DATA_STATE]->[0x0000] = {
  name => 'data null',
  emit => CHARACTER_TOKEN,
  error => 'NULL',
};
$Action->[DATA_STATE]->[KEY_ELSE_CHAR] = {
  name => 'data else',
  emit => CHARACTER_TOKEN,
  emit_data_read_until => qq{\x00<&},
};
  $XMLAction->[DATA_STATE]->[0x005D] = { # ]
    name => 'data ]',
    state => DATA_MSE1_STATE,
    emit => CHARACTER_TOKEN,
  };
  $XMLAction->[DATA_STATE]->[KEY_ELSE_CHAR] = {
    name => 'data else xml',
    emit => CHARACTER_TOKEN,
    emit_data_read_until => qq{\x00<&\]},
  };
$Action->[RCDATA_STATE]->[0x0026] = {
  name => 'rcdata &',
  state => ENTITY_STATE, # "entity data state" + "consume a character reference"
  state_set => {entity_add => -1, prev_state => RCDATA_STATE},
};
$Action->[RCDATA_STATE]->[0x003C] = {
  name => 'rcdata <',
  state => RCDATA_LT_STATE,
};
$Action->[RCDATA_STATE]->[KEY_EOF_CHAR] = $Action->[DATA_STATE]->[KEY_EOF_CHAR];
$Action->[RCDATA_STATE]->[0x0000] = {
  name => 'rcdata null',
  emit => CHARACTER_TOKEN,
  emit_data => "\x{FFFD}",
  error => 'NULL',
};
$Action->[RCDATA_STATE]->[KEY_ELSE_CHAR] = {
  name => 'rcdata else',
  emit => CHARACTER_TOKEN,
  emit_data_read_until => qq{\x00<&},
};
$Action->[RAWTEXT_STATE]->[0x003C] = {
  name => 'rawtext <',
  state => RAWTEXT_LT_STATE,
};
$Action->[RAWTEXT_STATE]->[KEY_EOF_CHAR] = $Action->[DATA_STATE]->[KEY_EOF_CHAR];
$Action->[RAWTEXT_STATE]->[0x0000] = $Action->[RCDATA_STATE]->[0x0000];
$Action->[RAWTEXT_STATE]->[KEY_ELSE_CHAR] = {
  name => 'rawtext else',
  emit => CHARACTER_TOKEN,
  emit_data_read_until => qq{\x00<},
};
$Action->[SCRIPT_DATA_STATE]->[0x003C] = {
  name => 'script data <',
  state => SCRIPT_DATA_LT_STATE,
};
$Action->[SCRIPT_DATA_STATE]->[KEY_EOF_CHAR] = $Action->[DATA_STATE]->[KEY_EOF_CHAR];
$Action->[SCRIPT_DATA_STATE]->[0x0000] = $Action->[RAWTEXT_STATE]->[0x0000];
$Action->[SCRIPT_DATA_STATE]->[KEY_ELSE_CHAR] = $Action->[RAWTEXT_STATE]->[KEY_ELSE_CHAR];
$Action->[PLAINTEXT_STATE]->[KEY_EOF_CHAR] = $Action->[DATA_STATE]->[KEY_EOF_CHAR];
$Action->[PLAINTEXT_STATE]->[0x0000] = $Action->[RAWTEXT_STATE]->[0x0000];
$Action->[PLAINTEXT_STATE]->[KEY_ELSE_CHAR] = {
  name => 'plaintext else',
  emit => CHARACTER_TOKEN,
  emit_data_read_until => qq{\x00},
};
# "Tag open state" is known as "tag state" in XML5.
$Action->[TAG_OPEN_STATE]->[0x0021] = {
  name => 'tag open !',
  state => MARKUP_DECLARATION_OPEN_STATE,
};
$Action->[TAG_OPEN_STATE]->[0x002F] = {
  name => 'tag open /',
  state => CLOSE_TAG_OPEN_STATE,
};
$Action->[TAG_OPEN_STATE]->[KEY_ULATIN_CHAR] = {
  name => 'tag open uc',
  ct => {
    type => START_TAG_TOKEN,
    delta => 1,
    append_tag_name => 0x0020, # UC -> lc
  },
  state => TAG_NAME_STATE,
};
  $XMLAction->[TAG_OPEN_STATE]->[KEY_ULATIN_CHAR] = {
    name => 'tag open uc xml',
    ct => {
      type => START_TAG_TOKEN,
      delta => 1,
      append_tag_name => 0x0000,
    },
    state => TAG_NAME_STATE,
  };
$Action->[TAG_OPEN_STATE]->[KEY_LLATIN_CHAR] = {
  name => 'tag open lc',
  ct => {
    type => START_TAG_TOKEN,
    delta => 1,
    append_tag_name => 0x0000,
  },
  state => TAG_NAME_STATE,
};
$Action->[TAG_OPEN_STATE]->[0x003F] = {
  name => 'tag open ?',
  state => BOGUS_COMMENT_STATE,
  error => 'pio',
  error_delta => 1,
  ct => {
    type => COMMENT_TOKEN,
  },
  reconsume => 1, ## $self->{nc} is intentionally left as is
};
  $XMLAction->[TAG_OPEN_STATE]->[0x003F] = { # ?
    name => 'tag open ? xml',
    state => PI_STATE,
  };
$Action->[TAG_OPEN_STATE]->[KEY_SPACE_CHAR] =
$Action->[TAG_OPEN_STATE]->[0x003E] = { # >
  name => 'tag open else',
  error => 'bare stago',
  error_delta => 1,
  state => DATA_STATE,
  reconsume => 1,
  emit => CHARACTER_TOKEN,
  emit_data => '<',
  emit_delta => 1,
};
$Action->[TAG_OPEN_STATE]->[KEY_ELSE_CHAR] = $Action->[TAG_OPEN_STATE]->[0x003E];
  $XMLAction->[TAG_OPEN_STATE]->[0x0000] = {
    name => 'tag open null xml',
    ct => {
      type => START_TAG_TOKEN,
      delta => 1,
      append_tag_name => 0xFFFD,
    },
    error => 'NULL',
    state => TAG_NAME_STATE,
  };
  ## XML5: "<:" has a parse error.
  $XMLAction->[TAG_OPEN_STATE]->[KEY_ELSE_CHAR] = {
    name => 'tag open else xml',
    ct => {
      type => START_TAG_TOKEN,
      delta => 1,
      append_tag_name => 0x0000,
    },
    state => TAG_NAME_STATE,
  };
$Action->[RCDATA_LT_STATE]->[0x002F] = {
  name => 'rcdata lt /',
  state => RCDATA_END_TAG_OPEN_STATE,
  buffer => {clear => 1},
};
$Action->[RAWTEXT_LT_STATE]->[0x002F] = {
  name => 'rawtext lt /',
  state => RAWTEXT_END_TAG_OPEN_STATE,
  buffer => {clear => 1},
};
$Action->[SCRIPT_DATA_LT_STATE]->[0x002F] = {
  name => 'script data lt /',
  state => SCRIPT_DATA_END_TAG_OPEN_STATE,
  buffer => {clear => 1},
};
$Action->[SCRIPT_DATA_ESCAPED_LT_STATE]->[0x002F] = {
  name => 'script data escaped lt /',
  state => SCRIPT_DATA_ESCAPED_END_TAG_OPEN_STATE,
  buffer => {clear => 1},
};
$Action->[SCRIPT_DATA_LT_STATE]->[0x0021] = {
  name => 'script data lt !',
  state => SCRIPT_DATA_ESCAPE_START_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => '<!',
};
$Action->[SCRIPT_DATA_ESCAPED_LT_STATE]->[KEY_ULATIN_CHAR] = {
  name => 'script data escaped lt uc',
  emit => CHARACTER_TOKEN,
  emit_data => '<',
  emit_data_append => 1,
  buffer => {clear => 1, append => 0x0020}, # UC -> lc
  state => SCRIPT_DATA_DOUBLE_ESCAPE_START_STATE,
};
$Action->[SCRIPT_DATA_ESCAPED_LT_STATE]->[KEY_LLATIN_CHAR] = {
  name => 'script data escaped lt lc',
  emit => CHARACTER_TOKEN,
  emit_data => '<',
  emit_data_append => 1,
  buffer => {clear => 1, append => 0x0000},
  state => SCRIPT_DATA_DOUBLE_ESCAPE_START_STATE,
};
$Action->[RCDATA_LT_STATE]->[KEY_ELSE_CHAR] = {
  name => 'rcdata lt else',
  state => RCDATA_STATE,
  reconsume => 1,
  emit => CHARACTER_TOKEN,
  emit_data => '<',
};
$Action->[RAWTEXT_LT_STATE]->[KEY_ELSE_CHAR] = {
  name => 'rawtext lt else',
  state => RAWTEXT_STATE,
  reconsume => 1,
  emit => CHARACTER_TOKEN,
  emit_data => '<',
};
$Action->[SCRIPT_DATA_LT_STATE]->[KEY_ELSE_CHAR] = {
  name => 'script data lt else',
  state => SCRIPT_DATA_STATE,
  reconsume => 1,
  emit => CHARACTER_TOKEN,
  emit_data => '<',
};
$Action->[SCRIPT_DATA_ESCAPED_LT_STATE]->[KEY_ELSE_CHAR] = {
  name => 'script data escaped lt else',
  state => SCRIPT_DATA_ESCAPED_STATE,
  reconsume => 1,
  emit => CHARACTER_TOKEN,
  emit_data => '<',
};
## XXX "End tag token" in latest HTML5 and in XML5.
$Action->[CLOSE_TAG_OPEN_STATE]->[KEY_ULATIN_CHAR] = {
  name => 'end tag open uc',
  ct => {
    type => END_TAG_TOKEN,
    delta => 2,
    append_tag_name => 0x0020, # UC -> lc
  },
  state => TAG_NAME_STATE,
};
  $XMLAction->[CLOSE_TAG_OPEN_STATE]->[KEY_ULATIN_CHAR] = {
    name => 'end tag open uc xml',
    ct => {
      type => END_TAG_TOKEN,
      delta => 2,
      append_tag_name => 0x0000,
    },
    state => TAG_NAME_STATE,
  };
$Action->[CLOSE_TAG_OPEN_STATE]->[KEY_LLATIN_CHAR] = {
  name => 'end tag open lc',
  ct => {
    type => END_TAG_TOKEN,
    delta => 2,
    append_tag_name => 0x0000,
  },
  state => TAG_NAME_STATE,
};
$Action->[CLOSE_TAG_OPEN_STATE]->[0x003E] = {
  name => 'end tag open >',
  error => 'empty end tag',
  error_delta => 2, # "<" in "</>"
  state => DATA_STATE,
};
  ## XML5: No parse error.
  
  ## NOTE: This parser raises a parse error, since it supports XML1,
  ## not XML5.
  
  ## NOTE: A short end tag token.

  $XMLAction->[CLOSE_TAG_OPEN_STATE]->[0x003E] = {
    name => 'end tag open > xml',
    error => 'empty end tag',
    error_delta => 2, # "<" in "</>"
    state => DATA_STATE,
    ct => {
      type => END_TAG_TOKEN,
      delta => 2,
    },
    emit => '',
  };
$Action->[CLOSE_TAG_OPEN_STATE]->[KEY_EOF_CHAR] = {
  name => 'end tag open eof',
  error => 'bare etago',
  state => DATA_STATE,
  reconsume => 1,
  emit => CHARACTER_TOKEN,
  emit_data => '</',
  emit_delta => 2,
};
$Action->[CLOSE_TAG_OPEN_STATE]->[KEY_SPACE_CHAR] = 
$Action->[CLOSE_TAG_OPEN_STATE]->[KEY_ELSE_CHAR] = {
  name => 'end tag open else',
  error => 'bogus end tag',
  error_delta => 2, # "<" of "</"
  state => BOGUS_COMMENT_STATE,
  ct => {
    type => COMMENT_TOKEN,
    delta => 2, # "<" of "</"
  },
  reconsume => 1,
  ## NOTE: $self->{nc} is intentionally left as is.  Although the
  ## "anything else" case of the spec not explicitly states that the
  ## next input character is to be reconsumed, it will be included to
  ## the |data| of the comment token generated from the bogus end tag,
  ## as defined in the "bogus comment state" entry.
};
  $XMLAction->[CLOSE_TAG_OPEN_STATE]->[0x0000] = {
    name => 'end tag open null xml',
    ct => {
      type => END_TAG_TOKEN,
      delta => 2,
      append_tag_name => 0xFFFD,
    },
    error => 'NULL',
    state => TAG_NAME_STATE, ## XML5: "end tag name state".
  };
  ## XML5: "</:" is a parse error.
  $XMLAction->[CLOSE_TAG_OPEN_STATE]->[KEY_ELSE_CHAR] = {
    name => 'end tag open else xml',
    ct => {
      type => END_TAG_TOKEN,
      delta => 2,
      append_tag_name => 0x0000,
    },
    state => TAG_NAME_STATE, ## XML5: "end tag name state".
  };
      ## This switch-case implements "tag name state", "RCDATA end tag
      ## name state", "RAWTEXT end tag name state", and "script data
      ## end tag name state" jointly with the implementation of
      ## "RCDATA end tag open state" and so on.
$Action->[TAG_NAME_STATE]->[KEY_SPACE_CHAR] = {
  name => 'tag name sp',
  state => BEFORE_ATTRIBUTE_NAME_STATE,
};
$Action->[TAG_NAME_STATE]->[0x003E] = {
  name => 'tag name >',
  state => DATA_STATE,
  emit => '',
};
$Action->[TAG_NAME_STATE]->[KEY_ULATIN_CHAR] = {
  name => 'tag name uc',
  ct => {
    append_tag_name => 0x0020, # UC -> lc
  },
};
$XMLAction->[TAG_NAME_STATE]->[KEY_ULATIN_CHAR] = {
  name => 'tag name uc xml',
  ct => {
    append_tag_name => 0x0000,
  },
};
$Action->[TAG_NAME_STATE]->[KEY_EOF_CHAR] = {
  name => 'tag name eof',
  error => 'unclosed tag',
  state => DATA_STATE,
  reconsume => 1,
};
$Action->[TAG_NAME_STATE]->[0x002F] = {
  name => 'tag name /',
  state => SELF_CLOSING_START_TAG_STATE,
};
$Action->[TAG_NAME_STATE]->[0x0000] = {
  name => 'tag name null',
  ct => {
    append_tag_name => 0xFFFD,
  },
  error => 'NULL',
};
$Action->[TAG_NAME_STATE]->[KEY_ELSE_CHAR] = {
  name => 'tag name else',
  ct => {
    append_tag_name => 0x0000,
  },
};
$Action->[SCRIPT_DATA_ESCAPE_START_STATE]->[0x002D] = {
  name => 'script data escape start -',
  state => SCRIPT_DATA_ESCAPE_START_DASH_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => '-',
};
$Action->[SCRIPT_DATA_ESCAPE_START_DASH_STATE]->[0x002D] = {
  name => 'script data escape start dash -',
  state => SCRIPT_DATA_ESCAPED_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => '-',
};
$Action->[SCRIPT_DATA_ESCAPE_START_STATE]->[KEY_ELSE_CHAR] = {
  name => 'script data escape start else',
  state => SCRIPT_DATA_STATE,
  reconsume => 1,
};
$Action->[SCRIPT_DATA_ESCAPE_START_DASH_STATE]->[KEY_ELSE_CHAR] = $Action->[SCRIPT_DATA_ESCAPE_START_STATE]->[KEY_ELSE_CHAR];
$Action->[SCRIPT_DATA_ESCAPED_STATE]->[0x002D] = {
  name => 'script data escaped -',
  state => SCRIPT_DATA_ESCAPED_DASH_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => '-',
};
$Action->[SCRIPT_DATA_ESCAPED_DASH_STATE]->[0x002D] = {
  name => 'script data escaped dash -',
  state => SCRIPT_DATA_ESCAPED_DASH_DASH_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => '-',
};
$Action->[SCRIPT_DATA_ESCAPED_DASH_DASH_STATE]->[0x002D] = {
  name => 'script data escaped dash dash -',
  emit => CHARACTER_TOKEN,
  emit_data => '-',
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_STATE]->[0x002D] = {
  name => 'script data double escaped -',
  state => SCRIPT_DATA_DOUBLE_ESCAPED_DASH_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => '-',
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_DASH_STATE]->[0x002D] = {
  name => 'script data double escaped -',
  state => SCRIPT_DATA_DOUBLE_ESCAPED_DASH_DASH_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => '-',
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_DASH_DASH_STATE]->[0x002D] = {
  name => 'script data double escaped dash dash -',
  emit => CHARACTER_TOKEN,
  emit_data => '-',
};
$Action->[SCRIPT_DATA_ESCAPED_STATE]->[0x003C] = {
  name => 'script data escaped <',
  state => SCRIPT_DATA_ESCAPED_LT_STATE,
};
$Action->[SCRIPT_DATA_ESCAPED_DASH_STATE]->[0x003C] = {
  name => 'script data escaped dash <',
  state => SCRIPT_DATA_ESCAPED_LT_STATE,
};
$Action->[SCRIPT_DATA_ESCAPED_DASH_DASH_STATE]->[0x003C] = {
  name => 'script data escaped dash dash <',
  state => SCRIPT_DATA_ESCAPED_LT_STATE,
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_STATE]->[0x003C] = {
  name => 'script data double escaped <',
  state => SCRIPT_DATA_DOUBLE_ESCAPED_LT_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => '<',
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_DASH_STATE]->[0x003C] = {
  name => 'script data double escaped dash <',
  state => SCRIPT_DATA_DOUBLE_ESCAPED_LT_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => '<',
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_DASH_DASH_STATE]->[0x003C] = {
  name => 'script data double escaped dash dash <',
  state => SCRIPT_DATA_DOUBLE_ESCAPED_LT_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => '<',
};
$Action->[SCRIPT_DATA_ESCAPED_DASH_DASH_STATE]->[0x003E] = {
  name => 'script data escaped dash dash >',
  state => SCRIPT_DATA_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => '>',
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_DASH_DASH_STATE]->[0x003E] = $Action->[SCRIPT_DATA_ESCAPED_DASH_DASH_STATE]->[0x003E];
$Action->[SCRIPT_DATA_ESCAPED_STATE]->[KEY_EOF_CHAR] =
$Action->[SCRIPT_DATA_ESCAPED_DASH_STATE]->[KEY_EOF_CHAR] =
$Action->[SCRIPT_DATA_ESCAPED_DASH_DASH_STATE]->[KEY_EOF_CHAR] = 
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_STATE]->[KEY_EOF_CHAR] =
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_DASH_STATE]->[KEY_EOF_CHAR] =
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_DASH_DASH_STATE]->[KEY_EOF_CHAR] = {
  name => 'script data escaped eof',
  error => 'eof in escaped script data', # XXXdocumentation
  state => DATA_STATE,
  reconsume => 1,
};
$Action->[SCRIPT_DATA_ESCAPED_STATE]->[0x0000] =
$Action->[SCRIPT_DATA_ESCAPED_DASH_STATE]->[0x0000] =
$Action->[SCRIPT_DATA_ESCAPED_DASH_DASH_STATE]->[0x0000] =
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_STATE]->[0x0000] =
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_DASH_STATE]->[0x0000] =
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_DASH_DASH_STATE]->[0x0000] = {
  name => 'script data escaped null',
  emit => CHARACTER_TOKEN,
  emit_data => "\x{FFFD}",
  error => 'NULL',
  state => SCRIPT_DATA_ESCAPED_STATE,
};
$Action->[SCRIPT_DATA_ESCAPED_STATE]->[KEY_ELSE_CHAR] = {
  name => 'script data escaped else',
  emit => CHARACTER_TOKEN,
  state => SCRIPT_DATA_ESCAPED_STATE,
};
$Action->[SCRIPT_DATA_ESCAPED_DASH_STATE]->[KEY_ELSE_CHAR] = {
  name => 'script data escaped dash else',
  emit => CHARACTER_TOKEN,
  state => SCRIPT_DATA_ESCAPED_STATE,
};
$Action->[SCRIPT_DATA_ESCAPED_DASH_DASH_STATE]->[KEY_ELSE_CHAR] = {
  name => 'script data escaped dash dash else',
  emit => CHARACTER_TOKEN,
  state => SCRIPT_DATA_ESCAPED_STATE,
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_STATE]->[KEY_ELSE_CHAR] = {
  name => 'script data double escaped else',
  emit => CHARACTER_TOKEN,
  state => SCRIPT_DATA_DOUBLE_ESCAPED_STATE,
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_DASH_STATE]->[KEY_ELSE_CHAR] = {
  name => 'script data double escaped dash else',
  emit => CHARACTER_TOKEN,
  state => SCRIPT_DATA_DOUBLE_ESCAPED_STATE,
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_DASH_DASH_STATE]->[KEY_ELSE_CHAR] = {
  name => 'script data double escaped dash dash else',
  emit => CHARACTER_TOKEN,
  state => SCRIPT_DATA_DOUBLE_ESCAPED_STATE,
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPE_START_STATE]->[KEY_SPACE_CHAR] =
$Action->[SCRIPT_DATA_DOUBLE_ESCAPE_END_STATE]->[KEY_SPACE_CHAR] =
$Action->[SCRIPT_DATA_DOUBLE_ESCAPE_START_STATE]->[0x003E] =
$Action->[SCRIPT_DATA_DOUBLE_ESCAPE_END_STATE]->[0x003E] =
$Action->[SCRIPT_DATA_DOUBLE_ESCAPE_START_STATE]->[0x002F] =
$Action->[SCRIPT_DATA_DOUBLE_ESCAPE_END_STATE]->[0x002F] = {
  name => 'script data double escape start sp>/',
  skip => 1,
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPE_START_STATE]->[KEY_ULATIN_CHAR] =
$Action->[SCRIPT_DATA_DOUBLE_ESCAPE_END_STATE]->[KEY_ULATIN_CHAR] = {
  name => 'script data double escape start uc',
  emit => CHARACTER_TOKEN,
  buffer => {append => 0x0020}, # UC -> lc
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPE_START_STATE]->[KEY_LLATIN_CHAR] =
$Action->[SCRIPT_DATA_DOUBLE_ESCAPE_END_STATE]->[KEY_LLATIN_CHAR] = {
  name => 'script data double escape start lc',
  emit => CHARACTER_TOKEN,
  buffer => {append => 0x0000},
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPE_START_STATE]->[KEY_ELSE_CHAR] = {
  name => 'script data double escape start else',
  state => SCRIPT_DATA_ESCAPED_STATE,
  reconsume => 1,
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPE_END_STATE]->[KEY_ELSE_CHAR] = {
  name => 'script data double escape end else',
  state => SCRIPT_DATA_DOUBLE_ESCAPED_STATE,
  reconsume => 1,
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_LT_STATE]->[0x002F] = {
  name => 'script data double escaped lt /',
  buffer => {clear => 1},
  state => SCRIPT_DATA_DOUBLE_ESCAPE_END_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => '/',
};
$Action->[SCRIPT_DATA_DOUBLE_ESCAPED_LT_STATE]->[KEY_ELSE_CHAR] = {
  name => 'script data double escaped lt else',
  state => SCRIPT_DATA_DOUBLE_ESCAPED_STATE,
  reconsume => 1,
};
      ## XML5: Part of the "data state".
$Action->[DATA_MSE1_STATE]->[0x005D] = {
  name => 'data mse1 ]',
  state => DATA_MSE2_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => ']',
};
$Action->[DATA_MSE1_STATE]->[KEY_ELSE_CHAR] = {
  name => 'data mse1 else',
  state => DATA_STATE,
  reconsume => 1,
};
$Action->[DATA_MSE2_STATE]->[0x003E] = {
  name => 'data mse2 >',
  error => 'unmatched mse', # XML5: Not a parse error. # XXXdocumentation
  error_delta => 2,
  state => DATA_STATE,
  emit => CHARACTER_TOKEN,
  emit_data => '>',
};
$Action->[DATA_MSE2_STATE]->[0x005D] = {
  name => 'data mse2 ]',
  emit => CHARACTER_TOKEN,
  emit_data => ']',
};
$Action->[DATA_MSE2_STATE]->[KEY_ELSE_CHAR] = {
  name => 'data mse2 else',
  state => DATA_STATE,
  reconsume => 1,
};
      ## XML5: "Tag attribute name before state".
$Action->[BEFORE_ATTRIBUTE_NAME_STATE]->[KEY_SPACE_CHAR] = {
  name => 'before attr name sp',
};
$Action->[BEFORE_ATTRIBUTE_NAME_STATE]->[0x003E] = {
  name => 'before attr name >',
  emit => '',
  state => DATA_STATE,
};
$Action->[BEFORE_ATTRIBUTE_NAME_STATE]->[KEY_ULATIN_CHAR] = {
  name => 'before attr name uc',
  ca => {
    set_name => 0x0020, # UC -> lc
  },
  state => ATTRIBUTE_NAME_STATE,
};
$XMLAction->[BEFORE_ATTRIBUTE_NAME_STATE]->[KEY_ULATIN_CHAR] = {
  name => 'before attr name uc xml',
  ca => {
    set_name => 0x0000,
  },
  state => ATTRIBUTE_NAME_STATE,
};
$Action->[BEFORE_ATTRIBUTE_NAME_STATE]->[0x002F] = {
  name => 'before attr name /',
  state => SELF_CLOSING_START_TAG_STATE,
};
$Action->[BEFORE_ATTRIBUTE_NAME_STATE]->[KEY_EOF_CHAR] = {
  name => 'before attr name eof',
  error => 'unclosed tag',
  state => DATA_STATE,
};
$Action->[BEFORE_ATTRIBUTE_NAME_STATE]->[0x0022] = 
$Action->[BEFORE_ATTRIBUTE_NAME_STATE]->[0x0027] = 
$Action->[BEFORE_ATTRIBUTE_NAME_STATE]->[0x003C] = 
$Action->[BEFORE_ATTRIBUTE_NAME_STATE]->[0x003D] = {
  name => q[before attr name "'<=],
  error => 'bad attribute name', ## XML5: Not a parse error.
  ca => {set_name => 0x0000},
  state => ATTRIBUTE_NAME_STATE,
};
$Action->[BEFORE_ATTRIBUTE_NAME_STATE]->[0x0000] = {
  name => 'before attr name null',
  ca => {set_name => 0xFFFD},
  error => 'NULL',
  state => ATTRIBUTE_NAME_STATE,
};
          ## XML5: ":" raises a parse error and is ignored.
$Action->[BEFORE_ATTRIBUTE_NAME_STATE]->[KEY_ELSE_CHAR] = {
  name => 'before attr name else',
  ca => {set_name => 0x0000},
  state => ATTRIBUTE_NAME_STATE,
};

      ## XML5: "Tag attribute name state".
$Action->[ATTRIBUTE_NAME_STATE]->[KEY_SPACE_CHAR] = {
  name => 'attr name sp',
  ca => {leave => 1},
  state => AFTER_ATTRIBUTE_NAME_STATE,
};
$Action->[ATTRIBUTE_NAME_STATE]->[0x003D] = {
  name => 'attr name =',
  ca => {leave => 1},
  state => BEFORE_ATTRIBUTE_VALUE_STATE,
};
$Action->[ATTRIBUTE_NAME_STATE]->[0x003E] = {
  name => 'attr name >',
  ca => {leave => 1},
  emit => '',
  state => DATA_STATE,
};
$XMLAction->[ATTRIBUTE_NAME_STATE]->[0x003E] = {
  name => 'attr name > xml',
  error => 'no attr value', ## XML5: Not a parse error. # XXXdocumentation
  ca => {leave => 1},
  emit => '',
  state => DATA_STATE,
};
$Action->[ATTRIBUTE_NAME_STATE]->[KEY_ULATIN_CHAR] = {
  name => 'attr name uc',
  ca => {name => 0x0020}, # UC -> lc
};
$XMLAction->[ATTRIBUTE_NAME_STATE]->[KEY_ULATIN_CHAR] = {
  name => 'attr name uc',
  ca => {name => 0x0000},
};
$Action->[ATTRIBUTE_NAME_STATE]->[0x002F] = {
  name => 'attr name /',
  ca => {leave => 1},
  state => SELF_CLOSING_START_TAG_STATE,
};
$XMLAction->[ATTRIBUTE_NAME_STATE]->[0x002F] = {
  name => 'attr name / xml',
  error => 'no attr value', ## XML5: Not a parse error. # XXXdocumentation
  ca => {leave => 1},
  state => SELF_CLOSING_START_TAG_STATE,
};
$Action->[ATTRIBUTE_NAME_STATE]->[KEY_EOF_CHAR] = {
  name => 'attr name eof',
  error => 'unclosed tag',
  ca => {leave => 1},
  state => DATA_STATE,
  reconsume => 1,
};
$Action->[ATTRIBUTE_NAME_STATE]->[0x0022] =
$Action->[ATTRIBUTE_NAME_STATE]->[0x0027] =
$Action->[ATTRIBUTE_NAME_STATE]->[0x003C] = {
  name => q[attr name "'<],
  error => 'bad attribute name', ## XML5: Not a parse error.
  ca => {name => 0x0000},
};
$Action->[ATTRIBUTE_NAME_STATE]->[0x0000] = {
  name => 'attr name null',
  ca => {name => 0xFFFD},
  error => 'NULL',
};
$Action->[ATTRIBUTE_NAME_STATE]->[KEY_ELSE_CHAR] = {
  name => 'attr name else',
  ca => {name => 0x0000},
};
      ## XML5: "Tag attribute name after state".
$Action->[AFTER_ATTRIBUTE_NAME_STATE]->[KEY_SPACE_CHAR] = {
  name => 'after attr name sp',
};
$Action->[AFTER_ATTRIBUTE_NAME_STATE]->[0x003D] = {
  name => 'after attr name =',
  state => BEFORE_ATTRIBUTE_VALUE_STATE,
};
$Action->[AFTER_ATTRIBUTE_NAME_STATE]->[0x003E] = {
  name => 'after attr name >',
  emit => '',
  state => DATA_STATE,
};
$XMLAction->[AFTER_ATTRIBUTE_NAME_STATE]->[0x003E] = {
  name => 'after attr name > xml',
  error => 'no attr value', ## XML5: Not a parse error. # XXXdocumentation
  emit => '',
  state => DATA_STATE,
};
$Action->[AFTER_ATTRIBUTE_NAME_STATE]->[KEY_ULATIN_CHAR] = {
  name => 'after attr name uc',
  ca => {set_name => 0x0020}, # UC -> lc
  state => ATTRIBUTE_NAME_STATE,
};
$XMLAction->[AFTER_ATTRIBUTE_NAME_STATE]->[KEY_ULATIN_CHAR] = {
  name => 'after attr name uc xml',
  ca => {set_name => 0x0000},
  state => ATTRIBUTE_NAME_STATE,
};
$Action->[AFTER_ATTRIBUTE_NAME_STATE]->[0x002F] = {
  name => 'after attr name /',
  state => SELF_CLOSING_START_TAG_STATE,
};
$XMLAction->[AFTER_ATTRIBUTE_NAME_STATE]->[0x002F] = {
  name => 'after attr name / xml',
  error => 'no attr value', ## XML5: Not a parse error. # XXXdocumentation
  state => SELF_CLOSING_START_TAG_STATE,
};
$Action->[AFTER_ATTRIBUTE_NAME_STATE]->[KEY_EOF_CHAR] = {
  name => 'after attr name eof',
  error => 'unclosed tag',
  state => DATA_STATE,
  reconsume => 1,
};
$Action->[AFTER_ATTRIBUTE_NAME_STATE]->[0x0022] =
$Action->[AFTER_ATTRIBUTE_NAME_STATE]->[0x0027] =
$Action->[AFTER_ATTRIBUTE_NAME_STATE]->[0x003C] = {
  name => q[after attr name "'<],
  error => 'bad attribute name', ## XML5: Not a parse error.
  #error2(xml) => 'no attr value', ## XML5: Not a parse error.
  ca => {set_name => 0x0000},
  state => ATTRIBUTE_NAME_STATE,
};
$Action->[AFTER_ATTRIBUTE_NAME_STATE]->[0x0000] = {
  name => q[after attr name else],
  ca => {set_name => 0xFFFD},
  error => 'NULL',
  #error2(xml) => 'no attr value', ## XML5: Not a parse error.
  state => ATTRIBUTE_NAME_STATE,
};
$Action->[AFTER_ATTRIBUTE_NAME_STATE]->[KEY_ELSE_CHAR] = {
  name => q[after attr name else],
  ca => {set_name => 0x0000},
  state => ATTRIBUTE_NAME_STATE,
};
$XMLAction->[AFTER_ATTRIBUTE_NAME_STATE]->[KEY_ELSE_CHAR] = {
  name => q[after attr name else],
  error => 'no attr value', ## XML5: Not a parse error.
  ca => {set_name => 0x0000},
  state => ATTRIBUTE_NAME_STATE,
};
      ## XML5: "Tag attribute value before state".
$Action->[BEFORE_ATTRIBUTE_VALUE_STATE]->[KEY_SPACE_CHAR] = {
  name => 'before attr value sp',
};
$Action->[BEFORE_ATTRIBUTE_VALUE_STATE]->[0x0022] = {
  name => 'before attr value "',
  state => ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE,
};
$XMLAction->[BEFORE_ATTRIBUTE_VALUE_STATE]->[0x0026] = {
  name => 'before attr value &',
  error => 'unquoted attr value', ## XML5: Not a parse error.
  state => ATTRIBUTE_VALUE_UNQUOTED_STATE,
  reconsume => 1,
};
$Action->[BEFORE_ATTRIBUTE_VALUE_STATE]->[0x0026] = {
  name => 'before attr value &',
  state => ATTRIBUTE_VALUE_UNQUOTED_STATE,
  reconsume => 1,
};
$Action->[BEFORE_ATTRIBUTE_VALUE_STATE]->[0x0027] = {
  name => "before attr value '",
  state => ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE,
};
$Action->[BEFORE_ATTRIBUTE_VALUE_STATE]->[0x003E] = {
  name => 'before attr value >',
  error => 'empty unquoted attribute value',
  emit => '',
  state => DATA_STATE,
};
$Action->[BEFORE_ATTRIBUTE_VALUE_STATE]->[KEY_EOF_CHAR] = {
  name => 'before attr value eof',
  error => 'unclosed tag',
  state => DATA_STATE,
};
$Action->[BEFORE_ATTRIBUTE_VALUE_STATE]->[0x003C] =
$Action->[BEFORE_ATTRIBUTE_VALUE_STATE]->[0x003D] =
$Action->[BEFORE_ATTRIBUTE_VALUE_STATE]->[0x0060] = {
  name => 'before attr value <=`',
  error => 'bad attribute value', ## XML5: Not a parse error.
  #error2(xml) => 'unquoted attr value', ## XML5: Not a parse error.
  ca => {value => 1},
  state => ATTRIBUTE_VALUE_UNQUOTED_STATE,
};
$Action->[BEFORE_ATTRIBUTE_VALUE_STATE]->[0x0000] = {
  name => 'before attr value null',
  ca => {value => "\x{FFFD}"},
  error => 'NULL',
  #error2(xml) => 'unquoted attr value', ## XML5: Not a parse error.
  state => ATTRIBUTE_VALUE_UNQUOTED_STATE,
};
$XMLAction->[BEFORE_ATTRIBUTE_VALUE_STATE]->[KEY_ELSE_CHAR] = {
  name => 'before attr value else xml',
  error => 'unquoted attr value', ## XML5: Not a parse error. # XXXdocumentation
  ca => {value => 1},
  state => ATTRIBUTE_VALUE_UNQUOTED_STATE,
};
$Action->[BEFORE_ATTRIBUTE_VALUE_STATE]->[KEY_ELSE_CHAR] = {
  name => 'before attr value else',
  ca => {value => 1},
  state => ATTRIBUTE_VALUE_UNQUOTED_STATE,
};

$Action->[AFTER_ATTRIBUTE_VALUE_QUOTED_STATE]->[KEY_SPACE_CHAR] = {
  name => 'after attr value quoted sp',
  state => BEFORE_ATTRIBUTE_NAME_STATE,
};
$Action->[AFTER_ATTRIBUTE_VALUE_QUOTED_STATE]->[0x003E] = {
  name => 'after attr value quoted >',
  emit => '',
  state => DATA_STATE,
};
$Action->[AFTER_ATTRIBUTE_VALUE_QUOTED_STATE]->[0x002F] = {
  name => 'after attr value quoted /',
  state => SELF_CLOSING_START_TAG_STATE,
};
$Action->[AFTER_ATTRIBUTE_VALUE_QUOTED_STATE]->[KEY_EOF_CHAR] = {
  name => 'after attr value quoted eof',
  error => 'unclosed tag',
  state => DATA_STATE,
  reconsume => 1,
};
$Action->[AFTER_ATTRIBUTE_VALUE_QUOTED_STATE]->[KEY_ELSE_CHAR] = {
  name => 'after attr value quoted else',
  error => 'no space between attributes',
  state => BEFORE_ATTRIBUTE_NAME_STATE,
  reconsume => 1,
};
$Action->[SELF_CLOSING_START_TAG_STATE]->[0x003E] = {
  name => 'self closing start tag >',
  skip => 1,
};
$Action->[SELF_CLOSING_START_TAG_STATE]->[KEY_EOF_CHAR] = {
  name => 'self closing start tag eof',
  error => 'unclosed tag',
  state => DATA_STATE, ## XML5: "Tag attribute name before state".
  reconsume => 1,
};
$Action->[SELF_CLOSING_START_TAG_STATE]->[KEY_ELSE_CHAR] = {
  name => 'self closing start tag else',
  error => 'nestc', # XXX This error type is wrong.
  state => BEFORE_ATTRIBUTE_NAME_STATE,
  reconsume => 1,
};
$Action->[MD_HYPHEN_STATE]->[0x002D] = {
  name => 'md hyphen -',
  ct => {type => COMMENT_TOKEN, data => '', delta => 3},
  state => COMMENT_START_STATE, ## XML5: "comment state".
};
$Action->[MD_HYPHEN_STATE]->[KEY_ELSE_CHAR] = {
  name => 'md hyphen else',
  error => 'bogus comment',
  error_delta => 3,
  state => BOGUS_COMMENT_STATE,
  reconsume => 1,
  ct => {type => COMMENT_TOKEN, data => '-', delta => 3},
};

my $c_to_key = [];
$c_to_key->[255] = KEY_EOF_CHAR; # EOF_CHAR
$c_to_key->[$_] = $_ for 0x0000..0x007F;
$c_to_key->[$_] = KEY_SPACE_CHAR for keys %$is_space;
$c_to_key->[$_] = KEY_ULATIN_CHAR for 0x0041..0x005A;
$c_to_key->[$_] = KEY_LLATIN_CHAR for 0x0061..0x007A;

sub _get_next_token ($) {
  my $self = shift;

  if ($self->{self_closing}) {
    ## NOTE: The |$self->{self_closing}| flag can never be set to
    ## tokens except for start tag tokens.  A start tag token is
    ## always set to |$self->{ct}| before it is emitted.
    $self->{parse_error}->(level => $self->{level}->{must}, type => 'nestc', token => $self->{ct});
    delete $self->{self_closing};
  }

  if (@{$self->{token}}) {
    $self->{self_closing} = $self->{token}->[0]->{self_closing};
    return shift @{$self->{token}};
  }

  A: {
    my $nc = $self->{nc};
    my $state = $self->{state};

    

    my $c = $nc > 0x007F ? KEY_ELSE_CHAR : $c_to_key->[$nc];
    my $action = $Action->[$state]->[$c] || $Action->[$state]->[KEY_ELSE_CHAR];
    if ($self->{is_xml}) {
      $action = $XMLAction->[$state]->[$c]
          || $Action->[$state]->[$c]
          || $XMLAction->[$state]->[KEY_ELSE_CHAR]
          || $Action->[$state]->[KEY_ELSE_CHAR];
    }

    if ($action and not $action->{skip}) {
      

      if (defined $action->{error}) {
        if ($action->{error_delta}) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => $action->{error},
                          line => $self->{line_prev},
                          column => $self->{column_prev} - $action->{error_delta} + 1);
        } else {
          $self->{parse_error}->(level => $self->{level}->{must}, type => $action->{error});
        }
      }

      if (defined $action->{state}) {
        $self->{state} = $action->{state};
        
        if ($action->{state_set}) {
          for (keys %{$action->{state_set}}) {
            $self->{$_} = $action->{state_set}->{$_};
          }
        }
      }

      if (my $act = $action->{ct}) {
        if (defined $act->{type}) {
          $self->{ct} = {type => $act->{type},
                         tag_name => '', data => $act->{data}};
          if ($act->{delta}) {
            $self->{ct}->{line} = $self->{line_prev};
            $self->{ct}->{column} = $self->{column_prev} - $act->{delta} + 1;
          } else {
            $self->{ct}->{line} = $self->{line};
            $self->{ct}->{column} = $self->{column};
          }
        }
        
        if (defined $act->{append_tag_name}) {
          $self->{ct}->{tag_name} .= chr ($nc + $act->{append_tag_name});
        }
      }
      
      if (my $aca = $action->{ca}) {
        if ($aca->{value}) {
          $self->{ca}->{value} .= $aca->{value} ne '1' ? $aca->{value} : chr $nc;
        } elsif (defined $aca->{name}) {
          $self->{ca}->{name} .= chr ($nc + $aca->{name});
        } elsif (defined $aca->{set_name}) {
          $self->{ca} = {
            name => chr ($nc + $aca->{set_name}),
            value => '',
            line => $self->{line}, column => $self->{column},
          };
        } elsif ($aca->{leave}) {
          if (exists $self->{ct}->{attributes}->{$self->{ca}->{name}}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'duplicate attribute', text => $self->{ca}->{name}, line => $self->{ca}->{line}, column => $self->{ca}->{column});
            ## Discard $self->{ca}.
          } else {
            
            $self->{ct}->{attributes}->{$self->{ca}->{name}} = $self->{ca};
            $self->{ca}->{index} = ++$self->{ct}->{last_index};
          }
        }
      }

      if (defined $action->{buffer}) {
        $self->{kwd} = '' if $action->{buffer}->{clear};
        $self->{kwd} .= chr ($nc + $action->{buffer}->{append})
            if defined $action->{buffer}->{append};

        
      }

      if (defined $action->{emit}) {
        if ($action->{emit} eq '') {
          if ($self->{ct}->{type} == START_TAG_TOKEN) {
            
            $self->{last_stag_name} = $self->{ct}->{tag_name};
          } elsif ($self->{ct}->{type} == END_TAG_TOKEN) {
            if ($self->{ct}->{attributes}) {
              
              $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
            } else {
              
            }
          } else {
            die "$0: $self->{ct}->{type}: Unknown token type";
          }
          
          if ($action->{reconsume}) {
            #
          } else {
            
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
          }
          return  ($self->{ct});
        } else {
          my $token = {type => $action->{emit}};
          if (defined $action->{emit_data}) {
            $token->{data} = $action->{emit_data};
            if ($action->{emit_data_append}) {
              $token->{data} .= chr $nc;
            }
          } elsif ($action->{emit} == CHARACTER_TOKEN) {
            $token->{data} .= chr $nc;
          }
          if ($action->{emit_delta}) {
            $token->{line} = $self->{line_prev};
            $token->{column} = $self->{column_prev} - $action->{emit_delta} + 1;
          } else {
            $token->{line} = $self->{line};
            $token->{column} = $self->{column};
          }
          if (defined $action->{emit_data_read_until}) {
            $self->{read_until}->($token->{data},
                                  $action->{emit_data_read_until},
                                  length $token->{data});
          }
          
          if ($action->{reconsume}) {
            #
          } else {
            
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
          }
          return  ($token);
        }
      } else {
        if ($action->{reconsume}) {
          #
        } else {
          
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        }
      }

      redo A;
    }

    if ({
      (RCDATA_END_TAG_OPEN_STATE) => 1,
      (RAWTEXT_END_TAG_OPEN_STATE) => 1,
      (SCRIPT_DATA_END_TAG_OPEN_STATE) => 1,
      (SCRIPT_DATA_ESCAPED_END_TAG_OPEN_STATE) => 1,
    }->{$state}) {
      ## This switch-case implements "RCDATA end tag open state",
      ## "RAWTEXT end tag open state", "script data end tag open
      ## state", "RCDATA end tag name state", "RAWTEXT end tag name
      ## state", and "script end tag name state" jointly with the
      ## implementation of the "tag name" state.

      my ($l, $c) = ($self->{line_prev}, $self->{column_prev} - 1); # "<"of"</"

      if (defined $self->{last_stag_name}) {
        #
      } else {
        ## No start tag token has ever been emitted
        ## NOTE: See <http://krijnhoetmer.nl/irc-logs/whatwg/20070626#l-564>.
        
        $self->{state} = {
          (RCDATA_END_TAG_OPEN_STATE) => RCDATA_STATE,
          (RAWTEXT_END_TAG_OPEN_STATE) => RAWTEXT_STATE,
          (SCRIPT_DATA_END_TAG_OPEN_STATE) => SCRIPT_DATA_STATE,
          (SCRIPT_DATA_ESCAPED_END_TAG_OPEN_STATE)
              => SCRIPT_DATA_ESCAPED_STATE,
        }->{$state} or die "${state}'s next state not found";
        ## Reconsume.
        return  ({type => CHARACTER_TOKEN, data => '</',
                  line => $l, column => $c});
        redo A;
      }

      my $ch = substr $self->{last_stag_name}, length $self->{kwd}, 1;
      if (length $ch) {
        my $CH = $ch;
        $ch =~ tr/a-z/A-Z/;
        my $nch = chr $nc;
        if ($nch eq $ch or $nch eq $CH) {
          
          ## Stay in the state.
          $self->{kwd} .= $nch;
          
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
          redo A;
        } else {
          
          $self->{state} = {
            (RCDATA_END_TAG_OPEN_STATE) => RCDATA_STATE,
            (RAWTEXT_END_TAG_OPEN_STATE) => RAWTEXT_STATE,
            (SCRIPT_DATA_END_TAG_OPEN_STATE) => SCRIPT_DATA_STATE,
            (SCRIPT_DATA_ESCAPED_END_TAG_OPEN_STATE)
                => SCRIPT_DATA_ESCAPED_STATE,
          }->{$state} or die "${state}'s next state not found";
          ## Reconsume.
          return  ({type => CHARACTER_TOKEN,
                    data => '</' . $self->{kwd},
                    line => $self->{line_prev},
                    column => $self->{column_prev} - 1 - length $self->{kwd},
                   });
          redo A;
        }
      } else { # after "</{tag-name}"
        unless ($is_space->{$nc} or
	        {
                 0x003E => 1, # >
                 0x002F => 1, # /
                }->{$nc}) {
          
          ## Reconsume.
          $self->{state} = {
            (RCDATA_END_TAG_OPEN_STATE) => RCDATA_STATE,
            (RAWTEXT_END_TAG_OPEN_STATE) => RAWTEXT_STATE,
            (SCRIPT_DATA_END_TAG_OPEN_STATE) => SCRIPT_DATA_STATE,
            (SCRIPT_DATA_ESCAPED_END_TAG_OPEN_STATE)
                => SCRIPT_DATA_ESCAPED_STATE,
          }->{$self->{state}} or die "${state}'s next state not found";
          return  ({type => CHARACTER_TOKEN,
                    data => '</' . $self->{kwd},
                    line => $self->{line_prev},
                    column => $self->{column_prev} - 1 - length $self->{kwd},
                   });
          redo A;
        } else {
          
          $self->{ct}
              = {type => END_TAG_TOKEN,
                 tag_name => $self->{last_stag_name},
                 line => $self->{line_prev},
                 column => $self->{column_prev} - 1 - length $self->{kwd}};
          $self->{state} = TAG_NAME_STATE;
          ## Reconsume.
          redo A;
        }
      }
    } elsif ($state == SCRIPT_DATA_DOUBLE_ESCAPE_START_STATE or
             $state == SCRIPT_DATA_DOUBLE_ESCAPE_END_STATE) {
      if ($is_space->{$nc} or
          $nc == 0x002F or # /
          $nc == 0x003E) { # >
        my $token = {type => CHARACTER_TOKEN,
                     data => chr $nc,
                     line => $self->{line}, column => $self->{column}};
        if ($state == SCRIPT_DATA_DOUBLE_ESCAPE_START_STATE) {
          $self->{state} = $self->{kwd} eq 'script' # "temporary buffer"
              ? SCRIPT_DATA_DOUBLE_ESCAPED_STATE
              : SCRIPT_DATA_ESCAPED_STATE;
        } else {
          $self->{state} = $self->{kwd} eq 'script' # "temporary buffer"
              ? SCRIPT_DATA_ESCAPED_STATE
              : SCRIPT_DATA_DOUBLE_ESCAPED_STATE;
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($token);
        redo A;
      } else {
        die "$state/$nc is implemented";
      }
    } elsif ($state == ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE) {
      ## XML5: "Tag attribute value double quoted state" and "DOCTYPE
      ## ATTLIST attribute value double quoted state".
      
      if ($nc == 0x0022) { # "
        if ($self->{ct}->{type} == ATTLIST_TOKEN) {
          
          ## XML5: "DOCTYPE ATTLIST name after state".
          push @{$self->{ct}->{attrdefs}}, $self->{ca};
          $self->{state} = AFTER_ATTLIST_ATTR_VALUE_QUOTED_STATE;
        } else {
          
          ## XML5: "Tag attribute name before state".
          $self->{state} = AFTER_ATTRIBUTE_VALUE_QUOTED_STATE;
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0026) { # &
        
        ## XML5: Not defined yet.

        ## NOTE: In the spec, the tokenizer is switched to the 
        ## "entity in attribute value state".  In this implementation, the
        ## tokenizer is switched to the |ENTITY_STATE|, which is an
        ## implementation of the "consume a character reference" algorithm.
        $self->{prev_state} = $state;
        $self->{entity_add} = 0x0022; # "
        $self->{state} = ENTITY_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($self->{is_xml} and 
               $is_space->{$nc}) {
        
        $self->{ca}->{value} .= ' ';
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed attribute value');
        if ($self->{ct}->{type} == START_TAG_TOKEN) {
          
          $self->{last_stag_name} = $self->{ct}->{tag_name};

          $self->{state} = DATA_STATE;
          ## reconsume
          return  ($self->{ct}); # start tag
          redo A;
        } elsif ($self->{ct}->{type} == END_TAG_TOKEN) {
          if ($self->{ct}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }

          $self->{state} = DATA_STATE;
          ## reconsume

          ## Discard the token.
          #return  ($self->{ct}); # end tag

          redo A;
        } elsif ($self->{ct}->{type} == ATTLIST_TOKEN) {
          ## XML5: No parse error above; not defined yet.
          push @{$self->{ct}->{attrdefs}}, $self->{ca};
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
          ## Reconsume.

          ## Discard the token.
          #return  ($self->{ct}); # ATTLIST

          redo A;
        } else {
          die "$0: $self->{ct}->{type}: Unknown token type";
        }
      } elsif ($nc == 0x0000) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        $self->{ca}->{value} .= "\x{FFFD}";
        ## Stay in the state
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        ## XML5 [ATTLIST]: Not defined yet.
        if ($self->{is_xml} and $nc == 0x003C) { # <
          
          ## XML5: Not a parse error.
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'lt in attr value'); ## TODO: type
        } else {
          
        }
        $self->{ca}->{value} .= chr ($nc);
        $self->{read_until}->($self->{ca}->{value},
                              qq[\x00"&<\x09\x0C\x20],
                              length $self->{ca}->{value});

        ## Stay in the state
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE) {
      ## XML5: "Tag attribute value single quoted state" and "DOCTYPE
      ## ATTLIST attribute value single quoted state".

      if ($nc == 0x0027) { # '
        if ($self->{ct}->{type} == ATTLIST_TOKEN) {
          
          ## XML5: "DOCTYPE ATTLIST name after state".
          push @{$self->{ct}->{attrdefs}}, $self->{ca};
          $self->{state} = AFTER_ATTLIST_ATTR_VALUE_QUOTED_STATE;
        } else {
          
          ## XML5: "Before attribute name state" (sic).
          $self->{state} = AFTER_ATTRIBUTE_VALUE_QUOTED_STATE;
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0026) { # &
        
        ## XML5: Not defined yet.

        ## NOTE: In the spec, the tokenizer is switched to the 
        ## "entity in attribute value state".  In this implementation, the
        ## tokenizer is switched to the |ENTITY_STATE|, which is an
        ## implementation of the "consume a character reference" algorithm.
        $self->{entity_add} = 0x0027; # '
        $self->{prev_state} = $state;
        $self->{state} = ENTITY_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($self->{is_xml} and 
               $is_space->{$nc}) {
        
        $self->{ca}->{value} .= ' ';
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed attribute value');
        if ($self->{ct}->{type} == START_TAG_TOKEN) {
          
          $self->{last_stag_name} = $self->{ct}->{tag_name};

          $self->{state} = DATA_STATE;
          ## reconsume

          ## Discard the token.
          #return  ($self->{ct}); # start tag

          redo A;
        } elsif ($self->{ct}->{type} == END_TAG_TOKEN) {
          if ($self->{ct}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }

          $self->{state} = DATA_STATE;
          ## reconsume

          ## Discard the token.
          #return  ($self->{ct}); # end tag

          redo A;
        } elsif ($self->{ct}->{type} == ATTLIST_TOKEN) {
          ## XML5: No parse error above; not defined yet.
          push @{$self->{ct}->{attrdefs}}, $self->{ca};
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
          ## Reconsume.

          ## Discard the token.
          #return  ($self->{ct}); # ATTLIST

          redo A;
        } else {
          die "$0: $self->{ct}->{type}: Unknown token type";
        }
      } elsif ($nc == 0x0000) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        $self->{ca}->{value} .= "\x{FFFD}";
        ## Stay in the state
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        ## XML5 [ATTLIST]: Not defined yet.
        if ($self->{is_xml} and $nc == 0x003C) { # <
          
          ## XML5: Not a parse error.
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'lt in attr value'); ## TODO: type
        } else {
          
        }
        $self->{ca}->{value} .= chr ($nc);
        $self->{read_until}->($self->{ca}->{value},
                              qq[\x00'&<\x09\x0C\x20],
                              length $self->{ca}->{value});

        ## Stay in the state
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == ATTRIBUTE_VALUE_UNQUOTED_STATE) {
      ## XML5: "Tag attribute value unquoted state".

      if ($is_space->{$nc}) {
        if ($self->{ct}->{type} == ATTLIST_TOKEN) {
          
          push @{$self->{ct}->{attrdefs}}, $self->{ca};
          $self->{state} = DOCTYPE_ATTLIST_NAME_AFTER_STATE;
        } else {
          
          ## XML5: "Tag attribute name before state".
          $self->{state} = BEFORE_ATTRIBUTE_NAME_STATE;
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0026) { # &
        

        ## XML5: Not defined yet.

        ## NOTE: In the spec, the tokenizer is switched to the
        ## "character reference in attribute value state".  In this
        ## implementation, the tokenizer is switched to the
        ## |ENTITY_STATE|, which is an implementation of the "consume
        ## a character reference" algorithm.
        $self->{entity_add} = 0x003E; # >
        $self->{prev_state} = $state;
        $self->{state} = ENTITY_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        if ($self->{ct}->{type} == START_TAG_TOKEN) {
          
          $self->{last_stag_name} = $self->{ct}->{tag_name};

          $self->{state} = DATA_STATE;
          
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
          return  ($self->{ct}); # start tag
          redo A;
        } elsif ($self->{ct}->{type} == END_TAG_TOKEN) {
          if ($self->{ct}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }

          $self->{state} = DATA_STATE;
          
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
          return  ($self->{ct}); # end tag
          redo A;
        } elsif ($self->{ct}->{type} == ATTLIST_TOKEN) {
          push @{$self->{ct}->{attrdefs}}, $self->{ca};
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
          
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
          return  ($self->{ct}); # ATTLIST
          redo A;
        } else {
          die "$0: $self->{ct}->{type}: Unknown token type";
        }
      } elsif ($nc == -1) {
        if ($self->{ct}->{type} == START_TAG_TOKEN) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed tag');
          $self->{last_stag_name} = $self->{ct}->{tag_name};

          $self->{state} = DATA_STATE;
          ## reconsume

          ## Discard the token.
          #return  ($self->{ct}); # start tag
          
          redo A;
        } elsif ($self->{ct}->{type} == END_TAG_TOKEN) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed tag');
          if ($self->{ct}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          } else {
            ## NOTE: This state should never be reached.
            
          }

          $self->{state} = DATA_STATE;
          ## reconsume

          ## Discard the token.
          #return  ($self->{ct}); # end tag

          redo A;
        } elsif ($self->{ct}->{type} == ATTLIST_TOKEN) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
          push @{$self->{ct}->{attrdefs}}, $self->{ca};
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
          ## Reconsume.

          ## Discard the token.
          #return  ($self->{ct}); # ATTLIST

          redo A;
        } else {
          die "$0: $self->{ct}->{type}: Unknown token type";
        }
      } elsif ($nc == 0x0000) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        $self->{ca}->{value} .= "\x{FFFD}";
        ## Stay in the state
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        if ({
             0x0022 => 1, # "
             0x0027 => 1, # '
             0x003D => 1, # =
             0x003C => 1, # <
             0x0060 => 1, # `
            }->{$nc}) {
          
          ## XML5: Not a parse error.
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'bad attribute value');
        } else {
          
        }
        $self->{ca}->{value} .= chr ($nc);
        $self->{read_until}->($self->{ca}->{value},
                              qq[\x00"'=&` \x09\x0C<>],
                              length $self->{ca}->{value});

        ## Stay in the state
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == SELF_CLOSING_START_TAG_STATE) {
      ## XML5: "Empty tag state".

      if ($nc == 0x003E) { # >
        if ($self->{ct}->{type} == END_TAG_TOKEN) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'nestc', token => $self->{ct});
          ## XXX: Different type than slash in start tag
          if ($self->{ct}->{attributes}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'end tag attribute');
          } else {
            
          }
          ## XXX: Test |<title></title/>|
        } else {
          
          $self->{self_closing} = 1;
        }

        $self->{state} = DATA_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  

        return  ($self->{ct}); # start tag or end tag

        redo A;
      } else {
        die "$state/$nc is implemented";
      }
    } elsif ($state == BOGUS_COMMENT_STATE) {
      ## XML5: "Bogus comment state" and "DOCTYPE bogus comment state".

      ## NOTE: Unlike spec's "bogus comment state", this implementation
      ## consumes characters one-by-one basis.
      
      if ($nc == 0x003E) { # >
        if ($self->{in_subset}) {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        } else {
          
          $self->{state} = DATA_STATE;
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  

        return  ($self->{ct}); # comment
        redo A;
      } elsif ($nc == -1) { 
        if ($self->{in_subset}) {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        } else {
          
          $self->{state} = DATA_STATE;
        }
        ## reconsume

        return  ($self->{ct}); # comment
        redo A;
      } elsif ($nc == 0x0000) {
        $self->{ct}->{data} .= "\x{FFFD}"; # comment
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        $self->{ct}->{data} .= chr ($nc); # comment
        $self->{read_until}->($self->{ct}->{data},
                              qq[\x00>],
                              length $self->{ct}->{data});

        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == MARKUP_DECLARATION_OPEN_STATE) {
      ## XML5: "Markup declaration state".
      
      if ($nc == 0x002D) { # -
        
        $self->{state} = MD_HYPHEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0044 or # D
               $nc == 0x0064) { # d
        ## ASCII case-insensitive.
        
        $self->{state} = MD_DOCTYPE_STATE;
        $self->{kwd} = chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
#               $nc == 0x005B) { # [
                        
        $self->{state} = MD_CDATA_STATE;
        $self->{kwd} = '[';
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
      }

      $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment',
                      line => $self->{line_prev},
                      column => $self->{column_prev} - 1);
      ## Reconsume.
      $self->{state} = BOGUS_COMMENT_STATE;
      $self->{ct} = {type => COMMENT_TOKEN, data => '',
                                line => $self->{line_prev},
                                column => $self->{column_prev} - 1,
                               };
      redo A;
    } elsif ($state == MD_DOCTYPE_STATE) {
      ## ASCII case-insensitive.
      if ($nc == [
            undef,
            0x004F, # O
            0x0043, # C
            0x0054, # T
            0x0059, # Y
            0x0050, # P
            NEVER_CHAR, # (E)
          ]->[length $self->{kwd}] or
          $nc == [
            undef,
            0x006F, # o
            0x0063, # c
            0x0074, # t
            0x0079, # y
            0x0070, # p
            NEVER_CHAR, # (e)
          ]->[length $self->{kwd}]) {
        
        ## Stay in the state.
        $self->{kwd} .= chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ((length $self->{kwd}) == 6 and
               ($nc == 0x0045 or # E
                $nc == 0x0065)) { # e
        if ($self->{is_xml} and
            ($self->{kwd} ne 'DOCTYP' or $nc == 0x0065)) {
          
          ## XML5: case-sensitive.
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'lowercase keyword', ## TODO
                          text => 'DOCTYPE',
                          line => $self->{line_prev},
                          column => $self->{column_prev} - 5);
        } else {
          
        }
        $self->{state} = DOCTYPE_STATE;
        $self->{ct} = {type => DOCTYPE_TOKEN,
                                  quirks => 1,
                                  line => $self->{line_prev},
                                  column => $self->{column_prev} - 7,
                                 };
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
                
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 1 - length $self->{kwd});
        $self->{state} = BOGUS_COMMENT_STATE;
        ## Reconsume.
        $self->{ct} = {type => COMMENT_TOKEN,
                                  data => $self->{kwd},
                                  line => $self->{line_prev},
                                  column => $self->{column_prev} - 1 - length $self->{kwd},
                                 };
        redo A;
      }
    } elsif ($state == MD_CDATA_STATE) {
      if ($nc == {
            '[' => 0x0043, # C
            '[C' => 0x0044, # D
            '[CD' => 0x0041, # A
            '[CDA' => 0x0054, # T
            '[CDAT' => 0x0041, # A
            '[CDATA' => NEVER_CHAR, # ([)
          }->{$self->{kwd}}) {
        
        ## Stay in the state.
        $self->{kwd} .= chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($self->{kwd} eq '[CDATA' and
               $nc == 0x005B) { # [
        if ($self->{is_xml} and 
            not $self->{tainted} and
            @{$self->{open_elements} or []} == 0) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'cdata outside of root element',
                          line => $self->{line_prev},
                          column => $self->{column_prev} - 7);
          $self->{tainted} = 1;
        } else {
          
        }

        $self->{ct} = {type => CHARACTER_TOKEN,
                                  data => '',
                                  line => $self->{line_prev},
                                  column => $self->{column_prev} - 7};
        $self->{state} = CDATA_SECTION_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 1 - length $self->{kwd});
        $self->{state} = BOGUS_COMMENT_STATE;
        ## Reconsume.
        $self->{ct} = {type => COMMENT_TOKEN,
                                  data => $self->{kwd},
                                  line => $self->{line_prev},
                                  column => $self->{column_prev} - 1 - length $self->{kwd},
                                 };
        redo A;
      }
    } elsif ($state == COMMENT_START_STATE) {
      if ($nc == 0x002D) { # -
        
        $self->{state} = COMMENT_START_DASH_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment');
        if ($self->{in_subset}) {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        } else {
          
          $self->{state} = DATA_STATE;
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  

        return  ($self->{ct}); # comment

        redo A;
      } elsif ($nc == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed comment');
        if ($self->{in_subset}) {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        } else {
          
          $self->{state} = DATA_STATE;
        }
        ## reconsume

        return  ($self->{ct}); # comment

        redo A;
      } elsif ($nc == 0x0000) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        $self->{ct}->{data} .= "\x{FFFD}"; # comment
        $self->{state} = COMMENT_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        $self->{ct}->{data} # comment
            .= chr ($nc);
        $self->{state} = COMMENT_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == COMMENT_START_DASH_STATE) {
      if ($nc == 0x002D) { # -
        
        $self->{state} = COMMENT_END_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment');
        if ($self->{in_subset}) {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        } else {
          
          $self->{state} = DATA_STATE;
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  

        return  ($self->{ct}); # comment

        redo A;
      } elsif ($nc == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed comment');
        if ($self->{in_subset}) {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        } else {
          
          $self->{state} = DATA_STATE;
        }
        ## reconsume

        return  ($self->{ct}); # comment

        redo A;
      } elsif ($nc == 0x0000) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        $self->{ct}->{data} .= "-\x{FFFD}"; # comment
        $self->{state} = COMMENT_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        $self->{ct}->{data} # comment
            .= '-' . chr ($nc);
        $self->{state} = COMMENT_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == COMMENT_STATE) {
      ## XML5: "Comment state" and "DOCTYPE comment state".

      if ($nc == 0x002D) { # -
        
        $self->{state} = COMMENT_END_DASH_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed comment');
        if ($self->{in_subset}) {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        } else {
          
          $self->{state} = DATA_STATE;
        }
        ## reconsume

        return  ($self->{ct}); # comment

        redo A;
      } elsif ($nc == 0x0000) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        $self->{ct}->{data} .= "\x{FFFD}"; # comment
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        $self->{ct}->{data} .= chr ($nc); # comment
        $self->{read_until}->($self->{ct}->{data},
                              qq[-\x00],
                              length $self->{ct}->{data});

        ## Stay in the state
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == COMMENT_END_DASH_STATE) {
      ## XML5: "Comment dash state" and "DOCTYPE comment dash state".

      if ($nc == 0x002D) { # -
        
        $self->{state} = COMMENT_END_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed comment');
        if ($self->{in_subset}) {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        } else {
          
          $self->{state} = DATA_STATE;
        }
        ## reconsume

        return  ($self->{ct}); # comment

        redo A;
      } elsif ($nc == 0x0000) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        $self->{ct}->{data} .= "-\x{FFFD}"; # comment
        $self->{state} = COMMENT_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        $self->{ct}->{data} .= '-' . chr ($nc); # comment
        $self->{state} = COMMENT_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == COMMENT_END_STATE or
             $state == COMMENT_END_BANG_STATE) {
      ## XML5: "Comment end state" and "DOCTYPE comment end state".
      ## (No comment end bang state.)

      if ($nc == 0x003E) { # >
        if ($self->{in_subset}) {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        } else {
          
          $self->{state} = DATA_STATE;
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  

        return  ($self->{ct}); # comment

        redo A;
      } elsif ($nc == 0x002D) { # -
        if ($state == COMMENT_END_BANG_STATE) {
          
          $self->{ct}->{data} .= '--!'; # comment
          $self->{state} = COMMENT_END_DASH_STATE;
        } else {
          
          ## XML5: Not a parse error.
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'dash in comment',
                          line => $self->{line_prev},
                          column => $self->{column_prev});
          $self->{ct}->{data} .= '-'; # comment
          ## Stay in the state
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($state != COMMENT_END_BANG_STATE and
               $nc == 0x0021) { # !
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'comment end bang'); # XXX error type
        $self->{state} = COMMENT_END_BANG_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed comment');
        if ($self->{in_subset}) {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        } else {
          
          $self->{state} = DATA_STATE;
        }
        ## Reconsume.

        return  ($self->{ct}); # comment

        redo A;
      } elsif ($nc == 0x0000) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        if ($state == COMMENT_END_BANG_STATE) {
          $self->{ct}->{data} .= "--!\x{FFFD}"; # comment
        } else {
          $self->{ct}->{data} .= "--\x{FFFD}"; # comment
        }
        $self->{state} = COMMENT_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        if ($state == COMMENT_END_BANG_STATE) {
          $self->{ct}->{data} .= '--!' . chr ($nc); # comment
        } else {
          $self->{ct}->{data} .= '--' . chr ($nc); # comment
        }
        $self->{state} = COMMENT_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } 
    } elsif ($state == DOCTYPE_STATE) {
      if ($is_space->{$nc}) {
        
        $self->{state} = BEFORE_DOCTYPE_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');
        $self->{ct}->{quirks} = 1;

        $self->{state} = DATA_STATE;
        ## Reconsume.
        return  ($self->{ct}); # DOCTYPE (quirks)

        redo A;
      } else {
        
        ## XML5: Swith to the bogus comment state.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before DOCTYPE name');
        $self->{state} = BEFORE_DOCTYPE_NAME_STATE;
        ## reconsume
        redo A;
      }
    } elsif ($state == BEFORE_DOCTYPE_NAME_STATE) {
      ## XML5: "DOCTYPE root name before state".

      if ($is_space->{$nc}) {
        
        ## Stay in the state
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no DOCTYPE name');
        $self->{state} = DATA_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  

        return  ($self->{ct}); # DOCTYPE (quirks)

        redo A;
      } elsif (0x0041 <= $nc and $nc <= 0x005A) { # A..Z
        
        $self->{ct}->{name} # DOCTYPE
            = chr ($nc + ($self->{is_xml} ? 0 : 0x0020));
        delete $self->{ct}->{quirks};
        $self->{state} = DOCTYPE_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no DOCTYPE name');
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{ct}); # DOCTYPE (quirks)

        redo A;
      } elsif ($self->{is_xml} and $nc == 0x005B) { # [
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no DOCTYPE name');
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        $self->{ct}->{has_internal_subset} = 1; # DOCTYPE
        $self->{in_subset} = 1;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE
        redo A;
      } elsif ($nc == 0x0000) {
        $self->{ct}->{name} = "\x{FFFD}";
        delete $self->{ct}->{quirks};
        $self->{state} = DOCTYPE_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        $self->{ct}->{name} = chr $nc;
        delete $self->{ct}->{quirks};
        $self->{state} = DOCTYPE_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_NAME_STATE) {
      ## XML5: "DOCTYPE root name state".

      if ($is_space->{$nc}) {
        
        $self->{state} = AFTER_DOCTYPE_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  

        return  ($self->{ct}); # DOCTYPE

        redo A;
      } elsif (0x0041 <= $nc and $nc <= 0x005A) { # A..Z
        
        $self->{ct}->{name} # DOCTYPE
            .= chr ($nc + ($self->{is_xml} ? 0 : 0x0020));
        delete $self->{ct}->{quirks};
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');
        $self->{state} = DATA_STATE;
        ## reconsume

        $self->{ct}->{quirks} = 1;
        return  ($self->{ct}); # DOCTYPE

        redo A;
      } elsif ($self->{is_xml} and $nc == 0x005B) { # [
        
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        $self->{ct}->{has_internal_subset} = 1; # DOCTYPE
        $self->{in_subset} = 1;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE
        redo A;
      } elsif ($nc == 0x0000) {
        $self->{ct}->{name} .= "\x{FFFD}"; # DOCTYPE
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        $self->{ct}->{name} .= chr ($nc); # DOCTYPE
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == AFTER_DOCTYPE_NAME_STATE) {
      ## XML5: Corresponding to XML5's "DOCTYPE root name after
      ## state", but implemented differently.

      if ($is_space->{$nc}) {
        
        ## Stay in the state
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{state} = DATA_STATE;
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'no md def'); ## TODO: type
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }
        
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($nc == -1) {
        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }
        
        ## Reconsume.
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($nc == 0x0050 or # P
               $nc == 0x0070) { # p
        
        $self->{state} = PUBLIC_STATE;
        $self->{kwd} = chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0053 or # S
               $nc == 0x0073) { # s
        
        $self->{state} = SYSTEM_STATE;
        $self->{kwd} = chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0022 and # "
               ($self->{ct}->{type} == GENERAL_ENTITY_TOKEN or
                $self->{ct}->{type} == PARAMETER_ENTITY_TOKEN)) {
        
        $self->{state} = DOCTYPE_ENTITY_VALUE_DOUBLE_QUOTED_STATE;
        $self->{ct}->{value} = ''; # ENTITY
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0027 and # '
               ($self->{ct}->{type} == GENERAL_ENTITY_TOKEN or
                $self->{ct}->{type} == PARAMETER_ENTITY_TOKEN)) {
        
        $self->{state} = DOCTYPE_ENTITY_VALUE_SINGLE_QUOTED_STATE;
        $self->{ct}->{value} = ''; # ENTITY
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($self->{is_xml} and
               $self->{ct}->{type} == DOCTYPE_TOKEN and
               $nc == 0x005B) { # [
        
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        $self->{ct}->{has_internal_subset} = 1; # DOCTYPE
        $self->{in_subset} = 1;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after DOCTYPE name'); ## TODO: type

        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{ct}->{quirks} = 1;
          $self->{state} = BOGUS_DOCTYPE_STATE;
        } else {
          
          $self->{state} = BOGUS_MD_STATE;
        }

        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == PUBLIC_STATE) {
      ## ASCII case-insensitive
      if ($nc == [
            undef, 
            0x0055, # U
            0x0042, # B
            0x004C, # L
            0x0049, # I
            NEVER_CHAR, # (C)
          ]->[length $self->{kwd}] or
          $nc == [
            undef, 
            0x0075, # u
            0x0062, # b
            0x006C, # l
            0x0069, # i
            NEVER_CHAR, # (c)
          ]->[length $self->{kwd}]) {
        
        ## Stay in the state.
        $self->{kwd} .= chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ((length $self->{kwd}) == 5 and
               ($nc == 0x0043 or # C
                $nc == 0x0063)) { # c
        if ($self->{is_xml} and
            ($self->{kwd} ne 'PUBLI' or $nc == 0x0063)) { # c
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'lowercase keyword', ## TODO: type
                          text => 'PUBLIC',
                          line => $self->{line_prev},
                          column => $self->{column_prev} - 4);
        } else {
          
        }
        $self->{state} = AFTER_DOCTYPE_PUBLIC_KEYWORD_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after DOCTYPE name', ## TODO: type
                        line => $self->{line_prev},
                        column => $self->{column_prev} + 1 - length $self->{kwd});
        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{ct}->{quirks} = 1;
          $self->{state} = BOGUS_DOCTYPE_STATE;
        } else {
          
          $self->{state} = BOGUS_MD_STATE;
        }
        ## Reconsume.
        redo A;
      }
    } elsif ($state == SYSTEM_STATE) {
      ## ASCII case-insensitive
      if ($nc == [
            undef, 
            0x0059, # Y
            0x0053, # S
            0x0054, # T
            0x0045, # E
            NEVER_CHAR, # (M)
          ]->[length $self->{kwd}] or
          $nc == [
            undef, 
            0x0079, # y
            0x0073, # s
            0x0074, # t
            0x0065, # e
            NEVER_CHAR, # (m)
          ]->[length $self->{kwd}]) {
        
        ## Stay in the state.
        $self->{kwd} .= chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ((length $self->{kwd}) == 5 and
               ($nc == 0x004D or # M
                $nc == 0x006D)) { # m
        if ($self->{is_xml} and
            ($self->{kwd} ne 'SYSTE' or $nc == 0x006D)) { # m
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'lowercase keyword', ## TODO: type
                          text => 'SYSTEM',
                          line => $self->{line_prev},
                          column => $self->{column_prev} - 4);
        } else {
          
        }
        $self->{state} = AFTER_DOCTYPE_SYSTEM_KEYWORD_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after DOCTYPE name', ## TODO: type
                        line => $self->{line_prev},
                        column => $self->{column_prev} + 1 - length $self->{kwd});
        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{ct}->{quirks} = 1;
          $self->{state} = BOGUS_DOCTYPE_STATE;
        } else {
          
          $self->{state} = BOGUS_MD_STATE;
        }
        ## Reconsume.
        redo A;
      }
    } elsif ($state == AFTER_DOCTYPE_PUBLIC_KEYWORD_STATE or
             $state == BEFORE_DOCTYPE_PUBLIC_IDENTIFIER_STATE) {
      if ($is_space->{$nc}) {
        
        ## Stay in or switch to the state.
        $self->{state} = BEFORE_DOCTYPE_PUBLIC_IDENTIFIER_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0022) { # "
        if ($state == AFTER_DOCTYPE_PUBLIC_KEYWORD_STATE) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before pubid literal'); # XXX documentation
        } else {
          
        }
        $self->{ct}->{pubid} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_PUBLIC_IDENTIFIER_DOUBLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0027) { # '
        if ($state == AFTER_DOCTYPE_PUBLIC_KEYWORD_STATE) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before pubid literal'); # XXX documentation
        } else {
          
        }
        $self->{ct}->{pubid} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_PUBLIC_IDENTIFIER_SINGLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no PUBLIC literal');
        
        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }
        
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($nc == EOF_CHAR) {
        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }
        
        ## Reconsume.
        return  ($self->{ct}); # DOCTYPE
        redo A;
      } elsif ($self->{is_xml} and
               $self->{ct}->{type} == DOCTYPE_TOKEN and
               $nc == 0x005B) { # [
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no PUBLIC literal');
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        $self->{ct}->{has_internal_subset} = 1; # DOCTYPE
        $self->{in_subset} = 1;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after PUBLIC');

        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{ct}->{quirks} = 1;
          $self->{state} = BOGUS_DOCTYPE_STATE;
        } else {
          
          $self->{state} = BOGUS_MD_STATE;
        }

        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_PUBLIC_IDENTIFIER_DOUBLE_QUOTED_STATE) {
      if ($nc == 0x0022) { # "
        
        $self->{state} = AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed PUBLIC literal');

        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }

        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($nc == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed PUBLIC literal');

        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }
        
        ## Reconsume.
        return  ($self->{ct}); # DOCTYPE
        redo A;
      } elsif ($nc == 0x0000) {
        $self->{ct}->{pubid} .= "\x{FFFD}"; # DOCTYPE/ENTITY/NOTATION
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        $self->{ct}->{pubid} .= chr $nc; # DOCTYPE/ENTITY/NOTATION
        $self->{read_until}->($self->{ct}->{pubid}, qq[\x00">],
                              length $self->{ct}->{pubid});

        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_PUBLIC_IDENTIFIER_SINGLE_QUOTED_STATE) {
      if ($nc == 0x0027) { # '
        
        $self->{state} = AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed PUBLIC literal');

        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }

        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($nc == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed PUBLIC literal');

        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }
      
        ## reconsume
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($nc == 0x0000) {
        $self->{ct}->{pubid} .= "\x{FFFD}"; # DOCTYPE/ENTITY/NOTATION
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        $self->{ct}->{pubid} .= chr $nc; # DOCTYPE/ENTITY/NOTATION
        $self->{read_until}->($self->{ct}->{pubid}, qq[\x00'>],
                              length $self->{ct}->{pubid});

        ## Stay in the state
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE or
             $state == BETWEEN_DOCTYPE_PUBLIC_AND_SYSTEM_IDS_STATE) {
      if ($is_space->{$nc}) {
        
        ## Stay in or switch to the state.
        $self->{state} = BETWEEN_DOCTYPE_PUBLIC_AND_SYSTEM_IDS_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0022) { # "
        if ($state == AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before system literal'); # XXX documentation
        } else {
          
        }
        $self->{ct}->{sysid} = ''; # DOCTYPE/ENTITY/NOTATION
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0027) { # '
        if ($state == AFTER_DOCTYPE_PUBLIC_IDENTIFIER_STATE) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before system literal'); # XXX documentation
        } else {
          
        }
        $self->{ct}->{sysid} = ''; # DOCTYPE/ENTITY/NOTATION
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          if ($self->{is_xml}) {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'no SYSTEM literal');
          } else {
            
          }
          $self->{state} = DATA_STATE;
        } else {
          if ($self->{ct}->{type} == NOTATION_TOKEN) {
            
          } else {
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'no SYSTEM literal');            
          }
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }
        
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($nc == EOF_CHAR) {
        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');
          
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }

        ## Reconsume.
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($self->{is_xml} and
               $self->{ct}->{type} == DOCTYPE_TOKEN and
               $nc == 0x005B) { # [
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no SYSTEM literal');
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        $self->{ct}->{has_internal_subset} = 1; # DOCTYPE
        $self->{in_subset} = 1;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after PUBLIC literal');

        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{ct}->{quirks} = 1;
          $self->{state} = BOGUS_DOCTYPE_STATE;
        } else {
          
          $self->{state} = BOGUS_MD_STATE;
        }

        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == AFTER_DOCTYPE_SYSTEM_KEYWORD_STATE or
             $state == BEFORE_DOCTYPE_SYSTEM_IDENTIFIER_STATE) {
      if ($is_space->{$nc}) {
        
        ## Stay in or switch to the state.
        $self->{state} = BEFORE_DOCTYPE_SYSTEM_IDENTIFIER_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0022) { # "
        if ($state == AFTER_DOCTYPE_SYSTEM_KEYWORD_STATE) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before system literal'); # XXX documentation
        } else {
          
        }
        $self->{ct}->{sysid} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0027) { # '
        if ($state == AFTER_DOCTYPE_SYSTEM_KEYWORD_STATE) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before system literal'); # XXX documentation
        } else {
          
        }
        $self->{ct}->{sysid} = ''; # DOCTYPE
        $self->{state} = DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no SYSTEM literal');
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  

        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }

        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($nc == EOF_CHAR) {
        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }
        
        ## Reconsume.
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($self->{is_xml} and
               $self->{ct}->{type} == DOCTYPE_TOKEN and
               $nc == 0x005B) { # [
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no SYSTEM literal');

        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        $self->{ct}->{has_internal_subset} = 1; # DOCTYPE
        $self->{in_subset} = 1;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after SYSTEM');

        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
                    
          $self->{ct}->{quirks} = 1;
          $self->{state} = BOGUS_DOCTYPE_STATE;
        } else {
          
          $self->{state} = BOGUS_MD_STATE;
        }

        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_SYSTEM_IDENTIFIER_DOUBLE_QUOTED_STATE) {
      if ($nc == 0x0022) { # "
        
        $self->{state} = AFTER_DOCTYPE_SYSTEM_IDENTIFIER_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif (not $self->{is_xml} and $nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed SYSTEM literal');

        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }
        
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($nc == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed SYSTEM literal');

        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }
        
        ## reconsume
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($nc == 0x0000) {
        $self->{ct}->{sysid} .= "\x{FFFD}"; # DOCTYPE/ENTITY/NOTATION
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        $self->{ct}->{sysid} .= chr $nc; # DOCTYPE/ENTITY/NOTATION
        $self->{read_until}->($self->{ct}->{sysid}, qq[\x00">],
                              length $self->{ct}->{sysid});

        ## Stay in the state
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_SYSTEM_IDENTIFIER_SINGLE_QUOTED_STATE) {
      if ($nc == 0x0027) { # '
        
        $self->{state} = AFTER_DOCTYPE_SYSTEM_IDENTIFIER_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif (not $self->{is_xml} and $nc == 0x003E) { # >
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed SYSTEM literal');

        $self->{state} = DATA_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  

        $self->{ct}->{quirks} = 1;
        return  ($self->{ct}); # DOCTYPE

        redo A;
      } elsif ($nc == -1) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed SYSTEM literal');

        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }

        ## reconsume
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($nc == 0x0000) {
        $self->{ct}->{sysid} .= "\x{FFFD}"; # DOCTYPE/ENTITY/NOTATION
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        $self->{ct}->{sysid} .= chr $nc; # DOCTYPE/ENTITY/NOTATION
        $self->{read_until}->($self->{ct}->{sysid}, qq[\x00'>],
                              length $self->{ct}->{sysid});

        ## Stay in the state
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == AFTER_DOCTYPE_SYSTEM_IDENTIFIER_STATE) {
      if ($is_space->{$nc}) {
        if ($self->{ct}->{type} == GENERAL_ENTITY_TOKEN) {
          
          $self->{state} = BEFORE_NDATA_STATE;
        } else {
          
          ## Stay in the state
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{state} = DATA_STATE;
        } else {
          
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }

        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($self->{ct}->{type} == GENERAL_ENTITY_TOKEN and
               ($nc == 0x004E or # N
                $nc == 0x006E)) { # n
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before NDATA'); ## TODO: type
        $self->{state} = NDATA_STATE;
        $self->{kwd} = chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == -1) {
        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');
          $self->{state} = DATA_STATE;
          $self->{ct}->{quirks} = 1;
        } else {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        }

        ## reconsume
        return  ($self->{ct}); # DOCTYPE/ENTITY/NOTATION
        redo A;
      } elsif ($self->{is_xml} and
               $self->{ct}->{type} == DOCTYPE_TOKEN and
               $nc == 0x005B) { # [
        
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        $self->{ct}->{has_internal_subset} = 1; # DOCTYPE
        $self->{in_subset} = 1;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after SYSTEM literal');

        if ($self->{ct}->{type} == DOCTYPE_TOKEN) {
          
          #$self->{ct}->{quirks} = 1;
          $self->{state} = BOGUS_DOCTYPE_STATE;
        } else {
          
          $self->{state} = BOGUS_MD_STATE;
        }

        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == BEFORE_NDATA_STATE) {
      if ($is_space->{$nc}) {
        
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ENTITY
        redo A;
      } elsif ($nc == 0x004E or # N
               $nc == 0x006E) { # n
        
        $self->{state} = NDATA_STATE;
        $self->{kwd} = chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == -1) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        ## reconsume
        return  ($self->{ct}); # ENTITY
        redo A;
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after SYSTEM literal');
        $self->{state} = BOGUS_MD_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == BOGUS_DOCTYPE_STATE) {
      if ($nc == 0x003E) { # >
        
        $self->{state} = DATA_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  

        return  ($self->{ct}); # DOCTYPE

        redo A;
      } elsif ($self->{is_xml} and $nc == 0x005B) { # [
        
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        $self->{ct}->{has_internal_subset} = 1; # DOCTYPE
        $self->{in_subset} = 1;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # DOCTYPE
        redo A;
      } elsif ($nc == -1) {
        
        $self->{state} = DATA_STATE;
        ## reconsume

        return  ($self->{ct}); # DOCTYPE

        redo A;
      } else {
        
        my $s = '';
        $self->{read_until}->($s, q{>[}, 0);

        ## Stay in the state
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == CDATA_SECTION_STATE) {
      ## NOTE: "CDATA section state" in the state is jointly implemented
      ## by three states, |CDATA_SECTION_STATE|, |CDATA_SECTION_MSE1_STATE|,
      ## and |CDATA_SECTION_MSE2_STATE|.

      ## XML5: "CDATA state".
      
      if ($nc == 0x005D) { # ]
        
        $self->{state} = CDATA_SECTION_MSE1_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == -1) {
        if ($self->{is_xml}) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'no mse'); ## TODO: type
        } else {
          
        }

        $self->{state} = DATA_STATE;
        ## Reconsume.
        if (length $self->{ct}->{data}) { # character
          
          return  ($self->{ct}); # character
        } else {
          
          ## No token to emit. $self->{ct} is discarded.
        }        
        redo A;
      } else {
        
        $self->{ct}->{data} .= chr $nc;
        $self->{read_until}->($self->{ct}->{data},
                              qq<\x00]>,
                              length $self->{ct}->{data});
        ## NOTE: NULLs are left as is (see spec's comment).  However,
        ## a token cannot contain more than one U+0000 NULL character
        ## for the ease of processing in the tree constructor.

        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }

      ## ISSUE: "text tokens" in spec.
    } elsif ($state == CDATA_SECTION_MSE1_STATE) {
      ## XML5: "CDATA bracket state".

      if ($nc == 0x005D) { # ]
        
        $self->{state} = CDATA_SECTION_MSE2_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        ## XML5: If EOF, "]" is not appended and changed to the data state.
        $self->{ct}->{data} .= ']';
        $self->{state} = CDATA_SECTION_STATE; ## XML5: Stay in the state.
        ## Reconsume.
        redo A;
      }
    } elsif ($state == CDATA_SECTION_MSE2_STATE) {
      ## XML5: "CDATA end state".

      if ($nc == 0x003E) { # >
        $self->{state} = DATA_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        if (length $self->{ct}->{data}) { # character
          
          return  ($self->{ct}); # character
        } else {
          
          ## No token to emit. $self->{ct} is discarded.
        }
        redo A;
      } elsif ($nc == 0x005D) { # ]
         # character
        $self->{ct}->{data} .= ']'; ## Add first "]" of "]]]".
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        $self->{ct}->{data} .= ']]'; # character
        $self->{state} = CDATA_SECTION_STATE;
        ## Reconsume. ## XML5: Emit.
        redo A;
      }
    } elsif ($state == ENTITY_STATE) {
      if ($is_space->{$nc} or
          {
            0x003C => 1, 0x0026 => 1, -1 => 1, # <, &

            ## Following characters are added here to detect parse
            ## error for "=" of "&=" in an unquoted attribute value.
            ## Though this disagree with the Web Applications 1.0
            ## spec, the result token sequences of both algorithms
            ## should be same, as these characters cannot form a part
            ## of character references.
            0x0022 => 1, 0x0027 => 1, 0x0060 => 1, # ", ', `
            0x003D => 1, # =

            ## As a result of the addition above, the following clause
            ## has no effect in fact.
            $self->{entity_add} => 1,
          }->{$nc}) {
        if ($self->{is_xml}) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare ero',
                          line => $self->{line_prev},
                          column => $self->{column_prev}
                              + ($nc == -1 ? 1 : 0));
        } else {
          
          ## No error
        }
        ## Don't consume
        ## Return nothing.
        #
      } elsif ($nc == 0x0023) { # #
        
        $self->{state} = ENTITY_HASH_STATE;
        $self->{kwd} = '#';
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($self->{is_xml} or
               (0x0041 <= $nc and
                $nc <= 0x005A) or # A..Z
               (0x0061 <= $nc and
                $nc <= 0x007A)) { # a..z
        
        #require HTML::HTML5::Parser::NamedEntityList;
        $self->{state} = ENTITY_NAME_STATE;
        $self->{kwd} = chr $nc;
        $self->{entity__value} = $self->{kwd};
        $self->{entity__match} = 0;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        
        ## Return nothing.
        #
      }

      ## We implement the "consume a character reference" in a
      ## slightly different way from the spec's algorithm, though the
      ## end result should be exactly same.

      ## NOTE: No character is consumed by the "consume a character
      ## reference" algorithm.  In other word, there is an "&" character
      ## that does not introduce a character reference, which would be
      ## appended to the parent element or the attribute value in later
      ## process of the tokenizer.

      if ($self->{prev_state} == DATA_STATE or
          $self->{prev_state} == RCDATA_STATE) {
        
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        return  ({type => CHARACTER_TOKEN, data => '&',
                  line => $self->{line_prev},
                  column => $self->{column_prev},
                 });
        redo A;
      } else {
        
        $self->{ca}->{value} .= '&';
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        redo A;
      }
    } elsif ($state == ENTITY_HASH_STATE) {
      if ($nc == 0x0078) { # x
        
        $self->{state} = HEXREF_X_STATE;
        $self->{kwd} .= chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0058) { # X
        
        if ($self->{is_xml}) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'uppercase hcro'); ## TODO: type
        }
        $self->{state} = HEXREF_X_STATE;
        $self->{kwd} .= chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif (0x0030 <= $nc and
               $nc <= 0x0039) { # 0..9
        
        $self->{state} = NCR_NUM_STATE;
        $self->{kwd} = $nc - 0x0030;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare nero',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 1);

        ## NOTE: According to the spec algorithm, nothing is returned,
        ## and then "&#" is appended to the parent element or the attribute 
        ## value in the later processing.

        if ($self->{prev_state} == DATA_STATE or
            $self->{prev_state} == RCDATA_STATE) {
          
          $self->{state} = $self->{prev_state};
          ## Reconsume.
          return  ({type => CHARACTER_TOKEN,
                    data => '&#',
                    line => $self->{line_prev},
                    column => $self->{column_prev} - 1,
                   });
          redo A;
        } else {
          
          $self->{ca}->{value} .= '&#';
          $self->{state} = $self->{prev_state};
          ## Reconsume.
          redo A;
        }
      }
    } elsif ($state == NCR_NUM_STATE) {
      if (0x0030 <= $nc and 
          $nc <= 0x0039) { # 0..9
        
        $self->{kwd} *= 10;
        $self->{kwd} += $nc - 0x0030;
        
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003B) { # ;
        
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        #
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no refc');
        ## Reconsume.
        #
      }

      my $code = $self->{kwd};
      my $l = $self->{line_prev};
      my $c = $self->{column_prev};
      if ((not $self->{is_xml} and $charref_map->{$code}) or
          ($self->{is_xml} and 0xD800 <= $code and $code <= 0xDFFF) or
          ($self->{is_xml} and $code == 0x0000)) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'invalid character reference',
                        text => (sprintf 'U+%04X', $code),
                        line => $l, column => $c);
        $code = $charref_map->{$code};
      } elsif ($code > 0x10FFFF) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'invalid character reference',
                        text => (sprintf 'U-%08X', $code),
                        line => $l, column => $c);
        $code = 0xFFFD;
      }

      if ($self->{prev_state} == DATA_STATE or
          $self->{prev_state} == RCDATA_STATE) {
        
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        return  ({type => CHARACTER_TOKEN, data => chr $code,
                  has_reference => 1,
                  line => $l, column => $c,
                 });
        redo A;
      } else {
        
        $self->{ca}->{value} .= chr $code;
        $self->{ca}->{has_reference} = 1;
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        redo A;
      }
    } elsif ($state == HEXREF_X_STATE) {
      if ((0x0030 <= $nc and $nc <= 0x0039) or
          (0x0041 <= $nc and $nc <= 0x0046) or
          (0x0061 <= $nc and $nc <= 0x0066)) {
        # 0..9, A..F, a..f
        
        $self->{state} = HEXREF_HEX_STATE;
        $self->{kwd} = 0;
        ## Reconsume.
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare hcro',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 2);

        ## NOTE: According to the spec algorithm, nothing is returned,
        ## and then "&#" followed by "X" or "x" is appended to the parent
        ## element or the attribute value in the later processing.

        if ($self->{prev_state} == DATA_STATE or
            $self->{prev_state} == RCDATA_STATE) {
          
          $self->{state} = $self->{prev_state};
          ## Reconsume.
          return  ({type => CHARACTER_TOKEN,
                    data => '&' . $self->{kwd},
                    line => $self->{line_prev},
                    column => $self->{column_prev} - length $self->{kwd},
                   });
          redo A;
        } else {
          
          $self->{ca}->{value} .= '&' . $self->{kwd};
          $self->{state} = $self->{prev_state};
          ## Reconsume.
          redo A;
        }
      }
    } elsif ($state == HEXREF_HEX_STATE) {
      if (0x0030 <= $nc and $nc <= 0x0039) {
        # 0..9
        
        $self->{kwd} *= 0x10;
        $self->{kwd} += $nc - 0x0030;
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif (0x0061 <= $nc and
               $nc <= 0x0066) { # a..f
        
        $self->{kwd} *= 0x10;
        $self->{kwd} += $nc - 0x0060 + 9;
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif (0x0041 <= $nc and
               $nc <= 0x0046) { # A..F
        
        $self->{kwd} *= 0x10;
        $self->{kwd} += $nc - 0x0040 + 9;
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003B) { # ;
        
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        #
      } else {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no refc',
                        line => $self->{line},
                        column => $self->{column});
        ## Reconsume.
        #
      }

      my $code = $self->{kwd};
      my $l = $self->{line_prev};
      my $c = $self->{column_prev};
      if ((not $self->{is_xml} and $charref_map->{$code}) or
          ($self->{is_xml} and 0xD800 <= $code and $code <= 0xDFFF) or
          ($self->{is_xml} and $code == 0x0000)) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'invalid character reference',
                        text => (sprintf 'U+%04X', $code),
                        line => $l, column => $c);
        $code = $charref_map->{$code};
      } elsif ($code > 0x10FFFF) {
        
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'invalid character reference',
                        text => (sprintf 'U-%08X', $code),
                        line => $l, column => $c);
        $code = 0xFFFD;
      }

      if ($self->{prev_state} == DATA_STATE or
          $self->{prev_state} == RCDATA_STATE) {
        
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        return  ({type => CHARACTER_TOKEN, data => chr $code,
                  has_reference => 1,
                  line => $l, column => $c,
                 });
        redo A;
      } else {
        
        $self->{ca}->{value} .= chr $code;
        $self->{ca}->{has_reference} = 1;
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        redo A;
      }
    } elsif ($state == ENTITY_NAME_STATE) {
      if ((0x0041 <= $nc and # a
           $nc <= 0x005A) or # x
          (0x0061 <= $nc and # a
           $nc <= 0x007A) or # z
          (0x0030 <= $nc and # 0
           $nc <= 0x0039) or # 9
          $nc == 0x003B or # ;
          ($self->{is_xml} and
           not ($is_space->{$nc} or
                {
                  0x003C => 1, 0x0026 => 1, -1 => 1, # <, &

                  ## See comment in the |ENTITY_STATE|'s |if|
                  ## statement for the rationale of addition of these
                  ## characters.
                  0x0022 => 1, 0x0027 => 1, 0x0060 => 1, # ", ', `
                  0x003D => 1, # =

                  ## This is redundant for the same reason.
                  $self->{entity_add} => 1,
                }->{$nc}))) {
        #local %entity2char;
        $self->{kwd} .= chr $nc; ## Bare entity name.
        if (defined $entity2char{$self->{kwd}} or ## HTML charrefs.
            $self->{ge}->{$self->{kwd}}) { ## XML general entities.
          if ($nc == 0x003B) { # ;
            if (defined $self->{ge}->{$self->{kwd}}) {
              ## A declared XML entity.
              if ($self->{ge}->{$self->{kwd}}->{only_text}) {
                
                $self->{entity__value} = $self->{ge}->{$self->{kwd}}->{value};
              } else {
                if (defined $self->{ge}->{$self->{kwd}}->{notation}) {
                  
                  $self->{parse_error}->(level => $self->{level}->{must}, type => 'unparsed entity', ## TODO: type
                                  value => $self->{kwd});
                } else {
                  
                }
                $self->{entity__value} = '&' . $self->{kwd}; ## TODO: expand
              }
            } else {
              ## An HTML character reference.
              if ($self->{is_xml}) {
                ## Not a declared XML entity.
                
                $self->{parse_error}->(level => $self->{level}->{must}, type => 'entity not declared', ## TODO: type
                                value => $self->{kwd},
                                level => {
                                          'amp;' => $self->{level}->{warn},
                                          'quot;' => $self->{level}->{warn},
                                          'lt;' => $self->{level}->{warn},
                                          'gt;' => $self->{level}->{warn},
                                          'apos;' => $self->{level}->{warn},
                                         }->{$self->{kwd}} ||
                                         $self->{level}->{must},
                                line => $self->{line_prev},
                                column => $self->{column} - length $self->{kwd});
              } else {
                
              }
              $self->{entity__value} = $entity2char{$self->{kwd}};
            }
            $self->{entity__match} = 1; ## Matched exactly with ";" entity.
            
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
            #
          } else {
            
            $self->{entity__value} = $entity2char{$self->{kwd}};
            $self->{entity__match} = -1; ## Exactly matched to non-";" entity.
            ## Stay in the state.
            
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
            redo A;
          }
        } else {
          if ($nc == 0x003B) { # ;
            ## A reserved HTML character reference or an undeclared
            ## XML entity reference.
            
            $self->{parse_error}->(level => $self->{level}->{must}, type => 'entity not declared', ## XXXtype
                            value => $self->{kwd},
                            level => $self->{level}->{must},
                            line => $self->{line_prev},
                            column => $self->{column} - length $self->{kwd});
            $self->{entity__value} .= chr $nc;
            $self->{entity__match} *= 2; ## Matched (positive) or not (zero)
            
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
            #
          } else {
            
            $self->{entity__value} .= chr $nc;
            $self->{entity__match} *= 2; ## Matched (positive) or not (zero)
            ## Stay in the state.
            
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
            redo A;
          }
        }
      } elsif ($nc == 0x003D) { # =
        if ($self->{entity__match} < 0 and
            $self->{prev_state} != DATA_STATE and # in attribute
            $self->{prev_state} != RCDATA_STATE) {
          $self->{entity__match} = 0;
        }
      }

      my $data;
      my $has_ref;
      if ($self->{entity__match} > 0) { ## A ";" entity.
        
        $data = $self->{entity__value};
        ## Strictly speaking the $has_ref flag should not be set if
        ## there is no matched entity.  However, this flag is used
        ## only in contexts where use of an
        ## unexpanded-entity-reference-like string is in no way
        ## allowed, so it should not make any difference in theory.
        $has_ref = 1;
        #
      } elsif ($self->{entity__match} < 0) { ## Matched to non-";" entity.
        if ($self->{prev_state} != DATA_STATE and # in attribute
            $self->{prev_state} != RCDATA_STATE and
            $self->{entity__match} < -1) {
          ## In attribute-value contexts, matched non-";" string is
          ## left as is if there is trailing alphabetical letters.
          
          $data = '&' . $self->{kwd};
          #
        } else {
          ## In attribute-value contexts, exactly matched non-";"
          ## string is replaced as a character reference.  In any
          ## context, matched non-";" string with or without trailing
          ## alphabetical letters is replaced as a character reference
          ## (with trailing letters).  Note that use of a no-";"
          ## character reference is always non-conforming.
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'no refc');
          $data = $self->{entity__value};
          $has_ref = 1;
          #
        }
      } else { ## Unmatched string.
        if ($self->{is_xml} and not $self->{kwd} =~ /;$/) {
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare ero',
                          line => $self->{line_prev},
                          column => $self->{column_prev} - length $self->{kwd});
        } else {
          
        }
        $data = '&' . $self->{kwd};
        #
      }
  
      ## NOTE: In these cases, when a character reference is found,
      ## it is consumed and a character token is returned, or, otherwise,
      ## nothing is consumed and returned, according to the spec algorithm.
      ## In this implementation, anything that has been examined by the
      ## tokenizer is appended to the parent element or the attribute value
      ## as string, either literal string when no character reference or
      ## entity-replaced string otherwise, in this stage, since any characters
      ## that would not be consumed are appended in the data state or in an
      ## appropriate attribute value state anyway.
 
      if ($self->{prev_state} == DATA_STATE or
          $self->{prev_state} == RCDATA_STATE) {
        
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        return  ({type => CHARACTER_TOKEN,
                  data => $data,
                  has_reference => $has_ref,
                  line => $self->{line_prev},
                  column => $self->{column_prev} + 1 - length $self->{kwd},
                 });
        redo A;
      } else {
        
        $self->{ca}->{value} .= $data;
        $self->{ca}->{has_reference} = 1 if $has_ref;
        $self->{state} = $self->{prev_state};
        ## Reconsume.
        redo A;
      }

    ## ========== XML-only states ==========

    } elsif ($state == PI_STATE) {
      ## XML5: "Pi state" and "DOCTYPE pi state".

      if ($is_space->{$nc} or
          $nc == 0x003F or # ?
          $nc == -1) {
        ## XML5: U+003F: "pi state": Same as "Anything else"; "DOCTYPE
        ## pi state": Switch to the "DOCTYPE pi after state".  EOF:
        ## "DOCTYPE pi state": Parse error, switch to the "data
        ## state".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare pio', ## TODO: type
                        line => $self->{line_prev},
                        column => $self->{column_prev}
                            - 1 * ($nc != -1));
        $self->{state} = BOGUS_COMMENT_STATE;
        ## Reconsume.
        $self->{ct} = {type => COMMENT_TOKEN,
                       data => '?',
                       line => $self->{line_prev},
                       column => $self->{column_prev}
                           - 1 * ($nc != -1),
                      };
        redo A;
      } else {
        ## XML5: "DOCTYPE pi state": Stay in the state.
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ct} = {type => PI_TOKEN,
                       target => $nc == 0x0000 ? "\x{FFFD}" : chr $nc,
                       data => '',
                       line => $self->{line_prev},
                       column => $self->{column_prev} - 1,
                      };
        $self->{state} = PI_TARGET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == PI_TARGET_STATE) {
      if ($is_space->{$nc}) {
        $self->{state} = PI_TARGET_AFTER_STATE;
        $self->{kwd} = chr $nc; # "temporary buffer"
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no pic'); ## TODO: type
        if ($self->{in_subset}) {
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        } else {
          $self->{state} = DATA_STATE;
        }
        ## Reconsume.
        return  ({type => COMMENT_TOKEN,
                  data => '?' . $self->{ct}->{target},
                  line => $self->{ct}->{line},
                  column => $self->{ct}->{column}});
        redo A;
      } elsif ($nc == 0x003F) { # ?
        $self->{state} = PI_AFTER_STATE;
        $self->{kwd} = ''; # "temporary buffer"
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        ## XML5: typo ("tag name" -> "target")
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ct}->{target} .= $nc == 0x0000 ? "\x{FFFD}" : chr $nc; # pi
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == PI_TARGET_AFTER_STATE) {
      if ($is_space->{$nc}) {
        $self->{kwd} .= chr $nc; # "temporary buffer"
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        $self->{state} = PI_DATA_STATE;
        ## Reprocess.
        redo A;
      }
    } elsif ($state == PI_DATA_STATE) {
      if ($nc == 0x003F) { # ?
        $self->{state} = PI_DATA_AFTER_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no pic'); ## TODO: type
        if ($self->{in_subset}) {
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state"
        } else {
          $self->{state} = DATA_STATE;
        }
        ## Reprocess.
        return  ({type => COMMENT_TOKEN,
                  data => '?' . $self->{ct}->{target} .
                      $self->{kwd} . # "temporary buffer"
                      $self->{ct}->{data},
                  line => $self->{ct}->{line},
                  column => $self->{ct}->{column}});
        redo A;
      } else {
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ct}->{data} .= $nc == 0x0000 ? "\x{FFFD}" : chr $nc; # pi
        $self->{read_until}->($self->{ct}->{data}, qq[\x00?],
                              length $self->{ct}->{data});
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Reprocess.
        redo A;
      }
    } elsif ($state == PI_AFTER_STATE) {
      ## XML5: Part of "Pi after state".

      if ($nc == 0x003E) { # >
        if ($self->{in_subset}) {
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        } else {
          $self->{state} = DATA_STATE;
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # pi
        redo A;
      } elsif ($nc == 0x003F) { # ?
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no s after target', ## TODO: type
                        line => $self->{line_prev},
                        column => $self->{column_prev}); ## XML5: no error
        $self->{ct}->{data} .= '?';
        $self->{state} = PI_DATA_AFTER_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no s after target', ## TODO: type
                        line => $self->{line_prev},
                        column => $self->{column_prev}
                            + 1 * ($nc == -1)); ## XML5: no error
        $self->{ct}->{data} .= '?'; ## XML5: not appended
        $self->{state} = PI_DATA_STATE;
        ## Reprocess.
        redo A;
      }
    } elsif ($state == PI_DATA_AFTER_STATE) {
      ## XML5: Same as "pi after state" and "DOCTYPE pi after state".

      if ($nc == 0x003E) { # >
        if ($self->{in_subset}) {
          $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        } else {
          $self->{state} = DATA_STATE;
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # pi
        redo A;
      } elsif ($nc == 0x003F) { # ?
        $self->{ct}->{data} .= '?';
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        $self->{ct}->{data} .= '?'; ## XML5: not appended
        $self->{state} = PI_DATA_STATE;
        ## Reprocess.
        redo A;
      }

    } elsif ($state == DOCTYPE_INTERNAL_SUBSET_STATE) {
      if ($nc == 0x003C) { # <
        $self->{state} = DOCTYPE_TAG_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0025) { # %
        ## XML5: Not defined yet.

        ## TODO: parameter entity expansion

        if (not $self->{stop_processing} and
            not $self->{document}->xml_standalone) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'stop processing', ## TODO: type
                          level => $self->{level}->{info});
          $self->{stop_processing} = 1;
        }

        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x005D) { # ]
        delete $self->{in_subset};
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_AFTER_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($is_space->{$nc}) {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed internal subset'); ## TODO: type
        delete $self->{in_subset};
        $self->{state} = DATA_STATE;
        ## Reconsume.
        return  ({type => END_OF_DOCTYPE_TOKEN});
        redo A;
      } else {
        unless ($self->{internal_subset_tainted}) {
          ## XML5: No parse error.
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'string in internal subset');
          $self->{internal_subset_tainted} = 1;
        }
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_INTERNAL_SUBSET_AFTER_STATE) {
      if ($nc == 0x003E) { # >
        $self->{state} = DATA_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ({type => END_OF_DOCTYPE_TOKEN});
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed DOCTYPE');
        $self->{state} = DATA_STATE;
        ## Reconsume.
        return  ({type => END_OF_DOCTYPE_TOKEN});
        redo A;
      } else {
        ## XML5: No parse error and stay in the state.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after internal subset'); ## TODO: type

        $self->{state} = BOGUS_DOCTYPE_INTERNAL_SUBSET_AFTER_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == BOGUS_DOCTYPE_INTERNAL_SUBSET_AFTER_STATE) {
      if ($nc == 0x003E) { # >
        $self->{state} = DATA_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ({type => END_OF_DOCTYPE_TOKEN});
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{state} = DATA_STATE;
        ## Reconsume.
        return  ({type => END_OF_DOCTYPE_TOKEN});
        redo A;
      } else {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_TAG_STATE) {
      if ($nc == 0x0021) { # !
        $self->{state} = DOCTYPE_MARKUP_DECLARATION_OPEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003F) { # ?
        $self->{state} = PI_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare stago');
        $self->{state} = DATA_STATE;
        ## Reconsume.
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare stago', ## XML5: Not a parse error.
                        line => $self->{line_prev},
                        column => $self->{column_prev});
        $self->{state} = BOGUS_COMMENT_STATE;
        $self->{ct} = {type => COMMENT_TOKEN,
                       data => '',
                      }; ## NOTE: Will be discarded.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_MARKUP_DECLARATION_OPEN_STATE) {
      ## XML5: "DOCTYPE markup declaration state".
      
      if ($nc == 0x002D) { # -
        $self->{state} = MD_HYPHEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0045 or # E
               $nc == 0x0065) { # e
        $self->{state} = MD_E_STATE;
        $self->{kwd} = chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0041 or # A
               $nc == 0x0061) { # a
        $self->{state} = MD_ATTLIST_STATE;
        $self->{kwd} = chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x004E or # N
               $nc == 0x006E) { # n
        $self->{state} = MD_NOTATION_STATE;
        $self->{kwd} = chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        #
      }
      
      ## XML5: No parse error.
      $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment',
                      line => $self->{line_prev},
                      column => $self->{column_prev} - 1);
      ## Reconsume.
      $self->{state} = BOGUS_COMMENT_STATE;
      $self->{ct} = {type => COMMENT_TOKEN, data => ''}; ## Will be discarded.
      redo A;
    } elsif ($state == MD_E_STATE) {
      if ($nc == 0x004E or # N
          $nc == 0x006E) { # n
        $self->{state} = MD_ENTITY_STATE;
        $self->{kwd} .= chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x004C or # L
               $nc == 0x006C) { # l
        ## XML5: <!ELEMENT> not supported.
        $self->{state} = MD_ELEMENT_STATE;
        $self->{kwd} .= chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 2
                            + 1 * ($nc == EOF_CHAR));
        ## Reconsume.
        $self->{state} = BOGUS_COMMENT_STATE;
        $self->{ct} = {type => COMMENT_TOKEN, data => ''}; ## Will be discarded
        redo A;
      }
    } elsif ($state == MD_ENTITY_STATE) {
      if ($nc == [
            undef,
            undef,
            0x0054, # T
            0x0049, # I
            0x0054, # T
            NEVER_CHAR, # (Y)
          ]->[length $self->{kwd}] or
          $nc == [
            undef,
            undef,
            0x0074, # t
            0x0069, # i
            0x0074, # t
            NEVER_CHAR, # (y)
          ]->[length $self->{kwd}]) {
        ## Stay in the state.
        $self->{kwd} .= chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ((length $self->{kwd}) == 5 and
               ($nc == 0x0059 or # Y
                $nc == 0x0079)) { # y
        if ($self->{kwd} ne 'ENTIT' or $nc == 0x0079) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'lowercase keyword', ## TODO: type
                          text => 'ENTITY',
                          line => $self->{line_prev},
                          column => $self->{column_prev} - 4);
        }
        $self->{ct} = {type => GENERAL_ENTITY_TOKEN, name => '',
                       line => $self->{line_prev},
                       column => $self->{column_prev} - 6};
        $self->{state} = DOCTYPE_MD_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 1
                            - (length $self->{kwd})
                            + 1 * ($nc == EOF_CHAR));
        $self->{state} = BOGUS_COMMENT_STATE;
        ## Reconsume.
        $self->{ct} = {type => COMMENT_TOKEN, data => ''}; ## Will be discarded
        redo A;
      }
    } elsif ($state == MD_ELEMENT_STATE) {
      if ($nc == [
           undef,
           undef,
           0x0045, # E
           0x004D, # M
           0x0045, # E
           0x004E, # N
           NEVER_CHAR, # (T)
          ]->[length $self->{kwd}] or
          $nc == [
           undef,
           undef,
           0x0065, # e
           0x006D, # m
           0x0065, # e
           0x006E, # n
           NEVER_CHAR, # (t)
          ]->[length $self->{kwd}]) {
        ## Stay in the state.
        $self->{kwd} .= chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ((length $self->{kwd}) == 6 and
               ($nc == 0x0054 or # T
                $nc == 0x0074)) { # t
        if ($self->{kwd} ne 'ELEMEN' or $nc == 0x0074) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'lowercase keyword', ## TODO: type
                          text => 'ELEMENT',
                          line => $self->{line_prev},
                          column => $self->{column_prev} - 5);
        }
        $self->{ct} = {type => ELEMENT_TOKEN, name => '',
                       line => $self->{line_prev},
                       column => $self->{column_prev} - 7};
        $self->{state} = DOCTYPE_MD_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 1
                            - (length $self->{kwd})
                            + 1 * ($nc == EOF_CHAR));
        $self->{state} = BOGUS_COMMENT_STATE;
        ## Reconsume.
        $self->{ct} = {type => COMMENT_TOKEN, data => ''}; ## Will be discarded
        redo A;
      }
    } elsif ($state == MD_ATTLIST_STATE) {
      if ($nc == [
           undef,
           0x0054, # T
           0x0054, # T
           0x004C, # L
           0x0049, # I
           0x0053, # S
           NEVER_CHAR, # (T)
          ]->[length $self->{kwd}] or
          $nc == [
           undef,
           0x0074, # t
           0x0074, # t
           0x006C, # l
           0x0069, # i
           0x0073, # s
           NEVER_CHAR, # (t)
          ]->[length $self->{kwd}]) {
        ## Stay in the state.
        $self->{kwd} .= chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ((length $self->{kwd}) == 6 and
               ($nc == 0x0054 or # T
                $nc == 0x0074)) { # t
        if ($self->{kwd} ne 'ATTLIS' or $nc == 0x0074) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'lowercase keyword', ## TODO: type
                          text => 'ATTLIST',
                          line => $self->{line_prev},
                          column => $self->{column_prev} - 5);
        }
        $self->{ct} = {type => ATTLIST_TOKEN, name => '',
                       attrdefs => [],
                       line => $self->{line_prev},
                       column => $self->{column_prev} - 7};
        $self->{state} = DOCTYPE_MD_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 1
                             - (length $self->{kwd})
                             + 1 * ($nc == EOF_CHAR));
        $self->{state} = BOGUS_COMMENT_STATE;
        ## Reconsume.
        $self->{ct} = {type => COMMENT_TOKEN, data => ''}; ## Will be discarded
        redo A;
      }
    } elsif ($state == MD_NOTATION_STATE) {
      if ($nc == [
           undef,
           0x004F, # O
           0x0054, # T
           0x0041, # A
           0x0054, # T
           0x0049, # I
           0x004F, # O
           NEVER_CHAR, # (N)
          ]->[length $self->{kwd}] or
          $nc == [
           undef,
           0x006F, # o
           0x0074, # t
           0x0061, # a
           0x0074, # t
           0x0069, # i
           0x006F, # o
           NEVER_CHAR, # (n)
          ]->[length $self->{kwd}]) {
        ## Stay in the state.
        $self->{kwd} .= chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ((length $self->{kwd}) == 7 and
               ($nc == 0x004E or # N
                $nc == 0x006E)) { # n
        if ($self->{kwd} ne 'NOTATIO' or $nc == 0x006E) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'lowercase keyword', ## TODO: type
                          text => 'NOTATION',
                          line => $self->{line_prev},
                          column => $self->{column_prev} - 6);
        }
        $self->{ct} = {type => NOTATION_TOKEN, name => '',
                       line => $self->{line_prev},
                       column => $self->{column_prev} - 8};
        $self->{state} = DOCTYPE_MD_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bogus comment',
                        line => $self->{line_prev},
                        column => $self->{column_prev} - 1
                            - (length $self->{kwd})
                            + 1 * ($nc == EOF_CHAR));
        $self->{state} = BOGUS_COMMENT_STATE;
        ## Reconsume.
        $self->{ct} = {type => COMMENT_TOKEN, data => ''}; ## Will be discarded
        redo A;
      }
    } elsif ($state == DOCTYPE_MD_STATE) {
      ## XML5: "DOCTYPE ENTITY state", "DOCTYPE ATTLIST state", and
      ## "DOCTYPE NOTATION state".

      if ($is_space->{$nc}) {
        ## XML5: [NOTATION] Switch to the "DOCTYPE NOTATION identifier state".
        $self->{state} = BEFORE_MD_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($self->{ct}->{type} == GENERAL_ENTITY_TOKEN and 
               $nc == 0x0025) { # %
        ## XML5: Switch to the "DOCTYPE bogus comment state".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before md name'); ## TODO: type
        $self->{state} = DOCTYPE_ENTITY_PARAMETER_BEFORE_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        ## Reconsume.
        redo A;
      } elsif ($nc == 0x003E) { # >
        ## XML5: Switch to the "DOCTYPE bogus comment state".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no md name'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        ## XML5: Switch to the "DOCTYPE bogus comment state".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before md name'); ## TODO: type
        $self->{state} = BEFORE_MD_NAME_STATE;
        redo A;
      }
    } elsif ($state == BEFORE_MD_NAME_STATE) {
      ## XML5: "DOCTYPE ENTITY parameter state", "DOCTYPE ENTITY type
      ## before state", "DOCTYPE ATTLIST name before state".

      if ($is_space->{$nc}) {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($self->{ct}->{type} == GENERAL_ENTITY_TOKEN and 
               $nc == 0x0025) { # %
        $self->{state} = DOCTYPE_ENTITY_PARAMETER_BEFORE_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        ## XML5: Same as "Anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no md name'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        ## Reconsume.
        redo A;
      } else {
        ## XML5: [ATTLIST] Not defined yet.
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ct}->{name} .= $nc == 0x0000 ? "\x{FFFD}" : chr $nc;
        $self->{state} = MD_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_ENTITY_PARAMETER_BEFORE_STATE) {
      if ($is_space->{$nc}) {
        ## XML5: Switch to the "DOCTYPE ENTITY parameter state".
        $self->{ct}->{type} = PARAMETER_ENTITY_TOKEN;
        $self->{state} = BEFORE_MD_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        ## XML5: Same as "Anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no md name'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md');
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        ## Reconsume.
        redo A;
      } else {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space after ENTITY percent'); ## TODO: type
        $self->{state} = BOGUS_COMMENT_STATE;
        $self->{ct} = {type => COMMENT_TOKEN, data => ''}; ## Will be discarded
        ## Reconsume.
        redo A;
      }
    } elsif ($state == MD_NAME_STATE) {
      ## XML5: "DOCTYPE ENTITY name state" and "DOCTYPE ATTLIST name state".
      
      if ($is_space->{$nc}) {
        if ($self->{ct}->{type} == ATTLIST_TOKEN) {
          $self->{state} = DOCTYPE_ATTLIST_NAME_AFTER_STATE;
        } elsif ($self->{ct}->{type} == ELEMENT_TOKEN) {
          $self->{state} = AFTER_ELEMENT_NAME_STATE;
        } else { # ENTITY/NOTATION
          $self->{state} = AFTER_DOCTYPE_NAME_STATE;
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        if ($self->{ct}->{type} == ATTLIST_TOKEN) {
          #
        } else {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'no md def'); ## TODO: type
        }
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ELEMENT/ENTITY/ATTLIST/NOTATION
        redo A;
      } elsif ($nc == EOF_CHAR) {
        ## XML5: [ATTLIST] No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md');
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        ## Reconsume.
        redo A;
      } else {
        ## XML5: [ATTLIST] Not defined yet.
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ct}->{name} .= $nc == 0x0000 ? "\x{FFFD}" : chr $nc;
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_ATTLIST_NAME_AFTER_STATE) {
      if ($is_space->{$nc}) {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST
        redo A;
      } elsif ($nc == EOF_CHAR) {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        ## Discard the current token.
        redo A;
      } else {
        ## XML5: Not defined yet.
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ca} = {name => $nc == 0x0000 ? "\x{FFFD}" : chr $nc, # attrdef
                       tokens => [],
                       line => $self->{line}, column => $self->{column}};
        $self->{state} = DOCTYPE_ATTLIST_ATTRIBUTE_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_ATTLIST_ATTRIBUTE_NAME_STATE) {
      if ($is_space->{$nc}) {
        $self->{state} = DOCTYPE_ATTLIST_ATTRIBUTE_NAME_AFTER_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        ## XML5: Same as "anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no attr type'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST
        redo A;
      } elsif ($nc == 0x0028) { # (
        ## XML5: Same as "anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before paren'); ## TODO: type
        $self->{state} = BEFORE_ALLOWED_TOKEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == EOF_CHAR) {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        ## XML5: Not defined yet.
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ca}->{name} .= $nc == 0x0000 ? "\x{FFFD}" : chr $nc;
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_ATTLIST_ATTRIBUTE_NAME_AFTER_STATE) {
      if ($is_space->{$nc}) {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        ## XML5: Same as "anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no attr type'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST
        redo A;
      } elsif ($nc == 0x0028) { # (
        ## XML5: Same as "anything else".
        $self->{state} = BEFORE_ALLOWED_TOKEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == EOF_CHAR) {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the token.
        redo A;
      } else {
        ## XML5: Not defined yet.
        $self->{ca}->{type} = chr $nc;
        $self->{state} = DOCTYPE_ATTLIST_ATTRIBUTE_TYPE_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_ATTLIST_ATTRIBUTE_TYPE_STATE) {
      if ($is_space->{$nc}) {
        $self->{state} = DOCTYPE_ATTLIST_ATTRIBUTE_TYPE_AFTER_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0023) { # #
        ## XML5: Same as "anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before default value'); ## TODO: type
        $self->{state} = DOCTYPE_ATTLIST_ATTRIBUTE_DECLARATION_BEFORE_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0022) { # "
        ## XML5: Same as "anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before default value'); ## TODO: type
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0027) { # '
        ## XML5: Same as "anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before default value'); ## TODO: type
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        ## XML5: Same as "anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no attr default'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST
        redo A;
      } elsif ($nc == 0x0028) { # (
        ## XML5: Same as "anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before paren'); ## TODO: type
        $self->{state} = BEFORE_ALLOWED_TOKEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == EOF_CHAR) {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the token.
        redo A;
      } else {
        ## XML5: Not defined yet.
        $self->{ca}->{type} .= chr $nc;
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_ATTLIST_ATTRIBUTE_TYPE_AFTER_STATE) {
      if ($is_space->{$nc}) {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0028) { # (
        ## XML5: Same as "anything else".
        $self->{state} = BEFORE_ALLOWED_TOKEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0023) { # #
        $self->{state} = DOCTYPE_ATTLIST_ATTRIBUTE_DECLARATION_BEFORE_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0022) { # "
        ## XML5: Same as "anything else".
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0027) { # '
        ## XML5: Same as "anything else".
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        ## XML5: Same as "anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no attr default'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST
        redo A;
      } elsif ($nc == EOF_CHAR) {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        ## XML5: Switch to the "DOCTYPE bogus comment state".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unquoted attr value'); ## TODO: type
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_UNQUOTED_STATE;
        ## Reconsume.
        redo A;
      }
    } elsif ($state == BEFORE_ALLOWED_TOKEN_STATE) {
      if ($is_space->{$nc}) {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x007C) { # |
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'empty allowed token'); ## TODO: type
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0029) { # )
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'empty allowed token'); ## TODO: type
        $self->{state} = AFTER_ALLOWED_TOKENS_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed allowed tokens'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST
        redo A;
      } elsif ($nc == EOF_CHAR) {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        if ($nc == 0x000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        push @{$self->{ca}->{tokens}}, $nc == 0x0000 ? "\x{FFFD}" : chr $nc;
        $self->{state} = ALLOWED_TOKEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == ALLOWED_TOKEN_STATE) {
      if ($is_space->{$nc}) {
        $self->{state} = AFTER_ALLOWED_TOKEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x007C) { # |
        $self->{state} = BEFORE_ALLOWED_TOKEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0029) { # )
        $self->{state} = AFTER_ALLOWED_TOKENS_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed allowed tokens'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST
        redo A;
      } elsif ($nc == EOF_CHAR) {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ca}->{tokens}->[-1] .= $nc == 0x0000 ? "\x{FFFD}" : chr $nc;
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == AFTER_ALLOWED_TOKEN_STATE) {
      if ($is_space->{$nc}) {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x007C) { # |
        $self->{state} = BEFORE_ALLOWED_TOKEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0029) { # )
        $self->{state} = AFTER_ALLOWED_TOKENS_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed allowed tokens'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST
        redo A;
      } elsif ($nc == EOF_CHAR) {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'space in allowed token', ## TODO: type
                        line => $self->{line_prev},
                        column => $self->{column_prev});
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ca}->{tokens}->[-1] .= ' ' . ($nc == 0x0000 ? "\x{FFFD}" : chr $nc);
        $self->{state} = ALLOWED_TOKEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == AFTER_ALLOWED_TOKENS_STATE) {
      if ($is_space->{$nc}) {
        $self->{state} = BEFORE_ATTR_DEFAULT_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0023) { # #
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before default value'); ## TODO: type
        $self->{state} = DOCTYPE_ATTLIST_ATTRIBUTE_DECLARATION_BEFORE_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0022) { # "
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before default value'); ## TODO: type
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0027) { # '
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before default value'); ## TODO: type
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no attr default'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unquoted attr value'); ## TODO: type
        $self->{state} = ATTRIBUTE_VALUE_UNQUOTED_STATE;
        ## Reconsume.
        redo A;
      }
    } elsif ($state == BEFORE_ATTR_DEFAULT_STATE) {
      if ($is_space->{$nc}) {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0023) { # #
        $self->{state} = DOCTYPE_ATTLIST_ATTRIBUTE_DECLARATION_BEFORE_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0022) { # "
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0027) { # '
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no attr default'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unquoted attr value'); ## TODO: type
        $self->{state} = ATTRIBUTE_VALUE_UNQUOTED_STATE;
        ## Reconsume.
        redo A;
      }
    } elsif ($state == DOCTYPE_ATTLIST_ATTRIBUTE_DECLARATION_BEFORE_STATE) {
      if ($is_space->{$nc}) {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no default type'); ## TODO: type
        $self->{state} = BOGUS_MD_STATE;
        ## Reconsume.
        redo A;
      } elsif ($nc == 0x0022) { # "
        # XXX parse error?
        ## XML5: Same as "anything else".
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0027) { # '
        # XXX parse error?
        ## XML5: Same as "anything else".
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        ## XML5: Same as "anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no attr default'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST
        redo A;
      } elsif ($nc == EOF_CHAR) {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        $self->{ca}->{default} = chr $nc;
        $self->{state} = DOCTYPE_ATTLIST_ATTRIBUTE_DECLARATION_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_ATTLIST_ATTRIBUTE_DECLARATION_STATE) {
      if ($is_space->{$nc}) {
        $self->{state} = DOCTYPE_ATTLIST_ATTRIBUTE_DECLARATION_AFTER_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0022) { # "
        ## XML5: Same as "anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before default value'); ## TODO: type
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0027) { # '
        ## XML5: Same as "anything else".
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before default value'); ## TODO: type
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        ## XML5: Same as "anything else".
        push @{$self->{ct}->{attrdefs}}, $self->{ca};
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST
        redo A;
      } elsif ($nc == EOF_CHAR) {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        push @{$self->{ct}->{attrdefs}}, $self->{ca};
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        $self->{ca}->{default} .= chr $nc;
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_ATTLIST_ATTRIBUTE_DECLARATION_AFTER_STATE) {
      if ($is_space->{$nc}) {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0022) { # "
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_DOUBLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0027) { # '
        $self->{ca}->{value} = '';
        $self->{state} = ATTRIBUTE_VALUE_SINGLE_QUOTED_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        push @{$self->{ct}->{attrdefs}}, $self->{ca};
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST
        redo A;
      } elsif ($nc == EOF_CHAR) {
        ## XML5: No parse error.
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        push @{$self->{ct}->{attrdefs}}, $self->{ca};
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE; ## XML5: "Data state".
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        ## XML5: Not defined yet.
        if ($self->{ca}->{default} eq 'FIXED') {
          $self->{state} = ATTRIBUTE_VALUE_UNQUOTED_STATE;
        } else {
          push @{$self->{ct}->{attrdefs}}, $self->{ca};
          $self->{state} = DOCTYPE_ATTLIST_NAME_AFTER_STATE;
        }
        ## Reconsume.
        redo A;
      }
    } elsif ($state == AFTER_ATTLIST_ATTR_VALUE_QUOTED_STATE) {
      if ($is_space->{$nc} or
          $nc == EOF_CHAR or
          $nc == 0x003E) { # >
        $self->{state} = DOCTYPE_ATTLIST_NAME_AFTER_STATE;
        ## Reconsume.
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no space before attr name'); ## TODO: type
        $self->{state} = DOCTYPE_ATTLIST_NAME_AFTER_STATE;
        ## Reconsume.
        redo A;
      }
    } elsif ($state == NDATA_STATE) {
      ## ASCII case-insensitive
      if ($nc == [
            undef, 
            0x0044, # D
            0x0041, # A
            0x0054, # T
            NEVER_CHAR, # (A)
          ]->[length $self->{kwd}] or
          $nc == [
            undef, 
            0x0064, # d
            0x0061, # a
            0x0074, # t
            NEVER_CHAR, # (a)
          ]->[length $self->{kwd}]) {
        
        ## Stay in the state.
        $self->{kwd} .= chr $nc;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ((length $self->{kwd}) == 4 and
               ($nc == 0x0041 or # A
                $nc == 0x0061)) { # a
        if ($self->{kwd} ne 'NDAT' or $nc == 0x0061) { # a
          
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'lowercase keyword', ## TODO: type
                          text => 'NDATA',
                          line => $self->{line_prev},
                          column => $self->{column_prev} - 4);
        } else {
          
        }
        $self->{state} = AFTER_NDATA_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after literal', ## TODO: type
                        line => $self->{line_prev},
                        column => $self->{column_prev} + 1
                            - length $self->{kwd});
        
        $self->{state} = BOGUS_MD_STATE;
        ## Reconsume.
        redo A;
      }
    } elsif ($state == AFTER_NDATA_STATE) {
      if ($is_space->{$nc}) {
        $self->{state} = BEFORE_NOTATION_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no notation name'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ENTITY
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after literal', ## TODO: type
                        line => $self->{line_prev},
                        column => $self->{column_prev} + 1
                            - length $self->{kwd});
        $self->{state} = BOGUS_MD_STATE;
        ## Reconsume.
        redo A;
      }
    } elsif ($state == BEFORE_NOTATION_NAME_STATE) {
      if ($is_space->{$nc}) {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no notation name'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ENTITY
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ct}->{notation} = $nc == 0x0000 ? "\x{FFFD}" : chr $nc; # ENTITY
        $self->{state} = NOTATION_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == NOTATION_NAME_STATE) {
      if ($is_space->{$nc}) {
        $self->{state} = AFTER_MD_DEF_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ENTITY
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## The current token.
        redo A;
      } else {
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ct}->{notation} .= $nc == 0x0000 ? "\x{FFFD}" : chr $nc; # ENTITY
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_ENTITY_VALUE_DOUBLE_QUOTED_STATE) {
      if ($nc == 0x0022) { # "
        $self->{state} = AFTER_MD_DEF_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0026) { # &
        $self->{prev_state} = $state;
        $self->{state} = ENTITY_VALUE_ENTITY_STATE;
        $self->{entity_add} = 0x0022; # "
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
## TODO: %
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed entity value'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        ## Reconsume.
        ## Discard the current token.
        redo A;
      } else {
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ct}->{value} .= $nc == 0x0000 ? "\x{FFFD}" : chr $nc; # ENTITY
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == DOCTYPE_ENTITY_VALUE_SINGLE_QUOTED_STATE) {
      if ($nc == 0x0027) { # '
        $self->{state} = AFTER_MD_DEF_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0026) { # &
        $self->{prev_state} = $state;
        $self->{state} = ENTITY_VALUE_ENTITY_STATE;
        $self->{entity_add} = 0x0027; # '
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
## TODO: %
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed entity value'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        ## Reconsume.
        ## Discard the current token.
        redo A;
      } else {
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ct}->{value} .= $nc == 0x0000 ? "\x{FFFD}" : chr $nc; # ENTITY
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == ENTITY_VALUE_ENTITY_STATE) {
      if ($is_space->{$nc} or
          {
            0x003C => 1, 0x0026 => 1, (EOF_CHAR) => 1, # <, &
            $self->{entity_add} => 1,
          }->{$nc}) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'bare ero',
                        line => $self->{line_prev},
                        column => $self->{column_prev}
                            + ($nc == EOF_CHAR ? 1 : 0));
        ## Don't consume
        ## Return nothing.
        #
      } elsif ($nc == 0x0023) { # #
        $self->{ca} = $self->{ct};
        $self->{state} = ENTITY_HASH_STATE;
        $self->{kwd} = '#';
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } else {
        #
      }

      $self->{ct}->{value} .= '&';
      $self->{state} = $self->{prev_state};
      ## Reconsume.
      redo A;
    } elsif ($state == AFTER_ELEMENT_NAME_STATE) {
      if ($is_space->{$nc}) {
        $self->{state} = BEFORE_ELEMENT_CONTENT_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0028) { # (
        $self->{state} = AFTER_CM_GROUP_OPEN_STATE;
        $self->{ct}->{content} = ['('];
        $self->{group_depth} = 1;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'no md def'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ELEMENT
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ct}->{content} = [$nc == 0x0000 ? "\x{FFFD}" : chr $nc];
        $self->{state} = CONTENT_KEYWORD_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == CONTENT_KEYWORD_STATE) {
      if ($is_space->{$nc}) {
        $self->{state} = AFTER_MD_DEF_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ELEMENT
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ct}->{content}->[-1] .= $nc == 0x0000 ? "\x{FFFD}" : chr $nc; # ELEMENT
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == AFTER_CM_GROUP_OPEN_STATE) {
      if ($is_space->{$nc}) {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0028) { # (
        $self->{group_depth}++;
        push @{$self->{ct}->{content}}, chr $nc;
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x007C or # |
               $nc == 0x002C) { # ,
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'empty element name'); ## TODO: type
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0029) { # )
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'empty element name'); ## TODO: type
        push @{$self->{ct}->{content}}, chr $nc;
        $self->{group_depth}--;
        $self->{state} = AFTER_CM_GROUP_CLOSE_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed cm group'); ## TODO: type
        push @{$self->{ct}->{content}}, (')') x $self->{group_depth};
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ELEMENT
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        #push @{$self->{ct}->{content}}, (')') x $self->{group_depth};
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        push @{$self->{ct}->{content}}, $nc == 0x0000 ? "\x{FFFD}" : chr $nc;
        $self->{state} = CM_ELEMENT_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == CM_ELEMENT_NAME_STATE) {
      if ($is_space->{$nc}) {
        $self->{state} = AFTER_CM_ELEMENT_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x002A or # *
               $nc == 0x002B or # +
               $nc == 0x003F) { # ?
        push @{$self->{ct}->{content}}, chr $nc;
        $self->{state} = AFTER_CM_ELEMENT_NAME_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x007C or # |
               $nc == 0x002C) { # ,
        push @{$self->{ct}->{content}}, $nc == 0x007C ? ' | ' : ', ';
        $self->{state} = AFTER_CM_GROUP_OPEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0029) { # )
        $self->{group_depth}--;
        push @{$self->{ct}->{content}}, chr $nc;
        $self->{state} = AFTER_CM_GROUP_CLOSE_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed cm group'); ## TODO: type
        push @{$self->{ct}->{content}}, (')') x $self->{group_depth};
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ELEMENT
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        #push @{$self->{ct}->{content}}, (')') x $self->{group_depth};
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the token.
        redo A;
      } else {
        if ($nc == 0x0000) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'NULL');
        }
        $self->{ct}->{content}->[-1] .= $nc == 0x0000 ? "\x{FFFD}" : chr $nc;
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == AFTER_CM_ELEMENT_NAME_STATE) {
      if ($is_space->{$nc}) {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x007C or # |
               $nc == 0x002C) { # ,
        push @{$self->{ct}->{content}}, $nc == 0x007C ? ' | ' : ', ';
        $self->{state} = AFTER_CM_GROUP_OPEN_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0029) { # )
        $self->{group_depth}--;
        push @{$self->{ct}->{content}}, chr $nc;
        $self->{state} = AFTER_CM_GROUP_CLOSE_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed cm group'); ## TODO: type
        push @{$self->{ct}->{content}}, (')') x $self->{group_depth};
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ELEMENT
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        #push @{$self->{ct}->{content}}, (')') x $self->{group_depth};
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'after element name'); ## TODO: type
        push @{$self->{ct}->{content}}, (')') x $self->{group_depth};
        $self->{state} = BOGUS_MD_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } elsif ($state == AFTER_CM_GROUP_CLOSE_STATE) {
      if ($is_space->{$nc}) {
        if ($self->{group_depth}) {
          $self->{state} = AFTER_CM_ELEMENT_NAME_STATE;
        } else {
          $self->{state} = AFTER_MD_DEF_STATE;
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x002A or # *
               $nc == 0x002B or # +
               $nc == 0x003F) { # ?
        push @{$self->{ct}->{content}}, chr $nc;
        if ($self->{group_depth}) {
          $self->{state} = AFTER_CM_ELEMENT_NAME_STATE;
        } else {
          $self->{state} = AFTER_MD_DEF_STATE;
        }
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x0029) { # )
        if ($self->{group_depth}) {
          $self->{group_depth}--;
          push @{$self->{ct}->{content}}, chr $nc;
          ## Stay in the state.
          
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
          redo A;
        } else {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after md def'); ## TODO: type
          $self->{state} = BOGUS_MD_STATE;
          ## Reconsume.
          redo A;
        }
      } elsif ($nc == 0x003E) { # >
        if ($self->{group_depth}) {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed cm group'); ## TODO: type
          push @{$self->{ct}->{content}}, (')') x $self->{group_depth};
        }
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ELEMENT
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        #push @{$self->{ct}->{content}}, (')') x $self->{group_depth};
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        if ($self->{group_depth}) {
          $self->{state} = AFTER_CM_ELEMENT_NAME_STATE;
        } else {
          $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after md def'); ## TODO: type
          $self->{state} = BOGUS_MD_STATE;
        }
        ## Reconsume.
        redo A;
      }
    } elsif ($state == AFTER_MD_DEF_STATE) {
      if ($is_space->{$nc}) {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      } elsif ($nc == 0x003E) { # >
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ENTITY/ELEMENT
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'unclosed md'); ## TODO: type
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        ## Discard the current token.
        redo A;
      } else {
        $self->{parse_error}->(level => $self->{level}->{must}, type => 'string after md def'); ## TODO: type
        $self->{state} = BOGUS_MD_STATE;
        ## Reconsume.
        redo A;
      }
    } elsif ($state == BOGUS_MD_STATE) {
      if ($nc == 0x003E) { # >
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        return  ($self->{ct}); # ATTLIST/ENTITY/NOTATION
        redo A;
      } elsif ($nc == EOF_CHAR) {
        $self->{state} = DOCTYPE_INTERNAL_SUBSET_STATE;
        ## Reconsume.
        ## Discard the current token.
        redo A;
      } else {
        ## Stay in the state.
        
    if ($self->{char_buffer_pos} < length $self->{char_buffer}) {
      $self->{line_prev} = $self->{line};
      $self->{column_prev} = $self->{column};
      $self->{column}++;
      $self->{nc}
          = ord substr ($self->{char_buffer}, $self->{char_buffer_pos}++, 1);
    } else {
      $self->{set_nc}->($self);
    }
  
        redo A;
      }
    } else {
      die "$0: $state: Unknown state";
    }
  } # A   

  die "$0: _get_next_token: unexpected case";
} # _get_next_token

1;

# Copyright 2007-2011 Wakaba <w@suika.fam.cx>.
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.

