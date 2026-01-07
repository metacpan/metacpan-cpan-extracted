
use 5.008;
use ExtUtils::MakeMaker;

my $EUMM_VERSION = $ExtUtils::MakeMaker::VERSION;
$EUMM_VERSION =~ tr/_//d;

my %write_makefile_args = (
    NAME         => 'Devel::Hide',
    VERSION_FROM => 'lib/Devel/Hide.pm',
    ABSTRACT_FROM => 'lib/Devel/Hide.pm',
    AUTHOR        => 'Adriano Ferreira <ferreira@cpan.org>',
    PREREQ_PM     => {
        'Test::More' => 0.82,
    },
    META_MERGE    => {
        license   => 'perl',
        resources => {
            repository => 'https://github.com/DrHyde/Devel-Hide',
            bugtracker => 'https://github.com/DrHyde/Devel-Hide/issues'
        },
    },
);

delete $write_makefile_args{LICENSE} if $EUMM_VERSION < 6.31;

delete $write_makefile_args{META_MERGE} if $EUMM_VERSION < 6.4501;

WriteMakefile(%write_makefile_args);

