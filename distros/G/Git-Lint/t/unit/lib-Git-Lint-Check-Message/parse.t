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

    my $input = [ 'match summary line' ];

    my $match = sub {
        my $lines_arref = shift;

        foreach my $line ( @{$lines_arref} ) {
            return 1 if $line =~ /^match/;
        }

        return;
    };

    my $plugin = $class->new();
    my @issues = $plugin->parse( input => $input, match => $match, check => 'test' );

    my $issue = { message => re('test') };
    my @expected = ( $issue );
    cmp_deeply( \@issues, \@expected, 'return was the expected filestructure and content' );
}

EXCEPTION: {
    note( 'exception' );

    my %input = ( input => [], match => sub { return }, check => 'test' );
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
