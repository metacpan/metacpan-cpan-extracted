use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Geo::Google',
    VERSION_FROM      => 'lib/Geo/Google.pm', # finds $VERSION
    PREREQ_PM         => {
Digest::MD5     => 0.0,
HTML::Entities  => 0.0,
JSON		=> 1.12,
LWP::Simple     => 0.0,
URI::Escape     => 0.0,
                         }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Geo/Google.pm', # retrieve abstract from module
       AUTHOR         => 'Allen Day E<lt>allenday@ucla.eduE<gt> ' .
				'(Initial through 0.2)\n' .
				'Revision 0.3 maintainer:\n  ' .
				'Michael Trowbridge E<lt>' .
				'michael.a.trowbridge@gmail.comE<gt>') : ()),
);
