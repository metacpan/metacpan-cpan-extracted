# Copyright (c) 2025 Löwenfelsen UG (haftungsbeschränkt)

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Module for interacting with file stores


package File::FStore::Base;

use v5.10;
use strict;
use warnings;

use Carp;

our $VERSION = v0.05;


sub contentise {
    my ($self, %opts) = @_;
    my $as = delete($opts{as}) // 'uuid';

    croak 'Stray options passed' if scalar keys %opts;
    confess 'No contentise known for this file' unless defined $self->{contentise};

    return $self->{contentise}->as($as,
        db => $self->db(default => undef),
        extractor => $self->extractor(default => undef),
    );
}


sub ise {
    my ($self, @args) = @_;
    return $self->contentise(@args);
}


sub as {
    my ($self, $as, %opts) = @_;
    $opts{store} //= $self->{store};
    return $self->Data::Identifier::as($as, %opts);
}


#@returns File::FStore
sub store {
    my ($self) = @_;
    return $self->{store};
}


#@returns Data::TagDB
sub db {
    my ($self, %opts) = @_;
    return $self->{db} //= $self->store->db(%opts);
}


#@returns Data::URIID
sub extractor {
    my ($self, %opts) = @_;
    return $self->{extractor} //= $self->store->extractor(%opts);
}


sub fii {
    my ($self) = @_;
    return $self->{fii} //= $self->store->fii;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::FStore::Base - Module for interacting with file stores

=head1 VERSION

version v0.05

=head1 SYNOPSIS

    use File::FStore;

    my File::FStore::Base $obj = ...;

This package is the base package for other packages, containing common methods.

=head1 METHODS

=head2 contentise

    my $ise = $file->contentise;
    # or:
    my $ise = $file->contentise(as => ...);

Returns the content based ISE (identifier) for the file.
This can be used as a primary key for the given file in databases.
It is globally unique (so can be transfered to unrelated systems without the worry of collisions).

Takes a single optional option C<as> which is documented in L<Data::Identifier/as>.
Defaulting to C<uuid>.

B<Note:>
Calculation of this identifier requires the values for C<size> from the C<properties> domain
and the values for C<sha-1-160> and C<sha-3-512> from the C<digests> domain.

B<Note:>
This value is only available on files that are in final state.
For L<File::FStore::Adder> this means the file file must at least be L<File::FStore::Adder/done>.

=head2 ise

    my $ise = $file->ise;
    # or:
    my $ise = $file->ise(%opts);

Returns an ISE (identifier) for this file.

Currently an alias for L</contentise>. Later versions may add more logic.

=head2 as

    my $xxx = $base->as($as, [ %opts ] );

Proxy for L<Data::Identifier/as>.

Automatically adds C<store> to C<%opts> if any is known (see L</store>).

=head2 store

    my File::FStore $store = $file->store;

Returns the store this file belongs to.

=head2 db

    my Data::TagDB $db = $file->db;
    # or:
    my Data::TagDB $db = $file->db(default => $def);

Proxy for L<File::FStore/db>.

=head2 extractor

    my Data::URIID $extractor = $file->extractor;
    # or:
    my Data::URIID $extractor = $file->extractor(default => $def);

Proxy for L<File::FStore/extractor>.

=head2 fii

    my File::Information $fii = $file->fii;

Proxy for L<File::FStore/fii>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
