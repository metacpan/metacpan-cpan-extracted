use strict;
use Test::More tests => 9;

require 't/testutils.pl';

use File::Spec;
use Find::Lib 'mylib';
use_ok 'MyLib';

in_inc( 'mylib' );

my $base = Find::Lib->base;
ok $base, 'base() returns the directory of your script';
is $base, $Find::Lib::Base, "It's accessible from outside";

is (Find::Lib->catfile('something'), File::Spec->catfile($base, 'something'));
is (Find::Lib->catdir('dir'), File::Spec->catdir($base, 'dir'));
is (Find::Lib->catdir('..', 'dir'), File::Spec->catdir($base, '..', 'dir'));
unlike (Find::Lib->catdir("x"), qr/Find::Lib/, 'Bug with dumb Exporter use');
