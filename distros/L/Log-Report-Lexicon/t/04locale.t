#!/usr/bin/env perl
# test locale

use Test::More;
use POSIX;
use locale;

my $alt_locale;
BEGIN  {
   eval "POSIX->import( qw/setlocale :locale_h/ )";

   # locale disabled?
   defined setlocale(LC_ALL, 'C')
       or plan skip_all => "no translation support in Perl or OS";

 LOCALE:
   foreach my $l (qw/nl_NL de_DE pt_PT tr_TR/)  # only non-english!
   {   foreach my $c ('utf-8', 'iso-8859-1', '')
       {   $alt_locale = $c ? "$l.$c" : $l;
           my $old = setlocale LC_ALL, $alt_locale;
           my $set = setlocale LC_ALL, $alt_locale;

           last LOCALE
               if defined $set && $set eq $alt_locale;
       }
       undef $alt_locale;
   }

   defined $alt_locale
       or plan skip_all => "cannot find alternative language for tests";

   plan tests => 10;
}

ok(1, "alt locale: $alt_locale");

ok(defined setlocale(LC_ALL, 'C'), 'set C');

my $try = setlocale(LC_ALL);
ok(defined $try, 'explicit C found');
ok($try eq 'C' || $try eq 'POSIX');

$! = 2;
my $err_posix = "$!";
ok(defined $err_posix, $err_posix);  # english

my $change = setlocale LC_ALL, $alt_locale;
ok(defined $change, "returned change to alternative locale");

is(setlocale(LC_ALL), $alt_locale, "set to $alt_locale successful?");
$! = 2;
my $err_alt = "$!";
ok(defined $err_alt, $err_alt);

if($err_posix eq $err_alt)
{   # some platforms have mistakes in their language configuration
    ok(1, "ERROR: libc translations not switched");
    warn "*** ERROR: changing language of libc error messages did not work\n";
    sleep 1;
}
else
{    ok(1, "libc does translate standard errors");
}

setlocale(LC_ALL, 'C');
$! = 2;
my $err_posix2 = "$!";
is($err_posix, $err_posix2, $err_posix2);
