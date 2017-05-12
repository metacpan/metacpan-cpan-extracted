use 5.010;

use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'Math::Vector::Real::kdTree',
               VERSION_FROM  => 'lib/Math/Vector/Real/kdTree.pm',
               PREREQ_PM     => { 'Math::Vector::Real' => '0.16',
                                  'Sort::Key::Top'     => '0.08' },
               ABSTRACT_FROM => 'lib/Math/Vector/Real/kdTree.pm',
               AUTHOR        => 'Salvador Fandiño <sfandino@yahoo.com>'
             );
