#!/usr/bin/perl

use warnings;
use strict;

$| = 1;

use HTTP::Server::Simple::Er;
my $server = HTTP::Server::Simple::Er->new(port => 7779);

print "me: ", $$, "\n";
$SIG{__WARN__} = sub {print "warning: ", @_};
my $surl = $server->child_server;
print "child: ", $server->child_pid, "\n";
kill INT => $$;

END { print "END: $$\n"; }

# vim:ts=2:sw=2:et:sta
