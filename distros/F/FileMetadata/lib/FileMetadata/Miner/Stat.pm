package FileMetadata::Miner::Stat;

use strict;
use utf8;
use POSIX qw(strftime);
use Fcntl ':mode';

our $VERSION = '1.0';

sub new {

  my $self = {};
  bless $self, shift;
  my $config = shift;

  # Set the size units

  $self->{'size_format'} = '';
  if (defined $config->{'size'}) {
    die "Invalid 'size' format" unless $config->{'size'} =~ /^(MB|KB|bytes)$/;
      $self->{'size_format'} = $config->{'size'};
  }

  # Set the format for date

  if (defined $config->{'date'}) {
    $self->{'time_format'} = $config->{'date'};
  } else {
    $self->{'time_format'} = '%T-%D';
  }
  return $self;
}

sub mine {

  my ($self, $path, $meta) = @_;
  my $result = stat ($path);
  my $name = ref ($self); # For efficiency

  return $result unless $result; # Return on error

  # Generate size in the right format
  my $size = (stat (_))[7];

  if ($self->{'size_format'} eq 'MB') {
    $meta->{"$name"."::size"} = $size/ (1024*1024) . " MB";
  } elsif ($self->{'size_format'} eq 'KB') {
    $meta->{"$name"."::size"} = $size/ (1024) . " KB";
  } elsif ($self->{'size_format'} eq 'bytes') {
    $meta->{"$name"."::size"} = "$size bytes";
  } else {
    $meta->{"$name"."::size"} = $size;
  }

  # Generate times in the right format

  my $time_str = strftime ($self->{'time_format'},
			   localtime ((stat (_))[9]));
  $meta->{"$name"."::mtime"} = $time_str;
  $time_str = strftime ($self->{'time_format'},
			localtime ((stat (_))[10]));
  $meta->{"$name"."::ctime"} = $time_str;

  # Figure out the type of file

  if (S_ISREG ((stat (_))[2])) {
    $meta->{"$name\:\:type"} = 'REG'
  } elsif (S_ISDIR ((stat (_))[2])) {
    $meta->{"$name\:\:type"} = 'DIR'
  } else {
    $meta->{"$name\:\:type"} = 'OTHER'
  }

  return $result;
}

1;
__END__

=head1 NAME

FileMetadata::Miner::Stat

=head1 SYNOPSIS

  use FileMetadata::Miner::Stat;

  my $config = {time => '%T',
  
                size => 'KB'};

  my $miner = FileMetadata::Miner::Stat->new ($config);

  my $meta = {};

  print "Size : $meta->{'FileMetadata::Miner::Stat::size'}"

  if $miner->mine ('path', $meta);

=head1 DESCRIPTION

This module extracts three statistics for a file.

1. The creation time

2. The last modified time

3. Size

4. The type of the file

This module implements methods required for FileMetadata framework miners
but can be used independently.

=head1 METHODS

=head2 new

See L<FileMetadata::Miner/"new">

The config hash can contain two keys
'time' - Time format string acceptable to strftime. The default is '%T=%D'.
Output is shown in L<"mine">. For a list of possible values see the
L<strftime>.

'size' - One of 'KB', 'MB' or 'bytes'. The default is for the value to
be in bytes and for no units to be specified in the value of the 
FileMetadata::Miner::Stat::size property. If this option is set, then the size
is represented as 'VALUE UNITS'.

The following can be passed to the new function:

  {

    time => '%T',

    size => 'bytes'

  }

=head2 mine

See L<FileMetadata::Miner/"mine">

This method uses the stat() function on the given file path. The following 
keys are set in the meta hash.

FileMetadata::Miner::Stat::ctime - Creation time of file

FileMetadata::Miner::Stat::mtime - Last modification time of file

FileMetadata::Miner::Stat::size - Size of file

FileMetadata::Miner::Stat::type - The type of the file.
Either 'REG', 'DIR' or 'OTHER'. (Added in version 1.1)

time and size are formatted according to config options given to the
new() method or by default as:

time '23:59:45-01/31/2002'

size '10 KB' '10240 bytes' '10240'

=head1 VERSION

1.1 - This is a small update to the first release

=head1 REQUIRES

POSIX

=head1 AUTHOR

Midh Mulpuri midh@enjine.com

=head1 LICENSE

This software can be used under the terms of any Open Source Initiative
approved license. A list of these licenses are available at the OSI site -
http://www.opensource.org/licenses/

=cut
