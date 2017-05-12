use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Mail::Field::Received',
    'VERSION_FROM' => 'Received.pm', # finds $VERSION
    'PREREQ_PM'    => {
                       'Mail::Field'       => 0,
                       'Test::More'        => 0,
                       'Test::Differences' => 0,
                      },
);
