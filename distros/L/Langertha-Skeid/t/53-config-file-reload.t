use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use YAML::PP;
use Langertha::Skeid;

my $NOW = 3_000_000;

sub write_config {
  my ($path, $yaml, $mtime) = @_;
  open my $out, '>', $path or die "open $path: $!";
  print {$out} $yaml or die "write $path: $!";
  close $out or die "close $path: $!";
  utime($mtime, $mtime, $path) or die "utime $path: $!";
  return;
}

# A parse failure for one unchanged file version is retried on a clock, not on every function
# dispatch. A different version bypasses that retry window so a correction takes effect promptly.
{
  my ($fh, $path) = tempfile();
  print {$fh} "nodes:\n  - id: kept\n    url: http://kept/v1\n";
  close $fh;
  my $mtime = (stat($path))[9];

  my $loads = 0;
  my $load_file = \&YAML::PP::load_file;
  no warnings 'redefine';
  local *Langertha::Skeid::_now = sub { $NOW };
  local *YAML::PP::load_file = sub {
    $loads++;
    return $load_file->(@_);
  };

  my $skeid = Langertha::Skeid->new(config_file => $path);
  is $loads, 1, 'the initial config is parsed once';

  write_config($path, "nodes: [\n", $mtime + 10);
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };
  $skeid->call_function('nodes.list', {}) for 1 .. 20;

  is $loads, 2, 'twenty dispatches parse one unchanged malformed file version only once';
  is $skeid->list_nodes->[0]{id}, 'kept', 'the last good config stays in force';
  is $skeid->reload_status->{ok}, 0, 'the parse failure is recorded';

  write_config(
    $path,
    "nodes:\n  - id: fixed\n    url: http://fixed/v1\n",
    $mtime + 20,
  );
  $skeid->call_function('nodes.list', {});

  is $loads, 3, 'a changed file version is parsed without waiting for the failed-version retry';
  is $skeid->list_nodes->[0]{id}, 'fixed', 'the corrected config takes effect';
  is_deeply $skeid->reload_status, { ok => 1 }, 'a successful correction clears the failure';
}

# A read can fail transiently after stat succeeded. The same file version therefore needs a
# bounded retry; remembering it forever would leave a valid config unapplied until another edit.
{
  my ($fh, $path) = tempfile();
  print {$fh} "nodes:\n  - id: old\n    url: http://old/v1\n";
  close $fh;
  my $mtime = (stat($path))[9];

  my ($loads, $fail_next) = (0, 0);
  my $load_file = \&YAML::PP::load_file;
  no warnings 'redefine';
  local *Langertha::Skeid::_now = sub { $NOW };
  local *YAML::PP::load_file = sub {
    $loads++;
    die "temporary config read failure\n" if $fail_next-- > 0;
    return $load_file->(@_);
  };

  my $skeid = Langertha::Skeid->new(config_file => $path);
  write_config(
    $path,
    "nodes:\n  - id: recovered\n    url: http://recovered/v1\n",
    $mtime + 10,
  );
  $fail_next = 1;
  local $SIG{__WARN__} = sub { };

  $skeid->call_function('nodes.list', {});
  is $skeid->list_nodes->[0]{id}, 'old', 'a transient read failure keeps the old config';
  is $loads, 2, 'the changed file was read once';

  $skeid->call_function('nodes.list', {}) for 1 .. 20;
  is $loads, 2, 'dispatches inside the retry window do not hammer the same file version';

  $NOW += 1;
  $skeid->call_function('nodes.list', {});
  is $loads, 3, 'the same file version is retried after the bounded delay';
  is $skeid->list_nodes->[0]{id}, 'recovered', 'the valid config then takes effect without another edit';
}

# A file can be replaced after YAML has parsed the bytes but before the reload records its mtime.
# The parsed version must be the one marked as seen, so the replacement is loaded next time.
{
  my ($fh, $path) = tempfile();
  print {$fh} "nodes:\n  - id: old\n    url: http://old/v1\n";
  close $fh;
  my $mtime = (stat($path))[9];

  my ($loads, $replace_after_load) = (0, 0);
  my $load_file = \&YAML::PP::load_file;
  no warnings 'redefine';
  local *YAML::PP::load_file = sub {
    my $loaded = $load_file->(@_);
    $loads++;
    if ($replace_after_load) {
      $replace_after_load = 0;
      write_config(
        $path,
        "nodes:\n  - id: latest\n    url: http://latest/v1\n",
        $mtime + 20,
      );
    }
    return $loaded;
  };

  my $skeid = Langertha::Skeid->new(config_file => $path);
  write_config(
    $path,
    "nodes:\n  - id: middle\n    url: http://middle/v1\n",
    $mtime + 10,
  );
  $replace_after_load = 1;

  $skeid->call_function('nodes.list', {});
  is $skeid->list_nodes->[0]{id}, 'middle', 'the version whose bytes were parsed is applied first';
  $skeid->call_function('nodes.list', {});
  is $skeid->list_nodes->[0]{id}, 'latest', 'a replacement during the prior read is loaded next';
  is $loads, 3, 'the initial, parsed, and replacement versions are each read once';
}

done_testing;
