use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";

use Git::Lint::Test;
use Test::Deep;
use Test::Exception;

my $class = 'Git::Lint::Check::Commit';
use_ok( $class );

HAPPY_PATH: {
    note( 'happy path' );

    Git::Lint::Test::override(
        package => 'Capture::Tiny',
        name    => 'capture',
        subref  => sub { return ( "one\ntwo", '', 0 ) },
    );

    my $plugin     = $class->new();
    my $diff_arref = $plugin->_diff_index();

    cmp_deeply( $diff_arref, ['one','two'], 'return is an ARRAYREF with expected members' );
}

EXCEPTION: {
    note( 'exception' );

    my $error = "failure\n";
    Git::Lint::Test::override(
        package => 'Capture::Tiny',
        name    => 'capture',
        subref  => sub { return ( '', $error, 1 ) },
    );

    my $plugin = $class->new();
    dies_ok( sub { $plugin->_diff_index() }, 'dies if exit' );
    is( $@, 'git-lint: ' . $error, 'exception matches expected' );
}

done_testing;
