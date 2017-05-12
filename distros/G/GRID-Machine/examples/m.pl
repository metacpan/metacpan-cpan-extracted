#!/usr/bin/perl

use strict;

use GRID::Machine;
use Sys::Hostname;

for my $host qw( orion beowulf ) {

    my $machine = GRID::Machine->new(
        host => $host,
        remotelibs => [ qw( testrem ) ],
        uses => [ 'Sys::Hostname' ]
    );

    # register remote procedure
    my $r = $machine->sub( remote => q{
        print 'remote proc host: ' . &hostname . "\n";
        Alpha::Beta::Gamma::Test()
    } );
    die $r->errmsg unless $r->ok;

    # make remote call
    $r = $machine->remote();

    die $r->errmsg unless $r->ok;
    die $r->errmsg if $r->errmsg; # workaround!

    if (my $out = $r->stdout) {
        $out =~ s/^/[$host]-out-> /mg;
        print $out
    }

    if (my $err = $r->stderr) {
        $err =~ s/^/[$host]-err-> /mg;
        print $err
    }

    for my $ret ($r->Results) {
        print "ret> $ret\n";
    }

}
