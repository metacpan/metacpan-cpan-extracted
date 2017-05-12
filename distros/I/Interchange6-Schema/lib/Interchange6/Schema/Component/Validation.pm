use utf8;

package Interchange6::Schema::Component::Validation;

=head1 NAME

Interchange6::Schema::Component::Validation

=head1 SYNOPSIS

  package My::Result;

  __PACKAGE__->load_components(qw(
    +Interchange6::Schema::Component::Validation
  ));

  sub validate {
    my $self = shift;
    my $schema = $self->result_source->schema;

    unless ( $self->some_column =~ /magic/ ) {
      $schema->throw_exception("some_column does not contain magic");
    }
  }

=head1 DESCRIPTION

This component allows validation of row attributes to be deferred until other components in the stack have been called. For example you might want to have the TimeStamp component called before validation so that datetime columns with set_on_create are defined before validation occurs. In this case your local_components call might look like;

__PACKAGE__->load_components(
    qw(TimeStamp +Interchange6::Schema::Component::Validation)
);

In order to fail validation the L</validation> method must throw an exception.

=cut

use strict;
use warnings;

use base 'DBIx::Class';

=head1 METHODS

=head2 validate

Called before insert or update action. Method should be overloaded by class which load this component. Validation failures should result in L<DBIx::Class::Schema::throw_exception|DBIx::Class::Schema/throw_exception> being called.

=cut

sub validate {
    # This method should be overloaded by calling class so this should never get
    # hit by Devel::Cover
    # uncoverable subroutine
    # uncoverable statement
    my $self = shift;
}

=head2 insert

Overload insert to call L</validate> before insert is performed.

=cut

sub insert {
    my ( $self, @args ) = @_;
    eval{ $self->validate };
    if ($@) {
        $self->result_source->schema->throw_exception($@);
    } 
    else {
        $self->next::method(@args);
    }
    return $self;
}

=head2 update

Overload update to call L</validate> before update is performed.

=cut

sub update {
    my ( $self, @args ) = @_;
    eval{ $self->validate };
    if ($@) {
        $self->result_source->schema->throw_exception($@);
    } 
    else {
        $self->next::method(@args);
    }
    return $self;
}

1;
