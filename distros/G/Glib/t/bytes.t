#!/usr/bin/perl

#
# Test the GBytes wrappers.
#

use strict;
use warnings;
use Glib;
use Test::More;

unless (Glib -> CHECK_VERSION (2, 32, 0)) {
  plan skip_all => 'GBytes is new in 2.32';
} else {
  plan tests => 13;
}

# Basic API.
my $data = pack 'C*', 0..255;

my $bytes = Glib::Bytes->new ($data);
isa_ok ($bytes, 'Glib::Bytes');
isa_ok ($bytes, 'Glib::Boxed');

is ($bytes->get_size, length $data);
is ($bytes->get_data, $data);

ok (defined $bytes->hash);
ok ($bytes->equal ($bytes));
is ($bytes->compare ($bytes), 0);

# Overloading.
is ("$bytes", $data, '"" overloading');
ok ($bytes eq $data, 'eq overloading');
is (length $bytes, length $data, 'length overloading');

# Wide characters.
eval {
  my $wstring = "\x{2665}";
  my $bytes = Glib::Bytes->new ($wstring);
};
like ($@, qr/Wide character/);

eval {
  my $wstring = "\x{2665}";
  utf8::encode ($wstring);
  my $bytes = Glib::Bytes->new ($wstring);
  is ($bytes->get_data, pack ('C*', 0xE2,0x99,0xA5));
};
is ($@, '');
