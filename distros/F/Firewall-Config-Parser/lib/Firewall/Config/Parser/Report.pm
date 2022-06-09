package Firewall::Config::Parser::Report;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# Firewall::Config::Parser::Report 通用属性
#------------------------------------------------------------------------------
has source =>
  ( is => 'ro', isa => 'HashRef[Firewall::Policy::Element::Source]', default => sub { {} }, writer => 'setSource', );

has destination => (
  is      => 'ro',
  isa     => 'HashRef[Firewall::Policy::Element::Destination]',
  default => sub { {} },
  writer  => 'setDestination',
);

has service => (
  is      => 'ro',
  isa     => 'HashRef[HashRef[Firewall::Policy::Element::Service]]',
  default => sub { {} },
  writer  => 'setService',
);

__PACKAGE__->meta->make_immutable;
1;
