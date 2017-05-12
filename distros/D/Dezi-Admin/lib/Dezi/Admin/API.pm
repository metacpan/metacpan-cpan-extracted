package Dezi::Admin::API;
use strict;
use warnings;
use Carp;
use Plack::Builder;
use Data::Dump qw( dump );
use JSON;
use Dezi::Admin::API::Indexes;

our $VERSION = '0.006';

=head1 NAME

Dezi::Admin::API - Dezi administration API

=head1 SYNOPSIS

 use Plack::Builder;
 use Dezi::Admin::API;
 my $api_app = Dezi::Admin::API->app(
    searcher        => $dezi_server,
    admin_config    => $dezi_admin_config,
 );
 builder {
     mount '/api' => $api_app
 };
 
=head1 DESCRIPTION

Plack application for Dezi administration API. Uses 
L<Plack::Middleware::REST> to give access to Dezi stats
and index metadata.

=head1 METHODS

=cut

=head2 app

Returns the API Plack app.

=cut

sub app {
    my $self    = shift;
    my %configs = @_;

    #dump \%configs;

    my $searcher = delete $configs{searcher}
        or croak "searcher required";
    my $admin_config = delete $configs{admin_config}
        or croak "admin key required in user_config";

    if ( !$admin_config->isa('Dezi::Admin::Config') ) {
        croak "admin value should be a Dezi::Admin::Config object";
    }

    # need to call this before we access ->engine for the first time.
    $searcher->setup_engine();

    my @models;
    my $stats_app;
    my $stats_logger = $searcher->stats_logger;
    if (    $stats_logger
        and $stats_logger->isa('Dezi::Stats::DBI') )
    {
        require Dezi::Admin::API::Stats;
        my $conn = $stats_logger->conn;
        my $tbl  = $stats_logger->table_name;

        $stats_app = Dezi::Admin::API::Stats->new(
            conn       => $conn,
            table_name => $tbl,
            searcher   => $searcher,
        )->to_app();
        push @models, 'stats';
    }

    return builder {

        # index meta
        mount '/indexes' => builder {
            enable 'REST',
                get => Dezi::Admin::API::Indexes::GET->new(
                engine => $searcher->engine, )->to_app(),
                list => Dezi::Admin::API::Indexes::LIST->new(
                engine => $searcher->engine, )->to_app(),
                pass_through => 0;
        };

        # Dezi::Stats
        if ($stats_app) {

            mount '/stats' => $stats_app;

        }

        # About page
        mount '/' => builder {
            sub {
                my $req   = Plack::Request->new(shift);
                my $resp  = $req->new_response();
                my $about = {
                    name    => $self,
                    version => $VERSION,
                    models  => \@models,
                    type    => $searcher->engine->type,
                };
                $resp->body( to_json($about) );
                $resp->status(200);
                $resp->content_type('application/json');
                return $resp->finalize();
            };
        };

    };

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
