
use ExtUtils::MakeMaker;

WriteMakefile( NAME          => 'Math::Vector::Real::XS',
               VERSION_FROM  => 'lib/Math/Vector/Real/XS.pm',
               PREREQ_PM     => { 'Math::Vector::Real' => '0.17' },
               ABSTRACT_FROM => 'lib/Math/Vector/Real/XS.pm',
               AUTHOR        => 'Salvador Fandiño <sfandino@yahoo.com>',
               LIBS          => [''],
               DEFINE        => '',
               INC           => '-I.',
             );
