# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Log::Info functions

This package tests the enable_file_channel function of Log::Info.

=cut

use Fatal      1.02 qw( open seek close );
use Fcntl      1.03 qw( :seek );
use FindBin    1.42 qw( $Bin );
use Test       1.13 qw( ok plan );

BEGIN { unshift @INC, $Bin };

use test qw( evcheck save_output restore_output tmpnam );


# Sink names for playing with
use constant SINK1 => 'sink1';

# Message texts for playing with
use constant MESSAGE1 => 'Mickey Murphy';
use constant MESSAGE2 => 'PC McGarry';
use constant MESSAGE3 => 'Captain Snort';
use constant MESSAGE4 => 'Sergeant Major Grout';

BEGIN {
  plan tests  => 22;
       todo   => [],
       ;
}

# -------------------------------------

sub read_file {
  my ($fn) = @_;
  open my $fh, '<', $fn;
  local $/ = undef;
  my $contents = <$fh>;
  close $fh;
  return $contents;
}

sub read_fh {
  my ($fh) = @_;
  my $pos = tell $fh;
  seek $fh, 0, SEEK_SET;
  local $/ = undef;
  my $contents = <$fh>;
  seek $fh, $pos, SEEK_SET;
  return $contents;
}

# ----------------------------------------------------------------------------

use Log::Info qw( :default_channels :log_levels Log );

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

ok 1, 1, 'compilation';

# -------------------------------------

=head2 Tests 2--4: log to file

Invoke

  enable_file_channel(CHAN_PROGRESS, $tmpfn, '*test A*', 'tmpfile');

(1) Test no exception thrown.

Log MESSAGE1 to CHAN_PROGRESS (at level LOG_INFO)

(2) Test no exception thrown.

(3) Check message is written to file.

=cut

{
  my $tmpfn = tmpnam;

  ok evcheck(sub {
               Log::Info::enable_file_channel
                 (CHAN_PROGRESS, $tmpfn, '*test A*', 'tmpfile');
             }), 1, 'log to file (1)';

  ok evcheck(sub {
               Log(CHAN_PROGRESS, LOG_INFO, MESSAGE1);
             }), 1, 'log to file (2)';

  ok read_file($tmpfn), MESSAGE1 . "\n", 'log to file (3)';
}

# -------------------------------------

my ($tmpnam, $tmpfh) = tmpnam;

=head2 Tests 5--7: log to file descriptor

Invoke

  enable_file_channel(CHAN_PROGRESS, ':' .fileno($tmpfh), '*test B*', 'tmpfile');

(1) Test no exception thrown.

Log MESSAGE2 to CHAN_PROGRESS (at level LOG_INFO)

(2) Test no exception thrown.

(3) Check message is written to file.

=cut

{
  my ($tmpfn, $tmpfh) = tmpnam;

  ok(evcheck(sub {
               Log::Info::enable_file_channel
                 (CHAN_PROGRESS, ':' . fileno($tmpfh), '*test B*', 'tmpfile');
             }), 1,                              'log to file descriptor (1)');

  ok(evcheck(sub {
               Log(CHAN_PROGRESS, LOG_INFO, MESSAGE2);
             }), 1,                              'log to file descriptor (2)');

  ok read_fh($tmpfh), MESSAGE2 . "\n",           'log to file descriptor (3)';
}

# -------------------------------------

=head2 Tests 8--10: log to stderr

Invoke

  enable_file_channel(CHAN_PROGRESS, '', '*test C*', 'tmpfile');

(1) Test no exception thrown.

Log MESSAGE3 to CHAN_PROGRESS (at level LOG_INFO)

(2) Test no exception thrown.

(3) Check message is written to file.

=cut

{
  ok(evcheck(sub {
               Log::Info::enable_file_channel
                   (CHAN_PROGRESS, '', '*test C*', 'tmpfile');
             }), 1,                                       'log to stderr (1)');

  my $stderr;
  ok(evcheck(sub {
               save_output('stderr', *STDERR{IO});
               Log(CHAN_PROGRESS, LOG_INFO, MESSAGE3);
               $stderr = restore_output('stderr');
             }), 1,                                       'log to stderr (2)');

  ok $stderr, MESSAGE3 . "\n",                            'log to stderr (3)';
}

# -------------------------------------

=head2 Tests 11--13: log to stderr (increased level)

Invoke

  enable_file_channel(CHAN_PROGRESS, '+2', '*test D*', 'tmpfile');

(1) Test no exception thrown.

Log MESSAGE4 to CHAN_PROGRESS (at level LOG_INFO),
    MESSAGE3 at level LOG_INFO+1, and MESSAGE2 at level LOG_INFO+2

