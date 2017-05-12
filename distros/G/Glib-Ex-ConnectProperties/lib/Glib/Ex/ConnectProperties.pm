# Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

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


# maybe:
# multiplier factor [$obj,'prop',mul=>2]
# get_method => name or subr
# set_method => name or subr
# paramspec  => $pspec

package Glib::Ex::ConnectProperties;
use 5.008;
use strict;
use warnings;
use Carp;
use Glib;
use Scalar::Util;
use Module::Load;
use Glib::Ex::SignalIds 5; # version 5 for add()

our $VERSION = 19;

# uncomment this to run the ### lines
#use Smart::Comments;


# Hard/weak refs are as follows.
#
# * Readable property in new() permanent linkage -- the $object signal
#   connection has a hard ref to $elem, and $elem->{'self'} has a hard ref
#   to $self, so $elem is kept alive while $object lives.  The entry for
#   $elem within connp $self->{'array'} is weak so that $elem goes away when
#   $object is destroyed.
#
# * Readable property in dynamic() linkage -- $elem->{'self'} is weak, which
#   means $self can be garbage collected.  Each $elem is still kept alive by
#   the signal connection, but $self->DESTROY drops those connections.
#
# * Write-only property -- there's no signal connection, and $self has a
#   hard ref to $elem, with nothing from $elem back to $self.  The
#   write-onlys don't keep $self alive, only the readables.  Once the last
#   readable object is destroyed the $self and write-onlys are destroyed.
#
# In all cases $elem->{'object'} is only a weak ref to the target $object so
# a ConnectProperties never keeps a target object alive.
#
# When $self->{'array'} gets down to just one element (one readable one)
# it'd be possible to discard it as there's nowhere for its "notify" to
# propagate values to.  But maybe an add() could be made to extend an
# existing linkage, in which case would still want that last element.  Maybe
# could go dynamic() style when down to one element, so if nothing else
# cares about the linkage then destroy the lot.
#

sub new {
  my ($class, @array) = @_;
  ### ConnectProperties new()

  if (@array < 2) {
    croak 'ConnectProperties: new() must have two or more object/property pairs';
  }

  # validate property names before making signal connections
  foreach my $elem (@array) {
    my ($object, $pname, @params) = @$elem;

    # for reference ParamSpec demands pname first char [A-Za-z] and then any
    # non [A-Za-z0-9-] crunched by canonical_key() to "-"s
    my $flavour;
    if ($pname =~ /(.*?)#(.*)/) {
      $pname = $2;
      ($flavour = $1) =~ tr/-/_/;
    } else {
      $flavour = 'object';
    }
    my $elem_class = "Glib::Ex::ConnectProperties::Element::$flavour";
    ### $elem_class
    Module::Load::load ($elem_class);

    # replacing element in @array
    $elem = $elem_class->new (object => $object,
                              pname  => $pname,
                              @params);
    $elem->check_property;
  }
  my $self = bless { array => \@array }, $class;
  my $first_readable_elem;

  foreach my $elem (@array) {
    if (my $h = delete $elem->{'hash_in'}) {
      ### hash_in func: "@{[keys %$h]}"
      $elem->{'func_in'} = _make_hash_func ($h);
    }
    if (my $h = delete $elem->{'hash_out'}) {
      ### hash_out func: "@{[keys %$h]}"
      $elem->{'func_out'} = _make_hash_func ($h);
    }

    if (delete $elem->{'bool_not'}) {
      $elem->{'func_in'} =  $elem->{'func_out'} = \&_bool_not;
    }

    Scalar::Util::weaken ($elem->{'object'});

    if (! delete $elem->{'write_only'} && $elem->is_readable) {
      $first_readable_elem ||= $elem;
      $elem->{'self'} = $self;
      $elem->connect_signals;
      Scalar::Util::weaken ($elem);  # the element of $self->{'array'}
    }
  }

  # set initially from first readable, in case not already the same
  if ($first_readable_elem) {
    ### initial propagate
    _do_read_handler ($first_readable_elem->{'object'}, $first_readable_elem);
  }
  return $self;
}

sub dynamic {
  my $self = shift->new(@_);
  foreach my $elem (@{$self->{'array'}}) {
    Scalar::Util::weaken ($elem->{'self'});
  }
  return $self;
}

