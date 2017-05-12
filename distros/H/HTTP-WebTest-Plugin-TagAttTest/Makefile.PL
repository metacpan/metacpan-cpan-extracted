use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTTP::WebTest::Plugin::TagAttTest',
    'VERSION_FROM'	=> 'lib/HTTP/WebTest/Plugin/TagAttTest.pm', # finds $VERSION
    'PREREQ_PM'		=> {
    'HTTP::WebTest' => 2.00, # should be installed to run tests
},
    (
      (ABSTRACT_FROM => 'lib/HTTP/WebTest/Plugin/TagAttTest.pm', # retrieve abstract from module
       AUTHOR     => 'Edward Fancher <efanche@ethercube.net>')),
);
