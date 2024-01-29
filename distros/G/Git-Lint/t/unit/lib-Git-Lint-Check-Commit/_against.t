use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";

use Git::Lint::Test;
use Test::Exception;

my $class = 'Git::Lint::Check::Commit';
use_ok( $class );

AGAINST_HEAD: {
    note( 'against HEAD' );

    Git::Lint::Test::override(
        package => 'Capture::Tiny',
        name    => 'capture',
        subref  => sub { return ( 'anything', '', 1 ) },
    );

    my $plugin  = $class->new();
    my $against = $plugin->_against();

    is( $against, 'HEAD', 'return indicates HEAD' );
}

AGAINST_INITIAL: {
    note( 'against initial' );

    Git::Lint::Test::override(
        package => 'Capture::Tiny',
        name    => 'capture',
        subref  => sub { return ( '', '', 1 ) },
    );

    my $plugin  = $class->new();
    my $against = $plugin->_against();

    is( $against, '4b825dc642cb6eb9a060e54bf8d69288fbee4904', 'return indicates initial' );
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
    dies_ok( sub { $plugin->_against() }, 'dies if stderr and exit' );
    is( $@, $error, 'exception matches expected' );
}

done_testing;
