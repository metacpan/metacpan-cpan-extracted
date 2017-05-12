use strict;
use Test::More;
use MIME::Lite;
use_ok('MIME::Lite::Generator');

my $msg = MIME::Lite->new(
	From     => 'me@myhost.com',
	To       => 'you@yourhost.com',
	Cc       => 'some@other.com, some@more.com',
	Subject  => 'Helloooooo!',
	Encoding => 'base64',
	Data     => 'Привет мир!'
);

my $gen = MIME::Lite::Generator->new($msg);
ok($gen, 'object created');
isa_ok($gen, 'MIME::Lite::Generator');

done_testing;
