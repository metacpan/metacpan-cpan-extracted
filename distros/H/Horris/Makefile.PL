
use strict;
use warnings;



use ExtUtils::MakeMaker 6.31;



my %WriteMakefileArgs = (
  'ABSTRACT' => 'Yet Another IRC Bot',
  'AUTHOR' => 'hshong <hshong@perl.kr>',
  'BUILD_REQUIRES' => {
    'App::Horris' => '0',
    'Test::MockObject::Extends' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '6.31'
  },
  'DISTNAME' => 'Horris',
  'EXE_FILES' => [
    'bin/horris'
  ],
  'LICENSE' => 'perl',
  'NAME' => 'Horris',
  'PREREQ_PM' => {
    'Acme::Letter' => '0',
    'AnyEvent' => '0',
    'AnyEvent::Feed' => '0',
    'AnyEvent::HTTP' => '0',
    'AnyEvent::IRC::Client' => '0',
    'AnyEvent::MP' => '0',
    'AnyEvent::MP::Global' => '0',
    'AnyEvent::RetryTimer' => '0',
    'AnyEvent::Twitter::Stream' => '0',
    'Config::General' => '0',
    'Const::Fast' => '0',
    'DBI' => '0',
    'Data::Dumper' => '0',
    'DateTime::Format::W3CDTF' => '0',
    'Encode' => '0',
    'File::Temp' => '0',
    'HTML::Strip' => '0',
    'HTML::TreeBuilder' => '0',
    'HTTP::Request' => '0',
    'HTTP::Response' => '0',
    'Image::Size' => '0',
    'JSON' => '0',
    'LWP::Simple' => '0',
    'LWP::UserAgent' => '0',
    'Moose' => '0',
    'Moose::Util::TypeConstraints' => '0',
    'MooseX::App::Cmd' => '0',
    'MooseX::App::Cmd::Command' => '0',
    'MooseX::Role::Pluggable' => '0',
    'MooseX::Role::Pluggable::Plugin' => '0',
    'MooseX::SimpleConfig' => '0',
    'URI' => '0',
    'URI::Escape' => '0',
    'WWW::Shorten' => '0',
    'WebService::KoreanSpeller' => '0',
    'constant' => '0',
    'namespace::autoclean' => '0',
    'namespace::clean' => '0'
  },
  'VERSION' => 'v0.1.2',
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



