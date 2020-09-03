package IO::Callback;

use warnings;
use strict;

=head1 NAME

IO::Callback - Emulate file interface for a code reference

=head1 VERSION

Version 2.00

=cut

our $VERSION = '2.00';

=head1 SYNOPSIS

C<IO::Callback> provides an easy way to produce a phoney read-only filehandle that calls back to your own code when it needs data to satisfy a read. This is useful if you want to use a library module that expects to read data from a filehandle, but you want the data to come from some other source and you don't want to read it all into memory and use L<IO::String>.

    use IO::Callback;

    my $fh = IO::Callback->new('<', sub { ... ; return $data });
    my $object = Some::Class->new_from_file($fh);

Similarly, IO::Callback allows you to wrap up a coderef as a write-only filehandle, which you can pass to a library module that expects to write its output to a filehandle.

    my $fh = IO::Callback->new('>', sub { my $data = shift ; ... });
    $object->dump_to_file($fh);


=head1 CONSTRUCTOR

=head2 C<new ( MODE, CODEREF [,ARG ...] )>

Returns a filehandle object encapsulating the coderef.

MODE must be either C<E<lt>> for a read-only filehandle or C<E<gt>> for a write-only filehandle.

For a read-only filehandle, the callback coderef will be invoked in a scalar context each time more data is required to satisfy a read. It must return some more input data (at least one byte) as a string. If there is no more data to be read, then the callback should return either C<undef> or the empty string. If ARG values were supplied to the constructor, then they will be passed to the callback each time it is invoked.

For a write-only filehandle, the callback will be invoked each time there is data to be written. The first argument will be the data as a string, which will always be at least one byte long. If ARG values were supplied to the constructor, then they will be passed as additional arguments to the callback. When the filehandle is closed, the callback will be invoked once with the empty string as its first argument.  

To simulate a non-fatal error on the file, the callback should set C<$!> and return the special value C<IO::Callback::Error>. See examples 6 and 7 below.

=head1 EXAMPLES

=over 4

=item Example 1

To generate a filehandle from which an infinite number of C<x> characters can be read:

=for test "ex1" begin

  my $fh = IO::Callback->new('<', sub {"xxxxxxxxxxxxxxxxxxxxxxxxxxx"});

  my $x = $fh->getc;  # $x now contains "x"
  read $fh, $x, 5;    # $x now contains "xxxxx"

=for test "ex1" end

=item Example 2

A filehandle from which 1000 C<foo> lines can be read before EOF:

=for test "ex2" begin

  my $count = 0;
  my $fh = IO::Callback->new('<', sub {
      return if ++$count > 1000; # EOF
      return "foo\n";
  });

  my $x = <$fh>;    # $x now contains "foo\n"
  read $fh, $x, 2;  # $x now contains "fo"
  read $fh, $x, 2;  # $x now contains "o\n"
  read $fh, $x, 20; # $x now contains "foo\nfoo\nfoo\nfoo\nfoo\n"
  my @foos = <$fh>; # @foos now contains ("foo\n") x 993

=for test "ex2" end

