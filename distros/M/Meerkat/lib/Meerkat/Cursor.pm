use v5.10;
use strict;
use warnings;

package Meerkat::Cursor;
# ABSTRACT: Wrap MongoDB::Cursor to inflate data to objects

our $VERSION = '0.015';

# Dependencies
use Moose 2;
use Try::Tiny::Retry 0.002 qw/:all/;

#pod =attr cursor (required)
#pod
#pod A L<MongoDB::Cursor> object
#pod
#pod =cut

has cursor => (
    is       => 'ro',
    isa      => 'MongoDB::Cursor',
    required => 1,
    handles  => [
        qw( fields sort limit tailable skip snapshot hint ),
        qw( explain count reset has_next next info all immortal),
    ],
);

#pod =attr collection (required)
#pod
#pod A L<Meerkat::Collection> used for inflating results.
#pod
#pod =cut

has collection => (
    is       => 'ro',
    isa      => 'Meerkat::Collection',
    required => 1,
);

around 'next' => sub {
    my $orig = shift;
    my $self = shift;

    my $data =
      retry { $self->$orig },
      retry_if { /not connected/ },
      delay_exp { 5, 1e6 },
      on_retry { $self->mongo_clear_caches };

    if ($data) {
        return $self->collection->thaw_object($data);
    }
    else {
        return;
    }
};

1;


# vim: ts=4 sts=4 sw=4 et:

__END__

=pod

=encoding UTF-8

=head1 NAME

Meerkat::Cursor - Wrap MongoDB::Cursor to inflate data to objects

=head1 VERSION

version 0.015

=head1 SYNOPSIS

  use Meerkat::Cursor;

=head1 DESCRIPTION

When a L<Meerkat::Collection> method returns a query cursor, it provides this
proxy for a L<MongoDB::Cursor>.  See documentation of that module for usage
information.

The only difference is that the C<next> method will return objects of the class
associated with the originating L<Meerkat::Collection>.

=head1 ATTRIBUTES

=head2 cursor (required)

A L<MongoDB::Cursor> object

=head2 collection (required)

A L<Meerkat::Collection> used for inflating results.

=for Pod::Coverage method_names_here

=head1 AUTHOR

David Golden <dagolden@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
