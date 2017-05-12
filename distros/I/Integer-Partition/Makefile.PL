# generate Makefile for building Integer::Partition
#
# Copyright (C) 2007-2013 David Landgren

use strict;
use ExtUtils::MakeMaker;

eval "use ExtUtils::MakeMaker::Coverage";
$@ or print "Adding testcover target\n";

WriteMakefile(
    NAME             => 'Integer::Partition',
    VERSION_FROM     => 'Partition.pm',
    ABSTRACT_FROM    => 'Partition.pm',
    AUTHOR           => 'David Landgren',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.008001',
);
