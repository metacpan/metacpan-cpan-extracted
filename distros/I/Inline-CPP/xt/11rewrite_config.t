use strict;
use warnings;

# To enable this suite one must set the RELEASE_TESTING to a true value.
# This prevents author tests from running on a user install.

# This test forces a rewrite of the Inline configuration file.  We don't want
# to do that to a user unnecessarily, so we skip unless RELEASE_TESTING.

BEGIN { 
    use Test::More;
    if ( $ENV{RELEASE_TESTING} ) {
        # Set up release testing environment.
        use Inline CPP => config => rewrite_config_file => 1;
    }
    else {
        my $msg =
            'Author Test: Set $ENV{RELEASE_TESTING} to a true value to run.';
        plan( skip_all => $msg );
    }
};

use Inline CPP => 'DATA';

is( add( 1, 1 ), 2, 'Successfully compiled after rewriting config file.' );

done_testing();

__DATA__

__CPP__

int add ( int a, int b ) {
    return a + b;
}
