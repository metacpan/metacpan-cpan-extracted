use strict;

use Test::More qw(no_plan);
use Data::Dumper;
use Test::Exception;

use threads;
use threads::shared;
our $work_done : shared = undef;


{
    package MyWorker;
    use base qw(GearmanX::Worker);
    use Data::Dumper;

    sub echo  :Expose  {
#	warn "WORKER: echo   params  ".Dumper @_;
	my $param = shift;
	if (ref ($param) eq 'ARRAY') {
	    return $param->[1];
	} elsif (ref ($param) eq 'HASH') {
	    return $param->{b};
	} else {
	    return $param;
	}
    }

    sub echo_2  :Expose  {
#	warn "WORKER: echo2   params  ".Dumper @_;
	my $param = shift;
	return $param->[1]->{b};
    }

    sub echo_3  :Expose  {
#	warn "WORKER: echo3   params  ".Dumper @_;
	my $param = shift;
	return [ '1+2', $param ] ;
    }

    sub echo_4  :Expose  {
#	warn "WORKER: echo3   params  ".Dumper @_;
	my $param = shift;
	return { a => $param } ;
    }

    sub aecho_1  :Expose {
	my $param = shift;
#	warn "in ASYNC";
	$work_done = $param->[1];
    }

    1;
}

my $saddr = $ENV{GEARMAND} || '127.0.0.1';

use GearmanX::Client;
my $c = new GearmanX::Client ( SERVERS => [$saddr] );
isa_ok ($c, 'GearmanX::Client');

unless ($c->status) {
    ok (1, "no server (maybe set GEARMAND environment variable)");
    exit;
}

#------------------------------------------------------

my $w = new MyWorker (SERVERS => $saddr);
$w->run_as_thread;


#-- first without any encoding, single scalars
my @r = $c->job_sync ('echo', '1+2');
is_deeply ($r[0], '1+2', 'echo roundtrip: scalar -> scalar');

#-- send a list, but get a scalar
@r = $c->job ('echo', [ '1+2', '3+4' ] );
is_deeply ($r[0], '3+4', 'echo roundtrip: list -> scalar');

#-- send hash get scalar
@r = $c->job ('echo', { a => '1+2', b => '3+4' } );
is_deeply ($r[0], '3+4', 'echo roundtrip: hash -> scalar');

#-- send list of * get scalar
@r = $c->job ('echo_2', [ 23, { a => '1+2', b => '3+4' } ] );
is_deeply ($r[0], '3+4', 'echo roundtrip: list of * -> scalar');

#-- send scalar get list
@r = $c->job ('echo_3', '3+4' );
is_deeply ($r[0], [ '1+2', '3+4' ], 'echo roundtrip: scalar get list');

#-- send scalar get hash
@r = $c->job ('echo_4', '3+4' );
is_deeply ($r[0], { a => '3+4' }, 'echo roundtrip: scalar get hash');


my $j = $c->job_async ('aecho_1', [ '1+2', '3+4' ]);
like ($j, qr/(\d+[.:]){1}/, 'aecho job id');

foreach (0..9) {    # polling is great, but max 10 secs
    sleep 1;
    last if $work_done;
}

is ($work_done, '3+4', 'async echo roundtrip: list -> scalar');

__END__



warn Dumper $c;


#my $result_ref = $c->do_task('xxxx', \ "1+2");
#warn Dumper $result_ref;

__END__







my $result_ref = $c->do_task('xxxx', \ "1+2");
#use Storable qw(thaw);
#my ($result) = thaw $$result_ref;
#print "1 + 2 = $result\n". Dumper $result;
print "1 + 2 = $$result_ref\n";

##use Storable qw(freeze);
#my $ff = freeze [ 3, 4, 5];
#my $result_ref = $c->do_task('xxxx', \ $ff);
#my ($result) = thaw $$result_ref;
#print "1 + 2 = $result\n". Dumper $result;


__END__

use threads;
use threads::shared;

my @workers = map { threads->new(\&MyWorker::new) } (1..1);
map { $_->detach } @workers;



sleep 4;


__END__



use constant WORKER_TIME => 5;

use_ok ('REST::Depend::Regex::Gearman');


my @urls      : shared = ();         # workers report back here
my @labels    : shared = ();        # workers report task labels here
my $work_cnt  : shared = 0;
my $work_drop : shared = 0;
my $alives    : shared = 0;



