use Modern::Perl;
use YAML::XS qw(Load Dump);
use JSON::XS;
use File::Slurp;

my $json_fn = shift;
my $text    = read_file( $json_fn, { binmode => ':raw' } );
my $json    = new JSON::XS;
$json->incr_parse($text);

my $stor = $json->incr_parse;

foreach my $lig (keys %$stor){
  print Dump $stor->{$lig};
}


