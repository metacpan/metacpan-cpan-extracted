#!/usr/bin/perl
use strict;

use lib 't';

use Test::More tests => 37;
use Finance::Currency::Convert::XE;

###########################################################

my $CHECK_DOMAIN    = 'www.xe.com';

my %format_tests = (
	'GBP' => {	'text'		=> qr/\d+\.\d+ Great Britain, Pound/,
				'symbol'	=> qr/&#163;\d+\.\d+/,
				'abbv'		=> qr/\d+\.\d+ GBP/ },
	'EUR' => {	'text'		=> qr/\d+\.\d+ Euro/,
				'symbol'	=> qr/&#8364;\d+\.\d+/,
				'abbv'		=> qr/\d+\.\d+ EUR/ },
	'ZMK' => {	'text'		=> qr/\d+\.\d+ Zambia, Kwacha/,
				'symbol'	=> qr/&#164;\d+\.\d+/,
				'abbv'		=> qr/\d+\.\d+ ZMK/ },
);

# offset hopefully allows for a large degree fluctuation
my ($start,$final,$offset) = ('10000.00',12500,10000); # mostly given up on getting the offset right
my ($value,$error);

###########################################################

SKIP: {
	skip "Can't see a network connection", 22   if(pingtest($CHECK_DOMAIN));

	my $obj = Finance::Currency::Convert::XE->new();
	isa_ok($obj,'Finance::Currency::Convert::XE','... got the object');

	my @currencies = $obj->currencies;

	is(scalar(@currencies),169,'... correct number of currencies');
	is($currencies[0],  'AED','... valid currency: first');
	is($currencies[47], 'GBP','... valid currency: GBP');
	is($currencies[168],'ZWD','... valid currency: last');

	$value = $obj->convert(
                  'source' => 'GBP',
                  'target' => 'EUR',
                  'value'  => $start,
                  'format' => 'number');

    $error = $obj->error;
    SKIP: {
        skip $error, 3  if(!$value && $error =~ /Unable to retrieve/);

        # have to account for currency fluctuations
        #cmp_ok($value, ">", ($final - $offset),'... conversion above lower limit');
        #cmp_ok($value, "<", ($final + $offset),'... conversion above upper limit');
        like($value,qr/^\d+\.\d+$/,'... conversion matches a number');
    }

	$value = $obj->convert(
                  'source' => 'GBP',
                  'target' => 'EUR',
                  'value'  => $start,
                  'format' => 'text');

    $error = $obj->error;
    SKIP: {
        skip $error, 1  if(!$value && $error =~ /Unable to retrieve/);

    	like($value,qr/\d+\.\d+ Euro/,'... conversion matches a text pattern');
    }

	$value = $obj->convert(
                  'source' => 'GBP',
                  'target' => 'EUR',
                  'value'  => $start);
    $error = $obj->error;
    SKIP: {
        skip $error, 3  if(!$value && $error =~ /Unable to retrieve/);

        # have to account for currency fluctuations
        #cmp_ok($value, ">", ($final - $offset),'... default format conversion above lower limit');
        #cmp_ok($value, "<", ($final + $offset),'... default format conversion above upper limit');
        like($value,qr/^\d+\.\d+$/,'... default format conversion matches a number');
    }

	$value = $obj->convert(
                  'source' => 'GBP',
                  'target' => 'GBP',
                  'value'  => $start);
   	is($value,$start,'... no conversion, should be the same');

	foreach my $curr (keys %format_tests) {
		foreach my $form (keys %{$format_tests{$curr}}) {
			$value = $obj->convert(
						  'source' => $curr,
						  'target' => $curr,
						  'value'  => $start,
						  'format' => $form);
            $error = $obj->error;
            SKIP: {
                skip $error, 1  if(!$value && $error =~ /Unable to retrieve/);

    			like($value,$format_tests{$curr}->{$form},"... format test: $curr/$form");
            }
		}
	}
}

