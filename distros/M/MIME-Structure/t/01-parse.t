use Test::More;

my %message_structure = (
    'simple'    => '(1 text/plain:0)',
    'one-level' => '(1 multipart/alternative:0 (1.1 text/plain:250) (1.2 text/plain:387))',
    'nested'    => '(1 multipart/mixed:0 (1.1 text/plain:276) (1.2 multipart/alternative:382 (1.2.1 text/plain:519) (1.2.2 text/plain:661)) (1.3 text/plain:767))',
);

plan 'tests' => 2 + 3 * scalar(keys %message_structure);

use_ok( 'MIME::Structure' );

my $parser = MIME::Structure->new;

isa_ok( $parser, 'MIME::Structure' );

foreach my $m (sort keys %message_structure) {
    my $fh;
    ok( open($fh, '<', "t/messages/$m.txt"), "open $m message" );
    my $root;
    ok( ($root) = $parser->parse($fh), "parse $m message" );
    is( $parser->concise_structure($root), $message_structure{$m}, "structure of $m message" );
    close $fh;
}
