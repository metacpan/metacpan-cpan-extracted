
use strict;
use Test;
use Games::RolePlay::MapGen;

plan tests => 1;

unless( -f "xml_parser.res" ) {
    skip(1,1,1);
    exit 0;
}

my $map = new Games::RolePlay::MapGen({
    tile_size    => 10,
    cell_size    => "23x23", 
    num_rooms    => "1d4", 
    bounding_box => "15x15"
}); 

add_generator_plugin $map "FiveSplit";
add_generator_plugin $map "BasicDoors"; # this should work with basicdoors first or last!

generate     $map; 
set_exporter $map "XML";
export       $map "09_map.xml";

$map = Games::RolePlay::MapGen->new();
$map->set_generator("XMLImport");
$map->generate( xml_input_file => "09_map.xml" );
$map->set_exporter( "XML" );
$map->export( "09_ma2.xml" );

open my $in, "-|", "diff -u 09_map.xml 09_ma2.xml" or die $!;
my $diffs = 0;
while(<$in>) {
    next unless m/^[-+] /;
    next if m/<option.*name="fname/;
    next if m/<option.*name="xml_input_file/;

    warn $_;

    $diffs ++;
}

close $in;

ok( $diffs, 0 );
