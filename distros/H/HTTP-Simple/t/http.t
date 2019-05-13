use strict;
use warnings;
no warnings 'redefine', 'once';

package HTTP::Simple::TestUA;
sub new { bless {} }

package main;

use Test::More;
use HTTP::Simple;
use File::Spec;
use File::Temp;

my $dir = File::Temp->newdir;
my $path = File::Spec->catfile($dir, 'test');

$HTTP::Simple::UA = HTTP::Simple::TestUA->new;

*HTTP::Simple::TestUA::get = sub { return {success => 1, status => 200, reason => 'OK', content => $_[1]} };
*HTTP::Simple::TestUA::head = sub { return {success => 1, status => 200, reason => 'OK', headers => {foo => $_[1]}} };
*HTTP::Simple::TestUA::mirror = sub { return {success => 1, status => 200, reason => 'OK'} };
*HTTP::Simple::TestUA::post_form = sub { return {success => 1, status => 200, reason => 'OK', content => $_[2]} };
*HTTP::Simple::TestUA::post = sub { return {success => 1, status => 200, reason => 'OK', content => $_[2]{content}} };

is get('foo'), 'foo', 'get';
is_deeply getjson('[{"foo":"bar"}]'), [{foo => 'bar'}], 'getjson';
is_deeply head('bar'), {foo => 'bar'}, 'head';
is mirror('foo', 'bar'), 200, 'mirror';
is_deeply postform('foo', {foo => 'bar'}), {foo => 'bar'}, 'postform';
is_deeply postjson('foo', [{foo => 'bar'}]), '[{"foo":"bar"}]', 'postjson';

{
  local $HTTP::Simple::JSON = 'JSON::PP';
  is_deeply getjson('[{"foo":"bar"}]'), [{foo => 'bar'}], 'getjson with decode_json';
  is_deeply postjson('foo', [{foo => 'bar'}]), '[{"foo":"bar"}]', 'postjson with encode_json';

  local $HTTP::Simple::JSON = 'HTTP::Simple::FakeJSON';
  ok !eval { getjson('[{"foo":"bar"}]'); 1 }, 'getjson with missing json module';

  local *HTTP::Simple::FakeJSON::decode_json = sub { return [] };
  is_deeply getjson('[{"foo":"bar"}]'), [], 'getjson with fake decode_json';

  local $HTTP::Simple::JSON = 'HTTP::Simple::TestUA';
  ok !eval { getjson('[{"foo":"bar"}]'); 1 }, 'getjson with missing decode_json';
}

*HTTP::Simple::TestUA::post = sub {
  my $length = 0;
  my $buf;
  do { $buf = $_[2]{content}(); $length += length $buf } while defined $buf and length $buf;
  return {success => 1, status => 200, reason => 'OK', content => $length};
};

{
  open my $temph, '>:raw', $path or die "open failed: $!";
  print $temph "file contents\n";
}
is postfile('foo', $path), 14, 'postfile';

my $str = "\0"x(1024*1024);
{
  open my $temph, '>:raw', $path or die "open failed: $!";
  print $temph $str;
}
is postfile('foo', $path), 1024*1024, 'postfile with large buffer';

$str = "\xE2\x98\x83";
{
  open my $temph, '>:raw', $path or die "open failed: $!";
  print $temph $str;
}
is postfile('foo', $path), 3, 'postfile with encoded text';

*HTTP::Simple::TestUA::get = sub { $_[2]{data_callback}($_[1]); return {success => 1, status => 200, reason => 'OK'} };

open my $fakeout, '>', \my $buffer or die "failed to open scalar buffer: $!";
my $stdout = select $fakeout;
my $code = getprint('foo');
select $stdout;
is $code, 200, 'getprint';
is $buffer, 'foo', 'right contents';

is getstore('foo', $path), 200, 'getstore';
my $contents = do {
  open my $temph, '<', $path or die "open $path failed: $!";
  local $/;
  readline $temph;
};
is $contents, 'foo', 'right contents';

