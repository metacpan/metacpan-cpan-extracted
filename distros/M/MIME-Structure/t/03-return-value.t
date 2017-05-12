use Test::More;

my %offsets = (
    'simple'    => { '1' => 0 },
    'one-level' => { '1' => 0, '1.1' => 250, '1.2' => 387 },
    'nested'    => { '1' => 0, '1.1' => 276, '1.2' => 382, '1.2.1' => 519, '1.2.2' => 661, '1.3' => 767 },
);

plan 'tests' => 2 + 5 * scalar(keys %offsets);

use_ok( 'MIME::Structure' );

my $parser = MIME::Structure->new;

isa_ok( $parser, 'MIME::Structure' );

foreach my $m (sort keys %offsets) {
    my $expected_num_entities = scalar keys %{ $offsets{$m} };
    my $fh;
    ok( open($fh, '<', "t/messages/$m.txt"), "open $m message" );
    my @entities = $parser->parse($fh);
    my $num_entities = scalar(@entities);
    ok( $num_entities, "parse $m message" );
    is( $num_entities, $expected_num_entities, 'entity count' );
    seek $fh, 0, 0 or die "Can't seek to beginning of message";
    my $message = $parser->parse($fh);
    is_deeply( $message, $entities[0], 'scalar vs. list context: message' );
    is( $num_entities, count_all_parts($message), 'scalar vs. list context: entity count' );
    close $fh;
}

sub count_all_parts {
    my ($msg) = @_;
    my $n = 1;
    if ($msg->{'parts'}) {
        $n += count_all_parts($_) for @{ $msg->{'parts'} };
    }
    return $n;
}
