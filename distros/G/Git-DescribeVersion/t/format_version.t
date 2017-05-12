# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use version 0.82;

my $vobject = version->parse('v1.2.3');

my %tests = (
  'v1.2.3' => [qw(
    dotted
    normal
    v-string
    v
    dot
    string
    ov
  )],
  '1.2.3' => [qw(
    no-v-string
    no-vstring
    no-v
    no_v
    no+vstring
    novstring
    nov
  )],
  '1.002003' => [qw(
    decimal
    default
    compatible
    pirate
  )]
);

plan tests => (map { @$_ } values %tests) + 1; # tests + new_ok

my $mod = 'Git::DescribeVersion';
eval "require $mod" or die $@;
my $gdv = new_ok($mod);

foreach my $version ( keys %tests ){
  foreach my $format ( @{$tests{$version}} ){
    $gdv->{format} = $format;
    is($gdv->format_version($vobject), $version, "format '$format' produces version '$version'");
  }
}
