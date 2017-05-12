package HTTP::ClientDetect::Location;

use 5.006;
use strict;
use warnings FATAL => 'all';
use Module::Load;
use Moo;

=head1 NAME

HTTP::ClientDetect::Location - Lookup the country of the client using Geo::IP

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';


=head1 SYNOPSIS

    use HTTP::ClientDetect::Location;
    my $geo = HTTP::ClientDetect::Location->new(db => "/path/to/geo-ip");
    # inside a Dancer route
    get '/detect' => sub {
        my $req = request;
        my $country_code = $geo->country_code($req);
    }


=head1 ACCESSORS

=head2 db

Path to the geoip database, which can be retrieved from
http://dev.maxmind.com/geoip/legacy/geolite/

C<db> must be passed to the constructor.

=cut

has db => (is => 'ro',
           required => 1,
           isa => sub {
               die "db is not a file" unless -f $_[0];
           });


=head2 geo

This accessor wraps L<Geo::IP> or L<Geo::IP::PurePerl>. Calling
$geo->geo will return an instantiated object, and you can call, e.g.
C<$geo->geo->country_code_by_addr("128.31.0.51")> or
C<$geo->geo->country_code_by_name("linuxia.de")>.

=cut

has geo => (is => 'rwp',
            builder => 1);

sub _build_geo {
    my $self = shift;
    my $module = "Geo::IP";
    eval {
        load $module;
    };
    if ($@) {
        $module .= "::PurePerl";
        # if we die here too bad
        load $module;
    }
    my $gi = $module->open($self->db);
    return $gi;
}

=head1 SUBROUTINES/METHODS

=head2 request_country($request_obj)

Return the country of the request. The request should be a string with
the ip or L<Dancer::Request> object (or something that respond to the
method "remote_address").

=cut

sub request_country {
    my ($self, $arg) = @_;
    my $ip;
    if (ref($arg)) {
        # Dancer
        if ($arg->can("remote_address")) {
            $ip = $arg->remote_address;
        }
        # Catalyst
        elsif ($arg->can("address")) {
            $ip = $arg->address;
        }
    }
    else {
        $ip = $arg;
    }
    return unless $ip;
    if ($ip =~ m/(([0-9]{1,3}\.){3}([0-9]{1,3}))/) {
        $ip = $1;
        return $self->geo->country_code_by_addr($ip);
    }
    else {
        return;
    }
}

=head1 AUTHOR

Marco Pessotto, C<< <melmothx at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-interchange6-plugin-autodetect at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HTTP-ClientDetect>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc HTTP::ClientDetect::Location


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTTP-ClientDetect>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HTTP-ClientDetect>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HTTP-ClientDetect>

=item * Search CPAN

L<http://search.cpan.org/dist/HTTP-ClientDetect/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Marco Pessotto.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See L<http://dev.perl.org/licenses/> for more information.


=cut

1; # End of HTTP::ClientDetect::Location
