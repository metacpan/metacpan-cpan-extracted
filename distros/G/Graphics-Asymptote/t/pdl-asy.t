#!perl

use Test::More tests => '7';
use strict;
use warnings;

# skip tests if no PDL
# test send_pdl stuff, specifically if it barfs on a non-piddle

SKIP:
{
	eval 'use PDL';
	skip('because PDL is required for PDL::Graphics::Asymptote', 7) if $@;
	
	use_ok( 'PDL::Graphics::Asymptote' );
	
	my $asy = PDL::Graphics::Asymptote->new;
	
	isa_ok($asy, 'PDL::Graphics::Asymptote');

	### Check diagnostic messages ###
	
	# test the parity check
	my $piddle = sequence(10);
	my $high_d = sequence(2,2,2);
	eval {$asy->send_pdl($piddle)};
	like($@, qr/I expected an even number/,
		'send_pdl checks for parity in the number of arguments');
	
	# test the type checking
	eval {$asy->send_pdl(asyvar => 'abcde')};
	like($@, qr/expecting a piddle but I got something else/,
		'send_pdl barfs on bad type');


	### Check what is sent ###


	# create the special file handle that will collect the output
	my $message;
	open (my $fh, '>', \$message);
	select $fh;

	# set verbosity to one
	$asy++;
	$asy->send_pdl(var => $piddle);						# shouldn't display the send results
	$asy++;
	$asy->send_pdl(var => $piddle);						# should display the send results
	$asy->send_pdl(var => $high_d);						# should properly send high-dimensional arrays
	$asy->set_verbosity;

	select STDOUT;
	close $fh;

	$message =~ s/^\*.+\n//;							# Get rid of the first
	$message =~ s/\n*\*.+\n+$//;						# and last lines, 
	my @chunks = split /\n\*.+\n\n\*.+\n/, $message;	# then split the message into chunks

	# Now let's examine the results
	# test a verbose = 1 variable send
	like($chunks[0], qr/pdl with dimensions 10 as var/,
		'verbosity = 1 => tells us its sending a piddle, but does not give contents');

	# test a verbose = 2 variable send
	chomp($chunks[1]);
	is($chunks[1], 'real [] var = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};',
		'verbosity = 2 => tell us the full, sent piddle');

	# test a verbose = 2 variable send
	chomp($chunks[2]);
	is($chunks[2], 'real [][][] var = { {  {0, 1},  {2, 3} }, {  {4, 5},  {6, 7} }};',
		'properly packages higher-dimensional arrays');
	
	
	### Check what is received ###
	# This needs work; in particular, rather than sleeping for 10s, the files
	# should be checked if they exist and are done being written.
	
#	$asy->send_pdl(test1 => sequence(10), test2 => sequence(10000),
#		test3 => sequence(500,500));
#	$asy->send( qq {
#		file test_file = output('test1.dat');
#		write(test_file, test1);
		
#		test_file = output('test2.dat');
#		write(test_file, test2);
		
#		test_file = output('test3.dat');
#		write(test_file, test3);
#	});
#	# give some time for everything to process
#	sleep 10;
#	# Finally, open up the resulting files and see if their contents match what
#	# we sent them.
#	use PDL::IO::Misc;
#	my $confirm1 = pdl(rcols('test1.dat'));
#	my $confirm2 = pdl(rcols('test2.dat'));
#	my $confirm3 = pdl(rcols('test3.dat'));
	
#	ok(sum($confirm1 - sequence(10)) == 0, '10 element piddle transfer');
#	ok(sum($confirm2 - sequence(10000)) == 0, '10,000 element piddle transfer');
#	ok(sum($confirm3 - sequence(500,500)) == 0, '500x500 element piddle transfer');
	
}
