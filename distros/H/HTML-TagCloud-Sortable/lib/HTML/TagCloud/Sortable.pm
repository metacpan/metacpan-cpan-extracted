package HTML::TagCloud::Sortable;

use strict;
use warnings;

use base qw( HTML::TagCloud );

our $VERSION = '0.04';

=head1 NAME

HTML::TagCloud::Sortable - A sortable HTML tag cloud

=head1 SYNOPSIS

    my $cloud = HTML::TagCloud::Sortable->new;
    
    # old HTML::TagCloud style
    $cloud->add( 'foo', $url, 10 );
    
    # new HTML::TagCloud::Sortable style
    $cloud->add( { name => 'foo', url => $url, count => 10, bar => 'baz' } );
    
    # old style
    print $cloud->html( 4 );
    
    # new style
    print $cloud->html( { limit => 4, sort_field => 'count', sort_type => 'numeric' } );

=head1 DESCRIPTION

HTML::TagCloud::Sortable is an API-compatible subclass of L<HTML::TagCloud>.
However, by using a different API, you can gain two features:

=over 4

=item * Store arbitrary data with your tags

=item * Sort the tags by any stored field

=back

=head1 METHODS

=head2 new( %options )

An overridden construtor. Takes the same arguments as L<HTML::TagCloud>.

=cut

sub new {
    my $self = shift->SUPER::new( @_ );
    $self->{ tags } = [];
    delete $self->{ urls };
    return $self;
}

=head2 add( \%tagdata )

Adds the hashref of data to the list of tags. NB: Insertion order is
maintained. At the minimum, you will need to supply C<name>, C<url> and
C<count> key-value pairs.

=cut

sub add {
    my ( $self, @args ) = @_;

    my ( $tag, $count );
    if ( ref $args[ 0 ] ) {
        push @{ $self->{ tags } }, $args[ 0 ];
        $tag   = $args[ 0 ]->{ name };
        $count = $args[ 0 ]->{ count };
    }
    else {
        my $url;
        ( $tag, $url, $count ) = @args;
        push @{ $self->{ tags } },
            { name => $tag, count => $count, url => $url };
    }

    $self->{ counts }->{ $tag } = $count;
}

=head2 tags( \%options )

This method is used by C<html> to get the relevant list of tags for display.
Options include:

=over 4

=item * limit - uses the N most popular tags

=item * sort_field - sort by this field

=item * sort_order - 'asc' or 'desc'

=item * sort_type - 'alpha' or 'numeric'

=back

The default sort order is alphabetically by tag name. You can pass a sub reference
to C<sort_field> to do custom sorting. Example:

    $cloud->html( { sort_field =>
        sub { $_[ 1 ]->{ count } <=> $_[ 0 ]->{ count }; }
    } );

Passing undef to sort_field will maintain insertion order.

=cut

my %sorts = (
    alpha => {
        asc => sub {
            my $f = shift;
            return sub { $_[ 0 ]->{ $f } cmp $_[ 1 ]->{ $f } }
        },
        desc => sub {
            my $f = shift;
            return sub { $_[ 1 ]->{ $f } cmp $_[ 0 ]->{ $f } }
        },
    },
    numeric => {
        asc => sub {
            my $f = shift;
            return sub { $_[ 0 ]->{ $f } <=> $_[ 1 ]->{ $f } }
        },
        desc => sub {
            my $f = shift;
            return sub { $_[ 1 ]->{ $f } <=> $_[ 0 ]->{ $f } }
        },
    },
);

sub tags {
    my ( $self, @args ) = @_;

    my %options;
    if ( defined $args[ 0 ] ) {
        if ( !ref $args[ 0 ] ) {
            $options{ limit } = shift @args;
        }
        else {
            %options = %{ $args[ 0 ] };
        }
    }

    $options{ sort_field } = 'name'  if !exists $options{ sort_field };
    $options{ sort_type }  = 'alpha' if !$options{ sort_type };
    $options{ sort_order } = 'asc'   if !$options{ sort_order };

    my ( @tags, @counts );

    if ( defined( my $limit = $options{ limit } ) ) {
        my @sorted = ( sort { $b->{ count } <=> $a->{ count } }
                @{ $self->{ tags } } );
        my %top = map { $_->{ name } => $_->{ count } }
            splice( @sorted, 0, $limit );
        @counts = ( sort { $b <=> $a } values %top );
        @tags = grep { exists $top{ $_->{ name } } } @{ $self->{ tags } };
    }
    else {
        @tags = @{ $self->{ tags } };
        @counts = ( sort { $b->{ count } <=> $a->{ count } }
                @{ $self->{ tags } } );
    }

    return unless scalar @tags;

    my $min = log( $counts[ -1 ] );
    my $max = log( $counts[ 0 ] );
    my $factor;

    # special case all tags having the same count
    if ( $max - $min == 0 ) {
        $min    = $min - $self->{ levels };
        $factor = 1;
    }
    else {
        $factor = $self->{ levels } / ( $max - $min );
    }

    if ( scalar @tags < $self->{ levels } ) {
        $factor *= ( scalar @tags / $self->{ levels } );
    }

    if ( my $sort = $options{ sort_field } ) {

        if ( !ref $sort ) {
            my $newsort = $sorts{ lc $options{ sort_type } }
                { lc $options{ sort_order } }->( $sort );
            $sort = $sort ne 'name'
                ? sub {
                $newsort->( @_ ) || $_[ 0 ]->{ name } cmp $_[ 1 ]->{ name };
                }
                : $newsort;
        }

        my $oldsort = $sort;
        $sort = sub { $oldsort->( $a, $b ); };
        @tags = sort $sort @tags;
    }

    for my $tag ( @tags ) {
        $tag->{ level } = int( ( log( $tag->{ count } ) - $min ) * $factor );
    }

    return @tags;
}

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2007-2009 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=head1 SEE ALSO

=over 4 

=item * L<HTML::TagCloud>

=back

=cut

1;
