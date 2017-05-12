use 5.006;    # our
use strict;
use warnings;

package MetaPOD::Result;

our $VERSION = 'v0.4.0';

# ABSTRACT: Compiled aggregate result object for MetaPOD

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY













use Moo qw( has );
use List::AllUtils qw( uniq );







has namespace => (
  is       => ro            =>,
  required => 0,
  lazy     => 1,
  builder  => sub           { undef },
  writer   => set_namespace =>,
  reader   => namespace     =>,
);

has inherits => (
  is       => ro            =>,
  required => 0,
  lazy     => 1,
  builder  => sub           { [] },
  writer   => _set_inherits =>,
  reader   => _inherits     =>,
);

has does => (
  is       => ro        =>,
  required => 0,
  lazy     => 1,
  builder  => sub       { [] },
  writer   => _set_does =>,
  reader   => _does     =>,
);

has interface => (
  is       => ro             =>,
  required => 0,
  lazy     => 1,
  builder  => sub            { [] },
  writer   => _set_interface =>,
  reader   => _interface     =>,
);







sub inherits {
  my $self = shift;
  return @{ $self->_inherits };
}







sub set_inherits {
  my ( $self, @inherits ) = @_;
  $self->_set_inherits( [ uniq @inherits ] );
  return $self;
}







sub add_inherits {
  my ( $self, @items ) = @_;
  $self->_set_inherits( [ uniq @{ $self->_inherits }, @items ] );
  return $self;
}







sub does {
  my $self = shift;
  return @{ $self->_does };
}







sub set_does {
  my ( $self, @does ) = @_;
  $self->_set_does( [ uniq @does ] );
  return $self;
}







sub add_does {
  my ( $self, @items ) = @_;
  $self->_set_does( [ uniq @{ $self->_does }, @items ] );
  return $self;
}







sub interface {
  my $self = shift;
  return @{ $self->_interface };
}







sub set_interface {
  my ( $self, @interfaces ) = @_;
  $self->_set_interface( [ uniq @interfaces ] );
  return $self;
}







sub add_interface {
  my ( $self, @items ) = @_;
  $self->_set_interface( [ uniq @{ $self->_interface }, @items ] );
  return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaPOD::Result - Compiled aggregate result object for MetaPOD

=head1 VERSION

version v0.4.0

=head1 METHODS

=head2 set_namespace

    $result->set_namespace( $namespace )

=head2 inherits

    my @inherits = $result->inherits;

=head2 set_inherits

    $result->set_inherits( @inherits )

=head2 add_inherits

    $result->add_inherits( @inherits );

=head2 does

    my @does = $result->does;

=head2 set_does

    $result->set_does( @does )

=head2 add_does

    $result->add_does( @does );

=head2 interface

    my @interfaces = $result->interface;

=head2 set_interface

    $result->set_interface( @interfaces )

=head2 add_interface

    $result->add_interface( @interface );

=begin MetaPOD::JSON v1.1.0

{
    "namespace": "MetaPOD::Result",
    "inherits" : "Moo::Object",
    "interface": "class"
}


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
