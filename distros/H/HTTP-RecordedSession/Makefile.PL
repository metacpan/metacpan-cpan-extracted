use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'HTTP::RecordedSession',
    'VERSION_FROM' => 'RecordedSession.pm', # finds $VERSION
    'PREREQ_PM'    => { 'Storable' => 0, },
);
