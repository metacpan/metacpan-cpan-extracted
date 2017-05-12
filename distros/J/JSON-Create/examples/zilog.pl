#!/home/ben/software/install/bin/perl
use warnings;
use strict;
use JSON::Create;
my $jc = JSON::Create->new ();
package Zilog::Z80;
sub new { return bless { memory => '64 kbytes' }; }
sub to_json {
    my ($self) = @_;
    return '"I can address as many as '.$self->{memory}.' of memory"';
}
1;
package main;
my $zilog = Zilog::Z80->new ();
my %stuff = (zilog => $zilog);
print $jc->run (\%stuff), "\n";
# Set up our object's method for printing JSON.
$jc->obj (
    'Zilog::Z80' => \& Zilog::Z80::to_json,
);
print $jc->run (\%stuff), "\n";
