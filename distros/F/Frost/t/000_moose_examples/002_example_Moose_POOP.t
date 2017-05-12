#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

#use Test::More 'no_plan';
use Test::More tests => 96;

use Frost::Asylum;

#	from Moose-0.87/t/200_examples/002_example_Moose_POOP.t

{
	package Moose::POOP::Object;
	use Frost;

	sub oid { $_[0]->id }

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	package Newswriter::Author;
	use Moose;

	extends 'Moose::POOP::Object';

	has 'first_name' => (is => 'rw', isa => 'Str');
	has 'last_name'  => (is => 'rw', isa => 'Str');

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{
	package Newswriter::Article;
	use Moose;
	use Moose::Util::TypeConstraints;

	use DateTime::Format::MySQL;

	extends 'Moose::POOP::Object';

	subtype 'Headline'
		=> as 'Str'
		=> where { length($_) < 100 };

	subtype 'Summary'
		=> as 'Str'
		=> where { length($_) < 255 };

#	CAVEAT: We cannot store foreign classes!
#
#	subtype 'DateTimeFormatString'
#		=> as 'Str'
#		=> where { DateTime::Format::MySQL->parse_datetime($_) };
#
	subtype 'DateTimeFormatString'
		=> as 'Str'
		=> where { DateTime::Format::MySQL->parse_date($_) };

	coerce 'DateTimeFormatString'
		=> from Object
		=> via { DateTime::Format::MySQL->format_date($_) };
#
###########################################

	enum 'State' => qw(draft posted pending archive);

	has 'headline' => (is => 'rw', isa => 'Headline');
	has 'summary'  => (is => 'rw', isa => 'Summary');
	has 'article'  => (is => 'rw', isa => 'Str');

#	has 'start_date' => (is => 'rw', isa => 'DateTimeFormatString');
#	has 'end_date'   => (is => 'rw', isa => 'DateTimeFormatString');
	has 'start_date' => (is => 'rw', isa => 'DateTimeFormatString', coerce => 1);
	has 'end_date'   => (is => 'rw', isa => 'DateTimeFormatString', coerce => 1);

	has 'author' => (is => 'rw', isa => 'Newswriter::Author');

	has 'state' => (is => 'rw', isa => 'State');				#	status is defined in Frost::Object...

#	CAVEAT: We cannot store foreign classes!
#
#	around 'start_date', 'end_date' => sub {
#		my $c	= shift;
#		my $self = shift;
#		$c->($self, DateTime::Format::MySQL->format_datetime($_[0])) if @_;
#		DateTime::Format::MySQL->parse_datetime($c->($self) || return undef);
#	};
#
###########################################

	no Moose;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

{ # check the meta stuff first
#	isa_ok(Moose::POOP::Object->meta, 'Frost::Meta::Class');
#		fails with something like Class::MOP::Class::Immutable::Class::MOP::Class::__ANON__::SERIAL::1
	isa_ok(Moose::POOP::Object->meta, 'Moose::Meta::Class');
	isa_ok(Moose::POOP::Object->meta, 'Class::MOP::Class');

#	isa_ok(Moose::POOP::Object->meta->get_meta_instance, 'Frost::Meta::Instance');
#		fails with something like Class::MOP::Class::__ANON__::SERIAL::3
	isa_ok(Moose::POOP::Object->meta->get_meta_instance, 'Moose::Meta::Instance');
	isa_ok(Moose::POOP::Object->meta->get_meta_instance, 'Class::MOP::Instance');

	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $base = Moose::POOP::Object->new ( asylum => $ASYL, id => 'BASE' );

	isa_ok($base, 'Moose::POOP::Object');
	isa_ok($base, 'Frost::Locum');
	isa_ok($base, 'Moose::Object');

	lives_ok	{ $ASYL->remove;	}	'Asylum closed and removed';
}

my $article_oid;
my $article_ref;
{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $article;
	lives_ok {
		$article = Newswriter::Article->new(
			asylum => $ASYL, id => 'A1',

			headline => 'Home Office Redecorated',
			summary  => 'The home office was recently redecorated to match the new company colors',
			article  => '...',

			author => Newswriter::Author->new(
				asylum => $ASYL, id => 'A1',		#	other class, same id !!!
				first_name => 'Truman',
				last_name  => 'Capote'
			),

			state => 'pending'
		);
	} '... created my article successfully';
	isa_ok($article, 'Newswriter::Article');
	isa_ok($article, 'Moose::POOP::Object');
	isa_ok($article, 'Frost::Locum');

	lives_ok {
		$article->start_date(DateTime->new(year => 2006, month => 6, day => 10));
		$article->end_date(DateTime->new(year => 2006, month => 6, day => 17));
	} '... add the article date-time stuff';

	ok($article->oid, '... got a oid for the article');

	$article_oid = $article->oid;
	$article_ref = "$article";

	is($article->headline,
		'Home Office Redecorated',
			'... got the right headline');
	is($article->summary,
		'The home office was recently redecorated to match the new company colors',
			'... got the right summary');
	is($article->article, '...', '... got the right article');

#	CAVEAT: We cannot store foreign classes!
#
#	isa_ok($article->start_date, 'DateTime');
#	isa_ok($article->end_date,   'DateTime');

	is($article->start_date, '2006-06-10',	'...got correct start_date');
	is($article->end_date,   '2006-06-17',	'...got correct start_date');

	isa_ok($article->author, 'Newswriter::Author');
	isa_ok($article->author, 'Frost::Locum');

	is($article->author->first_name, 'Truman', '... got the right author first name');
	is($article->author->last_name, 'Capote', '... got the right author last name');

	is($article->state, 'pending', '... got the right state');

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

#	Moose::POOP::Meta::Instance->_reload_db();

my $article2_oid;
my $article2_ref;
{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $article2;
	lives_ok {
		$article2 = Newswriter::Article->new(
			asylum => $ASYL, id => 'A2',

			headline => 'Company wins Lottery',
			summary  => 'An email was received today that informed the company we have won the lottery',
			article  => 'WoW',

			author => Newswriter::Author->new(
				asylum => $ASYL, id => 'A2',		#	other class, same id !!!
				first_name => 'Katie',
				last_name  => 'Couric'
			),

			state => 'posted'
		);
	} '... created my article successfully';
	isa_ok($article2, 'Newswriter::Article');
	isa_ok($article2, 'Moose::POOP::Object');
	isa_ok($article2, 'Frost::Locum');

	$article2_oid = $article2->oid;
	$article2_ref = "$article2";

	is($article2->headline,
		'Company wins Lottery',
			'... got the right headline');
	is($article2->summary,
		'An email was received today that informed the company we have won the lottery',
			'... got the right summary');
	is($article2->article, 'WoW', '... got the right article');

	ok(!$article2->start_date, '... these two dates are unassigned');
	ok(!$article2->end_date,   '... these two dates are unassigned');

	isa_ok($article2->author, 'Newswriter::Author');
	isa_ok($article2->author, 'Frost::Locum');

	is($article2->author->first_name, 'Katie', '... got the right author first name');
	is($article2->author->last_name, 'Couric', '... got the right author last name');

	is($article2->state, 'posted', '... got the right state');

	## orig-article

	my $article;
	lives_ok {
#		$article = Newswriter::Article->new(oid => $article_oid);
		$article = Newswriter::Article->new ( asylum => $ASYL, id => $article_oid );
	} '... (re)-created my article successfully';
	isa_ok($article, 'Newswriter::Article');
	isa_ok($article, 'Moose::POOP::Object');
	isa_ok($article, 'Frost::Locum');

	is($article->oid, $article_oid, '... got a oid for the article');
	isnt($article_ref, "$article", '... got a new article instance');

	is($article->headline,
		'Home Office Redecorated',
			'... got the right headline');
	is($article->summary,
		'The home office was recently redecorated to match the new company colors',
			'... got the right summary');
	is($article->article, '...', '... got the right article');

#	CAVEAT: We cannot store foreign classes!
#
#	isa_ok($article->start_date, 'DateTime');
#	isa_ok($article->end_date,   'DateTime');

	is($article->start_date, '2006-06-10',	'...got correct start_date');
	is($article->end_date,   '2006-06-17',	'...got correct start_date');

	isa_ok($article->author, 'Newswriter::Author');
	isa_ok($article->author, 'Frost::Locum');

	is($article->author->first_name, 'Truman', '... got the right author first name');
	is($article->author->last_name, 'Capote', '... got the right author last name');

	lives_ok {
		$article->author->first_name('Dan');
		$article->author->last_name('Rather');
	} '... changed the value ok';

	is($article->author->first_name, 'Dan', '... got the changed author first name');
	is($article->author->last_name, 'Rather', '... got the changed author last name');

	is($article->state, 'pending', '... got the right state');

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}

#	Moose::POOP::Meta::Instance->_reload_db();

{
	my $ASYL;

	lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

	my $article;
	lives_ok {
#		$article = Newswriter::Article->new(oid => $article_oid);
		$article = Newswriter::Article->new ( asylum => $ASYL, id => $article_oid );
	} '... (re)-created my article successfully';
	isa_ok($article, 'Newswriter::Article');
	isa_ok($article, 'Moose::POOP::Object');
	isa_ok($article, 'Frost::Locum');

	is($article->oid, $article_oid, '... got a oid for the article');
	isnt($article_ref, "$article", '... got a new article instance');

	is($article->headline,
		'Home Office Redecorated',
			'... got the right headline');
	is($article->summary,
		'The home office was recently redecorated to match the new company colors',
			'... got the right summary');
	is($article->article, '...', '... got the right article');

#	CAVEAT: We cannot store foreign classes!
#
#	isa_ok($article->start_date, 'DateTime');
#	isa_ok($article->end_date,   'DateTime');

	is($article->start_date, '2006-06-10',	'...got correct start_date');
	is($article->end_date,   '2006-06-17',	'...got correct start_date');

	isa_ok($article->author, 'Newswriter::Author');
	isa_ok($article->author, 'Frost::Locum');

	is($article->author->first_name, 'Dan', '... got the changed author first name');
	is($article->author->last_name, 'Rather', '... got the changed author last name');

	is($article->state, 'pending', '... got the right state');

	my $article2;
	lives_ok {
#		$article2 = Newswriter::Article->new(oid => $article2_oid);
		$article2 = Newswriter::Article->new ( asylum => $ASYL, id => $article2_oid );
	} '... (re)-created my article successfully';
	isa_ok($article2, 'Newswriter::Article');
	isa_ok($article2, 'Moose::POOP::Object');
	isa_ok($article2, 'Frost::Locum');

	is($article2->oid, $article2_oid, '... got a oid for the article');
	isnt($article2_ref, "$article2", '... got a new article instance');

	is($article2->headline,
		'Company wins Lottery',
			'... got the right headline');
	is($article2->summary,
		'An email was received today that informed the company we have won the lottery',
			'... got the right summary');
	is($article2->article, 'WoW', '... got the right article');

	ok(!$article2->start_date, '... these two dates are unassigned');
	ok(!$article2->end_date,   '... these two dates are unassigned');

	isa_ok($article2->author, 'Newswriter::Author');
	isa_ok($article2->author, 'Frost::Locum');

	is($article2->author->first_name, 'Katie', '... got the right author first name');
	is($article2->author->last_name, 'Couric', '... got the right author last name');

	is($article2->state, 'posted', '... got the right state');

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved';
}