sub run_experiment {
    my $deps = shift;
    my $d = REST::Depend::Regex::Gearman->new ($deps);
    my %o = @_;
    $o{worker} ||= 'perfect';

    @urls = ();
    @labels = ();
    $work_cnt = 0;
    $work_drop = 0;

    warn "== MAIN: $o{nr_workers} =====================================================================================";
    my @workers = map { threads->new(\&Worker::run, "W$_", $o{worker}) } (1.. $o{nr_workers});
    map { $_->detach } @workers;
    $alives = scalar @workers;

    $d->evolve ($o{kick});

    my $start_time = time;
    my $end_time   = $start_time + $o{max_time}; # we plan to work at most some secs on that
    my @gearmandized;

  LOOP: {
    do {
      RESPONSE:
	while (my $url = shift @urls) {
#	    warn "MAIN: popped $url";

	    my $label = shift @labels; # there MUST be one
	    warn "MAIN: task label $label found to be finished";
	    if (my ($t) = $d->things ($label)) {
		if ($t->{gearmandized} && $t->{gearmandized}->[0]) {               # we asked for it
		    $t->{gearmandized} = [ undef, time, undef ];
		} else {
		    warn "MAIN: got back UNSOLICITED, ignored";
		    next RESPONSE;
		}
	    } else {
#		warn "MAIN: STRANGE got $label in queue which is not known in Petri";
		next RESPONSE;
	    }

	    if (my ($place) = $d->things ($url)) {
		next RESPONSE unless $place;                               # it can happen that we get reported a very old worker result
#		warn "MAIN: already got a place at $url: ".Dumper $place;
		$place->touch;
	    } else {
		warn "MAIN: STRANGE got $url in queue which is not known in Petri";
		next RESPONSE;
	    }
	    $d->evolve ($url);
	}
	warn "MAIN: sleeping a bit with alive $alives";
	sleep 1;

#	$d->evolve ('xxx') if time > $end_time - $loop_time + 2; # 2 secs after start we pretend something else happened

	@gearmandized = grep { $_->{gearmandized}->[0] } map { $d->things ($_) } $d->transitions;
	warn "still gearmandized: " . scalar @gearmandized;

#	warn "MAIN: now is ".time;
	my @lates = grep { $_->{gearmandized}->[1] + $_->{gearmandized}->[2] < time }   @gearmandized;
	warn "MAIN: lates are now ".Dumper [ map { $_->{label} } @lates ];
	$d->ignite (map { $_->{label} }
		    map { $_->{gearmandized}->[0] = undef; $_ } # make sure we take it away from the worker
		    @lates);      # fire them again

#	last LOOP if time > $end_time;                                            # we end this game at worst-case time (sequential)
    } until scalar @gearmandized == 0 and scalar @urls == 0;
    }
#    warn "MAIN: leftovers: ".Dumper \@urls;
    is (scalar @urls, 0,            "nr $o{nr_workers} emptied all reported URLs (in ".(time - $start_time)." secs)");
    ok ($work_cnt >= $o{must_work}, "nr $o{nr_workers} worker executed at least as many times (works: $work_cnt, droppings: $work_drop)");
    is (scalar $d->ignitables, 0,   "nr $o{nr_workers} no more ignitions");

    warn "MAIN: killing all running workers";
    map  { $_->kill('KILL') } 
         grep { $_->is_running() } @workers;

}

my $deps = {
    q{aaa} => {
	q{bbb} => [ 'aaa2bbb' => { param1 => 'ppp' } ],
	q{ccc} => [ 'aaa2ccc' => { param1 => 'qqq' } ],
	q{ddd} => [ 'aaa2ccc' => { param1 => 'qqq' } ],
	q{eee} => [ 'aaa2ccc' => { param1 => 'qqq' } ]
    },
    q{eee} => {
	q{fff} => [ 'aaa2bbb' => { param1 => 'ppp' } ],
    },
};

#run_experiment ($deps, kick => 'eee', must_work => 1, nr_workers => 1, max_time => 1 * WORKER_TIME * 2);

foreach my $kind (
                  'suicidal',
                  'perfect',
                  'slow',
                  'sloppy'
                  ) {
    foreach my $nr (reverse (1..6)) { # varying the number of workers
	foreach (1..10) { # just stress-testing
	    run_experiment ($deps, kick => 'aaa', must_work => 5, worker => $kind, nr_workers => $nr, max_time => 10 * WORKER_TIME  );
	}
	sleep WORKER_TIME * 3; # just wait everything out
    }
}

__END__

my $deps = {
    q{/(?<map>.+)/} => {
	q{/$_{map}/.corpus} => [ 'map2corpus' => { config => q{/$_{map}/.config/map2corpus} } ]
    },
};

throws_ok {
    my $d = new REST::Depend::Regex ();
} qr/dependency/, 'mandatory dependency';

{
    my $deps = {
	q{/(?<map>.+)/} => {
	    q{/$_{map}/.corpus} => [ 'map2corpus' => { config => q{/$_{map}/.config/map2corpus} } ]
	},
    };
    my $d = new REST::Depend::Regex ($deps);
    isa_ok($d, 'REST::Depend::Regex');
    isa_ok($d, 'Graph::PetriNet');

    is (scalar $d->places,      0, 'empty places');
    is (scalar $d->transitions, 0, 'no transitions, so sad');
    is ($d->dependencies, $deps, 'identical dependencies');
}

#TODO: check consistency of rules

