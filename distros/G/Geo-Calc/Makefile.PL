use ExtUtils::MakeMaker;

require 5.008003; # Prereq of Moose

WriteMakefile(
    NAME        => 'Geo::Calc',
    VERSION     => '0.12',
    PREREQ_PM   => {
        Test::More                 => 0.47,
        Math::Trig                 => 1.04,
        Moose                      => 1.19,
        MooseX::FollowPBP          => 0.04,
        MooseX::Method::Signatures => 0.36,
        Math::BigFloat             => 1.60,
        Math::Units                => 1.3,
        POSIX                      => 0
    },
    AUTHOR      => 'Sorin Pop',
    ABSTRACT    => 'Geographical Calc',
    LICENSE     => 'perl'
  );
