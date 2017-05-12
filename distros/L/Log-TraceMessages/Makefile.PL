use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	   => 'Log::TraceMessages',
    'VERSION_FROM' => 'TraceMessages.pm', # finds $VERSION
    'PREREQ_PM'    => { 'HTML::FromText' => '1.004' },
);
