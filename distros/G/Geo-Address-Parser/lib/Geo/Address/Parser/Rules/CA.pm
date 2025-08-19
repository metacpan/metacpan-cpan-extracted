package Geo::Address::Parser::Rules::CA;

use strict;
use warnings;
use Exporter 'import';
our @EXPORT_OK = qw(parse_address);

# Canadian postal code: A1A 1A1 (letters/digits with a space)
my $postal_re = qr/\b([A-Z]\d[A-Z])\s*(\d[A-Z]\d)\b/i;

# Canadian provinces (2-letter abbreviations)
my $province_re = qr/\b(AB|BC|MB|NB|NL|NS|NT|NU|ON|PE|QC|SK|YT)\b/i;

sub parse_address {
    my ($class, $text) = @_;
    return unless defined $text;

    my @parts = map { s/^\s+|\s+$//gr } split /,/, $text;

    my ($name, $road, $city, $province, $postal);

    # Check for province + postal code in last part
    if ($parts[-1] =~ /$province_re\s*$postal_re/) {
        $province = uc($1);
        $postal   = uc("$2 $3");
        pop @parts;
    }
    # If province only
    elsif ($parts[-1] =~ /^$province_re$/) {
        $province = uc($1);
        pop @parts;
    }

    $city   = pop @parts if @parts;
    $road = pop @parts if @parts;
    $name   = join(', ', @parts) if @parts;

    return {
        name     => $name,
        road   => $road,
        city     => $city,
        region   => $province,
        postcode => $postal,
    };
}

1;

__END__

=head1 NAME

Geo::Address::Parser::Rules::CA - Parsing rules for Canadian addresses

=head1 DESCRIPTION

Parses a flat Canadian address string into components: name, road, city, province, postal code.

=head1 EXPORTS

=head2 parse_address($text)

Returns a hashref with keys:

=over

=item * name

=item * road

=item * city

=item * region (province)

=item * postcode

=back

=cut
