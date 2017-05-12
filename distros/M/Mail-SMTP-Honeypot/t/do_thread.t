# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..21\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
do './recurse2txt';     # get my Dumper

use Mail::SMTP::Honeypot;
*do_thread = \&Mail::SMTP::Honeypot::do_thread;

$loaded = 1;
print "ok 1\n";
######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

$test = 2;

sub ok {
  print "ok $test\n";
  ++$test;
}

sub next_sec {
  my ($then) = @_;
  $then = time unless $then;
  my $now;
# wait for epoch
  do { select(undef,undef,undef,0.1); $now = time }
        while ( $then >= $now );
  $now;
}

sub gotexp {
  my($got,$exp) = @_;
  if ($exp =~ /\D/) {
    print "got: $got\nexp: $exp\nnot "
        unless $got eq $exp;
  } else {
    print "got: $got, exp: $exp\nnot "
        unless $got == $exp;
  }
  &ok;
}

################################################################
################################################################

##	set up parms for test
my @answers;
my $reportr = sub {
  my($key) = @_;
  push @answers,'r'. $key;
};

my $reportw = sub {
  my($key) = @_;
  push @answers,'w'. $key;
};

my $conf = {};
Mail::SMTP::Honeypot::check_config($conf);
my($tp) = Mail::SMTP::Honeypot::_trace();
$$tp = {
	DUMMY	=> {
		read	=> $reportr,
		write	=> $reportw,
	},
	1	=> {
		read	=> $reportr,
	},
	2	=> {
		write	=> $reportw,
	},
	3	=> {
		read	=> sub {
				my($key) = @_;
				delete ${$tp}->{4};
				&$reportr;
			   },
		write	=> $reportw,
	},
	4	=> {
		read	=> $reportr,
		write	=> $reportw,
	},
	5	=> undef,
};

my $sig = Dumper($$tp);		# save array signature
my $ary = Dumper(\@answers);		# save answer signature

## test 2 - 3	should be nop
my $vec = '';
do_thread($vec,'read');
gotexp(Dumper(\@answers),$ary);
gotexp(Dumper($$tp),$sig);

## test 4 - 5	should be nop
do_thread($vec,'write');
gotexp(Dumper(\@answers),$ary);
gotexp(Dumper($$tp),$sig);

sub setvec {
  my $rin = '';
  foreach(@_) {
    vec($rin,$_,1) = 1;
  }
  return $rin;
}

## test 6 - 7	try reads on all non-read vectors, should be nop
$vec = setvec(2,5);
do_thread($vec,'read');
gotexp(Dumper(\@answers),$ary);
gotexp(Dumper($$tp),$sig); 

## test 8 - 9	try writes on all non-write vectors, should be nop
$vec = setvec(1,5);
do_thread($vec,'write');
gotexp(Dumper(\@answers),$ary);
gotexp(Dumper($$tp),$sig); 

## test 10 - 11	try read on all except 3, should do one only
$vec = setvec(1,2,4,5);
my $exp = {
	DUMMY	=> {
		read	=> $reportr,
		write	=> $reportw,
	},
	1	=> {
		read	=> undef,
	},
	2	=> {
		write	=> $reportw,
	},
	3	=> {
		read	=> sub {
				my($key) = @_;
				delete ${$tp}->{4};
				&$reportr;
			   },
		write	=> $reportw,
	},
	4	=> {
		read	=> $reportr,
		write	=> $reportw,
	},
	5	=> undef,
};
my @exp = qw(r1);
$sig = Dumper($exp);
$ary = Dumper(\@exp);
do_thread($vec,'read',1);	# set sort
gotexp(Dumper(\@answers),$ary);
gotexp(Dumper($$tp),$sig);

## test 12 - 13	repeat with same vector, should do 4 only
$exp = {
	DUMMY	=> {
		read	=> $reportr,
		write	=> $reportw,
	},
	1	=> {
		read	=> undef,
	},
	2	=> {
		write	=> $reportw,
	},
	3	=> {
		read	=> sub {
				my($x,$key) = @_;
				delete ${$tp}->{4};
				&$reportr;
			   },
		write	=> $reportw,
	},
	4	=> {
		read	=> undef,
		write	=> $reportw,
	},
	5	=> undef,
};
@answers = ();
@exp = qw(r4);
$sig = Dumper($exp);
$ary = Dumper(\@exp);
do_thread($vec,'read',1);	# set sort
gotexp(Dumper(\@answers),$ary);
gotexp(Dumper($$tp),$sig);

## test 14 - 15	repeat, should be nop
@answers = ();
$ary = Dumper(\@answers);
do_thread($vec,'read');
gotexp(Dumper(\@answers),$ary);
gotexp(Dumper($$tp),$sig);

## test 16 - 17	check write 1,2,3,4,5 -- should do 2 only
$vec = setvec(1,2,3,4,5);
$exp = {
	DUMMY	=> {
		read	=> $reportr,
		write	=> $reportw,
	},
	1	=> {
		read	=> undef,
	},
	2	=> {
		write	=> undef ,
	},
	3	=> {
		read	=> sub {
				my($x,$key) = @_;
				delete ${$tp}->{4};
				&$reportr;
			   },
		write	=> $reportw,
	},
	4	=> {
		read	=> undef,
		write	=> $reportw,
	},
	5	=> undef,
};
@exp = qw(w2);
$sig = Dumper($exp);
$ary = Dumper(\@exp);
do_thread($vec,'write',1);	# set sort
gotexp(Dumper(\@answers),$ary);
gotexp(Dumper($$tp),$sig);

## test 18 - 19	repeat, should do 3 only
@answers = ();
@exp = qw(w3);
$exp->{3}->{write} = undef;
$sig = Dumper($exp);
$ary = Dumper(\@exp);
do_thread($vec,'write',1);	# set sort
gotexp(Dumper(\@answers),$ary);
gotexp(Dumper($$tp),$sig);

## test 20 - 21	do the thread delete, 3 is still in the vector
@answers = ();
@exp = qw(r3);
$exp = {
	DUMMY	=> {
		read	=> $reportr,
		write	=> $reportw,
	},
	1	=> {
		read	=> undef,
	},
	2	=> {
		write	=> undef ,
	},
	3	=> {
		read	=> undef,
		write	=> undef,
	},
	5	=> undef,
};
$sig = Dumper($exp);
$ary = Dumper(\@exp);
do_thread($vec,'read',1);	# set sort
gotexp(Dumper(\@answers),$ary);
gotexp(Dumper($$tp),$sig);

