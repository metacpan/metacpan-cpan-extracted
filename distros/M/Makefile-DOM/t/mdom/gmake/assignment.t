use t::GmakeDOM;

plan tests => blocks() * 2;

run_tests;

__DATA__

=== TEST 1: recursively expanded variable setting
--- src

foo = bar

--- dom
MDOM::Document::Gmake
  MDOM::Assignment
    MDOM::Token::Bare         'foo'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Separator            '='
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'bar'
    MDOM::Token::Whitespace           '\n'



=== TEST 2: recursively expanded variable setting (more complex)
--- src

$(foo) = baz $(hey)

--- dom
MDOM::Document::Gmake
  MDOM::Assignment
    MDOM::Token::Interpolation        '$(foo)'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Separator            '='
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'baz'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Interpolation        '$(hey)'
    MDOM::Token::Whitespace           '\n'



=== TEST 3: var assignment changed the "rule context" to VOID
--- src
a: b
foo = bar
	# hello!
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'a'
    MDOM::Token::Separator            ':'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'b'
    MDOM::Token::Whitespace           '\n'
  MDOM::Assignment
    MDOM::Token::Bare         'foo'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Separator            '='
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'bar'
    MDOM::Token::Whitespace           '\n'
  MDOM::Token::Whitespace            '\t'
  MDOM::Token::Comment               '# hello!'
  MDOM::Token::Whitespace            '\n'



=== TEST 4: assignment indented by a tab which is not in the "rule context"
--- src

	foo = bar # this line begins with a tab

--- dom
M::D::G
  MDOM::Assignment
    MDOM::Token::Whitespace     '\t'
    MDOM::Token::Bare         'foo'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Separator            '='
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'bar'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Comment             '# this line begins with a tab'
    MDOM::Token::Whitespace           '\n'



=== TEST 5: simply-expanded var assignment
--- src

a := $($($(x)))

--- dom
MDOM::Document::Gmake
  MDOM::Assignment
    MDOM::Token::Bare         'a'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Separator            ':='
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Interpolation                '$($($(x)))'
    MDOM::Token::Whitespace           '\n'



=== TEST 6: multi-line var assignment (recursively-expanded)
--- src

SOURCES = count_words.c \
          lexer.c	\
		counter.c
--- dom
MDOM::Document::Gmake
  MDOM::Assignment
    MDOM::Token::Bare         'SOURCES'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Separator            '='
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'count_words.c'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Continuation         '\\n'
    MDOM::Token::Whitespace           '          '
    MDOM::Token::Bare         'lexer.c'
    MDOM::Token::Whitespace           '\t'
    MDOM::Token::Continuation         '\\n'
    MDOM::Token::Whitespace           '\t\t'
    MDOM::Token::Bare         'counter.c'
    MDOM::Token::Whitespace           '\n'



=== TEST 7: multi-line var assignment (simply-expanded)
--- src

SOURCES := count_words.c \
          lexer.c	\
		counter.c
--- dom
MDOM::Document::Gmake
  MDOM::Assignment
    MDOM::Token::Bare         'SOURCES'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Separator            ':='
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'count_words.c'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Continuation         '\\n'
    MDOM::Token::Whitespace           '          '
    MDOM::Token::Bare         'lexer.c'
    MDOM::Token::Whitespace           '\t'
    MDOM::Token::Continuation         '\\n'
    MDOM::Token::Whitespace           '\t\t'
    MDOM::Token::Bare         'counter.c'
    MDOM::Token::Whitespace           '\n'



=== TEST 8: other assignment variations (simply-expanded)
--- src

override foo := 32

--- dom
MDOM::Document::Gmake
  MDOM::Assignment
    MDOM::Token::Bare         'override'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'foo'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Separator            ':='
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         '32'
    MDOM::Token::Whitespace           '\n'



=== TEST 9: override + assignment (=)
--- src

override foo = 32

--- dom
MDOM::Document::Gmake
  MDOM::Assignment
    MDOM::Token::Bare         'override'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'foo'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Separator            '='
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         '32'
    MDOM::Token::Whitespace           '\n'



=== TEST 10: override + assignment (:=)
--- src

override foo := 32

--- dom
MDOM::Document::Gmake
  MDOM::Assignment
    MDOM::Token::Bare         'override'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'foo'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Separator            ':='
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         '32'
    MDOM::Token::Whitespace           '\n'



=== TEST 11: override + assignment (+=)
--- src

override CFLAGS += $(patsubst %,-I%,$(subst :, ,$(VPATH)))

--- dom
MDOM::Document::Gmake
  MDOM::Assignment
    MDOM::Token::Bare                'override'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Bare                'CFLAGS'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Separator           '+='
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Interpolation       '$(patsubst %,-I%,$(subst :, ,$(VPATH)))'
    MDOM::Token::Whitespace          '\n'



=== TEST 12: override + assignment (?=)
--- src

override files ?=  main.o kbd.o command.o display.o \
            insert.o search.o files.o utils.o

--- dom
MDOM::Document::Gmake
  MDOM::Assignment
    MDOM::Token::Bare                'override'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Bare                'files'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Separator           '?='
    MDOM::Token::Whitespace          '  '
    MDOM::Token::Bare                'main.o'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Bare                'kbd.o'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Bare                'command.o'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Bare                'display.o'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Continuation                '\\n'
    MDOM::Token::Whitespace          '            '
    MDOM::Token::Bare                'insert.o'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Bare                'search.o'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Bare                'files.o'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Bare                'utils.o'
    MDOM::Token::Whitespace          '\n'




