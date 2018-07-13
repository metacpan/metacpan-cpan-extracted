package FileHandle::Unget;

use strict;
use Symbol;
use FileHandle;
use Exporter;
use Scalar::Util qw( weaken );

use 5.005;

use vars qw( @ISA $VERSION $AUTOLOAD @EXPORT @EXPORT_OK );

@ISA = qw( Exporter FileHandle );

$VERSION = sprintf "%d.%02d%02d", q/0.16.34/ =~ /(\d+)/g;

@EXPORT = @FileHandle::EXPORT;
@EXPORT_OK = @FileHandle::EXPORT_OK;

# Based on dump_methods from this most helpful post by MJD:
# http://groups.google.com/groups?selm=20020621182734.15920.qmail%40plover.com
# We can't just use AUTOLOAD because AUTOLOAD is not called for inherited
# methods
sub wrap_methods
{
  no strict 'refs'; ## no critic (strict)

  my $class = shift or return;
  my $seen = shift || {};

  # Locate methods in this class
  my $symtab = \%{"$class\::"};
  my @names = keys %$symtab;
  for my $method (keys %$symtab) 
  { 
    my $fullname = "$class\::$method";

    next unless defined &$fullname;
    next if defined &{__PACKAGE__ . "::$method"};
    next if $method eq 'import';

    unless ($seen->{$method})
    {
      $seen->{$method} = $fullname;

      *{$method} = sub
        {
          my $self = $_[0];

          if (ref $self eq __PACKAGE__)
          {
            shift @_;
            my $super = "SUPER::$method";
            $self->$super(@_);
          }
          else
          {
            $method = "FileHandle::$method";
            &$method(@_);
          }
        };
    }
  }

  # Traverse parent classes of this one
  my @ISA = @{"$class\::ISA"};
  for my $class (@ISA)
  {
    wrap_methods($class, $seen);
  }
}

wrap_methods('FileHandle');

#-------------------------------------------------------------------------------

sub DESTROY
{
}

#-------------------------------------------------------------------------------

sub new
{
  my $class = shift;

  my $self;

  if (defined $_[0] && defined fileno $_[0])
  {
    $self = shift;
  }
  else
  {
    $self = $class->SUPER::new(@_);
    return undef unless defined $self; ## no critic (ProhibitExplicitReturnUndef)
  }

  my $values =
    {
      'fh' => $self,
      'eof_called' => 0,
      'filehandle_unget_buffer' => '',
    };

  weaken($values->{'fh'});
  
  tie *$self, "${class}::Tie", $values;

  bless $self, $class;
  return $self;
}

#-------------------------------------------------------------------------------

sub new_from_fd
{
  my $class = shift;

  my $self;

#  if (defined $_[0] && defined fileno $_[0])
#  {
#    $self = shift;
#  }
#  else
  {
    $self = $class->SUPER::new_from_fd(@_);
    return undef unless defined $self; ## no critic (ProhibitExplicitReturnUndef)
  }

  my $values =
    {
      'fh' => $self,
      'eof_called' => 0,
      'filehandle_unget_buffer' => '',
    };

  weaken($values->{'fh'});
  
  tie *$self, "${class}::Tie", $values;

  bless $self, $class;
  return $self;
}

#-------------------------------------------------------------------------------

sub ungetc
{
  my $self = shift;
  my $ord = shift;

  substr(tied(*$self)->{'filehandle_unget_buffer'},0,0) = chr($ord);
}

#-------------------------------------------------------------------------------

sub ungets
{
  my $self = shift;
  my $string = shift;

  substr(tied(*$self)->{'filehandle_unget_buffer'},0,0) = $string;
}

#-------------------------------------------------------------------------------

sub buffer
{
  my $self = shift;

  tied(*$self)->{'filehandle_unget_buffer'} = shift if @_;
  return tied(*$self)->{'filehandle_unget_buffer'};
}

