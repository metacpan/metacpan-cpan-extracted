use 5.006;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = $ExtUtils::MakeMaker::VERSION;
$EUMM_VERSION =~ s/_//g;

WriteMakefile(
    NAME              => 'Exporter',
    VERSION_FROM      => 'lib/Exporter.pm',
    ($] > 5.011) ? () : ( INSTALLDIRS => 'perl' ), # CPAN sourced versions should now install to site
    PREREQ_PM         => {
	'Carp' => '1.05',
    },
    ( $] >= 5.005 ? ( ABSTRACT_FROM  => 'lib/Exporter.pm') : () ),
    ( $EUMM_VERSION >= 6.31 ? ( LICENSE => 'perl') : () ),
    dist             => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    META_MERGE  => {
        recommends => { 
            'Test::Pod' => 1.18, 
            'Test::Pod::Coverage' => 1.04 
        },
	resources => {
            license => 'http://dev.perl.org/licenses/',
            bugtracker => 'http://rt.perl.org/perlbug/',
            repository => 'http://perl5.git.perl.org/perl.git/tree/HEAD:/lib',
            MailingList => 'http://lists.perl.org/list/perl5-porters.html',
        },
    },
);
