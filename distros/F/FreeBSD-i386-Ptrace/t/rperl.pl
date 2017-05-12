#!/usr/local/bin/perl
#
# $Id: rperl.pl,v 0.4 2015/01/14 06:30:20 dankogai Exp $
#
use strict;
use warnings;
use FreeBSD::i386::Ptrace;
use FreeBSD::i386::Ptrace::Syscall;
use File::Temp;
use BSD::Resource;
setrlimit( RLIMIT_CPU,   1, 1 );
setrlimit( RLIMIT_CORE,  0, 0 );

our $DEBUG = 0;
my @banned = qw{
ptrace fork vfork rfork bind listen accept
sleep nanosleep
};
my %banned = map { $_ => 1 } @banned;
my $timeout = 1;

my $src    = slurp();

my $pfh = File::Temp->new() or die $!;
$pfh->print($src);
$pfh->close;

my $coh = File::Temp->new() or die $!;
$coh->autoflush(1);
my $ceh = File::Temp->new() or die $!;
$ceh->autoflush(1);

defined( my $pid = fork() ) or die "fork failed:$!";

if ( $pid == 0 ) {    # son
    no warnings;
    close STDIN;
    open STDOUT, '>&', $coh;
    open STDERR, '>&', $ceh;
    # showtime!
    pt_trace_me;
    exec qw/perl -Tw/, $pfh->filename;
}
else {                # mother
    wait;             # for exec;
    eval {
        local $SIG{ALRM} = sub { die "timed out\n" };    # NB: \n required
        alarm $timeout;
        my $count = 0;    # odd on enter, even on leave
	while ( pt_to_sce($pid) == 0 ) {
            last if wait == -1;
            my $call = pt_getcall($pid);
	    my $name = $SYS{$call} || 'unknown';
            last if $name eq 'exit';
            next if !$banned{ $name };
	    #pt_kill($pid);
	    ptrace(PT_CONTINUE, $pid, 0, 9);
	    die "SYS_$SYS{$call} banned.\n";
        }
        alarm 0;
    };
    if ($@) {
        print "# $pid killed: $@";
    }
    my $cout = slurp($coh->filename);
    my $cerr = slurp($ceh->filename);
    print "# stdout\n", $cout, "\n", "# stderr\n", $cerr, "\n";
}

sub slurp {
    my $ret;
    local $/;
    if (@_) {
        my $fn = shift;
        open my $fh, "<", $fn or die "$fn:$!";
        $ret = <$fh>;
        close $fh;
    }
    else {
        $ret = <>;
    }
    $ret;
}
