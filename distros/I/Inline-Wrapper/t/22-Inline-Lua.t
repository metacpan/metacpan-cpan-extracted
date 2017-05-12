#!perl
#
#   Test Inline::Lua module creation
#
#   $Id: 22-Inline-Lua.t 8 2008-12-27 19:16:54Z infidel $
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
                    language    => 'Lua',
                    base_dir    => $tmpdir,
               ),
        'Inline::Wrapper' );

# Tests: default object output
is( $obj->base_dir(),       $tmpdir, "base directory ($tmpdir)" );
is( $obj->auto_reload(),          0, 'default auto_reload (FALSE)' );
is( $obj->language(),         'Lua', 'language (Lua)' );
is( $ext=$obj->_lang_ext(),  '.lua', 'language extension (.lua)' );

# Create the source file
write_source( $tmpdir, $modname, $ext );

SKIP: {
    eval { require Inline::Lua; };

    skip "Inline::Lua not installed.", 3 if $@;

# Tests: Can we load the module and execute its code properly?
is( @subs = $obj->load( $modname ),       1, "Loading of module $modname (1)");
is( $subs[0],                       'power', 'Function name correct (power)' );
is( ($obj->run( $modname, 'power', 2, 3 ))[0],
                                          8, 'Function ran correctly (8)' );
}

####################
### END OF TESTS ###
####################

# Create the source file
sub write_source
{
    my( $tmpdir, $modname, $ext ) = @_;
    my $source = <<'EOS';
function power( mantissa, exponent )
    return( mantissa^exponent )
end
EOS
    my $pathchar = ( $^O eq 'MSWin32' ) ? "\\" : '/';
    my $fullpath = join( $pathchar, $tmpdir, $modname . $ext );
    open( my $fd, '>', $fullpath )
        or fail( "Um, weird.  Cannot write to $fullpath; can't finish tests." );
    print $fd $source;
    close( $fd );
}

__END__
