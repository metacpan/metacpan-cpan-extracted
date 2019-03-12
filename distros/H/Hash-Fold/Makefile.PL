use 5.008000;
use strict;
use warnings;

use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval($ExtUtils::MakeMaker::VERSION);

sub eumm_ge ($$;$) {
    my ($version, $true, $false) = @_;
    return ($EUMM_VERSION >= $version) ? %$true : %{ $false || {} };
}

WriteMakefile(
    NAME             => 'Hash::Fold',
    AUTHOR           => q{chocolateboy <chocolate@cpan.org>},
    VERSION_FROM     => 'lib/Hash/Fold.pm',
    ABSTRACT_FROM    => 'lib/Hash/Fold.pm',
    PL_FILES         => {},
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
        'version'             => '0.77',
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
        'Test::Fatal' => 0,
    },
    PREREQ_PM             => {
        'Moo'             => 0,
        'Sub::Exporter'   => 0,
        'Types::Standard' => 0,
        'Throwable::Error' => 0,
    },
    eumm_ge(6.48, { MIN_PERL_VERSION => '5.8.0' }),
    eumm_ge(6.31, { LICENSE => 'artistic_2' }),
    eumm_ge(6.46, {
        META_MERGE => {
            resources => {
                repository => 'https://github.com/chocolateboy/Hash-Fold',
                bugtracker => 'https://github.com/chocolateboy/Hash-Fold/issues',
            },
        }
    }),
);
