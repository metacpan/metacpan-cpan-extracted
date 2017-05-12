use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME           => 'Geo::Distance::XS',
    AUTHOR         => 'gray <gray@cpan.org>',
    LICENSE        => 'perl',
    VERSION_FROM   => 'lib/Geo/Distance/XS.pm',
    ABSTRACT_FROM  => 'lib/Geo/Distance/XS.pm',
    LIBS           => ['-lm'],
    BUILD_REQUIRES => { 'Test::More' => 0.82, },
    PREREQ_PM      => {
        'Geo::Distance' => 0.16,
        XSLoader        => 0,
    },
    META_MERGE     => {
        resources => {
            repository => 'http://github.com/gray/geo-distance-xs',
        }
    },
    dist           => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean          => { FILES => 'Geo-Distance-XS-*' },
);

my $eumm_version =  do {
    no warnings 'numeric';
    eval $ExtUtils::MakeMaker::VERSION;
};
delete $conf{META_MERGE} if $eumm_version < 6.46;
$conf{PREREQ_PM} = {
    %{ $conf{PREREQ_PM} || {} }, %{ delete $conf{BUILD_REQUIRES} },
} if ($conf{BUILD_REQUIRES} and $eumm_version < 6.5503);

WriteMakefile(%conf);


sub MY::postamble {
    return <<"    MAKE_FRAG";
authortest:
\t\$(MAKE) -e \$(TEST_TYPE) TEST_FILES="xt/*.t"
    MAKE_FRAG
}

sub MY::dist_test {
    my $self = shift;
    return $self->MM::dist_test . <<"    MAKE_FRAG";
\tcd \$(DISTVNAME) && \$(MAKE) authortest \$(PASTHRU)
    MAKE_FRAG
}
