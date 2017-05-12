package Dezi::Admin;
use strict;
use warnings;
use Carp;
use Plack::Builder;
use Plack::App::File;
use Dezi::Admin::Config;

our $VERSION = '0.006';

=head1 NAME

Dezi::Admin - Dezi server administration UI

=head1 SYNOPSIS

 my $app = Dezi::Server->app(
     {   
         search_path   => 's',
         index_path    => 'i',
         engine_config => {
             indexer_config => {
                 config => { 'FuzzyIndexingMode' => 'Stemming_en1', },
             },
         },
         admin_class  => 'Dezi::Admin',
         stats_logger => $stats,
     }
 );

 # or from the command line

 % dezi --admin-class=Dezi::Admin

=head1 DESCRIPTION

Dezi::Admin is a Plack middleware that creates an administration
web interface to a Dezi server.

=head1 METHODS

=head2 app(I<args>)

Returns a Plack-ready application via Plack::Builder.

I<args> are passed directly to L<Dezi::Admin::Config> new().

=cut

sub app {
    my $self         = shift;
    my %args         = @_;
    my $admin_config = Dezi::Admin::Config->new(%args);

    return builder {

        enable "SimpleLogger",
            level => $admin_config->debug ? "debug" : "warn";

        enable_if { $_[0]->{REMOTE_ADDR} eq '127.0.0.1' }
        "Plack::Middleware::ReverseProxy";

        if ( defined $admin_config->authenticator ) {
            enable "Auth::Basic",
                authenticator => $admin_config->authenticator,
                realm         => $admin_config->auth_realm;
        }

        # HTML
        mount '/' => $admin_config->ui_server;

        # CSS/JS/etc
        mount '/static' =>
            Plack::App::File->new( root => $admin_config->ui_static_path )
            ->to_app;

        # REST API
        mount '/api' => $admin_config->api_server;

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
