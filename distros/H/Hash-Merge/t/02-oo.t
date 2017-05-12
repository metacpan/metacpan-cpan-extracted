#!/usr/bin/perl -w

use strict;
use Test::More tests=>49;
use Hash::Merge;

my %left = ( ss => 'left',
             sa => 'left',
	     sh => 'left',
	     as => [ 'l1', 'l2' ],
	     aa => [ 'l1', 'l2' ],
	     ah => [ 'l1', 'l2' ],
	     hs => { left=>1 },
	     ha => { left=>1 },
	     hh => { left=>1 } );

my %right = ( ss => 'right',
	      as => 'right',
	      hs => 'right',
	      sa => [ 'r1', 'r2' ],
	      aa => [ 'r1', 'r2' ],
	      ha => [ 'r1', 'r2' ],
	      sh => { right=>1 },
	      ah => { right=>1 },
	      hh => { right=>1 } );

# Test left precedence
my $merge = Hash::Merge->new();
ok($merge->get_behavior() eq 'LEFT_PRECEDENT', 'no arg default is LEFT_PRECEDENT');


my %lp = %{$merge->merge( \%left, \%right )};

is_deeply( $lp{ss},	'left',						'Left Precedent - Scalar on Scalar' );
is_deeply( $lp{sa},	'left',						'Left Precedent - Scalar on Array' );
is_deeply( $lp{sh},	'left',						'Left Precedent - Scalar on Hash' );
is_deeply( $lp{as},	[ 'l1', 'l2', 'right'],		'Left Precedent - Array on Scalar' );
is_deeply( $lp{aa},	[ 'l1', 'l2', 'r1', 'r2' ],	'Left Precedent - Array on Array' );
is_deeply( $lp{ah},	[ 'l1', 'l2', 1 ],			'Left Precedent - Array on Hash' );
is_deeply( $lp{hs},	{ left=>1 },				'Left Precedent - Hash on Scalar' );
is_deeply( $lp{ha},	{ left=>1 },				'Left Precedent - Hash on Array' );
is_deeply( $lp{hh},	{ left=>1, right=>1 },		'Left Precedent - Hash on Hash' );

ok($merge->set_behavior('RIGHT_PRECEDENT') eq 'LEFT_PRECEDENT', 'set_behavior() returns previous behavior');
ok($merge->get_behavior() eq 'RIGHT_PRECEDENT', 'set_behavior() actually sets the behavior)');

my %rp = %{$merge->merge( \%left, \%right )};

is_deeply( $rp{ss},	'right',						'Right Precedent - Scalar on Scalar' );
is_deeply( $rp{sa},	[ 'left', 'r1', 'r2' ],			'Right Precedent - Scalar on Array' );
is_deeply( $rp{sh},	{ right=>1 },					'Right Precedent - Scalar on Hash' );
is_deeply( $rp{as},	'right',						'Right Precedent - Array on Scalar' );
is_deeply( $rp{aa},	[ 'l1', 'l2', 'r1', 'r2' ],		'Right Precedent - Array on Array' );
is_deeply( $rp{ah},	{ right=>1 },					'Right Precedent - Array on Hash' );
is_deeply( $rp{hs},	'right',						'Right Precedent - Hash on Scalar' );
is_deeply( $rp{ha},	[ 1, 'r1', 'r2' ], 				'Right Precedent - Hash on Array' );
is_deeply( $rp{hh},	{ left=>1, right=>1 },			'Right Precedent - Hash on Hash' );

Hash::Merge::set_behavior( 'STORAGE_PRECEDENT' );
ok($merge->get_behavior() eq 'RIGHT_PRECEDENT', '"global" function does not affect object');
$merge->set_behavior('STORAGE_PRECEDENT');

my %sp = %{$merge->merge( \%left, \%right )};

is_deeply( $sp{ss},	'left',						'Storage Precedent - Scalar on Scalar' );
is_deeply( $sp{sa},	[ 'left', 'r1', 'r2' ],		'Storage Precedent - Scalar on Array' );
is_deeply( $sp{sh},	{ right=>1 },				'Storage Precedent - Scalar on Hash' );
is_deeply( $sp{as},	[ 'l1', 'l2', 'right'],		'Storage Precedent - Array on Scalar' );
is_deeply( $sp{aa},	[ 'l1', 'l2', 'r1', 'r2' ],	'Storage Precedent - Array on Array' );
is_deeply( $sp{ah},	{ right=>1 },				'Storage Precedent - Array on Hash' );
is_deeply( $sp{hs},	{ left=>1 },				'Storage Precedent - Hash on Scalar' );
is_deeply( $sp{ha},	{ left=>1 },				'Storage Precedent - Hash on Array' );
is_deeply( $sp{hh},	{ left=>1, right=>1 },		'Storage Precedent - Hash on Hash' );

$merge->set_behavior('RETAINMENT_PRECEDENT');
my %rep = %{$merge->merge( \%left, \%right )};

is_deeply( $rep{ss},	[ 'left', 'right' ],		'Retainment Precedent - Scalar on Scalar' );
is_deeply( $rep{sa},	[ 'left', 'r1', 'r2' ],		'Retainment Precedent - Scalar on Array' );
is_deeply( $rep{sh},	{ left=>'left', right=>1 },	'Retainment Precedent - Scalar on Hash' );
is_deeply( $rep{as},	[ 'l1', 'l2', 'right'],		'Retainment Precedent - Array on Scalar' );
is_deeply( $rep{aa},	[ 'l1', 'l2', 'r1', 'r2' ],	'Retainment Precedent - Array on Array' );
is_deeply( $rep{ah},	{ l1=>'l1', l2=>'l2', right=>1 },				
	   'Retainment Precedent - Array on Hash' );
is_deeply( $rep{hs},	{ left=>1, right=>'right' },
	   'Retainment Precedent - Hash on Scalar' );
is_deeply( $rep{ha},	{ left=>1, r1=>'r1', r2=>'r2' },				
	   'Retainment Precedent - Hash on Array' );
is_deeply( $rep{hh},	{ left=>1, right=>1 },		'Retainment Precedent - Hash on Hash' );

$merge->specify_behavior( {
				SCALAR => {
					   SCALAR => sub { $_[0] },
					   ARRAY  => sub { $_[0] },
					   HASH   => sub { $_[0] } },
				ARRAY => {
					  SCALAR => sub { $_[0] },
					  ARRAY  => sub { $_[0] },
					  HASH   => sub { $_[0] } },
				HASH => {
					 SCALAR => sub { $_[0] },
					 ARRAY  => sub { $_[0] },
					 HASH   => sub { $_[0] } }
			       }, "My Behavior" );

my %cp = %{$merge->merge( \%left, \%right )};

is_deeply( $cp{ss}, 'left',						'Custom Precedent - Scalar on Scalar' );
is_deeply( $cp{sa},	'left',						'Custom Precedent - Scalar on Array' );
is_deeply( $cp{sh},	'left',						'Custom Precedent - Scalar on Hash' );
is_deeply( $cp{as},	[ 'l1', 'l2'],				'Custom Precedent - Array on Scalar' );
is_deeply( $cp{aa},	[ 'l1', 'l2'],				'Custom Precedent - Array on Array' );
is_deeply( $cp{ah},	[ 'l1', 'l2'],				'Custom Precedent - Array on Hash' );
is_deeply( $cp{hs},	{ left=>1 },				'Custom Precedent - Hash on Scalar' );
is_deeply( $cp{ha},	{ left=>1 },				'Custom Precedent - Hash on Array' );
is_deeply( $cp{hh},	{ left=>1 },				'Custom Precedent - Hash on Hash' );
