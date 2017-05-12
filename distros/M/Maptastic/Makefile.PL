use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile
    (
     'NAME'		=> "Maptastic",
     'PREREQ_PM'        => { 'Test::Simple' => 0.41, Scalar::Util => 0 },
     'VERSION_FROM'     => "lib/Maptastic.pm",
     ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT         => "Map for multiple lists & iterative map",
       AUTHOR           => "The Map Junky <samv@cpan.org>") : ()),
    );


