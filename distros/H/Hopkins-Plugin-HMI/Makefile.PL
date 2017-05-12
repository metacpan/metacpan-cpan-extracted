
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;

use File::ShareDir::Install;
install_share dist => "share";


my %WriteMakefileArgs = (
  'ABSTRACT' => 'hopkins HMI session (using HTTP)',
  'AUTHOR' => 'Mike Eldridge <diz@cpan.org>',
  'BUILD_REQUIRES' => {
    'Test::More' => '0.42'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31',
    'File::ShareDir::Install' => '0.03'
  },
  'DISTNAME' => 'Hopkins-Plugin-HMI',
  'EXE_FILES' => [],
  'LICENSE' => 'perl',
  'NAME' => 'Hopkins::Plugin::HMI',
  'PREREQ_PM' => {
    'Catalyst::Action::RenderView' => '0.08',
    'Catalyst::Engine::Embeddable' => '0.000003',
    'Catalyst::Plugin::Authentication' => '0.100092',
    'Catalyst::Plugin::Session' => '0.24',
    'Catalyst::Plugin::Session::State::Cookie' => '0.17',
    'Catalyst::Plugin::Session::Store::FastMmap' => '0.11',
    'Catalyst::Plugin::Static::Simple' => '0.29',
    'Catalyst::View::TT' => '0.34',
    'Class::Accessor::Fast' => '0.31',
    'File::ShareDir' => '1.00',
    'Hopkins' => '0.900',
    'POE::Component::Server::HTTP' => '0.09',
    'Sys::Hostname::FQDN' => '0.10'
  },
  'VERSION' => '0.900',
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


