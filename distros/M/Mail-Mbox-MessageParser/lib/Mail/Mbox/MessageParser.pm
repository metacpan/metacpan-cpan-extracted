package Mail::Mbox::MessageParser;

use strict;
use 5.005;
use Carp;
use FileHandle::Unget;
use File::Spec;
use File::Temp;
sub _dprint;

use Mail::Mbox::MessageParser::MetaInfo;
use Mail::Mbox::MessageParser::Config;

use Mail::Mbox::MessageParser::Perl;
use Mail::Mbox::MessageParser::Grep;
use Mail::Mbox::MessageParser::Cache;

use vars qw( @ISA $VERSION $_DEBUG );
use vars qw( $_CACHE $UPDATING_CACHE );

@ISA = qw(Exporter);

$VERSION = sprintf "%d.%02d%02d", q/1.51.11/ =~ /(\d+)/g;
$_DEBUG = 0;

#-------------------------------------------------------------------------------

# The class-wide cache, which will be read and written when necessary. i.e.
# read when an folder reader object is created which uses caching, and
# written when a different cache is specified, or when the program exits, 
*_CACHE = \$Mail::Mbox::MessageParser::MetaInfo::_CACHE;

*UPDATING_CACHE = \$Mail::Mbox::MessageParser::MetaInfo::UPDATING_CACHE;
*SETUP_CACHE = \&Mail::Mbox::MessageParser::MetaInfo::SETUP_CACHE;
sub SETUP_CACHE;

#-------------------------------------------------------------------------------

# Outputs debug messages if $_DEBUG is true. 

sub _dprint
{
  return 1 unless $_DEBUG;

  my $message = join '',@_;

  foreach my $line (split /\n/, $message)
  {
    warn "DEBUG (" . __PACKAGE__ . "): $line\n";
  }

  # Be sure to return 1 so code like '_dprint "blah\n" and exit' works.
  return 1;
}

#-------------------------------------------------------------------------------

sub new
{
  my ($proto, $options, $cache_options) = @_;

  my $class = ref($proto) || $proto;

  carp "You must provide either a file name or a file handle"
    unless defined $options->{'file_name'} || defined $options->{'file_handle'};

  # Can't use grep or cache unless there is a filename
  unless (defined $options->{'file_name'})
  {
    $options->{'enable_cache'} = 0;
    $options->{'enable_grep'} = 0;
  }

  $_DEBUG = $options->{'debug'}
    if defined $options->{'debug'};

  my ($file_type, $need_to_close_filehandle, $error, $endline);

  ($options->{'file_handle'}, $file_type, $need_to_close_filehandle, $error, $endline) =
    _PREPARE_FILE_HANDLE($options->{'file_name'}, $options->{'file_handle'});

  if (defined $error &&
    !($error eq 'Not a mailbox' && $options->{'force_processing'}) &&
    !($error =~ 'Found a mix of unix and Windows line endings' && $options->{'force_processing'})
    )
  {
    # Here I assume the only errors for which the filehandle was opened is
    # "Not a mailbox" and mixed line endings
    close $options->{'file_handle'}
      if $error eq 'Not a mailbox' || $error =~ /Found a mix of unix and Windows line endings/;
    return $error;
  }

  # Grep implementation doesn't support compression right now
  $options->{'enable_grep'} = 0 if _IS_COMPRESSED_TYPE($file_type);

  $options->{'enable_cache'} = 1 unless defined $options->{'enable_cache'};;
  $options->{'enable_grep'} = 1 unless defined $options->{'enable_grep'};;

  my $self = undef;

  if ($options->{'enable_cache'})
  {
    $self = new Mail::Mbox::MessageParser::Cache($options, $cache_options);

    unless (ref $self)
    {
      warn "Couldn't instantiate Mail::Mbox::MessageParser::Cache: $self";
      $self = undef;
    }

    if ($UPDATING_CACHE)
    {
      _dprint "Couldn't instantiate Mail::Mbox::MessageParser::Cache: " .
        "Updating cache";
      $self = undef;
    }
  }

  if (!defined $self && $options->{'enable_grep'})
  {
    $self = new Mail::Mbox::MessageParser::Grep($options);

    unless (ref $self)
    {
      if ($self =~ /not installed/)
      {
        _dprint "Couldn't instantiate Mail::Mbox::MessageParser::Grep: $self";
      }
      else
      {
        warn "Couldn't instantiate Mail::Mbox::MessageParser::Grep: $self";
      }
      $self = undef;
    }
  }

  if (!defined $self)
  {
    $self = new Mail::Mbox::MessageParser::Perl($options);

    warn "Couldn't instantiate Mail::Mbox::MessageParser::Perl: $self"
      unless ref $self;
  }

  die "Couldn't instantiate any mailbox parser implementation"
    unless defined $self;

  _dprint "Instantiate mailbox parser implementation: " . ref $self;

  $self->_print_debug_information();

  $self->_read_prologue();

  $self->{'need_to_close_filehandle'} = $need_to_close_filehandle;

  $self->{'endline'} = $endline;

  return $self;
}

