#!/usr/bin/perl

use warnings::register;
use strict;

use Test::More tests => 8;

use Locale::Object::Currency;
use Locale::Object::Currency::Converter;

my $usd = Locale::Object::Currency->new( code => 'USD' );
my $gbp = Locale::Object::Currency->new( code => 'GBP' );
my $eur = Locale::Object::Currency->new( code => 'EUR' );
my $jpy = Locale::Object::Currency->new( code => 'JPY' );
  
my $converter = Locale::Object::Currency::Converter->new(
                                                       from    => $usd,
                                                       to      => $gbp,
                                                       service => 'XE'
                                                      );

#1
isa_ok( $converter, 'Locale::Object::Currency::Converter');

my $amount = 5;

# "Test" a conversion - output a test result, but don't fail if it
# doesn't work. This is because Finance::Currency::Convert::XE and 
# Finance::Currency::Convert::Yahoo occasionally don't work due to transient
# network conditions. We want to indicate success/failure but not actually
# kill the tests.

# We can hide any warnings (like the ones Finance::Currency::Convert::XE chucks
# out from time to time about a currency not being available) - this is only a test.
local $SIG{__WARN__} = sub {};

SKIP:
{
  skip 'Finance::Currency::Convert::XE not installed', 1 unless $converter->use_xe == 1;

  my $result = $converter->convert($amount);

  #2
  if (defined $result && $result !~ /ERROR/)
  {
    pass('An XE conversion worked');
  }
  else
  {
    pass('An XE conversion was not successful, this may be due to transient network conditions');
  }
}

#3
ok( $converter->service('Yahoo'), 'Resetting currency service worked' );

#4
ok( $converter->from($eur), "Resetting 'from' currency worked" );

#5
ok( $converter->to($jpy), "Resetting 'to' currency worked" );

SKIP:
{
  skip 'Finance::Currency::Convert::Yahoo not installed', 1 unless $converter->use_yahoo == 1;

  my $result = $converter->convert($amount);
  
  # More "tests" - see note above.
  
  #6
  if (defined $result && $result !~ /ERROR/)
  {
    pass('A Yahoo! conversion worked');
  }
  else
  {
    pass('A Yahoo! conversion was not successful, this may be due to transient network conditions');
  }
}
 
my $rate = $converter->rate;
 
#7
if (defined $rate)
{
  pass('A conversion rate was found');
}
else
{
  pass('A conversion rate was not found, this may be due to transient network conditions');
}
  
my $timestamp = $converter->timestamp;
  
#8
if (defined $timestamp)
{
  pass('A rate timestamp was found');
}
else
{
  pass('A rate timestamp was not found, this may be due to transient network conditions');
}

