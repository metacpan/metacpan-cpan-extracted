
package HTTP::DAVServer::AuthDigest;

our $VERSION=0.1;

use strict;
use warnings;

use Digest::MD5 qw();

=head1 NAME

HTTP::DAVServer::AuthDigest - Allows for customized password lookups when using
the Digest authorization mechanism.

=head1 DESCRIPTION

This module is called as part of the DAV handler when it is a non-public server that
does not have a REMOTE_USER set already. You can pass in a subreference which will be
called to lookup the user's password.

For testing this is simply all users are valid and their password is their userid.

In order for this code to work it must get the "Authorization" header passed in via CGI.
To do this you need to compile Apache with the ominous define "SECURITY_HOLE_PASS_AUTHORIZATION"

 CFLAGS="-DSECURITY_HOLE_PASS_AUTHORIZATION" ./configure

Like people haven't sniffed your basic authorization header before it got to the server already.
At least with Digest this header is a bit less useful for the hostial sniffer.

This code is not done and is only a sketch. 

=cut

sub headerParts {
    
    my $header=$_[0];
	$header =~ s/^Digest /", /;
    $header =~ s/"\s*$//;

	my @parts=split /", ([a-z]+)="/, $header;
	shift @parts;
    my %parts=@parts;
    return \%parts;

}

# Code inspired from LWP::Authen::Digest
#  - to conform to RFC 2617
#
#  Send in 
#      password callback (fed username) (default to username for passwd)
#      parts hashref (computed for CGI)
#      request method (computed for CGI)

sub authenticate {

	my ($passwd, $parts, $method) = @_;

    $passwd ||= sub { return $_[0] };

    if ($ENV{'GATEWAY_INTERFACE'}=~/^CGI/) {
        $method ||= $ENV{'REQUEST_METHOD'};
        $parts  ||= headerParts( $ENV{'HTTP_AUTHORIZATION'} );
    }

    my $md5=Digest::MD5->new;
    my @digest=();

    $md5->add( join(":", $parts->{'username'}, $parts->{'realm'}, $passwd->( $parts->{'username'} ) ));
    push @digest, $md5->hexdigest;
    $md5->reset;

    push @digest, $parts->{'nonce'};
    if ( $parts->{'qop'} ) {
        push @digest, $parts->{'nc'}, $parts->{'cnonce'}, $parts->{'qop'};
    }

    $md5->add(join( ":", $method, $parts->{'uri'} ) );  
    push @digest, $md5->hexdigest;
    $md5->reset;

    $md5->add( join ":", @digest);

    $ENV{'REMOTE_USER'} = $parts->{'username'} and return 1 if ( $md5->hexdigest eq $parts->{'response'} );
    return 0;


}


# Usage
#   $authenticated=authenticate( \&passwordLookup, [ $parts, $method] )
#     - sets REMOTE_USER environment variable
#
#   passwordLookup is a callback - supplied the rqeuested userid - returns cleartext password
#

=head1 SUPPORT

For technical support please email to jlawrenc@cpan.org ... 
for faster service please include "HTTP::DAVServer" and "help" in your subject line.

=head1 AUTHOR

 Jay J. Lawrence - jlawrenc@cpan.org
 Infonium Inc., Canada
 http://www.infonium.ca/

=head1 COPYRIGHT

Copyright (c) 2003 Jay J. Lawrence, Infonium Inc. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 ACKNOWLEDGEMENTS

Thank you to the authors of my prequisite modules. With out your help this code
would be much more difficult to write!

 XML::Simple - Grant McLean
 XML::SAX    - Matt Sergeant
 DateTime    - Dave Rolsky

Also the authors of litmus, a very helpful tool indeed!

=head1 SEE ALSO

HTTP::DAV, HTTP::Webdav, http://www.webdav.org/, RFC 2518

=cut

1;