#-------------------------------------------------------------------------------

sub input_record_separator
{
  my $self = shift;

  if(@_)
  {
    tied(*$self)->{'input_record_separator'} = shift;
  }

  return undef unless exists tied(*$self)->{'input_record_separator'}; ## no critic (ProhibitExplicitReturnUndef)
  return tied(*$self)->{'input_record_separator'};
}

#-------------------------------------------------------------------------------

sub clear_input_record_separator
{
  my $self = shift;

  delete tied(*$self)->{'input_record_separator'};
}

###############################################################################

package FileHandle::Unget::Tie;

use strict;
use FileHandle;
use bytes;

use 5.000;

use vars qw( $VERSION $AUTOLOAD @ISA );

@ISA = qw( IO::Handle );

$VERSION = '0.10';

#-------------------------------------------------------------------------------

my %tie_mapping = (
  PRINT => 'print', PRINTF => 'printf', WRITE => 'syswrite',
  READLINE => 'getline_wrapper', GETC => 'getc', READ => 'read', CLOSE => 'close',
  BINMODE => 'binmode', OPEN => 'open', EOF => 'eof', FILENO => 'fileno',
  SEEK => 'seek', TELL => 'tell', FETCH => 'fetch',
);

#-------------------------------------------------------------------------------

sub AUTOLOAD
{
  my $name = $AUTOLOAD;
  $name =~ s/.*://;

  die "Unhandled function $name!" unless exists $tie_mapping{$name};

  my $sub = $tie_mapping{$name};

  # Alias the anonymous subroutine to the name of the sub we want ...
  no strict 'refs'; ## no critic (strict)
  *{$name} = sub
    {
      my $self = shift;

      if (defined &$sub)
      {
        &$sub($self,@_);
      }
      else
      {
        # Prevent recursion
        # Temporarily disable warnings so that we don't get "untie attempted
        # while 1 inner references still exist". Not sure what's the "right
        # thing" to do here.
        {
          local $^W = 0;
          untie *{$self->{'fh'}};
        }

        $self->{'fh'}->$sub(@_);

        tie *{$self->{'fh'}}, __PACKAGE__, $self;
      }
    };

  # ... and go to it.
  goto &$name;
}

#-------------------------------------------------------------------------------

sub DESTROY
{
}

#-------------------------------------------------------------------------------

sub TIEHANDLE
{
  my $class = shift;
  my $self = shift;

  bless($self, $class);

  return $self;
}

#-------------------------------------------------------------------------------

sub binmode
{
  my $self = shift;

  warn "Under windows, calling binmode after eof exposes a bug that exists in some versions of Perl.\n"
    if $self->{'eof_called'};

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  if (@_)
  {
    binmode $self->{'fh'}, @_;
  }
  else
  {
    binmode $self->{'fh'};
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self;
}

#-------------------------------------------------------------------------------

sub fileno
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my $fileno = fileno $self->{'fh'};

  tie *{$self->{'fh'}}, __PACKAGE__, $self;

  return $fileno;
}

#-------------------------------------------------------------------------------

sub getline_wrapper
{
  if (wantarray)
  {
    goto &getlines;
  }
  else
  {
    goto &getline;
  }
}

#-------------------------------------------------------------------------------

