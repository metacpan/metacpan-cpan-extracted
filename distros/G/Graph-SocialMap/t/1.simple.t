#!/usr/bin/perl

use Test::More qw(no_plan);
use Graph::SocialMap;

# Key:   relation name
# Value: list of involved people.

#
# Peacock - Marry - Rose - Joan
#
#           Gugod - Autrijus
#

my $relation = {
    1357 => [qw/Marry Rose/],
    3579 => [qw/Marry Peacock/],
    2468 => [qw/Joan/],
    4680 => [qw/Rose Joan/],
    OSSF => [qw/Gugod Autrijus/],
};

my $gsm = Graph::SocialMap->new(relation => $relation);

# wop = weight of person
my $wop = $gsm->wop;

ok(1 == $wop->{Gugod});
ok(1 == $wop->{Autrijus});
ok(1 == $wop->{Peacock});
ok(2 == $wop->{Rose});
ok(2 == $wop->{Joan});
ok(2 == $wop->{Marry});

# dos = degree of seperation

ok(0 == $gsm->dos('Marry','Marry'));
ok(0 == $gsm->dos('Rose','Rose'));
ok(0 == $gsm->dos('Joan','Joan'));
ok(0 == $gsm->dos('Peacock','Peacock'));
# 10

ok(2 == $gsm->dos('Marry','Joan'));
ok(2 == $gsm->dos('Joan','Marry'));
ok(2 == $gsm->dos('Rose','Peacock'));
ok(2 == $gsm->dos('Peacock','Rose'));
ok(1 == $gsm->dos('Gugod','Autrijus'));
ok(1 == $gsm->dos('Autrijus','Gugod'));
ok(3 == $gsm->dos('Joan','Peacock'));
ok(3 == $gsm->dos('Peacock','Joan'));

# Not connected
ok(0 > $gsm->dos('Gugod','Marry'));
ok(0 > $gsm->dos('Marry','Gugod'));

