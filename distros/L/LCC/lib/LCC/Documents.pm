package LCC::Documents;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@LCC::Documents::ISA = qw(LCC);
$LCC::Documents::VERSION = '0.03';

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 reference to subroutine

sub browse_url { shift->_variable( 'browse_url',@_ ) } #browse_url

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 reference to subroutine

sub conceptual_url { shift->_variable( 'conceptual_url',@_ ) } #conceptual_url

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 reference to subroutine

sub fetch_url { shift->_variable( 'fetch_url',@_ ) } #fetch_url

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 servername to be used (default: `hostname`)
#      3 extension to be used (default: 'html')

sub server {

# Obtain the object
# Set default browse_url subroutine
# Set default conceptual_url subroutine
# Set default fetch_url subroutine

  my $self = shift;
  $self->browse_url( $self->_browse_url );
  $self->conceptual_url( $self->_conceptual_url );
  $self->fetch_url( $self->_fetch_url( @_ ) );
} #server

#------------------------------------------------------------------------

# The following subroutines are for internal use only

#------------------------------------------------------------------------

#  IN: 1 instantiated object
# OUT: 1 code reference for default browse URL handler

sub _browse_url { sub {undef} } #_browse_url

#------------------------------------------------------------------------

#  IN: 1 instantiated object
# OUT: 1 code reference for default conceptual URL handler

sub _conceptual_url { sub {$_[0]} } #_conceptual_url

#------------------------------------------------------------------------

#  IN: 1 instantiated object
#      2 servername to be used (default: `hostname`)
#      3 extension to be used (default: 'html')
# OUT: 1 code reference for default fetch URL handler

sub _fetch_url {

# Obtain the object
# Obtain the hostname, make sure it's clean
# Obtain the extension
# Return the code reference

  my $self = shift;
  chomp( my $server = shift || `hostname` );
  my $extension = shift || 'html';
  return sub {"http://$server/$_[0].$extension"};
} #_fetch_url

#------------------------------------------------------------------------

# The following subroutines deal with standard Perl features

#------------------------------------------------------------------------

__END__

=head1 NAME

LCC::Documents - base class for checking document information

=head1 SYNOPSIS

 use LCC;
 $lcc = LCC->new( $source, | {method => value} );
 my $documents = $lcc->Documents( $source | {method => value} ); # auto-type
 my $documents = $lcc->Documents( 'type',$source | {method => value} );

=head1 DESCRIPTION

The Documents object of the Perl support for LCC.  Do not create
directly, but through the Documents method of the LCC object.

=head1 METHODS

These methods are available to the LCC::Documents object.

=head2 browse_url

 $documents->conceptual_url( \&myconceptualurl );
 $coderef = $documents->conceptual_url;

Sets (and/or returns) the subroutine reference of the subroutine that should
be called to convert the document ID to a conceptual URL that the LCC will
store as an internal ID.

The subroutine should accept the ID as the only parameter and return the
conceptual URL that should be stored in the LCC database.

By default, a subroutine that returns the document ID, will be used.

=head2 browse_url

 $documents->browse_url( \&mybrowseurl );
 $coderef = $documents->browse_url;

Sets (and/or returns) the subroutine reference of the subroutine that should
be called to convert the document ID to a URL that the LCC will store as the
URL that users should use to access the document.

The subroutine should accept the ID as the only parameter and return the URL
that should be used as URL for the browser.

By default, a subroutine that returns undef will be used, indicating that the
browse URL is the same as the L<fetch_url>.

=head2 fetch_url

 $documents->fetch_url( \&myfetchurl );
 $coderef = $documents->fetch_url;

Sets (and/or returns) the subroutine reference of the subroutine that should
be called to convert the document ID to the URL that the LCC will use to fetch
the document.

The subroutine should accept the ID as the only parameter and return the URL
that should be used as URL to fetch the document.

By default, a subroutine that returns undef will be used, indicating that the
browse URL is the same as the L<fetch_url>.

=head2 next_document

 my ($id,$mtime,$length,$md5,$mimetype,$subtype) = $documents->next_document;

This method is called by the L<LCC::check> method to obtain the information
about the next document to be checked.  Should return an empty list when
there are no more documents to be checked.

This method is always implemented by the sub-modules.  Please do B<not> call
directly.

=head2 server

 $documents->server;                          # default to `hostname` and 'html'
 $documents->server( 'www.host.com','html' ); # use specified server and ext

Sets the L<browse_url> subroutine reference to always return undef, so that
the browse URL will always be the same as the fetch URL.

Sets the L<fetch_url> subroutine reference to allow for a simple translation
from the document ID to a URL that the LCC should use to fetch the document.
The input parameter specifies the server name that should be prefixed in the
URL.  If not specified, the server name will default to what is returned by
`hostname`.

Also sets the L<conceptual_url> subroutine reference so that the document ID
is returned as the conceptual URL.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 2002 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://lococa.sourceforge.net, the LCC.pm and the other LCC::xxx modules.

=cut
