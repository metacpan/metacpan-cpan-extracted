# Copyright 2010, 2011, 2012, 2014 Kevin Ryde

# This file is part of Glib-Ex-ObjectBits.
#
# Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Glib-Ex-ObjectBits.  If not, see <http://www.gnu.org/licenses/>.

package Glib::Ex::EnumBits;
use 5.008;
use strict;
use warnings;
use Carp;

# uncomment this to run the ### lines
#use Smart::Comments;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(to_display
                    to_display_default
                    to_description);

our $VERSION = 16;

sub to_display {
  my ($enum_class, $nick) = @_;
  ### EnumBits to_display(): "$enum_class $nick"

  if (@_ != 2) {
    croak 'EnumBits to_display() wrong number of arguments';
  }
  if (my $coderef = $enum_class->can('EnumBits_to_display')) {
    ### $coderef
    if (defined (my $str = $enum_class->$coderef($nick))) {
      return $str;
    }
  }
  if (defined (my $str = do {
    no strict 'refs';
    ${"${enum_class}::EnumBits_to_display"}{$nick}
  })) {
    return $str;
  }
  return to_display_default ($enum_class, $nick);
}

sub to_display_default {
  my ($enum_class, $nick) = @_;
  ### EnumBits to_display_default(): $nick

  if (@_ != 2) {
    # it's easy to forget the $enum_class parameter, guard against that ...
    croak 'EnumBits to_display_default() wrong number of arguments';
  }
  
  if ($nick =~ /^([-_ ]+)$/) {
    # consists entirely of separators, eg "--"
    # preserve something non-empty
    $nick =~ s/^\s+//; # leading whitespace
    $nick =~ s/\s+$//; # trailing whitespace
    return $nick;
  }

  my $str = join (' ',
                  map {ucfirst}
                  split(/[-_ ]+
                       |(?<=[^[:upper:][:digit:]])(?=\d)     # before a digit
                       |(?<=\d)(?=\D)        # after a digit
                       |(?<=[[:lower:]])(?=[[:upper:]])
                       |(?<=[[:upper:]])(?=[[:upper:]][[:lower:]])
                        /x,
                        $nick));
  if (defined $enum_class
      && defined (my $textdomain = do {
        no strict 'refs';
        ${"${enum_class}::EnumBits_textdomain"}
      })
      && Locale::Messages->can('dgettext')) {
    $str = Locale::Messages::dgettext ($textdomain, $str);
  }
  return $str;
}

sub to_description {
  my ($enum_class, $nick) = @_;
  if (@_ < 2) {
    croak "Not enough arguments for EnumBits to_description()";
  }
  if (my $coderef = $enum_class->can('EnumBits_to_description')) {
    return $enum_class->$coderef($nick);
  }
  return undef;
}

1;
__END__

# # cf g_enum_get_value_by_name() and g_enum_get_value_by_nick()
# sub to_nick {
#   my ($enum_class, $value) = @_;
#   if (my $h = to_info ($enum_class, $value)) {
#     return $h->{'nick'};
#   } else {
#     return undef;
#   }
# }
# 
# sub to_info {
#   my ($enum_class, $value) = @_;
#   my @info = Glib::Type->list_values($enum_class);
#   foreach my $h (@info) {
#     if ($value eq $h->{'name'}
#         || $value eq $h->{'nick'}) {
#       return $h;
#     }
#   }
#   if (looks_like_number($value)) {
#     foreach my $h (@info) {
#       if ($value == $h->{'value'}) {
#         return $h;
#       }
#     }
#   }
#   return undef;
# }

=for stopwords Ryde enum Enum Glib tooltip Glib-Ex-ObjectBits

=head1 NAME

Glib::Ex::EnumBits -- misc Glib enum helpers

=head1 SYNOPSIS

 use Glib::Ex::EnumBits;

=head1 FUNCTIONS

=head2 Display

=over

=item C<< $str = Glib::Ex::EnumBits::to_display ($enum_class, $nick) >>

Return a string to display C<$nick> from C<$enum_class>.  This is meant to
be suitable for a menu, label, etc.

C<$enum_class> is a class name such as C<"Glib::UserDirectory">.  A class
method and hash are consulted, otherwise C<to_display_default()> below is
used.  That default is often enough.

If C<$enum_class> has a C<< $enum_class->EnumBits_to_display ($nick) >>
method then it's called and if the values is not C<undef> then it's used.
For example,

    Glib::Type->register_enum ('My::Things',
                               'foo', 'bar-ski', 'quux');
    sub My::Things::EnumBits_to_display {
      my ($class, $nick) = @_;
      return "some thing $nick";
    }

Or if the class has a C<%EnumBits_to_display> package variable then it's
checked and if the hash value is not C<undef> then it's used,

    Glib::Type->register_enum ('My::Things',
                               'foo', 'bar-ski', 'quux');
    %My::Things::EnumBits_to_display = ('foo'     => 'Food',
                                        'bar-ski' => 'Barrage');

In a program (rather than a module) setting the variable this way might
provoke a "used only once" warning (see L<perldiag>).  Use C<no warnings
'once'>, or C<package> and C<our>,

    {
      package My::Things;
      Glib::Type->register_enum (__PACKAGE__, 'foo', 'bar');
      our %EnumBits_to_display = ('foo' => 'Oof');
    }

C<package> style like this can be handy if setting up a C<to_description()>
below too.

=item C<< $str = Glib::Ex::EnumBits::to_display_default ($enum_class, $nick) >>

Return a string form for value C<$nick> from C<$enum_class>.  The nick is
split into words and numbers and C<ucfirst()> applied to each word.  So for
example

    "some-val1" -> "Some Val 1"

The C<$enum_class> parameter is not currently used, but it's the same as
C<to_display()> above and might be used in the future for better default
mangling.  C<$enum_class> can be C<undef> to crunch a C<$nick> from an
unknown enum.

=back

=head2 Description

=over

=item C<< $str = Glib::Ex::EnumBits::to_description ($enum_class, $nick) >>

Return a string description of value C<$nick> from C<$enum_class>, or
C<undef> if nothing known.  This is meant to be a long form perhaps for a
tooltip etc.

If C<$enum_class> has a C<< $enum_class->EnumBits_to_description ($nick) >>
method then it's called,

    Glib::Type->register_enum ('My::Things',
                               'foo', 'bar-ski', 'quux');
    sub My::Things::EnumBits_to_description {
      my ($class, $nick) = @_;
      return "Long text about $nick";
    }

Or if the class has a C<%EnumBits_to_description> hash table that it's used,

    Glib::Type->register_enum ('My::Things',
                               'foo', 'bar-ski', 'quux');
    %My::Things::EnumBits_to_description =
      ('foo'     => 'Some foo for thought',
       'bar-ski' => 'Horizontal line segment');

=back

=head1 EXPORTS

Nothing is exported by default, but the functions can be requested in usual
C<Exporter> style,

    use Glib::Ex::EnumBits 'to_display_default';
    print to_display_default($class, $nick), "\n";

There's no C<:all> tag since this module is meant as a grab-bag of functions
and to import as-yet unknown things would be asking for name clashes.

=head1 SEE ALSO

L<Glib>,
L<Glib::Type>,
L<Gtk2::Ex::ComboBox::Enum>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/glib-ex-objectbits/index.html>

=head1 LICENSE

Copyright 2010, 2011, 2012, 2014 Kevin Ryde

Glib-Ex-ObjectBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Glib-Ex-ObjectBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Glib-Ex-ObjectBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
