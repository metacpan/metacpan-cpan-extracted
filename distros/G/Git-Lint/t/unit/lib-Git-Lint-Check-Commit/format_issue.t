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

    my $filename = 'test.txt';
    my $check    = 'Test';
    my $lineno   = 1;
    my $plugin   = $class->new();
    my $issue    = $plugin->format_issue( filename => $filename, check => $check, lineno => $lineno );

    my $expected = {
        filename => $filename,
        message  => re( "$check.+$lineno" ),  # this is very loose but just want to check
    };                                        # if the check name and lineno are in there.
    cmp_deeply( $issue, $expected, 'return was the expected filestructure and content' );
}

EXCEPTION: {
    note( 'exception' );

    my %input = ( filename => 'test.txt', check => 'Test', lineno => 1 );
    foreach my $required ( keys %input ) {
        local $input{ $required };
        my $stored = delete $input{ $required };

        my $plugin = $class->new();
        dies_ok( sub { $plugin->format_issue( %input ) }, "dies if missing $required" );
        like( $@, qr/^$required is a required argument/, 'exception matches expected' );
    }
}

done_testing;
