# Copyright (c) 2025-2026 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: Module for interacting with file stores


package File::FStore::Base;

use v5.10;
use strict;
use warnings;

use Carp;

use parent qw(Data::Identifier::Interface::Userdata Data::Identifier::Interface::Subobjects);

our $VERSION = v0.07;


sub contentise {
    my ($self, %opts) = @_;
    my $as = delete($opts{as}) // 'uuid';

    croak 'Stray options passed' if scalar keys %opts;
    confess 'No contentise known for this file' unless defined $self->{contentise};

    return $self->{contentise}->as($as,
        db        => $self->so_get('db', default => undef, no_defaults => 1),
        extractor => $self->so_get('extractor', default => undef, no_defaults => 1),
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


#@deprecated
sub db {
    my ($self, %opts) = @_;
    return $self->{db} //= $self->store->db(%opts);
}


#@deprecated
sub extractor {
    my ($self, %opts) = @_;
    return $self->{extractor} //= $self->store->extractor(%opts);
}


sub fii {
    my ($self) = @_;
    return $self->{fii} //= $self->store->fii;
}

# ---- Private helpers ----

sub _new {
    my ($pkg, %opts) = @_;
    my $self = bless \%opts, $pkg;

    croak 'No store is given' unless defined $self->{store};

    $self->so_attach(parent => $self->{store});

    return $self;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::FStore::Base - Module for interacting with file stores

=head1 VERSION

version v0.07

=head1 SYNOPSIS

    use File::FStore;

    my File::FStore::Base $obj = ...;

This package is the base package for other packages, containing common methods.

This package inherits from L<Data::Identifier::Interface::Userdata>, and L<Data::Identifier::Interface::Subobjects>.

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

(since v0.04, deprecated since v0.07, will be removed in v0.10, may warn).

This is deprecated. See L<Data::Identifier::Interface::Subobjects/so_get> for a replacement.

Deprecated proxy for L<File::FStore/db>.

=head2 extractor

    my Data::URIID $extractor = $file->extractor;
    # or:
    my Data::URIID $extractor = $file->extractor(default => $def);

(since v0.04, deprecated since v0.07, will be removed in v0.10, may warn).

This is deprecated. See L<Data::Identifier::Interface::Subobjects/so_get> for a replacement.

Deprecated proxy for L<File::FStore/extractor>.

=head2 fii

    my File::Information $fii = $file->fii;

(since v0.01, experimental since v0.07)

Proxy for L<File::FStore/fii>.
See there for information on the status of this method.

=head1 AUTHOR

Philipp Schafft <lion@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2025-2026 by Philipp Schafft <lion@cpan.org>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
