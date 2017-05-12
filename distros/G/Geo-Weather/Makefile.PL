use ExtUtils::MakeMaker;
WriteMakefile(
   NAME => "Geo::Weather",
   VERSION_FROM => "Weather.pm",
   ($] >= 5.005
      ? (ABSTRACT   => 'Get current weather from weather.com',
         AUTHOR     => 'Mike Machado <mike@innercite.com>')
      : ()),
  'dist' => {COMPRESS=>'gzip',SUFFIX=>'gz'},
  'PREREQ_PM' => {LWP::UserAgent => 1.73}
);
