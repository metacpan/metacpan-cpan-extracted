package Fey::Object::Iterator::FromSelect::Caching;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.47';

use Fey::ORM::Types qw( ArrayRef Bool );

use Moose;
use MooseX::SemiAffordanceAccessor;
use MooseX::StrictConstructor;

extends 'Fey::Object::Iterator::FromSelect';

has _cached_results => (
    traits   => ['Array'],
    is       => 'ro',
    isa      => ArrayRef [ArrayRef],
    lazy     => 1,
    default  => sub { [] },
    init_arg => undef,
    handles  => {
        _cache_result      => 'push',
        _get_cached_result => 'get',
    },

    # for cloning
    writer => '_set_cached_results',

    # for testability
    clearer => '_clear_cached_results',
);

has '_sth_is_exhausted' => (
    is       => 'rw',
    isa      => Bool,
    init_arg => undef,
);

override _get_next_result => sub {
    my $self = shift;

    my $result = $self->_get_cached_result( $self->index() );

    unless ($result) {

        # Some drivers (DBD::Pg, at least) will blow up if we try to
        # call a ->fetch type method on an exhausted statement
        # handle. DBD::SQLite can handle this, so it is not tested.
        return if $self->_sth_is_exhausted();

        $result = super();

        unless ($result) {
            $self->_set_sth_is_exhausted(1);
            return;
        }

        $self->_cache_result($result);
    }

    return $result;
};

## no critic (Subroutines::ProhibitBuiltinHomonyms)
sub reset {
    my $self = shift;

    $self->_reset_index();
}
## use critic

sub clone {
    my $self = shift;

    my $clone = $self->meta()->clone_object($self);

    # It'd be nice to actually share the array reference between
    # multiple objects, but that causes problems because the sth may
    # not be shared (if it has not yet been created). That means that
    # the two sth's pull the same data twice and stuff it into the
    # same array reference, so the data ends up in there twice.
    $clone->_set_cached_results( [ @{ $self->_cached_results() } ] );

    $clone->_set_sth( $self->sth() )
        if $self->_has_sth();

    $clone->_set_sth_is_exhausted(1)
        if $self->_sth_is_exhausted();

    $clone->reset();

    return $clone;
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: A caching subclass of Fey::Object::Iterator::FromSelect

__END__

=pod

=head1 NAME

Fey::Object::Iterator::FromSelect::Caching - A caching subclass of Fey::Object::Iterator::FromSelect

=head1 VERSION

version 0.47

=head1 SYNOPSIS

  use Fey::Object::Iterator::FromSelect::Caching;

  my $iter = Fey::Object::Iterator::FromSelect::Caching->new(
      classes     => 'MyApp::User',
      select      => $select,
      dbh         => $dbh,
      bind_params => \@bind,
  );

  print $iter->index();    # 0

  while ( my $user = $iter->next() ) {
      print $iter->index();    # 1, 2, 3, ...
      print $user->username();
  }

  # will return cached objects now
  $iter->reset();

=head1 DESCRIPTION

This class implements a caching subclass of
L<Fey::Object::Iterator::FromSelect>. This means that it caches
objects it creates internally. When C<< $iterator->reset() >> is
called it will re-use those objects before fetching more data from the
DBMS.

=head1 METHODS

This class provides the following methods:

=head2 $iterator->reset()

Resets the iterator so that the next call to C<< $iterator->next() >>
returns the first objects. Internally, this I<does not> reset the
L<DBI> statement handle, it simply makes the iterator use cached
objects.

=head2 $iterator->clone()

Clones the iterator while sharing its cached data with the original
object. This is really intended for internal use, so I<use at your own
risk>.

=head1 ROLES

This class does the L<Fey::ORM::Role::Iterator> role.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 - 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
