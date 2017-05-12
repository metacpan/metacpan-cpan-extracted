# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';
use GitDVTest;

plan tests => (@counts * 3 + 1) * @versions; # (counts * formats + isa) * versions
my $mock = mock_gw;
$mock->set_always('describe', undef);

use Git::DescribeVersion;

foreach my $version ( @versions ){
  my $fv = $$version[0];
  my $gv = Git::DescribeVersion->new(git_wrapper => $mock, first_version => $fv);
  isa_ok($gv, 'Git::DescribeVersion');
  foreach my $count ( @counts ){
    my ($sum, @lines) = @$count;
    $mock->mock('count_objects', sub { @lines });

  test_expectations($gv, $version, $sum, sub {
    my ($exp, $desc) = @_;
    is($gv->version, $exp, $desc);
  });
  }
}
