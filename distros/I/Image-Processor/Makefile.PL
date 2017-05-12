use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Image::Processor',
    'VERSION_FROM'	=> 'Processor.pm', # finds $VERSION
    'PREREQ_PM'		=> { Image::Magick    => 5.4, 
                         Text::Template   => 0,
                         Image::Size      => 0,
                         Mail::MboxParser => .31,
                          }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Processor.pm', # retrieve abstract from module
       AUTHOR     => 'Aaron J Johnson solution@gina.net') : ()),
);
