package Gzip::BinarySearch;

use strict;
use warnings;
use Carp;
use List::Util qw(min max);
use Gzip::RandomAccess;

our $VERSION = '0.91';

BEGIN {
    use Exporter;
    our @ISA = qw(Exporter);
    our @EXPORT_OK = qw(fs_column tsv_column);
}

# When binary searching, assume this is the biggest line we'll find.
# We'll try this first, then try a bigger decompression if it fails.
my $DEFAULT_EST_LINE_LENGTH = 512;

# When looking for adjacent identical lines (find_all) extract this
# many bytes at a time.
my $DEFAULT_SURROUNDING_LINES_BLOCKSIZE = 4096;

my @GRA_ALLOWED_ARGS = qw(file index_file index_span cleanup);
my %ALLOWED_ARGS = map { $_ => 1 } (
    @GRA_ALLOWED_ARGS, qw(key_func cmp_func),
    qw(est_line_length surrounding_lines_blocksize),
);

sub new {
    my ($class, %args) = @_;
    my $gzip = $class->_build_gzip(%args);
    for my $key (keys %args) {
        $ALLOWED_ARGS{$key} or croak "Invalid argument '$key'";
    }

    my $key_func = $args{key_func} || fs_column(qr/\s+/, 1);
    my $cmp_func = $args{cmp_func} || sub { $main::a cmp $main::b };

    my $est_line_length = $args{est_line_length}
        || $DEFAULT_EST_LINE_LENGTH;

    my $surrounding_lines_blocksize = $args{surrounding_lines_blocksize}
        || $DEFAULT_SURROUNDING_LINES_BLOCKSIZE;

    bless {
        gzip => $gzip,
        max_offset => $gzip->uncompressed_size - 1,
        est_line_length => $est_line_length,
        surrounding_lines_blocksize => $surrounding_lines_blocksize,
        key_func => $key_func,
        cmp_func => $cmp_func,
    }, $class;
}

sub find {
    my ($self, $key) = @_;

    my ($line, $mid) = $self->_find($key);
    return $line if defined $line;
    return;
}

sub find_all {
    my ($self, $key) = @_;

    my ($line, $mid) = $self->_find($key); 
    if (defined $line) {
        return $self->_search_surrounding_lines($key, $line, $mid);
    }
    return;
}

sub gzip { shift->{gzip} }
sub est_line_length { shift->{est_line_length} }
sub surrounding_lines_blocksize { shift->{surrounding_lines_blocksize} }

# Convenience functions
sub fs_column {
    my ($field_sep, $column_number) = @_;
    croak "Invalid column number, should be 1-based"
        if $column_number < 1;

    if (!ref $field_sep && $field_sep eq ' ') {
        # Force Perl to match a space, not \s+
        $field_sep = qr/ /;
    }

    return sub {
        chomp;
        my @f = split $field_sep, $_, -1;
        return $f[$column_number - 1];
    }
}

sub tsv_column {
    my $column_number = shift;
    return fs_column("\t", $column_number);
}

# Given a key, binary search for the first line encountered with this key,
# and return both the line and its offset in the uncompressed data.
# Return nothing if the key was not found.
sub _find {
    my ($self, $key) = @_;
    my ($low, $high, $mid) = (0, $self->{max_offset}, undef);

    while ($low <= $high) {
        $mid = int(($low + $high) / 2);
        my $line = $self->_get_line_at($mid);
        my $line_key = $self->_get_key($line);
        my $cmp = $self->_compare_keys($line_key, $key);

        if ($cmp < 0) {
            $low = $mid + 1;
        }
        elsif ($cmp > 0) {
            $high = $mid - 1;
        }
        else {
            return ($line, $mid);
        }
    }

    # Key not found
    return;
}

# Given an offset, return the entire line 'around' that offset.
# This includes any trailing newline character.
# If the offset is a newline, it will be counted as part of the preceding line.
sub _get_line_at {
    my ($self, $offset) = @_;
    my $L = $self->{est_line_length};

    my $seek_start = max($offset - $L, 0); # global offset
    my $seek_length = $L * 2;
    my $midpoint = $offset - $seek_start;  # relative to extracted $block, not global

    my $line;
    while (!defined $line) {
        my $block = $self->{gzip}->extract($seek_start, $seek_length);

        my $prev_nl = rindex($block, "\n", $midpoint - 1);  # -1 if no match
        my $next_nl = index($block, "\n", $midpoint);

        if ($prev_nl == -1 && $seek_start > 0) {
            my $extension = min($L, $seek_start);
            $seek_start -= $extension;
            $seek_length += $extension;
            $midpoint += $extension;
        }
        elsif ($next_nl == -1 && $seek_start + $seek_length < $self->{max_offset}) {
            $seek_length += $L;
        }
        else {
            $next_nl = length($block) if $next_nl == -1;  # no EOF newline - use last char
            $line = substr($block, $prev_nl + 1, $next_nl - $prev_nl);
        }
    }

    return $line;
}

