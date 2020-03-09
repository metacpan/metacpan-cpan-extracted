#!/usr/bin/perl -w

# Copyright 2010, 2014 Kevin Ryde

# This file is part of I18N-Langinfo-Wide.
#
# I18N-Langinfo-Wide is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3, or (at your option) any later
# version.
#
# I18N-Langinfo-Wide is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License along
# with I18N-Langinfo-Wide.  If not, see <http://www.gnu.org/licenses/>.

use strict;
use warnings;


{
  # cf /etc/locale.gen or locale -a
  $! = 9;
  print $!,"\n";
  require POSIX;
  delete $ENV{'LANGUAGE'}; # ='fr';
  delete $ENV{'LC_ALL'};
  delete $ENV{'LC_MESSAGES'};
  delete $ENV{'LANG'};

  print POSIX::setlocale(POSIX::LC_ALL(),'de_DE'),"\n";
  print POSIX::setlocale(POSIX::LC_MESSAGES(),'de_DE'),"\n";
  print POSIX::setlocale(POSIX::LC_MESSAGES()),"\n";

#   foreach my $i (1 .. 100) {
#     $! = $i;
#     if ("$!" =~ /[^[:ascii:]]/) {
#       print "$i\n";
#     }
#   }

  print POSIX::strerror(4),"\n";
  $! = 4;
  my $ext = "$^E";
  print $!,"\n";
  print "$ext\n";
  print "ext utf8 ",(utf8::is_utf8($ext)+0),"\n";

#   require Locale::Messages;
#   print Locale::Messages::dgettext('libc',"Bad file descriptor"),"\n";
  exit 0;
}

{
  require POSIX;
  POSIX::setlocale (POSIX::LC_ALL(), 'ja_JP');

  require I18N::Langinfo;
  print "ALT_DIGITS defined: ",defined(&I18N::Langinfo::ALT_DIGITS)?"yes":"no","\n";
  print "can('ALT_DIGITS'): ",I18N::Langinfo->can('ALT_DIGITS')?"yes":"no","\n";
  print "call ALT_DIGITS: ",I18N::Langinfo::ALT_DIGITS(),"\n";
  print "langinfo(ALT_DIGITS): '",I18N::Langinfo::langinfo(I18N::Langinfo::ALT_DIGITS()),"'\n";
  print "langinfo(ERA): '",I18N::Langinfo::langinfo(I18N::Langinfo::ERA()),"'\n";


#   $_ = I18N::Langinfo::ABDAY_1();
#   print I18N::Langinfo::langinfo(),"\n";
  exit 0;
}

{
  require Encode;
  foreach (Encode->encodings(':all')) { print; print "\n"; }

  print "with :all\n";
  require Encode;
  foreach (Encode->encodings(':all')) { print; print "\n"; }

  print "alias: ", Encode::resolve_alias("646"), "\n";

  exit 0;
}

exit 0;
