#!/usr/bin/env perl -w
use strict;
use Test;
BEGIN { plan tests => 7 }

my $language;
foreach $language  ("de_iso8859_1","fi","fr","ja_JP.EUC","ru","uk","hu") {
    print STDERR $language," ";
    my $kit  = "FAQ/OMatic/Language_".$language . ".pm";
    my $func = "FAQ::OMatic::Language_" . $language . "::translations";
   eval {
       require $kit; import $kit qw(translations);
   };
   my $tx = {};
   translations($tx);
   undef &translations;
   ok(1);
}
exit;
__END__