#-------------------------------------------------------------------------------

sub _init
{
  my $self = shift;

  $self->{'email_line_number'} = 0;
  $self->{'email_offset'} = 0;
  $self->{'email_length'} = 0;
  $self->{'email_number'} = 0;
}

#-------------------------------------------------------------------------------

sub DESTROY
{
  my $self = shift;

  $self->{'file_handle'}->close() if $self->{'need_to_close_filehandle'};
}

#-------------------------------------------------------------------------------

# Returns:
# - a file handle to the decompressed mailbox
# - the file type (see _GET_FILE_TYPE)
# - a boolean indicating whether the caller needs to close the file handle
# - an error message (or undef)
# - the endline: "\n", "\r\n", or undef
sub _PREPARE_FILE_HANDLE
{
  my $file_name = shift;
  my $file_handle = shift;

  _dprint "Preparing file handle";

  if (defined $file_handle)
  {
    # Promote this to a FileHandle::Unget if it isn't already
    $file_handle = new FileHandle::Unget($file_handle)
      unless UNIVERSAL::isa($file_handle, 'FileHandle::Unget');

    binmode $file_handle;

    my $file_type = _GET_FILE_TYPE(\$file_handle);
    _dprint "Filehandle file type: $file_type";

    # Do decompression if we need to
    if (_IS_COMPRESSED_TYPE($file_type))
    {
      my ($decompressed_file_handle,$error) =
        _DO_DECOMPRESSION($file_handle, $file_type);

      return ($file_handle,$file_type,0,$error,undef)
        unless defined $decompressed_file_handle;

      return ($decompressed_file_handle,$file_type,0,"Not a mailbox",undef)
        if _GET_FILE_TYPE(\$decompressed_file_handle) ne 'mailbox';

      my $endline;
      ($endline, $error) = _GET_ENDLINE(\$decompressed_file_handle);

      return ($decompressed_file_handle,$file_type,0,$error,$endline);
    }
    else
    {
      _dprint "Filehandle is not compressed";

      my ($endline, $error) = _GET_ENDLINE(\$file_handle);

      return ($file_handle,$file_type,0,"Not a mailbox",$endline)
        if !eof($file_handle) && $file_type ne 'mailbox';

      return ($file_handle,$file_type,0,$error,$endline);
    }
  }
  else
  {
    my $file_type = _GET_FILE_TYPE(\$file_name);
    _dprint "Filename \"$file_name\" file type: $file_type";

    my ($opened_file_handle,$error) =
      _OPEN_FILE_HANDLE($file_name, $file_type);

    return ($file_handle,$file_type,0,$error,undef)
      unless defined $opened_file_handle;

    my $endline;
    ($endline, $error) = _GET_ENDLINE(\$opened_file_handle);

    if (_IS_COMPRESSED_TYPE($file_type))
    {
      return ($opened_file_handle,$file_type,1,"Not a mailbox",$endline)
        if _GET_FILE_TYPE(\$opened_file_handle) ne 'mailbox';

      return ($opened_file_handle,$file_type,1,$error,$endline);
    }
    else
    {
      return ($opened_file_handle,$file_type,1,"Not a mailbox",$endline)
        if $file_type ne 'mailbox';

      return ($opened_file_handle,$file_type,1,$error,$endline);
    }
  }
}

