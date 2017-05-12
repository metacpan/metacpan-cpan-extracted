package FileMetadata::Store::XML;

our $VERSION = '0.1';

use XML::Simple;

=head1 NAME

FileMetadata::Store::XML

=cut

use strict;

=head1 DESCRIPTION

This modules implements a store for the FileMetadata framework using a
XML file for storage. This module does not implement any methods for
accessing the information from the store.

It is important to note that information is written to the XML file
only when the finish() method is called.

=head1 METHODS

=head2 new

See L<FileMetadata::Store>

The new method creates and returns a reference to a new object.

The format for the config hash is as follows

  {
    
    file => '/tmp/f00jkdw.xml',

    root_element => 'meta-info',

    item_element => 'item',

    store => [{name => 'id',

               property => 'ID',

               type => 'attribute'},

              {name => 'timestamp',

               property => 'TIMESTAMP',

               type => 'element'},

              {name => 'author',

               property => 'FileMetadata::Miner::HTML::author',

               default => 'Jules Verne'}

             ]

  }

'file' is the path to which the information must be written. If the file
already exists, it is assumed to have been written with the same configuration.
The contents of the file are not checked for consistency with the given
configuration.

'root_element' refers to the root element of the XML file. 'item_element' is
used as to enclose meta information for each item. These items are optional
and both would default to 'meta-info'. 'name' refers to the element or 
attribute name with which the corresponding 'property' will be stored. 'type'
identifies whether the item should be written as a element or an attribute.
It is possible to generate illegal XML by using a invalid value for 'name'.
The 'default' value is used if the 'property' is not found in the meta hash as
a key. 'type' and 'default' are optional. If 'type' is not specified, it
defaults to 'element'. If 'default' is not specified, the property is ignored
if not found.

The 'store' array is optional. If it is not present, each key in the
meta hash is used as an element name with the '::' replaced by '_'. If the
'store' array is provided, it must contain information for the 'ID' and
'TIMESTAMP' properties.

The resulting XML output from this store would look as below.

  <meta-info>

    <item id="/abcd.def">

      <timestamp>1020200222</timestamp>

      <author>Scott Lee</author>

    </item>

    <item id="/wxyz.def">

      <timestamp>1320290459</timestamp>

      <author>Timothy Walker</author>

    </item>

  </meta-info>

=cut

sub new {

  my $self = {};
  bless $self, shift;
  my $config = shift;
  die "Config hash was not supplied" unless defined $config;

  # Read the basic config information
  $self->{'root_element'} = $config->{'root_element'} or 'meta-info';
  $self->{'item_element'} = $config->{'item_element'} or 'meta-info';
  $self->{'file'} = $config->{'file'} or die 'config/file is needed';

  # Figure out element names

  if (defined $config->{'store'}) {

    foreach (@{$config->{'store'}}) {
      die "config/store/name is needed" unless defined $_->{'name'};
      die "config/store/property is needed" unless defined $_->{'property'};

      if ($_->{'property'} eq 'ID') {
	$self->{'id_element'} = $_->{'name'};
      } elsif ($_->{'property'} eq "TIMESTAMP") {
	$self->{'timestamp_element'} = $_->{'name'};
      }

    }

    die "config/store/property='ID' needs to be defined"
      unless defined $self->{'id_element'};

    die "config/store/property='TIMESTAMP' needs to be defined"
      unless defined $self->{'timestamp_element'};

    $self->{'store'} = $config->{'store'};

  } else {
    $self->{'id_element'} = 'ID';
    $self->{'timestamp_element'} = 'TIMESTAMP';
  }

  # Construct the XML hash from a pre-existing file

  $self->{'data'} = {}; # This hash acts as internal storage for data
  if (-f $self->{'file'}) {

    my $temp = XMLin ($config->{'file'},
		     keyattr => {});
    if (ref ($temp->{$self->{'item_element'}}) eq 'ARRAY') {
      foreach (@{$temp->{$self->{'item_element'}}}) {
	my $id = $_->{$self->{'id_element'}};
	$self->{'data'}->{$id} = $_;
      }
    } else {
      # Assume it is a hash
      my $id = $temp->{$self->{'item_element'}}->{$self->{'id_element'}};
      $self->{'data'}->{$id} = $temp->{$self->{'item_element'}};
    }
  }

  return $self;
}

=head2 store

See L<FileMetadata::Store/"store">

The store inserts required information from the meta hash into an internal
hash.

=cut

sub store {

  my ($self, $meta) = @_;

  if (defined $self->{'store'}) {

    my $meta_store = {};

    foreach (@{$self->{'store'}}) {

      # See if the item is in the hash
      my $value;

      if (defined $meta->{$_->{'property'}}) {
	$value = $meta->{$_->{'property'}};
      } else {
	$value = $_->{'default'};
      }

      if (defined $value) {
	$meta_store->{$_->{'name'}} = $value;
      }
    }

    my $id = $meta_store->{$self->{'id_element'}};
    $self->{'data'}->{$id} = $meta_store;

  } else {

    my $meta_store = {};

    foreach (keys (%{$meta})) {
      s/::/\-/g;
      $meta_store->{$_} = $meta->{$_};
    }

    my $id = $meta_store->{$self->{'id_element'}};
    $self->{'data'}->{$id} = $meta_store;
  }
}

=head2 remove

See L<FileMetadata::Store/"remove">

=cut

sub remove {

  my ($self, $id) = @_;
  delete $self->{'data'}->{$id};

}

=head2 clear

See L<FileMetadata::Store/"clear">

=cut

sub clear {

  my $self = shift;
  $self->{'data'} = {};

}

=head2 has

See L<FileMetadata::Store/"has">

=cut

sub has {

  my ($self, $id) = @_;

  if (defined $self->{'data'}->{$id}) {
    my $temp = $self->{'timestamp_element'};
    return $self->{'data'}->{$id}->{$temp};
  } else {
    return undef;
  }

}

=head2 list

See L<FileMetadata::Store/"has">

=cut

sub list {

  my $self = shift;
  my @list = keys %{$self->{data}};
  return \@list;

}

=head2 finish

This method writes meta data held internally to the output file all at once.

=cut

sub finish {

  my $self = shift;

  my $temp = {};
  my @temp_arr = values %{$self->{'data'}};
  $temp->{$self->{'item_element'}} = \@temp_arr;

  XMLout ($temp,
	  rootname => $self->{'root_element'},
	  outputfile => $self->{'file'},
	  noattr => 1);

}

1;

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
