package Geo::Coder::RandMcnally;

use strict;
use warnings;

use Carp qw(croak);
use Encode ();
use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = '0.01';
$VERSION = eval $VERSION;

sub new {
    my ($class, %params) = @_;

    my $self = bless \ %params, $class;

    $self->ua(
        $params{ua} || LWP::UserAgent->new(agent => "$class/$VERSION")
    );

    if ($self->{debug}) {
        my $dump_sub = sub { $_[0]->dump(maxlength => 0); return };
        $self->ua->set_my_handler(request_send  => $dump_sub);
        $self->ua->set_my_handler(response_done => $dump_sub);
    }
    elsif ($self->{compress}) {
        $self->ua->default_header(accept_encoding => 'gzip,deflate');
    }

    return $self;
}

sub response { $_[0]->{response} }

sub ua {
    my ($self, $ua) = @_;
    if ($ua) {
        croak q('ua' must be (or derived from) an LWP::UserAgent')
            unless ref $ua and $ua->isa(q(LWP::UserAgent));
        $self->{ua} = $ua;
    }
    return $self->{ua};
}

sub geocode {
    my ($self, @params) = @_;
    my %params = (@params % 2) ? (location => @params) : @params;

    while (my ($key, $val) = each %params) {
        $params{$key} = Encode::encode('utf-8', $val);
    }
    my $location = delete $params{location} or return;

    my $uri = URI->new('http://a2ageo.rmservers.com/mapengine3/sli');
    $uri->query_form(
        tid   => rand,
        line  => $location,
        %params,
    );

    my $res = $self->{response} = $self->ua->get(
        $uri, referer => 'http://maps.randmcnally.com/'
    );
    return unless $res->is_success;

    # Change the content type of the response from 'application/json' so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain');

    my $content = $res->decoded_content;
    return unless $content;

    my $data = eval { from_json($content) };
    return unless $data;

    my @results = @{ $data->{geocodedLocation} || [] };
    return wantarray ? @results : $results[0];
}


1;

__END__

=head1 NAME

Geo::Coder::RandMcnally - Geocode addresses with Rand Mcnally Maps

=head1 SYNOPSIS

    use Geo::Coder::RandMcnally;

    my $geocoder = Geo::Coder::RandMcnally->new;
    my $location = $geocoder->geocode(
        location => '9855 Woods Drive, Skokie, IL'
    );

=head1 DESCRIPTION

The C<Geo::Coder::RandMcnally> module provides an interface to the geocoding
service of Rand Mcnally Maps through an unofficial REST API.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::RandMcnally->new();

Creates a new geocoding object.

Accepts an optional B<ua> parameter for passing in a custom LWP::UserAgent
object.

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

In scalar context, this method returns the first location result; and in
list context it returns all location results.

Each location result is a hashref; a typical example looks like:

    {
      city       => "Skokie",
      country    => "USA",
      county     => "Cook County",
      lat        => "42.056628",
      lon        => "-87.761216",
      name       => "9855 Woods Dr, Skokie, 60077-1074, Cook County, IL, USA",
      postalCode => "60077-1074",
      precision  => 6,
      state      => "IL",
      street     => "9855 Woods Dr",
    }

=head2 response

    $response = $geocoder->response()

Returns an L<HTTP::Response> object for the last submitted request. Can be
used to determine the details of an error.

=head2 ua

    $ua = $geocoder->ua()
    $ua = $geocoder->ua($ua)

Accessor for the UserAgent object.

=head1 NOTES

International (non-US) queries do not appear to be supported by the service
at this time.

=head1 SEE ALSO

L<http://maps.randmcnally.com/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-RandMcnally>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::RandMcnally

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-randmcnally>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-RandMcnally>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-RandMcnally>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-RandMcnally>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-RandMcnally/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
