#!/usr/bin/perl -w

# Copyright 2008, 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Glib-Ex-ConnectProperties.
#
# Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ConnectProperties is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ConnectProperties.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Test::More tests => 128;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Glib::Ex::ConnectProperties;

#-----------------------------------------------------------------------------
# VERSION
my $want_version = 19;
{
  is ($Glib::Ex::ConnectProperties::VERSION, $want_version,
      'VERSION variable');
  is (Glib::Ex::ConnectProperties->VERSION,  $want_version,
      'VERSION class method');

  ok (eval { Glib::Ex::ConnectProperties->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Glib::Ex::ConnectProperties->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------

require Glib;
MyTestHelpers::glib_gtk_versions();

## no critic (ProtectPrivateSubs)

#-----------------------------------------------------------------------------
{
  package Foo;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      signals => { 'my-sig' => { return_type => 'Glib::String',
                                 flags       => ['run-last'],
                                 param_types => ['Glib::String','Glib::String'],
                               },
                 },
                   properties => [Glib::ParamSpec->boolean
                                  ('myprop-one',
                                   'myprop-one',
                                   'Blurb about boolean one.',
                                   0,
                                   Glib::G_PARAM_READWRITE),

                                  Glib::ParamSpec->boolean
                                  ('myprop-two',
                                   'myprop-two',
                                   'Blurb about boolean two.',
                                   0,
                                   Glib::G_PARAM_READWRITE),

                                  Glib::ParamSpec->double
                                  ('writeonly-double',
                                   'writeonly-double',
                                   'Blurb about writeonly double.',
                                   -1000, 1000, 111,
                                   ['writable']),

                                  Glib::ParamSpec->float
                                  ('readonly-float',
                                   'readonly-float',
                                   'Blurb about readonly float.',
                                   -2000, 2000, 222,
                                   'readable'),

                                  Glib::ParamSpec->string
                                  ('mystring',
                                   'mystring',
                                   'Blurb about string.',
                                   '', # default
                                   Glib::G_PARAM_READWRITE),

                                  Glib::ParamSpec->boxed
                                  ('mystrv',
                                   'mystrv',
                                   'Blurb about strv.',
                                   'Glib::Strv', # type
                                   Glib::G_PARAM_READWRITE),
                                 ];
}

#-----------------------------------------------------------------------------
# values_cmp

my $have_values_cmp = Glib::ParamSpec->can('values_cmp');
diag "have values_cmp(): ", ($have_values_cmp ? 'yes' : 'no');

# SKIP: {
#   $have_values_cmp or skip 'due to no values_cmp()', 1;
# }


#-----------------------------------------------------------------------------
# _pspec_equal() -- boolean

{ my $pspec = Glib::ParamSpec->boolean ('foo','foo','blurb',0,['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,1));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,0));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,1));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,0));

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,1));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,1));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,undef));

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,undef));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,0));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'x',2));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, '',0));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, '',''));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,0));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,2));
}

#-----------------------------------------------------------------------------
# _pspec_equal() -- string

{ my $pspec = Glib::ParamSpec->string ('foo','foo','blurb',
                                       'default',['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'x','x'));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'x',''));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'x','X'));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'x',undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,'x'));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,undef));
}

#-----------------------------------------------------------------------------
# _pspec_equal() -- char

{ my $pspec = Glib::ParamSpec->char ('foo','foo','blurb',
                                     32,127,32,['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,1));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 1,2));

}

#-----------------------------------------------------------------------------
# _pspec_equal() -- int

{ my $pspec = Glib::ParamSpec->int ('foo','foo','blurb',
                                    0,100,0,['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,123));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,0));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,123));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,0));
}

#-----------------------------------------------------------------------------
# _pspec_equal() -- float

{ my $pspec = Glib::ParamSpec->float ('foo','foo','blurb',
                                      0,100,0,['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,123));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,0));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,123));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,0));

  my $epsilon = $pspec->get_epsilon;
  diag "  epsilon is $epsilon";
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0, $epsilon / 2));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0, - $epsilon / 2));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $epsilon / 2, 0));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, - $epsilon / 2, 0));
}

