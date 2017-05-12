use ExtUtils::MakeMaker;

WriteMakefile( NAME         => 'Math::Vector::Real::Random',
               VERSION_FROM => 'lib/Math/Vector/Real/Random.pm',
               PREREQ_PM    => { 'Math::Vector::Real' => '0.03',
				 'Math::Random'       => '0.01' },
               AUTHOR       => 'Salvador Fandino <sfandino@yahoo.com>' );
