use 5.006;    # our
use strict;
use warnings;

package FakeUA;

our $VERSION = '0.001000';

# ABSTRACT: A fake dummy UA for doing get requests on

# AUTHORITY

our $AUTOLOAD;

sub AUTOLOAD {
  my $program = $AUTOLOAD;
  $program =~ s/.*:://;

  my ( $self, @args ) = @_;
  push @{ $self->{calls} }, [ $program, @args ];
  require HTTP::Response;
  return HTTP::Response->new();
}

sub new {
  my ( $self, @args ) = @_;
  bless { args => \@args, calls => [] }, $self;
}

1;