sub _get_key {
    my ($self, $line) = @_;
    local *::_ = \$line;
    return $self->{key_func}->();
}

sub _compare_keys {
    my ($self, $key1, $key2) = @_;
    local (*::a, *::b) = (\$key1, \$key2);
    return $self->{cmp_func}->();

}

# Given a line and a seekpoint in the uncompressed data, look forwards and backwards
# for adjacent lines with the same key. Return matching lines in same order as file.
sub _search_surrounding_lines {
    my ($self, $query, $mid_line, $mid) = @_;
    # Problem description:
    # when searching for 'zits', the algorithm expands, then shrinks line-by-line
    # at the end it trims the string to "zings\nzits\n..." and for some reason the
    # zits offset isn't used to trim it further.
    # you'll notice the _compare_keys thing which means $result_start is never set
    # if we're shrinking (?)

    my $block_start = max($mid - length($mid_line) + 1, 0);
    my $block_end = min($mid + length($mid_line) - 1, $self->{max_offset});
    my $block = $self->{gzip}->extract($block_start, $block_end - $block_start);

    # offsets for the result range, relative to block_start
    my ($result_start, $result_end) = (0, $block_end - $block_start);

    my $shrinking = 0;
    while (1) {
        my ($line, $offset) = $self->_first_line($block, $result_start, $result_end, $block_start == 0);
        if (!defined $line || $self->_compare_keys($self->_get_key($line), $query) == 0) {
            last if $shrinking;
            last if $block_start == 0;  # can't expand further
            # Expand left
            my $ex = min($self->{surrounding_lines_blocksize}, $block_start);
            $block_start -= $ex;
            $result_end += $ex;
            my $chunk = $self->{gzip}->extract($block_start, $ex);
            $block = $chunk . $block;
        }
        else {
            # Shrink
            $result_start = $offset + length($line);
            $shrinking = 1;
        }
    }
    my ($line, $offset) = $self->_first_line($block, $result_start, $result_end, $block_start == 0);
    $result_start = $offset;

    $shrinking = 0;
    while (1) {
        my ($line, $offset) = $self->_last_line($block, $result_start, $result_end, $result_end == $self->{max_offset});
        if (!defined $line || $self->_compare_keys($self->_get_key($line), $query) == 0) {
            last if $shrinking;
            last if $block_end == $self->{max_offset};
            # Expand right
            my $ex = min($self->{surrounding_lines_blocksize}, $self->{max_offset} - $block_end);
            my $chunk = $self->{gzip}->extract($block_end, $ex);
            $block_end += $ex;
            $result_end += $ex;
            $block .= $chunk;
        }
        else {
            $result_end = $offset - 1;
            $shrinking = 1;
        }
    }
    
    my $result = substr($block, $result_start, $result_end - $result_start);
    return map { "$_\n" } split /\n/, $result;
}

# Get the first complete line from the block, limiting to a range from
# $start to $end (inclusive). If $allow_incomplete, we instead return
# all data up to the first \n.
# Also return the offset of the start of this line, relative to the
# entire text block.
# Return nothing if we need more data (left/right) to get a full line.
sub _first_line {
    my ($self, $block, $start, $end, $allow_incomplete) = @_;
    my $nl = index($block, "\n", $start);
    $nl = -1 if $nl > $end;
    if ($allow_incomplete) {
        $nl = $end if $nl == -1;
        return (substr($block, $start, $nl - $start + 1), $start);
    }
    else {
        return if $nl == -1;  # more data needed
        my $nl2 = index($block, "\n", $nl + 1);
        die if $nl2 < $start && $nl2 != -1;
        return if $nl2 == -1 || $nl2 > $end;
        return (substr($block, $nl + 1, $nl2 - $nl), $nl + 1);
    }
}

