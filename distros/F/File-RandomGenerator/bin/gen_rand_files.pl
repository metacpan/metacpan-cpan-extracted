#!/usr/bin/perl

# PODNAME:
# ABSTRACT:

###### PACKAGES ######

use Modern::Perl;
use Getopt::Long;
use File::RandomGenerator;

###### CONSTANTS ######
###### GLOBAL VARIABLES ######

use vars qw($Depth $Width $RootDir $Count $Unlink);

###### MAIN PROGRAM ######

parse_cmd_line();

my $frg = File::RandomGenerator->new( depth     => $Depth,
									  width     => $Width,
									  num_files => $Count,
									  root_dir  => $RootDir,
									  unlink    => $Unlink,
);
my $cnt = $frg->generate;

say "dir:       " . $frg->root_dir();
say "generated: $cnt files";
say "cleanup:   ", $Unlink ? "on" : "off";

###### END MAIN #######

sub check_required {
	my $opt = shift;
	my $arg = shift;

	print_usage("missing arg $opt") if !$arg;
}

sub parse_cmd_line {
	my $help;
	my $rc = GetOptions( "d=s"    => \$Depth,
						 "w=s"    => \$Width,
						 "c=s"    => \$Count,
						 "r=s"    => \$RootDir,
						 "unlink" => \$Unlink,
						 "help|?" => \$help
	);

	print_usage("usage:") if $help;

	#    check_required('-d', $Depth);

	if (!$Depth) {
		$Depth = File::RandomGenerator->DEPTH() ;
	}
	
	$Width   = File::RandomGenerator->WIDTH    if !$Width;
	$Count   = File::RandomGenerator->FILE_CNT if !$Count;
	$RootDir = File::RandomGenerator->ROOT_DIR if !$RootDir;

	if ($Unlink) {
		$Unlink = 1;
	}

	$Unlink = File::RandomGenerator->UNLINK if !defined $Unlink;

	if ( !($rc) || ( @ARGV != 0 ) ) {
		## if rc is false or args are left on line
		print_usage("parse_cmd_line failed");
	}
}

sub print_usage {
	print STDERR "@_\n";

	my $unlink = 'off';
	if ( FileRandomGenerator->UNLINK ) {
		$unlink = 'on';
	}

	print "\n$0\n"
		. "\t[-d <depth>]     (default "
		. File::RandomGenerator->DEPTH . ")\n"
		. "\t[-w <width]      (default "
		. File::RandomGenerator->WIDTH . ")\n"
		. "\t[-c <files cnt>] (default "
		. File::RandomGenerator->FILE_CNT . ")\n"
		. "\t[-r <root dir>]  (default "
		. File::RandomGenerator->ROOT_DIR . ")\n"
		. "\t[-unlink]        (default $unlink)\n"
		. "\t[-verbose]\n"
		. "\t[-?] (usage)\n" . "\n";

	exit 1;
}

