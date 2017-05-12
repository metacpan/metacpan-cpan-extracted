#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'         => 'Games::GuessWord',
    'VERSION_FROM' => 'lib/Games/GuessWord.pm',
    'LICENSE'      => 'perl',
    'AUTHOR'       => 'Leon Brocard <acme@astray.com>',
    'ABSTRACT'     => 'Guess the letters in a word (ie Hangman)',
    'PREREQ_PM'    => { 'Test::Simple' => 0, },
    'dist'         => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
