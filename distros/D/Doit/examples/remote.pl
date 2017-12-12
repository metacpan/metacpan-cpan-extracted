#!/usr/bin/perl -w
# -*- cperl -*-

#
# Author: Slaven Rezic
#

use strict;
use FindBin;
use lib ("$FindBin::RealBin/../lib");
use Doit;

sub hello {
    require Sys::Hostname;
    warn "This runs somewhere: " . Sys::Hostname::hostname();
}

sub interactive {
    print STDERR "A question (y/n) ";
    chomp(my $yn = <STDIN>);
    print STDERR "You said: <$yn>\n";
}

return 1 if caller;

my $doit = Doit->init;

use Getopt::Long;
GetOptions("root"   => \my $do_root,
	   "remote" => \my $do_remote,
	   "local"  => \my $do_local,
	  )
    or die "usage: $0 [--root|--remote|--local]\n";

sub create_remote_connection {
    if ($do_root) {
	$doit->do_ssh_connect("eserte.dev4.bbbike.org", debug => 1, as => "root");
    } elsif ($do_remote) {
	$doit->do_ssh_connect("eserte.dev4.bbbike.org", debug => 1);
    } else {
	$doit->do_ssh_connect("localhost", debug => 1);
    }
}

my $remote = create_remote_connection();
my $cmd = q{echo $(hostname; echo -n ": "; date)};
$doit->system($cmd);
$doit->call("hello");
$remote->system($cmd);
$remote->system("id");
$remote->call("hello");
$remote->call("interactive");

my $second_remote = create_remote_connection();
$second_remote->system('echo', 'using 2nd connection');

$remote->system('echo', 'using 1st connection');
#$remote->exit;

__END__
