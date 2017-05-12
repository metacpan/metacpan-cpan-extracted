require 5.000;
use ExtUtils::MakeMaker;
eval "use Devel::Required";

WriteMakefile (
 NAME		=> "Devel::MaintBlead",
 ( $] >= 5.005 ) ? (
  AUTHOR	    => 'Elizabeth Mattijsen (liz@dijkmat.nl)',
  ABSTRACT	    => 'handle maint / blead code paths for distributions',
 ) : (),
 VERSION_FROM	=> 'lib/Devel/MaintBlead.pm',
 LICENSE        => 'perl',
);
