use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME          => 'Geo::Coder::Multimap',
    AUTHOR        => 'gray <gray@cpan.org>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/Geo/Coder/Multimap.pm',
    ABSTRACT_FROM => 'lib/Geo/Coder/Multimap.pm',
    PREREQ_PM     => {
        'Encode'         => 0,
        'JSON'           => 2.0,
        'LWP::UserAgent' => 0,
        'Test::More'     => 0,
        'URI'            => 1.36,
    },
    META_MERGE    => {
        resources => {
            repository => 'http://github.com/gray/geo-coder-multimap',
        },
        recommends => {
            'JSON::XS' => 2.0,
        },
    },
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'Geo-Coder-Multimap-*' },
);

unless (eval { ExtUtils::MakeMaker->VERSION(6.46) }) {
    delete $conf{META_MERGE};
}

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