#-------------------------------------------------------------------------------

# This function does not analyze the file to determine if it is valid. It only
# opens it using a suitable decompresson if necessary.
sub _OPEN_FILE_HANDLE
{
  my $file_name = shift;
  my $file_type = shift;

  _dprint "Opening file \"$file_name\"";

  # Non-compressed file
  unless (_IS_COMPRESSED_TYPE($file_type))
  {
    my $file_handle = new FileHandle::Unget($file_name);
    return (undef,"Can't open $file_name: $!") unless defined $file_handle;

    binmode $file_handle;

    _dprint "File \"$file_name\" is not compressed";

    return ($file_handle,undef);
  }

  # It must be a known compressed file type
  return (undef,"Can't decompress $file_name--no decompressor available")
    unless defined $Mail::Mbox::MessageParser::Config{'programs'}{$file_type};

  my $filter_command = qq{"$Mail::Mbox::MessageParser::Config{'programs'}{$file_type}" -cd "$file_name" |};

  _dprint "Calling \"$filter_command\" to decompress file \"$file_name\".";

  my $oldstderr;
  open $oldstderr,">&STDERR" or die "Can't save STDERR: $!\n";
  open STDERR,">" . File::Spec->devnull()
    or die "Can't redirect STDERR to " . File::Spec->devnull() . ": $!\n";

  my $file_handle = new FileHandle::Unget($filter_command);

  return (undef,"Can't execute \"$filter_command\" for file \"$file_name\": $!")
    unless defined $file_handle;

  binmode $file_handle;

  open STDERR, '>&', $oldstderr or die "Can't restore STDERR: $!\n";

  if (eof($file_handle))
  {
    $file_handle->close();
    return (undef,"Can't execute \"$filter_command\" for file \"$file_name\"");
  }

  return ($file_handle, undef);
}

#-------------------------------------------------------------------------------

# Returns: unknown, unknown binary, mailbox, non-mailbox ascii, bzip,
# bzip2, gzip, compress
sub _GET_FILE_TYPE
{
  my $file_name_or_handle_ref = shift;

  # Open the file if we need to
  my $file_handle_ref;
  my $need_to_close_filehandle = 0;  

  if (ref $file_name_or_handle_ref eq 'SCALAR')
  {
    my $temp = new FileHandle::Unget($$file_name_or_handle_ref);
    return 'unknown' unless defined $temp;
    $file_handle_ref = \$temp;

    $need_to_close_filehandle = 1;
  }
  else
  {
    $file_handle_ref = $file_name_or_handle_ref;
  }

  
  # Read test characters
  my $test_chars = '';
  my $readResult;

  while(index($test_chars,"\n\n") == -1 && index($test_chars,"\r\n\r\n") == -1)
  {
    $readResult =
      read($$file_handle_ref,$test_chars,4000,CORE::length($test_chars));

    last unless defined $readResult && $readResult != 0;

    last if _IS_BINARY_MAILBOX(\$test_chars);

    if(CORE::length($test_chars) >
        $Mail::Mbox::MessageParser::Config{'max_testchar_buffer_size'})
    {
      if(index($test_chars,"\n\n") == -1 && index($test_chars,"\r\n\r\n") == -1)
      {
        _dprint "Couldn't find end of first paragraph after " .
          "$Mail::Mbox::MessageParser::Config{'max_testchar_buffer_size'} bytes."
      }

      last;
    }
  }


  if($need_to_close_filehandle)
  {
    $$file_handle_ref->close();
  }
  else
  {
    $$file_handle_ref->ungets($test_chars);
  }

  return 'unknown' unless defined $readResult && $readResult != 0;


  unless (_IS_BINARY_MAILBOX(\$test_chars))
  {
    return 'mailbox' if _IS_MAILBOX(\$test_chars);
    return 'non-mailbox ascii';
  }

  # See "magic" on unix systems for details on how to identify file types
  return 'bzip2' if substr($test_chars, 0, 3) eq 'BZh';
  return 'bzip' if substr($test_chars, 0, 2) eq 'BZ';
  return 'xz' if substr($test_chars, 1, 4) eq '7zXZ';
  return 'lzip' if substr($test_chars, 0, 4) eq 'LZIP';
#  return 'zip' if substr($test_chars, 0, 2) eq 'PK' &&
#    ord(substr($test_chars,3,1)) == 0003 && ord(substr($test_chars,4,1)) == 0004;
  return 'gzip' if
    ord(substr($test_chars,0,1)) == oct(37) && ord(substr($test_chars,1,1)) == oct(213);
  return 'compress' if
    ord(substr($test_chars,0,1)) == oct(37) && ord(substr($test_chars,1,1)) == oct(235);

  return 'unknown binary';
}

