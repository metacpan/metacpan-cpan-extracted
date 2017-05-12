package KiokuDB::LiveObjects::TXNScope;
BEGIN {
  $KiokuDB::LiveObjects::TXNScope::AUTHORITY = 'cpan:NUFFIN';
}
$KiokuDB::LiveObjects::TXNScope::VERSION = '0.57';
use Moose;
# ABSTRACT: Transaction scope.

use Scalar::Util qw(weaken);

use namespace::clean -except => 'meta';

has entries => (
    isa => "ArrayRef",
    is  => "ro",
    default => sub { [] },
);

has live_objects => (
    isa => "KiokuDB::LiveObjects",
    is  => "ro",
    required => 1,
);

has parent => (
    isa => __PACKAGE__,
    is  => "ro",
);

sub push {
    my ( $self, @entries ) = @_;

    my $e = $self->entries;

    foreach my $entry ( @entries ) {
        push @$e, $entry;
        weaken($e->[-1]);
    }
}

sub rollback {
    my $self = shift;
    $self->live_objects->rollback_entries(grep { defined } splice @{ $self->entries });
}

sub DEMOLISH {
    my $self = shift;

    if ( my $l = $self->live_objects ) {
        if ( my $parent = $self->parent ) {
            $l->_set_txn_scope($parent);
        } else {
            $l->_clear_txn_scope();
        }
    }
}

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=encoding UTF-8

=head1 NAME

KiokuDB::LiveObjects::TXNScope - Transaction scope.

=head1 VERSION

version 0.57

=head1 SYNOPSIS

    $txn_scope = $live_objects->new_txn;

    $txn_scope->update_entries(@updated);

    $txn_scope->rollback;

=head1 DESCRIPTION

This is an auxiliary class used by transaction scoping to roll back entries
updated during a transaction when it is aborted.

This is used internally in L<KiokuDB/txn_do> and should not need to be used
directly.

=head1 ATTRIBUTES

=over 4

=item entries

An ordered log of updated entries.

=back

=head1 METHODS

=over 4

=item update_entries

Called by L<KiokuDB::LiveObjects/update_entries>. Adds entries to C<entries>.

=item rollback

Calls C<KiokuDB::LiveObjects/rollback_entries> with all the recorded entries.

=back

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
