use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'           => 'Mail::vpopmail',
    'VERSION_FROM'   => 'vpopmail.pm', # finds $VERSION
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'vpopmail.pm',
       AUTHOR        => 'Jeremy Kister <http://jeremy.kister.net/>') : ()),
);
