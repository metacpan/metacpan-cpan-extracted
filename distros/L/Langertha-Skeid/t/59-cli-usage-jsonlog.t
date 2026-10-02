use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use Path::Tiny qw(path);
use POSIX qw(WNOHANG);
use FindBin;
use Langertha::Skeid;

# `skeid usage` against a jsonlog store (skeid k69). The report printed "Argument ... isn't
# numeric" and an event id cut down to its date (the jsonlog id is a string, printed with %d),
# and "Store: (none)" for a store that plainly exists. And there was no option to name a jsonlog
# store at all -- only a config could, while --db and --dsn name the DBI stores.

my $bin = path($FindBin::Bin)->parent->child('bin', 'skeid')->stringify;
my $tmp = tempdir(CLEANUP => 1);

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
    exec $^X, '-w', $bin, @args;
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

sub record_two {
  my ($store) = @_;
  my $skeid = Langertha::Skeid->new(usage_store => $store);
  my @ids;
  for my $key (qw(k_alice k_bob)) {
    my $res = $skeid->call_function('usage.record', {
      api_format => 'openai', api_key_id => $key, model => 'm1', status_code => 200, ok => 1,
      metrics => { usage => { input => 10, output => 5, total => 15 } },
    });
    push @ids, $res->{id};
  }
  return @ids;
}

sub check_report {
  my ($label, $code, $output, $store_label, @ids) = @_;
  is $code, 0, "$label: exits 0" or diag $output;
  unlike $output, qr/isn't numeric|uninitialized/, "$label: no warnings";
  like $output, qr/^Usage backend: jsonlog$/m, "$label: backend named";
  like $output, qr/^Store: \Q$store_label\E$/m, "$label: the store is named by its path";
  like $output, qr/Totals: requests=2 input=20 output=10 total=30/, "$label: totals";
  like $output, qr/\Q$_\E/, "$label: event id $_ printed whole" for @ids;
}

# --- Directory mode, named on the command line ---------------------------------------------
{
  my $dir = "$tmp/events";
  my @ids = record_two({ backend => 'jsonlog', path => $dir, mode => 'dir' });
  is scalar(grep { defined && /-/ } @ids), 2, 'jsonlog ids are strings';

  check_report('--log-path dir', run_skeid('usage', '--log-path', $dir), $dir, @ids);
  check_report('--jsonlog dir', run_skeid('usage', '--jsonlog', $dir), $dir, @ids);
  check_report('--backend jsonlog --log-path dir',
    run_skeid('usage', '--backend', 'jsonlog', '--log-path', $dir), $dir, @ids);
}

# --- File mode, named on the command line ---------------------------------------------------
{
  my $file = "$tmp/usage.jsonl";
  my @ids = record_two({ backend => 'jsonlog', path => $file, mode => 'file' });
  check_report('--log-path file', run_skeid('usage', '--log-path', $file), $file, @ids);
}

# --- Through the config, as before ---------------------------------------------------------
{
  my $dir = "$tmp/cfg-events";
  my @ids = record_two({ backend => 'jsonlog', path => $dir, mode => 'dir' });
  my $cfg = path($tmp)->child('usage.yaml');
  $cfg->spew("usage_store:\n  backend: jsonlog\n  path: $dir\n");
  check_report('--config', run_skeid('usage', '--config', "$cfg"), $dir, @ids);
}

done_testing;
