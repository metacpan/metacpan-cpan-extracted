use ExtUtils::MakeMaker;

WriteMakefile1(
    NAME              => 'Geo::OGC::Service::WMTS',
    VERSION_FROM      => 'lib/Geo/OGC/Service/WMTS.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => { "Modern::Perl" => 0,
                           "Carp" => 0,
                           "File::Basename" => 0,
                           "File::Basename" => 0,
                           "Geo::OGC::Service" => 0.08,
                           "Geo::GDAL" => 0,
                           "Cwd" => 0,
                           "Math::Trig" => 0,
                           "HTTP::Date" => 0,
                           "Data::Dumper" => 0,
                           "XML::LibXML::PrettyPrint" => 0,
    },
    TEST_REQUIRES     => { "Plack::Test" => 0,
                           "XML::LibXML" => 0,
                           "XML::SemanticDiff" => 0,
                           "XML::LibXML::PrettyPrint" => 0,
                           "Plack::Builder" => 0,
                           "Geo::OGC::Service" => 0.12,
			   'File::ShareDir' => 0,
    },
    ABSTRACT_FROM     => 'lib/Geo/OGC/Service/WMTS.pm', # retrieve abstract from module
    AUTHOR            => 'Ari Jolma <ari.jolma at gmail.com>',
    MIN_PERL_VERSION  => '5.010000',
    LICENSE           => 'perl',
    META_MERGE        => {
        resources => {
            repository => 'git://github.com/ajolma/Geo-OGC-Service-WMTS.git',
        },
    }
);

sub WriteMakefile1 {  #Compatibility code for old versions of EU::MM. Written by Alexandr Ciornii, version 0.23. Added by eumm-upgrade.
    my %params=@_;
    my $eumm_version=$ExtUtils::MakeMaker::VERSION;
    $eumm_version=eval $eumm_version;
    die "EXTRA_META is deprecated" if exists $params{EXTRA_META};
    die "License not specified" if not exists $params{LICENSE};
    if ($params{AUTHOR} and ref($params{AUTHOR}) eq 'ARRAY' and $eumm_version < 6.5705) {
        $params{META_ADD}->{author}=$params{AUTHOR};
        $params{AUTHOR}=join(', ',@{$params{AUTHOR}});
    }
    if ($params{TEST_REQUIRES} and $eumm_version < 6.64) {
        $params{BUILD_REQUIRES}={ %{$params{BUILD_REQUIRES} || {}} , %{$params{TEST_REQUIRES}} };
        delete $params{TEST_REQUIRES};
    }
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
    
    WriteMakefile(%params);
}
