package MegaDistro::RpmMaker::Config;

use strict;
use warnings;

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(%buildtree $SPECFILE);
our @EXPORT_OK = qw( %metadata %stanza %OPTS build_pre );
our %EXPORT_TAGS;
$EXPORT_TAGS{'default'} = \@EXPORT;
$EXPORT_TAGS{'build'} = \@EXPORT_OK;
	
use lib '../MegaDistro';

use File::Path;
use File::Spec::Functions qw(:ALL);

use MegaDistro;
use MegaDistro::Config;

# hash to contain the various directories needed for building the rpm, on the system
our %buildtree;

#
# Package-specific configurables
#

# the package metadata (headers)
our %metadata = (
		  # the package Summary
		  'summary'	=>	'A pre-compiled set of perl modules',
		 
		  # the package Name
		  'name'	=>	'megadistro',	
		 
		  # the package Version
		  'version'	=>	$MegaDistro::VERSION,		
		 
		  # the package Release number
		  'release'	=>	'5',
		 
		  # the package License
		  'license'	=>	'GPL',		
		 
		  # the package Group
		  'group'	=>	'Development/Libraries',
		 
		  # the package Source location
		  'source'	=>	'http://search.cpan.org/CPAN/authors/id/D/DB/DBUCHMAN/megadistro-0.02.tar.gz',
		 
		  # the package URL
		  'url'		=>	'http://search.cpan.org/~dbuchman/MegaDistro-0.02/',
		 
		  # the package Requires (depends)
		  'requires'	  =>	'perl >= 5.6.1',
		 		 
		  # the package Obsolets (replaces)
		  'obsoletes'	  =>	'megadistro < ' . $MegaDistro::VERSION,
		  
		  # the package Conflicts
		  'conflicts'     =>    'megadistro < ' . $MegaDistro::VERSION,
		 
		  # the package Vendor
		  'vendor'	=>	'Perl MegaDistro',
		 
		  # the package Packager
		  'packager'	=>	'David Buchman',
		 
		  # the package BuildRoot (virtual root, build directory)
		  'buildroot'	=>	'%{_tmppath}/%{name}-%{version}-%{release}',
		  
		  # allow rpm to automatically set dependencies
		  'autoreqprov'   =>    'no',
		 					
	       );

# hash to contain various stanzas
our %stanza;

# option lines (params), for each given stanza
our %OPTS;

# the %description stanza
$stanza{'description'} = [
		    	   'The perl MegaDistro is a distributable binary, which contains a selection of pre-compiled modules.',
		  	 ];

# the %prep stanza
$stanza{'prep'} = [
	            '',
	   	  ];
	   
# the %setup stanza
$OPTS{'setup'} = '-q -c';
$stanza{'setup'} = [
	             '',
	    	   ];

# the %files stanza
$stanza{'files'} = [
	             '%defattr(-,root,root)',
		     '/',
	    	   ];

# the %install stanza
$stanza{'install'} = [ 
		       'rm -rf %{buildroot}',
		       'mkdir -p %{buildroot}',
		       'find %{_builddir} -type f -name .packlist -exec rm -f {} \';\'',
		       'find %{_builddir} -type f -name perllocal.pod -exec rm -f {} \';\'',
		       'cp -R %{_builddir}/%{name}-%{version}/usr %{buildroot}',
	      	     ];


sub _init_globals { #hack a la megadistro

	# rpmbuild-tree prefix
	$buildtree{'prefixdir'}  = catdir($Conf{'rootdir'}, 'rpmbuild');

	# SOURCES directory
	$buildtree{'SOURCES'}    = catdir($buildtree{'prefixdir'}, 'SOURCES');

	# BUILD directory
	$buildtree{'BUILD'}      = catdir($buildtree{'prefixdir'}, 'BUILD');

	# RPMS directory
	$buildtree{'RPMS'}       = catdir($buildtree{'prefixdir'}, 'RPMS');

	# SRPMS directory
	$buildtree{'SRPMS'}      = catdir($buildtree{'prefixdir'}, 'SRPMS');
	
	# SPECS directory
	$buildtree{'SPECS'}      = catdir($buildtree{'prefixdir'}, 'SPECS');

	# the name of the rpm spec file
	$buildtree{'specfile'}   = catdir($buildtree{'SPECS'}, 'megadistro.spec');
	
	# the name of the rpm rc file
	$buildtree{'rcfile'}     = $buildtree{'prefixdir'} . '/' . '.rpmrc';

	# the name of the default rcfile
	$buildtree{'drcfile'}    = '/usr/lib/rpm/rpmrc';
	
	# the name of the rpm macros file
	$buildtree{'macrosfile'} = $buildtree{'prefixdir'} . '/' . '.rpmmacros';
	
	# the package BuildArch hardware platform
	$metadata{'buildarch'}   = `rpm --eval %{_build_arch} 2>&1`; chomp $metadata{'buildarch'};
}

#
# Preparation
#
sub build_pre {
	if ( $args{'trace'} ) {
		print 'MegaDistro::SpecFile::Config : Executing sub-routine: build_pre' . "\n";
	}
	
	mkpath $buildtree{'SOURCES'} if ! -d $buildtree{'SOURCES'};
	mkpath $buildtree{'BUILD'}   if ! -d $buildtree{'BUILD'};
	mkpath $buildtree{'RPMS'}    if ! -d $buildtree{'RPMS'};
	mkpath $buildtree{'SRPMS'}   if ! -d $buildtree{'SRPMS'};
	mkpath $buildtree{'SPECS'}   if ! -d $buildtree{'SPECS'};
}

1;
