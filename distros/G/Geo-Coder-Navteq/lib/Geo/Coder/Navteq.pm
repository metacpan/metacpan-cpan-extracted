package Geo::Coder::Navteq;

use strict;
use warnings;

use Carp qw(croak);
use Encode ();
use LWP::UserAgent;
use URI;
use XML::Simple ();

our $VERSION = '0.03';
$VERSION = eval $VERSION;

sub new {
    my ($class, @params) = @_;
    my %params = (@params % 2) ? (appkey => @params) : @params;

    croak q('appkey' is required) unless $params{appkey};

    my $self = bless \ %params, $class;

    if ($params{ua}) {
        $self->ua($params{ua});
    }
    else {
        $self->{ua} = LWP::UserAgent->new(agent => "$class/$VERSION");
    }

    if ($self->{debug}) {
        my $dump_sub = sub { $_[0]->dump(maxlength => 0); return };
        $self->ua->set_my_handler(request_send  => $dump_sub);
        $self->ua->set_my_handler(response_done => $dump_sub);
    }
    elsif ($self->{compress}) {
        $self->ua->default_header(accept_encoding => 'gzip,deflate');
    }

    # Each appkey has this url aautomatically added on registration.
    $self->{url} ||= 'http://localhost';

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

    $self->_authenticate or return;

    my $location = $params{location} or return;
    $location = Encode::decode('utf-8', $location);

    my $uri = URI->new('http:/map24/webservices1.5');
    $uri->host($self->_hostname);
    $uri->query_form(
        action              => 'soap',
        bdom                => $self->_bdom($location),
        fromAjax            => 1,
        gzip                => 1,
        mid                 => '***',
        request_id          => ++$self->{request_id},
        sid                 => $self->_session_id,
        writeTypeAttributes => 'false',
        xsltdir             => 'ajax/2.3.0.4700/bdom_wb/',
    );

    my $res = $self->{response} = $self->ua->get(
        $uri, referer => $self->{url},
    );
    return unless $res->is_success;

    my $xml = $res->decoded_content;
    return unless $xml;

    my $data = eval { $self->_parser->xml_in(\$xml) };
    return unless $data;

    my $body = $data->{'soapenv:Body'};

    if (my $err = $body->{'soapenv:Fault'}{faultstring}) {
        if ($err =~ /RequestHeader NOT authenticated/) {
            $self->_authenticate(1);
            return &geocode;
        }

        return;
    }

    my @results = @{
        $body->{'tns:searchFreeResponse'}{MapSearchResponse}{Alternatives}
            || []
    };
    if (@results) {
        $#results = 0 unless wantarray;

        # Convert from decimal minutes to decimal degrees.
        for my $result (@results) {
            do { $_ /= 60 if defined $_ } for
                @{$result->{Coordinate}}{qw(Latitude Longitude)},
                @{$result->{PropertiesMinor}}{qw(X0 X1 Y0 Y1)},
        }
    }

    return wantarray ? @results : $results[0];
}

sub _authenticate {
    my ($self, $force) = @_;

    return 1 if not $force and $self->{auth_time};

    # TODO: determine if there is a standard timeout when sessions need
    # to be reauthed. That would avoid a single doomed geocode request.

    my $uri = URI->new('http:/map24/webservices1.5');
    $uri->host($self->_hostname);
    $uri->query_form(
        action         => 'GetMap24Application',
        applicationkey => $self->{appkey},
        cgi            => 'Map24AuthenticationService',
        requestid      => ++$self->{request_id},
        sid            => $self->_session_id,
    );

    my $res = $self->{response} = $self->ua->get(
        $uri, referer => $self->{url},
    );
    return unless $res->is_success;

    my $xml = $res->decoded_content;
    return unless $xml;

    my $data = eval { $self->_parser->xml_in(\$xml) };
    return unless $data;

    return unless $data->{'soapenv:Body'}{'tns:getMap24ApplicationResponse'}
        ->{GetMap24ApplicationResponse};

    $self->{auth_time} = time;

    return 1;
}

sub _parser {
    $_[0]->{parser} ||= XML::Simple->new(
        ContentKey => '-Value',
        ForceArray => ['item'],
        GroupTags  => {
            Alternatives    => 'item',
            PropertiesMajor => 'item',
            PropertiesMinor => 'item',
        },
        KeyAttr => ['Key'],
        NoAttr  => 1,
    );
}

{
    my @chars = (0..9, 'a'..'z');
    sub _hostname {
        my $rnd = join '', map { $chars[rand 36] } (1..8);
        return $rnd . '.tl.maptp50.map24.com';
    }
}

sub _session_id {
    return $_[0]->{session_id} ||= 'AJAXSESS_' . time . '123_' . rand;
}

# The encoding scheme takes a SOAP message and converts it into a binary
# representation of the resulting DOM. Only the location and session id will
# vary between messages, so the bulk of the message is pre-encoded.
sub _bdom {
    my ($self, $location) = @_;
    return '.74fsearchFree.7n_basicZ75Ltns.0WsearchFreeZ78vurn.0W'
        . 'Map24Geocoder51Z7D_.0G.0G.0GZ'
        . _encode_string($self->_session_id) . 'Z'
        . _encode_string($location) . 'XgzWgAgBWgCgDWgEgFXgJXgMWgGgNWgHgIX'
        . 'gLXgaVgOUXgbVgPUUXg0Xg1VD4fUXg8VgQUUUUU';
}

