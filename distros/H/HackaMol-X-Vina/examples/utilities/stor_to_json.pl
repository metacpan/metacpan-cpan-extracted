use Modern::Perl;
use JSON::XS;
use Storable;
use File::Slurp;

die "pass in.stor out.json " unless (@ARGV == 2);

my $db = retrieve(shift);
write_file (shift, encode_json $db);


