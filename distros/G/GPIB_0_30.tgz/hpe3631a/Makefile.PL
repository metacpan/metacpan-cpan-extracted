use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'GPIB::hpe3631a',
    'VERSION_FROM' => 'hpe3631a.pm', # finds $VERSION
    ($] ge '5.005') ? (
        'AUTHOR' => 'Jeff Mock (jeff@mock.com)',
        'ABSTRACT' => 'GPIB device control',
    ) : (),
);
