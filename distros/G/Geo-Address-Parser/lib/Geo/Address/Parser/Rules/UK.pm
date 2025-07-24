package Geo::Address::Parser::Rules::UK;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(parse_address);

# UK postcode pattern: e.g. SW1A 1AA
my $postcode_re = qr/\b([A-Z]{1,2}\d{1,2}[A-Z]?)\s*(\d[A-Z]{2})\b/i;

sub parse_address {
    my ($class, $text) = @_;
    return unless defined $text;

    my @parts = map { s/^\s+|\s+$//gr } split /,/, $text;

    my ($name, $street, $town, $postcode);

    # Look for postcode in the last part
    if ($parts[-1] =~ /$postcode_re/) {
        $postcode = uc("$1 $2");
        pop @parts;
    }

    $town   = pop @parts if @parts;
    $street = pop @parts if @parts;
    $name   = join(', ', @parts) if @parts;

    return {
        name     => $name,
        street   => $street,
        city     => $town,
        postcode => $postcode,
    };
}

1;

__END__

=head1 NAME

Geo::Address::Parser::Rules::UK - Parsing rules for UK addresses

=head1 DESCRIPTION

Parses a flat UK address string into components: name, street, city, and postcode.

=head1 EXPORTS

=head2 parse_address($text)

Returns a hashref with keys:

=over

=item * name

=item * street

=item * city

=item * postcode

=back

=cut
