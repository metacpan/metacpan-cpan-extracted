package Language::Farnsworth::Units::Currency;

use strict;
use warnings;

use Data::Dumper;

use Language::Farnsworth::Value;
use Language::Farnsworth::Value::Pari;
use Language::Farnsworth::Units;
use Language::Farnsworth::Error;


use Finance::Currency::Convert::XE;

{#this is a REALLY BAD THING TO DO BUT I DON'T WANT NO ROUNDING AT THIS LEVEL
	no warnings;
	package Finance::Currency::Convert::XE;

	sub _format
	{
		return "%f";
	}
}

#note that this is fairly C<en-US> centric!

my $defaultcurrency = "USD";

my $obj = Finance::Currency::Convert::XE->new(target => $defaultcurrency)
                || die "Failed to create object\n" ;

my @currencies = $obj->currencies; #go get a list of symbols

#this is a quick and dirty list of proper names and symbols for defining them below
my %symbols = (Afghanis=>'AFN',Baht=>'THB',Balboa=>'PAB',Bolivares_Fuertes=>'VEF',Bolivianos=>'BOB',Cedis=>'GHC', Colon=>'CRC',Colones=>'SVC',
	Convertible_Marka=>'BAM',Cordobas=>'NIO',Denars=>'MKD',Dinars=>'RSD',Dollars=>'USD',Dong=>'VND',Euro=>'EUR',Forint=>'HUF',Francs=>'CHF',Guarani=>'PYG',
	Guilders=>'ANG',Hryvnia=>'UAH',Kips=>'LAK',Koruny=>'CZK',Krone=>'NOK',Kroner=>'DKK',Kronor=>'SEK',Kronur=>'ISK',Krooni=>'EEK',Kuna=>'HRK',Lati=>'LVL',
	Leke=>'ALL',Lempiras=>'HNL',Leva=>'BGN',Liras=>'TRL',Lira=>'TRY',Litai=>'LTL',Meticais=>'MZN',Nairas=>'NGN',New_Dollars=>'TWD',New_Lei=>'RON',
	New_Manats=>'AZN',New_Shekels=>'ILS',Pesos=>'MXN',Pounds=>'GBP',Pulas=>'BWP',Quetzales=>'GTQ',Rand=>'ZAR',Reais=>'BRL',Ringgits=>'MYR',Riyals=>'SAR',
	Rubles=>'BYR',Rubles=>'RUB',Rupees=>'INR',Rupiahs=>'IDR',Shillings=>'SOS',Soms=>'KGS',Sums=>'UZS',Switzerland_Francs=>'CHF',Tenge=>'KZT',Tugriks=>'MNT',
	Won=>'KRW',Yen=>'JPY',Yuan_Renminbi=>'CNY',Zimbabwe_Dollars=>'ZWD',Zlotych=>'PLN');

sub init
{
	my $env = shift;
	#doupdate([],$env,[]); #ignore this for now

	$env->{funcs}->addfunc("updatecurrencies", [[undef, undef, undef, 0]], \&doupdate, $env);
}

sub doupdate
{
	my ($args, $env, $branches)= @_;
    
	my $lock = $Language::Farnsworth::Units::lock;
	$Language::Farnsworth::Units::lock = 0;

	for my $x (@currencies)
	{
		print "Fetching currency $x\n";
		my $currentval = $obj->convert(
                    'value' => '1.00',
                    'source' => $x,
					'format' => 'number'
           )   || die "Could not convert: " . $obj->error . "\n";
		$env->eval("$x := $currentval dollars;");
	}

	for my $name (keys %symbols)
	{
		print "Setting up $name\n";
		eval {$env->eval("$name := ".$symbols{$name});};
		if ($@)
		{
			warn $@ if ("".$@ =~ "Undefined symbol"); #ignore ones that aren't there anymore, dunno WHY that happens though, i blame XE
			die $@ if ("".$@ !~ "Undefined symbol"); #ignore ones that aren't there anymore, dunno WHY that happens though, i blame XE
		}
	}

	$Language::Farnsworth::Units::lock = $lock;

	return undef;
}

1;