{
    my @encode_table = (0..9, 'a'..'z', 'A'..'Z', qw(. _));
    my %decode_table = do { my $i = 0; map { $_ => $i++ } @encode_table };

    sub _encode_string {
        my ($str) = @_;

        return 0 unless defined $str;

        $str=~ s{ ([^0-9A-Za-z]) }{
            my $ord = ord $1;
            if (4096 > $ord) {
                join '', '.', @encode_table[$ord >> 6, $ord & 63];
            }
            else {
                join '', '_', @encode_table[
                    $ord >> 24, $ord >> 18 & 63, $ord >> 12 & 63,
                    $ord >> 16 & 63, $ord & 63
                ];
            }
        }egx;

        my $prefix = _encode_number(length $str);

        return $encode_table[ $decode_table{ substr($prefix, 0, 1) } & 15]
            . substr($prefix, 1) . $str;
    }

    sub _encode_number {
        my ($num) = @_;
        return $encode_table[32] unless $num;

        my $len    = length($num);
        my $chunks = int(($len - 1) / 3) + 2;
        my @s      = ('D');
        my $end    = 0;

        for my $chunk (0 .. $chunks - 1) {
            my $i = $chunk * 3;
            my @c = (0, 0, 0);

            for my $j (0 .. 2) {
                if ($i >= $len) {
                    $c[$j] = 15;
                    $end   = 1;
                }
                else {
                    $c[$j] = ord(substr $num, $i, 1) - 48;
                    $c[$j] = 0 if $c[$j] < 0 or $c[$j] > 9;
                }

                $i++
            }
            my $val = $c[0] << 8 | $c[1] << 4 | $c[2];
            push @s, @encode_table[$val >> 6, $val & 63];

            last if $end;
        }
        unless ($end) {
            $s[-1] = $encode_table[ $decode_table{$s[-1]} | 15 ];
        }

        return join '', @s;
    }
}


1;

__END__

=head1 NAME

Geo::Coder::Navteq - Geocode addresses with the Navteq MapTP AJAX API

=head1 SYNOPSIS

    use Geo::Coder::Navteq;

    my $geocoder = Geo::Coder::Navteq->new(
        appkey => 'Your Navteq MapTP AJAX API application key'
    );
    my $location = $geocoder->geocode(
        location => '425 W Randolph St, Chicago, IL'
    );

=head1 DESCRIPTION

The C<Geo::Coder::Navteq> module provides an interface to the geocoding
functionality of the Navteq MapTP AJAX API.

=head1 METHODS

=head2 new

    $geocoder = Geo::Coder::Navteq->new(
        'Your MapTP AJAX API application key'
    )
    $geocoder = Geo::Coder::Navteq->new(
        key   => 'Your MapTP AJAX API application key',
        debug => 1,
    )

Creates a new geocoding object.

An application key can be obtained here:
L<http://www.nn4d.com/site/global/build/web_apis/ajax_api_20/free_ajax_key/ajax_free_register.jsp>

Accepts an optional B<ua> parameter for passing in a custom LWP::UserAgent
object.

=head2 geocode

    $location = $geocoder->geocode(location => $location)
    @locations = $geocoder->geocode(location => $location)

In scalar context, this method returns the first location result; and in
list context it returns all location results.

Each location result is a hashref; a typical example looks like:

    {
        Coordinate => {
            Elevation => "0.0",
            Latitude  => "41.88447265625",
            Longitude => "-87.6388753255208"
        },
        Hierarchy       => 6,
        PropertiesMajor => {
            City   => "Chicago",
            Ctry   => "US",
            Cty    => "Cook",
            Sta    => "IL",
            Street => "425 W Randolph St",
            Zip    => 60606,
        },
        PropertiesMinor => {
            Distance => "0.0",
            ID       => 0,
            Lang     => "ENG",
            LUID     => "NT_4N4sL870u5vRO9r+Zt+44A",
            Q        => 1,
            S        => 100,
            Size     => 1,
            Type     => 6,
            Variance => "0.0029503035",
            X0       => "-87.6398",
            X1       => "-87.6339",
            Y0       => "41.8844966666667",
            Y1       => "41.8844",

        },
        Quality    => "Exact",
        Similarity => "1.0",
    }

=head2 response

    $response = $geocoder->response()

Returns an L<HTTP::Response> object for the last submitted request. Can be
used to determine the details of an error.

=head2 ua

    $ua = $geocoder->ua()
    $ua = $geocoder->ua($ua)

Accessor for the UserAgent object.

=head1 SEE ALSO

L<http://www.nn4d.com/site/global/build/manuals/ajaxapiintroduction.jsp>

L<Geo::Coder::Bing>, L<Geo::Coder::Bing::Bulk>, L<Geo::Coder::Google>,
L<Geo::Coder::Mapquest>, L<Geo::Coder::Multimap>, L<Geo::Coder::OSM>,
L<Geo::Coder::PlaceFinder>, L<Geo::Coder::TomTom>, L<Geo::Coder::Yahoo>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/Public/Bug/Report.html?Queue=Geo-Coder-Navteq>. I will
be notified, and then you'll automatically be notified of progress on your
bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Geo::Coder::Navteq

You can also look for information at:

=over

=item * GitHub Source Repository

L<http://github.com/gray/geo-coder-navteq>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Geo-Coder-Navteq>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Geo-Coder-Navteq>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/Public/Dist/Display.html?Name=Geo-Coder-Navteq>

=item * Search CPAN

L<http://search.cpan.org/dist/Geo-Coder-Navteq/>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