The example above uses a C<closure> (a special kind of anonymous sub, see L<http://perldoc.perl.org/perlfaq7.html#What's-a-closure?>) to allow the callback to keep track of how many lines it has returned. You don't have to use a closure if you don't want to, since C<IO::Callback> will forward extra constructor arguments to the callback. This example could be re-written as:

=for test "ex2a" begin

  my $count = 0;
  my $fh = IO::Callback->new('<', \&my_callback, \$count); 

  my $x = <$fh>;    # $x now contains "foo\n"
  read $fh, $x, 2;  # $x now contains "fo"
  read $fh, $x, 2;  # $x now contains "o\n"
  read $fh, $x, 20; # $x now contains "foo\nfoo\nfoo\nfoo\nfoo\n"
  my @foos = <$fh>; # @foos now contains ("foo\n") x 993

  sub my_callback {
      my $count_ref = shift;

      return if ++$$count_ref > 1000; # EOF
      return "foo\n";
  };

=for test "ex2a" end

=item Example 3

To generate a filehandle interface to data drawn from an SQL table:

=for test "ex3" begin

  my $sth = $dbh->prepare("SELECT ...");
  $sth->execute;
  my $fh = IO::Callback->new('<', sub {
      my @row = $sth->fetchrow_array;
      return unless @row; # EOF
      return join(',', @row) . "\n";
  });

  # ...

=for test "ex3" end

=item Example 4

You want a filehandle to which data can be written, where the data is discarded but an exception is raised if the data includes the string C<foo>.

=for test "ex4" begin

  my $buf = '';
  my $fh = IO::Callback->new('>', sub {
      $buf .= shift;
      die "foo written" if $buf =~ /foo/;

      if ($buf =~ /(fo?)\z/) {
          # Part way through a "foo", carry over to the next block.
          $buf = $1;
      } else {
          $buf = '';
      }
  });

=for test "ex4" end

=item Example 5

You have been given an object with a copy_data_out() method that takes a destination filehandle as an argument.  You don't want the data written to a file though, you want it split into 1024-byte blocks and inserted into an SQL database.

=for test "ex5" begin

  my $blocksize = 1024;
  my $sth = $dbh->prepare('INSERT ...');

  my $buf = '';
  my $fh = IO::Callback->new('>', sub {
      $buf .= shift;
      while (length $buf >= $blocksize) {
          $sth->execute(substr $buf, 0, $blocksize, '');
      }
  });

  $thing->copy_data_out($fh);

  if (length $buf) {
      # There is a remainder of < $blocksize
      $sth->execute($buf);
  }

=for test "ex5" end

=item Example 6

You're testing some code that reads data from a file, you want to check that it behaves as expected if it gets an IO error part way through the file.

=for test "ex6" begin

  use IO::Callback;
  use Errno qw/EIO/;

  my $block1 = "x" x 10240;
  my $block2 = "y" x 10240;
  my @blocks = ($block1, $block2);

  my $fh = IO::Callback->new('<', sub {
      return shift @blocks if @blocks;
      $! = EIO;
      return IO::Callback::Error;
  });

  # ...

=for test "ex6" end

=item Example 7

You're testing some code that writes data to a file handle, you want to check that it behaves as expected if it gets a C<file system full> error after it has written the first 100k of data.

=for test "ex7" begin

  use IO::Callback;
  use Errno qw/ENOSPC/;

  my $wrote = 0;
  my $fh = IO::Callback->new('>', sub {
      $wrote += length $_[0];
      if ($wrote > 100_000) {
          $! = ENOSPC;
          return IO::Callback::Error;
      }
  });

  # ...

=for test "ex7" end

=back

=cut

use Carp;
use Errno qw/EBADF/;
use IO::String;
use base qw/IO::String/;

sub open
{
    my $self = shift;
    return $self->new(@_) unless ref($self);

    my $mode = shift or croak "mode missing in IO::Callback::new";
    if ($mode eq '<') {
        *$self->{r} = 1;
    } elsif ($mode eq '>') {
        *$self->{w} = 1;
    } else {
        croak qq{invalid mode "$mode" in IO::Callback::new};
    }

    my $code = shift or croak "coderef missing in IO::Callback::new";
    ref $code eq "CODE" or croak "non-coderef second argument in IO::Callback::new";

    my $buf = '';
    *$self->{buf} = \$buf;
    *$self->{pos} = 0;
    *$self->{err} = 0;
    *$self->{lno} = 0;

    if (@_) {
        my @args = @_;
        *$self->{code} = sub { $code->(@_, @args) };
    } else {
        *$self->{code} = $code;
    }
}

sub close
{
    my $self = shift;
    return unless defined *$self->{code};
    return if *$self->{err};
    if (*$self->{w}) {
        my $ret = *$self->{code}('');
        if ($ret and ref $ret eq 'IO::Callback::ErrorMarker') {
            *$self->{err} = 1;
            return;
        }
    }
    foreach my $key (qw/code buf eof r w pos lno/) {
        delete *$self->{$key};
    }
    *$self->{err} = -1;
    undef *$self if $] eq "5.008";  # cargo culted from IO::String
    return 1;
}

sub opened
{
    my $self = shift;
    return defined *$self->{r} || defined *$self->{w};
}

sub getc
{
    my $self = shift;
    *$self->{r} or return $self->_ebadf;
    my $buf;
    return $buf if $self->read($buf, 1);
    return undef;
}

sub ungetc
{
    my ($self, $char) = @_;
    *$self->{r} or return $self->_ebadf;
    my $buf = *$self->{buf};
    $$buf = chr($char) . $$buf;
    --*$self->{pos};
    delete *$self->{eof};
    return 1;
}

