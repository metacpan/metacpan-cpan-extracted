require 5.006;

use strict;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Log::Dispatch::XML",
 AUTHOR		=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
 ABSTRACT	=> 'Log::Dispatch::XML - Collect one or more messages in XML format',
 VERSION_FROM	=> 'lib/Log/Dispatch/XML.pm',

 PREREQ_PM	=> {qw(
		    Log::Dispatch		1.16
		    Log::Dispatch::Buffer	0
                   )},
);
