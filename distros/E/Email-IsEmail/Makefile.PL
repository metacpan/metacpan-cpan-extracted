use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Email::IsEmail',
    AUTHOR           => q{Leandr Khaliullov <leandr@cpan.org>},
    VERSION_FROM     => 'lib/Email/IsEmail.pm',
    ABSTRACT_FROM    => 'lib/Email/IsEmail.pm',
    LICENSE          => 'BSD',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'          => '1.302052',
        'Test::Perl::Critic'  => '1.03',
        'Test::Pod'           => '1.51',
    },
    PREREQ_PM => {
        #'ABC'              => 1.6,
        #'Foo::Bar::Module' => 5.0401,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Email-IsEmail-*' },
    META_MERGE => {
        'meta-spec'     => { version => 2 },
        dynamic_config  => 0,
        resources       => {
            repository  => {
                type        => 'git',
                url         => 'https://github.com/khaliullov/perl-Email-IsEmail.git',
                web         => 'https://github.com/khaliullov/perl-Email-IsEmail',
            },
            homepage    => 'https://metacpan.org/module/Email-IsEmail',
            bugtracker  => {
                web         => "https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Email-IsEmail",
            },
        },
    },
);
