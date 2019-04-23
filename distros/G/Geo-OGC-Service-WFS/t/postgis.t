use strict;
use warnings;
use Carp;
use Test::More tests => 8;
use Plack::Test;
use HTTP::Request::Common;
use Geo::OGC::Service;
use XML::LibXML;
use XML::SemanticDiff;
use XML::LibXML::PrettyPrint;
use DBI;
BEGIN { use_ok('Geo::OGC::Service::WFS') };

# create a test database first

my $user = getlogin || getpwuid($<) || "Kilroy";
my $pass = $user;
my $test_db = 'wfstest';
my $dbh;    

sub setup_db {
    my $connect = "dbi:Pg:dbname=postgres";
    my %attr = (PrintError => 0, RaiseError => 1, AutoCommit => 1);
    $dbh = DBI->connect($connect, $user, $pass, \%attr);
    my ($e) = $dbh->selectrow_array("SELECT datname FROM pg_database WHERE datname='$test_db'");
    return "Database '$test_db' exists, skipping." if $e;
    $dbh->do("CREATE DATABASE $test_db encoding 'UTF-8'");
    $connect = "dbi:Pg:dbname=$test_db";
    $dbh = DBI->connect($connect, $user, $pass, \%attr);
    # check for postgis before creating it
    ($e) = $dbh->selectrow_array("SELECT extname FROM pg_extension WHERE extname='postgis'");
    unless ($e) {
        $dbh->do("CREATE EXTENSION postgis") or die $dbh->errstr;
    }
    for my $sql (
        "CREATE TABLE test (id serial primary key, i int, d double precision, s text, p text)",
        "SELECT AddGeometryColumn ('public','test','geom',4326,'POINT',2)",
        "INSERT INTO test (i, d, s, p, geom) VALUES (1, 2.1, 'hello', 'pass', ST_GeomFromText('POINT (1 2)',4326))"
        ) 
    {
        $dbh->do($sql) or die $dbh->errstr;
    }
}

sub cleanup {
    my $connect = "dbi:Pg:dbname=postgres";
    my %attr = (PrintError => 0, RaiseError => 1, AutoCommit => 1);
    $dbh = DBI->connect($connect, $user, $pass, \%attr);
    $dbh->do("DROP DATABASE IF EXISTS $test_db") or die $dbh->errstr;
}

eval {
    setup_db();
};
my $error = $@;

my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");