sub getline
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my $line;

  local $/ = $self->{'input_record_separator'}
    if exists $self->{'input_record_separator'};
  my $input_record_separator = $/;

  if (defined $input_record_separator &&
      $self->{'filehandle_unget_buffer'} =~ /(.*?$input_record_separator)/)
  {
    $line = $1;
    substr($self->{'filehandle_unget_buffer'},0,length $line) = '';
  }
  # My best guess at a fix for failures like these:
  # http://www.cpantesters.org/cpan/report/2185d342-b14c-11e4-9727-fcccf9ba27bb
  # http://www.cpantesters.org/cpan/report/74a6f9b6-95db-11e4-8169-9f55a5948d86
  # It seems like even though $/ == undef, we're not reading all the rest of
  # the file. Unfortunately I can't repro this, so I'll change it and see if
  # the CPAN-Testers tests start passing.
  elsif (!defined($input_record_separator))
  {
    $line = $self->{'filehandle_unget_buffer'};
    $self->{'filehandle_unget_buffer'} = '';
    my @other_lines = $self->{'fh'}->getlines(@_);

    # Not sure if this is necessary. The code in getlines() below seems to
    # suggest so.
    @other_lines = () if @other_lines && !defined($other_lines[0]);

    if ($line eq '' && !@other_lines)
    {
      $line = undef;
    }
    else
    {
      $line .= join('', @other_lines);
    }
  }
  else
  {
    $line = $self->{'filehandle_unget_buffer'};
    $self->{'filehandle_unget_buffer'} = '';
    my $templine = $self->{'fh'}->getline(@_);

    if ($line eq '' && !defined $templine)
    {
      $line = undef;
    }
    elsif (defined $templine)
    {
      $line .= $templine;
    }
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self;

  return $line;
}

#-------------------------------------------------------------------------------

sub getlines
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my @buffer_lines;

  local $/ = $self->{'input_record_separator'}
    if exists $self->{'input_record_separator'};
  my $input_record_separator = $/;

  if (defined $input_record_separator)
  {
    $self->{'filehandle_unget_buffer'} =~
      s/^(.*$input_record_separator)/push @buffer_lines, $1;''/mge;

    my @other_lines = $self->{'fh'}->getlines(@_);

    if (@other_lines)
    {
      if (defined $other_lines[0])
      {
        substr($other_lines[0],0,0) = $self->{'filehandle_unget_buffer'};
      }
    }
    else
    {
      if ($self->{'filehandle_unget_buffer'} ne '')
      {
        unshift @other_lines, $self->{'filehandle_unget_buffer'};
      }
    }

    $self->{'filehandle_unget_buffer'} = '';

    push @buffer_lines, @other_lines;
  }
  else
  {
    $buffer_lines[0] = $self->{'filehandle_unget_buffer'};
    $self->{'filehandle_unget_buffer'} = '';
    # Not sure why this isn't working for some platforms. If $/ is undef, then
    # all the lines should be in [0].
#    my $templine = ($self->{'fh'}->getlines(@_))[0];
    my @other_lines = $self->{'fh'}->getlines(@_);

    if ($buffer_lines[0] eq '' && !defined $other_lines[0])
    {
      # Should this really be "(undef)" and not just "undef"? Leaving it for
      # now, to avoid changing the API until I know the answer.
      $buffer_lines[0] = undef;
    }
    else
    {
      $buffer_lines[0] .= join('', @other_lines);
    }
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self;

  return @buffer_lines;
}

#-------------------------------------------------------------------------------

sub getc
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my $char;

  if ($self->{'filehandle_unget_buffer'} ne '')
  {
    $char = substr($self->{'filehandle_unget_buffer'},0,1);
    substr($self->{'filehandle_unget_buffer'},0,1) = '';
  }
  else
  {
    $char = $self->{'fh'}->getc(@_);
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self;

  return $char;
}

#-------------------------------------------------------------------------------

sub read
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my $scalar = \$_[0];
  my $length = $_[1];
  my $offset = $_[2];

  my $num_bytes_read = 0;

  if ($self->{'filehandle_unget_buffer'} ne '')
  {
    my $read_string = substr($self->{'filehandle_unget_buffer'},0,$length);
    substr($self->{'filehandle_unget_buffer'},0,$length) = '';

    my $num_bytes_buffer = length $read_string;

    # Try to read the rest
    if (length($read_string) < $length)
    {
      $num_bytes_read = read($self->{'fh'}, $read_string,
        $length - $num_bytes_buffer, $num_bytes_buffer);
    }

    if (defined $offset)
    {
      $$scalar = '' unless defined $$scalar;
      substr($$scalar,$offset) = $read_string;
    }
    else
    {
      $$scalar = $read_string;
    }

    $num_bytes_read += $num_bytes_buffer;
  }
  else
  {
    if (defined $_[2])
    {
      $num_bytes_read = read($self->{'fh'},$_[0],$_[1],$_[2]);
    }
    else
    {
      $num_bytes_read = read($self->{'fh'},$_[0],$_[1]);
    }
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self;

  return $num_bytes_read;
}

