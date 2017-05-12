package Fey::Meta::Method::FromSelect;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Moose;

extends 'Moose::Meta::Method', 'Class::MOP::Method::Generated';

with 'Fey::Meta::Role::FromSelect';

## no critic (Moose::ProhibitNewMethod)
sub new {
    my $class   = shift;
    my %options = @_;

    ( $options{package_name} && $options{name} )
        || confess
        "You must supply the package_name and name parameters $Class::MOP::Method::UPGRADE_ERROR_TEXT";

    $options{select}
        || confess 'You must supply a select query';

    my $self = $class->_new( \%options );

    $self->_initialize_body;

    return $self;
}
## use critic

sub _new {
    my $class = shift;
    my $options = @_ == 1 ? $_[0] : {@_};

    return bless $options, $class;
}

sub _initialize_body {
    my $self = shift;

    $self->{body} = $self->_make_sub_from_select(
        $self->select(),
        $self->bind_params(),
        $self->is_multi_column(),
    );

}

__PACKAGE__->meta()->make_immutable( inline_constructor => 0 );

1;

# ABSTRACT: A method metaclass for SELECT-based methods

__END__

=pod

=head1 NAME

Fey::Meta::Method::FromSelect - A method metaclass for SELECT-based methods

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  package MyApp::Song;

  query average_rating => (
      select      => $select,
      bind_params => sub { $_[0]->song_id() },
  );

=head1 DESCRIPTION

This method metaclass allows you to generate a method based on a C<SELECT>
query and an optional C<bind_params> subroutine reference.

=head1 OPTIONS

This metaclass accepts two additional parameters in addition to the
normal Moose method options.

=over 4

=item * select

This must do the L<Fey::Role::SQL::ReturnsData> role. It is required.

=item * bind_params

This must be a subroutine reference, which when called will return an array of
bind parameters for the query. This subref will be called as a method on the
object which has the method. This is an optional parameter.

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

=head1 WANTARRAY

The generated method will use DBI's C<selectcol_arrayref()> method to fetch
data from the database. If called in a list context, it returns all the values
it retrieves. In scalar context, it returns just the first value.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
