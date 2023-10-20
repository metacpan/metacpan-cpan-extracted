use 5.008004;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Email::Address::Classify',
    VERSION_FROM     => 'lib/Email/Address/Classify.pm',
    ABSTRACT_FROM    => 'lib/Email/Address/Classify.pm',
    AUTHOR           => 'Kent Oyer <kent@mxguardian.net>',
    LICENSE          => 'GPL_3',
    MIN_PERL_VERSION => '5.008004',
    PREREQ_PM        => {
        'strict'   => 0,
        'warnings' => 0,
        'File::Basename' => 0,
    },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/mxguardian/Email-Address-Classify.git',
                web  => 'https://github.com/mxguardian/Email-Address-Classify',
            },
            bugtracker => {
                web => 'https://github.com/mxguardian/Email-Address-Classify/issues'
            },
            homepage   => 'https://github.com/mxguardian/Email-Address-Classify',
        },
    },
);