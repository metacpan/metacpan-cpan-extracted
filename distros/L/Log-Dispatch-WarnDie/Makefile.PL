require 5.006;

use strict;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Log::Dispatch::WarnDie",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'Log::Dispatch::WarnDie - Log standard Perl warnings and errors',
 VERSION_FROM	=> 'lib/Log/Dispatch/WarnDie.pm',

 PREREQ_PM	=> {qw(
                   )},
);
