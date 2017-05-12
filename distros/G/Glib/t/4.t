#!/usr/bin/perl
#
# test Glib::Object derivation in Perl.
# derive from a C object in perl, and derive from a Perl object in perl.
# checks order of execution of initializers and finalizers, so the code
# gets a little hairy.
#
use strict;
use warnings;

use Glib qw(:constants);

# From 7.t.  Do we need a test helper class?
sub ok($$;$) {
    my($test, $num, $name) = @_;

    my $out = $test ? "ok" : "not ok";
    $out .= " $num" if $num;
    $out .= " - $name" if defined $name;

    print "$out\n";

    return $test;
}

sub pass($;$) {
    my($num, $name) = @_;
    return ok(1, $num, $name);
}

sub fail(;$) {
    my($name) = @_;
    return ok(0, 0, $name);
}

print "1..17\n";
pass 1;

my $init_self;

sub Foo::INIT_INSTANCE {
   $init_self = $_[0]*1;
   pass 2, 'Foo::INIT_INSTANCE';
}

sub Foo::FINALIZE_INSTANCE {
   pass 9, 'Foo::FINALIZE_INSTANCE'
}

my $setprop_self;

sub Foo::SET_PROPERTY {
   $setprop_self = $_[0]*1;
   pass $_[2], 'Foo::SET_PROPERTY';
}

sub Foo::GET_PROPERTY {
   pass 6, 'Foo::GET_PROPERTY';
   6;
}

Glib::Type->register (
   Glib::Object::, Foo::,
   properties => [
           Glib::ParamSpec->string (
              'some_string',
              'Some String Property',
              'This property is a string that is used as an example',
              'default value',
              [qw/readable writable/]
           ),
   ]);

sub Bar::INIT_INSTANCE {
   pass 3, 'Bar::INIT_INSTANCE';
}

sub Bar::FINALIZE_INSTANCE {
   pass 8, 'Bar::FINALIZE_INSTANCE';
}

Glib::Type->register (Foo::, Bar::,
                      properties => [
                         Glib::ParamSpec->int ('number', 'some number',
                                               'number in bar but not in foo',
                                               0, 10, 0, ['readable']),
                      ]);

{
   # instantiate a child.  we should get messages from both initializers.
   my $bar = new Bar;
   # make sure we can set parent properties on the child
   $bar->set(some_string => 4);
   ok $init_self == $setprop_self, 5;
   ok $bar->get("some_string") == 6, 7;
   # should see messages from both finalizers here.
}

pass 10;

#
# ensure that any properties added to the subclass were only added to
# the subclass, and not the parent.
#
ok  defined Foo->find_property('some_string'), 11;
ok !defined Foo->find_property('number'),      12;
ok  defined Bar->find_property('number'),      13;

my @fooprops = Foo->list_properties;
my @barprops = Bar->list_properties;

ok @fooprops == 1, 14, 'property count for parent';
ok @barprops == 2, 15, 'property count for child';

my @ancestry = Glib::Type->list_ancestors ('Bar');
my $ancestry_ok = $ancestry[0] eq 'Bar' &&
                  $ancestry[1] eq 'Foo' &&
                  $ancestry[2] eq 'Glib::Object';
print "".($ancestry_ok ? "ok 16" : "not ok")." - ancestry for Bar\n";

my $cname_ok = Glib::Type->package_from_cname ('GObject') eq 'Glib::Object';
print "".($cname_ok ? "ok 17" : "not ok")." - package_from_cname\n";


__END__

Copyright (C) 2003-2006 by the gtk2-perl team (see the file AUTHORS for the
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
