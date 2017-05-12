use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'=> 'IRC::Bot',
    'VERSION_FROM' => 'Bot.pm', 
    'PREREQ_PM' => { 
                      POE::Component::IRC => 2.7, 
                      Cache::Cache => 1.02
                   },
    'AUTHOR' => 'Benjamin W. Smith <defitro@just-another.net>',
);
