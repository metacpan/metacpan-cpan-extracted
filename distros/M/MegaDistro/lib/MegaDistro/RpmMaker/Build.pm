package MegaDistro::RpmMaker::Build;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(have_rpm build_rpm);

use lib '../MegaDistro';

use MegaDistro::Config qw(:default $DEVNULL);
use MegaDistro::RpmMaker::Config qw(:default :build);
use MegaDistro::RpmMaker::SpecFile qw(make_specfile);

use File::Spec::Functions qw(:ALL);
use File::Find;
use Archive::Tar;

no warnings 'File::Find';

sub have_rpm {
	`rpmbuild --help > /dev/null 2>&1`;
	if ( $? == 0 ) {
		return 1;
	}
	else {
		return 0;
	}
}

sub make_macrosfile {
	open( MACROSFILE, ">$buildtree{'macrosfile'}" ) || die "Cannot open file: $!";
	print MACROSFILE '%_topdir'                           . "\t" . $buildtree{'prefixdir'}          . "\n";
	print MACROSFILE '%_sourcedir'                        . "\t" . '%{_topdir}/SOURCES'             . "\n";
	print MACROSFILE '%_specdir'                          . "\t" . '%{_topdir}/SPECS'               . "\n";
	print MACROSFILE '%_tmppath'                          . "\t" . '%{_topdir}/.tmp'                . "\n";
	print MACROSFILE '%_builddir'                         . "\t" . '%{_topdir}/BUILD'               . "\n";
	print MACROSFILE '%_buildroot'                        . "\t" . '%{_tmppath}/%{name}-%{version}' . "\n";
	print MACROSFILE '%_rpmdir'                           . "\t" . '%{_topdir}/RPMS'                . "\n";
	print MACROSFILE '%_srpmdir'                          . "\t" . '%{_topdir}/SRPMS'               . "\n";
	print MACROSFILE '%_rpmfilename'                      . "\t" . '%%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm' . "\n";
	print MACROSFILE '%_enable_debug_packages'            . "\t" . '0'                              . "\n";
	print MACROSFILE '%debug_package'                     . "\t" . '%{nil}'                         . "\n";
	print MACROSFILE '%_unpackaged_files_terminate_build' . "\t" . '0'                              . "\n";
	close( MACROSFILE );
}

sub make_rcfile {
	my $macrofiles = `rpm --showrc | grep 'macrofiles'`; chomp $macrofiles;
	open( RCFILE, ">$buildtree{'rcfile'}" ) || die "Cannot open file: $!";
#	print RCFILE 'include:'    . "\t\t" . '/usr/lib/rpm/rpmrc'     . "\n";
	print RCFILE $macrofiles   . ':'    . $buildtree{'macrosfile'} . "\n";
	close( RCFILE );
}

sub tarball_rpm {
	if ( $args{'trace'} ) {
		print 'MegaDistro::RpmMaker::Build : Executing sub-routine: tarball_rpm' . "\n";
	}
	#create src tarball
	my $TARBALL = $metadata{'name'} . '-' . $metadata{'version'} . '.tar.gz';

	my @files;
	find(sub{push@files,abs2rel($File::Find::name,$Conf{'builddir'})},$Conf{'builddir'});
	shift @files if !$files[0];
	chdir $Conf{'builddir'};
	my $tar = Archive::Tar->create_archive(catdir($buildtree{'SOURCES'},$TARBALL),9,@files);

#	#check for tarball and copy to SOURCES directory
#	if ( -s "$Conf{'rootdir'}/$TARBALL" ) {
#		system( "cp $Conf{'rootdir'}/$TARBALL $buildtree{'SOURCES'}/$TARBALL" );
#		if ( $args{'debug'} ) {
#			print "\t" . 'Tarball successfully created - name is: ' . $TARBALL . "\n";
#		}
#	}
#	else {
#		die 'Error copying tarball!' . "\n";
#	}
}


sub build_rpm {
	MegaDistro::RpmMaker::Config::_init_globals();
	&build_pre;	#initialize the build directory tree
	&tarball_rpm;
	&make_macrosfile;
	&make_rcfile;
	&make_specfile;
	if ( $args{'trace'} ) {
		print 'MegaDistro::RpmMaker::Build : Executing sub-routine: build_rpm' . "\n";
	}

	my $addopts;
	if ( $args{'verbose'} ) {
		$addopts = '-v';
	}
	else {
		$addopts = '--quiet';
	}
	
	#check for specfile, and package.
	if ( -e "$buildtree{'specfile'}" ) {
		if ( !$args{'verbose'} ) {
			system( "rpmbuild --rcfile $buildtree{'drcfile'}:$buildtree{'rcfile'} -bb $addopts $buildtree{'specfile'} > $DEVNULL" );
		}
		else {
			system( "rpmbuild --rcfile $buildtree{'drcfile'}:$buildtree{'rcfile'} -bb $addopts $buildtree{'specfile'}" );
		}
	}
	else {
		die 'SPEC file not found!' . "\n";
	}

	my $RPM = $metadata{'name'} . '-' . $metadata{'version'} . '-' . $metadata{'release'} . '.' . $metadata{'buildarch'} . '.rpm';
	#copy the package, to $Conf{'rootdir'}
	if ( -e "$buildtree{'RPMS'}/$RPM" ) {
		system( "cp $buildtree{'RPMS'}/$RPM $Conf{'rootdir'}/$RPM" );
		if ( $args{'debug'} ) {
			print "\t" . 'RPM successfully created - name is: ' . $RPM . "\n"; #make this return?
											   #(output from caller)
		}

	}
	else {
		die 'Error copying RPM!' . "\n";
	}
}

1;
