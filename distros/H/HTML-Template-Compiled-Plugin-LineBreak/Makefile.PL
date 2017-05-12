use 5.008006;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTML::Template::Compiled::Plugin::LineBreak',
    VERSION_FROM      => 'lib/HTML/Template/Compiled/Plugin/LineBreak.pm', # finds $VERSION
    PREREQ_PM         => { 'HTML::Template::Compiled' => '0.86' },
);
