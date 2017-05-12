#!/usr/bin/perl -w
use Test::Simple tests=>33;
use strict;
BEGIN { use Cwd; eval "use lib '".cwd()."/lib';";}	
require Finance::MICR::LineParser;
#use Smart::Comments '####';

my $feedback;

my $controls = [
	{
		string => 'U000001398633U_T052000113T_9840837158U',
		check_number => '000001398633',
		routing_number => '0113',
		on_us => '9840837158U',
		transit => 'T052000113T',
	},
	{		
		string => 'T052001633T_004466021962U0149',
		check_number => '0149',
		routing_number => '1633',
		on_us => '004466021962U0149',
		transit => 'T052001633T',
	},	
	{		
		string => 'T05 ,200 16 33T_0044 660.w21962U0149',	#T052001633T 004466021962U0149
		check_number => '0149',
		routing_number => '1633',
		on_us => '004466021962U0149',
		transit => 'T052001633T',
	},	
	
];	

for (@{$controls}){
	my $c = $_;

	my $micr = new Finance::MICR::LineParser({ 
		string => $c->{string},
	});

	$feedback = $micr->status;
	#### $feedback
	ok($micr->check_number eq $c->{check_number});
	ok($micr->transit eq $c->{transit});
	ok($micr->routing_number eq $c->{routing_number});
	ok($micr->on_us eq $c->{on_us});
	ok($micr->get_check_type);
	ok($micr->micr);
	ok($micr->micr_pretty);
	
	
}




my $micr2 = new Finance::MICR::LineParser({ 
	string => 'T052001633Tafg hq4thq37t734t7q423 tunJUKHUHSULehtg78h3HBNerg 423t234, 23 -t32g234',
});
ok(not $micr2->valid);
ok($micr2->transit eq 'T052001633T');
ok($micr2->routing_number);
$feedback =  $micr2->status;
#### $feedback

my $micr3 = new Finance::MICR::LineParser({ 
	string => '052001633Tafg hq4thq37t734t7q423 tunJUKHUHSULehtg78h3HBNerg 423t234, 23 -t32g234',
});
ok(not $micr3->valid);
ok(not $micr3->transit);
ok(!$micr3->routing_number);
$feedback =  $micr3->status;

#### $feedback






#### check type 'unrecognized' - matched at least one

my $micrg = new Finance::MICR::LineParser({ 
	string => 'xxxxxxU T033351628T xxxxxxxxU',
});
ok(not $micrg->valid);
ok($micrg->get_check_type eq 'u');
ok($micrg->routing_number);
$feedback =  $micrg->status;
#### $feedback




my $mc = new Finance::MICR::LineParser({ 
	string => 'CCc0000014771CCcAa052000113Aa9840837158CCc',
	on_us_symbol=> 'CCc',
	transit_symbol => 'Aa',
});
ok( $mc->valid);
ok($mc->get_check_type eq 'b');
ok($mc->routing_number);
$feedback =  $micrg->status;
#### $feedback

