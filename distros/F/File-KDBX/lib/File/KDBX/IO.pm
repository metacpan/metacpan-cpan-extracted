package File::KDBX::IO;
# ABSTRACT: Base IO class for KDBX-related streams

use warnings;
use strict;

use Devel::GlobalDestruction;
use File::KDBX::Constants qw(:bool);
use File::KDBX::Util qw(:class :empty);
use List::Util qw(sum0);
use Ref::Util qw(is_blessed_ref is_ref is_scalarref);
use Symbol qw(gensym);
use namespace::clean;

extends 'IO::Handle';

our $VERSION = '0.903'; # VERSION

sub _croak { require Carp; goto &Carp::croak }

my %ATTRS = (
    _append_output  => 0,
    _buffer_in      => sub { [] },
    _buffer_out     => sub { [] },
    _error          => undef,
    _fh             => undef,
    _mode           => '',
);
while (my ($attr, $default) = each %ATTRS) {
    no strict 'refs'; ## no critic (ProhibitNoStrict)
    *$attr = sub {
        my $self = shift;
        *$self->{$attr} = shift if @_;
        *$self->{$attr} //= (ref $default eq 'CODE') ? $default->($self) : $default;
    };
}

sub new {
    my $class = shift || (caller)[0];
    my $self = bless gensym, ref($class) || $class;
    tie *$self, $self if 5.005 <= $];
    return $self;
}

sub DESTROY {
    return if in_global_destruction;
    local ($., $@, $!, $^E, $?);
    my $self = shift;
    $self->close;
}

