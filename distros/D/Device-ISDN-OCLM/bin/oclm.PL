use Config;
use File::Basename qw(basename dirname);
chdir(dirname($0));
($file = basename($0)) =~ s/\.PL$//i;
open OUT,">$file" or die "Can't create $file: $!";
chmod(0755, $file);
print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{'startperl'} -w

!GROK!THIS!

print OUT <<'!NO!SUBS!';
# oclm.PL
# v0.30
# 2000/01/02
# merlin
#
# Control the 3com OfficeConnect LanModem

=head1 NAME

oclm - Control the 3com OfficeConnect LanModem

=head1 SYNOPSIS

 oclm {<option>} <command>

=head1 DESCRIPTION

This program can be used to control the 3com OfficeConnect LanModem,
an ISDN TA/router. Device statistics are printed to stdout along with
a status message (typically OK).

The options are:

=over 4

=item -lanmodem <hostname[:port]>

Specify the hostname (and optionally port) of your LanModem. By default,
the value of the B<OCLM_LANMODEM> environment variable is used; or, if that
is not set, then the value I<3com.oc.lanmodem>.

=item -password <password>

Specify the password needed to access your locked LanModem. By default,
the value of the B<OCLM_PASSWORD> environment variable is used. This is
not needed if either your LanModem is not password protected, or if
manual calling is accessible and you only use the B<connect>, B<disconnect>,
B<status> and B<manual> commands.

=back

The commands are:

=over 4

=item connect [<provider>]

Manually connect to the specified provider name or provider index
(1-offset). If no provider is specified, then connects to the first
provider not currently connected. This displays the progress of the
connection attempt on stdout.

=item disconnect [<provider>]

Manually disconnect from the specified provider name or line index
(1-offset). If no provider is specified, then disconnects from the first
provider currently connected.

=item abort [<provider>]

Manually abort connection attempt to the specified provider name or line
index (1-offset). If no provider is specified, then aborts from the
first provider currently connecting.

=item system

Print LanModem system statistics.

=item isdn

Print ISDN line statistics.

=item current

Print current call statistics.

=item last

Print last call statistics.

=item last10

Print last 10 call statistics.

=item sp

Print service provider statistics.

=item manual

Print manual call information.

=item id

Print caller ID information. This attempts to determine the phone number
of current incoming calls. It often fails.

=back

=head1 BUGS

Specifying your password in any manner is, of course, insecure. Hard to
abort a call. Others unknown.

=head1 SEE ALSO

L<Device::ISDN::OCLM>

=head1 COPYRIGHT

Copyright 1999-2000 Merlin Hughes.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

Merlin Hughes E<lt>merlin@merlin.org>

=cut

use strict;
use FileHandle;
use Device::ISDN::OCLM;

STDOUT->autoflush (1);

my $lanmodem = Device::ISDN::OCLM->new ();

my $host = $ENV{'OCLM_LANMODEM'};
$lanmodem->lanmodem ($host) if defined ($host);
my $password = $ENV{'OCLM_PASSWORD'};
$lanmodem->password ($password) if defined ($password);

my $command;

while (defined ($command = shift) && ($command =~ /^-/)) {
  if ($command eq '-help') {
    syntaxError ('-help');
  } elsif ($command eq '-lanmodem') {
    my $arg = shift;
    syntaxError ("No argument specified for $command") if !defined ($arg);
    $lanmodem->lanmodem ($arg);
  } elsif ($command eq '-password') {
    my $arg = shift;
    syntaxError ("No argument specified for $command") if !defined ($arg);
    $lanmodem->password ($arg);
  } else {
    syntaxError ("Unknown option: $command");
  }
}