{ # structural test
    my $deps = {
	q{aaa} => {
	    q{bbb} => [ 'aaa2bbb' => { param1 => 'ppp' } ]
	},
    };
    my $d = new REST::Depend::Regex ($deps);
    my @new = $d->expand ('aaa');
    is_deeply ([ sort @new ], [ 'aaa', 'bbb' ],                                   'newlies');
    is_deeply ([ sort $d->places ],      [ 'aaa', 'bbb' ],                        'aaa expansion: places');
    is_deeply ([ sort $d->transitions ], [ 'a62802c1123ca78c7f6a925312743d21' ],  'aaa expansion: transitions');

    my ($t) = $d->things ('a62802c1123ca78c7f6a925312743d21');
    is_deeply ($t->{_in_places},  [ $d->things ('aaa') ], 'aaa2bbb in');
    is_deeply ($t->{_out_places}, [ $d->things ('bbb') ], 'aaa2bbb out');
}

{ # with pattern match
    my $deps = {
	q{/(?<map>.+)/} => {
	    q{/$_{map}/.corpus} => [ 'map2corpus' => { } ]
	},
    };
    my $d = new REST::Depend::Regex ($deps);
    my @new = $d->expand ('/aaa/');
    is_deeply ([ sort @new ], [ '/aaa/', '/aaa/.corpus' ],                                'newlies');
#    warn Dumper $d;
    is_deeply ([ sort $d->places ],      [ '/aaa/', '/aaa/.corpus' ],                     '/aaa/ expansion: places');
    is_deeply ([ sort $d->transitions ], [ '6d371bbb55474cf69db347dbb4e50a36' ],          '/aaa/ expansion: transitions');

    my ($t) = $d->things ('6d371bbb55474cf69db347dbb4e50a36');
    is_deeply ($t->{_in_places},  [ $d->things ('/aaa/') ],        'map2corpus_1 in');
    is_deeply ($t->{_out_places}, [ $d->things ('/aaa/.corpus') ], 'map2corpus_1 out');
}

{ # duplicate targets and sources
    my $deps = {
	q{^/(?<map>.+)/$} => {
	    q{/$_{map}/.corpus} => [ 'map2corpus' => { } ],
	    q{/$_{map}/.vs}     => [ 'map2vs'     => { } ]
	},
	q{^/aaa/$} => {
	    q{/aaa/.corpus}     => [ 'map2corpus' => { } ],
	},
    };
    my $d = new REST::Depend::Regex ($deps);
    my @new = $d->expand ('/aaa/');
    is_deeply ([ sort @new ], [ '/aaa/', '/aaa/.corpus', '/aaa/.vs' ],             'newlies');
#warn Dumper $d;
    is_deeply ([ sort $d->places ],      [ '/aaa/', '/aaa/.corpus', '/aaa/.vs' ],  '/aaa/ expansion: places');
    is_deeply ([ sort $d->transitions ], [ '6d371bbb55474cf69db347dbb4e50a36',
					   'cf2694d30f561b3cd15e3f581acd5450'  ],  '/aaa/ expansion: transitions');
    $deps->{ q{(?<resource>/(?<map>.+)/.corpus)} } = {
	q{/$_{map}/.vs/4x3} => [ 'corpus2vs' => { config => q{/$_{map}/.config/corpus2vs} } ]
    };

    @new = $d->expand ('/aaa/.corpus');
#warn Dumper $d;
    is_deeply ([ sort @new ], [ '/aaa/.vs/4x3' ],             'newlies');
    is_deeply ([ sort $d->places ],      [ '/aaa/', '/aaa/.corpus', '/aaa/.vs', '/aaa/.vs/4x3' ],  '/aaa/.corpus expansion: places');
    is_deeply ([ sort $d->transitions ], [ '55aa189d5c8bf7f4959c333e57eea00f',
					   '6d371bbb55474cf69db347dbb4e50a36',
					   'cf2694d30f561b3cd15e3f581acd5450'  ],  '/aaa/.corpus expansion: transitions');
}



exit;

# TODO: ignite erzeugt knoten?
# TODO params


__END__


my @log = (
    [ 1, '/map1/' ],
    [ 2, '/xxxx/' ],
    [ 3, '/map1/' ]
    );

my $s = $d->scheduler (\@log);

is_deeply (['/map1/',
	    '/map1/.corpus',
	    '/xxxx/',
	    '/xxxx/.corpus'
	   ], [
	       sort $s->places
	   ], 'involved resources');

is ((scalar grep { $_ =~ /^map2corpus/ } $s->transitions), 2, 'found all processes');



    sub echo_1 :Expose :storable(in)  {
	warn "WORKER: echo_1   params  ".Dumper @_;
	return $_[1] ;
    }

    sub echo_2 :Expose :storable(in)  {
	warn "WORKER: echo_2   params  ".Dumper @_;
	my %o = @_;
	return $o{b} ;
    }

    sub echo_3 :Expose :storable(in)  {
	warn "WORKER: echo_3   params  ".Dumper @_;
	return $_[1]->{b} ;
    }

    sub echo_4 :Expose :storable(out)  {
	warn "WORKER: echo_3   params  ".Dumper @_;
	return { a => $_[0] } ;
    }
