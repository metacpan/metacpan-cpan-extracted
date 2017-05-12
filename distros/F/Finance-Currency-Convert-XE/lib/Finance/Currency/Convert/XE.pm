package Finance::Currency::Convert::XE;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = '0.25';

#--------------------------------------------------------------------------

=head1 NAME

Finance::Currency::Convert::XE - Currency conversion module.

=head1 SYNOPSIS

  use Finance::Currency::Convert::XE;
  my $obj = Finance::Currency::Convert::XE->new()
                || die "Failed to create object\n" ;

  my $value = $obj->convert(
                    'source' => 'GBP',
                    'target' => 'EUR',
                    'value' => '123.45',
                    'format' => 'text'
            )   || die "Could not convert: " . $obj->error . "\n";

  my @currencies = $obj->currencies;

or

  use Finance::Currency::Convert::XE;
  my $obj = Finance::Currency::Convert::XE->new(
                    'source' => 'GBP',
                    'target' => 'EUR',
                    'format' => 'text'
            )   || die "Failed to create object\n" ;

  my $value = $obj->convert(
                    'value' => '123.45',
                    'format' => 'abbv'
           )   || die "Could not convert: " . $obj->error . "\n";

  $value = $obj->convert('123.45')
                || die "Could not convert: " . $obj->error . "\n";

  my @currencies = $obj->currencies;

=head1 DESCRIPTION

Currency conversion module using XE.com's Universal Currency Converter (tm)
site.

WARNING: Do not use this module for any commercial purposes, unless you have
obtain an explicit license to use the service provided by XE.com. For further
details please read the Terms and Conditions available at L<http://www.xe.com>.

=over

=item * http://www.xe.com/errors/noautoextract.htm

=back

=cut

#--------------------------------------------------------------------------

###########################################################################
#Library Modules                                                          #
###########################################################################

use WWW::Mechanize;
use HTML::TokeParser;

###########################################################################
#Constants                                                                #
###########################################################################

use constant    UCC => 'http://www.xe.com/currencyconverter';

###########################################################################
#Variables                                                                #
###########################################################################

my %currencies; # only need to load once!
my @defaults = ('source', 'target', 'format');

my $web = WWW::Mechanize->new();
$web->agent_alias( 'Mac Safari' );

#--------------------------------------------------------------------------

###########################################################################
#Interface Functions                                                      #
###########################################################################

=head1 METHODS

=over 4

=item new

Creates a new Finance::Currency::Convert::XE object. Can be supplied with
default values for source and target currency, and the format required of the
output. These can be overridden in the convert() method.

=cut

sub new {
    my ($this, @args) = @_;
    my $class = ref($this) || $this;
    my $self = {};
    bless $self, $class;
    $self->_initialize(@args);
    return $self;
}

=item currencies

Returns a plain array of the currencies available for conversion.

=cut

sub currencies {
    my $self = shift;
    return sort keys %currencies;
}

=item add_currencies

Allows the user to add currencies to the internal hash. Currencies can be added
as per the code below:

    $self->add_currencies(
                ZZZ => {text => 'An Example', symbol => '$'},
                ZZY => {text => 'Testing'} 
    );

Note that unless otherwise stated, the symbol will be set to '&#164;'. The code
used must be 3 characters in length, and a text part must be included.

=cut

sub add_currencies {
    my ($self,%hash) = @_;
    for my $code (keys %hash) {
        if($code =~ /[A-Z]{3}/i) {
            $code = uc $code;
            if($hash{$code}->{text}) {
                $currencies{$code}->{name}   = $hash{$code}->{text}   || die;
                $currencies{$code}->{symbol} = $hash{$code}->{symbol} || '&#164;';
            } else {
                $self->{error} = "User currency '$code' has no text part";
            }
        } else {
            $self->{error} = "User currency '$code' is invalid";
        }
    }
}

=item convert

Converts some currency value into another using XE.com's UCC.

An anonymous hash is used to pass parameters. Legal hash keys and values
are as follows:

  convert(
    source => $currency_from,
    target => $currency_to,
    value  => $currency_from_value,
    format => $print_format
  );

The format key is optional, and takes one of the following strings:

  'number' (returns '12.34')
  'symbol' (returns '&#163;12.34')
  'text'   (returns '12.34 Great Britain, Pound')
  'abbv'   (returns '12.34 GBP')

If format key is omitted, 'number' is assumed and the converted value
is returned.

If only a value is passed, it is assumed that this is the value to be
converted and the remaining parameters will be defined by the defaults set
in the constructor. Note that no internal defaults are assumed.

Note that not all countries have symbols in the standard character set.
Where known the appropriate currency symbol is used, otherwise the
generic currency symbol is used.

