#!/usr/bin/perl
use strict;
use warnings;

use Hook::Output::Tiny;
use Test::More;

my $of = 't/stdout.txt';
my $ef = 't/stderr.txt';

my $h = Hook::Output::Tiny->new;

# both
{
    $h->hook();

    print "out 1\n";
    print "out 2\n";

    warn "err 1\n";
    warn "err 2\n";

    $h->unhook;

    $h->write($of, 'stdout');

    open my $ofh, '<', $of or die $!;
    my @out = <$ofh>;
    close $ofh;

    is (@out, 2, "write() stdout file ok");

    my @stdout = $h->stdout;
    is (@stdout, 0, "write() stdout() ok");

    $h->write($ef, 'stderr');

    open my $efh, '<', $ef or die $!;
    my @err = <$efh>;
    close $efh;

    is (@err, 2, "write() stderr file ok");

    my @stderr = $h->stderr;

    is (@stderr, 0, "write() stderr() ok");

    _unlink();
}

#stdout
{
    $h->hook('stdout');
    print "blah";
    $h->write($of, 'stdout');
    $h->unhook('stdout');

    my @stdout = $h->stdout;
    is (@stdout, 0, "stdout empty in only write");

    open my $ofh, '<', $of or die $!;
    my @out = <$ofh>;
    close $ofh;

    is (@out, 1, "stdout by itself is ok write()");

    _unlink();
}

#stderr
{
    $h->hook('stderr');
    warn 'blah';
    $h->write($ef, 'stderr');
    $h->unhook('stderr');

    my @stderr = $h->stderr;
    is (@stderr , 0, "stderr empty in only write");

    open my $efh, '<', $ef or die $!;
    my @err = <$efh>;
    close $efh;

    is (@err, 1, "stderr by itself is ok write()");

    _unlink();
}

sub _unlink {
    for ($of, $ef){
        unlink $_ or die $! if -e $_;
        is (-f $_, undef, "$_ unlinked ok");
    }
}

done_testing();
