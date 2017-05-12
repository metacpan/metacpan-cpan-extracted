use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'HTTP::GetImages',
    'VERSION_FROM'	=> 'GetImages.pm', # finds $VERSION
    'PREREQ_PM'		=> {LWP::UserAgent=>0.1,HTTP::Request=>0.1,HTML::TokeParser=>0.1}, # e.g., Module::Name => 1.1
);
