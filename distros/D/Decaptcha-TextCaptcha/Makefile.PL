use strict;
use warnings;

# MIN_PERL_VERSION needs 6.48, and CONFIGURE_REQUIRES needs 6.52.
use ExtUtils::MakeMaker 6.52;

my %conf = (
    NAME               => 'Decaptcha::TextCaptcha',
    AUTHOR             => 'gray <gray@cpan.org>',
    LICENSE            => 'perl',
    VERSION_FROM       => 'lib/Decaptcha/TextCaptcha.pm',
    ABSTRACT_FROM      => 'lib/Decaptcha/TextCaptcha.pm',
    CONFIGURE_REQUIRES => { 'ExtUtils::MakeMaker' => 6.52, },
    PREREQ_PM          => { 'Lingua::EN::Words2Nums' => 0 },
    MIN_PERL_VERSION   => '5.010',
    BUILD_REQUIRES     => { 'Test::More' => 0.98, },
    META_MERGE         => {
        resources => {
            repository => 'https://github.com/gray/decaptcha-textcaptcha',
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'Decaptcha-TextCaptcha-*' },
);

my $eumm_version =  do {
    no warnings 'numeric';
    eval $ExtUtils::MakeMaker::VERSION;
};
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
