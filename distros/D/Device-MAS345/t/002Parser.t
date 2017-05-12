######################################################################
# Test suite for Device::MAS345
# by Mike Schilli <cpan@perlmeister.com>
######################################################################

use warnings;
use strict;

package Simulator;
use base qw( Device::MAS345 );

sub new {
    bless {}, shift;
}

sub read_raw {
    my($self) = @_;
    return $self->{simulator_data};
}

sub raw_set {
    my($self, $value) = @_;
    $self->{simulator_data} = $value;
}

package main;

use Test::More;
use Device::MAS345;
use Log::Log4perl qw(:easy);

plan tests => 6;

my $mas = Simulator->new( port => "/dev/ttyS0" );

$mas->raw_set("TE 23.45 C");
my($val, $unit, $mode) = $mas->read();
is($mode, "TE",   "mode");
is($val,  "23.45", "numeric value");
is($unit, "C", "unit");

$mas->raw_set("OH  211.4kOhm.");
($val, $unit, $mode) = $mas->read();
is($mode, "OH",   "ohm mode");
is($val, "211.4", "numeric value");
is($unit, "kOhm", "unit");
