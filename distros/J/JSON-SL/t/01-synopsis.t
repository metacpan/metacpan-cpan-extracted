#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use JSON::SL;
use Data::Dumper;
use Devel::Peek;

my $txt = <<'EOT';
{
    "some" : {
        "partial" : [42]
    },
    "other" : {
        "partial" : "a string"
    },
    "more" : {
        "more" : "stuff"
EOT

my $json = JSON::SL->new(512);
my $jpath = "/^/partial";
$json->set_jsonpointer( [$jpath] );
my @results = $json->feed($txt);

is($results[0]->{Value}->[0], 42, "Got first value");
is($results[1]->{Value}, 'a string', "Got second value");

is($results[0]->{Path}, '/some/partial', "First path matches");
is($results[1]->{Path}, '/other/partial', "Second path matches");

ok($results[0]->{JSONPointer} eq $jpath
   && $results[1]->{JSONPointer} eq $jpath,
   "Both results share same JSONPointer ($jpath)");

ok(exists $json->root->{some}, "Matching container still in root");
ok(scalar keys %{$json->root->{some} } == 0, "but has no entries..");

is($json->root->{more}->{more}, "stuff", "Still have some stuff there..");

done_testing();
