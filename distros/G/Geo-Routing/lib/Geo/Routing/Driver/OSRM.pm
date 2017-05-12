package Geo::Routing::Driver::OSRM;
BEGIN {
  $Geo::Routing::Driver::OSRM::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $Geo::Routing::Driver::OSRM::VERSION = '0.11';
}
use Any::Moose;
use warnings FATAL => "all";
use Any::Moose '::Util::TypeConstraints';
use Text::Trim;
use Geo::Routing::Driver::OSRM::Route;
use JSON::XS qw(decode_json);

with qw(Geo::Routing::Role::Driver);

has osrm_path => (
    is            => 'ro',
    isa           => 'Str',
    required      => 1,
    documentation => "The base URL of a HTTP with OSRM instance we can send queries to",
);

has use_curl => (
    is            => 'ro',
    isa           => 'Bool',
    default       => 1,
    documentation => "Should we shell out to curl(1) to get http content?",
);

enum OSRMQueryMethod => qw(
    json
    xml
);

has query_method => (
    is            => 'ro',
    isa           => 'OSRMQueryMethod',
    default       => 'json',
    documentation => "Should we make XML or JSON requests?",
);

sub route {
    my ($self, $query) = @_;

    my $method = $self->query_method;

    # Get the XML content
    my $query_string = $query->query_string($method);
    my $mech = $self->_mech;
    my $url = sprintf "%s%s", $self->osrm_path, $query_string;
    my $content;
    if ($self->use_curl) {
        chomp($content = qx[curl -s '$url']);
    } else {
        $mech->get($url);
        $content = $mech->content;
    }

    return unless $content;

    my $parsed;
    if ($method eq 'xml') {
        if ($content =~ m[<Document>\s*</Document>]s) {
            return;
        }

        my ($distance, $duration) = $content =~ /
            Distance: \s+ ([0-9]+) .*? m
            .*?
            ([0-9]+) \s+ minutes
        /x;

        $parsed = {
            distance     => ($distance / 1000),
            travel_time  => ($duration * 60),
            points       => [],
        };
    } elsif ($method eq 'json') {
        my $json = decode_json($content);

        return if $json->{status} eq '207';

        my $route_summary = $json->{route_summary};
        my ($distance, $duration) = @$route_summary{qw(total_distance total_time)};

        $parsed = {
            distance     => ($distance / 1000),
            travel_time  => ($duration),
            points       => $json->{route_geometry},
        };
    }

    my $route = Geo::Routing::Driver::OSRM::Route->new(%$parsed);

    return $route;
}

1;
