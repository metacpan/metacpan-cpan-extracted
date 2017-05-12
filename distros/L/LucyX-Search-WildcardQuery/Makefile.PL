use strict;
use warnings;
use ExtUtils::MakeMaker;

my $MM_Version = $ExtUtils::MakeMaker::VERSION;

if ( $MM_Version =~ /_/ )    # dev version
{
    $MM_Version = eval $MM_Version;
    die $@ if ($@);
}

WriteMakefile(
    NAME          => 'LucyX::Search::WildcardQuery',
    AUTHOR        => q{Peter Karman <karman@cpan.org>},
    VERSION_FROM  => 'lib/LucyX/Search/WildcardQuery.pm',
    ABSTRACT_FROM => 'lib/LucyX/Search/WildcardQuery.pm',
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002
        ? ( 'LICENSE' => 'perl' )
        : () ),
    PL_FILES  => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Lucy'       => '0.001000',
        'Data::Dump' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'LucyX-Search-WildcardQuery-*' },
    ( $MM_Version >= 6.48 ? ( MIN_PERL_VERSION => '5.8.3' ) : () ),
    ( $MM_Version >= 6.31 ? ( LICENSE          => 'perl' )  : () ),
    (   $MM_Version <= 6.44 ? ()
        : ( META_MERGE => {
                resources => {
                    license => 'http://dev.perl.org/licenses/',
                    homepage =>
                        'https://github.com/karpet/lucyx-search-wildcardquery',
                    bugtracker =>
                        'http://rt.cpan.org/NoAuth/Bugs.html?Dist=LucyX-Search-WildcardQuery',
                    repository =>
                        'https://github.com/karpet/lucyx-search-wildcardquery',
                },
            }
        )
    ),

);
