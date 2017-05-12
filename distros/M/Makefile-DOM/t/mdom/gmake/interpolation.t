use t::GmakeDOM;

plan tests => blocks() * 2;

run_tests;

__DATA__

=== TEST 1: variable references in prereq list
--- src

a: foo.c  bar.h	$(baz) # hello!
	@echo ...

--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'a'
    MDOM::Token::Separator    ':'
    MDOM::Token::Whitespace   ' '
    MDOM::Token::Bare         'foo.c'
    MDOM::Token::Whitespace   '  '
    MDOM::Token::Bare         'bar.h'
    MDOM::Token::Whitespace   '\t'
    MDOM::Token::Interpolation   '$(baz)'
    MDOM::Token::Whitespace      ' '
    MDOM::Token::Comment         '# hello!'
    MDOM::Token::Whitespace      '\n'
  MDOM::Command
    MDOM::Token::Separator    '\t'
    MDOM::Token::Modifier     '@'
    MDOM::Token::Bare         'echo ...'
    MDOM::Token::Whitespace   '\n'



=== TEST 2: variable interpolation cannot be escaped by \
--- src
all: ; echo \$a
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare               'all'
    MDOM::Token::Separator          ':'
    MDOM::Token::Whitespace         ' '
    MDOM::Command
      MDOM::Token::Separator        ';'
      MDOM::Token::Whitespace       ' '
      MDOM::Token::Bare             'echo \'
      MDOM::Token::Interpolation    '$a'
      MDOM::Token::Whitespace       '\n'



=== TEST 3: $@, $a, etc.
--- src
all: $a $(a) ${c}
	echo $@ $a ${a} ${abc} ${}
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare               'all'
    MDOM::Token::Separator          ':'
    MDOM::Token::Whitespace         ' '
    MDOM::Token::Interpolation      '$a'
    MDOM::Token::Whitespace         ' '
    MDOM::Token::Interpolation      '$(a)'
    MDOM::Token::Whitespace         ' '
    MDOM::Token::Interpolation      '${c}'
    MDOM::Token::Whitespace         '\n'
  MDOM::Command
    MDOM::Token::Separator          '\t'
    MDOM::Token::Bare               'echo '
    MDOM::Token::Interpolation      '$@'
    MDOM::Token::Bare               ' '
    MDOM::Token::Interpolation      '$a'
    MDOM::Token::Bare               ' '
    MDOM::Token::Interpolation      '${a}'
    MDOM::Token::Bare               ' '
    MDOM::Token::Interpolation      '${abc}'
    MDOM::Token::Bare               ' '
    MDOM::Token::Interpolation      '${}'
    MDOM::Token::Whitespace         '\n'

