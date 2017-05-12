# (X)Emacs mode: -*- cperl -*-

use strict;

=head1 Unit Test Package for Log::Info functions

This package tests the file-writing functionality of Log::Info

=cut

use autodie               qw( close open );
use Data::Dumper          qw( Dumper );
use Fatal                 qw( close open read seek );
use Fcntl                 qw( SEEK_END );
use FindBin               qw( $Bin );
use File::Glob            qw( );
use IO::Select            qw( );
use List::Util            qw( max );
use POSIX                 qw( tmpnam );
use Test::More            tests => 29;

use lib  "$Bin/../lib";

# Channel names for playing with
use constant TESTCHAN1 => 'testchan1';
use constant TESTCHAN2 => 'testchan2';

# Sink names for playing with
use constant SINK1 => 'sink1';
use constant SINK2 => 'sink2';

# Message texts for playing with
# Tests rely on no "\n" in these
# Each message to be distinct for searching
use constant MESSAGE1   => 'Message1';
use constant MESSAGE2   => 'Message2';
use constant MAXMESSLEN => ((length(MESSAGE1) > length(MESSAGE2)) ?
                            length(MESSAGE1) : length(MESSAGE2));

# File sizes for playing with
use constant MAXSIZE1 => 100;
use constant MAXSIZE2 => 80;

use constant MAXMAXSIZE => ((MAXSIZE1 > MAXSIZE2) ? MAXSIZE1 : MAXSIZE2);

# Translators
# TRANS1 adds 2 chars onto each message
# TRANS2 doubles the length of each message
# Each translator leaves the original message in place for searchability
#   (just add to 'em)
use constant TRANS1 => sub { "++$_[0]" };
use constant TRANS2 => sub { scalar(reverse($_[0])) . $_[0] };

use constant TMPNAM1 => tmpnam;
use constant TMPNAM2 => tmpnam;
use constant TMPNAM3 => tmpnam;

END {
  unlink map glob("$_*"), TMPNAM1, TMPNAM2, TMPNAM3
    unless $ENV{TEST_SAVE_FILES};
}

$Data::Dumper::Maxdepth = 3;
$Data::Dumper::Terse    = 1;
$Data::Dumper::Indent   = 0;

use Log::Info qw( :DEFAULT :log_levels );

$/ = "\n";

# -------------------------------------

sub slurp {
  my ($fn) = @_;

  my @lines;
  open my $fh, '<', $fn;
  while ( my $_ = <$fh> ) {
    chomp $_;
    push @lines, $_;
  }
  close $fh;
  return \@lines;
}

# -------------------------------------

=head2 Test 1: compilation

This test confirms that the test script and the modules it calls compiled
successfully.

The C<:DEFAULT> and C<:log_levels> tags are passed to the C<use> call for
C<Log::Info>.

=cut

is 1, 1, 'compilation';

=head2 Test 2: set up pipe to fh

create a pipe from C<$out> to C<$in>.  Unbuffer $out.

Create a channel TESTCHAN1 with sink SINK1 connected to $out at channel level
3, sink level undef.

Test no exception thrown.

=cut

my ($in, $out);

