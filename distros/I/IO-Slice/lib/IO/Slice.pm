package IO::Slice;
{
  $IO::Slice::VERSION = '0.2';
}

# ABSTRACT: restrict reads to a range in a file

use strict;
use English qw< -no_match_vars >;
use Symbol ();
use Fcntl qw< :seek >;
use Log::Log4perl::Tiny qw< :easy :dead_if_first >;


sub new {
   my $package = shift;
   my $efh = Symbol::gensym();
   my $self = tie *$efh, $package;
   $self->open(@_) if @_;
   return $efh;
}

sub TIEHANDLE {
   DEBUG "TIEHANDLE(@_)";
   my $package = shift;
   my $self = bless {}, $package;
   return $self;
}

sub DESTROY {
   DEBUG "DESTROY(@_)";
}


sub open {
   my $self = shift;
   my %args = ref($_[0]) ? %{$_[0]} : @_;

   $self->close();

   # mandatory features
   for my $mandatory (qw< offset length >) {
      LOGCROAK "open(): missing mandatory feature $mandatory"
         unless defined $args{$mandatory};
      $self->{$mandatory} = $args{$mandatory};
   }

   # optional/conditional features
   $self->{filename} = defined($args{filename})
      ? $args{filename} : '*undefined*';

   # underlying filehandle
   if ($args{fh}) {
      $self->{fh} = $args{fh};
   }
   else {
      LOGCROAK "open(): either fh or filename MUST be provided"
         unless exists $args{filename};
      open my $fh, '<:raw', $args{filename}
         or LOGCROAK "open('$args{filename}'): $OS_ERROR";
      $self->{fh} = $fh;
   }

   $self->{position} = 0;

   return $self; # been there, done that
}


sub close {
   my $self = shift;
   %$self = ();
   return 1;
}


sub opened {
   my $self = shift;
   return exists $self->{fh};
}


sub binmode {
   my $self = shift;
   return ! scalar @_;
}


sub getc {
   my $self = shift;
   my $buf;
   return $buf if $self->read($buf, 1);
   return undef;
}


sub ungetc {
   my $self = shift;
   $self->pos($self->{position} - 1);
   return 1;
}


sub eof {
   my $self = shift;
   return $self->{position} >= $self->{length};
}


sub pos {
   my $self = shift;
   my $retval = $self->{position};
   if (@_) {
      my $newpos = shift;
      $newpos ||= 0;
      $newpos = 0 if $newpos !~ m{\A\d+\z}mxs;
      $newpos += 0; # make it a "normal" non-negative integer
      $newpos = $self->{length} if $newpos > $self->{length};
      $self->{position} = $newpos;
   }
   return $retval;
}


sub seek {
   my ($self, $offset, $whence) = @_;

   $whence = '*undefined*' unless defined $whence;
   if ($whence == SEEK_SET) {
      $self->pos($offset);
   }
   elsif ($whence == SEEK_CUR) {
      $self->pos($self->{position} + $offset);
   }
   elsif ($whence == SEEK_END) {
      $self->pos($self->{length} + $offset);
   }
   else {
      LOGCROAK "seek(): whence value $whence is not valid";
   }

   return 1;
}


sub tell { return shift->{position} }


sub do_read {
   my ($self, $count) = @_;
   my $buf;
   defined (my $nread = $self->read($buf, $count)) or return;
   return $buf;
}


sub getline {
   my $self = shift;
   return if $self->{position} >= $self->{length};

   return $self->do_read($self->{length} - $self->{position})
      unless defined $INPUT_RECORD_SEPARATOR; # slurp mode

   my $chunk_size = 100;
   if (! length $INPUT_RECORD_SEPARATOR) { # paragraph mode
      return $self->_conditioned_getstuff(sub {
         my $idx = CORE::index $_[0], "\n\n";
         return if $idx < 0;
         my $nreturn = ++$idx;
         my $buflen = length $_[0];
         ++$idx;
         ++$idx while ($idx < $buflen) && (substr($_[0], $idx, 1) eq "\n");
         return ($nreturn, $idx);
      });
   }

   # look for $INPUT_RECORD_SEPARATOR, precisely
   return $self->_conditioned_getstuff(sub {
      my $idx = CORE::index $_[0], $INPUT_RECORD_SEPARATOR;
      return if $idx < 0;
      my $n = $idx + length($INPUT_RECORD_SEPARATOR);
      return ($n, $n);
   });
}

