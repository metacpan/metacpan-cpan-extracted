#!perl
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Fir',
    VERSION_FROM => 'lib/Fir.pm',
    LICENSE      => 'perl',
    AUTHOR       => 'Leon Brocard <acme@astray.com>',
    ABSTRACT     => 'a Tree::DAG_Node subclass for menu nagivation',
    PREREQ_PM    => {
        'Test::More'     => '0',
        'Tree::DAG_Node' => '0',
        'Moose'          => '0',
    },
);

