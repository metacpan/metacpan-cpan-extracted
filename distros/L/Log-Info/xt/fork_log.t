# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Log::Info functions

This package tests the C<fork_log> subr.

=cut

use Carp                        qw( carp croak );
use Config                      qw( %Config );
use Fatal                  1.02 qw( close open seek );
use Fcntl                  1.03 qw( :seek );
use File::Spec::Functions       qw( catfile );
use File::Temp             0.12 qw( tempfile );
use FindBin                1.42 qw( $Bin );
use Test                   1.13 qw( ok plan skip );

BEGIN { unshift @INC, $Bin };

use test      qw( DATA_DIR
                  evcheck save_output restore_output );
use test2     qw( -no-ipc-run runcheck );

# Message texts for playing with
use constant MESSAGE1 => 'The Journey of Master Ho';
use constant MESSAGE2 => 'The Dogwatch';
use constant MESSAGE3 => 'The Seal of Neptune';
use constant MESSAGE4 => 'The Mermaids Pearls';
use constant MESSAGE5 => 'Little Laura';
# (they're all films by smallfilms, www.smallfilms.co.uk, if you care...)

# Sink names for playing with
use constant SINK1 => 'sink1';

# Channel names for playing with
use constant CHAN1 => 'chan1';
use constant CHAN2 => 'chan2';
use constant CHAN3 => 'chan3';
use constant CHAN4 => 'chan4';

use constant TESTFILE1 => 'testfile1';

BEGIN {
  plan tests  => 71;
       todo   => [],
       ;
}

# ----------------------------------------------------------------------------

use Log::Info qw( :default_channels :log_levels Log );
use Log::Info::Fork qw( SRC_INFO );

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

=cut

ok 1, 1, 'compilation';

# -------------------------------------

my @mess = ();

=head2 Test 2: adding a sink

This test deletes the C<SINK_STDERR> sink, and adds a sink (C<SINK1), to
C<CHAN_INFO>.  The test is that no exception is thrown.

=cut

ok evcheck(sub {
             Log::Info::delete_sink(CHAN_INFO, SINK_STDERR);
             Log::Info::add_sink (CHAN_INFO, SINK1, 'SUBR', undef,
                                  { subr => sub { push @mess, $_[0] }});
           }, 'adding a sink'), 1, 'adding a sink';

# -------------------------------------

=head2 Tests 3--5: invoke fork_log (simple perl stdout)

Invoke fork_log, where the fork simply prints MESSAGE1 to stdout.

(1) Test no exception thrown.
(2) Test exactly one message logged to C<CHAN_INFO>
(3) Test MESSAGE1 is message logged to C<CHAN_INFO>

MESSAGE1 is deliberately I<not> newline terminated, to check handling of
incomplete lines.

=cut

ok(evcheck(sub { Log::Info::Fork->fork_log(sub {
                                             print STDOUT MESSAGE1;
                                           }); },
           'invoke fork_log (simple perl stdout) (1)'),
   1, 'invoke fork_log (simple perl stdout) (1)');

ok scalar(@mess), 1,   'invoke fork_log (simple perl stdout) (2)';
ok $mess[0], MESSAGE1, 'invoke fork_log (simple perl stdout) (3)';
@mess=();

# -------------------------------------

=head2 Tests 6--8: invoke fork_log (simple perl stderr)

Invoke fork_log, where the fork simply prints MESSAGE2 to stdout.

(1) Test no exception thrown.
(2) Test exactly one message logged to C<CHAN_INFO>
(3) Test MESSAGE2 is message logged to C<CHAN_INFO>

MESSAGE2 is deliberately newline terminated, to check handling of complete
lines.

=cut

ok(evcheck(sub { Log::Info::Fork->fork_log(sub {
                                             print STDERR MESSAGE2, "\n";
                                           }); },
           'invoke fork_log (simple perl stderr) (1)'),
   1, 'invoke fork_log (simple perl stderr) (1)');

ok scalar(@mess), 1,   'invoke fork_log (simple perl stderr) (2)';
ok $mess[0], MESSAGE2, 'invoke fork_log (simple perl stderr) (3)';
@mess = ();

