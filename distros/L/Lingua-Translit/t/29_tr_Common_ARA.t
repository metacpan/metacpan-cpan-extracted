use strict;
use Test::More tests => 3;

my $name        =   "Common ARA";
my $reversible  =   0;

my $input       =   "اخبار اليوم"; # "News Today"
my $output_ok   =   "akhbar alywm";

my $udohr       =   "يولد جميع الناس أحراراً متساوين في الكرامة والحقوق، " .
                    "وقد وهبوا عقلاً وضميراً وعليهم أن يعامل بعضهم بعضاً " .
                    "بروح الإخاء.";
my $udohr_ok    =   "ywld jmy'e alnas ahrara mtsawyn fy alkramh walhqwq, " .
                    "wqd whbwa 'eqla wdmyra w'elyhm an y'eaml b'edhm " .
                    "b'eda brwh alekha'.";

use Lingua::Translit;

my $tr = Lingua::Translit->new( $name );


my $output = $tr->translit( $input );

# 1
is( $tr->can_reverse(), $reversible, "$name: reversibility" );

# 2
is( $output, $output_ok, "$name: transliteration (short)" );

$output = $tr->translit( $udohr );

# 3
is( $output, $udohr_ok, "$name: transliteration (UDOHR)" );

# vim: set sts=4 sw=4 ts=4 ai et ft=perl:
