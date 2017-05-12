use utf8;
use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my %deps = (
    'Test::More'            => 0,
    'Hash::Merge'           => 0,
    'YAML::Syck'            => 0,
    'Class::Accessor::Fast' => 0,
    # 'WWW::Plurk'            => 0,
    # 'Net::Jaiku'            => 0,
    'Net::Twitter'          => 0,
    'Class::Accessor::Fast' => 0,
    'Text::Table'           => 0,
    'Number::RecordLocator' => 0,
    'Term::ReadLine'        => 0,
    'App::Cache'            => 0,
    'Data::Dumper::Simple'  => 0,
);

if ( $^O =~ m/darwin/i ) {
    $deps{'Mac::Glue'}  = '1.30';
    $deps{'Mac::Growl'} = '0.67';
} elsif ( $^O =~ m/linux/i )  {
    $deps{'Desktop::Notify'} = '0';
}


WriteMakefile(
    NAME             => 'Jaipo',
    AUTHOR           => q{BlueT - Matthew Lien - 練喆明 <BlueT@BlueT.org>},
    VERSION_FROM     => 'lib/Jaipo.pm',
    ABSTRACT_FROM    => 'lib/Jaipo.pm',
    LICENSE          => 'artistic_2',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => \%deps,
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Jaipo-*' },
    ($ExtUtils::MakeMaker::VERSION < 6.46 ? () : (
        META_MERGE => {
            resources => {
                bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Jaipo',
                repository => 'https://github.com/BlueT/jaipo'
            },
        })
    ),
    EXE_FILES    => [ qw(bin/jaipo) ],
);
