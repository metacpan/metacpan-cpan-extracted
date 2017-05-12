use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'GPIB::hpserial',
    'VERSION_FROM' => 'hpserial.pm', # finds $VERSION
    'LIBS'	=> [''],   # e.g., '-lm' 
    'DEFINE'	=> '',     # e.g., '-DHAVE_SOMETHING' 
    'INC'	=> '',     # e.g., '-I/usr/include/other' 
    ($] ge '5.005') ? (
        'AUTHOR' => 'Jeff Mock (jeff@mock.com)',
        'ABSTRACT' => 'GPIB device control',
    ) : (),
);
