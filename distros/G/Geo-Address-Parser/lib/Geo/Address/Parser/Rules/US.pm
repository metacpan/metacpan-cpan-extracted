package Geo::Address::Parser::Rules::US;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(parse_address);

sub parse_address {
    my ($class, $text) = @_;
    return unless defined $text;

    # Split by commas and trim whitespace
    my @parts = map { s/^\s+|\s+$//gr } split /,/, $text;

    my ($name, $street, $city, $region, $zip);

    # Try to extract region + ZIP code from last part
    if ($parts[-1] =~ /^([A-Z]{2})\s*(\d{5}(?:-\d{4})?)?$/) {
        $region = $1;
        $zip    = $2 // '';
        pop @parts;
    }

    $city   = pop @parts if @parts;
    $street = pop @parts if @parts;
    $name   = join(', ', @parts) if @parts;

    return {
        name    => $name,
        street  => $street,
        city    => $city,
        region  => $region,
        zip     => $zip,
    };
}

1;

__END__

=head1 NAME

Geo::Address::Parser::Rules::US - Parsing rules for US addresses

=head1 DESCRIPTION

Extracts name, street, city, state, and ZIP code from a flat US address string.

=head1 EXPORTS

=head2 parse_address($text)

Returns a hashref with keys:

=over

=item * name

=item * street

=item * city

=item * region

=item * zip

=back

=cut
