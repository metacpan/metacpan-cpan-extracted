use strict;
use warnings;

use Test::More qw(no_plan);
use Data::Dumper;
use List::MoreUtils qw(uniq);


BEGIN { use_ok('Graph::PetriNet') };

{
    package My::Place;
#    use Class::Trait qw(Graph::PetriNet::PlaceAble);

    sub new {
	my $class = shift;
	return bless {}, $class;
    }
}

{
    package My::Transition;
#    use Class::Trait qw(Graph::PetriNet::TransitionAble);

    sub new {
	my $class = shift;
	return bless { }, $class;
    }

}


my @ops = (
    { sources => [ 'a', 'b' ],
      op      => '>',
      target  => 'c' },
    { sources => [ 'c' ],
      op      => '>',
      target  => 'd' },
    { sources => [ 'y' ],
      op      => '>',
      target  => 'b' },
    { sources => [ 'x' ],
      op      => '>',
      target  => 'a' },
    { sources => [ 'd' ],
      op      => '>',
      target  => 'e' },
    );

my %places      = map { $_ => new My::Place }
	          uniq
                  map { @{ $_->{sources} }, $_->{target}  }
	          @ops;

#warn Dumper \%places;

my %transitions = map { join ("+", @{ $_->{sources} }) . ' '.$_->{op}.' '.$_->{target}
                        =>
                        [ new My::Transition, [ map { $places{$_} } @{ $_->{sources} } ],
				              [ map { $places{$_} }  ( $_->{target} )  ] ] }
	          @ops;

#warn Dumper \%transitions;

# internal test (not really testing the package here)
#$places{x}->tokens (1);
#is ($places{x}->tokens, 1, 'x has token');


my $pn = new Graph::PetriNet (places      => \%places,
			      transitions => \%transitions,
			      initialize  => 1);
map {is ($places{$_}->tokens, 0, "init token" )} keys %places;

is_deeply ([ sort keys %places ],
	   [ sort $pn->places ],                                            'found all place labels');
is_deeply ([ sort keys %transitions ],
	   [ sort $pn->transitions ],                                       'found all place labels');


is_deeply ([ $pn->things ('x', 'y', 'a') ], [ @places{qw(x y a)} ],    'found places');

{
    my ($tr) =  $pn->things ('c > d');
    is_deeply ($tr->{_in_places},  [ $places{c} ], 'transition: in');
    is_deeply ($tr->{_out_places}, [ $places{d} ], 'transition: out');
}


map { $_->tokens (1) } $pn->things ('x');
is_deeply ([ $pn->ignitables ], [ 'x > a' ], 'ignitables');

$pn->ignite;
map {is ($places{$_}->tokens, $_ eq 'a' ? 1 : 0, "ignition 1: $_ token" )} keys %places;

$pn->ignite;
map {is ($places{$_}->tokens, $_ eq 'c' ? 1 : 0, "ignition 2: $_ token" )} keys %places;

$pn->ignite;
map {is ($places{$_}->tokens, $_ eq 'd' ? 1 : 0, "ignition 3: $_ token" )} keys %places;

$pn->ignite;
map {is ($places{$_}->tokens, $_ eq 'e' ? 1 : 0, "ignition 4: $_ token" )} keys %places;

$pn->ignite;
map {is ($places{$_}->tokens, $_ eq 'e' ? 1 : 0, "ignition 5: $_ token" )} keys %places;

$pn->reset;
map {is ($places{$_}->tokens,                 0, "reset     : $_ token" )} keys %places;


$places{x}->tokens (1);
$places{y}->tokens (2);
is_deeply ([ sort $pn->ignitables ], [ 'x > a', 'y > b' ], 'ignitables');
$pn->ignite;
map {is ($places{$_}->tokens, $_ =~ /a|b|y/ ? 1 : 0, "ignition 6: $_ token" )} keys %places;
$pn->ignite;
map {is ($places{$_}->tokens, $_ =~ /c|b/   ? 1 : 0, "ignition 7: $_ token" )} keys %places;
$pn->ignite;
map {is ($places{$_}->tokens, $_ =~ /c|d/   ? 1 : 0, "ignition 8: $_ token" )} keys %places;
$pn->ignite;
map {is ($places{$_}->tokens, $_ =~ /d|e/   ? 1 : 0, "ignition 9: $_ token" )} keys %places;
$pn->ignite;
map {is ($places{$_}->tokens, $_ =~ /e/     ? 2 : 0, "ignition 10: $_ token" )} keys %places;

is_deeply ([ $pn->ignitables ], [  ], 'no ignitables');


__END__

warn Dumper $pn->things ('x');

$pn->add (
          map { $_->{sources}, join ("+", @{ $_->{sources} }) . ' '.$_->{op}.' '.$_->{target}, [ $_->{target} ] }
          @ops);
