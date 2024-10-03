# Copyright (c) 2024 Löwenfelsen UG (haftungsbeschränkt)
# Copyright (c) 2024 Philipp Schafft

# licensed under Artistic License 2.0 (see LICENSE file)

# ABSTRACT: module for reading and writing ValueFile files

package File::ValueFile::Simple::Writer;

use v5.10;
use strict;
use warnings;

use Carp;
use URI::Escape qw(uri_escape_utf8);

use constant FORMAT_ISE => '54bf8af4-b1d7-44da-af48-5278d11e8f32';

our $VERSION = v0.01;



sub new {
    my ($pkg, $out, %opts) = @_;
    my $fh;
    my $self = bless \%opts;

    if (ref $out) {
        $fh = $out;
    } else {
        open($fh, '>', $out) or croak $!;
    }

    $self->{fh} = $fh;

    if (defined $opts{format}) {
        $self->_write_marker(required => 'ValueFile', FORMAT_ISE, $opts{format});
    }

    foreach my $type (qw(required copy optional)) {
        my $list = $opts{$type.'_feature'} // next;
        $list = [$list] unless ref($list) eq 'ARRAY';
        foreach my $entry (@{$list}) {
            $self->_write_marker($type, 'Feature', $entry);
        }
    }

    return $self;
}

sub _escape {
    my ($in) = @_;

    return '!null' if !defined $in;
    return '!empty' if $in eq '';

    return uri_escape_utf8($in);
}

sub _write_marker {
    my ($self, $type, @line) = @_;
    if ($type eq 'required') {
        $self->{fh}->print('!!');
    } elsif ($type eq 'copy') {
        $self->{fh}->print('!&');
    } elsif ($type eq 'optional') {
        $self->{fh}->print('!?');
    } else {
        croak 'Bug: Bad marker: '.$type;
    }

    @line = map {_escape($_)} map {ref($_) ? $_->ise : $_} @line;

    local $, = ' ';
    $self->{fh}->say(@line);
}


sub write {
    my ($self, @line) = @_;

    unless (scalar @line) {
        $self->{fh}->say('');
        return;
    }

    @line = map {_escape($_)} map {ref($_) ? $_->ise : $_} @line;

    {
        my $l = length($line[0]);
        $line[0] .= ' ' x (19 - $l) if $l < 19;
    }

    local $, = ' ';
    $self->{fh}->say(@line);
}


sub write_hash {
    my ($self, $hash) = @_;

    foreach my $key (keys %{$hash}) {
        my $value = $hash->{$key};

        $value = [$value] unless ref($value) eq 'ARRAY';

        foreach my $entry (@{$value}) {
            $self->write($key => $entry);
        }
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ValueFile::Simple::Writer - module for reading and writing ValueFile files

=head1 VERSION

version v0.01

=head1 SYNOPSIS

    use File::ValueFile::Simple::Writer;

This module provides a simple way to write ValueFile files.

=head1 METHODS

=head2 new

    my $writer = File::ValueFile::Simple::Writer->new($out [, %opts]);

Opens a writer for the given output file.
C<$out> can be an open file handle that must support seeking or a filename.

This method dies on any problem.

In addition the following options (all optional) are supported:

=over

=item C<format>

The format to use. Must be an ISE or an instances of L<Data::Identifier>.

=item C<required_feature>, C<copy_feature>, C<optional_feature>

Features that are used in the file.
Required features need to be supported by the reading entity.
Copy features are safe to be copied, even if not understood.
Optional features do not need to be understood by the reader.

May be a single feature or a list (as array ref).
Each feature is given by the ISE or an instances of L<Data::Identifier>.

=back

=head2 write

    $writer->write(@line);

Writes a single line (record). Correctly escapes the output.

Values in C<@line> may be strings, numbers, or instances of L<Data::Identifier>.

=head2 write_hash

    $writer->write_hash($hashref);

Writes a hash as returned by L<File::ValueFile::Simple::Reader/read_as_hash> or L<File::ValueFile::Simple::Reader/read_as_hash_of_arrays>.

Values in C<$hashref> may be strings, numbers, or instances of L<Data::Identifier>.

=head1 AUTHOR

Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2024 by Löwenfelsen UG (haftungsbeschränkt) <support@loewenfelsen.net>.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
