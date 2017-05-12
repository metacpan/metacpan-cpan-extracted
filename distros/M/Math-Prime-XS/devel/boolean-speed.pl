#!/usr/bin/perl -w

use 5.004;
use Benchmark 'cmpthese';
use boolean 'true', 'false';

print "true ",true(),"\n";
print "false ",false(),"\n";

my $yes = !0;
sub yes () { $yes };

my $non = !1;
sub non () { $non }

cmpthese(1000000, {
                   yes => sub { (! yes()) && die },
                   true => sub { (! true()) && die },
                  });

cmpthese(1000000, {
                   yes => sub { yes() || die },
                   true => sub { true() || die },
                  });

cmpthese(1000000, {
                   non => sub { non() && die },
                   false => sub { false() && die },
                  });

exit 0;
