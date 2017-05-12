use t::GmakeDOM;

plan tests => blocks() * 2;

run_tests;

__DATA__

=== TEST 1: multi-line var assignment (the 'define' directive)
--- src

define remote-file
  $(if $(filter unix, $($1.type)), \
    /net/$($1.host)/$($1.path), \
    //$($1.host)/$($1.path))
endef

--- dom
MDOM::Document::Gmake
  MDOM::Directive
    MDOM::Token::Bare         'define'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'remote-file'
    MDOM::Token::Whitespace           '\n'
  MDOM::Unknown
    MDOM::Token::Bare             '  '
    MDOM::Token::Interpolation '$(if $(filter unix, $($1.type)), \\n    /net/$($1.host)/$($1.path), \\n    //$($1.host)/$($1.path))'
    MDOM::Token::Whitespace           '\n'
  MDOM::Directive
    MDOM::Token::Bare         'endef'
    MDOM::Token::Whitespace           '\n'




