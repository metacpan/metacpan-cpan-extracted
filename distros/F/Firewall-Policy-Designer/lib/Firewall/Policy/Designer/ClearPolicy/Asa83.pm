package Firewall::Policy::Designer::Asa83;

use Moose;
use namespace::autoclean;
use Firewall::Utils::Ip;
use Firewall::Policy::Searcher::Report::FwInfo;

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
  push( @{$self->commandText}, @commands );
}

sub design {
  my $self = shift;
  push( @{$self->commandText}, 'Asa8.3以上版本工具暂不支持设计，请自行设计' );
  return join( '', map {"$_\n"} @{$self->commandText} );
}

__PACKAGE__->meta->make_immutable;
1;
