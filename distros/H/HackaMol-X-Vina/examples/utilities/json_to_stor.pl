use Modern::Perl;
use JSON::XS;
use Storable;
use File::Slurp;

die "pass in.json out.stor " unless (@ARGV == 2);

my $json = read_file( shift, { binmode => ':raw' } );
my $db   = new JSON::XS;
$db->incr_parse($json);
$db->incr_parse;
store($db,shift);


