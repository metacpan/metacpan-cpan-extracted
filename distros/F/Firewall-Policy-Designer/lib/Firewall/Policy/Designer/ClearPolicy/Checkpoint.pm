package Firewall::Policy::Designer::Checkpoint;

#------------------------------------------------------------------------------
# 加载系统模块，辅助构造函数功能和属性
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载项目模块
#------------------------------------------------------------------------------
use Firewall::Utils::Ip;
use Firewall::Policy::Searcher::Report::FwInfo;

has dbi => ( is => 'ro', does => 'Firewall::DBI::Role', required => 1, );

has searcherReportFwInfo => ( is => 'ro', isa => 'Firewall::Policy::Searcher::Report::FwInfo', required => 1, );

has commandText => ( is => 'ro', isa => 'ArrayRef[Str]', default => sub { [] }, );

sub addToCommandText {
  my ( $self, @commands ) = @_;
  push( @{$self->commandText}, @commands );
}

sub design {
  my $self = shift;
  push( @{$self->commandText}, 'Checkpoint工具不支持设计，请自行设计' );
  return join( '', map {"$_\n"} @{$self->commandText} );
}

__PACKAGE__->meta->make_immutable;
1;
