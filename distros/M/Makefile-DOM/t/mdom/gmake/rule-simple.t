use t::GmakeDOM;

plan tests => blocks() * 2;

run_tests;

__DATA__

=== TEST 1: "hello world" one-linner (with whitespace)
--- src

all : ; echo "hello, world"

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'all'
    MDOM::Token::Whitespace   ' '
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace   ' '
    MDOM::Command
      MDOM::Token::Separator    ';'
      MDOM::Token::Whitespace   ' '
      MDOM::Token::Bare         'echo "hello, world"'
      MDOM::Token::Whitespace   '\n'



=== TEST 2: "hello world" one-linner (without whitespace)
--- src

all:;echo "hello, world"

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'all'
    MDOM::Token::Separator    ':'
    MDOM::Command
      MDOM::Token::Separator    ';'
      MDOM::Token::Bare         'echo "hello, world"'
      MDOM::Token::Whitespace   '\n'



=== TEST 3: "hello world" makefile
--- src

all:
	echo "hello, world"

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'all'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace   '\n'
  MDOM::Command
    MDOM::Token::Separator    '\t'
    MDOM::Token::Bare         'echo "hello, world"'
    MDOM::Token::Whitespace   '\n'



=== TEST 4: multiple commands
--- src

all  :
	pwd
	cp t/a t/b
	perl -e 'print "hello, world!\n"'

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare           'all'
    MDOM::Token::Whitespace     '  '
    MDOM::Token::Separator      ':'
    MDOM::Token::Whitespace     '\n'
  MDOM::Command
    MDOM::Token::Separator      '\t'
    MDOM::Token::Bare           'pwd'
    MDOM::Token::Whitespace     '\n'
  MDOM::Command
    MDOM::Token::Separator      '\t'
    MDOM::Token::Bare           'cp t/a t/b'
    MDOM::Token::Whitespace     '\n'
  MDOM::Command
    MDOM::Token::Separator      '\t'
    MDOM::Token::Bare           'perl -e \'print "hello, world!\n"\''
    MDOM::Token::Whitespace     '\n'



=== TEST 5: simple rule with an empty command
--- src

a: b ;

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare           'a'
    MDOM::Token::Separator      ':'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Bare           'b'
    MDOM::Token::Whitespace     ' '
    MDOM::Command
      MDOM::Token::Separator    ';'
      MDOM::Token::Whitespace   '\n'



=== TEST 6: simple rule without any commands
--- src

a : b

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare           'a'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Separator      ':'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Bare           'b'
    MDOM::Token::Whitespace     '\n'



=== TEST 7: weird target/prereq names
--- src

@a: @b @c+!

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare           '@a'
    MDOM::Token::Separator      ':'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Bare           '@b'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Bare           '@c+!'
    MDOM::Token::Whitespace     '\n'



=== TEST 8: line continuations in prereq list and weird target names
--- src

@a:\
	 @b   @c

@b : ;
@c:;;

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare          '@a'
    MDOM::Token::Separator     ':'
    MDOM::Token::Continuation  '\\n'
    MDOM::Token::Whitespace    '\t '
    MDOM::Token::Bare          '@b'
    MDOM::Token::Whitespace    '   '
    MDOM::Token::Bare          '@c'
    MDOM::Token::Whitespace    '\n'
  MDOM::Token::Whitespace      '\n'
  MDOM::Rule::Simple
    MDOM::Token::Bare          '@b'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Separator     ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Command
      MDOM::Token::Separator   ';'
      MDOM::Token::Whitespace  '\n'
  MDOM::Rule::Simple
    MDOM::Token::Bare          '@c'
    MDOM::Token::Separator     ':'
    MDOM::Command
      MDOM::Token::Separator   ';'
      MDOM::Token::Bare        ';'
      MDOM::Token::Whitespace  '\n'



=== TEST 9: line continuations in prereq list
--- src

a: \
	b\
    c \
    d

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare           'a'
    MDOM::Token::Separator      ':'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Continuation   '\\n'
    MDOM::Token::Whitespace     '\t'
    MDOM::Token::Bare           'b'
    MDOM::Token::Continuation   '\\n'
    MDOM::Token::Whitespace     '    '
    MDOM::Token::Bare           'c'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Continuation   '\\n'
    MDOM::Token::Whitespace     '    '
    MDOM::Token::Bare           'd'
    MDOM::Token::Whitespace     '\n'



=== TEST 10: suffix (-like) rules
--- src

.SUFFIXES:

.c.o:
	echo "hello $<!"

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         '.SUFFIXES'
    MDOM::Token::Separator            ':'
    MDOM::Token::Whitespace           '\n'
  MDOM::Token::Whitespace             '\n'
  MDOM::Rule::Simple
    MDOM::Token::Bare                 '.c.o'
    MDOM::Token::Separator            ':'
    MDOM::Token::Whitespace           '\n'
  MDOM::Command
    MDOM::Token::Separator            '\t'
    MDOM::Token::Bare         'echo "hello '
    MDOM::Token::Interpolation                '$<'
    MDOM::Token::Bare         '!"'
    MDOM::Token::Whitespace           '\n'



=== TEST 11: special targets:
--- src

.SECONDEXPAN:

/tmp/foo.o:

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         '.SECONDEXPAN'
    MDOM::Token::Separator            ':'
    MDOM::Token::Whitespace           '\n'
  MDOM::Token::Whitespace             '\n'
  MDOM::Rule::Simple
    MDOM::Token::Bare         '/tmp/foo.o'
    MDOM::Token::Separator            ':'
    MDOM::Token::Whitespace           '\n'




