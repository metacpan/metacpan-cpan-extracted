# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
package GitDVTest;
use strict;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
  &description
  &expect_warning
  &expectation
  &test_expectations
  &mock_gr
  &mock_gw
  &return_args
  @versions
  @commits
  @counts
);
use Test::More 0.96;
use Test::MockObject::Extends 1.09;
use version 0.82;

my $test_warn_mod = 'Test::Output';
my $test_warn = eval "use $test_warn_mod; 1";
$test_warn = 0 if $@;

# use sprintf for ease/clarity; use %d to turn '' into 0
sub description { sprintf '%s-%d-%s', $_[0], $_[1], 'gdeadbeef' }

sub expect_warning ($$;$) {
  my $sub = pop @_;
  my ($regexp, $message) = @_;
  $message ||= 'warning expected:';

  if( $test_warn ){
    stderr_like($sub, $regexp, $message);
  }
  else {
    # skip the test, but still run the coderef
    SKIP: { skip "$test_warn_mod required for testing warnings", 1; }
    # mention that we're expecting a warning
    diag($message);
    &$sub;
  }
}

sub expectation ($$$) {
  my ($gv, $version, $count) = @_;
  my ($tag, $dec, $dot, $regexp) = @$version;
  $tag = '~' if !defined $tag;
  $count ||= 0;

  # hack
  $gv->{version_regexp} = $regexp ||
    $Git::DescribeVersion::Defaults{version_regexp};

  my $exp    = defined $dec ? sprintf(($dec =~ /\./ ? "%s%03d" : "%s.%03d000"), $dec, $count): undef;
  my $dotted = defined $dot ? version->parse("$dot.$count")->normal : undef;
  my %values = (
    decimal => $exp,
    dotted  => $dotted,
    no_v    => (defined $dotted ? substr($dotted, 1) : undef),
  );
  return { map {
    ($_ => [$values{$_}, sprintf("describe %-15s in %s as %-15s",
      "$tag-$count", $_, defined $values{$_} ? $values{$_} : '~')])
  } keys %values };
}

sub return_args { shift if ref $_[0]; return @_ }

sub test_expectations ($$$&) {
  my ($gv, $version, $commits, $sub) = @_;
  my $exps = expectation($gv, $version, $commits);
  while( my ($format, $expdesc) = each %$exps ){
    $gv->{format} = $format;
    $sub->(@$expdesc);
  }
}

my $mocked = {};

sub mock_gr {
  return $mocked->{gr} ||=
    mock_wrapper(qw(Git::Repository run command));
}
sub mock_gw {
  return $mocked->{gw} ||=
    mock_wrapper(qw(Git::Wrapper describe count_objects __version));
}

sub mock_wrapper () {
  my ($pack, @methods) = @_;
  my $mock = Test::MockObject->new();
  my %methods = map { ($_, \&return_args) } @methods;
  $mock->fake_module($pack, %methods);
  $mock->mock($_ => $methods{$_}) for keys %methods;
  $mock;
}

# Should we be using version->parse->numify
# instead of specifying the expectation explicitly?

# make sub-arrays like (['v0.1', '0.001', 'v0.1', 'version_regexp'])
our @versions = map { [(split(/\s+/))[1, 2, 3, 4]] } split(/\n/, <<TAGS);
  v0.1                      0.001     v0.1
  v0.001                    0.001     v0.1
  v1.2                      1.002     v1.2
  v1.20                     1.020     v1.20
  v1.200                    1.200     v1.200
  v1.02                     1.002     v1.2
  v1.002                    1.002     v1.2
  v1.2.3                    1.002003  v1.2.3
  v1.02.03                  1.002003  v1.2.3
  v1.002003                 1.2003    v1.2003
  v2.1                      2.001     v2.1
  v2.1234                   2.1234    v2.1234
  ver-0.012                 0.012     v0.12      ver-(.+)
  ver-0.012                 0.012     v0.12
  ver|3.222                 3.222     v3.222     ver\\|(.+)
  ver|3.222                 3.222     v3.222
  4.1-rel1021               4.001     v4.1       ([0-9.]+)-rel.+
  4.1-rel1021               4.001     v4.1
  4.1-rel10.21              10.021    v10.21     rel(\\S+)
  release-1.2-narf          1.002     v1.2
  release-1.4.2-narf        1.004     v1.4       \\w+-([0-9.]+)\\.\\d-narf
  release-1.2-narf          1         v1         \\w+-(\\d+)\\.\\d-narf
  SILLY1.4TAG               1.004     v1.4
  date-12.05-ver-10.21-foo  10.021    v10.21     date-[0-9.]+-ver-([0-9.]+)-\\w+
  date-12.05-ver-10.21-foo  12.005    v12.5
TAGS

our @commits = qw(0 8 12 49 99 135 999 1234);

# make sub-arrays like (['0', 'count: 0', 'size: 0'])
our @counts = map { [split(/\n/)] } split(/\n\n/, <<COUNTS);
204
count: 204
size: 816
in-pack: 0
packs: 0
size-pack: 0
prune-packable: 0
garbage: 0

1006
count: 604
size: 816
in-pack: 402

999
count: 999
in-pack: 0

322
count: 222
in-pack: 100

24
count: 24

7
in-pack: 7
COUNTS

1;
