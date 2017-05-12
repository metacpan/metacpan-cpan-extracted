use strict;
use ExtUtils::MakeMaker;

my $opt = {
    NAME                => 'Lingua::KO::Romanize::Hangul',
    VERSION_FROM        => 'lib/Lingua/KO/Romanize/Hangul.pm',
    PREREQ_PM           => {
        'Test::More'    => '0',
    },
};

my $mm = $ExtUtils::MakeMaker::VERSION;
$mm =~ s/[^\d\.]+//g;
$opt->{LICENSE} = 'perl' if ( $mm >= 6.3001 );

WriteMakefile( %$opt );
