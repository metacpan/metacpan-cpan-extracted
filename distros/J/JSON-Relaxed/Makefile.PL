use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'PL_FILES' => {},
               'NAME' => 'JSON::Relaxed',
               'PREREQ_PM' => {
                                'Test::Most' => '0.34'
                              },
               'ABSTRACT' => 'JSON::Relaxed -- An extension of JSON that allows for better human-readability.',
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'VERSION_FROM' => 'lib/JSON/Relaxed.pm',
               'EXE_FILES' => [],
               'LICENSE' => 'perl'
             };


WriteMakefile(%$make_args);
