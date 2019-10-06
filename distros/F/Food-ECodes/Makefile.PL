use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME               => 'Food::ECodes',
    AUTHOR             => q{Mohammad S Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Food/ECodes.pm',
    ABSTRACT_FROM      => 'lib/Food/ECodes.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker'     => 0,
        'File::ShareDir::Install' => 0,
    },
    BUILD_REQUIRES   => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Moo'              => '2.000000',
        'namespace::clean' => '0.24',
        'XML::Simple'      => '2.20',
        'File::Share'      => '0.25',
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Food-ECodes-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Food::ECodes'           => { file => 'lib/Food/ECodes.pm'         , version => '0.18' },
            'Food::ECodes::Additive' => { file => 'lib/Food/ECodes/Additive.pm', version => '0.18' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Food-ECodes.git',
                web  => 'https://github.com/manwar/Food-ECodes',
            },
        }})
     : ()
    ),
);


package MY;
use File::ShareDir::Install 'postamble';
