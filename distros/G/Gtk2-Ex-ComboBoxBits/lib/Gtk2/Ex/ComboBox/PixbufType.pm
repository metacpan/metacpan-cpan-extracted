# Copyright 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-ComboBoxBits.
#
# Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 3, or (at your option) any
# later version.
#
# Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with Gtk2-Ex-ComboBoxBits.  If not, see <http://www.gnu.org/licenses/>.



# for-pixbuf-save ?
# insensitive or omit ?
#                   Glib::ParamSpec->object
#                   ('for-pixbuf-save',
#                    'for-pixbuf-save',
#                    'Blurb.',
#                    'Gtk2::Gdk::Pixbuf',
#                    Glib::G_PARAM_READWRITE),
#   if ($pname eq 'for_pixbuf_save') {
#     Scalar::Util::weaken ($self->{$pname});
#   }
#     my $pixbuf = $self->{'for_pixbuf_save'};
# ,
#              ($pixbuf ? ($pixbuf->get_width, $pixbuf->get_height) : ())

# writable =>
# exclude_read_only =>
# include-read-only ?

# always-select ?

# set_active_from_filename

# alphabetical ?

# type or active-type ?
# active-format ?

# $ptypecombo->order_first ('png', 'jpeg')
# $ptypecombo->order_last ('ico')


package Gtk2::Ex::ComboBox::PixbufType;
use 5.008;
use strict;
use warnings;
use Carp;
use Gtk2;
use Scalar::Util;
use List::Util qw(max);
use POSIX ();
use Gtk2::Ex::ComboBoxBits;
use Gtk2::Ex::PixbufBits 38;  # v.38 for type_supports_size()

# uncomment this to run the ### lines
#use Smart::Comments;

our $VERSION = 32;

if (0) {
  # These are the type names as of Gtk 2.20, extend if there's more and
  # want to translate their names.
  #
  # TRANSLATORS: These format names are localized in case a non-Latin script
  # ought to be shown instead, or as well.  Latin script languages will
  # probably leave all unchanged as that should make them easiest for the
  # user identify, even if a literal translation would result in a different
  # abbreviation.
  __('ANI');
  __('BMP');
  __('GIF');
  __('ICNS');
  __('ICO');
  __('JPEG');
  __('JPEG2000');
  __('PCX');
  __('PNG');
  __('PNM');
  __('QTIF');
  __('RAS');
  __('SVG');
  __('TGA');
  __('TIFF');
  __('WBMP');
  __('WMF');
  __('XBM');
  __('XPM');
}

use Glib::Object::Subclass
  'Gtk2::ComboBox',
  signals => { notify => \&_do_notify },
  properties => [ Glib::ParamSpec->string
                  ('active-type',
                   'Active pixbuf type',
                   'Gdk Pixbuf file save format, such as "png".',
                   (eval {Glib->VERSION(1.240);1}  
                    ? undef # default
                    : ''),  # no undef/NULL before Perl-Glib 1.240
                   Glib::G_PARAM_READWRITE),

                  Glib::ParamSpec->int
                  ('for-width',
                   'for-width',
                   'Only show file formats which support this width.',
                   0, POSIX::INT_MAX(),
                   0,
                   Glib::G_PARAM_READWRITE),
                  Glib::ParamSpec->int
                  ('for-height',
                   'for-height',
                   'Only show file formats which support this height.',
                   0, POSIX::INT_MAX(),
                   0,
                   Glib::G_PARAM_READWRITE),

                ];

use constant { _COLUMN_TYPE    => 0,   # arg string for gdk_pixbuf_save()
               _COLUMN_DISPLAY => 1,   # translated display string
             };

sub INIT_INSTANCE {
  my ($self) = @_;

  my $renderer = Gtk2::CellRendererText->new;
  $renderer->set (ypad => 0);
  $self->pack_start ($renderer, 1);
  $self->set_attributes ($renderer, text => _COLUMN_DISPLAY);

  $self->set_model (Gtk2::ListStore->new ('Glib::String', 'Glib::String'));
  _update_model($self);
}

sub GET_PROPERTY {
  my ($self, $pspec) = @_;
  my $pname = $pspec->get_name;
  ### ComboBox-PixbufType GET_PROPERTY: $pname

  if ($pname eq 'active_type') {
    my $iter;
    return (($iter = $self->get_active_iter)
            && $self->get_model->get_value ($iter, _COLUMN_TYPE));
  }
  # $pname eq 'for_width' or 'for_height' integers
  return $self->{$pname} || 0;
}

sub SET_PROPERTY {
  my ($self, $pspec, $newval) = @_;
  my $pname = $pspec->get_name;
  ### ComboBox-PixbufType SET_PROPERTY: $pname, $newval

  if ($pname eq 'active_type') {
    # because _COLUMN_TYPE==0
    Gtk2::Ex::ComboBoxBits::set_active_text ($self, $newval);
    ### active num now: $self->get_active
  } else {
    $self->{$pname} = $newval;
    _update_model($self);
  }
}

# 'notify' class closure
sub _do_notify {
  my ($self, $pspec) = @_;
  if ($pspec->get_name eq 'active') {
    $self->notify ('active-type');
  }
}

# Gtk2::Gdk::Pixbuf->$get_formats_method
# being either get_formats() or a fallback enough for the formats
# examinations below.  The fallback includes an 'is_writable' to use the
# smaller _is_writable().
#
my $get_formats_method
  = (Gtk2::Gdk::Pixbuf->can('get_formats') # new in Gtk 2.2
     ? 'get_formats'
     : sub { return ({ name => 'png',
                       is_writable => 1},
                     { name => 'jpeg',
                       is_writable => 1 }) });

