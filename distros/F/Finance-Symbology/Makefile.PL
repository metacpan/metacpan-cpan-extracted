#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'Finance::Symbology',
  VERSION_FROM => 'lib/Finance/Symbology.pm',
  PREREQ_PM    => {},
  AUTHOR       => 'George Tsafas <elb0w@elbowrage.com>'
);
