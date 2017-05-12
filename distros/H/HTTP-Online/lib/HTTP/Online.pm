package HTTP::Online;

=pod

=head1 NAME

HTTP::Online - Detect full "Internet" (HTTP) access using Microsoft NCSI

=head1 SYNOPSIS

    if ( HTTP::Online->new->online ) {
        print "Confirmed internet connection\n";
    } else {
        print "Internet is not available\n";
        exit(0);
    }
    
    # Now do your task that needs the internet...

=head1 DESCRIPTION

B<HTTP::Online> is a port of the older L<LWP::Online> module to L<HTTP::Tiny>
that uses only the (most accurate) methodology,
L<Microsoft NCSI|http://technet.microsoft.com/en-us/library/cc766017.aspx>.

=head2 Test Mode

  use LWP::Online ':skip_all';

As a convenience when writing tests scripts base on L<Test::More>, the
special ':skip_all' param can be provided when loading B<LWP::Online>.

This implements the functional equivalent of the following.

	BEGIN {
		unless ( HTTP::Online->new->online ) {
			require Test::More;
			Test::More->import(
				skip_all => 'Test requires a working internet connection'
			);
		}
	}

=head1 METHODS

=cut

use 5.006;
use strict;
use HTTP::Tiny 0.019 ();

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.02';
}

sub import {
	my $class = shift;
	if ( $_[0] and $_[0] eq ':skip_all' ) {
		require Test::More;
		unless ( HTTP::Online->new->online ) {
			Test::More->import( skip_all => 'Test requires a working internet connection' );			
		}
	}
}





######################################################################
# Constructor and Accessors

=pod

=head2 new

	my $internet = HTTP::Online->new;

	my $custom = HTTP::Online->new(
		http    => $custom_http_client,
		url     => 'http://my-ncsi-server.com/',
		content => 'Our Custom NCSI Server',
	);

The C<new> constructor creates a query object.

By default, it will be configured to use the same Microsoft NCSI service that
the Windows Network Awareness system does (from Windows Vista onwards).

Returns a L<HTTP::Online> object.

=cut

sub new {
	my $class = shift;
	my $self  = bless { @_ }, $class;

	# Apply defaults
	unless ( defined $self->{http} ) {
		$self->{http} = HTTP::Tiny->new(
			agent => "$class/$VERSION",
		);
	}
	unless ( defined $self->{url} ) {
		$self->{url} = 'http://www.msftncsi.com/ncsi.txt';
	}
	unless ( defined $self->{content} ) {
		$self->{content} = 'Microsoft NCSI';
	}

	return $self;
}

=pod

=head2 http

The C<http> method returns the HTTP client that will be used for the query.

=cut

sub http {
	$_[0]->{http};
}

=pod

=head2 url

The C<url> method returns a string with the location URL of the NCSI file.

=cut

sub url {
	$_[0]->{url};
}

=pod

=head2 content

The C<content> method returns a string with the expected string to be returned
from the NCSI server.

=cut

sub content {
	$_[0]->{content};
}





######################################################################
# Main Methods

=pod

=head2 online

The C<online> method issues a C<Pragma: no-cache> request to the server, and
examines the response to confirm that no redirects have occurred, and that the
returned content matches the expected value.

Returns true if full HTTP internet access is available, or false otherwise.

=cut

sub online {
	my $self     = shift;
	my $response = $self->http->get( $self->url, {
		headers => {
			Pragma => 'no-cache',
		},
	} );

	return (
		$response
		and
		$response->{success}
		and
		$response->{url} eq $self->url
		and
		$response->{content} eq $self->content
	);
}

=pod

=head2 offline

The C<offline> method is a convenience which currently returns the opposite of
the C<online> method, returning false if full HTTP internet access is available,
or true otherwise.

This may change in future to only return true if we are completely offline, and
true in situations where we have partial internet access or the user needs to
fill out some web form or view advertising to get full internet access.

=cut

sub offline {
	not $_[0]->online;
}

1;

=pod

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-Online>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

=head1 SEE ALSO

L<LWP::Online>

L<HTTP::Tiny>

L<http://technet.microsoft.com/en-us/library/cc766017.aspx>

=head1 COPYRIGHT

Copyright 2012 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
