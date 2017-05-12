package MegaDistro::DebMaker::Build;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(have_deb build_deb);

use lib '../MegaDistro';

use MegaDistro::Config qw(:default $DEVNULL);
use MegaDistro::DebMaker::Config qw(:default :build);
use MegaDistro::DebMaker::CtrlFile qw(make_ctrlfile);


sub have_deb {
	`dpkg-deb --help > /dev/null 2>&1`;
	if ( $? == 0 ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub build_root {
	if ( $args{'trace'} ) {
		print 'MegaDistro::DebMaker::Build : Executing sub-routine: build_root' . "\n";
	}

	system( "cp -fR $Conf{'builddir'}/* $buildtree{'BUILDROOT'}" );

	# to satisfy woody dpkg-deb compat.
	system( "find $buildtree{'ROOT'} -type d | xargs chmod 755" );
	
}


sub build_deb {
	MegaDistro::DebMaker::Config::_init_globals();
	&build_pre;	#initialize the build directory tree
	&build_root;
	&make_ctrlfile;
	if ( $args{'trace'} ) {
		print 'MegaDistro::DebMaker::Build : Executing sub-routine: build_deb' . "\n";
	}

	my $addopts;
	if ( $args{'verbose'} ) {
		$addopts = '-v';
	}
	else {
		$addopts = '--quiet';
	}
	
	#check for ctrlfile, and package
	if ( -e "$buildtree{'CONTROL'}/control" ) {
		if ( !$args{'verbose'} ) {
			system( "dpkg-deb -b $buildtree{'ROOT'} > $DEVNULL" );
		}
		else {
			system( "dpkg-deb -b $buildtree{'ROOT'}" );
		}
	}
	else {
		die 'Control file not found!' . "\n";
	}

	my $DEB = $metadata{'name'} . '_' . $metadata{'version'} . '-' . $metadata{'release'} . '.deb';
	# rename the package appropriately (post-build)
	if ( -e "$Conf{'rootdir'}/$buildtree{'PACKAGE'}.deb" ) {
		system( "mv $Conf{'rootdir'}/$buildtree{'PACKAGE'}.deb $Conf{'rootdir'}/$DEB" );
		if ( $args{'debug'} ) {
			print "\t" . 'DEB successfully created - name is: ' . $DEB . "\n";
		}

	}
	else {
		die 'Error copying DEB!' . "\n";
	}
}

1;
