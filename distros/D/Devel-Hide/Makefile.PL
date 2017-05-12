
use 5.006001;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = eval $ExtUtils::MakeMaker::VERSION;

WriteMakefile(
    NAME              => 'Devel::Hide',
    VERSION_FROM      => 'lib/Devel/Hide.pm', 
    PREREQ_PM         => {
        Test::More               => 0,
        ($] <= 5.008 ? (
            File::Temp           => 0
        ) : ())
    }, 
    ($] >= 5.005 ? (
       ABSTRACT_FROM  => 'lib/Devel/Hide.pm', 
       AUTHOR         => 'A. R. Ferreira <ferreira@cpan.org>',
    ) : ()),
    ($EUMM_VERSION >= 6.31 ? (
        LICENSE => 'perl',
    ) : ()),
    ($EUMM_VERSION >= 6.4501 ? (
        META_MERGE => {
            recommends => {
                # optional tests
                'Test::Pod'              => 1.18,
                'Test::Pod::Coverage'    => 1.04,
            },
            resources => {
                repository => 'https://github.com/aferreira/cpan-Devel-Hide',
            },
        },       
    ) : ()),
);

