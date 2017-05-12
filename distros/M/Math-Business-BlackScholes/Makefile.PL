use ExtUtils::MakeMaker;
WriteMakefile(
  NAME => "Math::Business::BlackScholes",
  VERSION_FROM => "BlackScholes.pm",
  PREREQ_PM => { "Math::CDF" => 0.1 },
  AUTHOR => 'Anders Johnson <anders@ieee.org>',
  ABSTRACT_FROM => "BlackScholes.pm",
);
