require 5.006;

use strict;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Log::ForPerl",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'Log::ForPerl - Log standard Perl warnings and errors',
 VERSION_FROM	=> 'lib/Log/ForPerl.pm',

 PREREQ_PM	=> {qw(
                   )},
);
