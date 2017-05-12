use t::GmakeDOM;

plan tests => blocks() * 2;

run_tests;

__DATA__

=== TEST 1: static pattern rules with ";" command
--- src

foo.o bar.o: %.o: %.c ; echo blah

%.c: ; echo $@

--- dom
MDOM::Document::Gmake
  MDOM::Rule::StaticPattern
    MDOM::Token::Bare           'foo.o'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Bare           'bar.o'
    MDOM::Token::Separator      ':'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Bare           '%.o'
    MDOM::Token::Separator      ':'
    MDOM::Token::Whitespace     ' '
    MDOM::Token::Bare           '%.c'
    MDOM::Token::Whitespace     ' '
    MDOM::Command
      MDOM::Token::Separator    ';'
      MDOM::Token::Whitespace   ' '
      MDOM::Token::Bare         'echo blah'
      MDOM::Token::Whitespace   '\n'
  MDOM::Token::Whitespace       '\n'
  MDOM::Rule::Simple
    MDOM::Token::Bare           '%.c'
    MDOM::Token::Separator      ':'
    MDOM::Token::Whitespace     ' '
    MDOM::Command
      MDOM::Token::Separator    ';'
      MDOM::Token::Whitespace   ' '
      MDOM::Token::Bare         'echo '
      MDOM::Token::Interpolation    '$@'
      MDOM::Token::Whitespace       '\n'



=== TEST 2: static pattern rules without ";" commands
--- src

foo.o bar.o: %.o: %.c
	@echo blah

--- dom
MDOM::Document::Gmake
  MDOM::Rule::StaticPattern
    MDOM::Token::Bare          'foo.o'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Bare          'bar.o'
    MDOM::Token::Separator     ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Bare          '%.o'
    MDOM::Token::Separator     ':'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Bare          '%.c'
    MDOM::Token::Whitespace    '\n'
  MDOM::Command
    MDOM::Token::Separator     '\t'
    MDOM::Token::Modifier      '@'
    MDOM::Token::Bare          'echo blah'
    MDOM::Token::Whitespace    '\n'