#-------------------------------------------------------------------------------

# Returns an endline result of either: undef, "\r\n", "\n"
# Returns an error message (or undef) as well
sub _GET_ENDLINE
{
  my $file_name_or_handle_ref = shift;

  # Open the file if we need to
  my $file_handle_ref;
  my $need_to_close_filehandle = 0;  

  if (ref $file_name_or_handle_ref eq 'SCALAR')
  {
    my $temp = new FileHandle::Unget($$file_name_or_handle_ref);
    return 'unknown' unless defined $temp;
    $file_handle_ref = \$temp;

    $need_to_close_filehandle = 1;
  }
  else
  {
    $file_handle_ref = $file_name_or_handle_ref;
  }

  
  # Read test characters
  my $test_chars = '';
  my $readResult;

  while(index($test_chars,"\n") == -1 && index($test_chars,"\r\n") == -1)
  {
    $readResult =
      read($$file_handle_ref,$test_chars,4000,CORE::length($test_chars));

    last unless defined $readResult && $readResult != 0;

    last if _IS_BINARY_MAILBOX(\$test_chars);

    if(CORE::length($test_chars) >
        $Mail::Mbox::MessageParser::Config{'max_testchar_buffer_size'})
    {
      if(index($test_chars,"\n") == -1 && index($test_chars,"\r\n") == -1)
      {
        _dprint "Couldn't find end of first line after " .
          "$Mail::Mbox::MessageParser::Config{'max_testchar_buffer_size'} bytes."
      }

      last;
    }
  }


  if($need_to_close_filehandle)
  {
    $$file_handle_ref->close();
  }
  else
  {
    $$file_handle_ref->ungets($test_chars);
  }

  return undef unless defined $readResult && $readResult != 0; ## no critic (ProhibitExplicitReturnUndef)

  return undef if _IS_BINARY_MAILBOX(\$test_chars); ## no critic (ProhibitExplicitReturnUndef)

  my $windows_count = 0;

  while ($test_chars =~ /\r\n/gs)
  {
    $windows_count++;
  }

  my $unix_count = 0;

  while ($test_chars =~ /(?<!\r)\n/gs)
  {
    $unix_count++;
  }

  _dprint "Found $unix_count UNIX line endings and $windows_count Windows line endings in a sample of length " . 
    CORE::length($test_chars);

  if($windows_count > 0 && $unix_count == 0)
  {
    return "\r\n", undef;
  }
  elsif($windows_count == 0 && $unix_count > 0)
  {
    return "\n", undef;
  }
  else
  {
    return $windows_count > $unix_count ? "\r\n" : "\n", 'Found a mix of unix and Windows line endings.' .
      ' Please normalize the line endings using a tool like "dos2unix".' .
      ' Use the force option to ignore this error and process using ' . ($windows_count > $unix_count ?
       'Windows' : 'Unix') . ' line endings (best guess).';
  }
}

#-------------------------------------------------------------------------------

sub _IS_COMPRESSED_TYPE
{
  my $file_type = shift;
  
  local $" = '|';

  my @types = qw( gzip bzip bzip2 xz lzip compress );
  my $file_type_pattern = "(@types)";

  return $file_type =~ /^$file_type_pattern$/;
}

#-------------------------------------------------------------------------------

