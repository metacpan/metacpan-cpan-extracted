#!perl -T

use strict;
use warnings;
use utf8;

use Lingua::TH::Numbers;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 60;


# Change all the Test::More pipes to output utf8, to prevent
# "Wide character in print" warnings. This is only available for Perl 5.8+
# however due to the reliance on PerlIO, so earlier versions will fail with
# "Unknown discipline ':utf8'".
if ( $] > 5.008 )
{
	my $builder = Test::More->builder();
	binmode( $builder->output(), ":utf8" );
	binmode( $builder->failure_output(), ":utf8" );
	binmode( $builder->todo_output(), ":utf8" );
}


foreach my $line ( <DATA> )
{
	chomp( $line );
	next unless defined( $line ) && $line ne '';
	next if substr( $line, 0, 1 ) eq '#';

	my ( $input, $style, $thai, $rgts ) = split( /\t/, $line );
	my $informal = defined( $style ) && $style eq 'Informal' ? 1 : 0;

	my $number = Lingua::TH::Numbers->new( $input );

	is(
		$number->spell(
			output_mode => 'thai',
			informal    => $informal,
		),
		$thai,
		"Spell $input (Thai script, $style).",
	);

	is(
		$number->spell(
			output_mode => 'rtgs',
			informal    => $informal,
		),
		$rgts,
		"Spell $input (RTGS, $style).",
	);
}


__DATA__
# Number	Formal/Informal	Thai	RTGS
0	Formal	ศูนย์	sun
1	Formal	หนึ่ง	nueng
2	Formal	สอง	song
3	Formal	สาม	sam
4	Formal	สี่	si
5	Formal	ห้า	ha
6	Formal	หก	hok
7	Formal	เจ็ด	chet
8	Formal	แปด	paet
9	Formal	เก้า	kao
10	Formal	สิบ	sip
11	Formal	สิบเอ็ด	sip et
12	Formal	สิบสอง	sip song
20	Formal	ยี่สิบ	yi sip
21	Formal	ยี่สิบเอ็ด	yi sip et
22	Formal	ยี่สิบสอง	yi sip song
100	Formal	หนึ่งร้อย	nueng roi
100	Informal	ร้อย	roi
1000	Formal	หนึ่งพัน	nueng phan
1000	Informal	พัน	phan
10000	Formal	หนึ่งหมื่น	nueng muen
10000	Informal	หมื่น	muen
12345	Formal	หนึ่งหมื่นสองพันสามร้อยสี่สิบห้า	nueng muen song phan sam roi si sip ha
12345	Informal	หมื่นสองพันสามร้อยสี่สิบห้า	muen song phan sam roi si sip ha
100000	Formal	หนึ่งแสน	nueng saen
100000	Informal	แสน	saen
1000000	Formal	หนึ่งล้าน	nueng lan
1000000	Informal	ล้าน	lan
1000000000000	Formal	หนึ่งล้านล้าน	nueng lan lan
1000000000000	Informal	ล้านล้าน	lan lan