SKIP: {
	skip "Can't see a network connection", 4    if(pingtest($CHECK_DOMAIN));

	my $obj = Finance::Currency::Convert::XE->new(
                  'source' => 'GBP',
                  'target' => 'EUR',
                  'format' => 'bogus');
	isa_ok($obj,'Finance::Currency::Convert::XE','... got the object');

	$value = $obj->convert($start);
    $error = $obj->error;
    SKIP: {
        skip $error, 3  if(!$value && $error =~ /Unable to retrieve/);

        # have to account for currency fluctuations
        #cmp_ok($value, ">", ($final - $offset),'... defaults conversion above lower limit');
        #cmp_ok($value, "<", ($final + $offset),'... defaults conversion above upper limit');
        like($value,qr/^\d+\.\d+$/,'... defaults conversion matches a number');
    }
}

SKIP: {
	skip "Can't see a network connection", 2    if(pingtest($CHECK_DOMAIN));

	my $obj = Finance::Currency::Convert::XE->new(
                  'source' => 'GBP',
                  'target' => 'ARS',
                  'format' => 'number');
	isa_ok($obj,'Finance::Currency::Convert::XE','... got the object');

	$value = $obj->convert($start);
    $error = $obj->error;
    SKIP: {
        skip $error, 1  if(!$value && $error =~ /Unable to retrieve/);

        # Apparently ARS has been causing problems
        like($value,qr/^\d+\.\d+$/,'... defaults conversion matches a number');
    }
}

SKIP: {
	skip "Can't see a network connection", 8    if(pingtest($CHECK_DOMAIN));

	my $obj = Finance::Currency::Convert::XE->new();

    $value = $obj->convert($start);
    is( $value, undef, '... blank source');
    like( $obj->error, qr/Source currency is blank/, '... blank source (error method)');

    $value = $obj->convert(value => $start, source => 'GBP');
    is( $value, undef, '... blank target');
    like( $obj->error, qr/Target currency is blank/, '... blank target (error method)');

    $value = $obj->convert(value => $start, source => 'bogus');
    is( $value, undef, '... bogus source');
    like( $obj->error, qr/is not available/, '... bogus source (error method)');

    $value = $obj->convert(value => $start, source => 'GBP', target => 'bogus');
    is( $value, undef, '... bogus target');
    like( $obj->error, qr/is not available/, '... bogus target (error method)');
}

###########################################################

SKIP: {
	skip "Can't see a network connection", 7    if(pingtest($CHECK_DOMAIN));

	my $obj = Finance::Currency::Convert::XE->new();
	isa_ok($obj,'Finance::Currency::Convert::XE','... got the object');

	my @currencies = $obj->currencies;
	is(scalar(@currencies),169,'... correct number of currencies');

    $obj->add_currencies(
                    ZZZ => {text => 'An Example', symbol => '$'},
                    ZZY => {text => 'Testing'} );
	@currencies = $obj->currencies;
	is(scalar(@currencies),171,'... correct number of currencies');

	is($currencies[169],'ZZY','... valid currency: new penultimate');
	is($currencies[170],'ZZZ','... valid currency: new last');

	my $value = $obj->convert(
			  'source' => 'ZZY',
			  'target' => 'ZZY',
			  'value'  => 5,
			  'format' => 'symbol');
    is($value,'&#164;5.00');

    $value = $obj->convert(
			  'source' => 'ZZY',
			  'target' => 'ZZY',
			  'value'  => 5,
			  'format' => 'text');
    is($value,'5.00 Testing');
}

###########################################################

# crude, but it'll hopefully do ;)
sub pingtest {
    my $domain = shift or return 0;
    my $cmd =   $^O =~ /solaris/i                           ? "ping -s $domain 56 1" :
                $^O =~ /dos|os2|mswin32|netware|cygwin/i    ? "ping -n 1 $domain "
                                                            : "ping -c 1 $domain >/dev/null 2>&1";

    eval { system($cmd) }; 
    if($@) {                # can't find ping, or wrong arguments?
        diag();
        return 1;
    }

    my $retcode = $? >> 8;  # ping returns 1 if unable to connect
    return $retcode;
}
