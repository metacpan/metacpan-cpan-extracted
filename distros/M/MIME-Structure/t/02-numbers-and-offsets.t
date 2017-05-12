use Test::More;

my %offsets = (
    'simple'    => { '1' => 0 },
    'one-level' => { '1' => 0, '1.1' => 250, '1.2' => 387 },
    'nested'    => { '1' => 0, '1.1' => 276, '1.2' => 382, '1.2.1' => 519, '1.2.2' => 661, '1.3' => 767 },
);

plan 'tests' => 2 + (2 * scalar keys(%offsets)) + scalar(map { keys %$_ } values %offsets);

use_ok( 'MIME::Structure' );

my $parser = MIME::Structure->new;

isa_ok( $parser, 'MIME::Structure' );

foreach my $m (sort keys %offsets) {
    my $fh;
    ok( open($fh, '<', "t/messages/$m.txt"), "open $m message" );
    my @entities = $parser->parse($fh);
    ok( scalar(@entities), "parse $m message" );
    foreach my $e (@entities) {
        my $number = $e->{'number'};
        my $offset = $e->{'offset'};
        is( $offset, $offsets{$m}{$number}, "offset of entity $number in $m message" );
    }
    close $fh;
}

