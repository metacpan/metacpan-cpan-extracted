package Dezi::Admin::UI;
use strict;
use warnings;
use Carp;
use base qw( Plack::Component );
use Plack::Request;
use Data::Dump qw( dump );
use Plack::Util::Accessor qw(
    debug
    base_uri
    extjs_uri
);

our $VERSION = '0.006';

=head1 NAME

Dezi::Admin::UI - Dezi administration UI application

=head1 SYNOPSIS

 use Plack::Builder;
 use Dezi::Admin::UI;
 my $ui_app = Dezi::Admin::UI->new(
    debug       => 0,
    base_uri    => '',
    extjs_uri   => '//cdn.sencha.io/ext-4.1.1-gpl',
 );
 builder {
    mount '/' => $ui_app;
 };
 
=head1 DESCRIPTION

Dezi::Admin::UI provides bootstrapping HTML to the ExtJS
application. Dezi::Admin::UI is a L<Plack::Component> subclass.

=head1 METHODS

=cut

=head2 prepare_app

Override base class to set default extjs_uri() value.

=cut

sub prepare_app {
    my ($self) = @_;
    $self->{extjs_uri} ||= '//cdn.sencha.io/ext-4.1.1-gpl';
}

=head2 default_page

Returns the HTML string suitable for the main UI. It uses
the jQuery-based examples from dezi.org.

=cut

sub default_page {
    my $self      = shift;
    my $extjs_uri = $self->extjs_uri;
    my $base_uri  = $self->base_uri;
    return <<EOF;
<html>
 <head>
  <title>Dezi Admin</title>
  
  <script type="text/javascript">
      ExtJS_URL             = '$extjs_uri';
      DEZI_ADMIN_BASE_URL   = '$base_uri/admin';
      DEZI_ABOUT = {};
  </script>
  
  <!-- ext base js/css -->
  <link rel="stylesheet" type="text/css" href="$extjs_uri/resources/css/ext-all.css" />
  <link rel="stylesheet" type="text/css" href="$extjs_uri/examples/shared/example.css" />
  <link rel="stylesheet" type="text/css" href="$extjs_uri/examples/portal/portal.css" />
  <link rel="stylesheet" type="text/css" href="$extjs_uri/examples/ux/css/GroupTabPanel.css" />
    
  <script type="text/javascript" charset="utf-8" src="$extjs_uri/ext-all.js"></script>
  <script type="text/javascript" charset="utf-8" src="$extjs_uri/examples/grouptabs/all-classes.js"></script>

  <script type="text/javascript">
      Ext.Ajax.request({
          url: '$base_uri/',
          success: function(resp,opts) {
              DEZI_ABOUT = Ext.decode(resp.responseText);
          }
      });
  </script>
  
  <!-- dezi server js/css -->
  <link rel="stylesheet" type="text/css" href="$base_uri/admin/static/css/dezi-admin.css" />
  <script type="text/javascript" charset="utf-8" src="$base_uri/admin/static/js/dezi-admin.js"></script>

 </head>
 <body id="ui"></body><!-- rendered via js -->
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
    my $resp = $req->new_response;

    if ( $req->method eq 'GET' ) {
        if ( $req->path ne '/' ) {
            $resp->status(404);
            $resp->body('No such resource');
        }
        else {
            my $body = $self->default_page;
            $resp->body($body);
        }
    }
    else {
        $resp->status(405);
        $resp->body('Allowed: GET');
    }

    $resp->status(200)               unless $resp->status;
    $resp->content_type('text/html') unless $resp->content_type;
    return $resp->finalize;
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-admin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-Admin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Admin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Admin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-Admin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-Admin>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-Admin/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
