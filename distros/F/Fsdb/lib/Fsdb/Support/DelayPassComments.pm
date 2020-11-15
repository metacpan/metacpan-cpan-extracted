#!/usr/bin/perl

#
# Fsdb::Support::DelayPassComments.pm
# Copyright (C) 2007 by John Heidemann <johnh@isi.edu>
# $Id: e2fb010c7ca0b5463de954715d29202803f1f8a7 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#


package Fsdb::Support::DelayPassComments;

=head1 NAME

Fsdb::Support::DelayPassComments - support for buffering comments

=head1 SYNOPSIS

Buffer and send out comments

=head1 FUNCTIONS

=head2 new

    $filter->{_delay_pass_comments} = new Fsdb::Support::DelayPassComments;

or more likely, one uses it indirectly with Fsdb::Filter and Fsdb::IO::Reader:

    $self->{_in} = finish_io_options('input', -comment_handler => create_delay_pass_comments_sub);
    $self->{_out} = new Fsdb::IO::Writer(...);
    ...
    # in Fsdb::Filter
    $self->{_delay_comments}->flush($self->{_out};

Creates a buffer for comments that will run with bounded memory usage.
New requires the output stream, a Fsdb::IO::Writer object.
Fsdb::Filter will dump these after all other output.

=cut

@ISA = ();
($VERSION) = 1.0;

use Carp;

sub new {
    my $class = shift @_;
    my $fsdb_out = shift @_;
    my($queue_ref) = [ 0 ];  # first element is byte count of buffered data,
			    # or an IO::Handle of the on-disk buffer.
    my $self = bless $queue_ref, $class;
    return $self;
}

=head2 enqueue

    $dpc->enqueue($comment [, $other_comments...])

Save up the $COMMENT.

=cut

sub enqueue {
    my $self = shift @_;
    foreach (@_) {
	if (ref($self->[0])) {
	    # going to disk
	    $self->[0]->print($_);
	    next;
	};
	push(@$self, $_);
	$self->[0] += length($_);
	$self->spill_to_disk if ($self->[0] > 10000);
    };
}

=head2 spill_to_disk

    $dpc->spill_to_disk

Internal: switch from in-memory caching to disk caching.

=cut

sub spill_to_disk {
    my $self = shift @_;
    my $fh = IO::File::new_tmpfile;
    croak "delayed_pass_comments: cannot create tmpfile"
	if (!defined($fh));
    shift @$self;   # eat the byte count
    # write everything so far to disk
    foreach (@{$self}) {
	print $fh $_;
    };
    # switch over
    $self->[0] = $fh;
    $#{$self} = 0;   # who knew $#a was writable?  Apparently the perlfunc man page...
}

=head2 flush

    $dpc->flush($output_fsdb);

Dump all saved comments to the saved Fsdb::IO::Writer,
or if C<$OUTPUT_FSDB> is undef, then to stdout.

=cut

sub flush {
    my $self = shift @_;
    my $fsdb = shift @_;

    return if ($#{$self} == 0);   # nothing queued
    if (!ref($self->[0])) {
        # in memory
	shift @$self;  # eat the size count
	foreach (@$self) {
	    if (defined($fsdb)) {
		$fsdb->write_raw($_);
	    } else {
		print $_;
	    };
	};
    } else {
	# on disk
	my $fh = shift @$self;
	$fh->seek(0, 0);  # rewind to start
	my($line);
	while (defined($line = $fh->getline)) {
	    if (defined($fsdb)) {
		$fsdb->write_raw($line);
	    } else {
		print $line;
	    };
	};
	$fh->close;
    }
    # reset to in-memory with no data
    $self->[0] = 0;
}

1;
