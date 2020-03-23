use strict;
use warnings;
use EAV::XS;
use Test::More tests => 1;


my $eav;

eval {
    $eav = EAV::XS->new('tld_check');
};

ok (! $eav && $@ =~ /odd number of elements/);
