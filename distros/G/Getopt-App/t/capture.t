use Test2::V0;
use Getopt::App -capture;

print STDOUT "# STDOUT is not yet captured\n" if $ENV{HARNESS_IS_VERBOSE};
print STDERR "# STDERR is not yet captured\n" if $ENV{HARNESS_IS_VERBOSE};

subtest import => sub {
  ok !__PACKAGE__->can('new'), 'cannot new';
  ok !__PACKAGE__->can('run'), 'cannot run';
};

subtest capture => sub {
  my $res = capture(\&demo, ["foo bar"]);
  is $res, ["foo bar\n", "some warning\n", 42], 'foo bar';
};

subtest die => sub {
  my $res = capture(sub { $! = 42; die 'not cool' });
  like $res, ["", qr{^not cool}, 42], 'captured';
};

print STDOUT "# STDOUT got restored\n" if $ENV{HARNESS_IS_VERBOSE};
print STDERR "# STDERR got restored\n" if $ENV{HARNESS_IS_VERBOSE};

done_testing;

sub demo {
  print STDERR "some warning\n";
  print STDOUT join "\n", $_[0][0], "";
  return 42;
}
