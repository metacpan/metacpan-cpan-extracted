use ExtUtils::MakeMaker;
WriteMakefile(
  NAME         =>'GPS::Point',
  VERSION_FROM =>'lib/GPS/Point.pm',
  AUTHOR       =>'Michael R. Davis (account=>perl,tld=>com,domain=>michaelrdavis)',
  ABSTRACT_FROM=> 'lib/GPS/Point.pm',
  LICENSE      => 'bsd',
  PREREQ_PM    => {
                   'Test::Simple'        => 0.44,
                   'Test::Number::Delta' => 0,
                   'Scalar::Util'        => 1.02,
                  },
);