# man perlfork for details
# simulate open(FOO, "-|")
sub _pipe_from_fork
{
  my $parent = shift;
  my $child = new FileHandle::Unget;

  pipe $parent, $child or die;

  my $pid = fork();
  return undef unless defined $pid; ## no critic (ProhibitExplicitReturnUndef)

  if ($pid)
  {
      close $child;
  }
  else
  {
      close $parent;
      open(STDOUT, ">&=" . fileno($child)) or die;
  }

  return $pid;
}

#-------------------------------------------------------------------------------

sub _DO_WINDOWS_DECOMPRESSION
{
  my $file_handle = shift;
  my $file_type = shift;

  return (undef,"Can't decompress file handle--no decompressor available")
    unless defined $Mail::Mbox::MessageParser::Config{'programs'}{$file_type};

  my $filter_command = qq{"$Mail::Mbox::MessageParser::Config{'programs'}{$file_type}" -cd};

  my ($temp_file_handle, $temp_file_name) =
    File::Temp::tempfile('mail-mbox-messageparser-XXXXXX', SUFFIX => '.tmp', TMPDIR => 1, UNLINK => 1);

  while(my $line = <$file_handle>)
  {
    print $temp_file_handle $line;
  }

  close $file_handle;
  # So that it won't be deleted until the program is complete
  # close $temp_file_handle;

  _dprint "Calling \"$filter_command\" to decompress filehandle";

  my $decompressed_file_handle =
    new FileHandle::Unget("$filter_command $temp_file_name |");

  binmode $decompressed_file_handle;

  return ($decompressed_file_handle,undef);
}

#-------------------------------------------------------------------------------

sub _DO_NONWINDOWS_DECOMPRESSION
{
  my $file_handle = shift;
  my $file_type = shift;

  return (undef,"Can't decompress file handle--no decompressor available")
    unless defined $Mail::Mbox::MessageParser::Config{'programs'}{$file_type};

  my $filter_command = qq{"$Mail::Mbox::MessageParser::Config{'programs'}{$file_type}" -cd};

  _dprint "Calling \"$filter_command\" to decompress filehandle";

  # Implicit fork
  my $decompressed_file_handle = new FileHandle::Unget;
  my $pid = _pipe_from_fork($decompressed_file_handle);

  unless (defined($pid))
  {
    $file_handle->close();
    die 'Can\'t fork to decompress file handle';
  }

  # In child. Write to the parent, giving it all the data to decompress.
  # We have to do it this way because other methods (e.g. open2) require us
  # to feed the filter as we use the filtered data. This method allows us to
  # keep the remainder of the code the same for both compressed and
  # uncompressed input.
  unless ($pid)
  {
    open(my $front_of_pipe, "|$filter_command 2>" . File::Spec->devnull())
      or return (undef,"Can't execute \"$filter_command\" on file handle: $!");

    binmode $front_of_pipe;

    print $front_of_pipe (<$file_handle>);

    $file_handle->close()
      or return (undef,"Can't execute \"$filter_command\" on file handle: $!");

    # We intentionally don't check for error here. This is because the
    # parent may have aborted, in which case we let it take care of
    # error messages. (e.g. Non-mailbox standard input.)
    close $front_of_pipe;

    exit;
  }

  binmode $decompressed_file_handle;

  # In parent
  return ($decompressed_file_handle,undef);
}

#-------------------------------------------------------------------------------

sub _DO_DECOMPRESSION
{
  my $file_handle = shift;
  my $file_type = shift;

  if ($^O eq 'MSWin32')
  {
    return _DO_WINDOWS_DECOMPRESSION($file_handle,$file_type);
  }
  else
  {
    return _DO_NONWINDOWS_DECOMPRESSION($file_handle,$file_type);
  }
}

#-------------------------------------------------------------------------------

