#!/usr/bin/perl
#########################

use Test::More;
use Expect;

#########################
if (system("which gdb")) {
	plan skip_all => "no GDB found.";
	exit 0;
}

my @patients=("double", "long");

# It seems that ok() cannot be used in a loop.
# So I had to change the "ok" in the middle to "fail() if".
plan "tests" => 1 + @patients*6;

sub Diag {
	diag(@_);
} 

$Expect::Log_Stdout=0;
#         $Expect::Exp_Internal = 1;
# $Expect::Debug = 1;


#########################
ok(1, "start");

our $current_val;

sub slave_getvalue
{
	my($slave)=@_;

	$slave->print("\n");
	$slave->expect(1, 
			[ qr(^={5,} NEW VALUE: (\S+))m, sub 
				{ 
					my($self)=@_;
					# Allow the child to print an expression, so that the values to 
					# be found isn't left on the stack (for printf() or similar).
					#Diag("eval of ", (($self->matchlist())[0]));
					$current_val=eval(($self->matchlist())[0]); 
				} 
			]
		);
		#Diag("slave has ", $slave->before());
	$slave->clear_accum;

	return $current_val;
}



for my $patient (@patients)
{
	Diag("Going for $patient");

	my $slave=new Expect;
	$slave->raw_pty(1);
#	$slave->spawn("perl t/test-$patient.pl", ())
	$slave->spawn("t/test-$patient", ())
		or die "Cannot spawn test-$patient";

	$client = new Expect;
	$client->raw_pty(1);
	$client->spawn("PERLLIB=/home/marek/mine/perl/CPAN/Hack-Live-1/lib/ strace -tt -o /tmp/adsfga -s 200000 hack-live -p" . $slave->pid, ())
		or die "Cannot spawn Games::Hack::Live: $!\n";

# Testing here doesn't work. It seems that perl doesn't keep the scalar at 
# the same memory location, but moves it around. 
# Strangely that works if the perl script is run separately - does the 
# Test:: framework something like eval()?

	$client->print("\n\n");
	$client->expect(4, [ qr(^---), ] );
	#Diag("prequel: got \n", $client->before, "\n------------END OF PREQUEL");
	$client->clear_accum;



	my $loop_min=5;
	my $loop_max=17;
	my $wanted;
	my $adr;
	my $count;
	my @matches;
# Take a few values, then try to inhibit changes.
	for my $loop (1 .. $loop_max)
	{
		#Diag("loop $loop");
		slave_getvalue($slave);
		#Diag("c-v $current_val");
		last unless $current_val;

		# change last digit
		my $one_less = $current_val;
		$one_less =~ s/([1-9]0*)$/$1 - 1/e;
		my $one_more = $current_val;
		$one_more =~ s/([0-8]9*)$/$1 + 1/e;
		#Diag("got current value as $current_val -- $one_less $one_more\n");

		$client->print(
				$current_val =~ m#\.# ?
				"find ($patient) $one_less - $one_more\n" :
				"find ($patient) $current_val\n");
		$client->expect(4, [ qr(^--->) ], );

		my $last=$client->before;
		$client->clear_accum;
		#Diag("h-l said $last");
		($wanted)=($last =~ /Most wanted:\s+(\w.*)/);
		last unless $wanted;

		# we know that the address must be on a page boundary - so we can eliminate a few false positives.
		($adr, $count)=@matches=grep($_ !~ /^(0x0+)?0$/,$wanted =~ /(\w+000)\((\d+)\)/g);
#		print STDERR "$loop: $wanted\n==== has $current_val: ", 
#		join(" ", @matches),"\n", 0+@matches, $matches[1] > $matches[3],"\n";

# Stop testing if there's only a single match, or a single best match.
		$count //= 0;
		last if $adr && $count >= $loop_min;
	}

	ok($current_val>0, "Identifiable output");
	ok($wanted, "Got list of addresses");


	ok(@matches==2, 
			"matching addresses: 1 wanted; got " . scalar(@matches)/2);

	my $last=$client->before;
	$client->clear_accum;
	$adr //= 0;
	Diag("got address $adr, with $count matches.");
	ok($adr, "address found");
# we allow a single bad value.
	ok($count >= $loop_min, "Not enough matches found?");


	Diag("Trying to kill writes.\n");

	$client->print("killwrites $adr\n");
	$client->clear_accum;
	$client->expect(1, [ qr(--->), sub { } ], );

	slave_getvalue($slave);
	slave_getvalue($slave);
	$slave->clear_accum;

	$old=slave_getvalue($slave);
	$new=slave_getvalue($slave);

	#Diag("old was $old, new is $new");
	ok($old == $new ,"changed value ($old == $new)?");

	$slave->print("quit\n");
	$client->print("kill\n\n");
	$client->hard_close;
	$slave->hard_close;

	# Diag("$patient done\n");
}

exit;