# -------------------------------------

=head2 Tests 9--11: invoke fork_log (simple perl out/err)

Invoke fork_log, where the fork prints MESSAGE1 (newline-terminated) to
stdout, and MESSAGE2 (not newline-terminated) to stderr.

(1) Test no exception thrown.
(2) Test exactly two messages logged to C<CHAN_INFO>
(3) Test MESSAGE1, MESSAGE2 are messages logged to C<CHAN_INFO> (in either
order).

=cut

ok(evcheck(sub { Log::Info::Fork->fork_log(sub {
                                             print STDOUT MESSAGE1 . "\n";
                                             print STDERR MESSAGE2;
                                           }); },
           'invoke fork_log (simple perl out/err) (1)'),
   1, 'invoke fork_log (simple perl out/err) (1)');

ok scalar(@mess), 2,   'invoke fork_log (simple perl out/err) (2)';

# Use if to be able to let ok do other comparisoh (since that produces better
# error messages)

if ( $mess[0] eq MESSAGE2 ) {
  ok $mess[1], MESSAGE1, 'invoke fork_log (simple perl out/err) (3)';
} else {
  ok $mess[0], MESSAGE1, 'invoke fork_log (simple perl out/err) (3)';
}
@mess = ();

# -------------------------------------

=head2 Tests 12--16: invoke fork_log (simple perl ordered)

Invoke fork_log, where the fork prints MESSAGES 3, 4, and 5 to stdout, each
newline-terminated, with no delay between 3 & 4, and 2 seconds between 4 & 5.

(1) Test no exception thrown.
(2) Test exactly three messages logged to C<CHAN_INFO>
(3) Test MESSAGE3 is the first message logged
(4) Test MESSAGE4 is the second message logged
(5) Test MESSAGE5 is the third message logged

=cut

ok(evcheck(sub { Log::Info::Fork->fork_log(sub {
                                             print STDOUT MESSAGE3, "\n";
                                             print STDOUT MESSAGE4, "\n";
                                             print STDOUT MESSAGE5, "\n";
                                           }); },
           'invoke fork_log (simple perl ordered) (1)'),
   1, 'invoke fork_log (simple perl ordered) (1)');

ok scalar(@mess), 3,   'invoke fork_log (simple perl ordered) (2)';
ok $mess[0], MESSAGE3, 'invoke fork_log (simple perl ordered) (3)';
ok $mess[1], MESSAGE4, 'invoke fork_log (simple perl ordered) (4)';
ok $mess[2], MESSAGE5, 'invoke fork_log (simple perl ordered) (5)';
@mess = ();

# -------------------------------------

=head2 Tests 17--21: invoke fork_log (start/end logged)

Invoke fork_log, where the fork prints MESSAGE 3 to stderr (without a
newline).  fork_log is requested to print start/end messages.

(1) Test no exception thrown.
(2) Test exactly three messages logged to C<CHAN_INFO>
(3) Test the start message is the first message logged
(4) Test MESSAGE3 is the second message logged
(5) Test the end message is the third message logged

=cut

my $name = 'Puff the magic Dragon';
ok(evcheck(sub { Log::Info::Fork->fork_log(sub {
                                             print STDERR MESSAGE3;
                                           }, undef, 1, $name); },
           'invoke fork_log (start/end logged) (1)'),
   1, 'invoke fork_log (start/end logged) (1)');

ok scalar(@mess), 3,   'invoke fork_log (start/end logged) (2)';
ok($mess[0], "Starting process: $name",
   'invoke fork_log (start/end logged) (3)');
ok $mess[1], MESSAGE3, 'invoke fork_log (start/end logged) (4)';
ok($mess[2],
   "Finishing process: $name", 'invoke fork_log (start/end logged) (5)');
@mess = ();

# -------------------------------------

=head2 Tests 22--25: fork_log, capturing a specified filehandle

Invoke fork log, specifying a code snippet that prints MESSAGE4 (no newline)
to a temporary file handle.

