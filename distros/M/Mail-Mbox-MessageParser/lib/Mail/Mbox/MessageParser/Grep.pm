package Mail::Mbox::MessageParser::Grep;

no strict;

@ISA = qw( Exporter Mail::Mbox::MessageParser );

use strict;
use Carp;

use Mail::Mbox::MessageParser;
use Mail::Mbox::MessageParser::Config;

use vars qw( $VERSION $DEBUG );
use vars qw( $CACHE );

$VERSION = sprintf "%d.%02d%02d", q/1.70.5/ =~ /(\d+)/g;

*ENTRY_STILL_VALID = \&Mail::Mbox::MessageParser::MetaInfo::ENTRY_STILL_VALID;
sub ENTRY_STILL_VALID;

*CACHE = \$Mail::Mbox::MessageParser::MetaInfo::CACHE;

*DEBUG = \$Mail::Mbox::MessageParser::DEBUG;
*dprint = \&Mail::Mbox::MessageParser::dprint;
sub dprint;

#-------------------------------------------------------------------------------

sub new
{
  my ($proto, $self) = @_;

  carp "Need file_name option" unless defined $self->{'file_name'};
  carp "Need file_handle option" unless defined $self->{'file_handle'};

  return "Mail::Mbox::MessageParser::Grep not configured to use GNU grep. Perhaps it is not installed"
    unless defined $Mail::Mbox::MessageParser::Config{'programs'}{'grep'};

  bless ($self, __PACKAGE__);

  $self->_init();

  return $self;
}

#-------------------------------------------------------------------------------

sub _init
{
  my $self = shift;

  # Reading grep data provides us with an array of potential email starting
  # locations. However, due to included emails and attachments, we have to
  # validate these locations as actually being the start of emails. As a
  # result, there may be more "chunks" in the array than emails. So
  # CHUNK_INDEX >= email_number-1.
  $self->{'CHUNK_INDEX'} = -1;

  $self->{'READ_BUFFER'} = '';
  $self->{'START_OF_EMAIL'} = 0;
  $self->{'END_OF_EMAIL'} = 0;

  $self->SUPER::_init();

  $self->_initialize_cache_entry();
}

#-------------------------------------------------------------------------------

sub reset
{
  my $self = shift;

  $self->{'CHUNK_INDEX'} = 0;

  $self->{'READ_BUFFER'} = '';
  $self->{'START_OF_EMAIL'} = 0;
  $self->{'END_OF_EMAIL'} = 0;

  $self->SUPER::reset();
}

#-------------------------------------------------------------------------------

sub end_of_file
{
  my $self = shift;

  # Reset eof in case the file was appended to. Hopefully this works all the
  # time. See perldoc -f seek for details.
  seek($self->{'file_handle'},0,1) if eof $self->{'file_handle'};

  return eof $self->{'file_handle'} &&
    $self->{'END_OF_EMAIL'} == length($self->{'READ_BUFFER'});
}

#-------------------------------------------------------------------------------

sub _read_prologue
{
  my $self = shift;

  dprint "Reading mailbox prologue using grep";

  $self->_read_until_match(
    qr/$Mail::Mbox::MessageParser::Config{'from_pattern'}/m,0);

  my $start_of_email = pos($self->{'READ_BUFFER'});
  $self->{'prologue'} = substr($self->{'READ_BUFFER'}, 0, $start_of_email);

  # Set up for read_next_email
  $self->{'END_OF_EMAIL'} = $start_of_email;
}

#-------------------------------------------------------------------------------

