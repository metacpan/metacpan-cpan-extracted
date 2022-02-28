use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";

use Git::Lint::Test;

my $class = 'Git::Lint::Command';
use_ok( $class );

SUCCESS: {
    note( 'success' );

    Git::Lint::Test::override(
        package => 'Capture::Tiny',
        name    => 'capture',
        subref  => sub { return ( "fake return\n", '', 0 ) },
    );
    my @cmd = ( qw{fake command} );
    my ( $stdout, $stderr, $exit ) = Git::Lint::Command::run( \@cmd );

    like( $stdout, qr/fake return\n/, 'stdout matches expected' );
    is( $stderr, '', 'stderr matches expected' );
    is( $exit, 0, 'exit matches expected' );
}

FAILURE: {
    note( 'failure' );

    Git::Lint::Test::override(
        package => 'Capture::Tiny',
        name    => 'capture',
        subref  => sub { return ( '', "fake failure\n", 1 ) },
    );
    my @cmd = ( qw{fake command} );
    my ( $stdout, $stderr, $exit ) = Git::Lint::Command::run( \@cmd );

    is( $stdout, '', 'stdout matches expected' );
    like( $stderr, qr/fake failure/, 'stderr matches expected' );
    is( $exit, 1, 'exit matches expected' );
}

done_testing;
