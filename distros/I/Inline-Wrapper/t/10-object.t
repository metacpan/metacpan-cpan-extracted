#!perl -T
#
#   Test basic object functionality
#
#   $Id: 10-object.t 8 2008-12-27 19:16:54Z infidel $
#

use Test::More tests => 16;

BEGIN {
	use_ok( 'Inline::Wrapper' );
}

my( $obj );

# Test: default object creation
isa_ok( $obj = Inline::Wrapper->new(),          'Inline::Wrapper' );

# Tests: default object output
is( $obj->base_dir(),       '.', 'default base directory (.)' );
is( $obj->auto_reload(),      0, 'default auto_reload (FALSE)' );
is( $obj->language(),     'Lua', 'default language (Lua)' );
is( @{ $obj->modules() },     0, 'default module list (empty)' );
is( $obj->_lang_ext(),   '.lua', 'default language extension (.lua)' );

# Test: custom object creation
isa_ok( $obj = Inline::Wrapper->new(
                   language     => 'C',
                   auto_reload  => 'florf',         # a true value
                   base_dir     => '/tmp/dongs',
               ),
        'Inline::Wrapper' );

# Tests: custom object output
is( $obj->base_dir(),    '/tmp/dongs', 'custom base directory (/tmp/dongs)' );
is( $obj->auto_reload(),            1, 'custom auto_reload (TRUE)' );
is( $obj->language(),             'C', 'custom language (C)' );
is( @{ $obj->modules() },           0, 'default module list (empty)' );
is( $obj->_lang_ext(),           '.c', 'custom language extension (.c)' );

# Tests: Create and set custom language
is( $obj->add_language( 'Esperanto' => '.esp' ),
                          'Esperanto', 'custom language addition (Esperanto)');
is( $obj->set_language( 'Esperanto' ),
                          'Esperanto', 'custom language set (Esperanto)' );
is( $obj->_lang_ext(),         '.esp', 'custom language extension (.esp)' );

__END__