sub read_next_email
{
  my $self = shift;

  unless (defined $self->{'file_name'} &&
    ENTRY_STILL_VALID($self->{'file_name'}))
  {
    # Patch up the data structures for the Perl implementation
    undef $self->{'CHUNK_INDEX'};
    $self->{'CURRENT_LINE_NUMBER'} =
      $CACHE->{$self->{'file_name'}}{'emails'}[$self->{'email_number'}]{'line_number'};
    $self->{'CURRENT_OFFSET'} =
      $CACHE->{$self->{'file_name'}}{'emails'}[$self->{'email_number'}]{'offset'};
    $self->{'READ_CHUNK_SIZE'} =
      $Mail::Mbox::MessageParser::Config{'read_chunk_size'};

    # Invalidate the remaining data
    $#{ $CACHE->{$self->{'file_name'}}{'emails'} } = $self->{'email_number'};

    bless ($self, 'Mail::Mbox::MessageParser::Perl');

    return $self->read_next_email();
  }

  return undef if $self->end_of_file();

  $self->{'email_line_number'} =
    $CACHE->{$self->{'file_name'}}{'emails'}[$self->{'email_number'}]{'line_number'};
  $self->{'email_offset'} =
    $CACHE->{$self->{'file_name'}}{'emails'}[$self->{'email_number'}]{'offset'};

  $self->{'START_OF_EMAIL'} = $self->{'END_OF_EMAIL'};

  # Slurp in an entire multipart email (but continue looking for the next
  # header so that we can get any following newlines as well)
  unless ($self->_read_header())
  {
    return $self->_extract_email_and_finalize();
  }

  unless ($self->_read_email_parts())
  {
    # Could issue a warning here, but I'm not sure how to do this cleanly for
    # a work-only module like this. Maybe something like CGI's cgi_error()?
    dprint "Inconsistent multi-part message. Could not find ending for " .
      "boundary \"" . $self->_multipart_boundary() . "\"";

    # Try to read the content length and use that
    my $email_header = substr($self->{'READ_BUFFER'}, $self->{'START_OF_EMAIL'},
      $self->{'START_OF_BODY'} - $self->{'START_OF_EMAIL'});

    my $content_length = Mail::Mbox::MessageParser::_GET_HEADER_FIELD(
      \$email_header, 'Content-Length:', $self->{'endline'});

    if (defined $content_length)
    {
      $content_length =~ s/Content-Length: *(\d+).*/$1/i;
      pos($self->{'READ_BUFFER'}) = $self->{'START_OF_EMAIL'} + $content_length;
    }
    # Otherwise use the start of the body 
    else
    {
      pos($self->{'READ_BUFFER'}) = $self->{'START_OF_BODY'};
    }

    # Reset the search and look for the start of the next email.
    $self->_read_rest_of_email();

    return $self->_extract_email_and_finalize();
  }

  $self->_read_rest_of_email();

  return $self->_extract_email_and_finalize();
}

#-------------------------------------------------------------------------------

sub _read_rest_of_email
{
  my $self = shift;

  # Look for the start of the next email
  while (1)
  {
    while ($self->{'READ_BUFFER'} =~
      m/$Mail::Mbox::MessageParser::Config{'from_pattern'}/mg)
    {
      $self->{'END_OF_EMAIL'} = pos($self->{'READ_BUFFER'}) - length($1);

      my $endline = $self->{'endline'};

      # Keep looking if the header we found is part of a "Begin Included
      # Message".
      my $end_of_string = '';
      my $backup_amount = 100;
      do
      {
        $backup_amount *= 2;
        $end_of_string = substr($self->{'READ_BUFFER'},
          $self->{'END_OF_EMAIL'}-$backup_amount, $backup_amount);
      } while (index($end_of_string, "$endline$endline") == -1 &&
        $backup_amount < $self->{'END_OF_EMAIL'});

      next if $end_of_string =~
          /$endline-----(?: Begin Included Message |Original Message)-----$endline[^\r\n]*(?:$endline)*$/i;

      next unless $end_of_string =~ /$endline$endline$/;

      # Found the next email!
      return;
    }

    # Didn't find next email in current buffer. Most likely we need to read some
    # more of the mailbox. Shift the current email to the front of the buffer
    # unless we've already done so.
    my $shift_amount = $self->{'START_OF_EMAIL'};
    $self->{'READ_BUFFER'} =
      substr($self->{'READ_BUFFER'}, $self->{'START_OF_EMAIL'});
    $self->{'START_OF_EMAIL'} -= $shift_amount;
    $self->{'START_OF_BODY'} -= $shift_amount;
    pos($self->{'READ_BUFFER'}) = length($self->{'READ_BUFFER'});

    # Start looking at the end of the buffer, but back up some in case the
    # edge of the newly read buffer contains the start of a new header. I
    # believe the RFC says header lines can be at most 90 characters long.
    unless ($self->_read_until_match(
      qr/$Mail::Mbox::MessageParser::Config{'from_pattern'}/m,90))
    {
      $self->{'END_OF_EMAIL'} = length($self->{'READ_BUFFER'});
      return;
    }

    redo;
  }
}

#-------------------------------------------------------------------------------

sub _multipart_boundary
{
  my $self = shift;

  my $endline = $self->{'endline'};

  if (substr($self->{'READ_BUFFER'},$self->{'START_OF_EMAIL'},
    $self->{'START_OF_BODY'}-$self->{'START_OF_EMAIL'}) =~
    /^(content-type: *multipart[^\n\r]*$endline( [^\n\r]*$endline)*)/im)
  {
    my $content_type_header = $1;
    $content_type_header =~ s/$endline//g;

    if ($content_type_header =~ /boundary *= *"([^"]*)"/i ||
        $content_type_header =~ /boundary *= *([-0-9A-Za-z'()+_,.\/:=? ]*[-0-9A-Za-z'()+_,.\/:=?])/i)
    {
      return $1
    }
  }

  return undef;
}

#-------------------------------------------------------------------------------