sub _conditioned_getstuff {
   my ($self, $condition, $chunk_size) = @_;
   $chunk_size ||= 100;
   my $initial_position = $self->{position};
   my $buffer;
   while ($self->{position} < $self->{length}) {
      my $chunk = $self->do_read($chunk_size);
      if (! $chunk) {
         $self->{position} = $initial_position;
         return;
      }
      $buffer = defined($buffer) ? $buffer . $chunk : $chunk;
      if (my ($nreturn, $ndelete) = $condition->($buffer)) {
         $buffer = substr $buffer, 0, $nreturn;
         $self->pos($initial_position + $ndelete);
         return $buffer;
      }
   }
   return $buffer;
}


sub getlines {
   LOGCROAK "getlines is only valid in list context"
      unless wantarray();
   my $self = shift;
   my ($line, @lines);
   push @lines, $line while defined($line = $self->getline());
   return @lines;
}

sub READLINE {
   goto &getlines if wantarray();
   goto &getline;
}


sub read {
   my $self = shift;
   my $bufref = \shift;
   my $length = shift;

   my $position = $self->{position};
   my $data_length = $self->{length};
   return 0 if $position >= $data_length;

   my $fh = $self->{fh};
   CORE::seek $fh, ($self->{offset} + $position), SEEK_SET
      or return;

   my $available = $data_length - $position;
   $length = $available if $length > $available;

   defined (my $nread = read $fh, $$bufref, $length, @_)
      or return;
   $self->pos($position + $nread);
   return $nread;
}

