use strict;
use warnings;
use Test::More;
use Getopt::App -capture;

subtest import => sub {
  ok !__PACKAGE__->can('new'), 'cannot new';
  ok !__PACKAGE__->can('run'), 'cannot run';
};

subtest capture => sub {
  my $res = capture(\&demo, ["foo bar"]);
  is_deeply $res, ["foo bar\n", "some warning\n", 42], 'foo bar';
};

done_testing;

sub demo {
  print STDERR "some warning\n";
  print STDOUT join "\n", $_[0][0], "";
  return 42;
}
