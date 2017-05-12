use strict;
use Test::More tests => 7;
use Encode qw/decode/;


my $name        = "Common DEU";


# Taken from http://www.unhchr.ch/udhr/lang/ger.htm
my $input       = "Alle Menschen sind frei und gleich an Würde und " .
                  "Rechten geboren. Sie sind mit Vernunft und Gewissen " .
                  "begabt und sollen einander im Geist der " .
                  "Brüderlichkeit begegnen.";
my $output_ok   = "Alle Menschen sind frei und gleich an Wuerde und " .
                  "Rechten geboren. Sie sind mit Vernunft und Gewissen " .
                  "begabt und sollen einander im Geist der " .
                  "Bruederlichkeit begegnen.";

my $ext         =   "ÄÖÜäöüß";
my $ext_out_ok  =   "AeOeUeaeoeuess";

my $all_caps    =   "MAßARBEIT -- Spaß";
my $all_caps_ok =   "MASSARBEIT -- Spass";


use Lingua::Translit;

my $tr = new Lingua::Translit($name);


my $output = $tr->translit($input);

# 1
is($tr->can_reverse(), 0, "$name: not reversible");

# 2
is($output, $output_ok, "$name: UDOHR transliteration");

$output    = $tr->translit(decode("UTF-8", $input));

# 3
is($output, $output_ok, "$name: UDOHR transliteration (decoded)");


my $ext_output = $tr->translit($ext);

# 4
is($ext_output, $ext_out_ok, "$name: umlauts and sz-ligature");

$ext_output    = $tr->translit(decode("UTF-8", $ext));

# 5
is($ext_output, $ext_out_ok, "$name: umlauts and sz-ligature (decoded)");


my $o = $tr->translit($all_caps);

# 6
is($o, $all_caps_ok, "$name: all caps");

$o    = $tr->translit(decode("UTF-8", $all_caps));

# 7
is($o, $all_caps_ok, "$name: all caps (decoded)");

# vim: sts=4 sw=4 ai et ft=perl
