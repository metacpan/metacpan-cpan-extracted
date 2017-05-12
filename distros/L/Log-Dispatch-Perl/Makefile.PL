require 5.006;

use strict;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Log::Dispatch::Perl",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'Log::Dispatch::Perl - Use core Perl functions for logging',
 LICENSE	=> 'perl',
 VERSION_FROM	=> 'lib/Log/Dispatch/Perl.pm',

 PREREQ_PM	=> {qw(
		    Log::Dispatch	1.16
                   )},
);