(1) Test no exception thrown.
(2) Test that exactly one message has been captured.
(3) Test that the captured message is MESSAGE4.
(4) Test that nothing was written to the temp file.

=cut

{
  my $tempfh = tempfile;

  ok(evcheck(sub { Log::Info::Fork->fork_log(sub {
                                               print $tempfh MESSAGE4;
                                             }, [{ fh => $tempfh, }]); },
             'fork_log, capturing a specified filehandle (1)'),
     1, 'fork_log, capturing a specified filehandle (1)');

  ok scalar(@mess), 1, 'fork_log, capturing a specified filehandle (2)';
  ok $mess[0], MESSAGE4, 'fork_log, capturing a specified filehandle (3)';
  seek($tempfh, 0, SEEK_SET);
  local $/ = undef;
  my $tempstr = <$tempfh>;
  ok $tempstr, '', 'fork_log, capturing a specified filehandle (4)';
}
@mess = ();

# -------------------------------------

=head2 Tests 26--28: fork_log, capturing a specified filedescriptor

Invoke fork log, specifying a code snippet that prints MESSAGE5 (with newline)
to a numbered file descriptor (to a temporary file).  The file descriptor is
explicitly closed by the code snippet.

(1) Test no exception thrown.
(2) Test that exactly one message has been captured.
(3) Test that the captured message is MESSAGE5.
(4) Test that nothing was written to the temp file.

=cut

{
  my $skip = ($Config{version} ge '5.8.0'              ?
              "File descriptor use is bugged in 5.8.0+" : undef);
  my $tempfh = tempfile;
  my $fileno = fileno $tempfh;
  skip($skip, evcheck(sub { Log::Info::Fork->fork_log
                              (sub {
                                 open my $tmpfh, ">&=$fileno";
                                 print $tmpfh MESSAGE5;
                                 close $tmpfh;
                               }, [{ fh => $fileno, }]); },
                     'fork_log, capturing a specified filedescriptor (1)'),
       1,                'fork_log, capturing a specified filedescriptor (1)');

  skip($skip, scalar(@mess), 1, 
                         'fork_log, capturing a specified filedescriptor (2)');
  skip($skip, $mess[0], MESSAGE5,
                         'fork_log, capturing a specified filedescriptor (3)');
  seek($tempfh, 0, SEEK_SET);
  local $/ = undef;
  my $tempstr = <$tempfh>;
  skip $skip, $tempstr, '', 'fork_log, capturing a specified filehandle (4)';
}
@mess = ();

# -------------------------------------

=head2 Tests 30--37: complex use of specified descriptors

Set up CHAN1, CHAN2 to log to arrays.

Invoke fork log, specifying a code snippet that prints MESSAGES1,2 (with
newline) to a temporary filehandle, printing MESSAGE3 (no newline) to a
numbered secondary temprorary filehandle, passed by file descriptor, in
between the two.  The file descriptor is not explicitly closed by the code
snippet.

The temporary filename is requested to be directed to CHAN1, the file
descriptor to CHAN2.

(1) Test no exception thrown by channel setup.
(2) Test no exception thrown by C<fork_log>.
(3) Test that exactly two messages have been captured to CHAN1.
(4) Test that the first captured message to CHAN1 is MESSAGE1.
(5) Test that the second captured message to CHAN1 is MESSAGE2.
(6) Test that exactly one message has been captured to CHAN2.
(7) Test that the captured message to CHAN2 is MESSAGE3.
(8) Test that nothing was written to the temp file.

=cut

