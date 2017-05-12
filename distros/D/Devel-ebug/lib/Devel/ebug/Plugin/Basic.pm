package Devel::ebug::Plugin::Basic;
$Devel::ebug::Plugin::Basic::VERSION = '0.59';
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(basic);

# get basic debugging information
sub basic {
  my ($self) = @_;
  my $response = $self->talk({ command => "basic" });
  $self->codeline($response->{codeline});
  $self->filename($response->{filename});
  $self->finished($response->{finished});
  $self->line($response->{line});
  $self->package($response->{package});
  $self->subroutine($response->{subroutine});
}

1;
