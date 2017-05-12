use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'NAME' => 'Debug::ShowStuff',
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'ABSTRACT' => 'Debug::ShowStuff - A collection of handy debugging routines for displaying the values of variables with a minimum of coding.',
               'PL_FILES' => {},
               'EXE_FILES' => [],
               'VERSION_FROM' => 'lib/Debug/ShowStuff.pm',
               'LICENSE' => 'perl',
               'PREREQ_PM' => {
                                'Text::TabularDisplay' => 0,
                                'Scalar::Util' => 0,
                                'Devel::StackTrace' => 0,
                                'String::Util' => 0,
                                'Tie::IxHash' => 0,
                                'Class::ISA' => 0,
                                'Term::ReadKey' => 0
                              }
             };


WriteMakefile(%$make_args);