#-------------------------------------------------------------------------------

sub seek
{
  my $self = shift;
  my $position = $_[0];
  my $whence = $_[1];

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  if($whence != 0 && $whence != 1 && $whence != 2)
  {
    tie *{$self->{'fh'}}, __PACKAGE__, $self;
    return 0;
  }

  my $status;

  # First try to seek using the built-in seek
  if (seek($self->{'fh'},$position,$whence))
  {
    $self->{'filehandle_unget_buffer'} = '';
    $status = 1;
  }
  else
  {
    my $absolute_position;

    $absolute_position = $position if $whence == 0;
    $absolute_position = $self->tell + $position if $whence == 1;
    $absolute_position = -s $self->{'fh'} + $position if $whence == 2;

    if ($absolute_position <= tell $self->{'fh'})
    {
      if ($absolute_position >= $self->tell)
      {
        substr($self->{'filehandle_unget_buffer'}, 0,
          $absolute_position - $self->tell) = '';
        $status = 1;
      }
      else
      {
        # Can't seek backward!
        $status = 0;
      }
    }
    else
    {
      # Shouldn't the built-in seek handle this?!
      warn "Seeking forward is not yet implemented in " . __PACKAGE__ . "\n";
      $status = 0;
    }
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self;

  return $status;
}

#-------------------------------------------------------------------------------

sub tell
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my $file_position = tell $self->{'fh'};

  if ($file_position == -1)
  {
    tie *{$self->{'fh'}}, __PACKAGE__, $self;
    return -1;
  }

  $file_position -= length($self->{'filehandle_unget_buffer'});

  tie *{$self->{'fh'}}, __PACKAGE__, $self;

  return $file_position;
}

#-------------------------------------------------------------------------------

sub eof
{
  my $self = shift;

  # Prevent recursion
  # Temporarily disable warnings so that we don't get "untie attempted
  # while 1 inner references still exist". Not sure what's the "right
  # thing" to do here.
  {
    local $^W = 0;
    untie *{$self->{'fh'}};
  }

  my $eof;

  if ($self->{'filehandle_unget_buffer'} ne '')
  {
    $eof = 0;
  }
  else
  {
    $eof = $self->{'fh'}->eof();
  }

  tie *{$self->{'fh'}}, __PACKAGE__, $self;

  $self->{'eof_called'} = 1;

  return $eof;
}

#-------------------------------------------------------------------------------

sub fetch
{
  my $self = shift;
  return $self;
}

1;

__END__

# -----------------------------------------------------------------------------

=head1 NAME

FileHandle::Unget - FileHandle which supports multi-byte unget


=head1 SYNOPSIS

  use FileHandle::Unget;
  
  # open file handle
  my $fh = FileHandle::Unget->new("file")
    or die "cannot open filehandle: $!";
  
  my $buffer;
  read($fh,$buffer,100);
  print $buffer;

  print <$fh>;
  
  $fh->close;


=head1 DESCRIPTION

FileHandle::Unget operates exactly the same as FileHandle, except that it
provides a version of ungetc that allows you to unget more than one character.
It also provides ungets to unget a string.

This module is useful if the filehandle refers to a stream for which you can't
just C<seek()> backwards. Some operating systems support multi-byte
C<ungetc()>, but this is not guaranteed. Use this module if you want a
portable solution. In addition, on some operating systems, eof() will not be
reset if you ungetc after having read to the end of the file.

