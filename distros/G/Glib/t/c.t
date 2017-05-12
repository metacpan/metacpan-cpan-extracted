#!/usr/bin/perl
# vim: set filetype=perl :
#
# $Id$
#

#
# enums and flags.
#

use strict;
use warnings;

#########################

use Test::More tests => 57;
BEGIN { use_ok('Glib') };

#########################

#
# Flags basics
#

my $f = Glib::ParamFlags->new (['readable', 'writable']); # with array
isa_ok ($f, 'Glib::Flags');
isa_ok ($f, 'Glib::ParamFlags');
ok ($f == ['readable', 'writable'], "value");

$f = Glib::ParamFlags->new ('readable'); # with plain string
isa_ok ($f, 'Glib::Flags');
isa_ok ($f, 'Glib::ParamFlags');
ok ($f == ['readable'], "value");

my $g = Glib::ParamFlags->new ($f + 'writable'); # from another
isa_ok ($g, 'Glib::ParamFlags');
ok ($g >= $f);

$@ = undef;
eval { my $h = Glib::Flags->new (['readable']); };
ok ($@, "Will croak on trying to create plain old Glib::Flags");

{
  my $f = Glib::ParamFlags->new (['readable']);
  my $g = $f;
  $g += 'writable';
  ok ($g == ['readable', 'writable'],
      "overloaded +=");
  ok ($f == ['readable'],
      "overloaded += leaves original unchanged");
}

foreach my $method (qw(bool as_arrayref eq union sub intersect xor all)) {
  my $func = Glib::Flags->can($method);
  ok ($func, "Glib::Flags::$method() func found");
  no warnings;
  ok (do { eval { $func->(undef, undef, 0) }; 1 },
      'Glib::Flags::$method() no segfault if passed a non-reference');
}

#########################

$@ = undef;
eval {
	Glib::Type->register_enum ('TestEnum', 
			qw/value-one value-two value-three/,
			[ 'value-four', 42 ], 'value-five', ['value-six']);
	1;
};
ok (!$@, 'register_enum');
is_deeply ([Glib::Type->list_ancestors ('TestEnum')],
	   ['TestEnum', 'Glib::Enum']);

$@ = undef;
eval {
	Glib::Type->register_flags ('TestFlags', 
			qw/value-one value-two value-three/,
			[ 'value-four', 1 << 16 ], 'value-five', ['value-six']);
	1;
};
ok (!$@, 'register_flags');
is_deeply ([Glib::Type->list_ancestors ('TestFlags')],
	   ['TestFlags', 'Glib::Flags']);

$@ = undef;
eval {
	Glib::Type->register_enum ('TestEnum1', 
			qw/value-one value-two value-three/,
			[ 'value-four', 42 ], 'value-five', []);
	1;
};
ok ($@, 'failed register_enum with empty array ref');

$@ = undef;
eval {
	Glib::Type->register_enum ('TestEnum2', 
			qw/value-one value-two value-three/,
			[ 'value-four', 42 ], 'value-five', undef);
	1;
};
ok ($@, 'failed register_enum with undef');

$@ = undef;
eval {
	Glib::Type->register_flags ('TestFlags1', 
			qw/value-one value-two value-three/,
			[ 'value-four', 1 << 16 ], 'value-five', []);
	1;
};
ok ($@, 'failed register_flag with empty array ref');

$@ = undef;
eval {
	Glib::Type->register_flags ('TestFlags2', 
			qw/value-one value-two value-three/,
			[ 'value-four', 1 << 16 ], 'value-five', undef);
	1;
};
ok ($@, 'failed register_flag with undef');

my @actual_values = Glib::Type->list_values ('TestEnum');
my @expected_values = (
  {
    value => 1,
    name => 'value-one',
    nick => 'value-one',
  },
  {
    value => 2,
    name => 'value-two',
    nick => 'value-two',
  },
  {
    value => 3,
    name => 'value-three',
    nick => 'value-three',
  },
  {
    value => 42,
    name => 'value-four',
    nick => 'value-four',
  },
  {
    value => 5,
    name => 'value-five',
    nick => 'value-five',
  },
  {
    value => 6,
    name => 'value-six',
    nick => 'value-six',
  },
);
is_deeply (\@actual_values, \@expected_values, 'list_interfaces');

