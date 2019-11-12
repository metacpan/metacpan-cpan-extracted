require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile (
 NAME		=> "LCC",
 ($[ >= 5.005) ?
 (AUTHOR	=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
  ABSTRACT	=> 'Content Provider Modules for Local Content Cache system') : (),
 VERSION_FROM	=> 'lib/LCC.pm',
 PREREQ_PM	=> {
                    'IO::File' => 0,
                    'IO::Socket' => 0,
                   },
 EXE_FILES	=> [<script/*>],
);
