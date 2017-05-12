package Hash::Storage::Driver::Memory;

our $VERSION = '0.03';

use v5.10;
use strict;
use warnings;

use File::Slurp;
use Storable qw/dclone/;

use base 'Hash::Storage::Driver::Base';

sub init {
    my ($self) = @_;
    $self->{data} = {};
}

sub get {
    my ( $self, $id ) = @_;
    my $hashes = $self->{data};
    my $hash = $hashes->{$id};

    return unless $hash;
    return dclone($hash);
}

sub set {
    my ( $self, $id, $fields ) = @_;
    my $hashes = $self->{data};

    @{ $hashes->{$id} }{ keys %$fields } = values %$fields;
}

sub del {
    my ( $self, $id ) = @_;
    my $hashes = $self->{data};

    delete $hashes->{$id};
}

sub list {
    my ( $self, @query ) = @_;
    my $hashes = $self->{data};

    my @hashes = values %$hashes;
    my $filtered = $self->do_filtering(\@hashes, \@query);
    return dclone $filtered;
}

sub count {
    my ( $self, $filter ) = @_;
    my $hashes = $self->list(where => $filter);
    return scalar(@$hashes);
}

1;    # End of Hash::Storage
