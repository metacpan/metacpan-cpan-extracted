package Katsubushi::Converter;
use strict;
use warnings;

no warnings "portable";

# see https://github.com/kayac/go-katsubushi/blob/master/generator.go#L12-L20
use constant {
    WORKER_ID_BITS  => 10,
    SEQUENCE_BITS   => 12,
    TIMESTAMP_SINCE => 1420070400000,
    TIMESTAMP_MASK  => 0x7FFFFFFFFFC00000,
};

sub id_to_epoch {
    my ($id) = @_;

    return int(id_to_epoch_msec($id) / 1000);
}

sub id_to_epoch_msec {
    my ($id) = @_;

    return ((($id & TIMESTAMP_MASK) >> (WORKER_ID_BITS + SEQUENCE_BITS)) + TIMESTAMP_SINCE);
}

sub epoch_to_id {
    my ($epoch) = @_;

    return epoch_msec_to_id($epoch * 1000);
}

sub epoch_msec_to_id {
    my ($epoch_msec) = @_;

    return ($epoch_msec - TIMESTAMP_SINCE) << (WORKER_ID_BITS + SEQUENCE_BITS);
}

1;

=head NAME

Katsubushi::Converter - id converter issued by katsubushi

=head1 SYNOPSIS

    use Katsubushi::Converter

    my $epoch = Katsubushi::Converter::id_to_epoch($id);
    print "id=${id} issued at ${epoch} in unix epoch time"

=head1 DESCRIPTION

This module provides methods to convert id issued by katsubushi.

katsubushi is id generator written in Go.
github.com/kayac/go-katsubushi

=head1 METHODS

=over 4

=item C<< $epoch = id_to_epoch($id) >>

=item C<< $epoch_msec = id_to_epoch_msec($id) >>

Convert id to epoch in seconds/milliseconds.

=item C<< $id = epoch_to_id($epoch) >>

=item C<< $id = epoch_msec_to_id($epoch_msec) >>

Convert epoch seconds/milliseconds to id.
This method assume that WorkerID and Sequense are both 0.

=back

=head1 AUTHOR

NAGATA Hiroaki <handlename>
