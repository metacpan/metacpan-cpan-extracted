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
    warn "I am " . getpwuid($<);
}

sub something {
    warn "else...";
}

return 1 if caller;

my $doit = Doit->init;

my $remote = $doit->do_sudo; # (sudo_opts => ['-u', '#'.$<]);
#my $cmd = q{echo $(hostname; echo -n ": "; date)};
#$doit->system($cmd);
$doit->call("hello");
#$remote->system($cmd);
#$remote->system("id");
$remote->call("hello");
$remote->call("something");

my $second_remote = $doit->do_sudo;
$second_remote->system('echo', 'Running two sudos in parallel is OK');

system("ls -al /tmp/.doit*"); # don't use $doit->system here, as it may fail --- with Linux Abstract Namespaces Sockets, nothing is listed here

warn $remote->exit;

__END__
