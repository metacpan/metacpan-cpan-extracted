# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl Geo-OGC-Service.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use v5.10;
use Encode qw(decode encode is_utf8);
use Test::More tests => 9;
use Plack::Test;
use HTTP::Request::Common;
use XML::SemanticDiff;
BEGIN { use_ok('Geo::OGC::Service') };
binmode STDERR, ":utf8"; 

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

#close(STDERR); # hide Geo::OGC::Service logging messages 

my $app;
eval {
    $app = Geo::OGC::Service->new({ config => 'cannot open this', services => {} })->to_app;
};
is substr($@, 0, 5), substr("Can't open file 'cannot open this'", 0, 5);

$app = Geo::OGC::Service->new({ config => {}, services => {} })->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    my $diff = XML::SemanticDiff->new();
    my @diff = $diff->compare(
        $res->content, '<?xml version="1.0" encoding="UTF-8"?>'.
        '<ExceptionReport version="1.0"><Exception exceptionCode="InvalidParameterValue" locator="service">'.
        "<ExceptionText>'' is not a known service to this server</ExceptionText></Exception></ExceptionReport>");
    is scalar(@diff), 0;
};

my $config = $0;
$config =~ s/\.t$/.conf/;

$app = Geo::OGC::Service->new({ config => $config, services => {} })->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    my $diff = XML::SemanticDiff->new();
    my $expected = '<?xml version="1.0" encoding="UTF-8"?>'.
        '<ExceptionReport version="1.0"><Exception exceptionCode="InvalidParameterValue" locator="service">'.
        "<ExceptionText>'' is not a known service to this server</ExceptionText></Exception></ExceptionReport>";
    my $got = $res->content;
    my @diff = $diff->compare($got, $expected);
    is scalar(@diff), 0;
    say STDERR "expected $expected\ngot $got" if @diff;
};

{
    package Geo::OGC::Service::Test;
    sub process_request {
        my ($self, $responder) = @_;
        my $writer = $responder->([200, [ 'Content-Type' => 'text/plain',
                                          'Content-Encoding' => 'UTF-8' ]]);
        $writer->write("I'm ok!");
        $writer->close;
    }
}

$app = Geo::OGC::Service->new({ config => $config, services => { test => 'Geo::OGC::Service::Test' }})->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?service=test");
    #say STDERR $res->content;
    is $res->content, "I'm ok!";
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new(POST => "/");
    $req->content_type('text/xm; charset=utf-8');
    my $request = decode utf8 => '<?xml version="1.0" encoding="UTF-8"?>'.
        '<request service="åäö"></request>';
    $req->content(encode utf8 => $request);
    my $res = $cb->($req);
    my $diff = XML::SemanticDiff->new();
    my $expected = decode
        utf8 => 
        '<?xml version="1.0" encoding="UTF-8"?>'.
        '<ExceptionReport version="1.0"><Exception exceptionCode="InvalidParameterValue" locator="service">'.
        "<ExceptionText>'åäö' is not a known service to this server</ExceptionText></Exception></ExceptionReport>";
    my $got = decode utf8 => $res->content;
    my @diff = $diff->compare($got, $expected);
    is scalar(@diff), 0;
    say STDERR "expected $expected\ngot $got" if @diff;
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new(POST => "/");
    $req->content_type('text/xml');
    $req->content_encoding('UTF-8');
    $req->content( '<?xml version="1.0" encoding="UTF-8"?>'.
                   '<request service="test">åäö</request>' );
    my $res = $cb->($req);
    is $res->content, "I'm ok!";
};

my $asked_config = 0;

{
    package Geo::OGC::Service::TestService;
    sub process_request {
        my ($self, $responder) = @_;
        my $writer = $responder->([200, [ 'Content-Type' => 'text/plain',
                                          'Content-Encoding' => 'UTF-8' ]]);
        my $config = $self->{plugin}->config($self->{config}, $self) if $self->{plugin};
        $writer->write("I'm ok!");
        $writer->close;
    }
}

{
    package Geo::OGC::Service::TestPlugin;
    sub new {
        my ($class) = @_;
        my $self = {};
        return bless $self, $class;
    }
    sub config {
        my ($service, $config) = @_;
        $asked_config = $config->{foo};
        return {};
    }
}

my $plugin = Geo::OGC::Service::TestPlugin->new();

# plugin is for all services
$app = Geo::OGC::Service->new({ config => { foo => 'bar' },
                                plugin => $plugin,
                                services => {test => 'Geo::OGC::Service::TestService'} })->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?service=test");
    is $asked_config, 'bar';
};

# plugin is for one service
$app = Geo::OGC::Service->new({ config => { foo => 'bar' },
                                services => {
                                    test => { service => 'Geo::OGC::Service::TestService',
                                              plugin => $plugin },
                                } })->to_app;

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?service=test");
    is $asked_config, 'bar';
};
