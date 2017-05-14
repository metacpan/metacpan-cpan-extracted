#!/usr/bin/perl

use strict;
use Carp;
use ExtUtils::MakeMaker;

# ########################################################################
# Environment variables
# ########################################################################
my $name 		= 'Math::Macopt';
my $author 		= 'Tom Chau';
my $version		= '0.03';

my $MACOPT_DIR 	= "macopt++";

&main();

sub main
{
	WriteMakefile(
		# General
		NAME 			=> $name,
		AUTHOR			=> $author,
		VERSION		 	=> $version,
		dist 			=> {
			SUFFIX		=> 'gz', 
			COMPRESS	=> 'gzip -f' 
		},
		clean	=> {
			FILES	=> "*~"
		},
		# Depends
		DIR	=> [
			'macopt++'
		],
		# Compilation and linking
		INC 		=> "-I$MACOPT_DIR",
		CCFLAGS		=> join(' ',
			"-v", 
			"-Dlinux", 
			"-DWL=32", 
			"-DFORTRANUNDERSCORE",
			"-DOPTIMIZE",
			"-fPIC", 
			`perl -MExtUtils::Embed -e ccopts`,
		),
		OBJECT 	=> "callperl.o base.o base_wrap.o $MACOPT_DIR/libmacopt.a",
		NEEDS_LINKING	=> 1,
		# C++ support
	 	CC		=> 'g++',
		LD		=> 'g++',
	 	XSOPT	=> '-C++',
	);
}

sub MY::test_via_harness
{
	my ($txt) = shift -> MM::test_via_harness (@_) ;
	$txt =~ s/PERL_DL_NONLAZY=1/PERL_DL_NONLAZY=0/ ;
	return $txt ;
}
sub MY::test_via_script
{
	my ($txt) = shift -> MM::test_via_script (@_) ;
	$txt =~ s/PERL_DL_NONLAZY=1/PERL_DL_NONLAZY=0/ ;
	return $txt ;
}

