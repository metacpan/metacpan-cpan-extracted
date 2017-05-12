package GrowthForecast::Aggregator::Callback;
use strict;
use warnings;
use utf8;
use Encode qw(encode_utf8);
use HTTP::Request::Common;

use Mouse;

has name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has description => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has section => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has code => (
    is => 'rw',
    isa => 'CodeRef',
    required => 1,
);

no Mouse;

sub run {
    my $self = shift;
    my %args = @_;

    my $service  = $args{service}  // die "Missing mandatory parameter: service";
    my $endpoint = $args{endpoint} // die "Missing mandatory parameter: endpoint";
    my $ua       = $args{ua}       // die "Missing mandatory parameter: ua";

    $endpoint =~ s!/$!!;

    my $url = "$endpoint/$service/$self->{section}/$self->{name}";

    my ($number) = $self->code->();
    my $req = POST $url, [
        number => $number,
        description => encode_utf8($self->description),
    ];
    my $res = $ua->request($req);
    return $res;
}

1;
__END__

=head1 NAME

GrwothForecast::Aggregator::Callback - Aggregate by callback

=head1 SYNOPSIS

    my $aggregator = GrowthForecast::Aggregator::Callback->new(
        service => 'blog',
        section => 'entry',
        name    => 'count',
        code => sub {
            ...
            return $n; # return the metrics value
        },
    );
    my $res = $aggregator->run(...);

=head1 DESCRIPTION

This aggregator aggregates data from RDBMS, and post it to GrowthForecast.

=head1 CONSTRUCTOR ARGUMENTS

=over 4

=item section: Str, required

Section name.

This module send request to "/api/$service/$section/$name"

=item name : Str, required

Name of the metrics.

This module send request to "/api/$service/$section/$name"

=item description: Str, required

Description of the query. The module post it as 'description' parameter.

=item code : CodeRef, required

Callback function to return metrics value.

=back

=head1 ARGUMENTS FOR 'run' METHOD

=over 4

=item service

Service name.

This module send request to "/api/$service/$section/$name"

=item endpoint

Endpoint URL, contains '/api'.

E.g. http://example.com/api/

=item ua

Instance of HTTP client. I tested on L<Furl>.

=back