sub _read_email_parts
{
  my $self = shift;

  my $boundary = $self->_multipart_boundary();

  return 1 unless defined $boundary;

  # RFC 1521 says the boundary can be no longer than 70 characters. Back up a
  # little more than that.
  my $endline = $self->{'endline'};
  $self->_read_until_match(qr/^--\Q$boundary\E--$endline/m,76)
    or return 0;

  return 1;
}

#-------------------------------------------------------------------------------

sub _extract_email_and_finalize
{
  my $self = shift;

  $self->{'email_length'} = $self->{'END_OF_EMAIL'}-$self->{'START_OF_EMAIL'};

  my $email = substr($self->{'READ_BUFFER'}, $self->{'START_OF_EMAIL'},
    $self->{'email_length'});

  while ($self->{'email_length'} >
    $CACHE->{$self->{'file_name'}}{'emails'}[$self->{'email_number'}]{'length'})
  {
    $self->_adjust_cache_data();
  }

  $self->{'email_number'}++;

  $self->SUPER::read_next_email();

  return \$email;
}

#-------------------------------------------------------------------------------

sub _read_header
{
  my $self = shift;

  $self->_read_until_match(qr/$self->{'endline'}$self->{'endline'}/m,0)
    or return 0;

  $self->{'START_OF_BODY'} =
    pos($self->{'READ_BUFFER'}) + length("$self->{'endline'}$self->{'endline'}");

  return 1;
}

#-------------------------------------------------------------------------------

# The search position is at the start of the pattern when this function
# returns 1.
sub _read_until_match
{
  my $self = shift;
  my $pattern = shift;
  my $backup = shift;

  # Start looking at the end of the buffer, but back up some in case the edge
  # of the newly read buffer contains part of the pattern.
  if (!defined pos($self->{'READ_BUFFER'}) ||
      pos($self->{'READ_BUFFER'}) - $backup <= 0) {
    pos($self->{'READ_BUFFER'}) = 0;
  } else {
    pos($self->{'READ_BUFFER'}) -= $backup;
  }

  while (1)
  {
    if ($self->{'READ_BUFFER'} =~ m/($pattern)/mg)
    {
      pos($self->{'READ_BUFFER'}) -= length($1);
      return 1;
    }

    pos($self->{'READ_BUFFER'}) = length($self->{'READ_BUFFER'});

    unless ($self->_read_chunk()) {
      $self->{'END_OF_EMAIL'} = length($self->{'READ_BUFFER'});
      return 0;
    }

    if (pos($self->{'READ_BUFFER'}) - $backup <= 0) {
      pos($self->{'READ_BUFFER'}) = 0;
    } else {
      pos($self->{'READ_BUFFER'}) -= $backup;
    }
  }
}

#-------------------------------------------------------------------------------

# Maintains pos($self->{'READ_BUFFER'})
sub _read_chunk
{
  my $self = shift;

  my $search_position = pos($self->{'READ_BUFFER'});

  # Reading the prologue, so use the offset of the first email
  if ($self->{'CHUNK_INDEX'} == -1)
  {
    my $length_to_read = $CACHE->{$self->{'file_name'}}{'emails'}[0]{'offset'};
    my $total_amount_read = 0;

    do {
      $total_amount_read += read($self->{'file_handle'}, $self->{'READ_BUFFER'},
        $length_to_read-$total_amount_read, length($self->{'READ_BUFFER'}));
    } while ($total_amount_read != $length_to_read);

    pos($self->{'READ_BUFFER'}) = $search_position;

    $self->{'CHUNK_INDEX'}++;
  }

  my $last_email_index = $#{$CACHE->{$self->{'file_name'}}{'emails'}};

  return 0 if $self->{'CHUNK_INDEX'} == $last_email_index+1;

  my $length_to_read =
    $CACHE->{$self->{'file_name'}}{'emails'}[$self->{'CHUNK_INDEX'}]{'length'};
  my $total_amount_read = 0;

  do {
    $total_amount_read += read($self->{'file_handle'}, $self->{'READ_BUFFER'},
      $length_to_read-$total_amount_read, length($self->{'READ_BUFFER'}));
  } while ($total_amount_read != $length_to_read);

  pos($self->{'READ_BUFFER'}) = $search_position;

  $self->{'CHUNK_INDEX'}++;

  return 1;
}

#-------------------------------------------------------------------------------

