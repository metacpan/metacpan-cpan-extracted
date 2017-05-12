#!/usr/bin/perl

use warnings;
use strict;

use Test::More no_plan =>;

use JSON::ON;

my @mods;
my $j = JSON::ON->new( module_handler => sub {push(@mods, @_)} );
ok($j, 'constructor') or die "this is not going well";

my $stuff = {
  scalar => bless(\(my $s = 7), 'a_scalar'),
  hash   => bless({}, 'a_hash'),
  array  => bless([], 'an_array'),
};
my $enc = $j->encode($stuff);
ok($enc, 'encoded');
# warn $enc;
# my $decoder = JSON::ON->JSON_CLASS->can('decode_json') or die "bah";
# print join("\n", map({keys %$_} values %{$decoder->($enc)}));

{
  my $dec = $j->decode($enc);

  is(scalar(@mods), 3);
  is_deeply([sort @mods], [qw(a_hash a_scalar an_array)], 'mod hook');
  is_deeply($dec, $stuff);
}



# vim:ts=2:sw=2:et:sta
