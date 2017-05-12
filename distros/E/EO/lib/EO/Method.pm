package EO::Method;

use strict;
use warnings;

use EO;
our @ISA = qw( EO );
our $VERSION = 0.96;

sub new_with_reference {
  my $class = shift;
  my $name = shift;
  my $ref  = shift;
  my $self = $class->new( @_ );
  $self->name( $name );
  $self->reference( $ref );
  return $self;
}

sub name {
  my $self = shift;
  if (@_) {
    $self->{ methodname } = shift;
    return $self;
  }
  return $self->{ methodname };
}

sub reference {
  my $self = shift;
  if (@_) {
    $self->{ methodreference } = shift;
    return $self;
  }
  return $self->{ methodreference };
}

sub code {
  my $self = shift;
  my $class = EO::Class->new_with_classname( 'B::Deparse' );
  eval {
    $class->load;
  };
  if (!$@) {
    my $b = B::Deparse->new();
    return $b->coderef2text( $self->reference );
  }
}

sub call {
  my $self = shift;
  $self->reference->( @_ );
}

1;

__END__

=head1 NAME

EO::Method - a class that represents methods

=head1 SYNOPSIS

  use EO::Method;

  $method = EO::Method->new();

  $method->name( 'foo' );
  my $name = $method->name;

  $method->reference( sub {} );
  my $ref = $method->reference;

  my $results = $method->call( @args );

  $method->new_with_reference( 'foo' => sub {} );

=head1 DESCRIPTION

EO::Method provides a representation of methods in a system.  In general objects
of this class will be created by instances of EO::Class.

=head1 INHERITANCE

EO::Method inherits from the EO class.

=head1 CONSTRUCTOR

=over 4

=item new_with_reference( NAME => CODEREF )

Returns an EO::Method object that has the name NAME and the reference CODEREF

=head1 METHODS

=over 4

=item name( [STRING] )

Gets and sets the methods name

=item reference( [CODEREF] )

Gets and sets the code that the method uses

=item call( LIST )

Calls the references with the arguments specified by LIST.

=back

=head1 SEE ALSO

EO::Class

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=head1 COPYRIGHT

Copyright 2003 Fotango Ltd. All Rights Reserved.

=cut



