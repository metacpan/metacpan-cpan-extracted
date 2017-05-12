use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => "Create Function Registries and Register Functions",
               NAME          => 'Function::Register',
               PREREQ_PM     => {
                                 'Test::More' => '',
                                },
               VERSION_FROM  => 'lib/Function/Register.pm',
              );
