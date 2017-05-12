# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.
# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..18\n"; }
END {print "not ok 1\n" unless $loaded;}

#use diagnostics;
do './recurse2txt';     # get my Dumper

use Net::NBsocket qw(
        open_listenNB
	connect_NB
);
use Socket;

use Mail::SMTP::Honeypot;
*newthread = \&Mail::SMTP::Honeypot::newthread;
*writesock = \&Mail::SMTP::Honeypot::writesock;
*readsock = \&Mail::SMTP::Honeypot::readsock;

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
my $flag = 0;
my $xaddr = '';
my $returnX = sub { ($flag,$xaddr) = @_ };
eval {
	local $^W = 0;# no warnings;
	*Mail::SMTP::Honeypot::dns_send = $returnX;
};
my($server,$port);
my $testhost = 'test.host.com';
my $conf = {
	hostname	=> $testhost,
};
Mail::SMTP::Honeypot::check_config($conf);
my $ipaddr = '127.0.0.1';
foreach (10000..10100) {              # find a port to bind to
  if ($server = open_listenNB($_,inet_aton($ipaddr))) {
    $port = $_;
    last;
  }
}
## test 2	verify listen
print "could not open listner\nnot " unless $server;
&ok;

my $listner	= fileno($server);

my($tp) = Mail::SMTP::Honeypot::_trace();

$$tp = {
	$listner => {
		sock	=> $server,
		read	=> \&newthread,
	},
};

my $sig = Dumper($$tp);

&next_sec();

## test 3	attempt accept with no client
newthread($listner);
gotexp(Dumper($$tp),$sig);

## test 4	verify return branch
print "failed to detect missing accept socket\nnot "
	if $flag;
&ok;

## test 5	create, verify client
my $client	= connect_NB($port,inet_aton($ipaddr));

my $now = &next_sec();

print "could not open client\nnot " unless $client;
&ok;

my $wfileno = fileno($client);		# client fileno for later use

## test 6	connect and generate new thread, verify correct branch
newthread($listner);
print "failed to create connection\nnot "
	unless $xaddr eq $ipaddr;
&ok;

#######################################
### kill listner
#######################################
close $server;

## test 7	verify returned hash
my $fileno = $flag;				# flag contains fileno of new thread
my $expwarg = '220 '. $testhost . " service ready\r\n";
my $exp = {
	$listner	=> {
		sock	=> $server,
		read	=> sub {},
	},
	$fileno	=> {	# contains fileno for connection
		alarm	=> $now,
		cok	=> 0,
		cmdcnt	=> 0,
		domain	=> '',
		lastc	=> 'CONN',
		next	=> sub {},
		name	=> '',
		ipaddr	=> $ipaddr,
		sock	=> ${$tp}->{$fileno}->{sock} || 'failed',
		proto	=> 'SMTP',
		wargs	=> $expwarg,
	},
};
gotexp(Dumper($$tp),Dumper($exp));

#########################################################
####### test read/write operations
#########################################################

## test 8	write stuff
$flag = 0;
my $string = 'The quick brown fox jumped over the lazy dog';
${$tp}->{$wfileno} = {
		wargs	=> $string,
		woff	=> 0,
		sock	=> $client,
		next	=> $returnX,
};

writesock($wfileno);
$exp = {
	$listner	=> {
		sock	=> $server,
		read	=> sub {},
	},
	$fileno	=> {	# contains fileno for connection
		alarm	=> $now,
		cmdcnt	=> 0,
		cok	=> 0,
		domain	=> '',
		lastc	=> 'CONN',
		next	=> sub {},
		name	=> '',
		ipaddr	=> $ipaddr,
		sock	=> ${$tp}->{$fileno}->{sock} || 'failed',
		proto	=> 'SMTP',
		wargs	=> $expwarg,
	},
	$wfileno	=> {
		wargs	=> $string,
		woff	=> length($string),
		sock	=> $client,
		next	=> $returnX,
	},
};
gotexp(Dumper($$tp),Dumper($exp));

## test 9	return taken
gotexp($flag,$wfileno);

## test 10 - 11	read stuff back
$now = next_sec();
$flag = 0;
my $flag2 = 0;
my $sock = ${$tp}->{$fileno}->{sock};
${$tp}->{$fileno} = {
	sock	=> $sock,
	roff	=> 0,
	next	=> $returnX,
};
$exp->{$fileno} = {
	alarm	=> $now,
	sock	=> $sock,
	roff	=> length($string),
	rargs	=> $string,
	next	=> $returnX,
};

readsock($fileno);
gotexp(Dumper($$tp),Dumper($exp));
gotexp($flag,$fileno);

## test 12 - 13	reque read operation, empty try, would block -- sets retry
$flag = 0;
readsock($fileno);
$exp->{$fileno}->{read} = sub {};
gotexp(Dumper($$tp),Dumper($exp));
gotexp($flag,0);

## test 14	close the write filehandle
print "could not close write filehandle\nnot "
	unless close $client;
&ok;

## test 15 - 16	generate a write error - write to closed socket
delete $exp->{$wfileno};

&next_sec();

writesock($wfileno);

gotexp(Dumper($$tp),Dumper($exp));
gotexp($flag,0);

## test 17	generate a zero byte read error, remote has disconnected
${$tp}->{$fileno}->{roff} = 0;
delete $exp->{$fileno};
readsock($fileno);
gotexp(Dumper($$tp),Dumper($exp));

## test 18	check for closed read socket
print "did not close read socket\nnot "
	if close $sock;
&ok;