NOTE: Using C<sysread()> with C<ungetc()> and other buffering functions is
still a bad idea.

=head1 METHODS

The methods for this package are the same as those of the FileHandle package,
with the following exceptions.

=over 4

=item new ( ARGS )

The constructor is exactly the same as that of FileHandle, except that you can
also call it with an existing IO::Handle object to "attach" unget semantics to
a pre-existing handle.


=item $fh->ungetc ( ORD )

Pushes a character with the given ordinal value back onto the given handle's
input stream. This method can be called more than once in a row to put
multiple values back on the stream. Memory usage is equal to the total number
of bytes pushed back.


=item $fh->ungets ( BUF )

Pushes a buffer back onto the given handle's input stream. This method can be
called more than once in a row to put multiple buffers of characters back on
the stream.  Memory usage is equal to the total number of bytes pushed back.

The buffer is not processed in any way--managing end-of-line characters and
whatnot is your responsibility.


=item $fh->buffer ( [BUF] )

Get or set the pushback buffer directly.


=item $fh->input_record_separator ( STRING )

Get or set the per-filehandle input record separator. If an argument is
specified, the input record separator for the filehandle is made independent of
the global $/. Until this method is called (and after
clear_input_record_separator is called) the global $/ is used.

Note that a return value of "undef" is ambiguous. It can either mean that this
method has never been called with an argument, or it can mean that it was called
with an argument of "undef".


=item $fh->clear_input_record_separator ()

Clear the per-filehandle input record separator. This removes the
per-filehandle input record separator semantics, reverting the filehandle to
the normal global $/ semantics.


=item tell ( $fh )

C<tell> returns the actual file position minus the length of the unget buffer.
If you read three bytes, then unget three bytes, C<tell> will report a file
position of 0. 

Everything works as expected if you are careful to unget the exact same bytes
which you read.  However, things get tricky if you unget different bytes.
First, the next bytes you read won't be the actual bytes on the filehandle at
the position indicated by C<tell>.  Second, C<tell> will return a negative
number if you unget more bytes than you read. (This can be problematic since
this function returns -1 on error.)


=item seek ( $fh, [POSITION], [WHENCE] )

C<seek> defaults to the standard seek if possible, clearing the unget buffer
if it succeeds. If the standard seek fails, then C<seek> will attempt to seek
within the unget buffer. Note that in this case, you will not be able to seek
backward--FileHandle::Unget will only save a buffer for the next bytes to be
read.

For example, let's say you read 10 bytes from a pipe, then unget the 10 bytes.
If you seek 5 bytes forward, you won't be able to read the first five bytes.
(Otherwise this module would have to keep around a lot of probably useless
data!)

=back


=head1 COMPATIBILITY

To test that this module is indeed a drop-in replacement for FileHandle, the
following modules were modified to use FileHandle::Unget, and tested using
"make test". They have all passed.


=head1 BUGS

There is a bug in Perl on Windows that is exposed if you open a stream, then
check for eof, then call binmode. For example:

  # First line
  # Second line

  open FH, "$^X -e \"open F, '$0';binmode STDOUT;print <F>\" |";

  eof(FH);
  binmode(FH);

  print "First line:", scalar <FH>, "\n";
  print "Second line:", scalar <FH>, "\n";

  close FH;

One solution is to make sure that you only call binmode immediately after
opening the filehandle. I'm not aware of any workaround for this bug that
FileHandle::Unget could implement. However, the module does detect this
situation and prints a warning.

Contact david@coppit.org for bug reports and suggestions.


=head1 AUTHOR

David Coppit <david@coppit.org>.


=head1 LICENSE

This code is distributed under the GNU General Public License (GPL) Version 2.
See the file LICENSE in the distribution for details.


=head1 SEE ALSO

Mail::Mbox::MessageParser for an example of how to use this package.

=cut