if (!defined ($command)) {
  syntaxError ("No command specified");
} elsif (($command eq 'connect') || ($command eq 'disconnect') || ($command eq 'abort')) {
  my $sp = shift;
  my $actionMethod;
  my $indexMethod;
  my $updown;
  if ($command eq 'connect') { # TODO: Neaten
    $actionMethod = 'manualConnect';
    $indexMethod = 'connectIndex';
    $updown = 'down';
  } elsif ($command eq 'disconnect') {
    $actionMethod = 'manualDisconnect';
    $indexMethod = 'disconnectIndex';
    $updown = 'up';
  } else {
    $actionMethod = 'manualAbort';
    $indexMethod = 'abortIndex';
    $updown = 'down';
  }
  my $status = execute ($lanmodem, 'getManualStatistics');
  if ($status eq "OK") {
    my $info = $lanmodem->manualStatistics ();
    my $index = 0;
    if (defined ($sp)) {
      if ($sp =~ /^\d+$/) {
	$index = $sp;
      } else {
	my $name;
	do {
	  ++ $index;
	  $name = $info->serviceProvider ($index);
	  syntaxError ("Unknown provider") if !defined ($name);
	} while ($name ne $sp);
	$index = $info->$indexMethod ($index);
	syntaxError ("Provider not $updown") if ($index < 0);
      }
    } else {
      my $stat;
      do {
	++ $index;
	$stat = $info->callStatus ($index);
	syntaxError ("No $updown providers") if !defined ($stat);
      } while !($stat =~ /$updown/i);
      # BUG: This loop should also check indexMethod because for
      # abort all will be "down", so need to check that we can
      # get an abort index
      $index = $info->$indexMethod ($index);
    }
    $status = execute ($lanmodem, $actionMethod, $index);
    while (($status eq "CONNECTING") || ($status eq "LOGGING IN")) {
      print "$status        \r";
      sleep (1);
      $status = execute ($lanmodem, 'connectStatus', $index);
    }
  }
  print "$status        \n";
} elsif (($command eq 'system') ||
	 ($command eq 'isdn') ||
	 ($command eq 'current') ||
	 ($command eq 'last') ||
	 ($command eq 'last10') ||
	 ($command eq 'sp') ||
	 ($command eq 'manual')) {
  my $map = { 'system' => 'System', 'isdn' => 'ISDN', 'current' => 'Current',
	      'last' => 'Last', 'last10' => 'Last10', 'sp' => 'SP', 'manual' => 'Manual' };
  my $cmd = 'get' . $map->{$command} . 'Statistics';
  my $status = execute ($lanmodem, $cmd);
  if ($status eq "OK") {
    $cmd = $command . 'Statistics';
    my $info = $lanmodem->$cmd ();
    print $info->toString ();
  }
  print "$status\n";
} elsif ($command eq 'id') {
  my $status = execute ($lanmodem, 'getCurrentStatistics');
  if ($status eq "OK") {
    my $info = $lanmodem->currentStatistics ();
    foreach my $index (1 .. 2) {
      my $direction = $info->callDirection ($index);
      if (defined ($direction) && ($direction eq "Incoming")) {
	my $calling = $info->callingNumber ($index);
	$calling = "unknown" if !defined ($calling);
	my $called = $info->calledNumber ($index);
	$called = "unknown" if !defined ($called);
	print ("Caller $calling (calling $called)\n");
      }
    }
  }
  print "$status\n";
} else {
  syntaxError ("Unknown command: $command");
}

sub
execute
{
  my ($lanmodem, $command, $param) = @_;
  my $status = $lanmodem->$command ($param);
  while (($status eq "CLOCK") || ($status eq "PASSWORD")) {
    if ($status eq "CLOCK") {
      sleep (1);
      $status = $lanmodem->setClock ();
    } elsif ($status eq "PASSWORD") {
      sleep (1);
      $status = $lanmodem->enterPassword ();
    }
    if ($status eq "OK") {
      sleep (1);
      $status = $lanmodem->$command ($param);
    }
  }
  $status;
}

sub
syntaxError
{
  my ($error) = @_;
  my $help = ($error eq '-help');
  print "Error:\n  $error\n" if !$help;
  print "Syntax:\n  oclm {<option>} <command>" . ($help ? "" : " (-help for details)") . "\n";
  print "Options:\n" .
#    "  -debug\n" .
    "  -lanmodem <host>[:<port>]  - default: \$OCLM_LANMODEM or else 3com.oc.lanmodem\n" .
    "  -password <password>       - default: \$OCLM_PASSWORD or else none\n" .
    "  -help                      - display this help page and exit\n" if $help;
  print "Commands:\n" .
    "  connect [<provider>]       - manual connect to provider name or provider index\n" .
    "                               default: first disconnected provider\n" . 
    "  disconnect [<provider>]    - manual disconnect from provider name or line index\n" .
    "                               default: first connected provider\n" . 
    "  abort [<provider>]         - manual abort from provider name or line index\n" .
    "                               default: first connecting provider\n" . 
    "  manual                     - manual call statistics\n" .
    "  system                     - system statistics\n" .
    "  isdn                       - ISDN statistics\n" .
    "  current                    - current call statistics\n" .
    "  last                       - last call statistics\n" .
    "  last10                     - last 10 calls statistics\n" .
    "  sp                         - service provider statistics\n" .
    "  id                         - display caller ID statistics\n" if $help;
  exit (1);
}

!NO!SUBS!
