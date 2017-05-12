#!/usr/bin/perl

use warnings;
use strict;

use lib "../lib";

use Data::Dumper;
use IPC::Exe qw(exe);

{
    # reap child processes 'xargs' when done
    local $SIG{CHLD} = 'IGNORE';

    # like IPC::Open2, except filehandles are generated on-the-fly
    my ($pid1, $TO_STDIN, $pid2, $FROM_STDOUT) = &{
        exe +{ stdin  => 1 }, sub { "2>&1" }, qw(perl -ne), 'print STDERR "360.0 / $_"',
        exe +{ stdout => 1 }, qw(bc -l),
    };

    # check if exe()'s were successful
    defined($pid1) && defined($pid2)
        or die("Failed to fork processes");

    # ask 'bc -l' results of "360 divided by given inputs"
    print $TO_STDIN "$_\n" for 2 .. 8;

    # we redirect stderr of 'perl' to stdout
    #   which, in turn, is fed into stdin of 'bc'

    # print captured outputs
    print "360 / $_ = " . <$FROM_STDOUT> for 2 .. 8;

    # close filehandles
    close($TO_STDIN);
    close($FROM_STDOUT);

    print Dumper([ $pid1, $TO_STDIN, $pid2, $FROM_STDOUT ]);
}
