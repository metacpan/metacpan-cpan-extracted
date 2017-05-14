package File::Kvpar;

use strict;
use warnings;

use constant HEAD => 1;
use constant TAIL => 2;

sub new {
    my $cls = shift;
    my ($mode, $file, $fh);
    my %self = (
        'elements' => [],
        'have_read' => 0,
        'pos' => 0,
    );
    if (@_ == 1) {
        $file = shift;
        if (ref $file) {
            ($fh, $file) = ($file, "<$file>");
            $mode = '<';
        }
        elsif ($file =~ s/^([<>+]+)//) {
            $mode = $1;
        }
        else {
            $mode = '<';
        }
    }
    elsif (@_ == 2) {
        ($mode, $file) = @_;
    }
    if (!defined $fh) {
        open $fh, $mode, $file or die "Can't open $file: $!";
    }
    @self{qw(file fh)} = ($file, $fh);
    bless \%self, $cls;
}

sub iter {
    my ($self) = @_;
    my @elems = @{ $self->{'elements'} };
    return sub {
        return shift @elems if @elems;
        return if $self->{'have_read'} & TAIL;
        return $self->_read_one;
    }
}

sub write {
    my $self = shift;
    return if !@_;
    my ($fh, $elems, $pos) = @$self{qw(fh elements pos)};
    my @elems = @$elems;
    splice @elems, $pos, @elems - $pos, @_ if $pos > 0;
    my @pars = map { _hash2par($_) } @_;
    print $fh @pars;
    my $ofs = tell $fh;
    truncate $fh, $ofs;
    push @elems, @_;
    $self->{'pos'} = @elems;
    @$elems = @elems;
    return $self;
}

sub append {
    my $self = shift;
    return if !@_;
    my ($fh, $elems, $pos) = @$self{qw(fh elements pos)};
    seek $fh, 0, 2 or die "Can't seek to end: $!";
    my @elems = @$elems;
    push @elems, @_;
    my @pars = map { _hash2par($_) } @_;
    print $fh @pars;
    $self->{'pos'} = @$elems;
    @$elems = @elems;
    return $self;
}

sub truncate {
    my ($self) = @_;
    my ($fh, $elems, $pos) = @$self{qw(fh elements pos)};
    my $ofs = tell $fh;
    truncate $fh, $ofs;
    splice @$elems, $pos;
    return $self;
}

sub _hash2par {
    my ($hash) = @_;
    my $par = '';
    my %hash = %$hash;
    my ($at, $lb) = delete @hash{'@','#'};
    if (defined $at) {
        $par .= '@' . $at;
        $par .= ' ' . $lb if defined $lb;
        $par .= "\n";
    }
    foreach my $k (sort keys %hash) {
        my $v = $hash{$k};
        $par .= "$k $v\n" if defined $v;
    }
    $par = "#empty\n" if !length $par;
    return $par . "\n";
}

