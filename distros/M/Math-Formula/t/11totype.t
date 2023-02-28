#!/usr/bin/env perl
# auto-detection of Code returns

  
use warnings;
use strict;
use utf8;

use Test::More;
use DateTime               ();
use DateTime::Duration     ();

use Math::Formula          ();
use Math::Formula::Context ();

my $timestamp = '2012-01-03T12:37:03+0410';
my $dt  = DateTime->new(year => 2012, month => 1, day => 3, hour => 12,
	minute => 37, second => 3, time_zone => '+0410');
my $duration = 'P7YT23S';
my $dur = DateTime::Duration->new(years => 7, seconds => 23);

my $expr1   = Math::Formula->new(dummy => "1");
my $context = Math::Formula::Context->new(name => 'test');

my @blessed = (
	[ $timestamp     => 'MF::DATETIME', $dt  ],
	[ $duration      => 'MF::DURATION', $dur ],
	[ test           => 'MF::FRAGMENT', $context ],
);

my @unblessed = (
	[ 42             => 'MF::INTEGER' => 42     ],
	[ 3.14           => 'MF::FLOAT'   => 3.14   ],
	[ 'true'         => 'MF::BOOLEAN' => 'true' ],
	[ '"(?^:^a.b$)"' => 'MF::REGEXP'  => qr/^a.b$/  ],
	[ $timestamp     => 'MF::DATETIME' => $timestamp ],
	[ '01:02:03'     => 'MF::TIME'    => '01:02:03' ],
	[ '01:02:03.123' => 'MF::TIME'    => '01:02:03.123' ],
	[ '2023-02-24'      => 'MF::DATE'    => '2023-02-24' ],
	[ '2023-02-25+0100' => 'MF::DATE'    => '2023-02-25+0100' ],
	[ $duration      => 'MF::DURATION'   => $duration ],
	[ '"tic"'        => 'MF::STRING'  => '"tic"' ],
	[ '"tac"'        => 'MF::STRING'  => \'tac'   ],
	[ "'toe'"        => 'MF::STRING'  => "'toe'" ],
);

foreach (@blessed, @unblessed)
{	my ($token, $type, $input) = @$_;

	my $result = $expr1->toType($input);
	ok defined $result, "result produced for $type";
	isa_ok $result, 'Math::Formula::Type', '... ';
	is ref $result, $type;

	is $result->token, $token;
}

is $expr1->toType('"qu\"te"')->value, 'qu"te', 'Difficult quotes';
is $expr1->toType('"qu\'te"')->value, "qu'te";

done_testing;
