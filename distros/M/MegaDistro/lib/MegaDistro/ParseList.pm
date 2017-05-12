package MegaDistro::ParseList;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(get_modlist);

use lib './MegaDistro';

use MegaDistro::Config;


sub get_modlist {
	my $modlist = $Conf{'modlist'};

	if ( $args{'trace'} ) {
		print 'MegaDistro::ParseList : Executing sub-routine: get_modlist' . "\n";
	}
	
	if ( $modlist ) {
	        if ( ! -e "$modlist" ) {
			die "\n" . "Module list " . $modlist . " does not exist!" . "\n";
		}
		elsif ( ! -s "$modlist" ) {
			die "\n" . "Module list " . $modlist . " is empty!" . "\n";
		}
	}
	open( MODLIST, "<$modlist" ) || die "Cannot open $modlist: $!";
	my @FILE = <MODLIST>;
	close( MODLIST );
	my @modlist;
	for (@FILE) {
		my $line = $_;
		chomp($line);
		next if $line=~ /^\#/;
		next if $line=~ /^\s*$/;
		push @modlist, $line;
	}
	if ( ! scalar @modlist ) {
		die "\n" . "Module list empty -- nothing to do." . "\n";
	}
	else {
		if ( $args{'debug'} ) {
			print "\t" . 'Successfully read in module list - Contains: ' . scalar @modlist . ' modules' . "\n";
		}
	}

	return @modlist;
}

1;