SKIP: {
    skip "Skip PostGIS tests. Reason: can't create or connect to database '$test_db': ".$error, 7 if $error;

    my $config = {
        "resource" => "/",
        "Content-Type" => "text/xml",
        "TARGET_NAMESPACE" => "http://ogr.maptools.org/",
        "PREFIX" => "ogr",
        "debug" => "0",
        "Title" => "Test WFS",
        "Operations" => "Query,Insert,Update,Delete",
        "FeatureTypeList" => [
            {
                "prefix" => "local",
                "gml:id" => "id",
                "DataSource" => "PG:dbname=$test_db host=localhost user=$user password=$pass",
                "test_auth.geom" => {
                    "Operations" => "Query,Insert,Update,Delete",
                    "pseudo_credentials" => "usern,pass"
                }
            }
            ]
    };

    my $app = Geo::OGC::Service->new({ config => $config, services => { WFS => 'Geo::OGC::Service::WFS' }})->to_app;

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => "/");
        $req->content_type('text/xml');
        $req->content( '<?xml version="1.0" encoding="UTF-8"?>'.
                       '<GetCapabilities service="WFS" />' );
        my $res = $cb->($req);
        #say STDERR $res->content;
        my $parser = XML::LibXML->new(no_blanks => 1);
        my $dom;
        eval {
            $dom = $parser->load_xml(string => $res->content);
        };
        if ($@) {
            is $@, 0, 'GetCapabilities';
        } else {
            is 1, 1, 'GetCapabilities';
        }
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => "/");
        $req->content_type('text/xml');
        $req->content( '<?xml version="1.0" encoding="UTF-8"?>'.
                       '<DescribeFeatureType service="WFS"><TypeName>local.test.geom</TypeName></DescribeFeatureType>' );
        my $res = $cb->($req);
        my $parser = XML::LibXML->new(no_blanks => 1);
        my $dom;
        eval {
            $dom = $parser->load_xml(string => $res->content);
        };
        if ($@) {
            is $@, 0, 'DescribeFeatureType';
        } else {
            $pp->pretty_print($dom);
            #say STDERR $dom->toString;
            is 1, 1, 'DescribeFeatureType';
        }
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => "/");
        $req->content_type('text/xml');
        my $post = Geo::OGC::Service::XMLWriter::Caching->new;
        $post->element(
            GetFeature => {service=>"WFS"}, 
            [Query => { typeNames => 'local.test.geom' }, [ [PropertyName => "s"], [PropertyName => "geometryProperty"] ]]
            );
        $req->content($post->to_string);
        my $res = $cb->($req);
        my $parser = XML::LibXML->new(no_blanks => 1);
        my $dom;
        eval {
            $dom = $parser->load_xml(string => $res->content);
        };
        if ($@) {
            is $@, 0, 'GetFeature';
        } else {
            $pp->pretty_print($dom);
            #say STDERR $dom->toString;
            is 1, 1, 'GetFeature';
        }
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => "/");
        $req->content_type('text/xml');
        my $post = Geo::OGC::Service::XMLWriter::Caching->new;
        my $point = [Point => {srsName => 'http://www.opengis.net/gml/srs/epsg.xml#4326'}, [pos => "3 4"]];
        $post->element(
            Transaction => {service=>"WFS"}, 
            [Insert => [ ['local.test.geom' => [ [i => 2], [d => 4.5], [s => 'foo'], [geometryProperty => $point] ]] ]]
            );
        $req->content($post->to_string);
        my $res = $cb->($req);
        my $parser = XML::LibXML->new(no_blanks => 1);
        my $dom;
        eval {
            $dom = $parser->load_xml(string => $res->content);
        };
        if ($@) {
            is $@, 0, 'Transaction Insert';
        } else {
            $pp->pretty_print($dom);
            #say STDERR $dom->toString;
            is 1, 1, 'Transaction Insert';
        }
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => "/");
        $req->content_type('text/xml');
        my $post = Geo::OGC::Service::XMLWriter::Caching->new;
        my $point = [Point => {srsName => 'EPSG:4326'}, [pos => "5 6"]];
        $post->element(
            Transaction => {service=>"WFS"}, 
            [Update => {typeName => 'local.test.geom'}, [ 
                 [ Property => [ [ValueReference => 'i'], [Value => 3] ] ],
                 [ Property => [ [ValueReference => 'geometryProperty'], [Value => $point] ] ],
                 [ Filter => [ResourceId => { rid => 2 } ] ]
             ]]
            );
        $req->content($post->to_string);
        my $res = $cb->($req);
        my $parser = XML::LibXML->new(no_blanks => 1);
        my $dom;
        eval {
            $dom = $parser->load_xml(string => $res->content);
        };
        if ($@) {
            is $@, 0, 'Transaction Update';
        } else {
            $pp->pretty_print($dom);
            #say STDERR $dom->toString;
            is 1, 1, 'Transaction Update';
        }
    };

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => "/");
        $req->content_type('text/xml');
        my $post = Geo::OGC::Service::XMLWriter::Caching->new;
        $post->element(
            Transaction => {service=>"WFS"}, 
            [Delete => {typeName => 'local.test.geom'}, [
                 [ Filter => [ResourceId => { rid => 1 } ] ]
             ]]
            );
        $req->content($post->to_string);
        my $res = $cb->($req);
        my $parser = XML::LibXML->new(no_blanks => 1);
        my $dom;
        eval {
            $dom = $parser->load_xml(string => $res->content);
        };
        if ($@) {
            is $@, 0, 'Transaction Delete';
        } else {
            $pp->pretty_print($dom);
            #say STDERR $dom->toString;
            is 1, 1, 'Transaction Delete';
        }
    };

    # test pseudo credentials

    for my $sql (
        "create table test_auth (id serial primary key, usern text, pass text)",
        "SELECT AddGeometryColumn ('public','test_auth','geom',4326,'POINT',2)",
        "insert into test_auth (usern, pass, geom) values ('me', 'pass', ST_GeomFromText('POINT (1 2)', 4326))",
        "insert into test_auth (usern, pass, geom) values ('me', 'pass', ST_GeomFromText('POINT (3 4)', 4326))",
        "insert into test_auth (usern, pass, geom) values ('her', 'pass', ST_GeomFromText('POINT (3 4)', 4326))"
        ) 
    {
        $dbh->do($sql) or die $dbh->errstr;
    }

    test_psgi $app, sub {
        my $cb = shift;
        my $req = HTTP::Request->new(POST => "/");
        $req->content_type('text/xml');
        my $post = <<'end'; # almost actual XML sent by OpenLayers
<?xml version="1.0"?>
<wfs:GetFeature xmlns:wfs="http://www.opengis.net/wfs" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" service="WFS" version="1.1.0" outputFormat="GML2" xsi:schemaLocation="http://www.opengis.net/wfs http://schemas.opengis.net/wfs/1.1.0/wfs.xsd">
  <wfs:Query typeName="feature:public.test_auth.geom">
    <ogc:Filter xmlns:ogc="http://www.opengis.net/ogc">
      <ogc:And>
        <ogc:And>
          <ogc:PropertyIsEqualTo matchCase="true">
            <ogc:PropertyName>usern</ogc:PropertyName>
            <ogc:Literal>me</ogc:Literal>
          </ogc:PropertyIsEqualTo>
          <ogc:PropertyIsEqualTo matchCase="true">
            <ogc:PropertyName>pass</ogc:PropertyName>
            <ogc:Literal>pass</ogc:Literal>
          </ogc:PropertyIsEqualTo>
        </ogc:And>
        <ogc:BBOX>
          <gml:Envelope xmlns:gml="http://www.opengis.net/gml">
            <gml:lowerCorner>
              0 0
            </gml:lowerCorner>
            <gml:upperCorner>
              5 5
            </gml:upperCorner>
          </gml:Envelope>
        </ogc:BBOX>
      </ogc:And>
    </ogc:Filter>
  </wfs:Query>
</wfs:GetFeature>
end

        $req->content($post);
        my $res = $cb->($req);
        #say STDERR $res->content;
        my $parser = XML::LibXML->new(no_blanks => 1);
        my $dom;
        eval {
            $dom = $parser->load_xml(string => $res->content);
        };
        if ($@) {
            is $@, 0, 'GetFeature with auth by properties';
        } else {
            #$pp->pretty_print($dom);
            #say STDERR $dom->toString;
            my @n = $dom->documentElement()->getChildrenByTagNameNS('*', 'featureMember');
            is @n, 2, 'GetFeature with auth by properties';
        }
    };

    cleanup();
}
