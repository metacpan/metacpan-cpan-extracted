use v5.10;
use strict;
use warnings;
use Carp;
use Encode qw(decode encode);
use Geo::GDAL::FFI;
use Test::More;
use Data::Dumper;
use JSON;
use FFI::Platypus::Buffer;

my $gdal = Geo::GDAL::FFI->new();

{
    package Output;
    use strict;
    use warnings;
    our @output;
    sub new {
        return bless {}, 'Output';
    }
    sub write {
        my $line = shift;
        push @output, $line;
    }
    sub close {
        push @output, "end";
    }
    sub output {
        my $output = join '', @output;
        $output =~ s/\n//g;
        return $output;
    }
}

# test vsistdout redirection
if(1){

    # create a small layer and copy it to vsistdout with redirection
    my $layer = $gdal->GetDriver('Memory')->Create->CreateLayer({GeometryType => 'None'});
    $layer->CreateField(value => 'Integer');
    $layer->CreateGeomField(geom => 'Point');
    my $feature = Geo::GDAL::FFI::Feature->new($layer->GetDefn);
    $feature->SetField(value => 12);
    $feature->SetGeomField(geom => [WKT => 'POINT(1 1)']);
    $layer->CreateFeature($feature);

    my $output = Output->new;
    $gdal->SetWriter($output);
    $gdal->GetDriver('GeoJSON')->Create('/vsistdout')->CopyLayer($layer);
    $gdal->CloseWriter;

    my $ret = $output->output;
    ok($ret eq
       '{"type": "FeatureCollection",'.
       '"features": '.
       '[{ "type": "Feature", "id": 0, "properties": '.
       '{ "value": 12 }, "geometry": { "type": "Point", '.
       '"coordinates": [ 1.0, 1.0 ] } }]}end', 
    "Redirect vsistdout to write/close methods of a class.");

}

# test Translate
if(1){
    my $ds = $gdal->GetDriver('GTiff')->Create('/vsimem/test.tiff', 10);
    my $png = $ds->Translate('/vsimem/test.png', -of => 'PNG');
    ok($png->GetDriver->GetName eq 'PNG', "Translate");
}

done_testing();
