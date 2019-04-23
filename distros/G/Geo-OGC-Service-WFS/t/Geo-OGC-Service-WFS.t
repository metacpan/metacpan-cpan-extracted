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
BEGIN { use_ok('Geo::OGC::Service::WFS') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $config = $0;
$config =~ s/\.t$/.conf/;

my $app = Geo::OGC::Service->new({ config => $config, services => { WFS => 'Geo::OGC::Service::WFS' }})->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?service=WFS");
    my $parser = XML::LibXML->new(no_blanks => 1);
    my $dom;
    eval {
        $dom = $parser->load_xml(string => $res->content);
    };
    if ($@) {
        is $@, 0;
    } else {
        my $expected = <<'END_XML';
<?xml version="1.0" encoding="UTF-8"?>
<ExceptionReport version="1.0">
<Exception exceptionCode="MissingParameterValue" locator="request"/>
</ExceptionReport>
END_XML
        my $diff = XML::SemanticDiff->new();
        my @diff = $diff->compare($res->content, $expected);
        my $n = @diff;
        if ($n) {
            my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");
            print STDERR "Got:\n",$pp->pretty_print($dom)->toString;
            $dom = $parser->load_xml(string => $expected);
            print STDERR "Expected:\n",$pp->pretty_print($dom)->toString;
        }
        is $n, 0;
    }
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?service=WFS&request=GetCapabilities");
    my $parser = XML::LibXML->new(no_blanks => 1);
    my $dom;
    eval {
        $dom = $parser->load_xml(string => $res->content);
    };
    if ($@) {
        is $@, 0;
    } else {
        is 1, 1;
    }
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?service=WFS&request=DescribeFeatureType&typename=x");
    my $parser = XML::LibXML->new(no_blanks => 1);
    my $dom;
    eval {
        $dom = $parser->load_xml(string => $res->content);
    };
    if ($@) {
        is $@, 0;
    } else {
        my $expected = <<'END_XML';
<?xml version="1.0" encoding="UTF-8"?>
<ExceptionReport version="1.0">
<Exception exceptionCode="InvalidParameterValue" locator="typeName">
<ExceptionText>Feature type 'x' is not available.</ExceptionText>
</Exception>
</ExceptionReport>
END_XML
        my $diff = XML::SemanticDiff->new();
        my @diff = $diff->compare($res->content, $expected);
        my $n = @diff;
        if ($n) {
            my $pp = XML::LibXML::PrettyPrint->new(indent_string => "  ");
            print STDERR "Got:\n",$pp->pretty_print($dom)->toString;
            $dom = $parser->load_xml(string => $expected);
            print STDERR "Expected:\n",$pp->pretty_print($dom)->toString;
        }
        is $n, 0;
    }
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?service=WFS&request=DescribeFeatureType&typename=test");
    my $parser = XML::LibXML->new(no_blanks => 1);
    my $dom;
    eval {
        $dom = $parser->load_xml(string => $res->content);
    };
    if ($@) {
        is $@, 0;
    } else {
        is 1, 1;
    }
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?service=WFS&request=GetFeature&typename=test");
    my $parser = XML::LibXML->new(no_blanks => 1);
    my $dom;
    eval {
        $dom = $parser->load_xml(string => $res->content);
    };
    if ($@) {
        is $@, 0;
    } else {
        is 1, 1;
    }
};