sub close {
    my $self = shift;
    my $fh = $self->_fh // return TRUE;
    $self->_POPPED($fh);
    $self->_fh(undef);
    return $fh->close;
}
sub eof {
    my $self = shift;
    return FALSE if @{$self->_buffer_in};
    my $fh = $self->_fh // return TRUE;
    local *$self->{_error} = *$self->{_error};
    my $char = $self->getc || return TRUE;
    $self->ungetc($char);
}
sub read { shift->sysread(@_) }
sub print {
    my $self = shift;
    for my $buf (@_) {
        return FALSE if !$self->write($buf, length($buf));
    }
    return TRUE;
}
sub printf { shift->print(sprintf(@_)) }
sub say { shift->print(@_, "\n") }
sub getc { my $c; (shift->read($c, 1) // 0) == 1 ? $c : undef }
sub sysread {
    my $self = shift;
    my ($out, $len, $offset) = @_;
    $out = \$_[0] if !is_scalarref($out);
    $offset //= 0;

    $self->_mode('r') if !$self->_mode;

    my $fh = $self->_fh or return 0;
    return 0 if defined $len && $len == 0;

    my $append = $self->_append_output;
    if (!$append) {
        if (!$offset) {
            $$out = '';
        }
        else {
            if (length($$out) < $offset) {
                $$out .= "\0" x ($offset - length($$out));
            }
            else {
                substr($$out, $offset) = '';
            }
        }
    }
    elsif (!defined $$out) {
        $$out = '';
    }

    $len ||= 0;

    my $buffer = $self->_buffer_in;
    my $buffer_len = $self->_buffer_in_length;

    if (!$len && !$offset) {
        if (@$buffer) {
            my $blen = length($buffer->[0]);
            if ($append) {
                $$out .= shift @$buffer;
            }
            else {
                $$out = shift @$buffer;
            }
            return $blen;
        }
        else {
            my $fill = $self->_FILL($fh) or return 0;
            if ($append) {
                $$out .= $fill;
            }
            else {
                $$out = $fill;
            }
            return length($fill);
        }
    }

    while ($buffer_len < $len) {
        my $fill = $self->_FILL($fh);
        last if empty $fill;
        $self->_buffer_in_add($fill);
        $buffer_len += length($fill);
    }

    my $read_len = 0;
    while ($read_len < $len && @$buffer) {
        my $wanted = $len - $read_len;
        my $read = shift @$buffer;
        if ($wanted < length($read)) {
            $$out .= substr($read, 0, $wanted, '');
            unshift @$buffer, $read;
            $read_len += $wanted;
        }
        else {
            $$out .= $read;
            $read_len += length($read);
        }
    }

    return $read_len;
}
sub syswrite {
    my ($self, $buf, $len, $offset) = @_;
    $len    //= length($buf);
    $offset //= 0;

    $self->_mode('w') if !$self->_mode;

    return $self->_WRITE(substr($buf, $offset, $len), $self->_fh);
}

sub autoflush {
    my $self = shift;
    my $fh = $self->_fh // return FALSE;
    return $fh->autoflush(@_);
}

sub opened {
    my $self = shift;
    my $fh = $self->_fh // return FALSE;
    return TRUE;
}
sub getline {
    my $self = shift;

    if (!defined $/) {  # SLURP
        local *$self->{_append_output} = 1;
        my $data;
        1 while 0 < $self->read($data);
        return $data;
    }
    elsif (is_scalarref($/) && ${$/} =~ /^\d+$/ && 0 < ${$/}) {
        # RECORD MODE
        goto &_not_implemented;
    }
    elsif (length $/ == 0) {
        # PARAGRAPH MODE
        goto &_not_implemented;
    }
    else {
        # LINE MODE
        goto &_not_implemented;
    }
}
sub getlines {
    my $self = shift;
    wantarray or _croak 'Must call getlines in list context';
    my @lines;
    while (defined (my $line = $self->getline)) {
        push @lines, $line;
    }
    return @lines;
}
sub ungetc {
    my ($self, $ord) = @_;
    unshift @{$self->_buffer_in}, chr($ord);
    return;
}
sub write {
    my ($self, $buf, $len, $offset) = @_;
    return $self->syswrite($buf, $len, $offset) == $len;
}
sub error {
    my $self = shift;
    return !!$self->_error;
}
sub clearerr {
    my $self = shift;
    my $fh = $self->_fh // return -1;
    $self->_error(undef);
    return;
}
sub sync {
    my $self = shift;
    my $fh = $self->_fh // return undef;
    return $fh->sync;
}
sub flush {
    my $self = shift;
    my $fh = $self->_fh // return undef;
    $self->_FLUSH($fh);
    return $fh->flush;
}
sub printflush {
    my $self = shift;
    my $orig = $self->autoflush;
    my $r = $self->print(@_);
    $self->autoflush($orig);
    return $r;
}
sub blocking {
    my $self = shift;
    my $fh = $self->_fh // return TRUE;
    return $fh->blocking(@_);
}

sub format_write            { goto &_not_implemented }
sub new_from_fd             { goto &_not_implemented }
sub fcntl                   { goto &_not_implemented }
sub fileno                  { goto &_not_implemented }
sub ioctl                   { goto &_not_implemented }
sub stat                    { goto &_not_implemented }
sub truncate                { goto &_not_implemented }
sub format_page_number      { goto &_not_implemented }
sub format_lines_per_page   { goto &_not_implemented }
sub format_lines_left       { goto &_not_implemented }
sub format_name             { goto &_not_implemented }
sub format_top_name         { goto &_not_implemented }
sub input_line_number       { goto &_not_implemented }
sub fdopen                  { goto &_not_implemented }
sub untaint                 { goto &_not_implemented }

##############################################################################

sub _buffer_in_add      { push @{shift->_buffer_in}, @_ }
sub _buffer_in_length   { sum0 map { length($_) } @{shift->_buffer_in} }

sub _buffer_out_add     { push @{shift->_buffer_out}, @_ }
sub _buffer_out_length  { sum0 map { length($_) } @{shift->_buffer_out} }

sub _not_implemented    { _croak 'Operation not supported' }

##############################################################################

sub TIEHANDLE {
    return $_[0] if is_blessed_ref($_[0]);
    die 'wat';
}

sub UNTIE {
    my $self = shift;
}

sub READLINE {
    goto &getlines if wantarray;
    goto &getline;
}

sub binmode { 1 }

{
    no warnings 'once';

    *READ = \&read;
    # *READLINE = \&getline;
    *GETC = \&getc;
    *FILENO = \&fileno;
    *PRINT = \&print;
    *PRINTF = \&printf;
    *WRITE = \&syswrite;
    # *SEEK = \&seek;
    # *TELL = \&tell;
    *EOF = \&eof;
    *CLOSE = \&close;
    *BINMODE = \&binmode;
}

sub _FILL { die 'Not implemented' }

##############################################################################

if ($ENV{DEBUG_IO}) {
    my %debug = (level => 0);
    for my $method (qw{
        new
        new_from_fd
        close
        eof
        fcntl
        fileno
        format_write
        getc
        ioctl
        read
        print
        printf
        say
        stat
        sysread
        syswrite
        truncate

        autoflush
        format_page_number
        format_lines_per_page
        format_lines_left
        format_name
        format_top_name
        input_line_number

        fdopen
        opened
        getline
        getlines
        ungetc
        write
        error
        clearerr
        sync
        flush
        printflush
        blocking

        untaint
    }) {
        no strict 'refs'; ## no critic (ProhibitNoStrict)
        no warnings 'redefine';
        my $orig = *$method{CODE};
        *$method = sub {
            local $debug{level} = $debug{level} + 2;
            my $indented_method = (' ' x $debug{level}) . $method;
            my $self = shift;
            print STDERR sprintf('%-20s -> %s (%s)', $indented_method, $self,
                join(', ', map { defined $_ ? substr($_, 0, 16) : 'undef' } @_)), "\n";
            my $r = $orig->($self, @_) // 'undef';
            print STDERR sprintf('%-20s <- %s [%s]', $indented_method, $self, $r), "\n";
            return $r;
        };
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

File::KDBX::IO - Base IO class for KDBX-related streams

=head1 VERSION

version 0.903

=head1 DESCRIPTION

This is a L<IO::Handle> subclass which provides self-tying and buffering. It currently provides an interface
for subclasses that is similar to L<PerlIO::via>, but this is subject to change. Don't depend on this outside
of the L<File::KDBX> distribution. Currently-available subclasses:

=over 4

=item *

L<File::KDBX::IO::Crypt>

=item *

L<File::KDBX::IO::HashBlock>

=item *

L<File::KDBX::IO::HmacBlock>

=back

=for Pod::Coverage autoflush
binmode
close
eof
fcntl
fileno
format_lines_left
format_lines_per_page
format_name
format_page_number
format_top_name
format_write
getc
input_line_number
ioctl
print
printf
read
say
stat
sysread
syswrite
truncate

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
L<https://github.com/chazmcgarvey/File-KDBX/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Charles McGarvey <ccm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by Charles McGarvey.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
