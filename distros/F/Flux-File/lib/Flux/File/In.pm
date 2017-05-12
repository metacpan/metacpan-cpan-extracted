package Flux::File::In;
{
  $Flux::File::In::VERSION = '1.01';
}

# ABSTRACT: input stream from any plain-text line-based file.


use Moo;

with 'Flux::In';
with 'Flux::In::Role::Lag';

use MooX::Types::MooseLike::Base qw(:all);

use File::Basename;
use Carp;

use autodie qw(open seek);

has file => (
    is => 'ro',
    required => 1,
    isa => Str,
);


has cursor => (
    is => 'ro',
    required => 1,
    isa => sub { die "$_[0] is not a cursor!" unless $_[0]->isa('Flux::File::Cursor') },
);

has 'fh' => (
    is => 'ro',
    lazy => 1,
    builder => 1,
);

sub _build_fh {
    my $self = shift;

    my $position = $self->cursor->position;
    open my $fh, '<', $self->file;
    seek $fh, $position, 0;
    return $fh;
}

sub read {
    my $self = shift;

    my $fh = $self->fh;
    my $line = <$fh>;
    return unless defined $line;
    if ($line !~ /\n$/) {
        # incomplete line => backstep
        seek $fh, - length $line, 1;
        return;
    }

    return $line;
}

sub read_chunk {
    my $self = shift;
    my ($size) = @_;

    my @result;
    my $fh = $self->fh;

    while (1) {
        my $line = <$fh>;
        last unless defined $line;
        if ($line !~ /\n$/) {
            # incomplete line => backstep
            seek $fh, - length $line, 1;
            last;
        }
        push @result, $line;
        $size--;
        last if $size <= 0;
    }
    return unless @result;
    return \@result;
}

sub _tell {
    my $self = shift;

    my $pos = tell $self->fh;
    if ($pos == -1) {
        die "tell failed: $!";
    }
    return $pos;
}

sub _size {
    my $self = shift;

    my @stat = stat $self->fh;
    unless (@stat) {
        die "stat failed: $!";
    }
    my $size = $stat[7];
    return $size;
}

sub lag {
    my $self = shift;

    return $self->_size - $self->_tell;
}

sub commit {
    my $self = shift;

    $self->cursor->set_position($self->_tell);
}

1;

__END__

=pod

=head1 NAME

Flux::File::In - input stream from any plain-text line-based file.

=head1 VERSION

version 1.01

=head1 DESCRIPTION

Input stream for the L<Flux::File> storage.

You'll usually want to instantiate it using C<< Flux::File->new($file)->in(Flux::File::Cursor->new($cursor_file)) >>, not directly.

=head1 AUTHOR

Vyacheslav Matyukhin <me@berekuk.ru>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yandex LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
