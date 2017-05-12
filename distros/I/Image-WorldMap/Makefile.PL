#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Image::WorldMap',
    'VERSION_FROM' => 'WorldMap.pm',
    'LICENSE'      => 'perl',
    'AUTHOR'       => 'Leon Brocard <acme@astray.com>',
    'ABSTRACT'     => 'Create graphical world maps of data',
    'PREREQ_PM'    => { 'Image::Imlib2' => 0, 'Test::More' => 0, },
    'dist'         => { 'COMPRESS' => 'gzip -9f', 'SUFFIX' => 'gz', },
);

sub MY::libscan {
    my $path = $_[1];
    return '' if $path =~ /\B\.svn\b/;
    return $path;
}