# Simulates -B, which consumes data on a stream. We only look at the first
# 1000 characters because the body may have foreign binary-like characters
sub _IS_BINARY_MAILBOX
{
  my ($start, $data_length);

  # Unix line endings
  {
    $start = 0;

    # Handle newlines at the start
    while (index(${$_[0]}, "\n\n", $start) == $start) {
      $start += 2;
    }

    $data_length = index(${$_[0]}, "\n\n", $start) - $start;
  }

  # If we didn't succeed with Unix line endings, try DOS line endings
  if ($data_length == -1)
  {
    # Handle newlines at the start
    $start = 0;

    while (index(${$_[0]}, "\r\n\r\n", $start) == $start) {
      $start += 4;
    }

    $data_length = index(${$_[0]}, "\r\n\r\n", $start) - $start;
  }

  # Didn't find any kind of empty line. Use the whole buffer.
  $data_length = CORE::length(${$_[0]}) - $start if $data_length == -1;

  my $bin_length = substr(${$_[0]}, $start ,$data_length) =~ tr/[\t\n\x20-\x7e]//c;

  my $non_bin_length = $data_length - $bin_length;

  return (($non_bin_length / $data_length) <= .70);
}

#-------------------------------------------------------------------------------

# Detects whether an ASCII file is a mailbox, based on whether it has a line
# whose prefix is 'From' and another line whose prefix is 'Received ',
# 'Date:', 'Subject:', 'X-Status:', 'Status:', or 'To:'.

sub _IS_MAILBOX
{
  my $test_characters = shift;

  if ($$test_characters =~ /$Mail::Mbox::MessageParser::Config{'from_pattern'}/im &&
      $$test_characters =~ /^(Received[ :]|Date:|Subject:|X-Status:|Status:|To:)/sm)
  {
    return 1;
  }
  else
  {
    return 0;
  }
}

#-------------------------------------------------------------------------------

sub reset
{
  my $self = shift;

  if (_IS_A_PIPE($self->{'file_handle'}))
  {
    _dprint "Avoiding seek() on a pipe";
  }
  else
  {
    seek $self->{'file_handle'}, length($self->{'prologue'}), 0
  }

  $self->{'email_line_number'} = 0;
  $self->{'email_offset'} = 0;
  $self->{'email_length'} = 0;
  $self->{'email_number'} = 0;
}

#-------------------------------------------------------------------------------

# Ceci n'set pas une pipe
sub _IS_A_PIPE
{
  my $file_handle = shift;

  return (-t $file_handle || -S $file_handle || -p $file_handle || ## no critic (ProhibitInteractiveTest)
    !-f $file_handle || !(seek $file_handle, 0, 1));
}

#-------------------------------------------------------------------------------

sub endline
{
  my $self = shift;

  return $self->{'endline'};
}

#-------------------------------------------------------------------------------

sub prologue
{
  my $self = shift;

  return $self->{'prologue'};
}

#-------------------------------------------------------------------------------

sub _print_debug_information
{
  return unless $_DEBUG;

  my $self = shift;

  _dprint "Version: $VERSION";

  foreach my $key (keys %$self)
  {
    my $value = $self->{$key};
    if (defined $value)
    {
      $value = '<non-scalar>' unless ref \$value eq 'SCALAR';
    }
    else
    {
      $value = '<undef>';
    }

    _dprint "$key: $value";
  }
}

#-------------------------------------------------------------------------------

# Returns true if the file handle has been fully read
sub end_of_file
{
  my $self = shift;

  # Reset eof in case the file was appended to. Hopefully this works all the
  # time. See perldoc -f seek for details.
  seek($self->{'file_handle'},0,1) if eof $self->{'file_handle'};

  return eof $self->{'file_handle'};
}

#-------------------------------------------------------------------------------

# The line number of the last email read
sub line_number
{
  my $self = shift;

  return $self->{'email_line_number'};
}

#-------------------------------------------------------------------------------

sub number
{
  my $self = shift;

  return $self->{'email_number'};
}

#-------------------------------------------------------------------------------

# The length of the last email read
sub length
{
  my $self = shift;

  return $self->{'email_length'};
}

#-------------------------------------------------------------------------------

# The offset of the last email read
sub offset
{
  my $self = shift;

  return $self->{'email_offset'};
}

#-------------------------------------------------------------------------------

sub _read_prologue
{
  die "Derived class must provide an implementation";
}

#-------------------------------------------------------------------------------

