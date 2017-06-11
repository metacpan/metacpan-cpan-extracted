#!/usr/bin/env perl
use warnings;
use strict;
use JSON::Create;
package Funky::Monkey::Baby; sub new {return bless {};} 1;
package main;
my $jc = JSON::Create->new ();
$jc->obj (
    'Funky::Monkey::Baby' => sub {
	die "There is no such thing as a funky monkey baby";
    },
);
eval {
    $jc->run ({fmb => Funky::Monkey::Baby->new ()});
};
if ($@) {
    print "$@\n";
}
