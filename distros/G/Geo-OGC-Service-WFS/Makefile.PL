use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Geo::OGC::Service::WFS',
    VERSION_FROM      => 'lib/Geo/OGC/Service/WFS.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    MIN_PERL_VERSION  => '5.012000',
    PM                => { 'lib/Geo/OGC/Service/WFS.pm' => '$(INST_LIBDIR)/WFS.pm',
                           'lib/Geo/OGC/Service/Filter.pm' => '$(INST_LIBDIR)/Filter.pm',
    },
    PREREQ_PM         => { "Carp" => 0,
                           "File::Basename" => 0,
                           "Modern::Perl" => 0,
                           "Capture::Tiny" => 0,
                           "Clone" => 0,
                           "JSON" => 0,
                           "DBI" => 0,
                           "Geo::GDAL" => 2.01, # to use streaming objects
                           "HTTP::Date" => 0,
                           "File::MkTemp" => 0,
                           "Data::Dumper" => 0,
                           "XML::LibXML::PrettyPrint" => 0, # for debugging
                           "Geo::OGC::Service" => 0.09,
    },
    TEST_REQUIRES     => { "strict" => 0,
                           "warnings" => 0,
                           "Modern::Perl" => 0,
                           "Test::More" => 0,
                           "Plack::Test" => 0,
                           "HTTP::Request::Common" => 0,
                           "XML::LibXML" => 0,
                           "XML::SemanticDiff" => 0,
                           "XML::LibXML::PrettyPrint" => 0,
                           "DBI" => 0,
                           "DBD::Pg" => 0,
                           "Geo::OGC::Service" => 0.09,
    },
    ABSTRACT_FROM     => 'lib/Geo/OGC/Service/WFS.pm', # retrieve abstract from module
    AUTHOR            => 'Ari Jolma <ari.jolma at gmail.com>',
    LICENSE           => 'perl'
);
