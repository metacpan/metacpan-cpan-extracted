use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	NAME              => 'Device::Serdisp',
	VERSION_FROM      => 'lib/Device/Serdisp.pm', # finds $VERSION
	PREREQ_PM         => {
		'GD'					=>	0,
	},
	($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Device/Serdisp.pm', # retrieve abstract from module
       AUTHOR         => 'Erik Wasser <erik.wasser@iquer.net>') : ()),
	LIBS              => ['-lserdisp -lusb -lgd'], # e.g., '-lm'
	DEFINE            => '', # e.g., '-DHAVE_SOMETHING'
	INC               => '', # e.g., '-I. -I/usr/include/other'
	# Un-comment this if you add C files to link with later:
	# OBJECT            => '$(O_FILES)', # link all the C files too
);