sub eof
{
    my $self = shift;
    return *$self->{eof};
}

# Use something very distinctive for the error return code, since write callbacks
# may pay no attention to what they are returning, and it would be bad to mistake
# returned noise for an error indication.
sub Error () {
    return bless {}, 'IO::Callback::ErrorMarker';
}

sub _doread {
    my $self = shift;

    return unless *$self->{code};
    my $newbit = *$self->{code}();
    if (defined $newbit) {
        if (ref $newbit) {
            if (ref $newbit eq 'IO::Callback::ErrorMarker') {
                *$self->{err} = 1;
                return;
            } else {
                confess "unexpected reference type ".ref($newbit)." returned by callback";
            }
        }
        if (length $newbit) {
            ${*$self->{buf}} .= $newbit;
            return 1;
        }
    }

    # fall-through for both undef and ''
    delete *$self->{code};
    return;
}

sub getline
{
    my $self = shift;

    *$self->{r} or return $self->_ebadf;
    return if *$self->{eof} || *$self->{err};
    my $buf = *$self->{buf};
    $. = *$self->{lno};

    unless (defined $/) {  # slurp
        1 while $self->_doread;
        return if *$self->{err};
        *$self->{pos} += length $$buf;
        *$self->{eof} = 1;
        *$self->{buf} = \(my $newbuf = '');
        $. = ++ *$self->{lno};
        return $$buf;
    }

    my $rs = length $/ ? $/ : "\n\n";
    for (;;) {
        # In paragraph mode, discard extra newlines.
        if ($/ eq '' and $$buf =~ s/^(\n+)//) {
            *$self->{pos} += length $1;
        }
        my $pos = index $$buf, $rs;
        if ($pos >= 0) {
            *$self->{pos} += $pos+length($rs);
            my $ret = substr $$buf, 0, $pos+length($rs), '';
            unless (length $/) {
                # paragraph mode, discard extra trailing newlines
                $$buf =~ s/^(\n+)// and *$self->{pos} += length $1;
                while (*$self->{code} and length $$buf == 0) {
                    $self->_doread;
                    return if *$self->{err};
                    $$buf =~ s/^(\n+)// and *$self->{pos} += length $1;
                }
            }
            $self->_doread while *$self->{code} and length $$buf == 0 and not *$self->{err};
            if (length $$buf == 0 and not *$self->{code}) {
                *$self->{eof} = 1;
            }
            $. = ++ *$self->{lno};
            return $ret;
        }
        if (*$self->{code}) {
            $self->_doread;
            return if *$self->{err};
        } else {
            # EOL not in buffer and no more data to come - the last line is missing its EOL.
            *$self->{eof} = 1;
            *$self->{pos} += length $$buf;
            *$self->{buf} = \(my $newbuf = '');
            $. = ++ *$self->{lno} if length $$buf;
            return $$buf if length $$buf;
            return;
        }
    }
}

sub getlines
{
    croak "getlines() called in scalar context" unless wantarray;
    my $self = shift;

    *$self->{r} or return $self->_ebadf;
    return if *$self->{err} || *$self->{eof};

    # To exactly match Perl's behavior on real files, getlines() should not
    # increment $. if there is no more input, but getline() should. I won't
    # call getline() until I've established that there is more input.
    my $buf = *$self->{buf};
    unless (length $$buf) {
        $self->_doread;
        return unless length $$buf;
    }

    my($line, @lines);
    push(@lines, $line) while defined($line = $self->getline);
    return @lines;
}

sub READLINE
{
    goto &getlines if wantarray;
    goto &getline;
}

sub read
{
    my $self = shift;

    *$self->{r} or return $self->_ebadf;
    my $len = $_[1]||0;

    croak "Negative length" if $len < 0;
    return if *$self->{err};
    return 0 if *$self->{eof};
    my $buf = *$self->{buf};

    1 while *$self->{code} and $len > length $$buf and $self->_doread;
    return if *$self->{err};
    if ($len > length $$buf) {
        $len = length $$buf;
        *$self->{eof} = 1 unless $len;
    }

    if (@_ > 2) { # read offset
        my $offset = $_[2]||0;
        if ($offset < -1 * length $_[0]) {
            croak "Offset outside string";
        }
        if ($offset > length $_[0]) {
            $_[0] .= "\0" x ($offset - length $_[0]);
        }
        substr($_[0], $offset) = substr($$buf, 0, $len, '');
    }
    else {
        $_[0] = substr($$buf, 0, $len, '');
    }
    *$self->{pos} += $len;
    return $len;
}