*HTTP::Simple::TestUA::get = sub { $_[2]{data_callback}($_[1]); return {success => 0, status => 400, reason => 'Bad Request'} };

undef $buffer;
open $fakeout, '>', \$buffer or die "failed to open scalar buffer: $!";
$stdout = select $fakeout;
$code = getprint('foo');
select $stdout;
is $code, 400, 'getprint HTTP 400';
is $buffer, 'foo', 'right contents';

is getstore('foo', $path), 400, 'getstore HTTP 400';
$contents = do {
  open my $temph, '<', $path or die "open $path failed: $!";
  local $/;
  readline $temph;
};
is $contents, 'foo', 'right contents';

*HTTP::Simple::TestUA::get = sub { return {success => 0, status => 400, reason => 'Bad Request'} };
*HTTP::Simple::TestUA::head = sub { return {success => 0, status => 500, reason => 'Internal Server Error'} };
*HTTP::Simple::TestUA::mirror = sub { return {success => 0, status => 404, reason => 'Not Found'} };
*HTTP::Simple::TestUA::post_form = sub { return {success => 0, status => 403, reason => 'Access Denied'} };
*HTTP::Simple::TestUA::post = sub { return {success => 0, status => 401, reason => 'Unauthorized'} };

ok !eval { get('foo'); 1 }, 'get HTTP error';
like $@, qr/400 Bad Request/, 'right error';
ok !eval { getjson('foo'); 1 }, 'getjson HTTP error';
like $@, qr/400 Bad Request/, 'right error';
ok !eval { head('foo'); 1 }, 'head HTTP error';
like $@, qr/500 Internal Server Error/, 'right error';
ok !eval { mirror('foo', 'bar'); 1 }, 'mirror HTTP error';
like $@, qr/404 Not Found/, 'right error';
ok !eval { postform('foo', 'bar'); 1 }, 'postform HTTP error';
like $@, qr/403 Access Denied/, 'right error';
ok !eval { postjson('foo', 'bar'); 1 }, 'postjson HTTP error';
like $@, qr/401 Unauthorized/, 'right error';
ok !eval { postfile('foo', $path); 1 }, 'postfile HTTP error';
like $@, qr/401 Unauthorized/, 'right error';

*HTTP::Simple::TestUA::get = sub { return {success => 0, status => 599, content => 'this is an error'} };
*HTTP::Simple::TestUA::head = sub { return {success => 0, status => 599, content => 'this is an error'} };
*HTTP::Simple::TestUA::mirror = sub { return {success => 0, status => 599, content => 'this is an error'} };
*HTTP::Simple::TestUA::post_form = sub { return {success => 0, status => 599, content => 'this is an error'} };
*HTTP::Simple::TestUA::post = sub { return {success => 0, status => 599, content => 'this is an error'} };

ok !eval { get('foo'); 1 }, 'get internal error';
like $@, qr/this is an error/, 'right error';
ok !eval { getjson('foo'); 1 }, 'getjson internal error';
like $@, qr/this is an error/, 'right error';
ok !eval { head('foo'); 1 }, 'head internal error';
like $@, qr/this is an error/, 'right error';
ok !eval { getprint('foo'); 1 }, 'getprint internal error';
like $@, qr/this is an error/, 'right error';
ok !eval { mirror('foo', 'bar'); 1 }, 'mirror internal error';
like $@, qr/this is an error/, 'right error';
ok !eval { postform('foo', 'bar'); 1 }, 'postform internal error';
like $@, qr/this is an error/, 'right error';
ok !eval { postjson('foo', 'bar'); 1 }, 'postjson internal error';
like $@, qr/this is an error/, 'right error';
ok !eval { postfile('foo', $path); 1 }, 'postfile internal error';
like $@, qr/this is an error/, 'right error';

done_testing;
