use ExtUtils::MakeMaker;
WriteMakefile(
    NAME            => "Geo::TigerLine",
    VERSION_FROM    => "lib/Geo/TigerLine.pm", # finds $VERSION
    PREREQ_PM       => { strict         => 0,
                         vars           => 0,
                         base           => 0,
                         Carp::Assert   => 0,
                         Class::Accessor => 0.15,
                         Class::Data::Inheritable => 0.02,
                         Carp           => 0,
                         Data::Dumper   => 0,
			 Test::More	=> 0.47,
                       },
);
