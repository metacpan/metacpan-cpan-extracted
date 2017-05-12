use 5.010;
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'Math::Vector::Real::Neighbors',
               VERSION_FROM  => 'lib/Math/Vector/Real/Neighbors.pm',
               PREREQ_PM     => { 'Math::Vector::Real' => '0.14',
                                  'Math::Vector::Real::kdTree' => '0.11',
                                  'Sort::Key::Radix' => '0.13' },
               ABSTRACT_FROM => 'lib/Math/Vector/Real/Neighbors.pm',
               AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>'
);
