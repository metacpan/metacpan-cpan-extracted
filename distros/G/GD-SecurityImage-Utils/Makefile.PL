use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'GD::SecurityImage::Utils',
   VERSION_FROM => 'lib/GD/SecurityImage/Utils.pm',
   PREREQ_PM => {
      GD => 0,
      'GD::SecurityImage' => 0,      
   },
   EXE_FILES => ['bin/captcha'],
);
