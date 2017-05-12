use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile1(
    META_MERGE => {
        resources => {
            repository => 'http://github.com/crenz/Mail-Audit-Attach',
        },
        recommends => {
                'Test::Pod::Coverage' => 1.04,
                'Test::Pod' => 1.14, #not a build prereq, dist can be built without it
        },
    },
    BUILD_REQUIRES => {
        'Test::More'  => 0,
    },

    NAME              => 'Mail::Audit::Attach',
    VERSION_FROM      => 'Attach.pm', # finds $VERSION
    PREREQ_PM         => {
        'Mail::Audit'  => 2,
        'MIME::Entity' => 5,
        'MIME::Head'   => 5,
        'Mail::Header' => 1,
        'MIME::Base64' => 0,        
    }, 
    ABSTRACT_FROM  => 'Attach.pm', # retrieve abstract from module
    AUTHOR         => 'Christian Renz <crenz@web42.com>',
    LICENSE        => 'perl',
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
