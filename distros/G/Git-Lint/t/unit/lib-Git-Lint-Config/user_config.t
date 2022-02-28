use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";

use Git::Lint::Test;
use Test::Exception;

my $class = 'Git::Lint::Config';
use_ok( $class );

NO_USER_CONFIG: {
    note( 'no user config' );

    Git::Lint::Test::override(
        package => 'Capture::Tiny',
        name    => 'capture',
        subref  => sub { return ( '', '', 1 ) },
    );

    my $object = $class->load();
    lives_ok( sub { $object->user_config() }, 'lives if no user config is defined' );
}

done_testing;
