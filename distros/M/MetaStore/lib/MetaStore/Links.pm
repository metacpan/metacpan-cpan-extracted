package MetaStore::Links;

=head1 NAME

MetaStore::Links - Class for links collections.

=head1 SYNOPSIS

    use MetaStore::Links;


=head1 DESCRIPTION

Class for links collections.

=head1 METHODS

=cut

use MetaStore::Item;
use Data::Dumper;
use strict;
use warnings;

our @ISA     = qw( MetaStore::Item );
our $VERSION = '0.01';

=head2 types

Return list for current types
=cut

sub types {
    return [ keys %{ $_[0]->attr } ];
}

=head2 by_type ( $link_type )

Get ids list for type

=cut

sub by_type {
    my $self = shift;
    my $type = shift;
    my $attr = $self->attr;
    my @res  = ();
    if ( defined $type ) {
        @res = @{ $attr->{$type} || [] } if exists $attr->{$type};
    }
    else {
        my %uniq;
        foreach my $key ( sort { $a <=> $b } keys %$attr ) {
            push @res, grep { !$uniq{$_}++ } @{ $self->by_type($key) };
        }
    }
    \@res;
}

=head2 add_by_type ( <type>, item_id1[, item_id2[, item_id3]])

Add items by type.

=cut

sub add_by_type {
    my $self = shift;
    my $type = shift;
    return unless defined $type;
    my %uniq;
    my @res  = ();
    my $attr = $self->attr;
    @res = grep { !$uniq{$_}++ } @{ $self->by_type($type) }, @_;
    $attr->{$type} = \@res;
    \@res;
}

=head2 delete_by_type ( $type[, item_id1[, item_id2[,item_id3]]])

Delete ids list , by type. Return result state of list;

=cut

sub delete_by_type {
    my $self = shift;
    my $type = shift;
    my $ids  = $self->by_type($type);
    return $ids unless ( scalar @_ );
    my %uniq;
    @uniq{@_} = ();
    $self->set_by_type( $type, grep { !exists $uniq{$_} } @$ids );
}

=head2 set_by_type( $type[, item_id1[, item_id2[,item_id3]]])

Set new list for $type. Set empty list unless got item_ids.

=cut

sub set_by_type {
    my $self = shift;
    my $type = shift;
    return [] unless defined $type;
    unless ( scalar @_ ) {
        delete $self->attr->{$type};
        $self->by_type($type);
    }
    else {

        #clear list for type
        $self->set_by_type($type);
        $self->add_by_type( $type, @_ );
    }
}

=head2  empty 

Empty all links

=cut

sub empty {
    my $self = shift;
    %{ $self->attr } = ();
    return $self->by_type;
}

1;
__END__

=head1 SEE ALSO

MetaStore, Collection::Item, README

=head1 AUTHOR

Zahatski Aliaksandr, E<lt>zag@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2006 by Zahatski Aliaksandr

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