{
  my $ok = 0;
  eval {
    pipe $in, $out
      or die "Pipe failed: $!\n";
    select((select($out), $| = 1)[0]);
    Log::Info::add_channel (TESTCHAN1, 3);
    Log::Info::add_sink    (TESTCHAN1, SINK1, 'FH', undef, { fh => $out });
    diag 'fileno $in: '  . fileno($in)
      if $ENV{TEST_DEBUG};
    diag 'fileno $out: ' . fileno($out)
      if $ENV{TEST_DEBUG};
    $ok = 1;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  is $ok, 1, 'set up pipe to fh';
}

=head2 Test 3: log to fh

Log MESSAGE1 at level 4, MESSAGE2 at level 3.

Test that MESSAGE2 only is written, and a newline is appended (and no
exception is thrown).

=cut

{
  my $ok = 0;
  my $read;

  eval {
    Log(TESTCHAN1, 4, MESSAGE1); # should not log to fh
    Log(TESTCHAN1, 3, MESSAGE2); # should log to fh

    local $SIG{ALRM} = sub { die "Timed out reading from pipe\n" }; alarm 2;
    $read = <$in>;
    alarm 0;
#    sysread $in, $read, 7;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  is $read, (MESSAGE2 . "\n"), 'log to fh';
}

=head2 Test 4: set up sink to file

Create a channel TESTCHAN2 with sink SINK2 connected to a temporary file.
Neither the sink nor the channel have any limits

Test no exception thrown.

=cut

{
  my $ok = 0;
  eval {
    Log::Info::add_channel (TESTCHAN2);
    Log::Info::add_sink    (TESTCHAN2, SINK2, 'FILE', undef,
                            { fn => TMPNAM1 });
    diag 'TMPNAM1: ', TMPNAM1
      if $ENV{TEST_DEBUG};
    # so now we have
    #   TESTCHAN1 => SINK1 (3;FH),
    #   TESTCHAN2 => SINK2 (;FILE:TMPNAM1)
    $ok = 1;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  is $ok, 1, 'set up sink to file';
}

=head2 Test 5: log to file

Write a log to temporary file.

Test log written.

=cut

{
  my $read;

  eval {
    Log(TESTCHAN2, 4, MESSAGE1); # should log to file

    open *TMPFH, TMPNAM1;
    local $/ = undef;
    $read = <TMPFH>;
    close *TMPFH;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
  }

  is $read, (MESSAGE1 . "\n"), 'log to file';
}

=head2 Test 6: add filelog to TESTCHAN1

Add FILE F<tmpnam> log to TESTCHAN1 as SINK2 at level 2.
Log MESSAGE1 at level 1, MESSAGE2 at level 3 to TESTCHAN1.

Test no exception thrown.

=cut

{
  my $ok = 0;
  eval {
    Log::Info::add_sink (TESTCHAN1, SINK2, 'FILE', 2,
                         { fn => TMPNAM3 });
    # so now we have
    #   TESTCHAN1//SINK1 (3;FH),
    #   TESTCHAN1//SINK2 (2;FILE:TMPNAM3), 
    #   TESTCHAN2//SINK2 (;FILE:TMPNAM1)
    Log(TESTCHAN1, 1, MESSAGE1); # should go to fh & file
    Log(TESTCHAN1, 3, MESSAGE2); # should go to fh only
    $ok = 1;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  is $ok, 1, 'add filelog to TESTCHAN1';
}

=head2 Test 7: dual log to fh (1)

Test MESSAGE1 logged to SINK1.

=cut

{
  my $ok = 0;
  my $read;

  eval {
    local $SIG{ALRM} = sub { die "Timed out reading from pipe\n" }; alarm 2;
    $read = <$in>;
    alarm 0;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  is $read, (MESSAGE1 . "\n"), 'dual log to fh (1)';
}

=head2 Test 8: dual log to fh (2)

Test MESSAGE2 logged to SINK1.

=cut

{
  my $ok = 0;
  my $read;

  eval {
    local $SIG{ALRM} = sub { die "Timed out reading from pipe\n" }; alarm 2;
    $read = <$in>;
    alarm 0;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  is $read, (MESSAGE2 . "\n"), 'dual log to fh (2)';
}

=head2 Test 9: log to two files

=cut

{
  my $ok = 0;
  my $read;

  is_deeply slurp(TMPNAM1), [ MESSAGE1 ], 'log to two files (1)';
  is_deeply slurp(TMPNAM3), [ MESSAGE1 ], 'log to two files (2)';
}

=head2 Test 11: delete fh sink from channel

delete SINK1 from TESTCHAN1

log MESSAGE2 to TESTCHAN1 at level 0

test no exception thrown

=cut

{
  my $ok = 0;

  eval {
    Log::Info::delete_sink(TESTCHAN1, SINK1);
    Log(TESTCHAN1, 0, MESSAGE2);
    $ok = 1;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  is $ok, 1, 'delete fh sink from channel';
}

=head2 Test 12: message not logged to deleted channel

Test nothing to read on $in

=cut

{
  my @ready;
  eval {
    my $s = IO::Select->new;
    $s->add($in);
    @ready = $s->can_read(0);
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
  }

  is $#ready, -1, 'message not logged to deleted channel';
}

=head2 Test 14: delete file sink from channel

test no exception thrown

=cut

{
  my $ok = 0;

  eval {
    Log::Info::delete_sink(TESTCHAN1, SINK2);
    $ok = 1;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  is $ok, 1, 'delete file sink from channel';
}

=head2 Test 15: add size-limited file sinks to channel, log series of messages

Truncate TMPNAM{1,2}.

Add sink for each TMPNAM to TESTCHAN, with MAXSIZE.

Log enough messages so that each file should be rotated.

Use translators to test sizes account for translation, too.

=cut

my $messagecount = 2* 1+int(MAXMAXSIZE / (length(MESSAGE1)+3));
my @expect;

{
  my $ok = 0;
  eval {
    truncate $_, 0
      for TMPNAM1, TMPNAM2;

    Log::Info::add_sink    (TESTCHAN1, SINK1, 'FILE', undef,
                            { fn      => TMPNAM1,
                              maxsize => MAXSIZE1, });
    Log::Info::add_sink    (TESTCHAN1, SINK2, 'FILE', undef,
                            { fn      => TMPNAM2,
                              maxsize => MAXSIZE2, });

    Log::Info::add_chan_trans(TESTCHAN1, TRANS1);
    Log::Info::add_sink_trans(TESTCHAN1, SINK1, TRANS2);

    my $suffix = 'aaa';
    for ((undef) x $messagecount) {
      my $msg = MESSAGE1 . $suffix++;
      Log(TESTCHAN1, 0, $msg);
      push @expect, $msg;
    }

    $ok = 1;
  }; if ( $@ ) {
    diag "test exception: $@";
    $ok = 0;
  }

  is $ok, 1, 'add size-limited file sinks to channel, log series of messages';
}

my @tmpnam1 = (TMPNAM1, map glob("$_.*"), TMPNAM1);
@tmpnam1    = @tmpnam1[1..$#tmpnam1,0]; # files in descending age order
my @tmpnam2 = map glob("$_*"), TMPNAM2;
@tmpnam2    = @tmpnam2[1..$#tmpnam2,0]; # files in descending age order

=head2 Test 16: all messages logged to rotated sink1

=cut

is_deeply [map @{slurp($_)}, reverse sort @tmpnam1],
          [map join('++++',(scalar reverse $_), $_), @expect];

=head2 Test 17: all messages logged to rotated sink2

=cut

is_deeply [map @{slurp($_)}, reverse sort @tmpnam2], [map '++' . $_, @expect];

=head2 Test 18: log rotated at appropriate size (sink1)

Test: each file to be less than or equal to MAXSIZE1+messagesize in size, and
for every file other than the last, the first message of the next file should
have taken them over the limit.

Log::Dispatch::FileRotate checks the size, if it's less than max, writes the
message; else pre-rotates.  Hence, the size may exceed the max by up to max
message size.

=cut

{
  my $ok = 0;

  for my $x ([\@tmpnam1, MAXSIZE1, 1], [\@tmpnam2, MAXSIZE2, 2]) {
    my ($tmpnams, $minsize) = @$x;
    my $maxsize = $minsize + max map length, MESSAGE1, MESSAGE2;

    for (my $i = 0; $i < @$tmpnams; $i++) {
      $_ = $tmpnams->[$i];
      my $size = -s $_;
      ok $size <= $maxsize, "x File $_ size $size <= $maxsize"
        or diag Dumper +{ map {; $_ => -s $_ } @$tmpnams};
      ok $i == $#$tmpnams || $size >= $minsize, "x File $_ size $size > $minsize"
        or diag Dumper +{ minsize => $minsize, 
                          maxsize => $maxsize, 
                          x => $x->[2] },
                       +{ map {; $_ => -s $_ } @$tmpnams };
    }
  }
}

=head2 Test 20: log switch at whole logged message point (sink1)

for each output file from SINK1, test that the last character is a newline

=cut

{
  my $ok = 0;

  eval {
    for (@tmpnam1) {
      open *TMPFH, $_;
      seek *TMPFH, -1, SEEK_END;
      my $a;
      read *TMPFH, $a, 1;
      close *TMPFH;
      die "Last character of $_ not newline:$a:\n"
        unless $a eq "\n";
    }
    $ok = 1;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  is $ok, 1, 'log switch at whole logged message point (sink1)';
}

=head2 Test 21: log switch at whole logged message point (sink2)

for each output file from SINK2, test that the last character is a newline

=cut

{
  my $ok = 0;

  eval {
    for (@tmpnam2) {
      open *TMPFH, $_;
      seek *TMPFH, -1, SEEK_END;
      my $a;
      read *TMPFH, $a, 1;
      close *TMPFH;
      die "Last character of $_ not newline:$a:\n"
        unless $a eq "\n";
    }
    $ok = 1;
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
    $ok = 0;
  }

  is $ok, 1, 'log switch at whole logged message point (sink2)';
}

=head2 Test 22: no messages logged to deleted fh sink

Test nothing to read on $in

=cut

{
  my @ready;
  eval {
    my $s = IO::Select->new;
    $s->add($in);
    @ready = $s->can_read(0);
  }; if ( $@ ) {
    print STDERR "Test failed:\n$@\n"
      if $ENV{TEST_DEBUG};
  }

  is $#ready, -1, 'no messages logged to deleted fh sink';
}
