#!/usr/bin/perl -w
# Test file for GMail::Checker

use strict;
use Test;
use GMail::Checker;

BEGIN {plan tests => 2}

my $gwrapper = new GMail::Checker();
my ($size, $unit) = $gwrapper->getsize(10000000);

ok (defined ($gwrapper) and (ref $gwrapper), 'new() is ok');
ok (($size == 9.5367431640625) and ($unit eq "Mbytes"), 'getsize() is ok');

# Testers with gmail account can use these tests, modify the test number to 4.

#$gwrapper->login("username","password");
#ok (defined($gwrapper->{SOCK}) and ($gwrapper->{USERNAME} ne '') and ($gwrapper->{PASSWORD} ne ''), 'login() ok');
#my $uidl = $gwrapper->get_uidl(MSG => 1);
#ok (($uidl =~ /[\x21-\x7E]+/) or ($uidl == -1), 'uidl() ok');

exit;
__END__
