use ExtUtils::MakeMaker;

WriteMakefile
(
  NAME          => 'Font::FNT'
, VERSION_FROM  => 'FNT.pm'
, ABSTRACT_FROM => 'FNT.pm'
, AUTHOR        => 'Steffen Goeldner'
, PREREQ_PM     => { YAML => 0.35 }
);
