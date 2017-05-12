use ExtUtils::MakeMaker;

WriteMakefile(
              NAME	=> 'Finance::Bank::IE',
              VERSION_FROM => 'lib/Finance/Bank/IE.pm',
              AUTHOR  => 'Ronan Waide <waider@waider.ie>',
              PREREQ_PM   => {
                              'Date::Parse' => '0',
                              'HTML::Entities' => '0',
                              'HTML::TokeParser' => '0',
                              'Test::MockModule' => '0',
                              'WWW::Mechanize'	=> '0',
                             },
             );
