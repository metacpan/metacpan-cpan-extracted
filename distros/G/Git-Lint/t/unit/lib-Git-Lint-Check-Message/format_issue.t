use strict;
use warnings;

use FindBin;
use lib "$FindBin::RealBin/../../../lib", "$FindBin::RealBin/../../lib";

use Git::Lint::Test;
use Test::Deep;
use Test::Exception;

my $class = 'Git::Lint::Check::Message';
use_ok( $class );

HAPPY_PATH: {
    note( 'happy path' );

    my $check  = 'test';
    my $plugin = $class->new();
    my $issue  = $plugin->format_issue( check => $check );

    my $regex = qr{$check};
    my $expected = {
        message => re($regex),
    };
    cmp_deeply( $issue, $expected, 'return was the expected filestructure and content' );
}

EXCEPTION: {
    note( 'exception' );

    my %input = ( check => 'test' );
    foreach my $required ( keys %input ) {
        local $input{ $required };
        my $stored = delete $input{ $required };

        my $plugin = $class->new();
        dies_ok( sub { $plugin->format_issue( %input ) }, "dies if missing $required" );
        like( $@, qr/^$required is a required argument/, 'exception matches expected' );
    }
}

done_testing;
