package Firewall::Policy::Designer::Checkpoint;

use Carp;
use Moose;
use namespace::autoclean;
use Firewall::Utils::Ip;
use Firewall::Policy::Searcher::Report::FwInfo;
use Mojo::Util qw(dumper);

has dbi => (
  is       => 'ro',
  does     => 'Firewall::DBI::Role',
  required => 1,
);

has searcherReportFwInfo => (
  is       => 'ro',
  isa      => 'Firewall::Policy::Searcher::Report::FwInfo',
  required => 1,
);

has commandText => (
  is      => 'ro',
  isa     => 'ArrayRef[Str]',
  default => sub { [] },
);

sub addToCommandText {
  my ( $self, @commands ) = @_;
  push @{$self->commandText}, @commands;
}

sub design {
  my $self = shift;
  push @{$self->commandText}, 'Checkpoint is not support now,please do it you self!';
  return join( '', map {"$_\n"} @{$self->commandText} );
}

__PACKAGE__->meta->make_immutable;
1;
