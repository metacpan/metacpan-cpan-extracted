use strict;
use ExtUtils::MakeMaker;

my $prereqs = {
    'Test::More'                => 0,
    'Params::Check'             => '0.20',
    'Module::Load::Conditional' => '0.66',
    'Locale::Maketext::Simple'  => 0,
    'File::Spec'                => 0,
    'File::Temp'                => 0,
    'ExtUtils::MakeMaker'       => 0,
};

WriteMakefile1(
    LICENSE => 'perl',
    META_MERGE => {
        resources => {
            repository => 'https://github.com/jib/ipc-cmd',
        },
    },

    NAME            => 'IPC::Cmd',
    VERSION_FROM    => 'lib/IPC/Cmd.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => $prereqs,
    INSTALLDIRS     => ( $] >= 5.009005 && $] < 5.012 ? 'perl' : 'site' ),
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
    ABSTRACT        => 'A cross platform way of running (interactive) commandline programs.'
);

sub WriteMakefile1 {  #Written by Alexandr Ciornii, version 0.21. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{BUILD_REQUIRES} and $eumm_version < 6.5503) {
        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM}={ %{$params{PREREQ_PM} || {}} , %{$params{BUILD_REQUIRES}} };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION} if $eumm_version < 6.48;
    delete $params{META_MERGE} if $eumm_version < 6.46;
    delete $params{META_ADD} if $eumm_version < 6.46;
    delete $params{LICENSE} if $eumm_version < 6.31;
    delete $params{AUTHOR} if $] < 5.005;
    delete $params{ABSTRACT_FROM} if $] < 5.005;
    delete $params{BINARY_LOCATION} if $] < 5.005;

    WriteMakefile(%params);
}