# For a permanent new() style connection DESTROY is only reached when all
# readable objects are gone already, so there's nothing to disconnect.  But
# a dynamic() is garbage collected with signal connections still present,
# hence an explicit disconnect() here.
#
sub DESTROY {
  my ($self) = @_;
  $self->disconnect;
}

sub disconnect {
  my ($self) = @_;
  my $array = $self->{'array'};
  ### ConnectProperties disconnect: "$self ".scalar(@$array)." elems"
  while (my $elem = pop @$array) {
    $elem->disconnect;
  }
}

my $value_validate_method
  = (
     # Perl-Glib 1.200, value_validate() not wrapped
     ! Glib::ParamSpec->can('value_validate')
     ? sub {
       my ($pspec, $value) = @_;
       return (0,$value); # unmodified, original value, always wantarray
     }

     # Perl-Glib 1.220, value_validate() buggy on non ref counted boxed types
     : ! eval{Glib->VERSION(1.240);1}
     ? sub {
       my ($pspec, $value) = @_;
       my $type = $pspec->get_value_type;
       if ($type->isa('Glib::Boxed') && ! $type->isa('Glib::Scalar')) {
         return (0,$value); # unmodified, original value, always wantarray
       }
       return $pspec->value_validate ($value);
     }

     # Perl-Glib 1.240, value_validate() good
     : 'value_validate');

# 'notify' or read_signal handler from a connected object
sub _do_read_handler {
  my $from_elem = $_[-1];
  my $self = $from_elem->{'self'};

  ### ConnectProperties _do_read_handler: "$self $_[0]/" . ($from_elem->{'pname'} || '[false]')
  ###   notify_in_progress: $self->{'notify_in_progress'}

  if ($self->{'notify_in_progress'}) { return; }
  local $self->{'notify_in_progress'} = 1;

  my $from_val = $from_elem->get_value;
  ###   from_value to propagate: $from_val
  if (my $func = $from_elem->{'func_out'}) {
    $from_val = $func->($from_val);
    ###   func_out becomes: $from_val
  }

  my $array = $self->{'array'};
  for (my $i = 0; $i < @$array; $i++) {
    my ($to_elem, $to_object);

    unless (($to_elem = $array->[$i])
            && ($to_object = $to_elem->{'object'})) {
      ###   elem gone, dropping: $i
      splice @$array, $i--, 1;
      next;
    }
    if ($to_elem == $from_elem         # not ourselves
        || $to_elem->{'read_only'}) {  # forced not write
      next;
    }

    my $to_pspec = $to_elem->find_property
      || do {
        ### no to_pspec (such as no container child property yet, etc)
        next;
      };
    my $to_flags = $to_pspec->get_flags;

    # skip non-writable targets
    ($to_flags & 'writable') || next;

    my $to_val = $from_val;
    if (my $func = $to_elem->{'func_in'}) {
      $to_val = $func->($to_val);
      ###   func_in becomes: $to_val
    }

    # value_validate() to clamp $to_val for $to_pspec
    # value_validate() is wrapped in Glib 1.220, remove the check when ready
    # to demand that version
    # In 1.240 may have to keep a new non ref counted boxed return from
    # func_in() alive if value_validate() makes an alias, hence
    # $to_val_keepalive.
    #
    my $to_val_keepalive = $to_val;
    (undef, $to_val) = $to_pspec->$value_validate_method($to_val);

    # skip if target already contains $to_val, to avoid extra 'notify's
    if ($to_flags & 'readable') {
      if (_pspec_equal ($to_pspec, $to_elem->get_value, $to_val)) {
        ###   suppress already equal: "$to_object/".($to_elem->{'pname'} || '[false]')
        next;
      }
    }

    ###   store to: "$to_object/". ($to_elem->{'pname'} || '[false]')
    $to_elem->set_value ($to_val);
  }

  return $from_elem->{'read_signal_return'};
}

