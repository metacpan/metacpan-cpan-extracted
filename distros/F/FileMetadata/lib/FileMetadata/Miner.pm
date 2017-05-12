package FileMetadata::Miner;

our $VERSION = '1.0';

=head1 NAME

FileMetadata::Miner

=head1 SYNOPSIS

An interface to be implemented by Miners in the FileMetadata framework

=head1 DESCRIPTION

Miners extract metadata from sources, usually  specializing in a certain
type of resource (e.g HTML files). Meta data for resources can be extracted by
multiple miners executed in a series. One miner can extract information
regarding file statistics. Such a miner would be generic. A more specialized
miner can then be used to extract information on the author.

Miners can be used outside the FileMetadata framework with ease and should be
implemented for such general use.

=head1 METHODS

=head2 new

This constructor takes a single argument. The argument is a reference to a hash
that represents configuration information. The method returns a reference
to a new miner object. The specifics of the config hash should be available
in the documentation for the Miner.

=head2 mine

This method returns a boolean value. It is true on a success and false
on failure.

This method takes two arguments:

1. The URI to the resource for which metadata is to be compiled.

URIs are prefixed by the protocol. If no protocol is present, it can be
assumed that the URI is an absolute path to a file.

It is possible that the Miner refers to another resource to obtain
data on the given URI or for that matter to no resource at all.

2. A reference to a hash that contains meta data known for the resource.

Any meta data found should be inserted into the hash. The keys in the hash
should be prefixed by the name space of the module. For example the
FileMetadata::Miner::Stat would insert keys 'FileMetadata::Miner::Stat::atime'
with the corresponding value. All values in the hash should be strings.

A miner should not alter or insert metadata not in its namespace.

=head1 VERSION

1.0 - This is the first release of this interface

=head1 AUTHOR

Midh Mulpuri midh@enjine.com

=head1 LICENSE

This software can be used under the terms of any Open Source Initiative
approved license. A list of these licenses are available at the OSI site -
http://www.opensource.org/licenses/

=cut
