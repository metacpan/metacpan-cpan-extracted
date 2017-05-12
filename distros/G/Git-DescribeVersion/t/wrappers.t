# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More tests => 3 * ((2 * 2) + 2); # wrappers * ((methods * tests) + extra tests)
use Test::MockObject 1.09;
use Test::MockObject::Extends 1.09;
use lib 't/lib';
use GitDVTest;
use Git::DescribeVersion ();

my %opts = (
  match_pattern => 'x*',
);

sub test_version_from {
  my ($gdv, $opt, $mod, @exp) = @_;
  my @sent = (
    [qw(describe), ['--match', $opts{match_pattern}], qw(--tags --long)],
    [qw(count-objects -v)],
  );

  # This is that black magic that Test::Tutorial talks about.
  # We want to test that we're sending the correct arguments to the different
  # modules, so we're going to wrap the internal 'git' method
  # so we can inspect the values it receives and returns.

  isa_ok($gdv, 'Git::DescribeVersion');
  is($gdv->{git}, $opt, "using $opt()");
  my $mock = Test::MockObject::Extends->new($gdv);

  # grab a reference to the original method
  my $original = $gdv->can('git');

  foreach my $method ( qw(version_from_describe version_from_count_objects) ){
    $mock->mock('git',
      sub {
        # test supplied arguments (ignoring invocant)
        my ($obj, @sentargs) = @_;
        is_deeply(\@sentargs, shift(@sent), "$mod $method received");

        # call original (list context)
        my @args = $original->(@_);

        # test returned arguments
        is_deeply(\@args,     shift(@exp),  "$mod $method returned");

        # return fake arguments so processing can continue... we're done testing
        return (1, 0);
      }
    );
    $gdv->$method();
  }
}

# set up mock objects before calling gdv->new
mock_gw;
mock_gr;

{
  my ($opt, $mod) = qw(git_repository Git::Repository);
  my $gdv = Git::DescribeVersion->new(%opts, $opt => mock_gr);
  test_version_from($gdv, $opt, $mod,
    [qw(describe --match), $opts{match_pattern}, qw(--tags --long)],
    [qw(count-objects -v)]
  );
}

{
  my ($opt, $mod) = qw(git_wrapper Git::Wrapper);
  my $gdv = Git::DescribeVersion->new(%opts, $opt => mock_gw);
  test_version_from($gdv, $opt, $mod,
    [{match => $opts{match_pattern}, tags => 1, long => 1}],
    [{v => 1}]
  );
}

SKIP: {
  skip 'backtick tests designed for Linux', 6
    if $^O !~ /linux|unix/i;

  my ($opt, $mod) = qw(git_backticks backticks);

  my $gdv = Git::DescribeVersion->new(%opts, $opt => 'echo');
  test_version_from($gdv, $opt, $mod, 
    [qq|describe --match $opts{match_pattern} --tags --long\n|],
    [qq|count-objects -v\n|]
  );
}
