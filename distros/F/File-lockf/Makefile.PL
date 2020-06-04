use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'	=> 'File::lockf',
    'VERSION_FROM' => 'lockf.pm',
    'LIBS'	=> [''],
    'DEFINE'	=> '',
    'INC'	=> '',
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/pbhenson/File-Lockf.git',
                web => 'https://github.com/pbhenson/File-Lockf',
            },
        },
    },
);