{
  my $skip = ($Config{version} ge '5.8.0'              ?
              "File descriptor use is bugged in 5.8.0+" : undef);

  my (@mess1, @mess2);

  skip($skip, evcheck(sub {
               Log::Info::add_channel(CHAN1, undef);
               Log::Info::add_sink   (CHAN1, SINK1, 'SUBR', undef,
                                      { subr => sub { push @mess1, $_[0] }});
               Log::Info::add_channel(CHAN2, undef);
               Log::Info::add_sink   (CHAN2, SINK1, 'SUBR', undef,
                                      { subr => sub { push @mess2, $_[0] }});
             }, 'complex use of specified descriptors (1)'),
     1, 'complex use of specified descriptors (1)');

  my $tempfh1 = tempfile;
  my $tempfh2 = tempfile;
  my $fileno2 = fileno $tempfh2;

  skip($skip, evcheck(sub {
               Log::Info::Fork->fork_log (sub {
                                            print $tempfh1 MESSAGE1, "\n";
                                            open my $tmpfh, ">&=$fileno2";
                                            print $tmpfh MESSAGE3;
                                            print $tempfh1 MESSAGE2, "\n";
                                          }, [{ fh      => $fileno2,
                                                name    =>'desc',
                                                channel => CHAN2, },
                                              { fh      => $tempfh1,
                                                name    => 'fh',
                                                channel => CHAN1, },
                                             ]); },
             'complex use of specified descriptors (2)'),
     1, 'complex use of specified descriptors (2)');

  skip $skip, scalar(@mess1), 2, 'complex use of specified descriptors (3)';
  skip $skip, $mess1[0], MESSAGE1, 'complex use of specified descriptors (4)';
  skip $skip, $mess1[1], MESSAGE2, 'complex use of specified descriptors (5)';
  skip $skip, scalar(@mess2), 1, 'complex use of specified descriptors (6)';
  skip $skip, $mess2[0], MESSAGE3, 'complex use of specified descriptors (7)';
  seek($tempfh1, 0, SEEK_SET);
  local $/ = undef;
  my $tempstr = <$tempfh1>;
  skip $skip, $tempstr, '', 'complex use of specified descriptors (8)';
}

# -------------------------------------

=head2 Tests 38--43: Formatting Code

Invoke fork_log, with a code snippet that prints MESSAGE2 to stdout, and then
MESSAGE1 to stderr, with a formatter that precedes the message with [source],
and reverses the message.

(1) Test no exception thrown.
(2) Test exactly four messages are logged to C<CHAN_INFO>
(3) Test first  message is [SRC_INFO] reverse "Starting process: test1"
(4) Test second/third message is [stdout]   reverse MESSAGE2
(5) Test third/second  message is [stderr]   reverse MESSAGE1
(6) Test fourth message is [SRC_INFO] reverse "Finishing process: test1"

Note that the order is I<not> defined for the messages printed (since they are
printed to different filehandles).

=cut

ok(evcheck(sub { Log::Info::Fork->fork_log(sub {
                                             print STDOUT MESSAGE2;
                                             print STDERR MESSAGE1;
                                           }, undef, 1, 'test1',
                                           sub {
                                             sprintf("[%s] %s",
                                                     $_[2],
                                                     scalar reverse $_[3])
                                           }); },
           'Formatting Code (1)'),
   1, 'Formatting Code (1)');

ok scalar(@mess), 4,   'Formatting Code (2)';
ok($mess[0], sprintf("[%s] %s",
                     SRC_INFO, scalar reverse 'Starting process: test1'),
   'Formatting Code (3)');
ok((sort(@mess[1,2]))[0],
   sprintf("[%s] %s", 'stderr', scalar reverse MESSAGE1),
   'Formatting Code (4)');
ok((sort(@mess[1,2]))[1],
   sprintf("[%s] %s", 'stdout', scalar reverse MESSAGE2),
   'Formatting Code (5)');
ok($mess[3], sprintf("[%s] %s",
                     SRC_INFO, scalar reverse 'Finishing process: test1'),
   'Formatting Code (6)');
@mess=();

# -------------------------------------

=head2 Tests 44--47: Arrayref exec test

Invoke fork_log, passing in an arrayref that is [ cat data/testfile1 ].

(1) Test that no exception is thrown.
(2) Check that there is one message for each line in the file
(3) Check that each message corresponds to a line in the file
(4) Check that no extraneous lines were found in the messages

=cut

my $testfn = catfile DATA_DIR, TESTFILE1;
ok(evcheck(sub {
             Log::Info::Fork->fork_log([cat => $testfn]);
           },
           'Arrayref exec test (1)'),
   1, 'Arrayref exec test (1)');

