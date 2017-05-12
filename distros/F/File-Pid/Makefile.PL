use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => "Pid File Manipulation",
               NAME          => 'File::Pid',
               PREREQ_PM     => {
                                 'Class::Accessor::Fast' => '0.19',
                                },
               VERSION_FROM  => 'lib/File/Pid.pm',
              );
