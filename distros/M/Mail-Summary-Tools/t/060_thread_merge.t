#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "Mail::Summary::Tools::Summary::Thread";

my $now     = time;
my $early   = $now - 100;
my $late    = $now + 100;
my $earlier = $early - 100;
my $later   = $late + 100;

{

	my $thread = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		extra => {
			date_from => $early,
			date_to   => $late,
		},
	);

	my $thread_new = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		extra => {
			date_from => $earlier,
			date_to   => $later,
		},
	);

	$thread->merge( $thread_new );

	is( $thread->extra->{date_from}, $earlier, "date_from" );
	is( $thread->extra->{date_to}, $later, "date_to" );
	ok( !$thread->extra->{out_of_date}, "not marked as out of date because no summary" );
}

{

	my $thread = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		summary    => 'oink',
		extra => {
			date_from => $early,
			date_to   => $late,
		},
	);

	my $thread_new = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		extra => {
			date_from => $early,
			date_to   => $late,
		},
	);

	$thread->merge( $thread_new );

	is( $thread->extra->{date_from}, $early, "date_from" );
	is( $thread->extra->{date_to}, $late, "date_to" );
	ok( !$thread->extra->{out_of_date}, "not marked as out of date because dates didn't change" );
	is( $thread->summary, "oink", "summary" );
}

{

	my $thread = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		summary    => 'oink',
		extra => {
			date_from => $early,
			date_to   => $late,
		},
	);

	my $thread_new = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		extra => {
			date_from => $earlier,
			date_to   => $later,
		},
	);

	$thread->merge( $thread_new );

	is( $thread->extra->{date_from}, $earlier, "date_from" );
	is( $thread->extra->{date_to}, $later, "date_to" );
	ok( $thread->extra->{out_of_date}, "marked as out of date" );
	is( $thread->summary, "oink", "summary" );
}
{

	my $thread = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		hidden     => 1,
		extra => {
			date_from => $early,
			date_to   => $late,
		},
	);

	my $thread_new = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		extra => {
			date_from => $earlier,
			date_to   => $later,
		},
	);

	$thread->merge( $thread_new );

	is( $thread->extra->{date_from}, $earlier, "date_from" );
	is( $thread->extra->{date_to}, $later, "date_to" );
	ok( $thread->extra->{out_of_date}, "marked as out of date" );
	ok( $thread->hidden, "hidden" );
}

{

	my $thread = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		extra => {
			date_from => $earlier,
			date_to   => $later,
		},
	);

	my $thread_new = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		summary    => 'oink',
		extra => {
			date_from => $early,
			date_to   => $late,
		},
	);

	$thread->merge( $thread_new );

	is( $thread->extra->{date_from}, $earlier, "date_from" );
	is( $thread->extra->{date_to}, $later, "date_to" );
	ok( $thread->extra->{out_of_date}, "marked as out of date" );
	is( $thread->summary, "oink", "summary" );
}

{

	my $thread = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		summary    => 'oink',
		extra => {
			date_from => $earlier,
			date_to   => $later,
		},
	);

	my $thread_new = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		extra => {
			date_from => $early,
			date_to   => $late,
		},
	);

	$thread->merge( $thread_new );

	is( $thread->extra->{date_from}, $earlier, "date_from" );
	is( $thread->extra->{date_to}, $later, "date_to" );
	ok( !$thread->extra->{out_of_date}, "not marked as out of date" );
	is( $thread->summary, "oink", "summary" );
}

{

	my $thread = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		extra => {
			date_from => $early,
			date_to   => $late,
		},
	);

	my $thread_new = Mail::Summary::Tools::Summary::Thread->new(
		message_id => 'foo@bar.com',
		subject    => 'Moose',
		summary    => 'oink',
		extra => {
			date_from => $earlier,
			date_to   => $later,
		},
	);

	$thread->merge( $thread_new );

	is( $thread->extra->{date_from}, $earlier, "date_from" );
	is( $thread->extra->{date_to}, $later, "date_to" );
	ok( !$thread->extra->{out_of_date}, "not marked as out of date because summary was new" );
	is( $thread->summary, "oink", "summary" );
}