#-----------------------------------------------------------------------------
# _pspec_equal() -- double

{ my $pspec = Glib::ParamSpec->double ('foo','foo','blurb',
                                       0,100,0,['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,123));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,0));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,123));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0,0));

  my $epsilon = $pspec->get_epsilon;
  diag "  epsilon is $epsilon";
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0, $epsilon / 2));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 0, - $epsilon / 2));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $epsilon / 2, 0));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, - $epsilon / 2, 0));
}

#-----------------------------------------------------------------------------
# _pspec_equal() -- object

{ my $pspec = Glib::ParamSpec->object ('foo','foo','blurb',
                                       'Glib::Object',['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  my $f1 = Foo->new;
  my $f2 = Foo->new;
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $f1,$f1));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $f1,$f2));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, $f1,undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,$f1));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,undef));
}

#-----------------------------------------------------------------------------
# _pspec_equal() -- scalar

{ my $pspec = Glib::ParamSpec->scalar ('foo','foo','blurb',['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 123,123));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'xyz','xyz'));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, 'xyz',123));
}


#-----------------------------------------------------------------------------
# _pspec_equal() -- strv

{ my $pspec = Glib::ParamSpec->boxed ('foo','foo','blurb',
                                      'Glib::Strv',['readable']);
  diag "pspec ",ref $pspec,", value_type=",$pspec->get_value_type;

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, [],undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,[]));
  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, [],[]));

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['x'],['x']));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['x'],[]));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['x'],undef));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, [],['x']));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, undef,['x']));

  ok (Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['a','b'],['a','b']));
  ok (! Glib::Ex::ConnectProperties::_pspec_equal ($pspec, ['a','b'],['a','x']));
}

#-----------------------------------------------------------------------------
# disconnect ()

{
  my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
  my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
  my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                               [$obj2,'myprop-two']);
  isa_ok ($conn, 'Glib::Ex::ConnectProperties');

  is ($conn->VERSION, $want_version, 'VERSION object method');
  { ok (eval { $conn->VERSION($want_version); 1 },
        "VERSION object check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { $conn->VERSION($check_version); 1 },
        "VERSION object check $check_version");
  }

  is ($obj1->get ('myprop-one'), 1);
  is ($obj1->get ('myprop-two'), 1);
  is ($obj2->get ('myprop-one'), 0);
  is ($obj2->get ('myprop-two'), 1);

  $obj2->set (myprop_two=>0);
  is ($obj1->get ('myprop-one'), 0);
  is ($obj1->get ('myprop-two'), 1);
  is ($obj2->get ('myprop-one'), 0);
  is ($obj2->get ('myprop-two'), 0);

  $conn->disconnect;
  ok (! MyTestHelpers::any_signal_connections($obj1));
  ok (! MyTestHelpers::any_signal_connections($obj2));

  $obj1->set (myprop_one=>1);
  is ($obj1->get ('myprop-one'), 1);
  is ($obj1->get ('myprop-two'), 1);
  is ($obj2->get ('myprop-one'), 0);
  is ($obj2->get ('myprop-two'), 0);
}

#-----------------------------------------------------------------------------
# dynamic ()

{
  my $obj1 = Foo->new (myprop_one => 1);
  my $obj2 = Foo->new (myprop_one => 0);
  my $conn = Glib::Ex::ConnectProperties->dynamic ([$obj1,'myprop-one'],
                                                   [$obj2,'myprop-one']);
  isa_ok ($conn, 'Glib::Ex::ConnectProperties');
  require Scalar::Util;
  Scalar::Util::weaken ($conn);
  is ($conn, undef, 'dynamic() gc when weakened');
  $obj1->set (myprop_one => 0);
  is ($obj1->get ('myprop-one'), 0);
  is ($obj2->get ('myprop-one'), 1, 'dynamic() no propagate after gc');
}

#-----------------------------------------------------------------------------
# read_signal

