#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011, 2012 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
# Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

use 5.008;
use strict;
use warnings;
use Glib::Ex::TieProperties;
use Test::More tests => 38;

use lib 't';
use MyTestHelpers;
BEGIN { MyTestHelpers::nowarnings() }

require Glib;
MyTestHelpers::glib_gtk_versions();

#-----------------------------------------------------------------------------
{
  package MyObject;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass
    'Glib::Object',
      properties => [Glib::ParamSpec->boolean
                     ('myprop-one',
                      'myprop-one',
                      'Blurb.',
                      0,
                      Glib::G_PARAM_READWRITE),

                     Glib::ParamSpec->boolean
                     ('myprop-two',
                      'myprop-two',
                      'Blurb.',
                      0,
                      Glib::G_PARAM_READWRITE),

                     Glib::ParamSpec->double
                     ('writeonly-double',
                      'writeonly-double',
                      'Blurb.',
                      -1000, 1000, 111,
                      ['writable']),

                     Glib::ParamSpec->float
                     ('readonly-float',
                      'readonly-float',
                      'Blurb.',
                      -2000, 2000, 222,
                      ['readable']),
                    ];
}
{
  package MyObjectNoProperties;
  use strict;
  use warnings;
  use Glib;
  use Glib::Object::Subclass 'Glib::Object';
}

#-----------------------------------------------------------------------------

my %want_props = ('myprop-one' => 1,
                  'myprop-two' => 1,
                  'readonly-float' => 1,
                  'writeonly-double' => 1);

my $gobject_has_properties = defined ((Glib::Object->list_properties)[0]);

my $want_version = 16;
{
  is ($Glib::Ex::TieProperties::VERSION, $want_version,
      'VERSION variable');
  is (Glib::Ex::TieProperties->VERSION, $want_version,
      'VERSION class method');
  ok (eval { Glib::Ex::TieProperties->VERSION($want_version); 1 },
      "VERSION class check $want_version");
  my $check_version = $want_version + 1000;
  ok (! eval { Glib::Ex::TieProperties->VERSION($check_version); 1 },
      "VERSION class check $check_version");
}

#-----------------------------------------------------------------------------
# tie()

diag "using tie()";
{
  my $obj = MyObject->new;
  my %h;
  my $tobj = tie %h, 'Glib::Ex::TieProperties', $obj;

  # tobj VERSION
  {
    is ($tobj->VERSION, $want_version, 'VERSION object method');
    ok (eval { $tobj->VERSION($want_version); 1 },
        "VERSION object check $want_version");
    my $check_version = $want_version + 1000;
    ok (! eval { $tobj->VERSION($want_version + 1000); 1 },
        "VERSION object check $check_version");
  }

  # tobj->object()
  is ($tobj->object, $obj, 'tobj->object');

  # tied()
  is (tied(%h), $tobj, 'tied()');

  # scalar(), SCALAR method new in 5.8.3
 SKIP: {
    $] >= 5.008003
      or skip "SCALAR method only in 5.8.3 up", 1;
    ok (scalar(%h), 'scalar() true, 1 or more properties exist');
  }

  # exists()
  ok (exists $h{'myprop-one'},
      'exists myprop-one');
  ok (exists $h{'myprop_one'},
      'exists myprop_one');
  ok (! exists $h{'nosuchproperty'},
      'exists nosuchproperty');

  # fetch/store
  is ($h{'myprop-one'}, 0, 'fetch myprop-one, default value');
  $h{'myprop-one'} = 1;
  is ($h{'myprop-one'}, 1, 'fetch myprop-one, after store');
  is ($h{'writeonly-double'}, undef, 'fetch writeonly-double');
  ok (! eval { $h{'nosuchproperty'} = 1; 1 },
      'store nosuchproperty, error');
  {
    my $handler_called = 0;
    my $handler = sub { $handler_called++ };
    my $handler_id = Glib::Log->set_handler ('GLib-GObject',
                                             ['warning'], $handler);
    $h{'readonly-float'} = 1.25;
    is ($handler_called, 1, 'store readonly-float, g_log warning');
    Glib::Log->remove_handler ('GLib-GObject', $handler_id);
  }

  # keys()
  # allow GObject to define extras
  is_deeply ([ sort grep {exists $want_props{$_}} keys %h ],
             [ sort keys %want_props ],
             'keys');

  # each()
  # allow GObject to define extras
  {
    my @got;
    while (my ($key,$value) = each %h) {
      if ($want_props{$key}) {
        push @got, [$key,$value];
      }
    }
    @got = sort {$a->[0] cmp $b->[0]} @got;
    is_deeply (\@got,
               [ ['myprop-one', 1 ],
                 ['myprop-two', 0 ],
                 ['readonly-float', 222 ],
                 ['writeonly-double', undef ] ],
               'each');
  }

  # delete()
  ok (! eval { delete $h{'myprop-one'}; 1 },
      'delete() myprop-one');

  # clear
  ok (! eval { %h = (); 1 },
      'clear myprop-one');
}

