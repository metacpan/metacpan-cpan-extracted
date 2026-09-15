package Linux::Event::_IO;
use v5.36;
use strict;
use warnings;


use Carp qw(croak);

sub _constructor_handles ($method, $option) {
    my $fh = $option->{fh};
    my $read_fh = $option->{read_fh};
    my $write_fh = $option->{write_fh};

    croak "$method(): fh cannot be combined with read_fh or write_fh"
        if defined($fh) && (defined($read_fh) || defined($write_fh));
    if (defined $fh) {
        $read_fh = $fh;
        $write_fh = $fh;
    }

    my @handle;
    my %seen;
    for my $pair ([read_fh => $read_fh], [write_fh => $write_fh]) {
        next if !defined $pair->[1];
        my $fd = fileno($pair->[1]);
        croak "$method(): $pair->[0] must be a filehandle" if !defined $fd;
        next if $seen{$fd}++;
        push @handle, [$pair->[0], $pair->[1], $fd];
    }
    return @handle;
}

sub _transition_resource_kind ($target) {
    return 'pipe' if $target->isa('Linux::Event::IO::Pipe');
    return 'tty' if $target->isa('Linux::Event::IO::TTY');
    return 'stream-socket'
        if $target->isa('Linux::Event::IO::Sock::Stream');
    return undef;
}

sub _guard_transition_resource_kind ($self, $class) {
    return if !defined($class) || ref($class) || $class eq '';

    my $source_kind = _transition_resource_kind($self);
    return if !defined $source_kind;

    my $target_kind = _transition_resource_kind($class);
    croak 'transition_to(): cannot change ordered-byte resource kind ('
        . $source_kind . ' -> '
        . (defined($target_kind) ? $target_kind : 'other') . ')'
        if !defined($target_kind) || $source_kind ne $target_kind;
    return;
}

1;