It should also be noted that there is a recommendation to use only the
standardised three letter abbreviation ('abbv' above). However, for
further reading please see:

  http://www.jhall.demon.co.uk/currency/
  http://www.jhall.demon.co.uk/currency/by_symbol.html

=cut

sub convert {
    my $self = shift;
    my %params = @_ > 1 ? @_ : (value => $_[0]);
    $params{$_} ||= $self->{$_} for(@defaults);

    undef $self->{error};
    unless( $params{source} ){
        $self->{error} = 'Source currency is blank. This parameter is required';
        return;
    }

    unless( exists($currencies{$params{source}}) ){
        $self->{error} = 'Source currency "' . $params{source} . '" is not available';
        return;
    }

    unless( $params{target} ){
        $self->{error} = 'Target currency is blank. This parameter is required';
        return;
    }

    unless( exists($currencies{$params{target}}) ){
        $self->{error} = 'Target currency "' . $params{target} . '" is not available';
        return;
    }

    # store later use
    $self->{code} = $params{target};
    $self->{name} = $currencies{$params{target}}->{name};
    $self->{symbol} = $currencies{$params{target}}->{symbol};
    $self->{string} = $self->_format($params{format});

    # This "feature" is actually useful as a pass-thru filter.
    if( $params{source} eq $params{target} ) {
        return sprintf $self->{string}, $params{value}
    }

    # get the base site
    $web->get( UCC );

    unless($web->success()) {
        $self->{error} = 'Unable to retrieve webpage';
        return;
    }

	my @forms = $web->forms();
	my $form_number = 1;
	my $found = 0;

	foreach my $form (@forms) {
		if ($form->action eq 'http://www.xe.com/currencyconverter/convert/') {
			$found = 1;
			last;
		}

		$form_number++;
	}

	if ($found) {
    # complete and submit the form
    $web->submit_form(
            form_number => $form_number,
            fields    => { 'From'   => $params{source},
                           'To'     => $params{target},
                           'Amount' => $params{value}
            }
		);
	}

    unless($found && $web->success()) {
        $self->{error} = 'Unable to retrieve webform';
        return;
    }

    # return the converted value
    return $self->_extract_text($web->content());
}

=item error

Returns a (hopefully) meaningful error string.

=cut

sub error {
    my $self = shift;
    return $self->{error};
}

###########################################################################
#Internal Functions                                                       #
###########################################################################

sub _initialize {
    my($self, %params) = @_;
    # set defaults
    $self->{$_} = $params{$_}   for(@defaults);

    return  if(keys %currencies);
    local($_);

    # Extract the mapping of currencies and their atrributes
    while(<Finance::Currency::Convert::XE::DATA>){
        s/\s*$//;
        my ($code,$text,$symbol) = split /\|/;
        $currencies{$code}->{name} = $text;
        $currencies{$code}->{symbol} = $symbol;
    }

    return;
}

# Formats the return string to the requirements of the caller
sub _format {
    my($self, $form) = @_;

    my %formats = (
        'symbol' => $self->{symbol} . '%.02f',
        'abbv'   => '%.02f ' . $self->{code},
        'text'   => '%.02f ' . $self->{name},
        'number' => '%.02f',
    );

    return $formats{$form}              if(defined $form && $formats{$form});
    return '%.02f';
}

# Extract the text from the html we get back from UCC and return
# it (keying on the fact that what we want is in the table after
# the faq link).
sub _extract_text {
    my($self, $html) = @_;
    my $tag;
    my $p = HTML::TokeParser->new(\$html);

    # first look for the 'td' element
    while (1) {
        return unless ($tag = $p->get_tag('td'));
        next unless (defined($tag->[1]{'align'}) && ($tag->[1]{'align'} eq 'left'));
        # this will probably be the value
        my $value = $p->get_trimmed_text;

        # then make sure this has the 'span' with the target
        # currency code
        my $tag2 = $p->get_tag('span');
        my $cd = $p->get_trimmed_text;
        if (defined($tag2) && defined($tag2->[1]{'class'} && $tag2->[1]{class} eq 'uccResCde'
)) {
            if ($cd eq $self->{code}) {
                # found it, return
                $value =~ s/,//g;
                return sprintf $self->{string}, $value;
            }
        }
    }

    # didn't find anything
    return;
}

1;

#--------------------------------------------------------------------------

=back

=head1 TERMS OF USE

XE.com have a Terms of Use policy that states:

  This website is for informational purposes only and is not intended to
  provide specific commercial, financial, investment, accounting, tax, or
  legal advice. It is provided to you solely for your own personal,
  non-commercial use and not for purposes of resale, distribution, public
  display or performance, or any other uses by you in any form or manner
  whatsoever. Unless otherwise indicated on this website, you may display,
  download, archive, and print a single copy of any information on this
  website, or otherwise distributed from XE.com, for such personal,
  non-commercial use, provided it is done pursuant to the User Conduct and
  Obligations set forth herein.

