use ExtUtils::MakeMaker;
my ($make_args);

# WriteMakefile params
$make_args = {
               'ABSTRACT' => 'File::Misc -- handy file tools',
               'PREREQ_PM' => {
                                'File::chdir' => 0,
                                'File::Path' => 0,
                                'File::Copy' => 0,
                                'File::Compare' => 0,
                                'File::Find' => 0,
                                'String::Util' => '1.24',
                                'Test::Toolbox' => '0.2',
                                'Class::ISA' => 0,
                                'File::Copy::Recursive' => 0
                              },
               'AUTHOR' => 'Miko O\'Sullivan <miko@idocs.com>',
               'NAME' => 'File::Misc',
               'LICENSE' => 'perl',
               'PL_FILES' => {},
               'VERSION_FROM' => 'lib/File/Misc.pm',
               'EXE_FILES' => []
             };


WriteMakefile(%$make_args);
