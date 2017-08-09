use 5.010001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'HTTP::MultiGet',
    VERSION_FROM      => 'lib/HTTP/MultiGet.pm', # finds $VERSION
    PREREQ_PM         => {
    qw(
      Moo  2.003002
      overload 1.28
      Modern::Perl 1.20170117
      MooX::Types::MooseLike::Base 0.29
      Carp 1.42
      namespace::clean 0.27
      Data::Dumper  2.167
      Test::More    1.302073
      Data::Result  1.0
      Log::Log4perl 1.49
      Time::HiRes   1.9741
      B             1.68
      Scalar::Util  1.48
      Ref::Util     0.203
      Log::Dispatch::Handle  2.65
      IO::Scalar    2.111
      Exporter      5.72
      Log::LogMethods  1.0001
      Data::Result  1.0001
      Data::Queue   1.0001
      AnyEvent::HTTP::Request  0.302
      HTTP::Request 6.13
      HTTP::Headers 6.13
      HTTP::Response 6.13
      AnyEvent::HTTP::Response 0.302
      AnyEvent 7.14
      AnyEvent::Loop 0
    )
    
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTTP/MultiGet.pm', # retrieve abstract from module
       AUTHOR         => 'Mike Shipper <AKALINUX@CPAN.ORG>') : ()),
);
