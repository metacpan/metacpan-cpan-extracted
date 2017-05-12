use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'HTTP::WebTest::Plugin::DateTest',
    'VERSION_FROM'	=> 'lib/HTTP/WebTest/Plugin/DateTest.pm',
    'PREREQ_PM'		=> {
                            'HTTP::WebTest' => 2.00, # should be installed to run tests
                            'Date::Parse'   => 2.23, # includes Date::Language modules
                            'Test::More'    => 0,    # require to do 'make test'
                           },
    ($] >= 5.005 ?
      (
       ABSTRACT_FROM    => 'lib/HTTP/WebTest/Plugin/DateTest.pm',
       AUTHOR           => 'Johannes la Poutre <japh@lapoutre.com>',
      ) : ()),
);

