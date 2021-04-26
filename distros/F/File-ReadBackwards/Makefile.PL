use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'File::ReadBackwards',
    'VERSION_FROM' => 'ReadBackwards.pm', # finds $VERSION

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            bugtracker => {
                web  => 'https://github.com/uperl/File-ReadBackwards/issues',
            },
            homepage => 'https://metacpan.org/pod/File::ReadBackwards',
            repository => {
                type => 'git',
                url  => 'https://github.com/uperl/File-ReadBackwards.git',
                web  => 'https://github.com/uperl/File-ReadBackwards',
            },
        },
    },

    clean => { FILES => 'File-ReadBackwards-*' },
);
