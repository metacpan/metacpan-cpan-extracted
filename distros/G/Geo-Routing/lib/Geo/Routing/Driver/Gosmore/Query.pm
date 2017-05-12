package Geo::Routing::Driver::Gosmore::Query;
BEGIN {
  $Geo::Routing::Driver::Gosmore::Query::AUTHORITY = 'cpan:AVAR';
}
BEGIN {
  $Geo::Routing::Driver::Gosmore::Query::VERSION = '0.11';
}
use Any::Moose;
use warnings FATAL => "all";

with 'Geo::Routing::Role::Query';

has fast => (
    is            => 'ro',
    isa           => 'Int',
    default       => 1,
    documentation => '',
);

has v => (
    is            => 'ro',
    isa           => 'Str',
    default       => 'motorcar',
    documentation => '',
);

sub query_string {
    my ($self) = @_;

    my %map = qw(
        from_longitude flon
        from_latitude  flat
        to_longitude   tlon
        to_latitude    tlat
    );

    my @atoms = qw(from_latitude from_longitude to_latitude to_longitude fast v);

    my $query_string = join '&', map {
        my $url_form = $map{$_} || $_;
        sprintf "%s=%s", $url_form, $self->$_;
    } grep {
        defined $self->$_;
    } @atoms;

    return $query_string;
}

1;
