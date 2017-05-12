use strict;
use warnings;

use Test::More qw(no_plan);
use Data::Dumper;
use List::MoreUtils qw(uniq);
use Time::HiRes qw(time);

BEGIN { use_ok('Graph::PetriNet') };

{
    package My::Place::TimeDepend;
#   use Class::Trait qw(Graph::PetriNet::PlaceAble);

    sub new {
	my $class = shift;
	my $object = shift;
	my $last_mod = shift;
	return bless { object => $object, last_mod => $last_mod }, $class;
    }
    sub last_mod {
	my $self = shift;
	return $self->{last_mod};
    }
    sub touch {
	my $self = shift;
	use Time::HiRes qw(time);
	$self->{last_mod} = time;
    }
}

{
    package My::Transition::TimeDepend;
    use Class::Trait (
	'Graph::PetriNet::TransitionAble' => {
	    exclude => [ 'ignitable', 'ignite' ] });

    sub new {
	my $class = shift;
	my $cmd   = shift;
	return bless { command => $cmd }, $class;
    }

    sub ignitable {
	my $self = shift;
	my $oldest;                                          # undef is safe place to start
	foreach my $out (@{ $self->{_out_places} }) {        # look for youngest (largest last_mod)
	    my $t = $out->last_mod;
	    $oldest = $t if !defined $oldest or $t < $oldest;
	}
	foreach my $in (@{ $self->{_in_places} }) {          # now find any input which is younger than
	    return 1 if $in->last_mod > $oldest;             # ... the oldest output
	}
	return 0;
    }

    sub ignite {
	my $self = shift;
	$self->execute;                                       # do some computation
	foreach my $out (@{ $self->{_out_places} }) {         # set all out timestamps to now
	    $out->touch;
	}
    }
    sub execute {
	my $self = shift;
#	warn "EXECUTE CDM ".$self->{command};
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

my $t = time;
my %places      = map { $_ => new My::Place::TimeDepend ($_, $t) }    # all have identical time
	          uniq
                  map { @{ $_->{sources} }, $_->{target}  }
	          @ops;

#warn Dumper \%places; exit;

my %transitions = map { join ("+", @{ $_->{sources} }) . ' '.$_->{op}.' '.$_->{target}
                        =>
                        [ new My::Transition::TimeDepend ( join ("+", @{ $_->{sources} }) . ' '.$_->{op}.' '.$_->{target} ),
			  [ map { $places{$_} } @{ $_->{sources} } ],
			  [ map { $places{$_} }  ( $_->{target} )  ] ] }
	          @ops;

#warn Dumper \%transitions; exit;

my $pn = new Graph::PetriNet (places      => \%places,
			      transitions => \%transitions,
			      );
map {ok (time - 2 < $places{$_}->last_mod && $places{$_}->last_mod < time + 2, "init lastmod" )} keys %places;

#warn Dumper [ keys %transitions];

sleep 1;
map { $_->touch } $pn->things ('x');
is_deeply ([ $pn->ignitables ], [ 'x > a' ], 'ignitables: x > a');

$pn->ignite;
is_deeply ([ $pn->ignitables ], [ 'a+b > c' ], 'ignitables: a+b > c');
$pn->ignite;
is_deeply ([ $pn->ignitables ], [ 'c > d' ], 'ignitables: c > d');
$pn->ignite;
is_deeply ([ $pn->ignitables ], [ 'd > e' ], 'ignitables: d > e');
$pn->ignite;
is_deeply ([ $pn->ignitables ], [  ], 'ignitables: none');



#warn Dumper $pn;
#warn Dumper $pn; exit;
#warn Dumper [ $pn->ignitables ]; exit;

__END__




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
