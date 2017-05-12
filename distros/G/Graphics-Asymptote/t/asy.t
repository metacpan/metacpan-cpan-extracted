#!perl

use Test::More tests => 17;
use strict;
use warnings;

use Graphics::Asymptote;

# The constructor wants key/value pairs in the argument list:
my $asy;
eval {$asy = Graphics::Asymptote->new(10)};
like($@, qr/Creating an Asymptote pipe requires/,
	'Constructor checks the number of arguments');

$asy = Graphics::Asymptote->new;

isa_ok($asy, 'Graphics::Asymptote');

# The tests are structured thus:
# 1) test verbosity increment, decrement, etc
# 2) test the output at various verbosity levels

### Setting Verbosity ###

ok($asy->get_verbosity() == 0, 'default verbosity should be zero');

# verbosity increment
$asy++;
ok($asy->get_verbosity() == 1, 'increment should increase verbosity by 1');

# verbosity set with argument
$asy->set_verbosity(6);
ok($asy->get_verbosity() == 6, 'set verbosity should set it to what I say');

# check set_verbosity with bad arguments:
eval {$asy->set_verbosity(-10)};
like($@, qr/set asymptote verbosity to anything but/,
	'set verbosity chokes on negative numbers');
eval {$asy->set_verbosity(13.2)};
like($@, qr/set asymptote verbosity to anything but/,
	'set verbosity chokes on fractions numbers');
eval {$asy->set_verbosity('blah!')};
like($@, qr/set asymptote verbosity to anything but/,
	'set verbosity chokes on non-numeric strings');

# decrement
$asy--;
is($asy->get_verbosity(), 5, 'decrement should decrease verbosity by 1');

# set_verbosity without any arguments
$asy->set_verbosity;
is($asy->get_verbosity(), 0,
	'set_verbosity without any arguments should set it to zero');

# decrement when at zero
$asy--;
is($asy->get_verbosity(), 0, 'decrement should not push verbosity below zero');

# Check the initialization option:
# Check that bad initializations don't work
eval {$asy = Graphics::Asymptote->new(verbose => 'blah!')};
like($@, qr/set asymptote verbosity to anything but/,
	'creation chokes on bad verbosity');

# Check that valid initializations do work
$asy = Graphics::Asymptote->new(verbose => 3);
is($asy->get_verbosity(), 3, 'initialization of verbosity should work');
$asy->set_verbosity();


### Test what send sends ###

# I do this by overriding the default filehandle using select, and redirecting
# it to a filehandle that points to a scalar.  For some reason, not clear to me,
# even if you set that scalar equal to '' after it's been written to, if you
# write to it again, it gets filled with almost the entire original expression.
# Weird.  So, I instead parse the output of one long run.

# set verbosity to one
$asy++;

# create the special file handle
my $message;
open (my $fh, '>', \$message);

# Send a whole bunch of stuff to Asymptote and collect the verbose output.
select $fh;

$asy->send('// asymptote comment');							# send should work
$asy->send('// asymptote comment # a comment');				# Perlish comments should be weeded out
$asy->send('// asymptote comment #a non-Perlish comment');	# Not-quite-Perlish comments should be let through
$asy->size(100);											# Check that on-the-fly function creation works
$asy->set_verbosity;

select STDOUT;
close $fh;

$message =~ s/^\*.+\n//;							# Get rid of the first
$message =~ s/\n*\*.+\n+$//;						# and last lines, 
my @chunks = split /\n\*.+\n\n\*.+\n/, $message;	# then split the message into chunks

# Now let's examine the results
like($chunks[0], qr'// asymptote comment',
	'with increased verbosity, send should tell us what is being sent');

# test a Perlish comment
unlike($chunks[1], qr/# a comment/,
	'send should filter out Perlish comments');

# test a non-Perlish but similar set of characters
like($chunks[2], qr/#a non-Perlish comment/,
	'send should not filter out non-Perlish comments');

# Test on-the-fly function creation
like($chunks[3], qr/size\(100\);/,
	'AUTOLOAD should properly create functions on-the-fly');

