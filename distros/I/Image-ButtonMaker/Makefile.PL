use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Image::ButtonMaker',
    VERSION_FROM      => 'lib/Image/ButtonMaker.pm', # finds $VERSION
    PREREQ_PM         => {Image::Magick => 5.5}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/Image/ButtonMaker.pm', # retrieve abstract from module
    AUTHOR            => 'Piotr Czarny <picz@sifira.dk>',
);