sub _pspec_equal {
  my ($pspec, $x, $y) = @_;

  # Glib::Param::Boxed values_cmp() is only by pointer value, so try to do
  # better by looking for an equal() or compare() method on the value type.
  # This is only for the exact pspec 'Glib::Param::Boxed'.  If you make a
  # subclass for a flavour of boxed object you should implement a values_cmp
  # for everyone to use.
  #
  if (ref $pspec eq 'Glib::Param::Boxed') {
    my $value_type = $pspec->get_value_type;  # string class name

    if (my $func = $value_type->can('Glib_Ex_ConnectProperties_equal')) {
      return $func->($x, $y);
    }

    # Gtk2::Gdk::Region and Gtk2::Gdk::Color have 'equal' (and GdkFont would
    # too but it's not wrapped as of Gtk2 1.221).  Gtk2::TreePath has a
    # 'compare' method.  Those methods don't much like undef (NULL), and
    # presume that other similar methods won't either, so guard against
    # that.
    #
    if (my $func = $value_type->can('equal')) {
      if (! defined $x || ! defined $y) {
        return ((defined $x) == (defined $y)); # undef==undef, else not equal
      }
      return $func->($x, $y);
    }
    if (my $func = $value_type->can('compare')) {
      if (! defined $x || ! defined $y) {
        return ((defined $x) == (defined $y)); # undef==undef, else not equal
      }
      return ($func->($x, $y) == 0);
    }
  }

  # values_cmp() wrapped in Glib 1.220, will remove the fallback when ready
  # to demand that version
  my $func = ($pspec->can('values_cmp')
              || $pspec->can('Glib_Ex_ConnectProperties_values_cmp')
              || croak 'ConnectProperties: oops, where\'s the values_cmp fallback?');
  return ($func->($pspec, $x, $y) == 0);
}

sub _make_hash_func {
  my ($h) = @_;
  ### _make_hash_func()
  ### $h
  if (defined(tied($h))) {
    return sub { $h->{$_[0]} };
  } else {
    return sub { defined $_[0] ? $h->{$_[0]} : undef };
  }
}
sub _bool_not {
  return ! $_[0];
}

#------------------------------------------------------------------------------
# equality refinements for Glib::Param::Boxed
#
# This is just a Glib_Ex_ConnectProperties_equal() func added into the
# package of the applicable type.  Not a documented feature yet.  Might
# prefer paramspec subclasses offering a suitable values_cmp() which
# everyone could use, rather than special stuff here.

# Glib::ParamSpec->scalar just makes a Glib::Param::Boxed so values_cmp is
# by the SV address, which will be almost always different.  Try instead a
# compare by 'eq'.  It won't look into arrays etc, but you probably should
# setup a new ParamSpec type to make that happen properly.
#
sub Glib::Scalar::Glib_Ex_ConnectProperties_equal {
  my ($x, $y) = @_;
  if (! defined $x || ! defined $y) { return ((defined $x) == (defined $y)) }
  return ($x eq $y);
}

# Glib::Strv at the perl level as arrayref of strings, or undef.
# In Gtk2::AboutDialog it's just a Glib::Param::Boxed, compare by value.
#
# undef is not equal to an empty array, the same as GParamSpecValueArray has
# NULL not equal to a zero length array in param_value_array_values_cmp().
# There's probably no difference in actual use though ...
#
sub Glib::Strv::Glib_Ex_ConnectProperties_equal {
  my ($x, $y) = @_;
  if (! defined $x || ! defined $y) { return ((defined $x) == (defined $y)); }
  if (@$x != @$y) { return 0; }
  foreach my $i (0 .. $#$x) {
    if ($x->[$i] ne $y->[$i]) { return 0; }
  }
  return 1;
}

# Gtk2::Gdk::Cursor, by type, with possibly undef
#
sub Gtk2::Gdk::Cursor::Glib_Ex_ConnectProperties_equal {
  my ($x, $y) = @_;
  if (! defined $x || ! defined $y) { return ((defined $x) == (defined $y)); }

  my $xtype = $x->type;
  if ($xtype eq 'cursor-is-pixmap') {
    return $x == $y;  # can't look into pixmap contents
  } else {
    return $xtype eq $y->type;  # standard cursors by type
  }
}

# Gtk2::Border at the perl level is a hashref of fields, or undef.
# In Gtk2::Entry it's just a Glib::Param::Boxed, compare here by values.
# Apart from Gtk2::Entry it's thankfully rare.
#
sub Gtk2::Border::Glib_Ex_ConnectProperties_equal {
  my ($x, $y) = @_;
  if (! defined $x || ! defined $y) { return ((defined $x) == (defined $y)); }

  return ($x->{'left'}      == $y->{'left'}
          && $x->{'right'}  == $y->{'right'}
          && $x->{'top'}    == $y->{'top'}
          && $x->{'bottom'} == $y->{'bottom'});
}

#------------------------------------------------------------------------------
# values_cmp fallback

