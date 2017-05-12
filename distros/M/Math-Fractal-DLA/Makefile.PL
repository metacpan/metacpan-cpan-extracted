use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
%prereq = (
  'GD' => 1.27,
  'Log::LogLite' => 0.8,
  'Test::More' => 0.54
          );

WriteMakefile(
    'NAME'		=> 'Math::Fractal::DLA',
    'VERSION_FROM'	=> 'lib/Math/Fractal/DLA.pm',
    'DISTNAME'		=> 'Math-Fractal-DLA',
    'PREREQ_PM'		=> \%prereq, 
    ($] >= 5.005 ?
      (ABSTRACT => 'Create a DLA fractal with GD',
       AUTHOR     => 'Wolfgang Gruber <w.gruber@urldirect.at>') : ()),
);