#-----------------------------------------------------------------------------
# tie() no properties

diag "using tie() with no properties";
{
  my $obj = MyObjectNoProperties->new;
  my %h;
  my $tobj = tie %h, 'Glib::Ex::TieProperties', $obj;

  # scalar()
  # 5.8.2 and earlier without SCALAR method also give false for empty %h
  ok ($gobject_has_properties || ! scalar %h,
      "scalar() false, if GObject doesn't have properties");
}

#-----------------------------------------------------------------------------
# new()

diag "using new()";
{
  my $obj = MyObject->new;
  my $h = Glib::Ex::TieProperties->new($obj);

  # tied()
  is (tied(%$h)->object, $obj, 'tied()->object');
}

#-----------------------------------------------------------------------------
# new() -- weak

diag "using new() weak";
{
  my $obj = MyObject->new;
  my $h = Glib::Ex::TieProperties->new($obj, weak => 1);
  $obj = undef;

  is (tied(%$h)->object, undef, 'destroyed tied()->object');
  is ($h->{'myprop-one'}, undef, 'destroyed fetch');
  ok (eval { $h->{'myprop-one'} = 1; 1}, 'destroyed store');
  ok (! scalar %$h, 'destroyed scalar() false');
  is_deeply ([ sort grep {exists $want_props{$_}} keys %$h ],
             [ ],
             'destroyed keys');
}


#-----------------------------------------------------------------------------

diag "using in_object()";
{
  my $obj = MyObject->new;
  Glib::Ex::TieProperties->in_object($obj);

  my $h = $obj->{'property'};
  my $tobj = tied %$h;

  # tied()
  is (tied(%$h)->object, $obj, 'in_object() - tied()->object');

  $obj = undef;
  is (tied(%$h)->object, $obj, 'in_object() - tied()->object destroyed');
  Scalar::Util::weaken ($h);
  Scalar::Util::weaken ($tobj);
  is ($h,    undef, 'in_object() hashref gc');
  is ($tobj, undef, 'in_object() tobj gc');
}

#-----------------------------------------------------------------------------

diag "using in_object() with field name";
{
  my $obj = MyObject->new;
  Glib::Ex::TieProperties->in_object($obj, field=>'xyzzy');

  is ($obj->{'property'}, undef, 'in_object xyzzy - not in "property" field');

  my $h = $obj->{'xyzzy'};
  my $tobj = tied %$h;

  # tied()
  is (tied(%$h)->object, $obj, 'in_object() xyzzy - tied()->object');

  $obj = undef;
  is (tied(%$h)->object, $obj, 'in_object() xyzzy - tied()->object destroyed');
  Scalar::Util::weaken ($h);
  Scalar::Util::weaken ($tobj);
  is ($h,    undef, 'in_object() xyzzy hashref gc');
  is ($tobj, undef, 'in_object() xyzzy tobj gc');
}

exit 0;
