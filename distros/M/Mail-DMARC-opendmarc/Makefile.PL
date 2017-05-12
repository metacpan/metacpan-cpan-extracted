use 5.010000;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

require ExtUtils::Liblist;

install_share 'share';


# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Mail::DMARC::opendmarc',
    VERSION_FROM      => 'lib/Mail/DMARC/opendmarc.pm', # finds $VERSION
    BUILD_REQUIRES	  => {
				'File::ShareDir::Install' => 0
				},
    PREREQ_PM         => {
				'File::ShareDir' => 0
				}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Mail/DMARC/opendmarc.pm', # retrieve abstract from module
       AUTHOR         => 'Davide Migliavacca <shari@cpan.org>') : ()),
    LIBS              => ['-lresolv -lopendmarc'], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
    INC               => '-I', # e.g., '-I. -I/usr/include/other'
	TYPEMAPS		  => ['typemap'],
	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too
	META_MERGE		  => {
				release_status => 'unstable',
				license =>  ['artistic_2']
				}
);

package MY;
use File::ShareDir::Install qw(postamble);

