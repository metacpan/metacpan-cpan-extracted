package Finance::RawMaterialPrice;

use strict;
use warnings;
use autodie;
use utf8;
use Carp qw( croak );
use LWP::Simple qw(get);

our $VERSION     = '0.02';
our @EXPORT      = qw(get_gold_price get_silver_price);
our @EXPORT_OK   = qw(get_raw_material_price);
our %EXPORT_TAGS = ( all => [ @EXPORT, @EXPORT_OK ] );
use base qw(Exporter);
my $base_url = 'http://www.finanzen.net/rohstoffe';

sub get_raw_material_price {
    my $url = shift;
    for ( split /\n/, get($url) ) {
        next unless m#<td>(\d+?),(\d{2}) (?:USD|EUR) je 1 kg (?:Gold|Silber)</td>#ms;
        my $price = "$1$2";
        return $price / 100000;
    }

}

sub get_gold_price {
    my $unit = shift || 'euro';
    unless ( $unit eq 'euro' or $unit eq 'dollar' ) {
        croak "Either use 'euro' or 'dollar'";
    }
    return get_raw_material_price("$base_url/goldpreis/$unit");
}

sub get_silver_price {
    my $unit = shift || 'euro';
    unless ( $unit eq 'euro' or $unit eq 'dollar' ) {
        croak "Either use 'euro' or 'dollar'";
    }
    return get_raw_material_price("$base_url/silberpreis/$unit");
}

__END__

=head1 NAME

Finance::RawMaterialPrice - To get the current gold and silver price

=head1 SYNOPSIS

  use Finance::RawMaterialPrice;
  my $gold_EUR_per_gram   = get_gold_price('dollar');
  my $silver_EUR_per_gram = get_silver_price('euro');

=head1 DESCRIPTION

This module provides the function get_gold_price to get the current price for
one gram gold. It also provides the function get_silver_price to do the
equivalent for the silver price. It parses http://www.finanzen.net to get this
prices.

For each function call you can specify the money unit you would like to get. I
only implemented 'dollar' or 'euro'. If you omit this parameter then the price
will be return in Euro.

=head2 EXPORT

get_gold_price
get_silver_price

=head1 SEE ALSO

LBMA::Statistics

=head1 AUTHOR

sdrfnord <sdrfnord@gmx.de>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012-2013 by sdrfnord

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
