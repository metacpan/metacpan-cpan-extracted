# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use GitDVTest;

my @tests = (
  [1,           2, '1',        'v1',           {}],
  [1.2,         3, '1.002',    'v1.2',         {}],

  [undef,   undef, '0.001',    'v0.1',         {}],

  [undef,   undef, '2.001',    'v2.1',         {first_version => '2.1'}],
  [undef,   undef, '2.001002', 'v2.1.2',       {first_version => '2.1.2'}],

  [undef,       3, '2.001',    'v2.1',         {first_version => '2.1'}],
  [undef,       3, '2.010',    'v2.10',        {first_version => '2.10'}],

  [undef,       4, '2.001003', 'v2.1.3',       {first_version => '2.1.3'}],

  [3.4,     undef, '3.004',    'v3.4',         {}],
  ['v3.4',  undef, '3.004',    'v3.4',         {}],
  ['3.4.4', undef, '3.004004', 'v3.4.4',       {}],
  ['3.4.4',    52, '3.004004', 'v3.4.4',       {}],

  [undef,   undef, undef,         undef,       {first_version => undef}],

  ['x',       'y', undef,         undef,       {}],
  [' ',     '201', undef,         undef,       {}],
  ['4',     'ppp', undef,         undef,       {}],
);

# tests * (formats + isa) + (formats * warnings)
plan tests => @tests * (3 + 1) + (3 * grep { !defined $$_[2] } @tests);

my $mod = 'Git::DescribeVersion';
eval "require $mod" or die $@;

foreach my $test ( @tests ){
  my ($prefix, $count, $dec, $dot, $opts) = @$test;
  my $gdv = $mod->new($opts);
  isa_ok($gdv, $mod);
test_expectations($gdv, [$prefix, $dec, $dot], $count, sub {
  my ($exp, $desc) = @_;

  my $parsed;
  my $parse = sub { $parsed = $gdv->parse_version($prefix, $count); };

  defined $exp
    ? &$parse
    : expect_warning(
      (exists $opts->{first_version} && !defined($opts->{first_version})
        ? qr/could not be determined/
        : qr/not a valid version string/),
      $parse);

  is($parsed, $exp, $desc);
});
}
