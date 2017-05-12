use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'    => 'HTML::Display',
    'VERSION_FROM'  => 'lib/HTML/Display.pm', # finds $VERSION
    'PREREQ_PM'    => {
                       'parent' => 0.218,
		       'URI::URL' => 0.00,
		       'Test::Harness' => 2.30,
                       'LWP' => 5.69,
		       'HTML::TokeParser::Simple' => 2,
                      }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/HTML/Display.pm', # retrieve abstract from module
       AUTHOR     => 'Max Maischein <corion@cpan.org>') : ()),
);

# To make Test::Prereq happy
1;
