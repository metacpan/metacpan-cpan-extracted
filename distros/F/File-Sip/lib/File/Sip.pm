package File::Sip;

#ABSTRACT: file parser intended for big files that don't fit into main memory.


use Moo;
use Carp 'croak';
use IO::File;
use Encode qw(decode);
use feature ':5.10';


has path => (
    is       => 'ro',
    required => 1,
);


has line_separator => (
    is      => 'ro',
    default => sub {qw/(\015\012|\015|\012)/},
);


has is_utf8 => (
    is      => 'ro',
    default => sub {1},
);


# internal cursor for iterations
has _read_line_position => (
    is      => 'rw',
    default => sub {0},
);

sub read_line {
    my ( $self, $line_number ) = @_;

    $line_number //= $self->_read_line_position;
    my $fh         = $self->_fh;
    my $line_index = $self->index->[$line_number];
    return if !defined $line_index;

    my $previous_line_index =
      ( $line_number == 0 ) ? 0 : $self->index->[ $line_number - 1 ];

    my $line;
    seek( $fh, $previous_line_index, 0 );
    read( $fh, $line, $line_index - $previous_line_index );

    $self->_read_line_position( $line_number + 1 ) if @_ == 1;

    return decode( "utf8", $line ) if defined $line && $self->is_utf8;
    return $line;
}

# file handle return by IO::File
has _fh => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my ($self) = @_;
        my $open_file_param = "<:crlf";
        IO::File->new( $self->path, $open_file_param )
          or croak "Failed to open file '" . $self->path . "' : '$!'";
    }
);

# File stat array
has _stat => (
    is => 'lazy',
);

sub _build__stat {
    my ($self) = @_;
    my @stat = stat( $self->_fh );
    return \@stat;
}


has index => (
    is      => 'rw',
    lazy    => 1,
    builder => 1,
);

sub _build_index {
    my ($self) = @_;
    my $index = [];

    my ($blocksize) = @{ $self->_stat }[11];
    $blocksize ||= 8192;

    my $buffer      = '';
    my $offset      = 0;
    my $line_number = 0;

    # make sure we jump to the begining of the file
    seek( $self->_fh, 0, SEEK_SET );

    # build the index, char by char, splitting on the line separator
    my $line_sep = $self->line_separator;
    while ( my $count = read( $self->_fh, $buffer, $blocksize ) ) {
        for my $i ( 0 .. $count ) {
            my $char = substr $buffer, $i, 1;
            if ( $char =~ /$line_sep/ ) {
                $index->[ $line_number++ ] = $offset + $i + 1;
            }
        }
        $offset += $count;
    }

    # reset the cursor at the begining of the file and return the index
    seek( $self->_fh, 0, SEEK_SET );
    return $index;
}

1;


=pod

=head1 NAME

File::Sip - file parser intended for big files that don't fit into main memory.

=head1 VERSION

version 0.003

=head1 DESCRIPTION

In most of the cases, you don't want to use this, but L<File::Slurp::Tiny> instead.

This class is able to read a line from a file without loading the whole file in
memory. When you want to deal with files of millions of lines, on a limited
environment, brute force isn't an option.

An index of all the lines in the file is built in order to be able to access
their starting position depending on their line number.

The memory used is then limited to the size of the index plus the size of the
line that is read (until the line separator character is reached).

It also provides a way to nicely iterate over all the lines of the file, using
only the amount of memory needed to store one line at a time, not the whole file.

=head1 ATTRIBUTES

=head2 path

Required, file path as a string.

=head2 line_separator

Optional, regular expression of the newline seperator, default is
C</(\015\012|\015|\012)/>.

=head2 is_utf8

Optional, flag to tell if the file is utf8-encoded, default is true. 

If true, the line returned by C<read_line> will be decoded.

=head2 index

Index that contains positions of all lines of the file, usage:

    $sip->index->[ $line_number ] = $seek_position;

=head1 METHODS

=head2 read_line

Return the line content at the given position (terminated by C<line_separator>).

    my $line = $sip->read_line( $line_number );

It's also possible to read the entire file, line by line without providing a
line number to the method, until C<undef> is returned:

    while (my $line = $sip->read_line()) {
        # do something with $line
    }

=head1 ACKNOWLEDGMENT

This module was written at Weborama when dealing with huge raw files, where huge
means "oh no, it really won't fit anymore in this compute slot!" (which are
limited in main-memory).

=head1 BENCHMARK

C<File::Sip> is not faster than in-memory parsers like L<File::Slurp::Tiny> but
it has a lower memory footprint. With small files, it's not obvious (when the file
is small, the cost of the index is almost equal to the cost of all the
characters of the file).
But when the file gets bigger, the gain in main memory grows.

With files bigger than few megabytes, C<File::Sip> will consume up to 20 times less
memory than L<File::Slurp>. This factor of 20 appears to be an asymptotic limit
as size of studied files grows.

If you want to estimate the memory size of a running process that uses C<File::Sip>, you
can then assume that the size of the index will be around 1/20th of the size of
the processed file.

=head1 AUTHORS

This module has been written at Weborama by Alexis Sukrieh and Bin Shu.

=head1 AUTHOR

Alexis Sukrieh <sukria@sukria.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Weborama.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__
