
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'Math::Vector::Real::Polyline',
               VERSION_FROM  => 'lib/Math/Vector/Real/Polyline.pm',
               PREREQ_PM     => { 'Math::Vector::Real' => '0.18' },
               ABSTRACT_FROM => 'lib/Math/Vector/Real/Polyline.pm',
               AUTHOR        => 'Salvador Fandino <sfandino@yahoo.com>',
               LICENSE       => 'perl',
             );
