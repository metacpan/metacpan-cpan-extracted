use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'Mail::Convert::Mbox::ToEml',
  'VERSION_FROM' => 'lib/Mail/Convert/Mbox/ToEml.pm',
  'PREREQ_PM'    => {},
  (eval { ExtUtils::MakeMaker->VERSION(6.21) } ? (LICENSE => 'perl') : ()),
  (
    $] >= 5.005
    ?  ## Add these new keywords supported since 5.005
      (
      ABSTRACT_FROM => 'lib/Mail/Convert/Mbox/ToEml.pm',
      AUTHOR        => 'Reinhard Pagitsch <rpirpag@gmx.at>'
      )
    : ()
  ),
);
