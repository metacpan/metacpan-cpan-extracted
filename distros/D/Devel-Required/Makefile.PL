require 5.000;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Devel::Required",
 ($] >= 5.005) ? (
  AUTHOR	    => 'Elizabeth Mattijsen (liz@dijkmat.nl)',
  ABSTRACT	    => 'Automatic update of required modules documentation'
 ) : (),
 VERSION_FROM	=> 'lib/Devel/Required.pm',
 LICENSE        => 'perl',
);
