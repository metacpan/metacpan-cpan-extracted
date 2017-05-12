package Finance::Currency::Convert::BChile;

use warnings;
use strict;

use Carp;

=head1 NAME

Finance::Currency::Convert::BChile - Currency conversion module
between Chilean Pesos (CLP) and USA Dollars (USD).

=head1 VERSION

Version 0.05

=cut

$Finance::Currency::Convert::BChile::VERSION = '0.05';

use LWP::UserAgent;
use HTML::TokeParser;

# As of 2013-07-24, bcentral.cl uses an iframe in homepage and
# feeds values from another URL
my $BCENTRAL_URL = 'http://si3.bcentral.cl/indicadoresvalores/secure/indicadoresvalores.aspx';
my $DEFAULT_UA   = 'Finance::Currency::Convert::BChile perl module';

=head1 SYNOPSIS

Currency conversion module between Chilean Pesos (CLP) and USA
Dollars (USD). The conversion rate is obtained from the official
source in Chile: the central bank "Banco Central de Chile", from
their webpage http://www.bcentral.cl

    use Finance::Currency::Convert::BChile;

    my $conversor = Finance::Currency::Convert::BChile->new();
    $conversor->update;
    print $conversor->CLP2USD(20170);

=head1 FUNCTIONS

=head2 new

Creates a new Finance::Currency::Convert::BChile object.
Initializes the web robot. You can pass a user agent string
as a parameter.

=cut

sub new {
	my ($this, @args) = @_;

	my $class = ref($this) || $this;

	my $ua_string = $args[0] || $DEFAULT_UA;

	my $self = {};
	bless $self, $class;

	$self->{'ua'} = LWP::UserAgent->new
		or croak "Unable to create user agent";
	$self->{'ua'}->agent($ua_string);

	$self->{'dolar'} = '';
	$self->{'fecha'} = '';

	return $self;
}

=head2 update

Obtains the data from bcentral page.
You can pass a fake value as a parameter. In this case there's no
update from bcentral site.

=cut

sub update {
	my $self     = shift;
	my $simulate = shift;

	if ($simulate) {
		$self->{'dolar'} = $simulate;
		$self->{'fecha'} = 'UNKNOWN';

		return 1;
	}

	my $response = $self->{'ua'}->get($BCENTRAL_URL);

	unless ($response->is_success) {
		carp "Unable to get page: " . $response->status_line;

		$self->{'dolar'} = '';
		$self->{'fecha'} = '';
		return 0;
	}

	my $p = HTML::TokeParser->new(\$response->content)
		or croak "Unable to parse response: $!";

	my ($dolar, $fecha);

    while (my $token = $p->get_tag("div")) {
        next unless $token->[1]{id} eq 'ind-dia';

        while (my $token2 = $p->get_tag("p")) {
            next unless $token2->[1]{class} eq 'published-date';
            last;
        }
        while (my $token2 = $p->get_tag("span")) {
            next unless $token2->[1]{id} eq 'Lbl_fecha';
            last;
        }
        $fecha = $p->get_text;

        while (my $token2 = $p->get_tag("span")) {
            next unless $token2->[1]{id} eq 'RptListado_ctl03_lbl_valo';
            $dolar = $p->get_text;
            last;
        }
    }

	return 0 unless $dolar and $fecha;
    return 0 unless $dolar =~ /^\d+[,.]{0,1}\d+$/;

	$self->{'dolar'} = $dolar;
	$self->{'fecha'} = $fecha;

	return 1;
}

=head2 date

Return the date obtained from Banco Central's site.
There's no formatting at all.

=cut

sub date {
	my $self = shift;

	return $self->{'fecha'};
}

=head2 dollarValue

Return the value of 1 dollar in CLP.
There's no formatting.

=cut

sub dollarValue {
	my $self = shift;

	return $self->{'dolar'};
}

=head2 rate

Return the rate of transforming CLP in USD.
If there's no value data, return -1

=cut

sub rate {
	my $self = shift;

	my $valor = $self->{'dolar'};

	# Changing decimal separator
	$valor =~ s/,/./;

    return -1 unless $valor;
    return -1 unless $valor =~ /^\d+[,.]{0,1}\d+$/;

	return -1 unless $valor >= 0;

	return 1 / $valor;
}

=head2 CLP2USD

Convert the amount received as parameter (CLP) to USD,
rounded at two decimals.
Returns -1 on error.

=cut

sub CLP2USD {
	my $self  = shift;
	my $pesos = shift;

	if ($pesos !~ /^\d+$/) {
		carp "Argument to CLP2USD must be an integer";
		return -1;
	}

	my $rate = $self->rate;
	return -1 unless $rate >= 0;

	return sprintf("%.2f", $pesos * $rate);
}

=head2 USD2CLP

Convert the amount received as parameter (USD) to CLP,
rounded as integer (no decimals).
Returns -1 on error.

=cut

sub USD2CLP {
	my $self    = shift;
	my $dolares = shift;

	if ($dolares !~ /^\d+(\.\d{0,2}){0,1}$/) {
		carp "Wrong format in argument to USD2CLP";
		return -1;
	}

	my $valor = $self->{'dolar'};

	# Changing decimal separator
	$valor =~ s/,/./;

	return -1 unless $valor >= 0;

	return sprintf("%.0f", $dolares * $valor);
}

=head1 AUTHOR

Hugo Salgado, C<< <hsalgado at vulcano.cl> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-currency-convert-bchile at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-Currency-Convert-BChile>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::Currency::Convert::BChile


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-Currency-Convert-BChile>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-Currency-Convert-BChile>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-Currency-Convert-BChile>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-Currency-Convert-BChile>

=back

=head1 SEE ALSO

  HTML::TokeParser
  LWP::UserAgent

=cut

=head1 TERMS OF USE

The data obtained from bcentral site is under this policy:
  http://www.bcentral.cl/sitio/condiciones-uso.htm

No liability is accepted by the author for abuse or miuse of
the software herein. Use of this software is only permitted under
the terms stipulated by bcentral.cl.

=cut

=head1 ACKNOWLEDGEMENTS

This module was built for NIC Chile (http://www.nic.cl), who
granted its liberation as free software.

=head1 COPYRIGHT & LICENSE

Copyright 2007 Hugo Salgado, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Finance::Currency::Convert::BChile
