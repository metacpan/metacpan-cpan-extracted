use Test::More;

my %message = (
    'simple'    => 1,
    'one-level' => 3,
    'nested'    => 6,
);

my %regex = (
    'body_offset'    => qr/^\d+$/,
#   'content_length' => qr/^\d+$/,
    'encoding'       => qr/^(7bit|quoted-printable)$/,
#   'fields'        => qr/^xxx$/,
#   'header'         => qr/^xxx$/,
    'kind'           => qr/^(message|part)$/,
#   'length'         => qr/^\d+$/,
    'level'          => qr/^\d+$/,
    'line'           => qr/^\d+$/,
    'number'         => qr/^1(\.\d+)*$/,
    'offset'         => qr/^\d+$/,
#   'parent'         => qr/^xxx$/,
#   'parts'          => qr/^xxx$/,
#   'parts_boundary' => qr/^xxx$/,
#   'subtype'        => qr/^xxx$/,
#   'type'           => qr/^xxx$/,
#   'type_params'    => qr/^xxx$/,
);

my $total_entities = 0;
$total_entities += $_ for values %message;

plan 'tests' => 2 + 2 * scalar(keys %message) + scalar(keys %regex) * $total_entities;

use_ok( 'MIME::Structure' );

my $parser = MIME::Structure->new;

isa_ok( $parser, 'MIME::Structure' );

foreach my $m (sort keys %message) {
    my $fh;
    ok( open($fh, '<', "t/messages/$m.txt"), "open $m message" );
    my @entities = $parser->parse($fh);
    ok( scalar(@entities), "parse $m message" );
    foreach my $e (@entities) {
        my $number = $e->{'number'};
        like( $e->{$_}, $regex{$_}, "entity $number $_" ) for sort keys %regex;
    }
    close $fh;
}

