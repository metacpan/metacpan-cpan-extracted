use t::GmakeDOM;

plan tests => blocks() * 2;

run_tests;

__DATA__

=== TEST 1: the include directive
--- src
include foo *.mk $(bar)
--- dom
MDOM::Document::Gmake
  MDOM::Directive
    MDOM::Token::Bare         'include'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'foo'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         '*.mk'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Interpolation                '$(bar)'
    MDOM::Token::Whitespace           '\n'



=== TEST 2: multi-line include directive
--- src
include foo *.mk $(bar) \
    blah blah
--- dom
MDOM::Document::Gmake
  MDOM::Directive
    MDOM::Token::Bare         'include'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'foo'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         '*.mk'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Interpolation                '$(bar)'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Continuation                '\\n'
    MDOM::Token::Whitespace          '    '
    MDOM::Token::Bare                'blah'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Bare                'blah'
    MDOM::Token::Whitespace           '\n'



=== TEST 3: the -include directive
--- src

-include filenames...

--- dom
MDOM::Document::Gmake
  MDOM::Directive
    MDOM::Token::Modifier             '-'
    MDOM::Token::Bare          'include'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Bare          'filenames...'
    MDOM::Token::Whitespace           '\n'



=== TEST 4: multi-line -include directive
--- src

-include foo bar \
    $@ $^

--- dom
MDOM::Document::Gmake
  MDOM::Directive
    MDOM::Token::Modifier             '-'
    MDOM::Token::Bare          'include'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Bare          'foo'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Bare          'bar'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Continuation                '\\n'
    MDOM::Token::Whitespace    '    '
    MDOM::Token::Interpolation         '$@'
    MDOM::Token::Whitespace    ' '
    MDOM::Token::Interpolation         '$^'
    MDOM::Token::Whitespace           '\n'



=== TEST 5: sinclude directive
sinclude is another name for -include
--- src

sinclude  %.c src

--- dom
M::D::G
  M::D
    M::T::B             'sinclude'
    M::T::W             '  '
    M::T::B             '%.c'
    M::T::W             ' '
    M::T::B             'src'
    M::T::W             '\n'

