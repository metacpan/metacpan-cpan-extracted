#!/usr/bin/perl

use strict;
use warnings;

use Symbol;
use Test::More tests => 5;
use IO::Handle;
BEGIN { use_ok('IPC::ForkPipe') };

#########################
my $fh = gensym;

my $pid = pipe_from_fork( $fh );
die "Unable to fork: $!" unless defined $pid;

if( $pid ) {    # parent
    pass( "pipe_from_fork didn't die" );
    my $line = <$fh>;
    chomp $line;
    is( $line, "Hello world", "Text from child" );
    waitpid $pid, 2;
}
else {          # child
    print "Hello world\n";
    exit 0;
}

#########################
$pid = pipe_to_fork( $fh );
die "Unable to fork: $!" unless defined $pid;
if( $pid ) {    # parent
    pass( "pipe_to_fork didn't die" );
    print $fh "Honk honk\n";
    $fh->autoflush( 1 );
    waitpid $pid, 2;
}
else {          # child
    my $line = <>;
    chomp $line;
    die "Wrong" if $line ne 'Honk honk';
    exit 0;
}

pass( "Sane exit" );