{
  my $obj1 = Foo->new (mystring => 'one');
  my $obj2 = Foo->new (mystring => 'two');
  Glib::Ex::ConnectProperties->new
      ([$obj1,'mystring'],
       [$obj2,'mystring',
        read_signal => 'my-sig',
        read_signal_return => 'rsigret' ]);
  is ($obj1->get ('mystring'), 'one', 'read_signal initial obj1');
  is ($obj2->get ('mystring'), 'one', 'read_signal initial obj2');

  $obj2->set(mystring => 'abc');
  is ($obj1->get ('mystring'), 'one', 'read_signal no change obj1');
  is ($obj2->get ('mystring'), 'abc', 'read_signal no change obj2');

  my $ret = $obj2->signal_emit ('my-sig', 'def', 'jki');
  is ($ret, 'rsigret', 'read_signal_return value');
  is ($obj1->get ('mystring'), 'abc', 'read_signal propagate to obj1');
  is ($obj2->get ('mystring'), 'abc', 'read_signal propagate in obj2');
}

#-----------------------------------------------------------------------------
# bool_not

{
  my $obj1 = Foo->new (myprop_one => 1);
  my $obj2 = Foo->new (myprop_one => 0);
  Glib::Ex::ConnectProperties->new
      ([$obj1,'myprop-one'],
       [$obj2,'myprop-one', bool_not => 1]);

  ok (  $obj1->get ('myprop-one'));
  ok (! $obj2->get ('myprop-one'));
  $obj1->set('myprop-one',0);
  ok (! $obj1->get ('myprop-one'));
  ok (  $obj2->get ('myprop-one'));
  $obj2->set('myprop-one',0);
  ok (  $obj1->get ('myprop-one'));
  ok (! $obj2->get ('myprop-one'));
}

#-----------------------------------------------------------------------------
# func_in

{
  my $obj1 = Foo->new (myprop_one => 1);
  my $obj2 = Foo->new (myprop_one => 0);
  my @saw_args;
  Glib::Ex::ConnectProperties->new
      ([$obj1,'myprop-one'],
       [$obj2,'myprop-one', func_in => sub { @saw_args = @_; return @_ } ]);
  $obj1->set('myprop-one',0);
  is_deeply (\@saw_args, [0]);
}

#-----------------------------------------------------------------------------
# func_out

{
  my $obj1 = Foo->new;
  my $obj2 = Foo->new;
  my @saw_args;
  Glib::Ex::ConnectProperties->new
      ([$obj1,'mystring'],
       [$obj2,'mystring', func_out => sub { @saw_args = @_; return @_ } ]);
  $obj2->set('mystring','abc');
  is_deeply (\@saw_args, ['abc']);
}

#-----------------------------------------------------------------------------
# hash_in, hash_out

{
  my $obj1 = Foo->new (mystring => 'a');
  my $obj2 = Foo->new;
  Glib::Ex::ConnectProperties->new
      ([$obj1,'mystring'],
       [$obj2,'mystring',
        hash_in  => { 'a' => 'x', 'b' => 'y' },
        hash_out => { 'x' => 'a', 'y' => 'b' } ]);
  is ($obj1->get('mystring'), 'a');
  is ($obj2->get('mystring'), 'x');

  $obj1->set('mystring','b');
  is ($obj1->get('mystring'), 'b');
  is ($obj2->get('mystring'), 'y');

  $obj2->set('mystring','x');
  is ($obj1->get('mystring'), 'a');
  is ($obj2->get('mystring'), 'x');

  $obj2->set('mystring','z');
  is ($obj1->get('mystring'), undef);
  is ($obj2->get('mystring'), 'z');
}

#-----------------------------------------------------------------------------
# weaken

{
  my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
  my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
  my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                               [$obj2,'myprop-two']);
  require Scalar::Util;

  my $weak_obj1 = $obj1;
  Scalar::Util::weaken ($weak_obj1);
  $obj1 = undef;
  is ($weak_obj1, undef, 'obj1 not kept alive');

  my $weak_obj2 = $obj2;
  Scalar::Util::weaken ($weak_obj2);
  $obj2 = undef;
  is ($weak_obj2, undef, 'obj2 not kept alive');

  Scalar::Util::weaken ($conn);
  is ($conn, undef, 'conn garbage collected when none left');
}

