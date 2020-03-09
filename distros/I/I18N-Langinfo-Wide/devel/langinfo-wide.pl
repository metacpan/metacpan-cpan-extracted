# Copyright 2009, 2011 Kevin Ryde

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

use I18N::Langinfo ();
use I18N::Langinfo::Wide;
use POSIX;

binmode STDOUT, ':utf8' or die;
binmode STDERR, ':utf8' or die;

my $loc = POSIX::setlocale(POSIX::LC_ALL());
print "Locale = $loc\n";
my $set = 'fr_FR';
$set = 'en_GB';
$set = 'ar_IN';
$set = 'ja_JP';
$ENV{'LANGUAGE'} = $set;
# $ENV{'LANG'} = 'en_IN';
# $ENV{'LC_ALL'} = 'en_IN';
# $ENV{'LC_ALL'} = 'en_IN';
$loc = POSIX::setlocale(POSIX::LC_ALL(), $set);
print "Locale = $loc\n";

$loc = POSIX::setlocale(POSIX::LC_MESSAGES());
print "Locale = $loc\n";

sub hstr {
  my ($str) = @_;
  if (! defined $str) { print "str undef\n"; return; }
  print "len ",length($str)," '$str'";
  foreach my $i (0 .. length($str)-1) {printf " %02X", ord(substr($str,$i,1))}
  print "\n";
}

{
  sub dd {
    my ($key) = @_;
    my $func = "I18N::Langinfo::$key";
    my $keyval = eval { no strict 'refs'; &$func() };
    if (! defined $keyval) { printf "%-30s undef\n", $key; return; }
    my (@strs) = I18N::Langinfo::langinfo($keyval);
    printf "%-10s %#X %d count=%d ", $key, $keyval, scalar @strs;
    foreach my $str (@strs) { hstr ($str); }
    my $str = I18N::Langinfo::Wide::langinfo($keyval);
    print "  wide "; hstr($str);
  }
  dd("ALT_DIGITS");
  dd("P_CS_PRECEDES");
  foreach my $key (sort @I18N::Langinfo::EXPORT_OK) {
    dd ($key);
  }
  exit 0;
}

{
  my $uni = "\x{3007}"; #\x{4E00}\x{4E8C}\x{4E09}";
  print "uni "; hstr ($uni);
  my $charset = I18N::Langinfo::langinfo(I18N::Langinfo::CODESET());
  print $charset,"\n";
  my $euc = Encode::encode ($charset, $uni, Encode::FB_CROAK());
  print "euc "; hstr ($euc);
  $uni = Encode::decode ($charset, $euc, Encode::FB_CROAK());
  print "back "; hstr ($uni);
}

