use t::GmakeDOM;

plan tests => blocks() * 2;

run_tests;

__DATA__

=== TEST 13: export + assignment (:=)
--- src

export foo := 32

--- dom
MDOM::Document::Gmake
  MDOM::Directive
    MDOM::Token::Bare         'export'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'foo'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Separator            ':='
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         '32'
    MDOM::Token::Whitespace           '\n'




