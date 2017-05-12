package Fey::Meta::Attribute::FromSelect;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Moose;

extends 'Moose::Meta::Attribute';

with 'Fey::Meta::Role::FromSelect';

## no critic (Subroutines::ProhibitUnusedPrivateSubroutines)
sub _process_options {
    my $class   = shift;
    my $name    = shift;
    my $options = shift;

    $options->{lazy} = 1;

    $options->{default} = $class->_make_sub_from_select(
        $options->{select},
        $options->{bind_params},
        $options->{multi_column},
        $options->{isa},
    );

    return $class->SUPER::_process_options( $name, $options );
}

sub _new {
    my $class = shift;
    my $options = @_ == 1 ? $_[0] : {@_};

    my $self = $class->SUPER::_new($options);

    $self->{select}          = $options->{select};
    $self->{bind_params}     = $options->{bind_params};
    $self->{is_multi_column} = $options->{multi_column};

    return $self;
}
## use critic

# The parent class's constructor is not a Moose::Object-based
# constructor, so we don't want to inline one that is.
__PACKAGE__->meta()->make_immutable( inline_constructor => 0 );

## no critic (Modules::ProhibitMultiplePackages)
package    # hide from PAUSE
    Moose::Meta::Attribute::Custom::FromSelect;
sub register_implementation {'Fey::Meta::Attribute::FromSelect'}

1;

# ABSTRACT: An attribute metaclass for SELECT-based attributes

__END__

=pod

=head1 NAME

Fey::Meta::Attribute::FromSelect - An attribute metaclass for SELECT-based attributes

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  package MyApp::Song;

  has average_rating => (
      metaclass   => 'FromSelect',
      is          => 'ro',
      isa         => 'Float',
      select      => $select,
      bind_params => sub { $_[0]->song_id() },
  );

=head1 DESCRIPTION

This attribute metaclass allows you to set an attribute's default
based on a C<SELECT> query and optional bound parameters. This is a
fairly common need when writing ORM-based classes.

=head1 OPTIONS

This metaclass accepts two additional parameters in addition to the
normal Moose attribute options.

=over 4

=item * select

This must do the L<Fey::Role::SQL::ReturnsData> role. It is required.

=item * bind_params

This must be a subroutine reference, which when called will return an
array of bind parameters for the query. This subref will be called as
a method on the object which has the attribute. This is an optional
parameter.

=back

Note that this metaclass overrides any value you provide for "default"
with a subroutine that executes the query and gets the value it
returns.

=head1 METHODS

This class adds a few methods to those provided by
C<Moose::Meta::Attribute>:

=head2 $attr->select()

Returns the query object associated with this attribute.

=head2 $attr->bind_params()

Returns the bind_params subroutine reference associated with this
attribute, if any.

=head1 ArrayRef TYPES

By default, the C<SELECT> is expected to return just a single row with
one column. However, if you set the type of the attribute to ArrayRef
(or a subtype), then the select can return multiple rows, still with a
single column.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