{
   no strict 'refs';
   no warnings 'once';


   *sysseek = \&seek;
   *sysread = \&read;


   my $nothing = sub { return };
   *print = $nothing;
   *printflush = $nothing;
   *printf = $nothing;
   *fileno = $nothing;
   *error  = $nothing;
   *clearerr = $nothing;
   *sync = $nothing;
   *write = $nothing;
   *setbuf = $nothing;
   *setvbuf = $nothing;
   *untaint = $nothing;
   *autoflush = $nothing;
   *fcntl = $nothing;
   *ioctl = $nothing;
   *input_line_number = $nothing;

   *GETC = \&getc;
   *PRINT = $nothing;
   *PRINTF = $nothing;
   *READ = \&read;
   *WRITE = $nothing;
   *SEEK = \&seek;
   *TELL = \&tell;
   *EOF  = \&eof;
   *CLOSE = \&close;
   *BINMODE = \&binmode;
   *FILENO = $nothing;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Slice - restrict reads to a range in a file

=head1 VERSION

version 0.2

=head1 SYNOPSIS

   use IO::Slice;

   # Define a slice based on a file
   my $sfh = IO::Slice->new(
      filename => '/path/to/file',
      offset   => 13,
      length   => 16,
   );

   # Ditto, based on a previously available filehandle $fh. The
   # filehandle MUST be seekable.
   my $sfh = IO::Slice->new(
      fh     => $fh,
      offset => 13,
      length => 16,
   );

   # Both the filehandle and the filename can be provided. The
   # filehandle will win.
   my $sfh = IO::Slice->new(
      fh       => $fh,
      filename => '/path/to/file',
      offset   => 13,
      length   => 16,
   );

   # Whatever, you can use $sfh as any other filehandle, mostly.

=head1 DESCRIPTION

This module allows the definition of a filehandle that only works on
a slice of an input file. The C<new> method provides back a GLOB that
can be used as any other filehandle, mostly, with the notable
exception of some methods like C<stat>, C<fileno> and the tracking
of the input lines.

   my $sfh = IO::Slice->new(
      filename => '/path/to/file',
      offset   => 13,
      length   => 16,
   );

The provided handle works only for reading, not for writing.

The parameters that you can pass to the constructor are:

=over

=item *

the source of data. This can be provided by either a filename (through
the C<filename> key) or a filehandle (through the C<fh> key). If both
are provided, the filehandle will take precedence for getting the data.

=item *

the C<offset>, specifying an offset where the slice starts. C<0> means
the start of the file

=item *

the C<length>, specifying the number of bytes in the slice

=back

=head1 METHODS

=head2 B<< new >>

create a new IO::Slice object.

Parameters can be passed either as an hash reference or
key-value pairs. Useful parameters are:

=over

=item C<offset>

set the offset of the slice from the start of file. This is mandatory

=item C<length>

set the length of the slice. This is mandatory.

=back

Neither C<offset> nor C<length> are tested for correctness against the
file.

You have to provide at least one of C<fh> and C<filename> so that the
data source can be reached. If you provide both, C<fh> will used for
taking the data.

Returns the object. Throws an exception in case of errors.

=head2 B<< open >>

open a slice. Parameters are the same as the L</new> method.

=head2 B<< close >>

close the tied handle and the associated object.

=head2 B<< opened >>

assess whether the object is associated to an opened file

=head2 B<< binmode >>

support the binmode method... but in a fake way, does not
accept anything actually.

=head2 B<< getc >>

get one byte from the input stream.

=head2 B<< ungetc >>

release one byte back into the input stream

=head2 B<< eof >>

test whether there are still bytes to read or we are at the
end of the file

=head2 B<< pos >>

accessor for the position. It allows you to set the position by
passing an input parameter, and to retrieve the current position.

=head2 B<< seek >>

set current position in the stream. Two positional parameters are
accepted:

=over

=item * offset

specifies the offset to use

=item * whence

specifies the reference point for applying the offset

=back

Both are consistent with what you find in CORE::seek documentation.

=head2 B<< tell >>

get current position in the stream.

=head2 B<< do_read >>

convenience function around C<read>. Takes as input the count of
needed bytes and outputs a string that is the result of the
underlying C<read>, without requiring you to provide a buffer.

=head2 B<< getline >>

get a line from the input. Returns a single scalar with one line.

This honors C<$/> (aka C<$INPUT_RECORD_SEPARATOR>), so I<line> might
not be what you generally consider a line.

=head2 B<< getlines >>

list-version for getting lines, propedeutic to READLINE

=head2 B<< read >>

read bytes from the stream. The interface is the same as the
CORE::read function, with the following positional parameters:

=over

=item * filehandle

mandatory parameter

=item * buffer

mandatory parameter

=item * offset

optional parameter, used for putting data into the buffer

=back

Returns undef if errors arise or end of file. Returns number of 
read characters otherwise (0 if end of file).

=head2 B<< sysseek >>

alias of L</seek>

=head2 B<< sysread >>

alias for L</read>

=head2 Nullified Functions

The following functions are defined but don't actually do anything.

=over

=item print

=item printflush

=item printf

=item fileno

=item error

=item clearerr

=item sync

=item write

=item setbuf

=item setvbuf

=item untaint

=item autoflush

=item fcntl

=item ioctl

=item input_line_number

=back

=head1 SEE ALSO

This module is heavily inspired (and in some places based) on code from
L</IO::String> 1.08 by Gisle Aas.

=head1 AUTHOR

Flavio Poletti <polettix@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Flavio Poletti <polettix@cpan.org>

This module is free software.  You can redistribute it and/or
modify it under the terms of the Artistic License 2.0.

This program is distributed in the hope that it will be useful,
but without any warranty; without even the implied warranty of
merchantability or fitness for a particular purpose.

=cut
