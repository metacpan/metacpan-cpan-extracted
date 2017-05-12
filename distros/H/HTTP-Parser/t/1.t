# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################

use strict;
use Test::More tests => 22;

# <1>
BEGIN { use_ok('HTTP::Parser') };

#########################

# parse request

my $parser = HTTP::Parser->new;
my @lines = ('GET / HTTP/1.1','Host: localhost','Connection: close','');
my @ok = (-2,-2,-2,0);

# <4>
my $result;
$parser->add("\x0a\x0a");  # blank lines before Request-Line should be ignored
for my $line(@lines) {
  $result = $parser->add("$line\x0d\x0a");
  is($result,shift @ok,"Passing '$line'");
}

# <6>
if($result) {
  skip "Didn't get request object", 6;
} else {
  my $req = $parser->request;
  isa_ok($req,'HTTP::Request');

  is($req->method(),'GET','Method');

  my $uri = $req->uri;
  isa_ok($uri,'URI');
  is($uri->path,'/','URI path');

  my @head;
  $req->headers->scan(sub { push @head, [@_] }); 
  ok(eq_set(\@head,[[Connection => 'close'], [Host => 'localhost'],
   ['X-HTTP-Version' => '1.1']]),'Headers');
  is($req->content,'','Content');
}

# by default we should fail to parse a response

$parser = HTTP::Parser->new;
@lines = ('HTTP/1.1 200 OK','Server: Test/0.1','Content-Length: 15',
 'Content-Type: text/plain','','Some content!');
@ok = (-2,-2,-2,-2,15,0);

# <1>
eval {
  $parser->add("$lines[0]\x0d\x0a\x0d\x0a");
};
ok($@, 'response failed by default');

# parse response

# <5>
$parser = HTTP::Parser->new(response => 1);
for my $line(@lines) {
  $result = $parser->add("$line\x0d\x0a");
  is($result,shift @ok,"Passing '$line'");
}

# <3>
if($result) {
  skip "Didn't get response object", 3;
} else {
  my $res = $parser->object;
  isa_ok($res, 'HTTP::Response');
  is($res->header('content-type'), 'text/plain', 'content type is correct');
  is($res->content, "Some content!\x0d\x0a", 'content is correct');
}

# <1>
$parser = HTTP::Parser->new(request => 1);
$parser->add("GET //foo///bar/baz HTTP/1.1\x0d\x0a\x0d\x0a");
is $parser->request->uri->path, '//foo///bar/baz';
