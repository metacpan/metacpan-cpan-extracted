use t::GmakeDOM;

plan tests => blocks() * 2;

run_tests;

__DATA__

=== TEST 1: single-line comment
--- src

# This is a comment

--- dom
M::D::G
  M::T::C           '# This is a comment'
  M::T::W           '\n'



=== TEST 2: comment indented by spaces
--- src
   # comment indented by spaces

--- dom
M::D::G
  M::T::W       '   '
  M::T::C       '# comment indented by spaces'
  M::T::W       '\n'



=== TEST 3:
--- src

foo.o : foo.c defs.h   # module for twiddling the frobs
	cc -c -g foo.c

--- dom
M::D::G
  M::R::S
    M::T::B             'foo.o'
    M::T::W             ' '
    M::T::S             ':'
    M::T::W             ' '
    M::T::B             'foo.c'
    M::T::W             ' '
    M::T::B             'defs.h'
    M::T::W             '   '
    M::T::C             '# module for twiddling the frobs'
    M::T::W             '\n'
  M::C
    M::T::S             '\t'
    M::T::B             'cc -c -g foo.c'
    M::T::W             '\n'



=== TEST 4: comments indented by a tab outside the "rule context"
--- src
	# This is a comment rather than a command
--- dom
M::D::G
  M::T::W       '\t'
  M::T::C       '# This is a comment rather than a command'
  M::T::W       '\n'




=== TEST 5: comments indented by a tab within the "rule context"
--- src

foo : bar
	# This is a shell command

--- dom
M::D::G
  M::R::S
    M::T::B         'foo'
    M::T::W         ' '
    M::T::S         ':'
    M::T::W         ' '
    M::T::B         'bar'
    M::T::W         '\n'
  M::C
    M::T::S       '\t'
    M::T::B       '# This is a shell command'
    M::T::W       '\n'



=== TEST 6: line continuations in comments
--- src

a: b # hello! \
	this is comment too! \
 so is this line

	# this is a cmd
	+touch $$

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare           'a'
    MDOM::Token::Separator      ':'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Bare           'b'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Comment        '# hello! \\n\tthis is comment too! \\n so is this line'
    MDOM::Token::Whitespace     '\n'
  MDOM::Token::Whitespace       '\n'
  MDOM::Command
    MDOM::Token::Separator      '\t'
    MDOM::Token::Bare           '# this is a cmd'
    MDOM::Token::Whitespace     '\n'
  MDOM::Command
    MDOM::Token::Separator      '\t'
    MDOM::Token::Modifier       '+'
    MDOM::Token::Bare           'touch '
    MDOM::Token::Interpolation  '$$'
    MDOM::Token::Whitespace     '\n'



=== TEST 7: unescaped '#'
--- src
all: foo\\# hello
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare           'all'
    MDOM::Token::Separator      ':'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Bare           'foo\\'
    MDOM::Token::Comment        '# hello'
    MDOM::Token::Whitespace     '\n'



=== TEST 8: when no space between words and '#'
--- src
bar: foo#hello
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare           'bar'
    MDOM::Token::Separator      ':'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Bare           'foo'
    MDOM::Token::Comment        '#hello'
    MDOM::Token::Whitespace     '\n'



=== TEST 9: '#' escaped by '\'
--- src

\#a: \#b \#c

--- dom
M::D::G
  M::R::S
    M::T::B             '\#a'
    M::T::S             ':'
    M::T::W             ' '
    M::T::B             '\#b'
    M::T::W             ' '
    M::T::B             '\#c'
    M::T::W             '\n'



=== TEST 10: standalone single-line comment
--- src
# hello
#world!
--- dom
MDOM::Document::Gmake
  MDOM::Token::Comment    '# hello'
  MDOM::Token::Whitespace '\n'
  MDOM::Token::Comment    '#world!'
  MDOM::Token::Whitespace '\n'



=== TEST 11: standalone multi-line comment
--- src
# hello \
	world\
    !
--- dom
MDOM::Document::Gmake
  MDOM::Token::Comment    '# hello \\n\tworld\\n    !'
  MDOM::Token::Whitespace '\n'



=== TEST 12: comments indented by a tab
--- src
	# blah
--- dom
MDOM::Document::Gmake
  MDOM::Token::Whitespace    '\t'
  MDOM::Token::Comment       '# blah'
  MDOM::Token::Whitespace    '\n'



=== TEST 13: multi-line comment indented with tabs
--- src
	# blah \
hello!\
	# hehe
--- dom
MDOM::Document::Gmake
  MDOM::Token::Whitespace    '\t'
  MDOM::Token::Comment       '# blah \\nhello!\\n\t# hehe'
  MDOM::Token::Whitespace    '\n'