As such this software is for personal use ONLY. No liability is accepted by
the author for abuse or miuse of the software herein. Use of this software
is only permitted under the terms stipulated by XE.com.

The full legal document is available at L<http://www.xe.com/legal/>

=head1 TODO

Currency symbols are currently specified with a generic symbol, if the
currency symbol is unknown. Are there any other symbols available in
Unicode? Let me know if there are.

=head1 SEE ALSO

L<HTML::TokeParser>, 
L<WWW::Mechanize>

=head1 SUPPORT

There are no known bugs at the time of this release. However, if you spot a
bug or are experiencing difficulties that are not explained within the POD
documentation, please submit a bug to the RT system (see link below). However,
it would help greatly if you are able to pinpoint problems or even supply a
patch.

Fixes are dependant upon their severity and my availablity. Should a fix not
be forthcoming, please feel free to (politely) remind me by sending an email
to barbie@cpan.org .

RT: L<http://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Currency-Convert-XE>

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT

  Copyright © 2002-2011 Barbie for Miss Barbell Productions.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic Licence v2.

=cut

#--------------------------------------------------------------------------

__DATA__
AED|United Arab Emirates, Dirham|&#164;
AFN|Afghan Afghani|&#164;
ALL|Albanian Lek|&#164;
AMD|Armenian Dram|&#164;
ANG|Netherlands Antilles Guilder|&#164;
AOA|Angolan Kwanza|&#164;
ARS|Argentine Peso|&#164;
AUD|Australian Dollar|$
AWG|Aruban or Dutch Guilder|&#164;
AZN|Azerbaijani New Manat|&#164;
BAM|Bosnian Convertible Marka|&#164;
BBD|Barbadian or Bajan Dollar|&#164;
BDT|Bangladeshi Taka|&#164;
BGN|Bulgarian Lev|&#164;
BHD|Bahraini Dinar|&#164;
BIF|Burundian Franc|&#164;
BMD|Bermudian Dollar|&#164;
BND|Bruneian Dollar|&#164;
BOB|Bolivian Boliviano|&#164;
BRL|Brazilian Real|&#164;
BSD|Bahamian Dollar|&#164;
BTN|Bhutanese Ngultrum|&#164;
BWP|Botswana Pula|&#164;
BYR|Belarusian Ruble|&#164;
BZD|Belizean Dollar|&#164;
CAD|Canadian Dollar|$
CDF|Congolese Franc|&#164;
CHF|Switzerland, Franc|&#164;
CLP|Chilean Peso|&#164;
CNY|Chinese Yuan Renminbi|&#164;
COP|Colombian Peso|&#164;
CRC|Costa Rican Colon|&#164;
CUC|Cuban Convertible Peso|&#164;
CUP|Cuban Peso|&#164;
CVE|Cape Verdean Escudo|&#164;
CZK|Czech Koruna|&#164;
DJF|Djiboutian Franc|&#164;
DKK|Danish Krone|&#164;
DOP|Dominican Peso|&#164;
DZD|Algerian Dinar|&#164;
EEK|Estonia, Kroon|&#164;
EGP|Egyptian Pound|&#164;
ERN|Eritrean Nakfa|&#164;
ETB|Ethiopian Birr|&#164;
EUR|Euro|&#8364;
FJD|Fijian Dollar|&#164;
FKP|Falkland Island Pound|&#164;
GBP|Great Britain, Pound|&#163;
GEL|Georgian Lari|&#164;
GGP|Guernsey Pound|&#164;
GHS|Ghanaian Cedi|&#164;
GIP|Gibraltar Pound|&#164;
GMD|Gambian Dalasi|&#164;
GNF|Guinean Franc|&#164;
GTQ|Guatemalan Quetzal|&#164;
GYD|Guyanese Dollar|&#164;
HKD|Hong Kong Dollar|&#164;
HNL|Honduran Lempira|&#164;
HRK|Croatian Kuna|&#164;
HTG|Haitian Gourde|&#164;
HUF|Hungarian Forint|&#164;
IDR|Indonesian Rupiah|&#164;
ILS|Israeli Shekel|&#8362;
IMP|Isle of Man Pound|&#164;
INR|Indian Rupee|&#8360;
IQD|Iraqi Dinar|&#164;
IRR|Iranian Rial|&#164;
ISK|Icelandic Krona|&#164;
JEP|Jersey Pound|&#164;
JMD|Jamaican Dollar|&#164;
JOD|Jordanian Dinar|&#164;
JPY|Japanese Yen|&#165;
KES|Kenyan Shilling|&#164;
KGS|Kyrgyzstan, Som|&#164;
KHR|Cambodian Riel|&#164;
KMF|Comoran Franc|&#164;
KPW|North Korea, Won|&#164;
KRW|South Korea, Won|&#8361;
KWD|Kuwait, Dinar|&#164;
KYD|Caymanian Dollar|&#164;
KZT|Kazakhstani Tenge|&#164;
LAK|Laos, Kip|&#164;
LBP|Lebanon, Pound|&#164;
LKR|Sri Lanka, Rupee|&#164;
LRD|Liberia, Dollar|&#164;
LSL|Lesotho, Loti|&#164;
LTL|Lithuania, Litas|&#164;
LVL|Latvia, Lat|&#164;
LYD|Libya, Dinar|&#164;
MAD|Morocco, Dirham|&#164;
MDL|Moldova, Leu|&#164;
MGA|Madagascar, Ariary|&#164;
MKD|Macedonia, Denar|&#164;
MNT|Mongolia, Tughrik|&#164;
MOP|Macau, Pataca|&#164;
MRO|Mauritania, Ouguiya|&#164;
MUR|Mauritius, Rupee|&#164;
MVR|Maldives, Rufiyaa|&#164;
MWK|Malawi, Kwacha|&#164;
MXN|Mexico, Peso|&#164;
MYR|Malaysia, Ringgit|&#164;
MZN|Mozambique, Metical|&#164;
NAD|Namibia, Dollar|&#164;
NGN|Nigeria, Naira|&#164;
NIO|Nicaragua, Cordoba|&#164;
NOK|Norway, Krone|&#164;
NPR|Nepal, Rupee|&#164;
NZD|New Zealand, Dollar|&#164;
OMR|Oman, Rial|&#164;
PAB|Panama, Balboa|&#164;
PEN|Peru, Nuevo Sol|&#164;
PGK|Papua New Guinea, Kina|&#164;
PHP|Philippines, Peso|&#164;
PKR|Pakistan, Rupee|&#8360;
PLN|Poland, Zloty|&#164;
PYG|Paraguay, Guarani|&#164;
QAR|Qatar, Riyal|&#164;
RON|Romania, New Leu|&#164;
RSD|Serbia, Dinar|&#164;
RUB|Russia, Ruble|&#164;
RWF|Rwanda, Franc|&#164;
SAR|Saudi Arabia, Riyal|&#164;
SBD|Solomon Islands, Dollar|&#164;
SCR|Seychelles, Rupee|&#164;
SDG|Sudan, Pound|&#164;
SEK|Sweden, Krona|&#164;
SGD|Singapore, Dollar|&#164;
SHP|Saint Helena, Pound|&#164;
SKK|Slovakia, Koruna|&#164;
SLL|Sierra Leone, Leone|&#164;
SOS|Somalia, Shilling|&#164;
SPL|Seborga, Luigino|&#164;
SRD|Suriname, Dollar|&#164;
STD|São Tome and Principe, Dobra|&#164;
SVC|Salvadoran Colon|&#164;
SYP|Syria, Pound|&#164;
SZL|Swaziland, Lilangeni|&#164;
THB|Thailand, Baht|&#3647;
TJS|Tajikistan, Somoni|&#164;
TMM|Turkmenistan, Manat|&#164;
TND|Tunisia, Dinar|&#164;
TOP|Tonga, Pa'anga|&#164;
TRY|Turkey, New Lira|&#164;
TTD|Trinidad and Tobago, Dollar|&#164;
TVD|Tuvalu, Dollar|&#164;
TWD|Taiwan, New Dollar|&#164;
TZS|Tanzania, Shilling|&#164;
UAH|Ukraine, Hryvna|&#164;
UGX|Uganda, Shilling|&#164;
USD|United States, Dollar|$
UYU|Uruguay, Peso|&#164;
UZS|Uzbekistan, Som|&#164;
VEF|Venezuela, Bolivar Fuerte|&#164;
VND|Vietnam, Dong|&#164;
VUV|Vanuatu, Vatu|&#164;
XAF|Central African CFA Franc BEAC|&#164;
XAG|Silver Ounce|&#164;
XAU|Gold Ounce|&#164;
XBT|Bitcoin|&#164;
XCD|East Caribbean Dollar|&#164;
XDR|IMF Special Drawing Rights|&#164;
XOF|CFA Franc|&#164;
XPD|Palladium Ounce|&#164;
XPF|CFP Franc|&#164;
XPT|Platinum Ounce|&#164;
YER|Yemen, Rial|&#164;
ZAR|South Africa, Rand|&#164;
ZMK|Zambia, Kwacha|&#164;
ZWD|Zimbabwe, Dollar|&#164;
