use ExtUtils::MakeMaker;

WriteMakefile(
   NAME         => 'GD::SecurityImage::AC',
   VERSION_FROM => 'lib/GD/SecurityImage/AC.pm',
   'linkext'    => { LINKTYPE=>'' },       # no link needed
   PREREQ_PM    => {
                     'GD::SecurityImage' => '1.60',
                     'Digest::MD5'       => 0,
   },
   'dist'       => {'COMPRESS'=>'gzip -9f', 'SUFFIX' => 'gz',
                    'ZIP'=>'/usr/bin/zip','ZIPFLAGS'=>'-rl'},
   ($] >= 5.005 ? (
   AUTHOR        => 'Benjamin Franz <snowhare@nihongo.org>',
   ABSTRACT_FROM => 'lib/GD/SecurityImage/AC.pod',
   ) : ()),
   ($] >= 5.800 ?     ## Add these new keywords supported since 5.8
             (NO_META      => 1) : ()),

   PL_FILES     => {},
);
