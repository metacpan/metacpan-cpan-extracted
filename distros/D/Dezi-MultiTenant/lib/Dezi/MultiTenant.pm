package Dezi::MultiTenant;
use strict;
use warnings;
use Dezi::Server;
use Dezi::MultiTenant::Config;
use JSON;
use Plack::Builder;
use Plack::Request;
use Plack::App::URLMap;
use Data::Dump qw( dump );
use Carp;
use Module::Load;
use Scalar::Util qw( blessed );

our $VERSION = '0.003';

=head1 NAME

Dezi::MultiTenant - multiple Dezi::Server applications in a single instance

=head1 SYNOPSIS

 % dezi --server-class Dezi::MultiTenant --dezi-config myconfig.pl
 
 # or in your own Plack app
 
 use Plack::Runner;
 use Dezi::MultiTenant;
 
 my $multitenant_config = { 
   'foo' => Dezi::Config->new(\%foo_opts),
   'bar' => Dezi::Config->new(\%bar_opts),
 };
 
 my $runner = Plack::Runner->new();
 my $app = Dezi::MultiTenant->app( $multitenant_config );
 $runner->run($app);
 
 # /foo mounts a Dezi::Server
 # /bar mounts a Dezi::Server
 
=head1 DESCRIPTION

Dezi::MultiTenant provides a simple way to mount multiple
Dezi::Server applications in a single Plack app using
a single configuration structure.

Dezi::Server allows you to serve multiple indexes, but all
the indexes must have identical schemas.

Dezi::MultiTenant allows you to server multiple indexes per
server, and each server can have a different schema, as well
as individual administration, logging, unique configuration, etc.

=head1 METHODS

=cut

=head2 app( I<config> )

Returns Plack $app instance via Plack::Builder. 

I<config> should either be a hashref with keys representing each
Dezi::Server's mount point, or a Dezi::MultiTenant::Config object.
By default the root '/' mount point is reserved for the 
Dezi::MultiTenant->about() method response. Hash keys should have
the '/' prefix (same syntax as L<Plack::App::URLMap>).

=cut

sub app {
    my $class = shift;
    my $config = shift or croak "config required";
    my $mt_config;
    if ( blessed $config) {
        if ( $config->isa('Dezi::MultiTenant::Config') ) {
            $mt_config = $config;
        }
        else {
            croak "config is not a Dezi::MultiTenant::Config-derived object";
        }
    }
    else {
        $mt_config = Dezi::MultiTenant::Config->new($config);
    }

    my $url_map = Plack::App::URLMap->new();
    my @loaded;
    for my $path ( $mt_config->paths() ) {
        $url_map->map(
            $path => builder {
                mount '/' =>
                    Dezi::Server->app( $mt_config->config_for($path) );
            }
        );
        push @loaded, $path;
    }

    return builder {

        # global logging
        enable "SimpleLogger", level => $config->{'debug'} ? "debug" : "warn";

        # optional gzip compression for clients that request it
        # client must set "Accept-Encoding" request header
        enable "Deflater",
            content_type => [
            'text/css',        'text/html',
            'text/javascript', 'application/javascript',
            'text/xml',        'application/xml',
            'application/json',
            ],
            vary_user_agent => 1;

        # JSONP response based on 'callback' param
        enable "JSONP";

        # / is self-description
        $url_map->map(
            '/' => sub {
                my $req = Plack::Request->new(shift);
                return $class->about( $req, \@loaded );
            }
        );

        $url_map->map(
            '/favicon.ico' => sub {
                my $req = Plack::Request->new(shift);
                my $res = $req->new_response();
                $res->redirect( 'http://dezi.org/favicon.ico', 301 );
                $res->finalize();
            }
        );

        # TODO /admin

        $url_map->to_app;
    };

}

=head2 about( I<plack_request>, I<loaded> )

Returns Plack::Response-like array ref
describing the multi-tenant application.

=cut

sub about {
    my ( $class, $req, $loaded ) = @_;

    if ( $req->path ne '/' ) {
        my $resp = 'Resource not found';
        return [
            404,
            [   'Content-Type'   => 'text/plain',
                'Content-Length' => length $resp,
            ],
            [$resp]
        ];
    }

    my $base_uri = $req->base;
    $base_uri =~ s,/$,,;    # zap any trailing /
    my %avail = ();
    for my $i (@$loaded) {

        # virtual host check
        if ( $i =~ m!^https?:! ) {
            $avail{$i} = $i;
        }
        else {
            $avail{$i} = $base_uri . $i;
        }
    }

    my $about = {
        description => $class,
        version     => $VERSION,
        available   => \%avail,
    };
    my $resp = to_json($about);
    return [
        200,
        [   'Content-Type'   => 'application/json',
            'Content-Length' => length $resp,
        ],
        [$resp],
    ];
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-multitenant at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-MultiTenant>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::MultiTenant


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-MultiTenant>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-MultiTenant>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-MultiTenant>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-MultiTenant/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

