#!/usr/bin/perl

use Distribution::Guess::BuildSystem;

my $dist = $ARGV[0];

my $dist_dir = unpack_dist( $dist );

unless( $dist_dir )
	{
	warn "Could not unpcak $dist\n";
	exit;
	}
	
#print "Unwrapped $dist to $dist_dir\n";

my $guesser = Distribution::Guess::BuildSystem->new( dist_dir => $dist_dir );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
if( $guesser->has_makefile_pl && ! $guesser->has_build_pl )
	{
	print "Found a Makefile.PL!\n";
	
	if( $guesser->uses_makemaker )
		{
		print "Uses MakeMaker!\n";
		}
	elsif( $guesser->uses_module_install )
		{
		print "Uses Module::Install!\n";
		print "Uses auto_install\n" if $guesser->uses_auto_install;
		}
	}
elsif( $guesser->has_makefile_pl && $guesser->has_build_pl )
	{
	print "Found a Makefile.PL and a Build.PL!\n";
	print "Build.PL wraps Makefile.PL!\n" if $guesser->build_pl_wraps_makefile_pl;

	if( $guesser->uses_makemaker )
		{
		print "Uses MakeMaker!\n";
		}
	elsif( $guesser->uses_module_install )
		{
		print "Uses Module::Install!\n";
		print "Uses auto_install\n" if $guesser->uses_auto_install;
		}

	print "Found a Build.PL!\n";
	
	print "Uses Module::Build!\n" if $guesser->uses_module_build;
	print "Uses Module::Build::Compat!\n" if $guesser->uses_module_build_compat;	
	}
elsif( $guesser->has_build_pl )
	{
	print "Found a Build.PL!\n";
	
	print "Uses Module::Build!\n" if $guesser->uses_module_build;
	print "Uses Module::Build::Compat!\n" if $guesser->uses_module_build_compat;
	}
else
	{
	print "Didn't see a Makefile.PL or a Build.PL!\n";
	}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
sub unpack_dist 
	{ 	
	require Archive::Extract;
	require File::Temp;

	my $dist = shift;
	
	( my $prefix = __PACKAGE__ ) =~ s/::/-/g;
	
	my $unpack_dir = eval { File::Temp::tempdir(
		$prefix . "-$$.XXXX",
		TMPDIR  => 1,
		CLEANUP => 1,
		) }; 

	my $extractor = eval { 
		Archive::Extract->new( archive => $dist ) 
		};
	if( defined $@ and $@ )
		{
		return;
		}
			
	my $rc = $extractor->extract( to => $unpack_dir );

	$extractor->extract_path;		
	}