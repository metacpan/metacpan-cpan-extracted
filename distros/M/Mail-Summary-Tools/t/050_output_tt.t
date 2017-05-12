#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';

use ok "Mail::Summary::Tools::Output::TT";

use Mail::Summary::Tools::Summary;
use Mail::Summary::Tools::Summary::List;
use Mail::Summary::Tools::Summary::Thread;

my $thread = Mail::Summary::Tools::Summary::Thread->new(
	subject => "Things",
	summary => "moose",
	message_id => "123",
);

my $list = Mail::Summary::Tools::Summary::List->new(
	name => "mailinglist1",
	threads => [ $thread ]
);

my $summary = Mail::Summary::Tools::Summary->new( lists => [ $list ] );

{
	Mail::Summary::Tools::Output::TT->new(
		template_input => \"[% FOREACH list IN summary.lists %][% FOREACH thread IN list.threads %][% thread.message_id %][% END %][% END %]",
		template_output => \(my $out),
	)->process( $summary );

	is( $out, $thread->message_id, "TT works" );
}

{
	my $p = Mail::Summary::Tools::Output::TT->new(
		template_input => \"[% processor %]",
		template_output => \(my $out),
	);
	
	$p->process( $summary );

	is( $out, "$p", "ref to processor" );
}

{
	Mail::Summary::Tools::Output::TT->new(
		template_input => \"[% foo %]",
		template_output => \(my $out),
	)->process( $summary, { foo => "lalaaa" } );

	is( $out, "lalaaa", "pass in extra vars" );
}
