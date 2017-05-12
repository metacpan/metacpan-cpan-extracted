use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Inline::WebChat',
    'VERSION_FROM'	=> 'WebChat.pm', # finds $VERSION
    'PREREQ_PM'		=> {
				WWW::Chat::Processor => 0.62,
				Inline    => 0.1,
			    }, # e.g., Module::Name => 1.1
);
