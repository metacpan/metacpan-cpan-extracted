#!/usr/bin/env perl
use strict;
use warnings;
use Mojo::Util qw(dumper);
use 5.018;

my $string = '[H3C-object-policy-ip-tttt]dis this
#
object-policy ip tttt
 rule 8 pass source-ip 16.33.56.76 destination-ip 10.11.11.12 service ftp
 rule 1 pass source-ip 16.33.60.54 destination-ip 10.1.1.11.1 service ssh
 rule 55 pass source-ip 18.33.4.4 destination-ip 18.22.22.22
 rule 3 pass source-ip 16.33.44.55 destination-ip 10.23.45.6 service ftp
 rule 3 append destination-ip 10.11.11.12
 rule 56 pass source-ip 16.33.56.78 destination-ip 10.11.11.12 service https
#
return
[H3C-object-policy-ip-tttt]';

if ( $string =~ /rule\s+(?<ruleId>\d+)\s+pass[^\n]+\n\s*#/si ) {
  say $+{ruleId};

}
else {
  say "not match";
}

