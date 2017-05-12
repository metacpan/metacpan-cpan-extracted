#
#	NOTHREADS version of tracetest
#
use Time::HiRes qw(sleep);

my %args = @ARGV;

my $duration = $args{'-d'} || 35;

#
#	fork some procs
#
	my $cnt = $args{'-p'} || 2;
	my @procs = ();
	for (1..$cnt) {
		if (my $pid = fork()) {
			push @procs, $pid;
		}
		elsif (defined($pid)) {
			@procs = ();
			runtest();
			last;
		}
		else {
			die "Can't fork()\n";
		}
	}
	exit 1 unless scalar @procs;	# must be a child

#print STDERR "\n*** PIDs are $$,", join(', ', @procs), "\n";
	waitpid($procs[0], 0),
	shift @procs
		while (scalar @procs);

sub runtest {
#	print STDERR "In runtest\n";
	my $callback = sub {
		sleep 0.5;
		return time();
	};

	my $started = time();
	my $count = 1;
	while ((time() - $started) < $duration) {
#print STDERR "Scan ", $count++, "for thread $$:0\n";
		my @ret = array_ret();
#		print "array_ret returned ", join(', ', @ret), "\n";
		my $ret = scalar_ret();
		void_ret();
		recurse_ret(1);
		closure_ret($callback);
		eval_ret('sleep 0.5; time();');
	}
#print STDERR "Scan done for thread $$:0\n";
	return 1;
}

sub closure_ret {
	$_[0]->();
}

sub eval_ret {
	eval $_[0];
	return 1;
}

sub array_ret {
	sleep 0.5;
	return (1,2,3,4);
}

sub scalar_ret {
	sleep 0.5;
	return "scalar value";
}

sub void_ret {
	my $this = 'adffadfasdf';
	sleep 0.5;
}

sub recurse_ret {
	sleep 0.5 unless $_[0] < 10;
	return ($_[0] < 10) ?
		recurse_ret($_[0]+1) : $_[0];
}
