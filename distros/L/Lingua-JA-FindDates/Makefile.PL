use strict;
use warnings;
use ExtUtils::MakeMaker;

# Module requires Perl 5.10 or above.

if ($] < 5.010) {
    exit;
}

my $repo = 'https://github.com/benkasminbullock/Lingua--JA--FindDates';
my $base = 'lib/Lingua/JA/FindDates';
#my $pm = "$base.pm";
my $pm = "lib/Lingua/JA/FindDates.pm";
my $pod = "$base.pod";

WriteMakefile (
    NAME => 'Lingua::JA::FindDates',
    VERSION_FROM => $pm,
    ABSTRACT_FROM => $pod,
    LICENSE => 'perl',
    AUTHOR => 'Ben Bullock <bkb@cpan.org>',
    EXE_FILES => [
        'script/subsjdate',
    ],
    META_MERGE => {
        resources => {
            repository => $repo,
            bugtracker => "$repo/issues",
        },
    },
    MIN_PERL_VERSION => '5.010001',
);