*sysread = \&read;
*syswrite = \&write;

sub stat {
    my $self = shift;
    return unless $self->opened;
    return 1 unless wantarray;

    my @stat = $self->SUPER::stat();

    # size unknown, report 0
    $stat[7] = 0;
    $stat[12] = 1;

    return @stat;
}

sub print
{
    my $self = shift;

    my $result;
    if (defined $\) {
        if (defined $,) {
            $result = $self->write(join($,, @_).$\);
        }
        else {
            $result = $self->write(join("",@_).$\);
        }
    }
    else {
        if (defined $,) {
            $result = $self->write(join($,, @_));
        }
        else {
            $result = $self->write(join("",@_));
        }
    }

    return unless defined $result;
    return 1;
}
*printflush = \*print;

sub printf
{
    my $self = shift;
    my $fmt = shift;
    my $result = $self->write(sprintf($fmt, @_));
    return unless defined $result;
    return 1;
}

sub getpos
{
    my $self = shift;

    $. = *$self->{lno};
    return *$self->{pos};
}
*tell = \&getpos;
*pos  = \&getpos;

sub setpos
{
    croak "setpos not implemented for IO::Callback";
}

sub truncate
{
    croak "truncate not implemented for IO::Callback";
}

sub seek
{
    croak "Illegal seek";
}
*sysseek = \&seek;

sub write
{
    my $self = shift;

    *$self->{w} or return $self->_ebadf;
    return if *$self->{err};

    my $slen = length($_[0]);
    my $len = $slen;
    my $off = 0;
    if (@_ > 1) {
        my $xlen = defined $_[1] ? $_[1] : 0;
        $len = $xlen if $xlen < $len;
        croak "Negative length" if $len < 0;
        if (@_ > 2) {
            $off = $_[2] || 0;
            if ( $off >= $slen and $off > 0 and ($] < 5.011 or $off > $slen) ) {
                croak "Offset outside string";
            }
            if ($off < 0) {
                $off += $slen;
                croak "Offset outside string" if $off < 0;
            }
            my $rem = $slen - $off;
            $len = $rem if $rem < $len;
        }
    }
    return $len if $len == 0;
    my $ret = *$self->{code}(substr $_[0], $off, $len);
    if (defined $ret and ref $ret eq 'IO::Callback::ErrorMarker') {
        *$self->{err} = 1;
        return;
    }
    *$self->{pos} += $len;
    return $len;
}

sub error {
    my $self = shift;

    return *$self->{err};
}

sub clearerr {
    my $self = shift;

    *$self->{err} = 0;
}

sub _ebadf {
    my $self = shift;

    $! = EBADF;
    *$self->{err} = -1;
    return;
}

*GETC   = \&getc;
*PRINT  = \&print;
*PRINTF = \&printf;
*READ   = \&read;
*WRITE  = \&write;
*SEEK   = \&seek;
*TELL   = \&getpos;
*EOF    = \&eof;
*CLOSE  = \&close;

=head1 AUTHOR

Dave Taylor, C<< <dave.taylor.cpan at gmail.com> >>

=head1 BUGS AND LIMITATIONS

Fails to inter-operate with some library modules that read or write filehandles from within XS code. I am aware of the following specific cases, please let me know if you run into any others:

=over 4

=item C<Digest::MD5::addfile()>

=back

Please report any other bugs or feature requests to C<bug- at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IO::Callback>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Callback

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IO::Callback>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IO::Callback>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IO::Callback>

=item * Search CPAN

L<http://search.cpan.org/dist/IO::Callback>

=back

=head1 SEE ALSO

L<IO::String>, L<IO::Stringy>, L<perlfunc/open>

=head1 ACKNOWLEDGEMENTS

Adapted from code in L<IO::String> by Gisle Aas.

=head1 MANITAINER

This module is currently being maintained by Toby Inkster (TOBYINK)
for bug fixes. No substantial changes or new features are planned.

=head1 COPYRIGHT & LICENSE

Copyright 1998-2005 Gisle Aas.

Copyright 2009-2010 Dave Taylor.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of IO::Callback
