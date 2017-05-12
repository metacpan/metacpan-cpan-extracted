#!/usr/bin/perl

use warnings;
use strict;

use lib "../lib";

use Data::Dumper;
use IPC::Exe qw(exe);

{
    # reap child processes 'xargs' when done
    local $SIG{CHLD} = 'IGNORE';

    # like IPC::Open3, except filehandles are generated on-the-fly
    my ($pid, $TO_STDIN, $FROM_STDOUT, $FROM_STDERR) = &{
        exe +{ stdin => 1, stdout => 1, stderr => 1 }, qw(xargs ls -ld),
    };

    # check if exe() was successful
    defined($pid) or die("Failed to fork process");

    # ask 'xargs' to 'ls -ld' three files
    print $TO_STDIN "/bin\n";
    print $TO_STDIN "does_not_exist\n";
    print $TO_STDIN "/etc\n";

    # cause 'xargs' to flush its stdout
    close($TO_STDIN);

    # print captured outputs
    print "stderr> $_" while <$FROM_STDERR>;
    print "stdout> $_" while <$FROM_STDOUT>;

    # close filehandles
    close($FROM_STDOUT);
    close($FROM_STDERR);

    print Dumper([ $pid, $TO_STDIN, $FROM_STDOUT, $FROM_STDERR ]);
}
