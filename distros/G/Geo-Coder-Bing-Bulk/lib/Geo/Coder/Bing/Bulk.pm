package Geo::Coder::Bing::Bulk;

use strict;
use warnings;

use Carp qw(croak);
use Encode ();
use HTTP::Request::Common ();
use JSON;
use LWP::UserAgent;
use URI;

our $VERSION = '0.04';
$VERSION = eval $VERSION;

sub new {
    my ($class, @params) = @_;
    my %params = (@params % 2) ? (key => @params) : @params;

    croak q('key' is required) unless $params{key};

    my $self = bless \ %params, $class;

    $self->ua(
        $params{ua} || LWP::UserAgent->new(agent => "$class/$VERSION")
    );

    if ($self->{debug}) {
        my $dump_sub = sub { $_[0]->dump(maxlength => 0); return };
        $self->ua->set_my_handler(request_send  => $dump_sub);
        $self->ua->set_my_handler(response_done => $dump_sub);
    }
    elsif (exists $self->{compress} ? $self->{compress} : 1) {
        $self->ua->default_header(accept_encoding => 'gzip,deflate');
    }

    croak q('https' requires LWP::Protocol::https)
        if $self->{https} and not $self->ua->is_protocol_supported('https');

    $self->{status}  = '';

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

sub upload {
    my $self = shift;

    my $locs = (1 == @_ and 'ARRAY' eq ref $_[0]) ? $_[0] : \@_;
    return unless @$locs;

    my $uri = URI->new(
        'http://spatial.virtualearth.net/REST/v1/Dataflows/Geocode',
    );
    $uri->scheme('https') if $self->{https};
    $uri->query_form(
        key   => $self->{key},
        input => 'pipe',
    );

    my $req = HTTP::Request::Common::POST(
        $uri, content_type => 'text/plain',
    );

    my $id = 0;
    for my $loc (@$locs) {
        (my $str = $loc) =~ tr/|\n\r/ /s;
        $req->add_content_utf8("$id||$str\n");
        $id++;
    }
    # Prevents LWP warning about wrong content length.
    $req->content_length(length(${$req->content_ref}));

    my $res = $self->{response} = $self->ua->request($req);
    return unless $res->is_success;

    # Change the content type of the response from 'application/json' so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain');

    my $content = $res->decoded_content;
    return unless $content;

    my $data = eval { from_json($content) };
    return unless $data;

    return $self->{id} = $data->{resourceSets}[0]{resources}[0]{id};
}

sub is_pending {
    my ($self) = @_;

    my $status = $self->_status;
    return 1 if not $status or 'pending' eq $status;
}

sub _status {
    my ($self) = @_;

    return unless $self->{content} or $self->{id};

    my $uri = URI->new(
        'http://spatial.virtualearth.net/REST/v1/Dataflows/Geocode/' .
        $self->{id}
    );
    $uri->scheme('https') if $self->{https};
    $uri->query_form(
        key => $self->{key},
    );

    my $res = $self->{response} = $self->ua->get($uri);
    return unless $res->is_success;

    # Change the content type of the response from 'application/json' so
    # HTTP::Message will decode the character encoding.
    $res->content_type('text/plain');

    my $content = $res->decoded_content;
    return unless $content;

    my $data = eval { from_json($content) };
    return unless $data;

    my $resources = $data->{resourceSets}[0]{resources}[0];
    return unless $resources->{status};

    $self->{failed}    = 1 if $resources->{failedEntityCount};
    $self->{succeeded} = 1 if $resources->{processedEntityCount};

    return $self->{status} = lc $resources->{status};
}

sub download { $_[0]->_download('succeeded') }
sub failed   { $_[0]->_download('failed') }

sub _download {
    my ($self, $type) = @_;

    return unless 'completed' eq $self->{status};
    return unless $self->{$type};

    my $uri = URI->new(
        'http://spatial.virtualearth.net/REST/v1/Dataflows/Geocode/' .
        $self->{id} . '/output/' . $type
    );
    $uri->scheme('https') if $self->{https};
    $uri->query_form(
        key => $self->{key},
    );

    my $res = $self->{response} = $self->ua->get($uri);
    return unless $res->is_success;

    my $content_ref = $res->decoded_content(ref => 1);
    return unless $$content_ref;

    return $self->_parse_output($content_ref);
}

# Convert the pipe-delimited output to a data structure conforming
# to the data schema described here [1].
# [1] http://msdn.microsoft.com/en-us/library/ff701736.aspx
my %field_mapping = (
    0  => 'Id',
    2  => 'Query',
    12 => [ Address => 'AddressLine' ],
    13 => [ Address => 'AdminDistrict' ],
    14 => [ Address => 'CountryRegion' ],
    15 => [ Address => 'District' ],
    16 => [ Address => 'FormattedAddress' ],
    17 => [ Address => 'Locality' ],
    18 => [ Address => 'PostalCode' ],
    19 => [ Address => 'PostalTown' ],
    20 => [ RooftopLocation => 'Latitude' ],
    21 => [ RooftopLocation => 'Longitude' ],
    22 => [ InterpolatedLocation => 'Latitude' ],
    23 => [ InterpolatedLocation => 'Longitude' ],
    24 => 'Confidence',
    25 => 'DisplayName',
    26 => 'EntityType',
    27 => 'StatusCode',
    28 => 'FaultReason',
);

sub _parse_output {
    my ($self, $ref) = @_;

    my @data;
    while ($$ref =~ /([^\n\r]+)/g) {
        my @fields = split '\|', $1, 31;
        my $data = {};
        for my $i (keys %field_mapping) {
            my $val = $fields[$i];
            if (length $val) {
                my $key = $field_mapping{$i};
                if (ref $key) {
                    $data->{$key->[0]}{$key->[1]} = $val;
                }
                else {
                    $data->{$key} = $val;
                }
            }
        }
        push @data, $data;
    }

    return \@data;
}


1;

__END__

=head1 NAME

Geo::Coder::Bing::Bulk - Geocode addresses in bulk with the Bing Spatial
Data Services API

=head1 SYNOPSIS

    use Geo::Coder::Bing::Bulk;

    my $bulk = Geo::Coder::Bing::Bulk->new(key => 'Your Bing Maps key');
    my $id = $bulk->upload(\@locations);
    sleep 30 while $bulk->is_pending;
    my $data = $bulk->download;
    my $failed = $bulk->failed;

=head1 DESCRIPTION

The C<Geo::Coder::Bing::Bulk> module provides an interface to the Bing
Spatial Data Services API.

=head1 METHODS

=head2 new

    $bulk = Geo::Coder::Bing->new('Your Bing Maps key')
    $bulk = Geo::Coder::Bing->new(
        key => 'Your Bing Maps key',
        id  => 'Job ID',
    )

Creates a new bulk geocoding object.

A Bing Maps key can be obtained here:
L<http://msdn.microsoft.com/en-us/library/ff428642.aspx>.

Accepts an optional B<https> parameter for securing network traffic.

Accepts an optional B<ua> parameter for passing in a custom LWP::UserAgent
object.

Accepts an optional B<id> parameter from a previous call to L</upload>.

=head2 upload

    $id = $bulk->upload(\@locations)

Submits a single bulk query for all the given location strings and returns
the assigned job id.

Note that query size is limited to 300 MB (uncompressed) and 200,000
locations; there is a limit of 10 concurrent bulk jobs and 50 jobs per 24
hours.

=head2 is_pending

    $bool = $bulk->is_pending

Polls for the job status and returns true if it has not yet completed.

=head2 download

    $array_ref = $bulk->download

Downloads the results of the query and returns an array reference if there
were results. A typical result looks like:

    {
        Address => {
            AddressLine   => "W Sunset Blvd & Los Liones Dr",
            AdminDistrict => "CA",
            CountryRegion => "United States",
            FormattedAddress =>
                "W Sunset Blvd & Los Liones Dr, Pacific Palisades, CA 90272",
            Locality   => "Pacific Palisades",
            PostalCode => 90272,
        },
        Confidence => "High",
        DisplayName =>
            "W Sunset Blvd & Los Liones Dr, Pacific Palisades, CA 90272",
        EntityType => "RoadIntersection",
        Id         => 0,
        InterpolatedLocation =>
            { Latitude => "34.04185", Longitude => "-118.554" },
        Query      => "Sunset Blvd and Los Liones Dr, Pacific Palisades, CA",
        StatusCode => "Success",
    },


=head2 failed

    $array_ref = $bulk->failed

Returns an array reference if there were query failures.

Note that Bing will report invalid addresses as successfully geocoded even
though it could not determine its location. Failures appear to only concern
query construction- ex. missing fields, etc. So this is likely not going to
affect users of this module- until advanced locations (hashrefs of fields)
are permitted.

=head2 response

    $response = $bulk->response()

Returns an L<HTTP::Response> object for the last submitted request. Can be
used to determine the details of an error.

=head2 ua

    $ua = $bulk->ua()
    $ua = $bulk->ua($ua)

Accessor for the UserAgent object.

=head1 SEE ALSO

L<http://msdn.microsoft.com/en-us/library/ff701734.aspx>

L<Geo::Coder::Bing>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-Bing-Bulk>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Bing::Bulk

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-bing-bulk>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-Bing-Bulk>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-Bing-Bulk>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Bing-Bulk>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-Bing-Bulk/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010-2011 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
