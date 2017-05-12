
=head1 NAME

JSON::Streaming::Reader::EventWrapper - Internal utility package for JSON::Streaming::Reader

=cut

package JSON::Streaming::Reader::EventWrapper;

use strict;
use warnings;

# Make a dummy ref that can be used as a singleton exception to signal a buffer underrun.
use constant UNDERRUN => {};

sub new {
    my ($class) = @_;

    my $self = bless {}, $class;

    $self->{buffer} = "";
    $self->{offset} = 0;
    $self->{txn_offset} = undef;

    return $self;
}

sub feed_buffer {
    my ($self, $data) = @_;

    $self->{buffer} .= $$data;
}

sub signal_eof {
    my ($self) = @_;

    $self->{eof} = 1;
}

sub begin_reading {
    my ($self) = @_;

    $self->{txn_offset} = $self->{offset};
}

sub roll_back_reading {
    my ($self) = @_;

    $self->{offset} = $self->{txn_offset};
    $self->{txn_offset} = undef;

}

sub complete_reading {
    my ($self) = @_;

    $self->{txn_offset} = undef;
    $self->_trim_buffer();
}

sub is_reading {
    return defined($_[0]->{txn_offset});
}

sub read {
    my ($self) = @_;

    my $length = $_[2];
    die "Can only read a single byte" if $length != 1;

    if ($self->{offset} < length($self->{buffer})) {
        $_[1] = substr($self->{buffer}, $self->{offset}, 1);
        $self->{offset}++;
        return 1;
    }
    else {
        if ($self->{eof}) {
            return 0;
        }
        else {
            #print STDERR "Underrun!\n";
            #$self->_show_buffer();
            die(UNDERRUN);
        }
    }
}

# Discard anything we've already read from the buffer
sub _trim_buffer {
    my ($self) = @_;

    return if $self->{offset} == 0;
    $self->{buffer} = substr($self->{buffer}, $self->{offset});
    $self->{offset} = 0;
}

# For debugging
sub _show_buffer {
    my ($self, $offset) = @_;

    $offset = $self->{offset} unless defined($offset);

    print STDERR "Buffer: ", $self->{buffer}, "\n";
    print STDERR "        ", " " x $offset, "^\n";
}

1;

=head1 DESCRIPTION

This package is an internal implementation detail of L<JSON::Streaming::Reader>. It is used
to provide an API that looks like it blocks on top of a handle that doesn't block,
so the parsing functions can pretend they have a blocking handle.

Instances of this class support enough of the C<IO::Handle> interface to satisfy L<JSON::Streaming::Reader>
and no more. In other words, they support only the C<read> method and assume that the caller will only ever
want 1 character at a time.

This is not a public API. See the event-based API on L<JSON::Streaming::Reader>, which is
implemented in terms of this class. This class may go away in future versions,
once refactoring renders it no longer necessary.

=head1 SYNOPSIS

    my $event_wrapper = JSON::Streaming::Reader::EventWrapper->new();
    $event_wrapper->feed_buffer(\$string_of_data);
    $event_wrapper->begin_reading();
    my $char;
    eval {
        $event_wrapper->read($char, 1);
    };
    if ($@ == JSON::Streaming::Reader::EventWrapper::UNDERRUN) {
        $event_wrapper->roll_back_reading();
    }
    else {
        $event_wrapper->complete_reading();
        # Do something with $char
    }