{
  open my $testfh, '<', $testfn;
  local $/ = "\n";
  chomp(my @lines = <$testfh>);
  close $testfh;

  ok scalar(@mess), scalar(@lines), 'Arrayref exec test (2)';
  my %lines = map { $_ => 1 } @lines;
  my $noextras = 1;
  for (@mess) {
    if ( exists $lines{$_} ) {
      delete $lines{$_};
    } else {
      warn "Found non-line in \@mess: $_\n";
      $noextras = 0;
    }
  }

  ok scalar keys %lines, 0, 'Arrayref exec test (3)';
  ok $noextras, 1, 'Arrayref exec test (4)';
}

# -------------------------------------

=head2 Tests 48--51: Log to Alternative Channels/Levels

Initialize CHAN3 to log to arrayref.  Set channel level on 3 to be
LOG_WARNING.

Invoke fork_log, where the fork simply prints MESSAGE3 to stdout
(with newline), and MESSAGE1 to stderr (without newline).  Request stdout to
go to CHAN3 (level LOG_INFO), and stderr to go to CHAN3 (level LOG_WARNING).

(1) Test no exception thrown by channel setup.
(2) Test no exception thrown by C<fork_log>.
(3) Test exactly one message logged to CHAN3
(4) Test MESSAGE1 is message logged to CHAN3

=cut

{
  my (@mess1);

  ok(evcheck(sub {
               Log::Info::add_channel(CHAN3, LOG_WARNING);
               Log::Info::add_sink   (CHAN3, SINK1, 'SUBR', undef,
                                      { subr => sub { push @mess1, $_[0] }});
             }, 'Log to Alternative Channels/Levels (1)'),
     1, 'Log to Alternative Channels/Levels (1)');

  ok(evcheck(sub { Log::Info::Fork->fork_log(sub {
                                               print STDOUT MESSAGE3, "\n";
                                               print STDERR MESSAGE1;
                                             }, [ { fh      => *STDOUT{IO},
                                                    channel => CHAN3,
                                                    level   => LOG_INFO},
                                                  { fh      => *STDERR{IO},
                                                    channel => CHAN3,
                                                    level   => LOG_WARNING, },
                                                ]); },
             'Log to Alternative Channels/Levels (2)'),
     1, 'Log to Alternative Channels/Levels (2)');

  ok scalar(@mess1), 1, 'Log to Alternative Channels/Levels (3)';
  ok $mess1[0], MESSAGE1, 'Log to Alternative Channels/Levels (4)';
}
@mess = ();

# -------------------------------------

=head2 Tests 52--56: Log Process Arguments (arrayref)

Invoke fork_log, using the arrayref proc to cat F<data/testfile1>, with
argument logging turned on.

(1) Test no exception thrown by C<fork_log>.
(2) Check for the presence of an appropriate C<Process Args> message (as the
    first message).
(3) Check that there is one message for each line in the file
(4) Check that each message corresponds to a line in the file
(5) Check that no extraneous lines were found in the messages

=cut

my $testname = 'test2';
my @testargs = ('cat', catfile(DATA_DIR, TESTFILE1));
ok(evcheck(sub {
             Log::Info::Fork->fork_log(\@testargs, undef, 2, $testname);
           }, 'Log Process Arguments (arrayref) (1)'),
     1, 'Log Process Arguments (arrayref) (1)');

my $testargs = join ' ', @testargs;
ok($mess[0], qr/^Process Args: $testname: $testargs$/,
   'Log Process Arguments (arrayref) (2)');
shift @mess;

{
  open my $testfh, '<', $testfn;
  local $/ = "\n";
  chomp(my @lines = <$testfh>);
  close $testfh;

  ok scalar(@mess), scalar(@lines), 'Log Process Arguments (arrayref)  (3)';
  my %lines = map { $_ => 1 } @lines;
  my $noextras = 1;
  for (@mess) {
    if ( exists $lines{$_} ) {
      delete $lines{$_};
    } else {
      warn "Found non-line in \@mess: $_\n";
      $noextras = 0;
    }
  }

  ok scalar keys %lines, 0, 'Log Process Arguments (arrayref)  (4)';
  ok $noextras, 1, 'Log Process Arguments (arrayref)  (5)';
}

