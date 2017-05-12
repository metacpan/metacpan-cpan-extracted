#!/usr/bin/perl -w

BEGIN {
    # copied from t/op/fork.t from Perl 5.8.0:
    require Config; import Config;
    unless ($Config{'d_fork'}
	    or (($^O eq 'MSWin32' || $^O eq 'NetWare') and $Config{useithreads}
		and $Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/
               ))
    {
	print "1..0 # Skip: no fork\n";
	exit 0;
    }
}

use strict;
use File::CounterFile;
my $counter = "./zz-counter-$$";
unlink($counter);

$| = 1;

my $num_rounds = 100;
my $num_kids = 10;
my $num_incs = 10;

print "1..$num_rounds\n";

for my $round (1 .. $num_rounds) {
    for (1 .. $num_kids) {
	my $kid = fork();
	die "Can't fork: $!" unless defined $kid;
	next if $kid;
	
	#print "Child $$\n";
	#select(undef, undef, undef, 0.01);
	my $c = File::CounterFile->new($counter);
	for (1 .. $num_incs) {
	    #select(undef, undef, undef, 0.01);
	    my $v = $c->inc;
	    #print "$$: $v\n";
	}
	exit;
    }

    for (1 .. $num_kids) {
	my $pid = wait;
	die "Can't wait: $!" if $pid == -1;
	#print "Kid $pid done\n";
    }
    #print "All done\n";

    my $c = File::CounterFile->new($counter);
    print "not " unless $c->value == $num_kids * $num_incs;
    print "ok $round\n";

    unlink($counter) || warn "Can't unlink $counter: $!";
}
