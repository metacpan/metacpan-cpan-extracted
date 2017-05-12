#!perl
#
#   Test Inline::Foo module creation
#
#   $Id: 20-Inline-Foo.t 8 2008-12-27 19:16:54Z infidel $
#

use Test::More tests => 13;
use File::Temp qw( tempdir );

###
### VARS
###

my( $obj, $tmpdir, @subs, $modname, $ext );
$modname = 'dongs';

###
### PRECONFIG
###

$tmpdir  = tempdir( 'inl-wrp-testXXXXX', TMPDIR => 1, CLEANUP => 1 );

###
### TESTS
###

# Test: Can we use the module?
BEGIN {
	use_ok( 'Inline::Wrapper' );
}

# Test: default object creation
isa_ok( $obj = Inline::Wrapper->new(
                    language    => 'Foo',
                    base_dir    => $tmpdir,
               ),
        'Inline::Wrapper' );

# Tests: default object output
is( $obj->base_dir(),       $tmpdir, "base directory ($tmpdir)" );
is( $obj->auto_reload(),          0, 'default auto_reload (FALSE)' );
is( $obj->language(),         'Foo', 'language (Foo)' );
is( $ext=$obj->_lang_ext(),  '.foo', 'language extension (.foo)' );

# Create the source file
write_source( $tmpdir, $modname, $ext );

# Tests: Can we load the module and execute its code properly?
is( @subs = $obj->load( $modname ),       1, "Loading of module $modname (1)");
is( $subs[0],                       'test1', 'Function name correct (test1)' );
is( $obj->run( $modname, 'test1', 'arglebargle' ),
                                          1, 'Function ran correctly (TRUE)' );

# Tests: module deletion successful
is( ($obj->modules())[0],            'dongs', 'Module name list correct' );
is( ($obj->functions( 'dongs' ))[0], 'test1', 'Function list correct' );
is( $obj->unload( 'dongs' ),         'dongs', 'Module deletion successful' );
is( $obj->modules(),                       0, 'Module count correct (0)' );

###
### END OF TESTS
###

# Create the source file
sub write_source
{
    my( $tmpdir, $modname, $ext ) = @_;
    my $source = <<'EOS';
foo-sub test1 {
    foo-return $_[0] foo-eq 'arglebargle';
}
EOS
    my $pathchar = ( $^O eq 'MSWin32' ) ? "\\" : '/';
    my $fullpath = join( $pathchar, $tmpdir, $modname . $ext );

    open( my $fd, '>', $fullpath )
        or fail( "Um, weird.  Cannot write to $fullpath; can't finish tests." );
    print $fd $source;
    close( $fd );
}

__END__
