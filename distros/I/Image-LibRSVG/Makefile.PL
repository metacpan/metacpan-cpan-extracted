use ExtUtils::MakeMaker;

my %config;

$config{INC} = ' ' . `pkg-config --cflags librsvg-2.0`;
$config{LIBS} = ' ' . `pkg-config --libs-only-l librsvg-2.0`;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Image::LibRSVG',
    'VERSION_FROM'	=> 'lib/Image/LibRSVG.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
       %config,
);
