#!/usr/bin/env perl
use Game::EnergyLoop;
use Object::Pad;
class Foo {
    field $name :param;
    field $energy :param;
    field $priority :param :reader;
    field $cur_energy = 0;
    method enlo_energy ( $new = undef ) {
        $cur_energy = $new if defined $new;
        return $cur_energy;
    }
    method enlo_update( $value, $epoch ) {
        print "$epoch RUN $name ($priority) $value\n";
        return $energy;
    }
}
sub pri { @{$_[0]} = sort {$b->priority <=> $a->priority} @{$_[0]} }
my @obj = map {
    Foo->new(
        name     => "N$_",
        energy   => ( 1 + int rand 8 ),
        priority => int rand 2,
    )
} 1 .. 3;
my $epoch = 0;
for ( 1 .. 10 ) {
    $epoch += Game::EnergyLoop::update( \@obj, \&pri, $epoch );
}
