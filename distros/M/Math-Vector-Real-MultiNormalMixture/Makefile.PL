
use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'Math::Vector::Real::MultiNormalMixture',
               VERSION_FROM  => 'lib/Math/Vector/Real/MultiNormalMixture.pm', # finds $VERSION
               PREREQ_PM     => { 'Math::Vector::Real' => '0.06' },
               ABSTRACT_FROM => 'lib/Math/Vector/Real/MultiNormalMixture.pm', # retrieve abstract from module
               AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>',
             );
