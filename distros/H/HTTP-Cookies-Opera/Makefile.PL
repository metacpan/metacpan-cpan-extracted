use strict;
use warnings;
use ExtUtils::MakeMaker;

my %conf = (
    NAME          => 'HTTP::Cookies::Opera',
    AUTHOR        => 'gray <gray@cpan.org>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/HTTP/Cookies/Opera.pm',
    ABSTRACT_FROM => 'lib/HTTP/Cookies/Opera.pm',
    PREREQ_PM     => {
        'HTTP::Cookies' => 0,
        'parent'        => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0.82,
        'Time::Fake' => 0,
    },
    META_MERGE     => {
        resources => {
            repository => 'http://github.com/gray/http-cookies-opera',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'HTTP-Cookies-Opera-*' },
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
