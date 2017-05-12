#!perl -T

use Test::More tests => 2;

use Digest::PasswordComposer;

my $pwdcomposer = Digest::PasswordComposer->new();

$pwdcomposer->domain('perl.org');

is($pwdcomposer->password('FooBarBAZ'),'ecfe26cc');

is($pwdcomposer->password('perl.org'),'27fa2fe7');

