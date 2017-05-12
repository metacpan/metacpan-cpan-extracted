
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'Math::Vector::Real::Farthest',

               VERSION_FROM  => 'lib/Math/Vector/Real/Farthest.pm',

               PREREQ_PM     => { 'Sort::Key::Top'     => '0.07',
                                  'Math::nSphere'      => '0.01',
                                  'Math::Vector::Real' => '0.11' },

               ABSTRACT_FROM => 'lib/Math/Vector/Real/Farthest.pm',

               AUTHOR        => 'Salvador Fandiño <sfandino@yahoo.com>',
);