@mess = ();

# -------------------------------------

=head2 Tests 57--60: Log Process Arguments (coderef)

Invoke fork_log, using the coderef proc to print MESSAGE1 (no newline), with
argument logging turned on.

(1) Test no exception thrown by C<fork_log>.
(2) Check that there are exactly two messages.
(3) Check for the presence of an appropriate C<Process Args> message (as the
    first message).
(4) Check that the second message is MESSAGE1.

=cut

{
  my $testname = 'test3';

  # Can't use MESSAGE1 directly as it gets inlined...  Well, we could, but
  # that would mean relying on the inlining, which wouldn't be so robust

  my $testline = MESSAGE1;
  ok(evcheck(sub {
               Log::Info::Fork->fork_log(sub { print $testline },
                                         undef, 2, $testname);
             }, 'Log Process Arguments (coderef) (1)'),
     1, 'Log Process Arguments (coderef) (1)');

  ok scalar(@mess), 2, 'Log Process Arguments (coderef) (2)';
  ok($mess[0], qr/^Process Args: $testname: \s*{\s*(use\s*strict\s*'refs'\s*;\s*)?print\s+\$testline[\s;]*}$/,
     'Log Process Arguments (coderef) (3)');
  ok $mess[1], MESSAGE1, 'Log Process Arguments (coderef) (4)';
  @mess = ();
}

# -------------------------------------

=head2 Tests 61--64: Log Process Results One

Invoke fork_log, forking the code

  print MESSAGE5;
  exit 10;

with results printing turned on.

(1) Test no exception thrown by C<fork_log>.
(2) Test that there are exactly two messages
(3) Check that the first message is MESSAGE5
(4) Check that the second message is an appropriate exit message

=cut

{
  my $testname = 'test4';
  ok(evcheck(sub {
               Log::Info::Fork->fork_log(sub { print MESSAGE5; exit 10 },
                                         undef, 4, $testname);
             }, 'Log Process Results One (1)'),
     1, 'Log Process Results One (1)');

  ok scalar(@mess), 2, 'Log Process Results One (2)';
  ok $mess[0], MESSAGE5, 'Log Process Results One (3)';
  ok($mess[1], "Process exited: $testname: Exit/Core/Sig: 10/0/0",
     'Log Process Results One (4)');
}
@mess = ();

# -------------------------------------

=head2 Tests 65--68: Log Process Results Two

Invoke fork_log, forking the arrayref [ 'echo', MESSAGE3 ], with results
printing turned on.

(1) Test no exception thrown by C<fork_log>.
(2) Test that there are exactly two messages
(3) Check that the first message is MESSAGE3
(4) Check that the second message is an appropriate exit message

=cut

{
  my $testname = 'test5';
  ok(evcheck(sub {
               Log::Info::Fork->fork_log([ echo => MESSAGE3, ],
                                         undef, 4, $testname);
             }, 'Log Process Results Two (1)'),
     1, 'Log Process Results Two (1)');

  ok scalar(@mess), 2, 'Log Process Results Two (2)';
  ok $mess[0], MESSAGE3, 'Log Process Results Two (3)';
  ok($mess[1], "Process exited: $testname: Exit/Core/Sig: 0/0/0",
     'Log Process Results Two (4)');
}
@mess = ();


# -------------------------------------

=head2 Tests 61--64: Return Process Results One

Invoke fork_log, forking the code

  exit 10;

(1) Test no exception thrown by C<fork_log>.
(2) Test that there are no messages
(3) Check that the return code is 10 << 8.

=cut

{
  my $testname = 'test6';
  my $rv;
  ok(evcheck(sub {
               $rv = Log::Info::Fork->fork_log(sub { exit 10 },
                                               undef, 0, $testname);
             }, 'Return Process Results One (1)'),
     1, 'Return Process Results One (1)');

  ok scalar(@mess), 0, 'Return Process Results One (2)';
  ok $rv, 10 << 8, 'Return Process Results One (3)';
}
@mess = ();

# -------------------------------------
