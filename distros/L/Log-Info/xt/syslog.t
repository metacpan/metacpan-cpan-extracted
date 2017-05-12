# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Log::Info functions

This package tests the syslog-writing functionality of Log::Info

=cut

use Fatal                 qw( close open seek );
use Fcntl                 qw( :seek );
use FindBin               qw( $Script );
use Test                  qw( ok plan skip );

# Channel names for playing with
use constant TESTCHAN1 => 'testchan1';
use constant TESTCHAN2 => 'testchan2';

# Sink names for playing with
use constant SINK1 => 'sink1';
use constant SINK2 => 'sink2';

# Each message to be distinct for searching
use constant MESSAGE1 => 'Tomsk';
use constant MESSAGE2 => 'Orinoco';
use constant MESSAGE3 => 'Bulgaria';

use constant SYSLOG  => '/var/log/syslog';
use constant MAILLOG => '/var/log/mail.log';

BEGIN {
  plan tests  => 9;
       todo   => [],
       ;
}

use lib $Script, '..', 'lib';

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

The C<:DEFAULT>, C<:log_levels>, and C<:syslog_facilities> tags are passed to
the C<use> call for C<Log::Info>.

=cut

use Log::Info qw( :DEFAULT :log_levels :syslog_facilities );
ok 1, 1, 'compilation';

# -------------------------------------

=head2 Test 2: set up syslog channel

Create a channel TESTCHAN1 (at default level) with sink SINK1 connected to
syslog at level C<LOG_WARNING>.

Test no exception thrown.

=cut

{
  my $ok = 0;
  eval {
    Log::Info::add_channel (TESTCHAN1);
    Log::Info::add_sink    (TESTCHAN1, SINK1, 'SYSLOG', LOG_WARNING);
    $ok = 1;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  ok $ok, 1, 'set up syslog channel';
}

# -------------------------------------

=head2 Test 3: log test message

Log MESSAGE1 at level LOG_ERR, MESSAGE2 at level LOG_NOTICE.

Test that no exception is thrown.

=cut

{
  my $ok = 0;
  my $read;

  eval {
    Logf(TESTCHAN1, LOG_ERR,    "[%d] %s", $$, MESSAGE1);
    Logf(TESTCHAN1, LOG_NOTICE, "[%d] %s", $$, MESSAGE2);
    $ok = 1;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  ok $ok, 1, 'log test message';
}

# -------------------------------------

=head2 Test 4: test for presence of log message in syslog

Grep syslog for messages; test MESSAGE1 is present, MESSAGE2 is not.

=cut

{
  my ($ok, $skip) = (0) x 2;

  $skip = "set TEST_SYSLOG to run (on a system with a suitable syslog config)"
    unless $ENV{TEST_SYSLOG};

  unless ( $skip ) {
    eval {
      open *SYSLOG, SYSLOG
    }; if ( $@ ) {
      warn "Failed to open ${\ SYSLOG() }: $@\n"
        if $ENV{TEST_DEBUG};
      $skip = "cannot open ${\ SYSLOG() }";
    }
  }

  unless ( $skip ) {
    while (<SYSLOG>) {
      chomp;
      my ($date, $hostname, $prog, $pid, $message);
      if ( ($date, $hostname, $prog, $pid, $message) =
           # Trim whitespace at end of line; Sys::Syslog adds a space after
           # each logged line.
               /^(\w{3}\ [\d ]\d\ \d{2}:\d{2}:\d{2})
                 \ (\S+)\ (.+?)(?:\[(\d+)\])?:\ (.*?)\s*$/x ) {
        if ( $prog eq $Script and defined $pid and $pid == $$ ) {
          if ( $message eq MESSAGE2 ) {
            $ok = -1;
          } elsif ( $message eq MESSAGE1 ) {
            $ok = 1
              if $ok == 0;
          } else {
            warn "Weird message seen at line $.:\n  $_\n"
              if $ENV{TEST_DEBUG};
          }
        } else {
          warn "Ignoring syslog message at line $. ($Script/$pid) ($prog/$$) :\n  $_\n"
            if $ENV{TEST_DEBUG} > 1;
        }
      } elsif ( $ENV{TEST_DEBUG} ) {
        warn "Couldn't match syslog line $.:\n  $_\n"
          unless /last message repeated \d+ times$/;
      }
    }
  }

  skip $skip, $ok, 1, 'test for presence of log message in syslog';
}

# -------------------------------------

=head2 Test 5: set up syslog channel with duff facility

Create a channel TESTCHAN2 at level C<LOG_ERR> with sink SINK1 connected to
syslog at level C<LOG_NOTICE>, with facility C<mail>.

Test exception thrown at add_sink point.

=cut

{
  my $ok = 0;
  eval {
    Log::Info::add_channel (TESTCHAN2, LOG_ERR);
    $ok = 1;
    Log::Info::add_sink    (TESTCHAN2, SINK1, 'SYSLOG', LOG_NOTICE,
                            { facility => 'LOG_MAIL' });
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG} and ! $ok;
    $ok++;
  }

  ok $ok, 2, 'set up syslog channel with duff facility';
}

# -------------------------------------

=head2 Test 6: set up syslog channel with FTY_MAIL facility

Add sink SINK1 to TESTCHAN2 connected to syslog at level C<LOG_NOTICE>, with
facility C<FTY_MAIL>.

Test no exception thrown.

=cut

{
  my $ok = 0;
  eval {
    Log::Info::add_sink    (TESTCHAN2, SINK1, 'SYSLOG', LOG_NOTICE,
                            { facility => FTY_MAIL });
    $ok = 1;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG} and ! $ok;
    $ok = 0;
  }

  ok $ok, 1, 'set up syslog channel with FTY_MAIL facility';
}

