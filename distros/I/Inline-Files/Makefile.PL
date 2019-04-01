
use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => q[Inline::Files],
   VERSION_FROM => 'lib/Inline/Files.pm',
   ABSTRACT_FROM => 'lib/Inline/Files.pm',
   PREREQ_PM => {
      'Filter::Util::Call' => 0,
      Test                 => 0,
      Cwd                  => 0,
   },
   META_MERGE        => {
      "meta-spec" => { version => 2 },
      resources => {
         repository => {
            type => 'git',
            url => 'git@gitlab.com:ambs/perl5-inline-files.git',
            web => 'https://gitlab.com/ambs/perl5-inline-files.git',
         },
      },
   },
);
