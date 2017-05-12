package IPC::MorseSignals::TestSuite;

use strict;
use warnings;

use Data::Dumper;
use POSIX qw/pause SIGKILL EXIT_FAILURE/;

use IPC::MorseSignals::Emitter;
use IPC::MorseSignals::Receiver;

use base qw/Exporter/;

our @EXPORT_OK = qw/try bench init cleanup/;

$Data::Dumper::Indent = 0;

my ($lives, $pid, $rdr);

sub slaughter;
local $SIG{INT} = sub { slaughter };

sub diag { warn "# @_" }

sub spawn {
 --$lives;
 die 'forked too many times' if $lives < 0;
 pipe $rdr, my $wtr or die "pipe() failed: $!";
 $pid = fork;
 if (!defined $pid) {
  die "fork() failed: $!";
 } elsif ($pid == 0) {
  local %SIG;
  close $rdr or die "close() failed: $!";
  select $wtr;
  $| = 1;
  my $rcv = IPC::MorseSignals::Receiver->new(\%SIG, done => sub {
   my $msg = Dumper($_[1]);
   $msg =~ s/\n\r/ /g;
   print $wtr "$msg\n";
  });
  $SIG{__WARN__} = sub {
   my $warn = join '', @_;
   $warn =~ s/\n\r/ /g;
   print $wtr "!warn:$warn\n";
  };
  print $wtr "!ok\n";
  pause while 1;
  exit EXIT_FAILURE;
 }
 close $wtr or die "close() failed: $!";
 my $oldfh = select $rdr;
 $| = 1;
 select $oldfh;
 my $t = <$rdr>;
}

sub slaughter {
 if (defined $rdr) {
  close $rdr or die "close() falied: $!";
  undef $rdr;
 }
 if ($pid) {
  kill SIGKILL => $pid;
  my $kid;
  do {
   $kid = waitpid $pid, 0;
  } while ($kid != $pid && $kid != -1);
  undef $pid;
 }
}

sub respawn {
 diag "respawn ($lives lives left)";
 slaughter;
 spawn;
}

sub init {
 ($lives) = @_;
 $lives ||= 10;
 undef $pid;
 undef $rdr;
 spawn;
}

sub cleanup { slaughter }

my $snd = IPC::MorseSignals::Emitter->new;

sub try {
 my ($msg) = @_;
 my $speed = 2 ** 10;
 my $dump = Dumper($msg);
 1 while chomp $dump;
 $dump =~ s/\n\r/ /g; 
 $snd->reset;
 my $len = 0;
 while (($speed /= 2) >= 1) {
  $snd->post($msg);
  $len = $snd->len;
  my $a = 1 + (int($len / $speed) || 1);
  last unless $a <= 20;
  $snd->speed($speed);
  my $r = '';
  eval {
   local $SIG{ALRM} = sub { die 'timeout' };
   local $SIG{__WARN__} = sub { $a = alarm 0; die 'do not want warnings' };
   alarm $a;
   $snd->send($pid);
   $r = <$rdr>;
   $a = alarm 0;
  };
  if (defined $r) {
   1 while chomp $r;
   return 1, $speed, $len if $r eq $dump;
  }
  $snd->reset;
  respawn;
 }
 return 0, $speed, $len;
}

sub bench {
 my ($l, $n, $res) = @_;
 my $speed = 2 ** 16;
 my $ok = 0;
 my @alpha = ('a' .. 'z');
 my $msg = join '', map { $alpha[rand @alpha] } 1 .. $l;
 my $dump = Dumper($msg);
 1 while chomp $dump;
 $dump =~ s/\n\r/ /g;
 my $desc_base = "$l bytes sent $n time" . ('s' x ($n != 1));
 while (($ok < $n) && (($speed /= 2) >= 1)) {
  $ok = 0;
  my $desc = "$desc_base at $speed bits/s";
  diag "try $desc...";
TRY:
  for (1 .. $n) {
   $snd->post($msg);
   my $a = 1 + (int($snd->len / $speed) || 1);
   $snd->speed($speed);
   my $r = '';
   eval {
    local $SIG{ALRM} = sub { die 'timeout' };
    local $SIG{__WARN__} = sub { alarm 0; die 'do not want warnings' };
    alarm $a;
    $snd->send($pid);
    $r = <$rdr>;
    alarm 0;
   };
   if (defined $r) {
    1 while chomp $r;
    if ($r eq $dump) {
     ++$ok;
     next TRY;
    }
   }
   $snd->reset;
   respawn;
   last TRY;
  }
 }
 push @$res, $desc_base . (($speed) ? ' at ' . $speed . ' bits/s' : ' failed');
 return ($ok == $n);
}

1;
