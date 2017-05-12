use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Image::Simple::Gradient',
    AUTHOR              => q{Hernan Lopes <hernanlopes@gmail.com>},
    VERSION_FROM        => 'lib/Image/Simple/Gradient.pm',
    ABSTRACT_FROM       => 'lib/Image/Simple/Gradient.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'GD' => 2.45,
        'Moose' => '1.0',
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Image-Simple-Gradient-*' },
);
