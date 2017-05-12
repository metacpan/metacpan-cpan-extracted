#! /usr/bin/perl

use strict;
use warnings;

use Test::More tests => 2;

use File::Redirect qw(mount);

my $path = $0;
$path =~ s/04_zip.t/Foo-Bar-0.01.zip/;

mount( 'Zip', $path, 'zip:');

use lib qw(zip:/Foo-Bar-0.01/lib);

require Foo::Bar;

ok(1, 'require');

ok(42 == Foo::Bar::foo(), 'compiled');