(2) Test no exception thrown.

(3) Check messages 4 & 3 are written.

=cut

{
  ok(evcheck(sub {
               Log::Info::enable_file_channel
                 (CHAN_PROGRESS, '+2', '*test D*', 'tmpfile');
             }), 1,                     'log to stderr (increased level) (1)');

  my $stderr;
  ok(evcheck(sub {
               save_output('stderr', *STDERR{IO});
               Log(CHAN_PROGRESS, LOG_INFO,   MESSAGE4);
               Log(CHAN_PROGRESS, LOG_INFO+1, MESSAGE3);
               Log(CHAN_PROGRESS, LOG_INFO+2, MESSAGE2);
               $stderr = restore_output('stderr');
             }), 1,                     'log to stderr (increased level) (2)');

  ok($stderr, MESSAGE4 . "\n" . MESSAGE3 . "\n",
                                        'log to stderr (increased level) (3)');
}
# -------------------------------------

=head2 Tests 14--16: log to file (with level)

Invoke

  enable_file_channel(CHAN_PROGRESS, "$tmpfn+1", '*test E*', 'tmpfile');

(1) Test no exception thrown.

Log MESSAGE1 to CHAN_PROGRESS (at level LOG_INFO),
    MESSAGE2 at level LOG_INFO+1

(2) Test no exception thrown.

(3) Check message1 is written to file.

=cut

{
  my $tmpfn = tmpnam;

  ok(evcheck(sub {
               Log::Info::enable_file_channel
                 (CHAN_PROGRESS, "$tmpfn+1", '*test E*', 'tmpfile');
             }), 1,                            'log to file (with level) (1)');

  ok(evcheck(sub {
               Log(CHAN_PROGRESS, LOG_INFO,   MESSAGE1);
               Log(CHAN_PROGRESS, LOG_INFO+1, MESSAGE2);
             }), 1,                            'log to file (with level) (2)');

  ok read_file($tmpfn), MESSAGE1 . "\n",       'log to file (with level) (3)';
  unlink $tmpfn
    unless $ENV{TEST_DEBUG};
}

# -------------------------------------

=head2 Tests 17--19: log to file descriptor (with level)

Invoke

  enable_file_channel(CHAN_PROGRESS, '+1:' . fileno($tmpfh), '*test F*', 'tmpfile');

(1) Test no exception thrown.

Log MESSAGE2 to CHAN_PROGRESS (at level LOG_INFO)
    MESSAGE4 at level LOG_INFO+1

(2) Test no exception thrown.

(3) Check message2 is written to file.

=cut

{
  my ($tmpfn, $tmpfh) = tmpnam;

  ok(evcheck(sub {
               Log::Info::enable_file_channel
                   (CHAN_PROGRESS, '+1:' . fileno($tmpfh), '*test F*', 'tmpfile');
             }), 1,                 'log to file descriptor (with level) (1)');

  ok(evcheck(sub {
               Log(CHAN_PROGRESS, LOG_INFO,   MESSAGE2);
               Log(CHAN_PROGRESS, LOG_INFO+1, MESSAGE4);
             }), 1,                 'log to file descriptor (with level) (2)');

  ok(read_fh($tmpfh), MESSAGE2 . "\n", 
                                    'log to file descriptor (with level) (3)');
}


# -------------------------------------

=head2 Tests 20--22: repeated options

Invoke

  enable_file_channel(CHAN_INFO, '', '*test G*', 'tmpfile');
  enable_file_channel(CHAN_INFO, '', '*test G*', 'tmpfile');

(1) Test no exception thrown.

Log MESSAGE4 to CHAN_INFO (at level LOG_INFO)
    MESSAGE1 at level LOG_INFO+1

(2) Test no exception thrown.

(3) Check message4 is written file.

=cut

{
  ok(evcheck(sub {
               Log::Info::enable_file_channel
                   (CHAN_INFO, '', '*test G*', SINK_STDERR);
               Log::Info::enable_file_channel
                   (CHAN_INFO, '', '*test G*', SINK_STDERR);
             }), 1,                                    'repeated options (1)');

  my $stderr;
  ok(evcheck(sub {
               save_output('stderr', *STDERR{IO});
               Log(CHAN_INFO, LOG_INFO,   MESSAGE2);
               Log(CHAN_INFO, LOG_INFO+2, MESSAGE4);
               $stderr = restore_output('stderr');
             }), 1,                                    'repeated options (2)');

  ok $stderr, MESSAGE2 . "\n",                         'repeated options (3)';
}

# ----------------------------------------------------------------------------
