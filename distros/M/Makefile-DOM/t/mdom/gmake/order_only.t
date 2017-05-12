use t::GmakeDOM;

plan tests => 2 * blocks();

run_tests;

__DATA__

=== TEST 1:
--- src
foo:|bar;
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'foo'
    MDOM::Token::Separator            ':'
    MDOM::Token::Bare            '|'
    MDOM::Token::Bare         'bar'
    MDOM::Command
      MDOM::Token::Separator          ';'
      MDOM::Token::Whitespace         '\n'



=== TEST 2:
--- src
foo: a b| c d
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'foo'
    MDOM::Token::Separator            ':'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'a'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'b'
    MDOM::Token::Bare         '|'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'c'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'd'
    MDOM::Token::Whitespace           '\n'



=== TEST 3:
--- src
foo: a|
--- dom
MDOM::Document::Gmake
  MDOM::Rule::Simple
    MDOM::Token::Bare         'foo'
    MDOM::Token::Separator            ':'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'a'
    MDOM::Token::Bare         '|'
    MDOM::Token::Whitespace           '\n'

