package KiokuDB::Backend::Role::TXN::Memory::Scan;
BEGIN {
  $KiokuDB::Backend::Role::TXN::Memory::Scan::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::Backend::Role::TXN::Memory::Scan::VERSION = '0.57';
use Moose::Role;

use Data::Stream::Bulk::Util qw(bulk);

use namespace::clean -except => 'meta';

with qw(
    KiokuDB::Backend::Role::TXN::Memory
    KiokuDB::Backend::Role::Clear
    KiokuDB::Backend::Role::Scan
);

requires qw(
    all_storage_entries
    clear_storage
);

sub clear {
    my $self = shift;

    if ( @{ $self->_txn_stack } ) {
        %{ $self->_txn_stack->[-1] } = ( %{ $self->_new_frame }, cleared => 1 );
    } else {
        $self->clear_storage;
    }
}

sub all_entries {
    my $self = shift;

    my $stack = $self->_txn_stack;

    if ( @$stack ) {
        my $frame = $stack->[-1];

        my $flat = $self->_collapsed_txn_stack;

        my $live = bulk(grep { not $_->deleted } values %{ $flat->{live} });

        if ( $flat->{cleared} ) {
            # return all the inserted entries since the clear
            return $live;
        } else {
            my $all = $self->all_storage_entries;

            # create a filter for all the IDs that have been either deleted or superseded in the transaction frame
            my %mask; @mask{ keys %{ $flat->{live} } } = ();

            my $shadowed = keys %mask ? $all->filter(sub {[ grep { not exists $mask{$_->id} } @$_ ]}) : $all;

            # make note of all read entries in the transaction frame
            my $noted_shadowed = $shadowed->filter(sub {
                @{ $frame->{live} }{ map { $_->id } @$_ } = @$_;
                return $_;
            });

            return $live->cat($noted_shadowed);
        }
    } else {
        return $self->all_storage_entries;
    }
}


# ex: set sw=4 et:

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::Backend::Role::TXN::Memory::Scan

=head1 VERSION

version 0.57

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
