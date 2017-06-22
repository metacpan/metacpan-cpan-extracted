# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Geo-OGC-Service.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 6;
use Plack::Test;
use HTTP::Request::Common;
use Geo::OGC::Service;
use XML::LibXML;
use XML::SemanticDiff;
use XML::LibXML::PrettyPrint;
use Plack::Builder;
BEGIN { use_ok('Geo::OGC::Service::WMTS') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

use File::ShareDir;	 
my $dir = File::ShareDir::dist_dir('Geo-GDAL');
Geo::GDAL::PushFinderLocation($dir);

eval {
    if ($Geo::GDAL::VERSION >= 2) {
        Geo::OSR::SpatialReference->new(EPSG=>2931);
    } else {
        Geo::OSR::SpatialReference->create(EPSG=>2931);
    }
};
BAIL_OUT("You have Geo::GDAL module, but GDAL data files could not be found. ".
         "You need to set the GDAL_DATA environment ".
         "variable to point to the correct location. ".
	 "The error message is $@\n") if $@;

my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");

my $config = {
    debug => 0
};

my $app = Geo::OGC::Service->new({ 
    config => $config, 
    services => { 
        WMTS => 'Geo::OGC::Service::WMTS',
        WMS => 'Geo::OGC::Service::WMTS',
        TMS => 'Geo::OGC::Service::WMTS',
    }})->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?service=WMTS&request=GetCapabilities");
    my $parser = XML::LibXML->new(no_blanks => 1);
    my $dom;
    eval {
        $dom = $parser->load_xml(string => $res->content);
    };
    if ($@) {
        is $@, 0;
    } else {
        #$pp->pretty_print($dom);
        #say STDERR $dom->toString;
        my $root = $dom->documentElement();
        my $name = $root->nodeName;
        #say STDERR $name;
        is $name, 'Capabilities';
    }
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?service=WMS&request=GetCapabilities");
    my $parser = XML::LibXML->new(no_blanks => 1);
    my $dom;
    eval {
        $dom = $parser->load_xml(string => $res->content);
    };
    if ($@) {
        is $@, 0;
    } else {
        #$pp->pretty_print($dom);
        #say STDERR $dom->toString;
        my $root = $dom->documentElement();
        my $name = $root->nodeName;
        #say STDERR $name;
        is $name, 'WMT_MS_Capabilities';
    }
};

$app = builder {
    mount "/TMS" => $app;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/TMS");
    my $parser = XML::LibXML->new(no_blanks => 1);
    my $dom;
    eval {
        $dom = $parser->load_xml(string => $res->content);
    };
    if ($@) {
        is $@, 0;
    } else {
        #$pp->pretty_print($dom);
        #say STDERR $dom->toString;
        my $root = $dom->documentElement();
        my $name = $root->nodeName;
        #say STDERR $name;
        is $name, 'TileMapService';
    }
};

$config = {
    debug => 0,
    blank => '/tmp/blank',
    TileSets => [
        {
            "Layers" => "test",
            "Format" => "text/plain",
            "path" => '/tmp',
            "ext" => "txt"
        }
    ]
};

my $params = 'layer=test&tilerow=1&tilecol=1&tilematrix=1&tilematrixset=EPSG:3857&format=txt';

{
    my $blank = 'me blank';
    open(my $fh, ">", "/tmp/blank") or die "can't write to /tmp";
    print $fh $blank;
    $fh->close;
    
    $app = Geo::OGC::Service->new({ 
        config => $config, 
        services => { 
            WMTS => 'Geo::OGC::Service::WMTS'
        }})->to_app;
    
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/?service=WMTS&request=GetTile&$params");
        is $res->content, $blank;
    };

    unlink '/tmp/blank';
}

{
    mkdir '/tmp/1';
    mkdir '/tmp/1/1';

    my $blank = 'me tile';
    my $tile = "/tmp/1/1/0.txt";
    open(my $fh, ">", $tile) or die "can't write to /tmp";
    print $fh $blank;
    $fh->close;
    
    $app = Geo::OGC::Service->new({ 
        config => $config, 
        services => { 
            WMTS => 'Geo::OGC::Service::WMTS'
        }})->to_app;
    
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/?service=WMTS&request=GetTile&$params");
        is $res->content, $blank;
    };
    
    unlink $tile;
    
    rmdir '/tmp/1/1';
    rmdir '/tmp/1';
}