BEGIN {
  if (! Glib::ParamSpec->can('values_cmp')) {
    no warnings 'once';

    # overall fallback: integers, characters by number; Glib::Object's by ref;
    # Glib::Boxed by value (fairly useless most of the time)
    *Glib::ParamSpec::Glib_Ex_ConnectProperties_values_cmp = sub {
      my ($pspec, $x, $y) = @_;
      if (! defined $x || ! defined $y) { return ((defined $x) <=> (defined $y))}
      return ($x <=> $y);
    };

    # string and enum by alphabetical
    # no Glib::Param::GType since values_cmp() exists whenever that one will ...
    *Glib::Param::String::Glib_Ex_ConnectProperties_values_cmp
      = *Glib::Param::Enum::Glib_Ex_ConnectProperties_values_cmp
        = sub {
          my ($pspec, $x, $y) = @_;
          if (! defined $x || ! defined $y) {
            return ((defined $x) <=> (defined $y));
          }
          return ($x cmp $y);
        };

    # bools allowing any 0, '', undef
    *Glib::Param::Boolean::Glib_Ex_ConnectProperties_values_cmp = sub {
      my ($pspec, $x, $y) = @_;
      return ((! $x) <=> (! $y));
    };

    # double following epsilon
    *Glib::Param::Double::Glib_Ex_ConnectProperties_values_cmp = sub {
      my ($pspec, $x, $y) = @_;
      my $epsilon = $pspec->get_epsilon;
      if ($x < $y) {
        return -($y-$x > $epsilon);
      } else {
        return ($x-$y > $epsilon);
      }
    };

    # float truncated to single precision before comparing, and following epsilon
    *Glib::Param::Float::Glib_Ex_ConnectProperties_values_cmp = sub {
      my ($pspec, $x, $y) = @_;
      ($x, $y) = unpack 'f2', pack ('f2', $x, $y);
      my $epsilon = $pspec->get_epsilon;
      if ($x < $y) {
        return -($y-$x > $epsilon);
      } else {
        return ($x-$y > $epsilon);
      }
    };
  }
}

1;
__END__

=for stopwords Perl-Gtk2 Gtk2 Gtk2-Perl Perl-Gtk2's Perl-Gtk Gtk CheckButton ConnectProperties enum arrayref ParamSpec pspecs Ryde Glib-Ex-ConnectProperties arrayrefs superclass ie stringizing numizing recognises subclasses Eg

=head1 NAME

Glib::Ex::ConnectProperties -- link properties between objects

=for test_synopsis my ($check,$widget);

=head1 SYNOPSIS

 use Glib::Ex::ConnectProperties;
 my $conn = Glib::Ex::ConnectProperties->new
                        ([ $check,  'active' ],
                         [ $widget, 'visible' ]);

 $conn->disconnect;   # explicit disconnect

=head1 DESCRIPTION

C<Glib::Ex::ConnectProperties> links together specified properties on two or
more C<Glib::Object>s (such as Gtk2 widgets etc) so a change made to any one
of them is propagated to the others.

This is an easy way to tie a user control widget to a setting elsewhere.
For example a CheckButton C<active> could be linked to the C<visible> of
another widget, letting the user click to hide or show.

      +--------------------+             +-------------+
      | CheckButton/active |  <------->  | Foo/visible |
      +--------------------+             +-------------+

The advantage of ConnectProperties is that it's bi-directional.  If other
code in the program changes "Foo/visible" then that change is propagated to
"CheckButton/active" too, ensuring the button display shows what it's
controlling no matter how the target changes.  See F<examples/sensitive.pl>
in the Glib-Ex-ConnectProperties sources for a complete program.

=head2 Property Types

The following property types are supported

    string
    number         integer or float
    enum           Glib::Enum subtypes
    flags          Glib::Flags subtypes
    object         Glib::Object
    string array   Glib::Strv
    some boxed     Glib::Boxed

Boxed types which work include C<Gtk2::Gdk::Color> and
C<Gtk2::Gdk::Rectangle>, but others may not.  See L</Equality> below.

Read-only properties can be used.  They're propagated out to the other
linked properties but any changes in those others are not stored back.
Usually this is only useful when the read-only is the only one changing.
You could easily enough make an explicit signal handler to propagate the
value, but a ConnectProperties is convenient and is careful not to make
circular references.  See the C<read_only> option below to force read-only.

