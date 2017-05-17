use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
  (
   'NAME'	=> 'Log-Dispatch-Tk',
   'VERSION' => '1.9',
   'dist' => {COMPRESS=>'gzip -9f', SUFFIX => 'gz'},
   'PREREQ_PM' =>
   {
    'Tk' => 0,
    'Log::Dispatch' => '2.00',
    'Log::Dispatch::Output' => '1.011'
   },
   ($] >= 5.005 ?
    (ABSTRACT   => 'Tk text widget for Log::Dispatch messages',
     AUTHOR     => 'Dominique Dumont (ddumont@cpan.org)') : ())
  );
