
use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile1(
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            bugtracker => 'https://github.com/CpanelInc/p5-Mail-Pyzor/issues',
            repository => {
                type => 'git',
                url  => 'git://github.com/CpanelInc/p5-Mail-Pyzor.git',
                web  => 'https://github.com/CpanelInc/p5-Mail-Pyzor',
            },
        },
    },

    NAME          => 'Mail::Pyzor',
    VERSION_FROM  => 'lib/Mail/Pyzor.pm',      # finds \$VERSION
    AUTHOR        => 'cPanel, LLC (CPANEL)',
    ABSTRACT_FROM => 'lib/Mail/Pyzor.pm',
    LICENSE       => 'Apache 2.0',

    # For now we use 5.14’s /a modifier.
    MIN_PERL_VERSION => 5.014000,

    PREREQ_PM => {
        'parent'                   => 0,
        'Digest::SHA'              => 0,
        'Email::MIME'              => 0,
        'Email::MIME::ContentType' => 0,
        'Encode'                   => 0,
        'IO::SigGuard'             => 0.12,
        'IPC::Run'                 => 0,
        'HTML::Parser'             => 0,
        'X::Tiny'                  => 0,
    },

    TEST_REQUIRES => {
        'autodie'            => 0,
        'JSON'               => 0,
        'Test::Class'        => 0,
        'Test::More'         => 0,
        'Test::FailWarnings' => 0,
        'Test::Deep'         => 0,
        'Test::Exception'    => 0,
        'File::Slurp'        => 0,
        'Data::Dumper'       => 0,
        'File::Which'        => 0,
        'IO::Pty'            => 0,
    },
);

sub WriteMakefile1 {    #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 2. Added by eumm-upgrade.
    my %params       = @_;
    my $eumm_version = $ExtUtils::MakeMaker::VERSION;
    $eumm_version = eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ( $params{AUTHOR} and ref( $params{AUTHOR} ) eq 'ARRAY' and $eumm_version < 6.5705 ) {
        $params{META_ADD}->{author} = $params{AUTHOR};
        $params{AUTHOR} = join( ', ', @{ $params{AUTHOR} } );
    }
    if ( $params{TEST_REQUIRES} and $eumm_version < 6.64 ) {
        $params{BUILD_REQUIRES} = { %{ $params{BUILD_REQUIRES} || {} }, %{ $params{TEST_REQUIRES} } };
        delete $params{TEST_REQUIRES};
    }
    if ( $params{BUILD_REQUIRES} and $eumm_version < 6.5503 ) {

        #EUMM 6.5502 has problems with BUILD_REQUIRES
        $params{PREREQ_PM} = { %{ $params{PREREQ_PM} || {} }, %{ $params{BUILD_REQUIRES} } };
        delete $params{BUILD_REQUIRES};
    }
    delete $params{CONFIGURE_REQUIRES} if $eumm_version < 6.52;
    delete $params{MIN_PERL_VERSION}   if $eumm_version < 6.48;
    delete $params{META_MERGE}         if $eumm_version < 6.46;
    delete $params{META_ADD}           if $eumm_version < 6.46;
    delete $params{LICENSE}            if $eumm_version < 6.31;

    WriteMakefile(%params);
}