Write-only properties can be used.  Nothing is read out of them, they're
just set from changes in the other linked properties.  Write-only properties
are unusual, but see the C<write_only> option below to force write-only.

It works to link properties on the same object.  This can ensure they update
together.  It also works to have different ConnectProperties linkages with
an object/property in common.  A change coming from one group propagates
through to the other.  This arises quite naturally if there's two separate
controls for the same target.

=head2 Property Class Name

A property name can include an explicit class such as C<GtkLabel::justify>
in the usual style of C<set_property()>, C<find_property()>, etc.

    [ $widget, 'GtkLabel::justify' ]   # class name and property name

If a subclass accidentally shadows a superclass property name then this
gives access to the superclass property.  But it's otherwise unnecessary and
is not recommended.  For a Perl subclass like C<My::Foo::Bar> the
fully-qualified name is C<My__Foo__Bar::propname>, as usual for Perl module
to Glib class name conversion.

=head2 Other Settings

Various additional object or widget settings can be accessed by
ConnectProperties.  They're either other flavour properties, or are
non-property attributes which have some sort of signal notifying when they
change.  For example

    child#propname

See the following modules for Gtk related things,

=over

=over

=item L<Glib::Ex::ConnectProperties::Element::child>

=item L<Glib::Ex::ConnectProperties::Element::combobox_active>

=item L<Glib::Ex::ConnectProperties::Element::model_rows>

=item L<Glib::Ex::ConnectProperties::Element::response_sensitive>

=item L<Glib::Ex::ConnectProperties::Element::screen_size>

=item L<Glib::Ex::ConnectProperties::Element::tree_selection>

=item L<Glib::Ex::ConnectProperties::Element::iconview_selection>

=item L<Glib::Ex::ConnectProperties::Element::widget>

=item L<Glib::Ex::ConnectProperties::Element::widget_allocation>

=back

=back

The C<Gtk2> elements don't create a dependency on C<Gtk2> unless you use
them.  The implementation is modular so extras are not loaded unless used.
The C<#> separator character doesn't clash with plain property names as it's
not allowed in a ParamSpec name.

See L<Glib::Ex::ConnectProperties::Element> to create a new element
subclass.

=head1 FUNCTIONS

=head2 Creation

=over 4

=item C<< $conn = Glib::Ex::ConnectProperties->new ([$obj1,$pname1], [$obj,$pname2], ...) >>

Connect two or more given object+property combinations.  The connection
lasts for as long as the objects do.

The return value is a Perl object of type C<Glib::Ex::ConnectProperties>.
It can be kept to later break the connection with C<disconnect()> below,
otherwise it can be ignored.

=item C<< $conn = Glib::Ex::ConnectProperties->dynamic ([$obj1,$pname1], [$obj,$pname2], ...) >>

Connect two or more given object+property combinations.  The return is a
Perl object of type C<Glib::Ex::ConnectProperties>.  The connection lasts
only as long as you keep this returned object.

=back

The arguments to both constructors are arrayrefs with an object, a property
name, and perhaps further options as described below.  For example

    Glib::Ex::ConnectProperties->new
      ([$object1, 'some-propname'],
       [$object2, 'another-propname']);

An initial value is propagated from the first object+property (the first
readable one) to set all the others, if they're not already the same.  So
put the object with the desired initial value first.

A ConnectProperties only keeps weak references to the objects, so the
linkage doesn't prevent some or all of them being garbage collected.

A C<dynamic()> linkage can be used if it's only wanted for a certain time,
or if desired linkages might change and you want to drop an old one and make
a new.  For example something like the following inside a widget or object
would allow a target to be changed, including changed to C<undef> for
nothing linked.

    sub set_target {
      my ($self, $target_object) = @_;
      $self->{'conn'} =
        $target_object
          && Glib::Ex::ConnectProperties->dynamic
                         ([$self,   'my-prop'],
                          [$target, 'target-prop']);
    }

=head2 Operations

=over

=item C<< $conn->disconnect() >>

Disconnect the given ConnectProperties linkage.

C<$conn> can made by either C<new()> and C<dynamic()> above.  A dynamic one
is also disconnected automatically when garbage collected.

=back

=head1 OPTIONS

Various key/value options can be given in each C<[$object,$propname]>
element.  For example,

    Glib::Ex::ConnectProperties->new
        ([$checkbutton, 'active'],
         [$label, 'sensitive', bool_not => 1]);

=head2 General Options

=over

=item C<< read_only => $bool >>

