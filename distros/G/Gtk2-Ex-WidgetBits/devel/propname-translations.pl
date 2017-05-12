#!/usr/bin/perl -w

# Copyright 2009, 2010, 2011 Kevin Ryde

# This file is part of Gtk2-Ex-WidgetBits.
#
# Gtk2-Ex-WidgetBits is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# Gtk2-Ex-WidgetBits is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;
use Gtk2;
use FindBin;
use Storable;
use Module::Util;
use Locale::Messages;
use Module::Load;

my $tempfile = '/tmp/propname-translations.tmp';

sub pname_is_superclass {
  my ($class, $pname) = @_;
  no strict 'refs';
  foreach my $superclass (@{"${class}::ISA"}) {
    if ($superclass->can('find_property')
        && $superclass->find_property($pname)) {
      return 1;
    }
  }
  return 0;
}

if (! @ARGV) {

  my @props;
  foreach my $class (Module::Util::find_in_namespace ('Gtk2::Ex'),
                     Module::Util::find_in_namespace ('Glib::Ex'),
                     grep {/Gtk2::Ex/} Module::Util::find_in_namespace ('App'),
                    ) {
    Module::Load::load ($class);
    if (! eval {
      1;
    }) {
      print "Cannot load $class: $@";
      next;
    }
    if (! $class->isa('Glib::Object')) {
      # print "$class not an object\n";
      next;
    }
    my @list;
    if (! eval { @list = $class->list_properties }) {
      print "$@";
      next;
    }

    foreach my $pspec (@list) {
      my $pname = $pspec->get_name;
      next if pname_is_superclass($class,$pname);
      push @props, [ $class, $pname, $pspec->get_nick ];
    }
  }
  print "total pspecs ",scalar(@props),"\n";
  store \@props, $tempfile;

  foreach my $filename (glob '/usr/share/locale/*/LC_MESSAGES/gtk20-properties.mo') {
    $filename =~ m{locale/([^/]+)};
    my $lang = $1;
    print "lang $lang\n";
    # $ENV{'LANG'} = 'fr;
    $ENV{'LANGUAGE'} = $lang;
    print "perl $0 file\n";
    system "perl $0 file";
  }

} else {
  print "$tempfile\n";
  my $props = retrieve($tempfile);
  # print "total pspecs ",scalar(@$props),"\n";
  foreach my $elem (@$props) {
    my ($class, $pname, $raw_nick) = @$elem;
    Module::Load::load ($class);

    my $pspec = $class->find_property($pname);
    my $pspec_nick = $pspec->get_nick;

    my $trans_nick = Locale::Messages::dgettext('gtk20-properties',$raw_nick);
    if ($pspec_nick ne $trans_nick) {
      print "$class $pname $raw_nick\n";
    }
  }
}

exit 0;
