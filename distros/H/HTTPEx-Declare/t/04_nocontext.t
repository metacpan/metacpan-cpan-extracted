use strict;
use warnings;
use lib '.';
use HTTP::Request;
use HTTPEx::Declare;
use Test::More tests => 3;

do {
    local $@;
    eval { res };
    like $@, qr/\QCan't call res() outside run block\E/;
};

interface Test => {};
my $response1 = run {
    res( body => 'OK!' );
} HTTP::Request->new( GET => 'http://localhost/' );

is $response1->content, 'OK!';


interface Test => {};
my $response2 = run {
    my $req = shift;
    res( body => 'OK!:' . $req->param('foo') );
} HTTP::Request->new( GET => 'http://localhost/?foo=bar' );

is $response2->content, 'OK!:bar';

