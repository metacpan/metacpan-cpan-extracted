use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  'NAME'         => 'HTML::Template::HTX',
  'VERSION_FROM' => 'HTX.pm', # finds $VERSION
  'PREREQ_PM'    => {FileHandle => 0, HTML::Entities => 0, URI::Escape => 0},

  ($] >= 5.005 ? ( ## Add these new keywords supported since 5.005
    'ABSTRACT_FROM' => 'HTX.pm', # retrieve abstract from module
    'AUTHOR'        => 'Theo Niessink <niessink@martinic.nl>',
  ) : ()),
);
