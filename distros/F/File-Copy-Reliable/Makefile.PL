#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'File::Copy::Reliable',
    'VERSION_FROM' => 'lib/File/Copy/Reliable.pm',
    'ABSTRACT'     => 'File copying and moving with extra checking',
    'AUTHOR'       => 'Leon Brocard <acme@astray.com>',
    'LICENSE'      => 'perl',
    'PREREQ_PM'    => {
        'File::Copy'      => 0,
        'Path::Class'     => '0',
        'Test::Exception' => '0',
        'Test::File'      => '0',
    },
);

