#!/usr/bin/perl
#
# $Id: perlwmii.pl 10 2008-12-15 20:57:02Z gomor $
#
use strict; use warnings;

use lib '/home/gomor/perl5/lib/perl/5.8.8';

my $client = $ENV{WMII_ADDRESS};

use Lib::IXP qw(:subs :consts);
use IO::Socket;
use File::Find;
use threads;

open(my $log, '>', "$ENV{HOME}/perlwmii.log") or die("open: $!\n");
$log->autoflush(1);

print $log "WMII_ADDRESS: $ENV{WMII_ADDRESS}\n";

my @proglist = ();
my $proglist = '';

my $statusBar = '';

my @normcolors  = ('#888888', '#222222', '#333333');
my @focuscolors = ('#ffffff', '#285577', '#4c7899');
my $background  = '#333333';
my $font        = '-*-fixed-medium-r-*-*-13-*-*-*-*-*-*-*';

my $mod   = 'Mod1';
my $left  = 'h';
my $right = 'l';
my $up    = 'k';
my $down  = 'j';

configure();
print $log "configure() done\n";

starts();
print $log "starts() done\n";

socketpair(CHILD, PARENT, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
   or die("socketpair [$!]\n");
print $log "socketpair done\n";

# Create xread event loop, it writes to parent what it has read
threads->create(sub {
   print $log "xread starts\n";
   PARENT->blocking(0);
   PARENT->autoflush(1);
   while (1) {
      xread($client, '/event', fileno(PARENT))
         or print $log "ERROR: xread: ".ixp_errbuf()."\n";
   }
   print $log "xread exited !!!!\n";
   return(0);
});

print $log "eventLoop starts\n";
CHILD->autoflush(1);
eventLoop(\*CHILD);
print $log "eventLoop exited !!!\n";

#
# Subroutines
#

sub starts {
   system("/usr/lib/gnome-settings-daemon/gnome-settings-daemon &");
   system("nm-applet --sm-disable &");
   system("spicctrl -l 1 && spicctrl -l 0");
}

sub configure {
   # Keys
   xwrite($client, '/keys',
"$mod-space\n".
"$mod-d\n".
"$mod-s\n".
"$mod-m\n".
"$mod-p\n".
"$mod-Return\n".
"$mod-Shift-$left\n".
"$mod-Shift-$right\n".
"$mod-Shift-$up\n".
"$mod-Shift-$down\n".
"$mod-$left\n".
"$mod-$right\n".
"$mod-$up\n".
"$mod-$down\n".
"$mod-1\n".
"$mod-2\n".
"$mod-3\n".
"$mod-4\n".
"$mod-5\n".
"$mod-6\n".
"$mod-7\n".
"$mod-8\n".
"$mod-9\n".
"$mod-0\n".
"$mod-Shift-1\n".
"$mod-Shift-2\n".
"$mod-Shift-3\n".
"$mod-Shift-4\n".
"$mod-Shift-5\n".
"$mod-Shift-6\n".
"$mod-Shift-7\n".
"$mod-Shift-8\n".
"$mod-Shift-9\n".
"$mod-Shift-0\n".
"$mod-Shift-c\n".
"$mod-f\n".
"$mod-Shift-space\n".
""
   ) or print $log "ERROR: xwrite: ".ixp_errbuf()."\n";

   xwrite($client, '/ctl',
"font $font\n".
"focuscolors ".join(' ', @focuscolors)."\n".
"normcolors ".join(' ', @normcolors)."\n".
"grabmod $mod\n".
"border 2\n".
""
   )
      or print $log "ERROR: xwrite: ".ixp_errbuf()."\n";

   # Colrules
   xwrite($client, '/colrules',
"/.*/ -> 58+42\n".
""
   ) or print $log "ERROR: xwrite: ".ixp_errbuf()."\n";

   # Tagging rules
   xwrite($client, '/tagrules',
"/XMMS.*/ -> ~\n".
"/Mplayer.*/ -> ~\n".
"/aMSN.*/ -> ~\n".
"/.*/ -> !\n".
"/.*/ -> 1\n".
""
   ) or print $log "ERROR: xwrite: ".ixp_errbuf()."\n";

   # Status bar
   statusBar();

   # Action items
   #my @items = qw(quit);
}

sub proglist {
   no warnings 'File::Find';
   find(\&wanted, split(':', $ENV{PATH}));
   $proglist .= "$_\n" for sort(@proglist);
}

sub wanted {
   -f $File::Find::name && -x _ &&  do {
      $File::Find::name =~ s/^.*\///;
      push @proglist, $File::Find::name;
   }
}

sub statusBar {
   main->processCreateTag(1);
   main->processCreateTag(2);
   main->processCreateTag(3);
   main->processCreateTag(4);
   main->processCreateTag(5);
   main->processCreateTag(6);
   main->processCreateTag(7);
   main->processCreateTag(8);
   main->processCreateTag(9);
   main->processCreateTag(0);
   threads->create(sub {
      xcreate($client, '/rbar/status', 'test')
         or print $log "ERROR: xcreate: ".ixp_errbuf()."\n";
      while (1) {
         chomp(my $bat  = `acpi -b`);
         chomp(my $date = `date`);
         chomp(my $cpu  = `sensors |grep Core`);
         $bat  =~ s/Battery\s+\d+:\s+(?:dis)?charging,\s+(\d+%),\s+(\d{2}:\d{2}:\d{2}).*$/$1 ($2)/;
         $date =~ s/^(.*\d{1,2}:\d{1,2}):\d{1,2}(.*)$/$1$2/;
         $cpu  =~ s/^Core\s+\d:\s+(\+\d+.\d+...).*$/$1/s;
         $statusBar = "$cpu | $bat | $date";
         xwrite($client, '/rbar/status', $statusBar)
            or print $log "ERROR: xwrite: ".ixp_errbuf()."\n";
         sleep(60);
      }
      return(0);
   });
}

sub eventLoop {
   my ($in) = @_;
   while (1) {
      chomp(my $line = <$in>);
      processEvent($line);
   }
}

sub processEvent {
   my ($event) = @_;
   print $log "DEBUG: EVENT: $event\n";
   my @toks = split(/\s+/, $event);
   my $sub = "process@{[shift @toks]}";
   if (main->can($sub)) {
      main->$sub(@toks);
   }
   else {
      print $log "DEBUG: NEW EVENT: $event\n";
   }
}

sub processKey {
   shift; my @args = @_;

   my $keys = {
      "$mod-space" => sub { xwrite($client, '/tag/sel/ctl', 'select toggle') },
      "$mod-d" => sub { xwrite($client, '/tag/sel/ctl', "colmode sel default") },
      "$mod-s" => sub { xwrite($client, '/tag/sel/ctl', "colmode sel stack")   },
      "$mod-m" => sub { xwrite($client, '/tag/sel/ctl', "colmode sel max")     },
      "$mod-p" => sub { system("`dmenu -b -fn 'fixed' -nf '$normcolors[0]' -nb '$normcolors[1]' -sf '$focuscolors[0]' -sb '$focuscolors[1]'` &"); 1 },
      "$mod-Return" => sub { system("x-terminal-emulator &"); 1 },
      "$mod-Shift-$left"  => sub { xwrite($client, '/tag/sel/ctl', 'send sel left') },
      "$mod-Shift-$right" => sub { xwrite($client, '/tag/sel/ctl', 'send sel right') },
      "$mod-Shift-$up" => sub { xwrite($client, '/tag/sel/ctl', 'send sel up') },
      "$mod-Shift-$down" => sub { xwrite($client, '/tag/sel/ctl', 'send sel down') },
      "$mod-$left"   => sub { xwrite($client, '/tag/sel/ctl', 'select left') },
      "$mod-$right"  => sub { xwrite($client, '/tag/sel/ctl', 'select right') },
      "$mod-$up"     => sub { xwrite($client, '/tag/sel/ctl', 'select up') },
      "$mod-$down"   => sub { xwrite($client, '/tag/sel/ctl', 'select down') },
      "$mod-1" => sub { xwrite($client, '/ctl', 'view 1') },
      "$mod-2" => sub { xwrite($client, '/ctl', 'view 2') },
      "$mod-3" => sub { xwrite($client, '/ctl', 'view 3') },
      "$mod-4" => sub { xwrite($client, '/ctl', 'view 4') },
      "$mod-5" => sub { xwrite($client, '/ctl', 'view 5') },
      "$mod-6" => sub { xwrite($client, '/ctl', 'view 6') },
      "$mod-7" => sub { xwrite($client, '/ctl', 'view 7') },
      "$mod-8" => sub { xwrite($client, '/ctl', 'view 8') },
      "$mod-9" => sub { xwrite($client, '/ctl', 'view 9') },
      "$mod-0" => sub { xwrite($client, '/ctl', 'view 0') },
      "$mod-Shift-1" => sub { xwrite($client, '/client/sel/tags', '1') },
      "$mod-Shift-2" => sub { xwrite($client, '/client/sel/tags', '2') },
      "$mod-Shift-3" => sub { xwrite($client, '/client/sel/tags', '3') },
      "$mod-Shift-4" => sub { xwrite($client, '/client/sel/tags', '4') },
      "$mod-Shift-5" => sub { xwrite($client, '/client/sel/tags', '5') },
      "$mod-Shift-6" => sub { xwrite($client, '/client/sel/tags', '6') },
      "$mod-Shift-7" => sub { xwrite($client, '/client/sel/tags', '7') },
      "$mod-Shift-8" => sub { xwrite($client, '/client/sel/tags', '8') },
      "$mod-Shift-9" => sub { xwrite($client, '/client/sel/tags', '9') },
      "$mod-Shift-0" => sub { xwrite($client, '/client/sel/tags', '0') },
      "$mod-f" => sub { xwrite($client, '/client/sel/ctl', 'Fullscreen toggle') },
      "$mod-Shift-c" => sub { xwrite($client, '/client/sel/ctl', 'kill') },
      "$mod-Shift-space" => sub { xwrite($client, '/tag/sel/ctl', 'send sel toggle') },
   };

   &{$keys->{$args[0]}}()
      or print $log "ERROR: processKey: ".ixp_errbuf()."\n";
   print $log "processKey: $args[0]\n";
}

sub processColumnFocus {
   shift; my @args = @_;
}

sub processClientFocus {
   shift; my @args = @_;
   if (defined($args[0])) {
      print $log "processClientFocus: $args[0]\n";
      my $buf = xread($client, '/client/sel/props', -1) or return;
      my @toks = split(':', $buf, 3);
      xcreate($client, '/lbar/status', $toks[-1])
         or print $log "ERROR: xcreate: ".ixp_errbuf()."\n";
   }
}

sub processCreateClient {
   shift; my @args = @_;
}

sub processDestroyClient {
   shift; my @args = @_;
}

sub processCreateTag {
   shift; my @args = @_;
   if (defined($args[0])) {
      my $name = shift(@args);
      xcreate($client, "/lbar/$name", join(' ', @normcolors)." $name")
         or print $log "ERROR: processCreateTag(): ".ixp_errbuf()."\n";
   }
}

sub processDestroyTag {
   shift; my @args = @_;
   if (defined($args[0])) {
      xremove($client, "/lbar/$args[0]")
         or print $log "ERROR: processDestroyTag(): ".ixp_errbuf()."\n";
   }
}

sub processFocusTag {
   shift; my @args = @_;
   main->processClientFocus(@args);
   if (defined($args[0])) {
      xwrite($client, "/lbar/$args[0]", join(' ', @focuscolors)." $args[0]")
         or print $log "ERROR: processFocusTag(): ".ixp_errbuf()."\n";
   }
}

sub processUnfocusTag {
   shift; my @args = @_;
   if (defined($args[0])) {
      xwrite($client, "/lbar/$args[0]", join(' ', @normcolors)." $args[0]")
         or print $log "ERROR: processUnfocusTag(): ".ixp_errbuf()."\n";
   }
}

sub processUrgentTag {
   shift; my @args = @_;
}

sub processNotUrgentTag {
   shift; my @args = @_;
}

sub processCreateColumn {
   shift; my @args = @_;
}

sub processDestroyColumn {
   shift; my @args = @_;
}

sub processClientMouseDown {
   shift; my @args = @_;
}

sub processClientClick {
   shift; my @args = @_;
}

sub processLeftBarClick {
   shift; my @args = @_;
   if (defined($args[0])) {
      xwrite($client, '/ctl', "view $args[0]")
         or print $log "ERROR: processLeftBarClick(): ".ixp_errbuf()."\n";
   }
}

sub processFocusFloating {
   shift; my @args = @_;
}

sub processUrgent {
   shift; my @args = @_;
}

sub processNotUrgent {
   shift; my @args = @_;
}
