package MegaDistro::DebMaker::CtrlFile;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(make_ctrlfile);

use lib '../MegaDistro';

use MegaDistro::Config;
use MegaDistro::DebMaker::Config qw(:default :build);


sub make_ctrlfile {
	if ( $args{'trace'} ) {
		print 'MegaDistro::DebMaker::make_ctrlfile : Executing sub-routine: make_ctrlfile' . "\n";
	}

	open( CTRLFILE, ">$buildtree{'CONTROL'}/control" ) || die "Cannot open: $!";
	print CTRLFILE 'Package: '      . $metadata{'name'}          . "\n";
	print CTRLFILE 'Version: '      . $metadata{'version'}	     .  '-'
					. $metadata{'release'}       . "\n";
	print CTRLFILE 'Section: '      . $metadata{'section'}       . "\n";
	print CTRLFILE 'Priority: '     . $metadata{'priority'}      . "\n";
	print CTRLFILE 'Depends: '      . $metadata{'depends'}       . "\n";
	print CTRLFILE 'Suggests: '     . $metadata{'suggests'}      . "\n";
	print CTRLFILE 'Replaces: '     . $metadata{'replaces'}      . "\n";
	print CTRLFILE 'Conflicts: '    . $metadata{'conflicts'}     . "\n";
	print CTRLFILE 'Maintainer: '   . $metadata{'maintainer'}    . "\n";
	print CTRLFILE 'Description: '  . $metadata{'description'}   . "\n";
	
	for (join("\n\ ",@{$section{'description'}})) {
		print CTRLFILE ' ' . $_ . "\n";
	}

	close( CTRLFILE );
	
	if ( $args{'debug'} ) {
		print "\t" . 'Control file successfully created - name is: ' . 'control' . "\n";
	}

}

1;
