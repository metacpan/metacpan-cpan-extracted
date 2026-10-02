use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Path::Tiny qw(path);
use POSIX qw(WNOHANG);
use FindBin;
use Langertha::Skeid;

# A config named on the command line that is not there is an operator error, not "run with no
# config": serve used to start with no nodes and answer every request 503, with nothing but a
# "Config: (none)" line to say why (skeid k68). A file that vanishes after a good load is a
# different case -- the last good config stays in force -- but it must not go unmentioned.

my $bin = path($FindBin::Bin)->parent->child('bin', 'skeid')->stringify;
my $tmp = tempdir(CLEANUP => 1);

# Runs bin/skeid with the test's @INC and returns (exit code, output). A serve that does start
# is killed after $timeout seconds and reported as exit code -1.
sub run_skeid {
  my (@args) = @_;
  my $out = path($tmp)->child('out-' . $$ . '-' . int(rand(1e9)));
  local $ENV{PERL5LIB} = join(':', grep { !ref } @INC);
  my $pid = fork;
  die "fork: $!" unless defined $pid;
  if (!$pid) {
    open STDOUT, '>', "$out" or die $!;
    open STDERR, '>&', \*STDOUT or die $!;
    chdir $tmp or die $!;
    exec $^X, $bin, @args;
    die "exec: $!";
  }
  my $deadline = time + 20;
  my $code;
  while (time < $deadline) {
    if (waitpid($pid, WNOHANG) == $pid) { $code = $? >> 8; last }
    select(undef, undef, undef, 0.1);
  }
  unless (defined $code) {
    kill 'TERM', $pid;
    waitpid($pid, 0);
    $code = -1;
  }
  return ($code, (-f "$out" ? $out->slurp_utf8 : ''));
}

my $missing = "$tmp/does/not/exist.yaml";

{
  my ($code, $output) = run_skeid('serve', '--listen', '127.0.0.1:0', '--config', $missing);
  isnt $code, -1, 'serve with a missing --config does not start';
  ok $code > 0, 'and exits non-zero';
  like $output, qr/\Q$missing\E/, 'the error names the path';
  like $output, qr/not found|does not exist|no such/i, 'and says what is wrong with it';
  unlike $output, qr/Starting Skeid proxy/, 'nothing claims the proxy started';
}

{
  my ($code, $output) = run_skeid('serve', '--listen', '127.0.0.1:0', '--config', $tmp);
  ok $code > 0, 'serve with a directory as --config exits non-zero';
  like $output, qr/\Q$tmp\E/, 'naming the path';
}

{
  my ($code, $output) = run_skeid('usage', '--config', $missing);
  ok $code > 0, 'usage with a missing --config exits non-zero';
  like $output, qr/\Q$missing\E/, 'naming the path';
}

# --- The library refuses a missing file at construction as well ------------------------------
{
  my $skeid = eval { Langertha::Skeid->new(config_file => $missing) };
  ok !$skeid, 'Langertha::Skeid->new with a missing config_file dies';
  like $@, qr/\Q$missing\E/, 'naming the path';
}

# --- A file that vanishes after a good load: the config is kept, and it is said once ---------
{
  my $file = path($tmp)->child('skeid.yaml');
  $file->spew("nodes:\n  - id: kept\n    url: http://kept/v1\n");
  my $skeid = Langertha::Skeid->new(config_file => "$file");
  is $skeid->list_nodes->[0]{id}, 'kept', 'loaded';

  $file->remove;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $skeid->call_function('nodes.list', {}) for 1 .. 5;

  is $skeid->list_nodes->[0]{id}, 'kept', 'the last good config stays in force';
  is scalar(grep { /\Q$file\E/ } @warnings), 1, 'the vanished file is reported once, not per request'
    or diag explain \@warnings;

  $file->spew("nodes:\n  - id: back\n    url: http://back/v1\n");
  utime(time + 10, time + 10, "$file");
  $skeid->call_function('nodes.list', {});
  is $skeid->list_nodes->[0]{id}, 'back', 'the file coming back is read again';

  $file->remove;
  $skeid->call_function('nodes.list', {});
  is scalar(grep { /\Q$file\E/ } @warnings), 2, 'vanishing again is reported again';
}

done_testing;