{
  my $obj1 = Foo->new (myprop_one => 1, myprop_two => 0);
  my $obj2 = Foo->new (myprop_one => 0, myprop_two => 1);
  my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                               [$obj2,'myprop-two']);

  $obj1 = undef;
  $obj2->set (myprop_two=>0);
  is (scalar @{$conn->{'array'}}, 1,
      'notice linked object gone');
}

{
  my $obj1 = Foo->new (myprop_one => 1, myprop_two => 1);
  my $obj2 = Foo->new (myprop_one => 0, myprop_two => 0);
  my $conn = Glib::Ex::ConnectProperties->new ([$obj1,'myprop-one'],
                                               [$obj2,'myprop-two',
                                                write_only => 1]);
  require Scalar::Util;

  my $weak_obj1 = $obj1;
  Scalar::Util::weaken ($weak_obj1);
  $obj1 = undef;
  is ($weak_obj1, undef, 'obj1 not kept alive');

  Scalar::Util::weaken ($conn);
  is ($conn, undef, 'conn garbage collected when last readable gone');
}

#-----------------------------------------------------------------------------
# write-only

{
  my $obj1 = Foo->new;
  my $obj2 = Foo->new;
  my $obj3 = Foo->new; $obj3->{'readonly-float'} = 999;
  Glib::Ex::ConnectProperties->new ([$obj1,'writeonly-double'],
                                    [$obj2,'writeonly-double'],
                                    [$obj3,'readonly-float']);
  is ($obj1->{'writeonly_double'}, 999,
      'obj1 writeonly-double set initially');
  is ($obj2->{'writeonly_double'}, 999,
      'obj2 writeonly-double set initially');
}

{
  my $obj1 = Foo->new;
  my $obj2 = Foo->new;
  Glib::Ex::ConnectProperties->new ([$obj1,'writeonly-double'],
                                    [$obj2,'readonly-float']);
  $obj2->{'readonly-float'} = 999;
  $obj2->notify ('readonly-float');
  is ($obj1->{'writeonly_double'}, 999,
      'writeonly-double set by notify');
}

SKIP: {
  Glib::ParamSpec->can('value_validate')
      or skip 'due to value_validate() not available', 1;
  my $obj1 = Foo->new; $obj1->{'readonly-float'} = 1500;
  my $obj2 = Foo->new;
  Glib::Ex::ConnectProperties->new ([$obj1,'readonly-float'],
                                    [$obj2,'writeonly-double']);
  is ($obj2->{'writeonly_double'}, 1000,
      'obj1 writeonly-double set initially with value_validate clamp');
}

#-----------------------------------------------------------------------------
# strv

{
  my $obj1 = Foo->new;
  my $obj2 = Foo->new;
  Glib::Ex::ConnectProperties->new ([$obj1,'mystrv'],
                                    [$obj2,'mystrv']);
  is_deeply ($obj1->get('mystrv'), undef);
  $obj1->set (mystrv => ['hello', 'world']);
  is_deeply ($obj1->get('mystrv'), ['hello', 'world']);
  is_deeply ($obj2->get('mystrv'), ['hello', 'world']);
}

{
  my $obj1 = Foo->new (mystrv => ['initial', 'one']);
  my $obj2 = Foo->new (mystrv => ['blah', 'blah']);
  Glib::Ex::ConnectProperties->new ([$obj1,'mystrv'],
                                    [$obj2,'mystrv']);
  is_deeply ($obj1->get('mystrv'), ['initial', 'one']);
  is_deeply ($obj2->get('mystrv'), ['initial', 'one']);
  $obj2->set (mystrv => ['hello', 'world']);
  is_deeply ($obj1->get('mystrv'), ['hello', 'world']);
  is_deeply ($obj2->get('mystrv'), ['hello', 'world']);
}


exit 0;
