use 5.006001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
	'NAME'          => 'Log::Dispatch::File::Alerts',
	'VERSION_FROM'  => 'lib/Log/Dispatch/File/Alerts.pm', # finds $VERSION
	'PREREQ_PM'     => {
		'Log::Log4perl' => '0.32',
		'Log::Dispatch' => '2.37',
		'Test::More'	=> '1.001002',
#		'Pod::Readme'   => '0.05', # only needed for 'make dist'
	},
	($] >= 5.005 ? (   ## Add these new keywords supported since 5.005
		ABSTRACT_FROM   => 'lib/Log/Dispatch/File/Alerts.pm', # retrieve abstract from module
		AUTHOR          => 'M. Jacob <jacob@j-e-b.net>') : (),
		LICENSE         => 'perl',
		depend          => {
			create_distdir  => 'Changes',
			Changes         => 'lib/Log/Dispatch/File/Alerts.pm'."\n\t".q[$(FULLPERLRUN) -MPod::Readme -e 'Pod::Readme->new( readme_type => "changes" )->parse_from_file( "lib/Log/Dispatch/File/Alerts.pm", "Changes" )']."\n\n",
		},
		realclean       => {
			FILES           => "Changes"
		},
	),
);
