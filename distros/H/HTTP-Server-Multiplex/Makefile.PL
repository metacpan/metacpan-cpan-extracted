use ExtUtils::MakeMaker;

require 5.008;

WriteMakefile
  ( NAME      => 'HTTP::Server::Multiplex'
  , VERSION   => '0.11'
  , PREREQ_PM =>
    { IO::Multiplex   => 1.09
    , Net::CIDR       => 0.11
    , LWP             => 5.806
    , File::Spec      => 3.12
    , Log::Report     => 0.18
    , List::Util      => 1.18
    , Sys::Hostname   => 1.11
    , Storable        => 2.15
    , URI             => 1.35
    , LWP::MediaTypes => 1.33

    , Test::More      => 0.47
    , Test::Pod       =>'1.00'
    }
  , AUTHOR    => 'Mark Overmeer'
  , ABSTRACT  => 'Single process rich HTTP/1.1 daemon'
  , LICENSE   => 'perl'
  );

### used by oodist during production of distribution
sub MY::postamble { <<'__POSTAMBLE' }

# for DIST
RAWDIR          = ../public_html/httpd-multiplex/raw
DISTDIR         = ../public_html/httpd-multiplex/source
LICENSE         = artistic

# for POD
FIRST_YEAR      = 2008
EMAIL           = perl@overmeer.net
WEBSITE         = http://perl.overmeer.net/httpd-multiplex/
__POSTAMBLE
