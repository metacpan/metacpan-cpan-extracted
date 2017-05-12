use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'AUTHOR'    => 'Tsukui Akihiro (milano@cpan.org)',
    'NAME'	=> 'HDML::LinkExtor',
    'VERSION_FROM' => 'lib/HDML/LinkExtor.pm', # finds $VERSION
    'PREREQ_PM' => {
	HTML::LinkExtor => 0,
	HTML::Tagset => 0,
	URI => 0,
    }
);
