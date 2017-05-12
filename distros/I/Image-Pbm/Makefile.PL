use ExtUtils::MakeMaker;

WriteMakefile
(
  NAME          => 'Image::Pbm'
, VERSION_FROM  => 'Pbm.pm'
, ABSTRACT_FROM => 'Pbm.pm'
, AUTHOR        => 'Steffen Goeldner'
, PREREQ_PM     => { 'Image::Xbm' => 1.08, Image::PBMlib => 2.00 }
);
