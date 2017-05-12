#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok 'Mail::Summary::Tools::FlatFile';

use Mail::Summary::Tools::Summary;

my $summary = Mail::Summary::Tools::Summary->new(
	lists => [
		Mail::Summary::Tools::Summary::List->new(
			name => "list1",
			threads => [
				Mail::Summary::Tools::Summary::Thread->new(
					message_id => 'unique1@example.com',
					subject => "Moose droppings",
					extra => {
						posters => [ { name => "User 1", email => 'foo@example.com' } ],
					},
					default_archive => "gmane",
				),
				Mail::Summary::Tools::Summary::Thread->new(
					message_id => 'unique2@example.com',
					subject => "Moose drool",
					default_archive => "gmane",
					summary => "This is a summary",
				),
			],
		),
		Mail::Summary::Tools::Summary::List->new(
			name => "list2",
			threads => [
				Mail::Summary::Tools::Summary::Thread->new(
					message_id => 'unique3@example.com',
					subject => "Moose nuts",
					default_archive => "gmane",
				),
			],
		),
	],
);

my $flat = Mail::Summary::Tools::FlatFile->new( summary => $summary );

{
	my $res = $flat->save;

	$res =~ s/^#.*$//mg;
	like( $res, qr/---/, "contains separators" );
	is( scalar(grep { length } split /\s*\n---\n\s*/, $res ), 3, "three threads" );
	like( $res, qr/unique1\@example.com/, "refers to message IDs" );
	like( $res, qr/This is a summary/, "contains summary of second thread" );
}

$flat->skip_summarized(1);

{
	my $res = $flat->save;
	$res =~ s/^#.*$//mg;
	is( scalar(grep { length } split /\s*\n---\n\s*/, $res ), 2, "just two threads" );
	unlike( $res, qr/This is a summary/, "doesn't contain summary" );
}