Treat the property as read-only, ignoring any C<writable> flag in its
ParamSpec.  This is probably of limited use, but might for instance on an
output-only or to stop other properties writing back to a master control.
See F<examples/unidirectional.pl> in the Glib-Ex-ConnectProperties sources
for a complete program.

=item C<< write_only => $bool >>

Treat the property as write-only, ignoring any C<readable> flag in its
ParamSpec.

This can be used for display things such as a C<Gtk2::Label> which you want
to set, but don't want to read back.  If the value is mangled for display
(see L<Value Transformations> below) then there might be no easy reverse
transformation to read back anyway.

    Glib::Ex::ConnectProperties->new
        ([$job, 'status'],
         [$label, 'text', write_only => 1]);

Of course an explicit signal handler can do a one-way set like this, but
ConnectProperties is a fewer lines of code.

=item C<< read_signal => $signame >>

Connect to C<$signame> to see changes to the property.  The default is the
notify signal as C<notify::$propname> which means a property change is
immediately seen and propagated.  A different signal can be used to do it at
other times instead.

For example on a C<Gtk2::Entry> the C<text> property notifies for every
character typed by the user.  Using the C<activate> signal instead you can
take the value only when the user presses Return.

    Glib::Ex::ConnectProperties->new
        ([$entry, 'text', read_signal => 'activate'],
         [$label, 'text']);

The signal can have any parameters (which are all ignored currently).
Usually the only sensible signals are those like C<activate> which are some
sort of user action.

=item C<< read_signal_return => $signame >>

The return value for the C<read_signal> handler above.  The default return
is C<undef>.

Generally the signals which are useful for triggering a read have no return
value (ie. C<void>), so no particular return is needed.  But for example if
a widget event handler was a good time to look at a property then a return
of C<Gtk2::EVENT_PROPAGATE> would generally be wanted to let other handlers
see the event too.

    Glib::Ex::ConnectProperties->new
        ([$widget, 'window',
          read_signal => 'map-event',
          read_signal_return => Gtk2::EVENT_PROPAGATE ],
         [$drawing_thing, 'target-window']);

=back

=head2 Value Transformations

Storing a value goes through the following steps,

=over

=item 1.

Value transformations specified in the element, if any.

=item 2.

C<value_validate()> of the target ParamSpec (in Glib-Perl 1.220 where that
method is available).

=item 3.

Equality check, if the target is readable, to avoid a C<set_property()> if
it's already what's desired (see L</Equality> below).

=item 4.

C<set_property()>

=back

C<value_validate()> does things like clamp numbers outside the ParamSpec
min/max, perhaps manipulate string contents, etc.  This at least gives
something which can be stored.

Perl's usual value coercing such as stringizing, numizing, truncating
integers, etc, applies to the C<value_validate()> call and the
C<set_property()> call, in the usual way.  This means string properties can
be linked to number properties or similar with no special transformations.

In the following options the "in" transformations are for storing and the
"out" for reading.  C<func> is the most general.  C<hash> is handy for a
fixed set of possible values.

=over

=item C<< bool_not => 1 >>

Negate with the Perl C<!> operator.  For example a check button which when
checked makes a label insensitive,

    Glib::Ex::ConnectProperties->new
        ([$checkbutton, 'active'],
         [$label, 'sensitive', bool_not => 1]);

=item C<< func_in => $coderef >>

=item C<< func_out => $coderef >>

Call C<< $value = &$coderef($value) >> to transform values going in or
coming out.  (See F<examples/func-transform.pl> in the
Glib-Ex-ConnectProperties sources for a complete program doing this.)

=item C<< hash_in => $hashref >>

=item C<< hash_out => $hashref >>

Apply C<< $value = $hashref->{$value} >> to transform values going in or
coming out.

If a C<$value> doesn't exist in the hash then the result will be C<undef> in
the usual way.  Various tied hash modules can change that in creative ways,
for example C<Hash::WithDefaults> to look in fallback hashes.

The hashes are not copied, so future changes to their contents will be used,
though there's nothing to forcibly update property values if current
settings might be affected.

See F<examples/hash-transform.pl> in the Glib-Ex-ConnectProperties sources
for a complete program using hash transforms.

=back

For a read-write property the "in" should generally be the inverse of "out".
Nothing is done to enforce that, but strange things are likely to happen if
the two are inconsistent.