sub _par2hash {
    my ($par) = @_;
    chomp $par;
    my %hash;
    foreach (split /\n/, $par) {
        if (/^[@](\S*)(?: (.+))?$/) {
            $hash{'@'} = $1 if length $1;
            $hash{'#'} = $2 if defined $2;
        }
        elsif (/^[#]/) {
            next;
        }
        elsif (/^(\S+) (.*)$/) {
            $hash{$1} = $2;
        }
    }
    return \%hash;
}

sub _read_one {
    my ($self) = @_;
    my $fh = $self->{'fh'};
    local $/ = '';
    my $elems = $self->{'elements'};
    if (my $par = <$fh>) {
        $self->{'pos'}++;
        my $hash = _par2hash($par);
        push @{ $elems }, $hash;
        $self->{'have_read'} |= HEAD;
        return $hash;
    }
    else {
        $self->{'have_read'} |= TAIL;
        return;
    }
}

sub _read_remainder {
    my ($self) = @_;
    my ($hash, @rem);
    while ($hash = $self->_read_one) {
        push @rem, $hash;
    }
    return @rem;
}

sub head {
    my ($self) = @_;
    my $elems = $self->{'elements'};
    return $self->_read_one if !@$elems;
    return $elems->[0];
}

sub tail {
    my ($self) = @_;
    my $elems = $self->{'elements'};
    $self->_read_remainder if !( $self->{'have_read'} & TAIL );
    return if @$elems < 2;
    return @$elems[1..$#$elems];
}

sub reset {
    my ($self) = @_;
    seek $self->{'fh'}, 0, 0 or die "Can't seek to beginning of file: $!";
    $self->{'pos'} = 0;
    $self->{'elements'} = [];
    $self->{'have_read'} = 0;
    return $self;
}

sub elements {
    my ($self) = @_;
    my $elems = $self->{'elements'};
    $self->_read_remainder if ( $self->{'have_read'} & (HEAD|TAIL) ) != (HEAD|TAIL);
    return @$elems;
}

1;

=pod

=head1 NAME

File::Kvpar - read and write files containing key-value paragraphs

=head1 SYNOPSIS

    $kv = File::Kvpar->new($file);
    $kv = File::Kvpar->new($mode, $file);  # $mode = '<' || '>' || ...
    $kv = File::Kvpar->new($fh);
    $iter = $kv->iter;
    while ($elem = &$iter) {
        ...
    }
    @a = $kv->elements;
    $a = $kv->head;
    @a = $kv->tail;
    foreach ($kv->elements) {
        ...
    }

=head1 DESCRIPTION

A B<kvpar> file consists of zero or more paragraphs (delimited by blank lines).
Each line in a paragraph has the form C<< I<KEY> I<VAL> >>; the key and value
are separated by a single space (ASCII character 32).

A single element may have the form C<< @I<STR> I<VAL> >> -- if it does, the
element's hash will be augmented with the key/value pairs
(
C<@> => I<STR>,
C<#> => I<VAL>
).  No further interpretation is made, but one use of this might be to treat
I<STR> as the object's B<type> and I<VAL> as the object's B<primary key>.

=head1 METHODS

=over 4

=item B<new>

    $kv = File::Kvpar->new($file);
    $kv = File::Kvpar->new($mode, $file);
    $kv = File::Kvpar->new($fh);

Open or create a kvpar-formatted file.

I<$mode> defaults to C<< E<lt> >> if a file path is the only argument.

For greater control, pass a filehandle as the only argument.  Passing both a
mode and filehandle will cause an exception to be thrown.

=item B<iter>

    $iter = $kv->iter;
    while ($hash = &$iter) { ... }
    while ($hash = $iter->()) { ... }

Return a CODE reference that may be invoked to obtain the next element in the
file.  It returns the undefined value if all elements have been read.

=item B<elements>

Return a list (not an array reference) of all elements in the file.  Any unread
elements will be read.

=item B<head>

Return the first element in the file.  It will be read if it hasn't already been.

=item B<tail>

    @elems = $kv->tail;

Return a list of all elements after the first.  Any unread elements will be read.

=item B<write>

    $kv->write(@hashes);

Write I<@hashes> to the current position in the file.  The file will be
truncated afterwards, since the alternative would totally mess up files in most
cases.  The file must have been opened for write access, of course.

=item B<append>

    $kv->append(@hashes);

Write I<@hashes> to the end of the file.  The file must have been opened for
write access, of course.

=item B<truncate>

    $kv = File::Kvpar->new('<+', $file);
    $kv->head;  # Read and discard the first element
    $kv->truncate;
    $kv->write({...});

Truncate the file at the current position and discard any elements that may
have been read at or after the current position.  If nothing has been read from
the file, the file will become empty.

=item B<reset>

    $kv->reset;

Set the file position to 0 -- i.e., seek to the beginning of the file -- and
discard any elements that have already been read.  If the file has been opened
for write access, the next B<write> will truncate it.  If it has been opened
for append access, the next B<append> will wreak havoc unless you call
B<truncate> first.

This will throw an exception if the underlying filehandle is not seekable.

=back

=cut

