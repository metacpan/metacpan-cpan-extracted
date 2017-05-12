#!perl
#
#   Test Inline::Lua module creation
#
#   $Id: 23-Inline-Ruby.t 8 2008-12-27 19:16:54Z infidel $
#

use Test::More tests => 10;
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
                    base_dir    => $tmpdir,
               ),
        'Inline::Wrapper' );

# Tests: default object output
is( $obj->base_dir(),       $tmpdir, "base directory ($tmpdir)" );
is( $obj->auto_reload(),          0, 'default auto_reload (FALSE)' );
is( $obj->add_language( 'Ruby' => '.rb' ),
                             'Ruby', 'add language (Ruby)' );
is( $obj->set_language( 'Ruby' ),
                             'Ruby', 'set_language (Ruby)' );
is( $ext=$obj->_lang_ext(),   '.rb', 'language extension (.rb)' );

# Create the source file
write_source( $tmpdir, $modname, $ext );

SKIP: {
    eval { require Inline::Ruby; };

    skip "Inline::Ruby not installed.", 3 if $@;

# Tests: Can we load the module and execute its code properly?
is( @subs = $obj->load( $modname ),       1, "Loading of module $modname (1)");
is( $subs[0],                      'zamfir', 'Function name correct (zamfir)' );
is( ($obj->run( $modname, 'zamfir', 2, 3 ))[0],
                                         25, 'Function ran correctly (25)' );

}

####################
### END OF TESTS ###
####################

# Create the source file
sub write_source
{
    my( $tmpdir, $modname, $ext ) = @_;
    my $source = <<'EOS';
def zamfir( num1, num2 )
    return num1 * 14 - num2
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
