package FileMetadata::Miner::Ext;

our $VERSION = '0.1';

use strict;
use XML::Simple;

sub new {

  my $self = {};
  bless $self, shift;

  my $config = shift;

  # Obtain the file suffix to look for from the config

  if (exists $config->{'suffix'}) {
    $self->{'ext'} = $config->{'suffix'};
  } else {
    $self->{'ext'} = '.ext';
  }

  return $self;

}

sub mine {

  my ($self, $path, $meta) = @_;

  # Get the file path for the XML file to examine

  $path = $path . $self->{'ext'};

  if (-f $path && -r $path) {

    my $ext = XMLin ($path);

    while (my ($key, $value) = each (%{$ext})) {

      $meta->{ref ($self) . "::$key"} = $value;

    }
  }

  # If file cannot be opened, we still return true

  return 1;
}

1;

__END__

=head1 NAME

FileMetadata::Miner::Ext

=head1 SYNOPSIS

  my $miner = FileMetadata::Miner::Ext->new ({});

  my $meta = {};

  $miner->mine ('path', $meta);

  foreach (keys %{$meta}) {

    print "$_ = $meta->{$_}", "\n";

  }

=head1 DESCRIPTION

This module allows meta data for a file to be described using another
file written in a specific XML format. The file with the meta data should
only differ from the file it describes by a suffix.

The XML is as described below.

  <meta-data>

    <Title>My document</Title>

    <description>Here is a description</description>

  </meta-data>

The root element can contain any number of elements which form
the basis for keys in the meta hash. The text that these elements 
enclose foms the value. The above document would result in the following keys
to be inserted into the meta hash.

FileMetadata::Miner::Ext::Title => 'My document'

FileMetadata::Miner::Ext::description => 'Here is a description'

=head1 METHODS

=head2 new

See L<FileMetadata::Miner/"new">

The new method accpets a single key 'config' in the config hash. This
suffix is appended to any given file path. The resulting file is 
expected to be in the XML format described above. The default suffix is '.ext'.
The config hash can be constructed as follows:

  {

    suffix => '.ext'

  }

=head2 mine

See L<FileMetadata::Miner/"mine">

The mine method inserts keys into the meta hash as described in the
L<"desc">. This method always returns a true value. Failures to open the
suffixed file are not considered as a failure to miner data. It is considered 
that this data is not available.

=head1 VERSION

0.1 - This is the first release

=head1 REQUIRES

XML::Simple

=head1 AUTHOR

Midh Mulpuri midh@enjine.com

=head1 LICENSE

This software can be used under the terms of any Open Source Initiative
approved license. A list of these licenses are available at the OSI site -
http://www.opensource.org/licenses/

=cut
