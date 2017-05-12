#!perl

use 5.010;
use strict;
use warnings;

use Getopt::Long::Negate::ID qw(
                                   negations_for_option
                     );
use Test::More 0.98;

is_deeply([negations_for_option('tak-foo')], ['foo']);
is_deeply([negations_for_option('tidak-foo')], ['foo']);
is_deeply([negations_for_option('bukan-foo')], ['foo']);

is_deeply([negations_for_option('dengan_foo')], ['tanpa_foo']);
is_deeply([negations_for_option('tanpa-foo')], ['dengan-foo']);

is_deeply([negations_for_option('adalah-foo')], ['bukan-foo']);
is_deeply([negations_for_option('ialah-foo')], ['bukan-foo']);

is_deeply([negations_for_option('matikan-foo')], ['hidupkan-foo']);
is_deeply([negations_for_option('padamkan-foo')], ['nyalakan-foo']);
is_deeply([negations_for_option('hidupkan_foo')], ['matikan_foo']);
is_deeply([negations_for_option('nyalakan_foo')], ['padamkan_foo']);

is_deeply([negations_for_option('izinkan-foo')], ['larang-foo']);
is_deeply([negations_for_option('ijinkan-foo')], ['larang-foo']);
is_deeply([negations_for_option('bolehkan-foo')], ['larang-foo']);
is_deeply([negations_for_option('perbolehkan-foo')], ['larang-foo']);
is_deeply([negations_for_option('larang_foo')], ['izinkan_foo']);

is_deeply([negations_for_option('foo')], ['tak-foo']);

DONE_TESTING:
done_testing;
