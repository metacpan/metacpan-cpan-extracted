package MegaDistro::RpmMaker::SpecFile;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(make_specfile);

use lib '../MegaDistro';

use MegaDistro::Config;
use MegaDistro::RpmMaker::Config qw(:default :build);


sub make_specfile {
	if ( $args{'trace'} ) {
		print 'MegaDistro::RpmMaker::SpecFile : Executing sub-routine: make_specfile' . "\n";
	}
	open( SPECFILE, ">$buildtree{'specfile'}" ) || die "Cannot open: $!";
	print SPECFILE 'Summary: '      . $metadata{'summary'}      . "\n";
	print SPECFILE 'Name: '         . $metadata{'name'}         . "\n";
	print SPECFILE 'Version: '      . $metadata{'version'}      . "\n";
	print SPECFILE 'Release: '      . $metadata{'release'}      . "\n";
	print SPECFILE 'License: '      . $metadata{'license'}      . "\n";
	print SPECFILE 'Group: '        . $metadata{'group'}        . "\n";
	print SPECFILE 'Source: '       . $metadata{'source'}       . "\n";
	print SPECFILE 'URL: '          . $metadata{'url'}          . "\n";
	print SPECFILE 'Requires: '     . $metadata{'requires'}     . "\n";
	print SPECFILE 'Obsoletes: '    . $metadata{'obsoletes'}    . "\n";
	print SPECFILE 'Conflicts: '    . $metadata{'conflicts'}    . "\n";
	print SPECFILE 'Vendor: '       . $metadata{'vendor'}       . "\n";
	print SPECFILE 'Packager: '     . $metadata{'packager'}     . "\n";
        print SPECFILE 'BuildArch: '    . $metadata{'buildarch'}    . "\n";
	print SPECFILE 'BuildRoot: '    . $metadata{'buildroot'}    . "\n";
	print SPECFILE 'AutoReqProv: '  . $metadata{'autoreqprov'}  . "\n";
	
	print SPECFILE "\n";
	
	print SPECFILE '%description' . "\n";
	for (join("\n",@{$stanza{'description'}})) {
		print SPECFILE $_ . "\n";
	}
	print SPECFILE "\n";
	
	print SPECFILE '%prep' . "\n";
	for (join("\n",@{$stanza{'prep'}})) {
		print SPECFILE $_ . "\n";
	}
	print SPECFILE "\n";
	
	print SPECFILE '%setup' . ' ' . $OPTS{'setup'} . "\n";
	for (join("\n",@{$stanza{'setup'}})) {
		print SPECFILE $_ . "\n";
	}
	print SPECFILE "\n";
	
	print SPECFILE '%files' . "\n";
	for (join("\n",@{$stanza{'files'}})) {
		print SPECFILE $_ . "\n";
	}
	print SPECFILE "\n";
	
	print SPECFILE '%install' . "\n";
	for (join("\n",@{$stanza{'install'}})) {
		print SPECFILE $_ . "\n";
	}
	print SPECFILE "\n";

	close( SPECFILE );
	
	if ( $args{'debug'} ) {
		print "\t" . 'Spec file successfully created - name is: ' . $SPECFILE . "\n";
	}

}

1;
