use ExtUtils::MakeMaker;

WriteMakefile (
               AUTHOR        => 'Casey West <casey@geeknest.com>',
               ABSTRACT      => "Group a list of data structures to your specifications",
               NAME          => 'List::Group',
               PREREQ_PM     => {
                                 'Test::More' => '',
                                 'Test::Deep' => '',
                                 'POSIX'      => '',
                                 'Storable'   => '',
                                },
               VERSION_FROM  => 'lib/List/Group.pm',
              );
