
use strict;
use warnings;

use ExtUtils::MakeMaker 6.30;

use File::ShareDir::Install;
install_share dist => "share";

my %WriteMakefileArgs = (
  'ABSTRACT' => 'Microsoft Exchange Web Services Client',
  'AUTHOR' => 'Oliver Gorwits <oliver@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.30',
    'File::ShareDir::Install' => '0.03'
  },
  'DISTNAME' => 'EWS-Client',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'EWS::Client',
  'PREREQ_PM' => {
    'Authen::NTLM' => '0',
    'Carp' => '0',
    'Data::Dumper' => '0',
    'DateTime' => '0',
    'DateTime::Format::ISO8601' => '0',
    'Encode' => '0',
    'File::ShareDir' => '0',
    'HTML::Strip' => '0',
    'LWP::Authen::Ntlm' => '0',
    'LWP::Protocol::https' => '6.02',
    'Log::Report' => '0',
    'Moose' => '0',
    'Moose::Role' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::Iterator' => '0',
    'URI::Escape' => '0',
    'XML::Compile::SOAP11' => '0',
    'XML::Compile::Transport::SOAPHTTP' => '0',
    'XML::Compile::WSDL11' => '0'
  },
  'VERSION' => '1.300000',
  'test' => {
    'TESTS' => 't/*.t'
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);

package
MY;
use File::ShareDir::Install qw(postamble);


