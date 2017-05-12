use warnings;
use strict;

use Test::More tests => 4;
use Config;

my $perl = $Config{perlpath};

my $output = `$perl ./bufrencode.pl --data t/307080.data --metadata t/metadata.txt_ed4 -t t/bt`;
my $expected = read_binary_file('t/encoded_ed4') ;
is($output, $expected, 'testing bufrencode.pl on 2 synop bufr edition 4');

`$perl ./bufrencode.pl --data t/307080.data --metadata t/metadata.txt_ed3 --outfile t/outenc1 -t t/bt`;
$output = read_binary_file('t/outenc1');
unlink 't/outenc1';
$expected = read_binary_file('t/encoded_ed3') ;
is($output, $expected, 'testing bufrencode.pl -o on 2 synop bufr edition 3');

$output = `$perl ./bufrencode.pl --data t/substituted_data --metadata t/substituted_metadata -t t/bt`;
$expected = read_binary_file('t/substituted.bufr') ;
is($output, $expected, 'testing bufrencode.pl on message with unnumbered descriptors');



# Testing of join_subsets and encode_nil_message

use Geo::BUFR;
Geo::BUFR->set_tablepath('t/bt');
my $bufr3 = Geo::BUFR->new();
$bufr3->fopen('t/bufr3subset.dat');
# Enforce decoding of metadata
$bufr3->next_observation();

# Create NIL BUFR message based on the same metadata
my $stationid_ref = {
                     '001001' => 1,
                     '001002' => 492,
                     '001015' => 'BLINDERN',
                 };
my $new_bufr = Geo::BUFR->new();
$new_bufr->copy_from($bufr3,'metadata');
# Encode nil_message with delayed replication factors set to 2,3
my $nil_msg = $new_bufr->encode_nil_message($stationid_ref,[2,3]);
my $nil_bufr = Geo::BUFR->new($nil_msg);

# Then join the nil message with subset 3 and 1 from $bufr3
Geo::BUFR->set_verbose(2);
my ($data_refs,$desc_refs,$N) =
    Geo::BUFR->join_subsets($bufr3,[3,1],$nil_bufr);
my $join_bufr = Geo::BUFR->new();
$join_bufr->copy_from($bufr3,'metadata');
$join_bufr->set_number_of_subsets($N);
$join_bufr->set_compressed_data(0);
my $new_message = $join_bufr->encode_message($data_refs,$desc_refs);

$expected = read_binary_file('t/join.bufr');
is($new_message, $expected, 'testing joining subsets and encoding nil message');


# Read in binary file
sub read_binary_file {
    my $infile = shift;
    local $/; # Enable slurp mode
    open my $fh, '<', $infile or die "Can't open $infile: $!";
    binmode($fh);
    return <$fh>;
};
