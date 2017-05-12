use t::GmakeDOM;

plan tests => blocks() * 2;

run_tests;

__DATA__

=== TEST 1: unknown entities
--- src

a $(foo)
	echo $@

--- dom
MDOM::Document::Gmake
  MDOM::Unknown
    MDOM::Token::Bare               'a '
    MDOM::Token::Interpolation      '$(foo)'
    MDOM::Token::Whitespace         '\n'
  MDOM::Unknown
    MDOM::Token::Bare               '\techo '
    MDOM::Token::Interpolation      '$@'
    MDOM::Token::Whitespace         '\n'




