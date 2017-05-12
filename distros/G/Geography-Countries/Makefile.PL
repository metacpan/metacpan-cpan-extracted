use ExtUtils::MakeMaker;

my %args = (
    NAME                 => 'Geography::Countries',
    VERSION_FROM         => 'lib/Geography/Countries.pm',
    ABSTRACT_FROM        => 'lib/Geography/Countries.pm',
    MIN_PERL_VERSION     =>  5.006,
    AUTHOR               => 'Abigail <geography-countries@abigail.be>',
    LICENSE		 => 'mit',
    META_MERGE           => {
        resources        => {
            repository   => 'git://github.com/Abigail/geography--countries.git',
        },
        keywords         => [qw [Geography Countries]],
    },
);

my %filter = (
    MIN_PERL_VERSION     => '6.48',
    LICENSE              => '6.48',
    META_MERGE           => '6.46',
    AUTHOR               => '6.07',
    ABSTRACT_FROM        => '6.07',
);


delete $args {$_} for grep {defined $filter {$_} &&
                            $ExtUtils::MakeMaker::VERSION lt $filter {$_}}
                            keys %args;


WriteMakefile %args;
