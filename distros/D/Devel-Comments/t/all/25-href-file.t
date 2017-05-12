#!/run/bin/perl

use strict;
use warnings;
use feature 'say';
use Carp;

use lib qw{
	      lib
	   ../lib
	../../lib
	      run/t
	   ../run/t
	../../run/t
};

use Test::More 0.94;
use Test::Deep;
use Try::Tiny;

use IO::Capture::Stdout::Extended;
use IO::Capture::Stderr::Extended;
use IO::Capture::Sayfix;
use IO::Capture::Tellfix;

# Make S::C::Any print to a file 
# with the filename passed in the use line inside a href

# passed to done_testing() after all subtests are run
my $test_counter	= 0;

# temp for actual calls to Test::More, Test::Deep, and friends
my $regex			;
my $got				;
my $expected		;
my $subname			;

# setup Test::Hump-ish
my $name			= 'dc-href-file';

my $self	= {
	
	
	};

$self->{-capture}{-stdout}	= IO::Capture::Stdout::Extended->new();
$self->{-capture}{-stderr}	= IO::Capture::Stderr::Extended->new();

BEGIN { $::out_filename		= '/home/xiong/projects/comments/file/test.log' }

# execute code within Test::Hump-ish box
$self->{-capture}{-stdout}->start();		# STDOUT captured
$self->{-capture}{-stderr}->start();		# STDERR captured
{
	try {
		use Devel::Comments ({ -file => $::out_filename });
		### foobar
		no Devel::Comments;
		### foobar
	}
	catch {
		$self->{-got}{-evalerr}	= $_;
	};
	
}
$self->{-capture}{-stdout}->stop();			# not captured
$self->{-capture}{-stderr}->stop();			# not captured

# Test for and report any eval error
$subname		= join q{}, $name, q{-evalerr};
$test_counter++;
ok( !$self->{-got}{-evalerr}, $subname );
diag("Eval error: $self->{-got}{-evalerr}") if $self->{-got}{-evalerr};

# define Test::Hump-ish subtests
my $do_cap_string	= sub {				# exact string eq STD*
	my $stdwhat		= shift;			# '-stdout' or '-stderr'
	$got			= $self->{-got}{$stdwhat}{-string}
					= join q{}, $self->{-capture}{$stdwhat}->read;
	$expected		= $self->{-want}{$stdwhat}{-string};
	$subname		= join q{}, $name, $stdwhat, q{-string};
	$test_counter++;
	is( $got, $expected, $subname );
};
	

# do subtests
my $subwhat			;

$subwhat			= q{-stdout};
$self->{-want}{$subwhat}{-string}	
	= q{};			# exactly empty, thank you

&$do_cap_string($subwhat);

$subwhat			= q{-stderr};
$self->{-want}{$subwhat}{-string}	
	= q{};			# exactly empty, thank you

&$do_cap_string($subwhat);

# now test the temp file contents
#~ say '.t: $::out_filename: ', $::out_filename;
open my $outfh, '<', $::out_filename
	or die 'Failed to open temporary test file for reading. ', $!;

my $prev_fh			= select $outfh;
local $/			= undef;			# slurp
select $prev_fh;

$got				= <$outfh>;

#~ print ">$got<\n";

$expected	
	= q{### foobar}	. qq{\n}
	;

$subname		= join q{}, $name, q{-tmpfile}, q{-string};
	$test_counter++;
	is( $got, $expected, $subname );
	



#$subwhat			= q{-stderr};

#&$do_cap_string($subwhat);




#	# character-by-character testing
#	my $obtained	= $self->{-got}{$subwhat}{-string};
#	my $want		= $self->{-want}{$subwhat}{-string};
#	my $length		= length $want;
#	foreach my $i (0..$length) {
#		$got			= substr $obtained, $i, 1;
#		$expected		= substr $want,     $i, 1;
#		$subname		= join q{}, $name, $subwhat, , q{-}, $i;
#		$test_counter++;
#		is( $got, $expected, $subname );
#	};


done_testing($test_counter);



