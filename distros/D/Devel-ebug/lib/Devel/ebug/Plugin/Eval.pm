package Devel::ebug::Plugin::Eval;
$Devel::ebug::Plugin::Eval::VERSION = '0.59';
use strict;
use warnings;
use base qw(Exporter);
our @EXPORT = qw(eval yaml);

# eval
sub eval {
  my($self, $eval) = @_;
  my $response = $self->talk({
    command => "eval",
    eval    => $eval,
  });
  return wantarray ? ( $response->{eval}, $response->{exception} ) :
                     $response->{eval};
}

# yaml
sub yaml {
  my($self, $yaml) = @_;
  my $response = $self->talk({
    command => "yaml",
    yaml    => $yaml,
  });
  return $response->{yaml};
}

1;
