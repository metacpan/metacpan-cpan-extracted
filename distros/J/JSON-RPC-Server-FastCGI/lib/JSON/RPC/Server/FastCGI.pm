package JSON::RPC::Server::FastCGI;

use warnings;
use strict;
use CGI::Fast;
use base qw(JSON::RPC::Server::CGI);

=head1 NAME

JSON::RPC::Server::FastCGI - A FastCGI version of JSON::RPC::Server

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

	use JSON::RPC::Server::FastCGI;
    use lib 'libs/'; # you could put your handler modules here

    # If you want to use an 'External' FastCGI Server:
    # $ENV{FCGI_SOCKET_PATH} = "elsewhere:8888";

	my $server = JSON::RPC::Server::FastCGI->new;
    $server->dispatch_to('MyApp')->handle();

=head1 CONSTRUCTOR

=head2 new

Creates a server. All that needs to be done is call dispatch (or dispatch_to)
followed by $server->handle().

=cut 
# We cannot use the direct parent method (JSON::RPC::Server::CGI::new);
# though we are a subclass of JSON::RPC::Server::CGI, we cannot
# invoke it's constructor since it is per-request, and FastCGI is not.
# That's why we just use the more general grand-parent constructor.
sub new {
    my $self  = JSON::RPC::Server::new(@_);
    $self;
}

=head1 OVERRIDDEN METHODS

=head2 handle

This is exactly the same as $server->handle, except 
that it uses an instance of CGI::Fast instead of CGI.

=cut

sub handle {
    my $self = shift;
	my $cgi;
	while ($cgi = new CGI::Fast) {
		$self->request( HTTP::Request->new($cgi->request_method, $cgi->url) );
		$self->{_cgi} = $cgi;
		$self->SUPER::handle();
	}
}

=head2 cgi

Returns the CGI::Fast object associated with this server.

=cut

sub cgi {
    my $self = shift;
	return $self->{_cgi};
}


=head1 METHODS

    Pretty much the same as JSON::RPC::Server;
    (See L<http://search.cpan.org/~makamaka/JSON-RPC/lib/JSON/RPC.pm>)


=head1 AUTHOR

Faiz Kazi, C<< <faiz at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-json-rpc-server-fastcgi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=JSON-RPC-Server-FastCGI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JSON::RPC::Server::FastCGI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JSON-RPC-Server-FastCGI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JSON-RPC-Server-FastCGI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JSON-RPC-Server-FastCGI>

=item * Search CPAN

L<http://search.cpan.org/dist/JSON-RPC-Server-FastCGI>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2008 Faiz Kazi, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of JSON::RPC::Server::FastCGI
