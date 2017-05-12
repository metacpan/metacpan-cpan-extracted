#!perl
#
#   Test Inline::Foo module creation
#
#   $Id: 21-Inline-C.t 8 2008-12-27 19:16:54Z infidel $
#

use Test::More tests => 9;
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
                    language    => 'C',
                    base_dir    => $tmpdir,
               ),
        'Inline::Wrapper' );

# Tests: default object output
is( $obj->base_dir(),       $tmpdir, "base directory ($tmpdir)" );
is( $obj->auto_reload(),          0, 'default auto_reload (FALSE)' );
is( $obj->language(),           'C', 'language (C)' );
is( $ext=$obj->_lang_ext(),    '.c', 'language extension (.c)' );

# Create the source file
write_source( $tmpdir, $modname, $ext );

SKIP: {
    eval { require Inline::C };
    skip 'Inline::C not installed?  Weird.', 3 if $@;

# Tests: Can we load the module and execute its code properly?
is( @subs = $obj->load( $modname ),       1, "Loading of module $modname (1)");
is( $subs[0],                       'slurm', 'Function name correct (slurm)' );
is( ($obj->run( $modname, 'slurm', 15, 12 ))[0],
                                         42, 'Function ran correctly (42)' );
}

###
### END OF TESTS
###

# Create the source file
sub write_source
{
    my( $tmpdir, $modname, $ext ) = @_;
    my $source = <<'EOS';
int slurm( int foo, int bar ) {
    return foo * 2 + bar;
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