package Tester;

use Test::More;

Glib::Type->register (
	Glib::Object::, __PACKAGE__,
	signals => {
		sig1 => {
			class_closure => sub { 
				is ($_[1], 'value-two', 'closure enum');
				ok ($_[2]->isa ('TestFlags'), 'closure flags');
			},
			return_type => undef,
			param_types => [ 'TestEnum', 'TestFlags' ],
		},
	},
	properties => [
		Glib::ParamSpec->enum (
			'some_enum',
			'Some Enum Property',
			'This is a test of a perl created enum',
			'TestEnum',
			'value-one',
			[qw/readable writable/],
		),
		Glib::ParamSpec->flags (
			'some_flags',
			'Some Flags Property',
			'This is a test of a perl created flags',
			'TestFlags',
			[qw/value-one value-five/],
			[qw/readable writable/],
		)
	]);

sub GET_PROPERTY
{
	$_[0]->{$_[1]->get_name};
}

sub SET_PROPERTY
{
	$_[0]->{$_[1]->get_name} = $_[2];
}

sub INIT_INSTANCE
{
	my $self = shift;
	$self->{some_enum} = 'value-one';
	$self->{some_flags} = ['value-one'];
}

sub sig1
{
	shift->signal_emit ('sig1', @_);
}

package main;

#
# App-registered flags.
#

my $obj = Tester->new;
$obj->sig1 ('value-two', ['value-one', 'value-two']);

is ($obj->get ('some_enum'), 'value-one', 'enum property');
$obj->set (some_enum => 'value-two');
is ($obj->get ('some_enum'), 'value-two', 'enum property, after set');

is_deeply (\@{ $obj->get ('some_flags') }, ['value-one'], 'flags property');
is_deeply ($obj->get('some_flags')->as_arrayref, ['value-one'], 'flags property');

is (($obj->get('some_flags') ? "true" : "false"), "true",
    'flags property, boolean context');
is ($obj->get('some_flags')->bool, 1,
    'flags property, bool()');

$obj->set (some_flags => ['value-one', 'value-two']);
is_deeply (\@{ $obj->get ('some_flags') }, ['value-one', 'value-two'],
	   'flags property, after set');

ok ($obj->get ('some_flags') & $obj->get ('some_flags'),
    '& is overloaded');

eval {
  $obj->set (some_flags => []);
  $obj->set (some_flags => undef);
};
ok ($@ eq '', 'empty flags values do not croak');
ok ($obj->get ('some_flags') == [], 'empty flags values work');

is_deeply (\@{ $obj->get ('some_flags') }, [], 'empty flags @{}');
is_deeply ($obj->get('some_flags')->as_arrayref, [],
           'empty flags, as_arrayref()');

is (($obj->get('some_flags') ? "true" : "false"), "false",
    'empty flags, boolean context');
is ($obj->get('some_flags')->bool, 0,
    'empty flags, bool()');

$obj->set (some_flags => [qw/value-one value-two/]);

ok ($obj->get ('some_flags') == [qw/value-one value-two/], '== is overloaded');
ok ($obj->get ('some_flags') != [qw/value-one/], '!= is overloaded');

ok ($obj->get ('some_flags') eq [qw/value-one value-two/], 'eq is overloaded');
ok ($obj->get ('some_flags') ne [qw/value-one/], 'ne is overloaded');

__END__

Copyright (C) 2003-2005, 2009 by the gtk2-perl team (see the file AUTHORS for the
full list)

This library is free software; you can redistribute it and/or modify it under
the terms of the GNU Library General Public License as published by the Free
Software Foundation; either version 2.1 of the License, or (at your option) any
later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU Library General Public License for more
details.

You should have received a copy of the GNU Library General Public License along
with this library; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