sub read_next_email
{
  my $self = shift;

  if ($UPDATING_CACHE)
  {
    _dprint "Storing data into cache, length " . $self->{'email_length'};

    my $_CACHE = $Mail::Mbox::MessageParser::Cache::_CACHE;

    $_CACHE->{$self->{'file_name'}}{'emails'}[$self->{'email_number'}-1]{'length'} =
      $self->{'email_length'};

    $_CACHE->{$self->{'file_name'}}{'emails'}[$self->{'email_number'}-1]{'line_number'} =
      $self->{'email_line_number'};

    $_CACHE->{$self->{'file_name'}}{'emails'}[$self->{'email_number'}-1]{'offset'} =
      $self->{'email_offset'};
    $_CACHE->{$self->{'file_name'}}{'emails'}[$self->{'email_number'}-1]{'validated'} =
      1;

    $_CACHE->{$self->{'file_name'}}{'modified'} = 1;

    if ($self->end_of_file())
    {
      $UPDATING_CACHE = 0;

      # Last one is always validated
      $_CACHE->{$self->{'file_name'}}{'emails'}[$self->{'email_number'}-1]{'validated'} =
        1;
    }

  }
}

#-------------------------------------------------------------------------------

# - Returns header lines in the email header which match the given name.
# - Example names: 'From:', 'Received:' or 'From '
# - If the calling context wants a list, a list of the matching header lines
#   are returned. Otherwise, the first (and perhaps only) match is returned.
# - Wrapped lines are handled. Look for multiple \n's in the return value(s)
# - 'From ' also looks for Gnus 'X-From-Line:' or 'X-Draft-From:'

# Stolen from grepmail
sub _GET_HEADER_FIELD
{
  my $email_header = shift;
  my $header_name = shift;
  my $endline = shift;

  die unless ref $email_header;

  # Avoid perl 5.6 bug which causes spurious warning even though $email_header
  # is defined.
  local $^W = 0 if $] >= 5.006 && $] < 5.008;

  if ($header_name =~ /^From$/i &&
    $$email_header =~ /^((?:From\s|X-From-Line:|X-Draft-From:).*$endline(\s.*$endline)*)/im)
  {
    return wantarray ? ($1) : $1;
  }

  my @matches = $$email_header =~ /^($header_name\s.*$endline(?:\s.*$endline)*)/igm;

  if (@matches)
  {
    return wantarray ? @matches : shift @matches;
  }

  if (lc $header_name eq 'from ' &&
    $$email_header =~ /^(From\s.*$endline(\s.*$endline)*)/im)
  {
    return wantarray ? ($1) : $1;
  }

  return undef; ## no critic (ProhibitExplicitReturnUndef)
}

1;

__END__

# --------------------------------------------------------------------------

=head1 NAME

Mail::Mbox::MessageParser - A fast and simple mbox folder reader

=head1 SYNOPSIS

  #!/usr/bin/perl

  use Mail::Mbox::MessageParser;

  # Compression support
  my $file_name = 'mail/saved-mail.xz';
  my $file_handle = new FileHandle($file_name);

  # Set up cache. (Not necessary if enable_cache is false.)
  Mail::Mbox::MessageParser::SETUP_CACHE(
    { 'file_name' => '/tmp/cache' } );

  my $folder_reader =
    new Mail::Mbox::MessageParser( {
      'file_name' => $file_name,
      'file_handle' => $file_handle,
      'enable_cache' => 1,
      'enable_grep' => 1,
    } );

  die $folder_reader unless ref $folder_reader;

  # Any newlines or such before the start of the first email
  my $prologue = $folder_reader->prologue;
  print $prologue;

  # This is the main loop. It's executed once for each email
  while(!$folder_reader->end_of_file())
  {
    my $email = $folder_reader->read_next_email();
    print $$email;
  }

=head1 DESCRIPTION

This module implements a fast but simple mbox folder reader. One of three
implementations (Cache, Grep, Perl) will be used depending on the wishes of the
user and the system configuration. The first implementation is a cached-based
one which stores email information about mailboxes on the file system.
Subsequent accesses will be faster because no analysis of the mailbox will be
needed. The second implementation is one based on GNU grep, and is
significantly faster than the Perl version for mailboxes which contain very
large (10MB) emails. The final implementation is a fast Perl-based one which
should always be applicable.

