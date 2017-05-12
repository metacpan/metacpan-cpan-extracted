use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'NAME' => 'Log::QnD',
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'ABSTRACT' => 'Log::QnD - Quick and dirty logging system',
               'PL_FILES' => {},
               'EXE_FILES' => [],
               'VERSION_FROM' => 'lib/Log/QnD.pm',
               'LICENSE' => 'perl',
               'PREREQ_PM' => {
                                'IO::Scalar' => 0,
                                'String::Util' => 0,
                                'Test' => 0,
                                'Class::PublicPrivate' => 0,
                                'JSON' => 0,
                                'File::ReadBackwards' => 0
                              }
             };


WriteMakefile(%$make_args);
