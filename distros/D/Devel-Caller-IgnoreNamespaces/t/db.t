#!perl

use warnings;

use Devel::Caller::IgnoreNamespaces;
use Carp;

use Test::More tests => 1;

$SIG{__WARN__} = sub { fail($_[0]) if($_[0] =~ /DB::args were not set/) };

foo(1);
sub foo { carp("Hlagh"); }

pass("Hurrah");
