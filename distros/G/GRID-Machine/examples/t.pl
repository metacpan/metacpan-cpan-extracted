#!/usr/bin/perl

use strict;
use GRID::Machine;
use Sys::Hostname;

my $host = 'beowulf';

my $machine = GRID::Machine->new(
    host => $host,
    uses => [ 'Sys::Hostname' ]
);

# register remote procedure
my $r = $machine->sub( remote => q{
    my ($arg1, $arg2, $lsub, $arg3, $arg4) = @_;
    die "Code reference expected\n" unless UNIVERSAL::isa($lsub, 'CODE');
    print 'remote proc host: ' . &hostname . "\n";
    my @cb_ret = &test_callback;
    my @cb_ret1 = $lsub->();
    return "ret from remote sub (named callback ret: '@cb_ret', anonymous callback ret: '@cb_ret1')"
} );
die $r->errmsg unless $r->ok;

# register local callback (install remote stub for named local callback)
$r = $machine->callback( test_callback => sub {
    print 'local callback host: ' . &hostname . "\n";
    return 'ret from local callback'
} );
die $r->errmsg unless $r->ok;

# make remote call
$r = $machine->remote(
    'arg1', 2,
    # pass local callback as an argument
    # (crete remote stub for anonymous inline callback)
    $machine->callback( sub {
        print "inside anonymous inline callback...\n";
        return 'anon ret'
    } ), [], 'last argument'
);

die $r->errmsg unless $r->noerr;

if (my $out = $r->stdout) {
    $out =~ s/^/[$host]out> /m;
    print $out
}

if (my $err = $r->stderr) {
    $err =~ s/^/[$host]err> /m;
    print $err
}

for my $ret ($r->Results) {
    print "ret> $ret\n";
}

# pp2@nereida:~/DMITRI/GRID-Machine-0.073/examples$ t.pl
# local callback host: nereida.deioc.ull.es
# inside inline callback...
# [beowulf]out> remote proc host: beowulf
# ret> ret from remote sub (named callback ret: 'ret from local callback', \
#                                      anonymous callback ret: 'anon ret')
# pp2@nereida:~/DMITRI/GRID-Machine-0.073/examples$ 
