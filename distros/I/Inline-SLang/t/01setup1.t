# -*-perl-*-
#
# $Id: 01setup1.t,v 1.2 2005/01/03 21:09:27 dburke Exp $
#
# Test that Inline::SLang works with SETUP => 'slsh'.
#

use strict;

my $loaded = 0;
BEGIN {
    # So that we can test the "initialise as slsh" code,
    # we set up the environment to look for the initialisation
    # files in the test directory.
    #
    use FindBin;

    # Should we use Bin rather than RealBin?
    $ENV{SLSH_PATH}     = $FindBin::RealBin;
    $ENV{SLSH_CONF_DIR} = $FindBin::RealBin;
    $ENV{HOME}          = $FindBin::RealBin;

    use Test::More tests => 5;
}
END   { fail( "Able to 'use Inline SLang'" ) unless $loaded; }

## Tests

use Inline 'SLang' => Config => SETUP => 'slsh';
use Inline 'SLang';
pass( "Able to 'use Inline SLang'" );
$loaded = 1;

my $counter = Inline::SLang::sl_setup_called();
is ( $counter, 1, "The slsh initialization code has been called once" );

my $path = get_path();
is ( $path, $FindBin::RealBin, "library path is set correctly" );

# Test that the slsh.rc and .slshrc files from the test
# directory have been evaluated.
#
ok ( is_user_variable_defined( "system_rc_called" ),
     "  system (slsh.rc) file evaluated" );
ok ( is_user_variable_defined( "user_rc_called" ),
     "  user (.slshrc) file evaluated" );

__END__
__SLang__

define get_path () {
  return get_slang_load_path();
}

define is_user_variable_defined(name) {
    return -2 == is_defined (name);
}

