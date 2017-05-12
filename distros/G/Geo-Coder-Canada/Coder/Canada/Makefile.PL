use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'         => 'Geo::Coder::Canada',
    'VERSION_FROM' => 'Canada.pm', # finds $VERSION
    'PREREQ_PM'    => {
      XML::Simple    => 1,
      LWP::UserAgent => 1,
      URI            => 1,
      HTTP::Request  => 1,
    }, 
);
