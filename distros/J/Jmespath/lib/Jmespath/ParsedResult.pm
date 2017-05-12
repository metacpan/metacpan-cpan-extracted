package Jmespath::ParsedResult;
use strict;
use warnings;
use Jmespath::TreeInterpreter;

sub new {
  my ( $class, $expression, $parsed ) = @_;
  my $self = bless {}, $class;
  $self->{expression} = $expression;
  $self->{parsed} = $parsed;
  return $self;
}

sub search {
  my ( $self, $data, $options ) = @_;
  $options = $options || undef;
  my $interpreter = Jmespath::TreeInterpreter->new($options);
  my $result = $interpreter->visit( $self->{ parsed }, $data );
  return $result;
}

sub _render_dot_file {
  my ($self) = @_;
  my $renderer = Jmespath::GraphvizVisitor->new;
  my $contents = Jmespath::Renderer->visit( $self->parsed );
  return $contents;
}

# try to emulate __REPR__
sub stringify {
  return shift->{parsed};
}

1;
