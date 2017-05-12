#!/usr/bin/perl

use warnings;
use strict;

use lib 't/lib', 'lib';

use Frost::Test;

use Test::More tests => 73;
#use Test::More 'no_plan';

use Frost::Asylum;

$Frost::Util::UUID_CLEAR	= 1;		#	delivers simple 'UUIDs' A-A-A-A-1, -2, -3... for testing

$Data::Dumper::Deparse	= true;

our $ASYL;

lives_ok		{ $ASYL = Frost::Asylum->new ( data_root => $TMP_PATH ) }	'Asylum constructed';

#	from Moose-0.87/t/200_examples/003_example.t

sub U {
	my $f = shift;
	sub { $f->($f, @_) };
}

sub Y {
	my $f = shift;
	U(sub { my $h = shift; sub { $f->(U($h)->())->(@_) } })->();
}

{
	package List;
	use Moose::Role;

	use Frost::Util;

	has '_list' => (
		is	=> 'ro',
		isa	=> 'ArrayRef',
		init_arg => '::',
		default  => sub { [] }
	);

	sub head { (shift)->_list->[0] }
	sub tail {
		my $self = shift;

		$self->new
		(
			'::' =>
			[
				@{$self->_list}[1 .. $#{$self->_list}]
			],
			asylum	=> $self->asylum,
			id			=> UUID,
		);
	}

	sub print {
		join ", " => @{$_[0]->_list};
	}

	package List::Immutable;
	use Moose::Role;

	use Frost::Util;

	requires 'head';
	requires 'tail';

	sub is_empty { not defined ($_[0]->head) }

	sub length {
		my $self = shift;
		(::Y(sub {
			my $redo = shift;
			sub {
				my ($list, $acc) = @_;
				return $acc if $list->is_empty;
				$redo->($list->tail, $acc + 1);
			}
		}))->($self, 0);
	}

	sub apply {
		my ($self, $function) = @_;

		#::IS_DEBUG and ::DEBUG ::Dump [ $self, $function ], [qw( self function )];

		(::Y(sub {
			my $redo = shift;

			#::IS_DEBUG and ::DEBUG ::Dump [ $redo ], [qw( redo )];

			sub {
				my ($list, $func, $acc) = @_;

				#::IS_DEBUG and ::DEBUG ::Dump [ $list, $func, $acc, $list->is_empty() ], [qw( list func acc empty )];

				return $list->new
				(
					'::'		=> $acc,
					asylum	=> $list->asylum,
					id			=> UUID,
				)
					if $list->is_empty;
				$redo->(
					$list->tail,
					$func,
					[ @{$acc}, $func->($list->head) ]
				);
			}
		}))->($self, $function, []);
	}

	package My::List1;
#	use Moose;
	use Frost;

	::lives_ok {
		with 'List', 'List::Immutable';
	} '... successfully composed roles together';

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;

	package My::List2;
#	use Moose;
	use Frost;

	::lives_ok {
		with 'List::Immutable', 'List';
	} '... successfully composed roles together';

	no Frost;

	__PACKAGE__->meta->make_immutable()		unless $::MAKE_MUTABLE;
}

my $IDS	= {};

foreach my $load ( 0..1 )

# =begin testing
{
	my $load_text	= $load ? ' Loading...' : ' Creating...';

	diag $load_text;

	IS_DEBUG and DEBUG "----- $load_text";		#	gives us the line number...
	{
		my $coll;
		if ( $load )	{ $coll	= My::List1->new( asylum => $ASYL, id => $IDS->{E1} );	}
		else				{ $coll	= My::List1->new( asylum => $ASYL, id => UUID );	}

		isa_ok($coll, 'My::List1');

		$IDS->{E1}	||= $coll->id;

		is(	$IDS->{E1},	$coll->id,	'...got correct id ' . $IDS->{E1} );

		ok($coll->does('List'), '... $coll does List');
		ok($coll->does('List::Immutable'), '... $coll does List::Immutable');

		ok($coll->is_empty, '... we have an empty collection' . $load_text );
		is($coll->length, 0, '... we have a length of 0 for the collection' . $load_text );
	}

	IS_DEBUG and DEBUG "----- $load_text";
	{
		my $coll;
		if ( $load )	{ $coll	= My::List2->new( asylum => $ASYL, id => $IDS->{E2} );	}
		else				{ $coll	= My::List2->new( asylum => $ASYL, id => UUID );	}

		isa_ok($coll, 'My::List2');

		$IDS->{E2}	||= $coll->id;

		is(	$IDS->{E2},	$coll->id,	'...got correct id ' . $IDS->{E2} );

		ok($coll->does('List'), '... $coll does List');
		ok($coll->does('List::Immutable'), '... $coll does List::Immutable');

		ok($coll->is_empty, '... we have an empty collection' . $load_text );
		is($coll->length, 0, '... we have a length of 0 for the collection' . $load_text );
	}

	IS_DEBUG and DEBUG "----- $load_text";

	diag 'My::List1 is '			. ( My::List1->meta->is_mutable		? 'mutable' : 'IMMUTABLE' );
	diag 'My::List2 is '			. ( My::List2->meta->is_mutable		? 'mutable' : 'IMMUTABLE' );
	diag 'Moose::Object is '	. ( Moose::Object->meta->is_mutable	? 'mutable' : 'IMMUTABLE' );

	{
		my $coll;
		if ( $load )	{ $coll	= My::List1->new( asylum => $ASYL, id => $IDS->{L1} );	}
		else				{ $coll	= My::List1->new('::' => [ 1 .. 10 ], asylum => $ASYL, id => UUID );	}
		isa_ok($coll, 'My::List1');

		IS_DEBUG and DEBUG "----- $load_text";

		$IDS->{L1}	||= $coll->id;

		is(	$IDS->{L1},	$coll->id,	'...got correct id ' . $IDS->{L1} );

		IS_DEBUG and DEBUG "----- $load_text";

		ok($coll->does('List'), '... $coll does List');
		ok($coll->does('List::Immutable'), '... $coll does List::Immutable');

		IS_DEBUG and DEBUG "----- $load_text";

		ok(!$coll->is_empty, '... we do not have an empty collection' . $load_text );

		IS_DEBUG and DEBUG "----- $load_text";

		is($coll->length, 10, '... we have a length of 10 for the collection' . $load_text );

		IS_DEBUG and DEBUG "----- $load_text";

		is($coll->print, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', '... got the right printed value');

		IS_DEBUG and DEBUG "----- $load_text";

		my $coll2;
		if ( $load )	{ $coll2	= My::List1->new( asylum => $ASYL, id => $IDS->{L1_2} );	}
		else				{ $coll2	= $coll->apply(sub { $_[0] * $_[0] });	}

		isa_ok($coll2, 'My::List1');

		$IDS->{L1_2}	||= $coll2->id;

		is(	$IDS->{L1_2},	$coll2->id,	'...got correct id ' . $IDS->{L1_2} );

		is($coll->print, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', '... original is still the same');
		is($coll2->print, '1, 4, 9, 16, 25, 36, 49, 64, 81, 100', '... new collection is changed');
	}

	IS_DEBUG and DEBUG "----- $load_text";
	{
		my $coll;
		if ( $load )	{ $coll	= My::List2->new( asylum => $ASYL, id => $IDS->{L2} );	}
		else				{ $coll	= My::List2->new('::' => [ 1 .. 10 ], asylum => $ASYL, id => UUID );	}
		isa_ok($coll, 'My::List2');

		$IDS->{L2}	||= $coll->id;

		is(	$IDS->{L2},	$coll->id,	'...got correct id ' . $IDS->{L2} );

		ok($coll->does('List'), '... $coll does List');
		ok($coll->does('List::Immutable'), '... $coll does List::Immutable');

		ok(!$coll->is_empty, '... we do not have an empty collection' . $load_text );
		is($coll->length, 10, '... we have a length of 10 for the collection' . $load_text );

		is($coll->print, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', '... got the right printed value');

		my $coll2;
		if ( $load )	{ $coll2	= My::List2->new( asylum => $ASYL, id => $IDS->{L2_2} );	}
		else				{ $coll2	= $coll->apply(sub { $_[0] * $_[0] });	}

		isa_ok($coll2, 'My::List2');

		$IDS->{L2_2}	||= $coll2->id;

		is(	$IDS->{L2_2},	$coll2->id,	'...got correct id ' . $IDS->{L2_2} );

		is($coll->print, '1, 2, 3, 4, 5, 6, 7, 8, 9, 10', '... original is still the same');
		is($coll2->print, '1, 4, 9, 16, 25, 36, 49, 64, 81, 100', '... new collection is changed');
	}

	IS_DEBUG and DEBUG "----- $load_text";

	lives_ok	{ $ASYL->close;	}	'Asylum closed and saved' . $load_text;

	IS_DEBUG and DEBUG "----- $load_text";

	IS_DEBUG and DEBUG Dump [ $ASYL, $IDS ], [qw( ASYL IDS )];
}
