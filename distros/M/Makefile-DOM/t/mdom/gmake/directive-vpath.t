use t::GmakeDOM;

plan tests => blocks() * 2;

run_tests;

__DATA__

=== TEST 1:
--- src

vpath %.c src:../headers
vpath   %.d
vpath

--- dom
M::D::G
  M::D
    M::T::B       'vpath'
    M::T::W       ' '
    M::T::B       '%.c'
    M::T::W       ' '
    M::T::B       'src'
    M::T::S         ':'
    M::T::B         '../headers'
    M::T::W       '\n'
  M::D
    M::T::B       'vpath'
    M::T::W       '   '
    M::T::B       '%.d'
    M::T::W       '\n'
  M::D
    M::T::B     'vpath'
    M::T::W     '\n'



=== TEST 1: the vpath directive
--- src

vpath %.1 %.c src
  vpath %h include

--- dom
MDOM::Document::Gmake
  MDOM::Directive
    MDOM::Token::Bare         'vpath'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         '%.1'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare           '%.c'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'src'
    MDOM::Token::Whitespace           '\n'
  MDOM::Directive
    MDOM::Token::Whitespace          '  '
    MDOM::Token::Bare                'vpath'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Bare                '%h'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Bare                'include'
    MDOM::Token::Whitespace          '\n'



=== TEST 2: multi-line vpath directive
--- src

vpath %.1 %.c src \
    %h include

--- dom
MDOM::Document::Gmake
  MDOM::Directive
    MDOM::Token::Bare         'vpath'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         '%.1'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare           '%.c'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Bare         'src'
    MDOM::Token::Whitespace           ' '
    MDOM::Token::Continuation                '\\n'
    MDOM::Token::Whitespace          '    '
    MDOM::Token::Bare                '%h'
    MDOM::Token::Whitespace          ' '
    MDOM::Token::Bare                'include'
    MDOM::Token::Whitespace          '\n'




