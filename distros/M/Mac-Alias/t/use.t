#!perl

use v5.26;
use warnings;
use lib 'lib';

use Test::More;
use Test::Warnings;

BEGIN { plan tests => 1 + 6 + 1; }

BEGIN { use_ok('Mac::Alias', ':all') }

sub is_exported {
	my $name = shift;
	is \&{$name}, \&{"Mac::Alias::$name"}, $name;
}

is_exported 'is_alias';
is_exported 'make_alias';
is_exported 'parse_alias';
is_exported 'read_alias';
is_exported 'read_alias_mac';
is_exported 'read_alias_perl';

done_testing;
