#!/usr/bin/perl
use Test::More qw[no_plan];
use strict;
$^W = 1;

BEGIN {
    require_ok 'CGI';
    require_ok 'Email::MIME';
    require_ok 'Email::MIME::Modifier';
    require_ok 'Email::MIME::ContentType';
    require_ok 'HTTP::Request';
    require_ok 'HTTP::Message';
    require_ok 'Class::Accessor::Fast';
    use_ok 'HTTP::Request::Params';
    use_ok 'HTTP::Request::Common';
    use_ok 'HTTP::Request';
}

my $get_request = HTTP::Request::Params->new({
                    req => get_request(),
                  });
test_request($get_request);

my $post_request = HTTP::Request::Params->new({req => post_request()});
test_request($post_request);

my $post_upload_request = HTTP::Request::Params->new({req => post_upload_request()});
test_request($post_upload_request);

like $post_upload_request->params->{myself}, qr/sub post_upload_request/, 'found myself';
is scalar($post_upload_request->mime->parts), 3;

sub test_request {
    isa_ok $get_request, 'HTTP::Request::Params';
    isa_ok $get_request->req, 'HTTP::Request';
    isa_ok $get_request->mime, 'Email::MIME';
    is ref($get_request->params), 'HASH', 'params is HASH';
    is ref($get_request->params->{multi}), 'ARRAY', 'params->{multi} is ARRAY';
    ok !ref($get_request->params->{single}), 'params->{single} is singular';
    is $get_request->params->{single}, 'one', 'single is one';
}

sub get_request {
    HTTP::Request->new(GET => q[http://example.com/?multi=1;multi=2;single=one]);
}

sub post_request {
<<__REQ__;
POST http://example.com?multi=1

multi=2;single=one
__REQ__
}

sub post_upload_request {
my $req = POST q[http://exmaple.com/?multi=2],
               Content_Type => 'form-data',
               Content => [
                   multi => 1,
                   single => 'one',
                   myself => [ $0 ],
               ];
return $req;
}
