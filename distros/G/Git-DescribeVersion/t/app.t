# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
eval "use Test::Output";
plan skip_all => "Test::Output required for testing STDOUT"
  if $@;

use lib 't/lib';
use GitDVTest;

plan tests => @commits * @versions * 3 * 2; # commits * versions * formats * (run + App->run)

my $mock = mock_gw;
use Git::DescribeVersion;
my $gv = {git_wrapper => $mock};

use Git::DescribeVersion::App;

foreach my $commits ( @commits ){
  $mock->set_series('describe', map { (description($$_[0], $commits)) x (3 * 2) } @versions);
  foreach my $version ( @versions ){
  test_expectations($gv, $version, $commits, sub {
    my ($exp, $desc) = @_;
    stdout_is(sub{ run($gv) }, "$exp\n", $desc);
    stdout_is(sub{ Git::DescribeVersion::App->run($gv) }, "$exp\n", $desc);
  });
  }
}