# -------------------------------------

=head2 Test 7: log test message (2)

Log MESSAGE2 at level LOG_WARNING, MESSAGE3 at level LOG_CRIT.

Test that no exception is thrown.

=cut

{
  my $ok = 0;
  my $read;

  eval {
    Logf(TESTCHAN2, LOG_WARNING, "[%d] %s", $$, MESSAGE2);
    Logf(TESTCHAN2, LOG_CRIT,    "[%d] %s", $$, MESSAGE3);
    $ok = 1;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  ok $ok, 1, 'log test message (2)';
}

# -------------------------------------

=head2 Test 8: test for presence of log message in syslog (2)

Grep syslog for messages; test MESSAGE3 is present, MESSAGE2 is not.

=cut

{
  my ($ok, $skip) = (0) x 2;

  eval {
    open *SYSLOG, SYSLOG
  }; if ( $@ ) {
    warn "Failed to open ${\ SYSLOG() }: $@\n"
      if $ENV{TEST_DEBUG};
    $skip = "cannot open ${\ SYSLOG() }";
  }

  unless ( $skip ) {
    while (<SYSLOG>) {
      chomp;
      my ($date, $hostname, $prog, $pid, $message);
      if ( ($date, $hostname, $prog, $pid, $message) =
           # Trim whitespace at end of line; Sys::Syslog adds a space after
           # each logged line.
               /^(\w{3}\ [\d ]\d\ \d{2}:\d{2}:\d{2})
                 \ (\S+)\ (.+?):\ (?:\[(\d+)\])\ (.*?)\s*$/x ) {
        if ( $prog eq $0 and defined $pid and $pid == $$ ) {
          if ( $message eq MESSAGE1 ) {
            # Ignore; consequence of previous test
          } elsif ( $message eq MESSAGE2 ) {
            $ok = -1;
          } elsif ( $message eq MESSAGE3 ) {
            $ok = 1
              if $ok == 0;
          } else {
            warn "Weird message seen at line $.:\n  $_\n"
              if $ENV{TEST_DEBUG};
          }
        }
      } elsif ( $ENV{TEST_DEBUG} > 1 ) {
        warn "Couldn't match syslog line $.:\n  $_\n"
          unless /last message repeated \d+ times$/;
      }
    }
  }

  skip $skip, $ok, 1, 'test for presence of log message in syslog (2)';
}

# -------------------------------------

=head2 Test 9: test for presence of log message in maillog

Grep syslog for messages; test MESSAGE3 is present, MESSAGE2 is not.

=cut

{
# sleep 5;
  my ($ok, $skip) = (0) x 2;

  eval {
    # Sleep here; occasionally, syslog takes a moment to catch up...
    sleep 2;
    open *MAILLOG, MAILLOG;
  }; if ( $@ ) {
    warn "Failed to open ${\ MAILLOG() }: $@\n"
      if $ENV{TEST_DEBUG};
    $skip = "cannot open ${\ MAILLOG() }\n";
  }

  unless ( $skip ) {
    while (<MAILLOG>) {
      chomp;
      my ($date, $hostname, $prog, $pid, $message);
      if ( ($date, $hostname, $prog, $pid, $message) =
           # Trim whitespace at end of line; Sys::Syslog adds a space after
           # each logged line.
               /^(\w{3}\ [\d ]\d\ \d{2}:\d{2}:\d{2})
                 \ (\S+)\ (.+?):\ (?:\[(\d+)\])\ (.*?)\s*$/x ) {
        if ( $prog eq $0 and defined $pid and $pid == $$ ) {
          if ( $message eq MESSAGE2 ) {
            $ok = -1;
          } elsif ( $message eq MESSAGE3 ) {
            $ok = 1
              if $ok == 0;
          } else {
            warn "Weird message seen at line $.:\n  $_\n"
              if $ENV{TEST_DEBUG};
          }
        }
      } elsif ( $ENV{TEST_DEBUG} > 1 ) {
        warn "Couldn't match mailllog line $.:\n  $_\n"
          unless /last message repeated \d+ times$/;
      }
    }
  }

  skip $skip, $ok, 1, 'test for presence of log message in maillog';
}