sub _adjust_cache_data
{
  my $self = shift;

  my $last_email_index = $#{$CACHE->{$self->{'file_name'}}{'emails'}};

  die<<EOF
Error: Cannot adjust cache data. Please email the author with your mailbox to
have him fix the problem. In the meantime, disable the grep implementation.
EOF
    if $self->{'email_number'} == $last_email_index;

  $CACHE->{$self->{'file_name'}}{'emails'}[$self->{'email_number'}]{'length'} +=
    $CACHE->{$self->{'file_name'}}{'emails'}[$self->{'email_number'}+1]{'length'};

  if($self->{'email_number'}+2 <= $last_email_index)
  {
    @{$CACHE->{$self->{'file_name'}}{'emails'}}
      [$self->{'email_number'}+1..$last_email_index-1] =
        @{$CACHE->{$self->{'file_name'}}{'emails'}}
        [$self->{'email_number'}+2..$last_email_index];
  }

  pop @{$CACHE->{$self->{'file_name'}}{'emails'}};

  $self->{'CHUNK_INDEX'}--;
}

#-------------------------------------------------------------------------------

sub _initialize_cache_entry
{
  my $self = shift;
    
  my @stat = stat $self->{'file_name'};
      
  my $size = $stat[7];
  my $time_stamp = $stat[9];

  $CACHE->{$self->{'file_name'}}{'size'} = $size;
  $CACHE->{$self->{'file_name'}}{'time_stamp'} = $time_stamp;
  $CACHE->{$self->{'file_name'}}{'emails'} =
    _READ_GREP_DATA($self->{'file_name'});
}

#-------------------------------------------------------------------------------

sub _READ_GREP_DATA
{
  my $filename = shift;

  my @lines_and_offsets;

  dprint "Reading grep data";

  {
    my @grep_results;

    @grep_results = `unset LC_ALL LC_COLLATE LANG LC_CTYPE LC_MESSAGES; $Mail::Mbox::MessageParser::Config{'programs'}{'grep'} --extended-regexp --line-number --byte-offset --binary-files=text "^From [^:]+(:[0-9][0-9]){1,2}(  *([A-Z]{2,6}|[+-]?[0-9]{4})){1,3}( remote from .*)?\r?\$" "$filename"`;

    dprint "Read " . scalar(@grep_results) . " lines of grep data";

    foreach my $match_result (@grep_results)
    {
      my ($line_number, $byte_offset) = $match_result =~ /^(\d+):(\d+):/;
      push @lines_and_offsets,
        {'line number' => $line_number,'byte offset' => $byte_offset};
    }
  }

  my @emails;

  for(my $match_number = 0; $match_number <= $#lines_and_offsets; $match_number++)
  {
    if ($match_number == $#lines_and_offsets)
    {
      my $filesize = -s $filename;
      $emails[$match_number]{'length'} =
        $filesize - $lines_and_offsets[$match_number]{'byte offset'};
    }
    else
    {
      $emails[$match_number]{'length'} =
        $lines_and_offsets[$match_number+1]{'byte offset'} -
        $lines_and_offsets[$match_number]{'byte offset'};
    }

    $emails[$match_number]{'line_number'} =
      $lines_and_offsets[$match_number]{'line number'};

    $emails[$match_number]{'offset'} =
      $lines_and_offsets[$match_number]{'byte offset'};

    $emails[$match_number]{'validated'} = 0;
  }

  return \@emails;
}

1;

__END__

# --------------------------------------------------------------------------

=head1 NAME

Mail::Mbox::MessageParser::Grep - A GNU grep-based mbox folder reader

=head1 SYNOPSIS

  #!/usr/bin/perl

  use Mail::Mbox::MessageParser;

  my $filename = 'mail/saved-mail';
  my $filehandle = new FileHandle($filename);

  my $folder_reader =
    new Mail::Mbox::MessageParser( {
      'file_name' => $filename,
      'file_handle' => $filehandle,
      'enable_grep' => 1,
    } );

  die $folder_reader unless ref $folder_reader;

  # Any newlines or such before the start of the first email
  my $prologue = $folder_reader->prologue;
  print $prologue;

  # This is the main loop. It's executed once for each email
  while(!$folder_reader->end_of_file());
  {
    my $email = $folder_reader->read_next_email();
    print $email;
  }

=head1 DESCRIPTION

This module implements a GNU grep-based mbox folder reader. It can only be
used when GNU grep is installed on the system. Users must not instantiate this
class directly--use Mail::Mbox::MessageParser instead. The base MessageParser
module will automatically manage the use of grep and non-grep implementations.

=head2 METHODS AND FUNCTIONS

The following methods and functions are specific to the
Mail::Mbox::MessageParser::Grep package. For additional inherited ones, see
the Mail::Mbox::MessageParser documentation.

=over 4

=item $ref = new( { 'file_name' => <mailbox file name>,
                    'file_handle' => <mailbox file handle> });

    <file_name> - The full filename of the mailbox
    <file_handle> - An opened file handle for the mailbox

The constructor for the class takes two parameters. The I<file_name> parameter
is the filename of the mailbox. The I<file_handle> argument is the opened file
handle to the mailbox. 

Returns a reference to a Mail::Mbox::MessageParser object, or a string
describing the error.

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

Mail::Mbox::MessageParser

=cut
