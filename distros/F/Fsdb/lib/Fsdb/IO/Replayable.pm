#!/usr/bin/perl

#
# Fsdb::IO::Replayable.pm
# Copyright (C) 2007-2008 by John Heidemann <johnh@isi.edu>
# $Id: f32b4b55b6822dc8038d31e8123af0a099f77752 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#


package Fsdb::IO::Replayable;

=head1 NAME

Fsdb::IO::Replayable - support for buffering fsdb rows

=head1 SYNOPSIS

Buffer and replaying fsdb rows

=head1 FUNCTIONS

=head2 new

    $replayable = new Fsdb::IO::Replayable(-writer_args => \@writer_args,
	-reader_args => \@reader_args);
    $writer = $replayable->writer;
    $replayable->close;  # warning: close replayable, NOT writer
    $reader = $replayable->reader;

Creates a buffer for Fsdb::IO objects that will run with bounded memory usage.
After you close it, you can replay it one or more times by opening readers.

Arguments to the new method:

=over 4

=item -writer_args => @arref
Gives arguments to pass to Fsdb::IO::Writer to make a new stream.

=item -reader_args => @arref
Gives arguments to pass to Fsdb::IO::Reader to make a new stream.

=item -tmpdir => $dirname
Specifies wher tmpfiles go.

=back

=cut

@ISA = ();
($VERSION) = 1.0;

use Carp;
use Fsdb::Support::NamedTmpfile;

sub new {
    my $class = shift @_;
    my $self = bless {
	_tmpdir => undef,
	_reader_args => [],
	_writer_args => [],

	_filename => undef,
	_writer => undef,

	_write_version => 0,  # can write if write>0
	_read_version => 0,  # can read if read>0 && read==write
    }, $class;

    my(@args) = @_;
    while ($#args >= 0) {
	my($key) = shift @args;
	my($value) = shift @args;
	if ($key eq '-writer_args') {
	    $self->{_writer_args} = $value;
	} elsif ($key eq '-reader_args') {
	    $self->{_reader_args} = $value;
	} elsif ($key eq '-tmpdir') {
	    $self->{_tmpdir} = $value;
	} else {
	    croak "Fsdb::IO::Replayable: unknown argument $key\n";
	};
    };

    $self->{_filename} = Fsdb::Support::NamedTmpfile::alloc($self->{_tmpdir});

    return $self;
}


=head2 writer

    $writer = $replayable->writer;

Return a fsdb writer object.  If the file was written already,
resets it for rewriting.

=cut

sub writer {
    my $self = shift @_;

    $self->{_write_version}++;
    $self->{_writer} = new Fsdb::IO::Writer(-file => $self->{_filename}, @{$self->{_writer_args}});
    return $self->{_writer};
}

=head2 close

    $replayable->close;

Close the replayable for writing.
Closes the writer object, if any.
Allows reading to start.

=cut

sub close {
    my $self = shift @_;

    croak "Fsdb::IO::Replayable: close called without open writer.\n"
	if (!defined($self->{_writer}));
    $self->{_writer}->close;
    $self->{_writer} = undef;
    $self->{_read_version} = $self->{_write_version};
}

=head2 reader

    $reader = $replayable->reader;

Return a fsdb reader object to re-read the file.
Can be called once.

The caller is expected to close and discard any readers.

=cut

sub reader {
    my $self = shift @_;

    croak "Fsdb::IO::Replayable: reader called without ever having a writer.\n"
	if ($self->{_read_version} == 0);
    croak "Fsdb::IO::Replayable: reader called without closed writer.\n"
	if ($self->{_read_version} != $self->{_write_version});

    my $reader = new Fsdb::IO::Reader(-file => $self->{_filename}, @{$self->{_reader_args}});
    return $reader;
}


1;