# Same deal as above, but for the last line. $allow_incomplete
# returns all data from the last \n onwards, and ignores a
# trailing newline at the end of the range.
sub _last_line {
    my ($self, $block, $start, $end, $allow_incomplete) = @_;
    my $nl = rindex($block, "\n", $end);
    $nl = -1 if $nl < $start;
    if ($allow_incomplete) {
        $nl = rindex($block, "\n", $nl - 1) if $nl == $end;  # ignore trailing newline
        $nl = $start - 1 if $nl == -1;  # pretend there's one
        return (substr($block, $nl + 1, $end - $nl), $nl + 1);
    }
    else {
        return if $nl == -1;  # more data needed
        my $nl2 = rindex($block, "\n", $nl - 1);
        die if $nl2 > $end && $nl2 != -1;
        return if $nl2 == -1 || $nl2 < $start;
        return (substr($block, $nl2 + 1, $nl - $nl2), $nl2 + 1);
    }
}

# Build and return the Gzip::RandomAccess object.
sub _build_gzip {
    my ($class, %args) = @_;

    my %gra_args;
    for my $key (@GRA_ALLOWED_ARGS) {
        $gra_args{$key} = $args{$key} if exists $args{$key};
    }

    return Gzip::RandomAccess->new(%gra_args);
}

__END__

=head1 NAME

Gzip::BinarySearch - binary search a sorted, gzipped flatfile database

=head1 SYNOPSIS

  use Gzip::BinarySearch qw(tsv_column);

  my $db = Gzip::BinarySearch->new(
      file => 'file.gz',
      key_func => tsv_column(2),
  );
  print $db->find($key);
  print for $db->find_all($key);

=head1 DESCRIPTION

This module can binary search gzipped databases, such as TSVs,
without decompressing the entire file. You need only declare how
the file is sorted.

Behind the scenes, we use L<Gzip::RandomAccess> to perform the
random-access decompression.

=head1 METHODS

=head2 new (%args)

You may pass C<index_file>, C<index_span> and C<cleanup> arguments,
which are passed directly to L<Gzip::RandomAccess>, so check that
module's perldoc for more info.

=over

=item file (required)

Path to the gzip file you want to search.

=item key_func (default: first field, whitespace-separated)

A function that takes a line (aliased to C<$_>) and should return the
key for that line, which will be used when comparing lines.

For TSVs, you can use C<tsv_column> to generate a key function (see
below).

=item cmp_func (default: Perl's 'cmp' operator)

A function that accepts two keys, C<$a> and C<$b>, and returns a
value indicating which is 'greater' in the same way as Perl's
C<sort> builtin. This must match the file's natural ordering
(or else).

=item est_line_length

Providing an estimate of the maximum line length in the gzip file
can help L<Gzip::BinarySearch> know how much data to uncompress.
The default is 512 bytes - getting it wrong will affect speed,
but it'll still work.

=item surrounding_lines_blocksize

How many bytes to search either side of a matching line to find
adjacent matching lines when using C<find_all>. If you have a lot
of rows with the same key, upping this value will speed things up.
The default is 4096 bytes.

=back

=head2 find ($key)

Return the line matching the key supplied, or nothing (undef/empty
list) if nothing found.

=head2 find_all ($key)

Return all lines matching the key supplied, or an empty list if none
found. The lines will be returned in the order they appear in the
file.

=head2 gzip

Returns the L<Gzip::RandomAccess> object we're using.

=head1 EXPORTED FUNCTIONS

=head2 tsv_column ($column_number)

Returns a key function that will parse each line as a TSV and return
the specified column number as a key.

=head2 fs_column ($field_separator, $column_number)

Returns a key function that will split a line by the field separator
provided, and return the specified column number.
(C<$field_separator> may be a regex or string).

For example, to split like awk(1) and use the first column:

  key_func => fs_column(qr/\s+/, 1)

=head2 est_line_length

=head2 surrounding_lines_blocksize

Accessors for constructor arguments.

=head1 CAVEATS

Currently only works with Linux line endings (ASCII 0x10).

Does not support fancy multibyte encodings (specifically UTF-8) but
I aim to add support in a later release.

Isn't as efficient as it could be - aligning decompression to
the indexed points in the gzip would help, as would caching
decompressed blocks.

=head1 AUTHOR

Richard Harris <richardjharris@gmail.com>

=cut