# _is_writable($format) returning bool
#
*_is_writable =
  (exists((Gtk2::Gdk::Pixbuf->$get_formats_method)[0]->{'is_writable'})
   ?
   # 'is_writable' field, new in Perl-Gtk 1.240
   sub {
     my ($format) = @_;
       ### _is_writable() using field
       ### $format
     return $format->{'is_writable'};
   }
   : do {
     # Perl-Gtk 1.222 and earlier hard coded
     #
     my %is_writable = (png  => 1, # Gtk 2.0 and 2.2
                        jpeg => 1,

                        (Gtk2->check_version(2,4,0)  # 2.4.0 for ico saving
                         ? () : (ico => 1)),

                        (Gtk2->check_version(2,8,0)  # 2.8.0 for bmp saving
                         ? () : (bmp => 1)),

                        (Gtk2->check_version(2,10,0) # 2.10.0 for tiff saving
                         ? () : (tiff =>  1)),
                       );
     sub {
       my ($format) = @_;
       ### _is_writable() using fallback
       ### $format
       return $is_writable{$format->{'name'}};
     }
   });

sub _update_model {
  my ($self) = @_;
  ### PixbufType _update_model()

  my $for_width  = max (1, $self->get('for-width'));
  my $for_height = max (1, $self->get('for-height'));
  my @types =
    grep {Gtk2::Ex::PixbufBits::type_supports_size($_,$for_width,$for_height)}
      map {$_->{'name'}}
        grep {_is_writable($_)}
          Gtk2::Gdk::Pixbuf->$get_formats_method;

  # eg. 'png' => 'PNG'
  my %display = map { $_ => uc($_) } @types;

  # translated descriptions
  if (eval { require Locale::Messages }) {
    foreach my $type (@types) {
      $display{$type} = Locale::Messages::dgettext ('Gtk2-Ex-ComboBoxBits',
                                                    uc($display{$type}));
    }
  }

  # alphabetical by translated description
  @types = sort { $display{$a} cmp $display{$b} } @types;

  my $type = $self->get('active-type');
  my $model = $self->get_model;
  $model->clear;
  foreach my $type (@types) {
    ### $type
    ### display: $display{$type}
    $model->set ($model->append,
                 _COLUMN_TYPE,    $type,
                 _COLUMN_DISPLAY, $display{$type});
  }

  # preserve existing setting
  $self->set (active_type => $type);
}

1;
__END__

=for stopwords Gtk Gtk2 Perl-Gtk combobox ComboBox Gdk Pixbuf Gtk
writability png jpeg ico bmp programmatically

=head1 NAME

Gtk2::Ex::ComboBox::PixbufType -- combobox for Gdk Pixbuf file format types

=head1 SYNOPSIS

 use Gtk2::Ex::ComboBox::PixbufType;
 my $ptypecombo = Gtk2::Ex::ComboBox::PixbufType->new;

=head1 WIDGET HIERARCHY

C<Gtk2::Ex::ComboBox::PixbufType> is a subclass of
C<Gtk2::ComboBox>,

    Gtk2::Widget
      Gtk2::Container
        Gtk2::Bin
          Gtk2::ComboBox
            Gtk2::Ex::ComboBox::PixbufType

=head1 DESCRIPTION

A C<PixbufType> combobox displays file format types available for
C<Gtk2::Gdk::Pixbuf>.

    +------+
    | PNG  |
    +------+
      ...

The C<active-type> property is the type displayed and updated with the
user's selection, eg "png".

Currently the types shown are the writable formats in alphabetical order.
Writability is checked in C<Gtk2::Gdk::PixbufFormat> under new enough
Perl-Gtk2 (some time post 1.223), or for older Perl-Gtk2 there's a
hard-coded list of "png", "jpeg", "tiff", "ico" and "bmp" (less any not
applicable under an older Gtk).

=head1 FUNCTIONS

=over 4

=item C<< $ptypecombo = Gtk2::Ex::ComboBox::PixbufType->new (key=>value,...) >>

Create and return a new combobox object.  Optional key/value pairs set
initial properties as per C<< Glib::Object->new >>.  For example,

 my $ptypecombo = Gtk2::Ex::ComboBox::PixbufType->new
                    (active_type => 'png');

=back

=head1 PROPERTIES

=over 4

=item C<active-type> (string or C<undef>, default C<undef>)

The format type selected in the ComboBox.  This is the user's combobox
choice, or setting it programmatically changes that choice.

The value is a format type name string such as "png", as in the C<name>
field of C<Gtk2::Gdk::PixbufFormat> and as taken by C<< $pixbuf->save >>.

There's no default for C<active-type>, just as there's no default for the
ComboBox C<active>.  When creating a PixbufType combobox a desired initial
selection can be set.  "png" or "jpeg" are always available.

=item C<for-width> (integer 0 up, default 0)

=item C<for-height> (integer 0 up, default 0)

Show only those file format types which support an image of this size.  For
example "ico" format only goes up to 255x255, so if C<for-width> and
C<for-height> are 300x150 then ico is not offered.  The default size 0 means
no size restriction.

These properties are C<int> type the same as Pixbuf width/height.

=back

=head1 SEE ALSO

L<Gtk2::ComboBox>,
L<Gtk2::Ex::ComboBox::Enum>

=head1 HOME PAGE

L<http://user42.tuxfamily.org/gtk2-ex-comboboxbits/index.html>

=head1 LICENSE

Copyright 2010, 2011 Kevin Ryde

Gtk2-Ex-ComboBoxBits is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by the
Free Software Foundation; either version 3, or (at your option) any later
version.

Gtk2-Ex-ComboBoxBits is distributed in the hope that it will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
more details.

You should have received a copy of the GNU General Public License along with
Gtk2-Ex-ComboBoxBits.  If not, see L<http://www.gnu.org/licenses/>.

=cut
