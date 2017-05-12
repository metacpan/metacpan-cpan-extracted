package Dezi::UI;

use warnings;
use strict;
use base qw( Plack::Middleware );
use Carp;
use Plack::Request;
use Plack::Util::Accessor qw( base_uri search_path );
use Data::Dump qw( dump );

our $VERSION = '0.001005';

=head1 NAME

Dezi::UI - HTML interface to a Dezi server

=head1 SYNOPSIS

 % dezi --ui-class=Dezi::UI

=head1 DESCRIPTION

Dezi::UI is an example HTML interface for exploring a Dezi server.
Dezi::UI isa Plack::Middleware.

=head1 METHODS

=head2 default_page

Returns the HTML string suitable for the main UI. It uses
the jQuery-based examples from dezi.org.

=cut

sub default_page {
    return <<EOF;
<html>
 <head>
  <title>Dezi UI</title>
  <link rel="stylesheet" type="text/css" href="//dezi.org/ui/example/dezi-ui.css" />
  <script type="text/javascript">var DEZI_SEARCH_URI = 'REPLACE_ME';</script>
  <script src="//ajax.googleapis.com/ajax/libs/jquery/1.7.2/jquery.min.js" type="text/javascript"></script>
  <script src="//dezi.org/ui/example/jquery.ba-bbq.js" type='text/javascript'></script>
  <script src="//dezi.org/ui/example/dezi-ui-jquery.js" type='text/javascript'></script>
 </head>
 <body></body>
</html>
EOF

}

=head2 call( I<env> )

Implements the required Middleware method. GET requests
are the only allowed interface.

=cut

sub call {
    my ( $self, $env ) = @_;
    my $req  = Plack::Request->new($env);
    my $path = $req->path;
    my $resp = $req->new_response;
    if ( $req->method eq 'GET' ) {
        $resp->status(200);
        $resp->content_type('text/html');
        my $body = $self->default_page;
        my $search_uri;
        if ($self->base_uri) {
            $search_uri  = $self->base_uri . $self->search_path;
        }
        else {
            my $uri = $req->base;
            $uri =~ s,/ui,,; 
            $search_uri = $uri . $self->search_path;
        }
        $body =~ s,REPLACE_ME,$search_uri,g;
        $resp->body($body);
    }
    else {
        $resp->status(400);
        $resp->body('GET only allowed');
    }
    return $resp->finalize;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-ui at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-UI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::UI

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-UI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-UI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-UI>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-UI/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
