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

    my $input = [ 'diff --git a/test b/test',
                  'index 5d0cff14..b67ad5f2 100644',
                  '--- a/test',
                  '+++ b/test',
                  '@@ -295,7 +295,7 @@ no',
                  '-no',
                  '+match',
                  '-no',
                  '+match' ];

    my $match = sub {
        my $line = shift;
        return 1 if $line =~ /^match$/;
        return;
    };

    my $check = 'Test';

    my $plugin = $class->new();
    my @issues = $plugin->parse( input => $input, match => $match, check => $check );

    my $issue = { message => re('Test.+line'), filename => 'test' };
    my @expected = ( $issue, $issue );
    cmp_deeply( \@issues, \@expected, 'return was the expected filestructure and content' );
}

EXCEPTION: {
    note( 'exception' );

    my %input = ( input => [], match => sub { return }, check => 'Test' );
    foreach my $required ( keys %input ) {
        local $input{ $required };
        my $stored = delete $input{ $required };

        my $plugin = $class->new();
        dies_ok( sub { $plugin->parse( %input ) }, "dies if missing $required" );
        like( $@, qr/^$required is a required argument/, 'exception matches expected' );
    }

    $input{match} = 'not a code ref';
    my $plugin = $class->new();
    dies_ok( sub { $plugin->parse( %input ) }, 'dies if match is not a code ref' );
    like( $@, qr/match argument must be a code ref/, 'exception matches expected' );
}

done_testing;
