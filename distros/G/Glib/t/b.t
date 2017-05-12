#!env perl -w

#
# tied properties.
#

use strict;
use warnings;

use Test::More
	tests => 8;

BEGIN { use_ok 'Glib'; }

package MyClass;

use Glib::Object::Subclass
   Glib::Object::,
   properties => [
   	Glib::ParamSpec->string (
		'some_string',
		'Some String Property',
		'This is a property string',
		'default',
		[qw/readable writable/],
	),
   	Glib::ParamSpec->string (
		'read_string',
		'Read String Property',
		'This is a read only property string',
		'default',
		[qw/readable/],
	),
	Glib::ParamSpec->scalar (
		'some_scalar',
		'Some Scalar Property',
		'This property is a scalar that is used as an example',
		[qw/readable writable/]
	),
   ]
   ;

sub GET_PROPERTY {
   my ($self, $pspec) = @_;
   $self->{'__real_'.$pspec->get_name};
}

sub SET_PROPERTY {
   my ($self, $pspec, $newval) = @_;
   $self->{'__real_'.$pspec->get_name} = $newval;
}

sub INIT_INSTANCE
{
	my $self = shift;

	$self->{__real_some_string} = 'one';
	$self->{__real_read_string} = 'two';
}

############
package main;

my $obj = new MyClass;

$obj->tie_properties;
ok(1, '$obj->tie_properites');

is ($obj->{some_string}, 'one', '$obj->{some_string} empty');
is ($obj->{read_string}, 'two', '$obj->{read_string} empty');

$obj->{some_string} = 42;
eval { $obj->{read_string} = 44; 1; };
ok ($@ =~ /property read_string is read-only/, 
	'$obj->{read_string} read only croak');

is ($obj->{some_string}, 42, '$obj->{some_string} 42');
is ($obj->{read_string}, 'two', '$obj->{read_string} empty');

my $foo = 'hello';
$obj->set(some_scalar => $foo);
is ($obj->get("some_scalar"), 'hello', '$obj->{some_scalar} hello');
   
__END__

Copyright (C) 2003 by the gtk2-perl team (see the file AUTHORS for the
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
