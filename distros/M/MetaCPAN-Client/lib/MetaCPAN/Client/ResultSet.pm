use strict;
use warnings;
package MetaCPAN::Client::ResultSet;
# ABSTRACT: A Result Set
$MetaCPAN::Client::ResultSet::VERSION = '2.017000';
use Moo;
use Carp;

use MetaCPAN::Client::Types qw< ArrayRef >;

has type => (
    is       => 'ro',
    isa      => sub {
        croak 'Invalid type' unless
            grep { $_ eq $_[0] } qw<author distribution favorite
                                   file module rating release mirror>;
    },
    required => 1,
);

# in case we're returning from a scrolled search
has scroller => (
    is        => 'ro',
    isa       => sub {
        use Safe::Isa;
        $_[0]->$_isa('MetaCPAN::Client::Scroll')
            or croak 'scroller must be an MetaCPAN::Client::Scroll object';
    },
    predicate => 'has_scroller',
);

# in case we're returning from a fetch
has items => (
    is  => 'ro',
    isa => ArrayRef,
);

has total => (
    is      => 'ro',
    default => sub {
        my $self = shift;

        return $self->has_scroller ? $self->scroller->total
                                   : scalar @{ $self->items };
    },
);

sub BUILDARGS {
    my ( $class, %args ) = @_;

    exists $args{scroller} or exists $args{items}
        or croak 'ResultSet must get either scroller or items';

    exists $args{scroller} and exists $args{items}
        and croak 'ResultSet must get either scroller or items, not both';

    return \%args;
}

sub next {
    my $self   = shift;
    my $result = $self->has_scroller ? $self->scroller->next
                                     : shift @{ $self->items };

    defined $result or return;

    my $class = 'MetaCPAN::Client::' . ucfirst $self->type;
    return $class->new_from_request( $result->{'_source'} || $result->{'fields'} || $result );
}

sub aggregations {
    my $self = shift;

    return $self->has_scroller ? $self->scroller->aggregations : {};
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MetaCPAN::Client::ResultSet - A Result Set

=head1 VERSION

version 2.017000

=head1 DESCRIPTION

Object representing a result from Elastic Search. This is used for the complex
(as in L<non-simple/MetaCPAN::Client/"SEARCH SPEC">) queries to MetaCPAN. It
provides easy access to the scroller and aggregations.

=head1 ATTRIBUTES

=head2 scroller

An L<MetaCPAN::Client::Scroll> object.

=head2 items

An arrayref of items to manually scroll over, instead of a scroller object.

=head2 type

The entity of the result set. Available types:

=over 4

=item * author

=item * distribution

=item * module

=item * release

=item * favorite

=item * file

=back

=head2 aggregations

The aggregations available in the Elastic Search response.

=head1 METHODS

=head2 next

Iterator call to fetch the next result set object.

=head2 total

Iterator call to fetch the total amount of objects available in result set.

=head2 has_scroller

Predicate for ES scroller presence.

=head2 BUILDARGS

Double checks construction of objects. You should never run this yourself.

=head1 AUTHORS

=over 4

=item *

Sawyer X <xsawyerx@cpan.org>

=item *

Mickey Nasriachi <mickey@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Sawyer X.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
