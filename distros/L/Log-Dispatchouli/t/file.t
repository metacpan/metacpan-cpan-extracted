use strict;
use warnings;

use Log::Dispatchouli;
use Test::More 0.88;
use File::Spec::Functions qw( catfile );
use File::Temp qw( tempdir );

my $tmpdir = tempdir( TMPDIR => 1, CLEANUP => 1 );

sub logger_and_warnings {
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_; };
  my $logger = Log::Dispatchouli->new($_[0]);
  return ($logger, @warnings);
}

{
  {
    my ($logger, @warnings) = logger_and_warnings({
      log_pid  => 1,
      ident    => 't_file',
      to_file  => 1,
      log_path => $tmpdir,
    });

    isa_ok($logger, 'Log::Dispatchouli');

    is($logger->ident, 't_file', '$logger->ident is available');

    is(@warnings, 1, "we got a warning");
    like($warnings[0], qr{to_file.+deprecated}, "...about to_file");

    $logger->log([ "point: %s", {x=>1,y=>2} ]);
  }

  my ($log_file) = glob(catfile($tmpdir, 't_file.*'));
  ok -r $log_file, 'log file with ident name';

  like slurp_file($log_file),
    qr/^.+? \[$$\] point: \{\{\{("[xy]": [12](, ?)?){2}\}\}\}$/,
    'logged timestamp, pid, and hash';
}

{
  {
    my ($logger, @warnings) = logger_and_warnings({
      log_pid  => 0,
      ident    => 'ouli_file',
      to_file  => 1,
      log_file => 'ouli.log',
      log_path => $tmpdir,
      file_format => sub { "$$: sec:" . time() . " m:" . $_[0] },
    });

    isa_ok($logger, 'Log::Dispatchouli');

    is($logger->ident, 'ouli_file', '$logger->ident is available');

    is(@warnings, 1, "we got a warning");
    like($warnings[0], qr{to_file.+deprecated}, "...about to_file");

    $logger->log([ "point: %s", {x=>1,y=>2} ]);
  }

  my $log_file = catfile($tmpdir, 'ouli.log');
  ok -r $log_file, 'log file with custom name';

  like slurp_file($log_file),
    qr/^$$: sec:\d+ m:point: \{\{\{("[xy]": [12](, ?)?){2}\}\}\}$/,
    'custom file callbacks';
}

done_testing;

sub slurp_file {
  my ($file) = @_;
  open my $fh, '<', $file
    or die "Failed to open $file: $!";
  local $/;
  return <$fh>;
}
