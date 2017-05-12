use 5.010000;
use ExtUtils::MakeMaker;

my %options = (
    NAME              => 'List::OrderBy',
    VERSION_FROM      => 'lib/List/OrderBy.pm',
    PREREQ_PM         => {
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/List/OrderBy.pm', # retrieve abstract from module
       AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),
    LIBS              => [''], # e.g., '-lm'
    DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	# Insert -I. if you add *.h files later:
    INC               => '',

    XSOPT             => '',

	# Un-comment this if you add C files to link with later:
    # OBJECT            => '$(O_FILES)', # link all the C files too

    LICENSE           => 'perl',
    'dist'            => {
      PREOP     => 'chmod 600 Makefile.PL',
      TARFLAGS	=> '--group=none --owner=bjoern -cvf',
      COMPRESS  => 'gzip -9',
    },
    clean => { FILES => [], },
);

WriteMakefile(%options);