A read-only property only needs an "out" transformation and a write-only
property only needs an "in" transformation, including when the C<read_only>
or C<write_only> options above force that (L</General Options>).

=head1 IMPLEMENTATION NOTES

ConnectProperties uses a C<notify> signal handler on each object to update
the others.  Updating those others causes them to emit their own further
C<notify> signals (even if the value is unchanged), so some care must be
taken not to have an infinite loop.  The present strategy is

=over 4

=item *

An "in progress" flag in the ConnectProperties object, so during an update
it recognises that any further C<notify> emissions as its own doing and can
be ignored.

=item *

On each target the value from a C<get> is compared before doing a C<set>.
If already right then the C<set> call is not made at all.

=back

The in-progress flag acts against immediate further C<notify>s.  This could
also be done by temporarily disconnecting or blocking the handlers, but that
seems more work than ignoring.

Compare-before-set copes with C<freeze_notify()> because in that case the
C<notify> calls don't come while the "in progress" flag is on, only later,
perhaps a long time later.

If the C<func_in> / C<func_out> transformations are inconsistent, so that a
value going in is always different from what comes out, then usually the "in
progress" case prevents an infinite loop, as long as the program eventually
reaches a state with no C<freeze_notify> in force.

It might be wondered if something simpler is possible.  For the general case
no, not really.  The specific C<set_foo()> methods on most widgets and
objects often notice an unchanged setting and do nothing, but when using the
generic C<set_property()> the protection above is needed.

=head2 Equality

An existing value and prospective new value are compared using
C<values_cmp()> in Glib-Perl 1.220 or a fallback otherwise.  For example in
C<Glib::Param::Double> anything within "epsilon" (1e-90 by default) is close
enough.  C<values_cmp()> lets ParamSpec subclasses control what they
consider equal.

The core C<Glib::Param::Boxed> only compares by pointer value, which is
fairly useless since boxed objects are frequently copied so you probably
don't have an identical pointer.  ConnectProperties tries to improve this
by:

=over

=item *

C<equal()> or C<compare()> method from the value type when available.  This
covers C<Gtk2::Gdk::Color>, C<Gtk2::Gdk::Region> and C<Gtk2::TreePath>.

=item *

C<Glib::Strv> compared by string contents.

=item *

C<Gtk2::Border> compared by field values.

=item *

C<Gtk2::Gdk::Cursor> compared by C<type>, though bitmap cursors are still
only by pointer.

=item *

C<Glib::Scalar> compared with C<eq>.  This may be of limited help and it's
probably better to subclass C<Glib::Param::Scalar> and make a type-specific
C<values_cmp>, if/when that's possible.

=back

C<Glib::Param::Object> pspecs could perhaps benefit from using an C<equal()>
or C<compare()> method on the object the same as for boxed objects.  But
usually when setting a C<Glib::Object> it's a particular object which is
desired, not just contents.  If that's not so then as with C<Glib::Scalar>
it could be handled by a ParamSpec subclass with a C<values_cmp()> to
express when different objects are equal enough.  If/when possible that
would work for both C code and Perl code comparisons.

=head2 Object Implementation

When writing an object or widget (per L<Glib::Object::Subclass>) don't
forget to explicitly C<notify> if changing a property outside a
C<SET_PROPERTY()>.  For example,

    sub set_foo {
      my ($self, $newval) = @_;
      if ($self->{'foo'} != $newval) {
        $self->{'foo'} = $newval;
        $self->notify('foo');
      }
    }

This sort of C<notify> is necessary in any object or widget implementation.
Failing to do so will mean ConnectProperties doesn't work, and probably
other things too.  A C<SET_PROPERTY()> can call out to a setter function
like the above to re-use code.  In that case Glib collapses the C<notify()>
there to just one notify at the end of C<SET_PROPERTY()>.

=head1 SEE ALSO

L<Glib::Object>,
L<Glib::ParamSpec>,
L<Glib::Boxed>

L<Gtk2>,
L<Glib::Ex::TieProperties>

L<Tie::Wx::Widget>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-connectproperties/index.html>

=head1 LICENSE

Copyright 2007, 2008, 2009, 2010, 2011, 2012 Kevin Ryde

Glib-Ex-ConnectProperties is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3, or (at your option) any
later version.

Glib-Ex-ConnectProperties is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General
Public License for more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-ConnectProperties.  If not, see L<http://www.gnu.org/licenses/>.

=cut
