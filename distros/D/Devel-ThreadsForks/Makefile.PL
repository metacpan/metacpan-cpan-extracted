require 5.000;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Devel::ThreadsForks",
 ($] >= 5.005) ? (
  AUTHOR	    => 'Elizabeth Mattijsen (liz@dijkmat.nl)',
  ABSTRACT	    => 'Check for availability of threads or forks',
 ) : (),
 VERSION_FROM	=> 'lib/Devel/ThreadsForks.pm',
 LICENSE        => 'perl',
);
