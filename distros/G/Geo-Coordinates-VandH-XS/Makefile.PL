use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'            => 'Geo::Coordinates::VandH::XS',
    'VERSION_FROM'    => 'XS.pm',
    'LIBS'            => [ "-lm" ],
);
