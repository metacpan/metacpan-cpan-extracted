#!perl -T

use Test::More tests => 5;

use Digest::PasswordComposer;

can_ok('Digest::PasswordComposer',('new'));

my $pwdcomposer = Digest::PasswordComposer->new();

isa_ok($pwdcomposer, 'Digest::PasswordComposer');

can_ok('Digest::PasswordComposer',('domain'));

is($pwdcomposer->domain(),'');

$pwdcomposer->domain('perl.org');

is($pwdcomposer->domain(),'perl.org');

