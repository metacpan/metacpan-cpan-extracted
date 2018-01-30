###############################################################################
# Purpose : Load resources from the filesystem
# Author  : John Alden
# Created : Aug 2006
###############################################################################

package Email::MIME::CreateHTML::Resolver::Filesystem;

use strict;
use URI::file;
use File::Slurp::WithinPolicy 'read_file';
use MIME::Types;
use File::Spec;

our $VERSION = '1.042';

sub new {
	my ($class, $options) = @_;
	$options ||= {};
	my $self = {%$options};
	return bless($self, $class);
}

#Simple/secure resource loader from local filesystem
sub get_resource {
	my ($self, $uri) = @_;
	my $base = $self->{base};
	
	#Handle file:// URIs if necessary
	my ($path, $base_dir) = map {defined && m|^file://|? URI::file->new($_)->file() : $_} ($uri, $base);	
	
	#Allow for base dir
	my $fullpath = defined($base_dir) ? File::Spec->catfile($base_dir,$path) : $path;

	#Read in the file 
	my $content = read_file($fullpath);
	my ($volume,$directories,$filename) = File::Spec->splitpath( $path );
	
	#Deduce MIME type/transfer encoding (currently using extension)
	#We may want to improve the sophistication of this (e.g. making use of $content)
	my ($mimetype,$encoding) = MIME::Types::by_suffix($filename);

	return ($content,$filename,$mimetype,$encoding);
}

1;

=head1 NAME

Email::MIME::CreateHTML::Resolver::Filesystem - finds resources via the filesystem

=head1 SYNOPSIS

	my $o = new Email::MIME::CreateHTML::Resolver::Filesystem(\%args)
	my ($content,$filename,$mimetype,$xfer_encoding) = $o->get_resource($uri)

=head1 DESCRIPTION

This is used by Email::MIME::CreateHTML to load resources.

=head1 METHODS

=over 4

=item $o = new Email::MIME::CreateHTML::Resolver::Filesystem(\%args)

%args can contain:

=over 4

=item base

Base directory used to resolve relative filepaths passed to get_resource.

=back

=item ($content,$filename,$mimetype,$xfer_encoding) = $o->get_resource($uri)

=back

=head1 TODO

 - Currently the MIME type is deduced from the file extension via MIME::Types; given we have the content available, more sophisticated strategies are probably possible

=head1 AUTHOR

Tony Hennessy, Simon Flack and John Alden with additional contributions by
Ricardo Signes <rjbs@cpan.org> and Henry Van Styn <vanstyn@cpan.org>

=head1 COPYRIGHT

(c) BBC 2005,2006. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt

=cut