The Cache implementation is about 6 times faster than the standard Perl
implementation. The Grep implementation is about 4 times faster than the
standard Perl implementation. If you have GNU grep, it's best to enable both
the Cache and Grep implementations. If the cache information is available,
you'll get very fast speeds. Otherwise, you'll take about a 1/3 performance
hit when the Grep version is used instead.

The overriding requirement for this module is speed. If you wish more
sophisticated parsing, use Mail::MboxParser (which is based on this module) or
Mail::Box.


=head2 METHODS AND FUNCTIONS

=over 4

=item SETUP_CACHE(...)

  SETUP_CACHE( { 'file_name' => <cache file name> } );

  <cache file name> - the file name of the cache

Call this function once to set up the cache before creating any parsers. You
must provide the location to the cache file. There is no default value.

=item new(...)

  new( { 'file_name' => <mailbox file name>,
    'file_handle' => <mailbox file handle>,
    'enable_cache' => <1 or 0>,
    'enable_grep' => <1 or 0>,
    'force_processing' => <1 or 0>,
    'debug' => <1 or 0>,
  } );

  <mailbox file name> - the file name of the mailbox
  <mailbox file handle> - the already opened file handle for the mailbox
  <enable_cache> - true to attempt to use the cache implementation
  <enable_grep> - true to attempt to use the grep implementation
  <force_processing> - true to force processing of files that look invalid
  <debug> - true to print some debugging information to STDERR

The constructor takes either a file name or a file handle, or both. If the
file handle is not defined, Mail::Mbox::MessageParser will attempt to open the
file using the file name. You should always pass the file name if you have it,
so that the parser can cache the mailbox information.

This module will automatically decompress the mailbox as necessary. If a
filename is available but the file handle is undef, the module will call bzip,
bzip2, gzip, lzip, xz to decompress the file in memory if the filename ends
with the appropriate suffix. If the file handle is defined, it will detect the
type of compression and apply the correct decompression program.

The Cache, Grep, or Perl implementation of the parser will be loaded,
whichever is most appropriate. For example, the first time you use caching,
there will be no cache. In this case, the grep implementation can be used
instead. The cache will be updated in memory as the grep implementation parses
the mailbox, and the cache will be written after the program exits. The file
name is optional, in which case I<enable_cache> and I<enable_grep> must both
be false.

I<force_processing> will cause the module to process folders that look to be
binary, or whose text data doesn't look like a mailbox.

Returns a reference to a Mail::Mbox::MessageParser object on success, and a
scalar desribing an error on failure. ("Not a mailbox", "Can't open <filename>: <system error>", "Can't execute <uncompress command> for file <filename>"


=item reset()

Reset the filehandle and all internal state. Note that this will not work with
filehandles which are streams. If there is enough demand, I may add the
ability to store the previously read stream data internally so that I<reset()>
will work correctly.


=item endline()

Returns "\n" or "\r\n", depending on the file format.


=item prologue()

Returns any newlines or other content at the start of the mailbox prior to the
first email.


=item end_of_file()

Returns true if the end of the file has been encountered.


=item line_number()

Returns the line number for the start of the last email read.


=item number()

Returns the number of the last email read. (i.e. The first email will have a
number of 1.)


=item length()

Returns the length of the last email read.


=item offset()

Returns the byte offset of the last email read.


=item read_next_email()

Returns a reference to a scalar holding the text of the next email in the
mailbox, or undef at the end of the file.

=back


=head1 BUGS

No known bugs.

Contact david@coppit.org for bug reports and suggestions.


=head1 AUTHOR

David Coppit <david@coppit.org>.


=head1 LICENSE

This code is distributed under the GNU General Public License (GPL) Version 2.
See the file LICENSE in the distribution for details.


=head1 HISTORY

This code was originally part of the grepmail distribution. See
http://grepmail.sf.net/ for previous versions of grepmail which included early
versions of this code.


=head1 SEE ALSO

Mail::MboxParser, Mail::Box

=cut
