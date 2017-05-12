package Games::Dice::Roll20;
use strict;
use warnings;

use Moo;
use Parse::RecDescent;
use Games::Dice::Roll20::Dice;
use POSIX qw(ceil floor);

our $VERSION = '0.03';

has mock => (
    is      => 'rw',
    clearer => 'unmock',
    isa     => sub {
        return unless defined $_[0];
        my $type = ref $_[0];
        die "Argument to mock has to be an array, hash or code reference."
          if $type !~ '^(CODE|HASH|ARRAY)$';
    }
);

## grammar stolen from https://github.com/agentzh/perl-parsing-library-benchmark

my $grammar = q{

    {
        my %valid_functions = (
            ceil  => \&POSIX::ceil,
            floor => \&POSIX::floor,
            abs   => \&POSIX::abs,

            ## to be consistent with roll20 is use the floor + 0.5 method
            ## instead of Math::Random.

            round => sub { POSIX::floor( $_[0] + 0.50000000000008 ) },
        );

        my $function_re = join( '|', keys %valid_functions );
    }

    expr: <leftop: term add_op term>
    {
        $return = Games::Dice::Roll20::_reduce_list( @{ $item[1] } )
    }

    add_op: /[+-]/

    term: <leftop: call mul_op call>
    {
        $return = Games::Dice::Roll20::_reduce_list( @{ $item[1] } )
    }

    mul_op: /[*\/]/

    call: /$function_re/o '(' expr ')'
        {
            $return = $valid_functions{ $item[1] }->( $item[3] );
        }
         | atom


    atom:
          dice
        | number
        | '(' <commit> expr ')'  { $return = $item{expr} }
        | <error?> <reject>

    number: /[-+]?\d+(?:\.\d+)?/

    dice: count 'd' sides modifiers[sides => $item{sides}](s?)
    {
        $return = Games::Dice::Roll20::Dice->new(
            amount     => $item{count}->[0],
            sides      => $item{sides},
            mock       => $arg{dice_obj}->mock,
            modifiers  => { map { @{$_} } @{ $item{'modifiers(s?)'} } },
        );
    }

    modifiers:   compounding
               | penetrating
               | exploding
               | successes_and_failures
               | keep_and_drop
               | rerolling(s?)
                 {
                    $return =
                      @{ $item[1] }
                      ? [ 'rerolling', [ map { $_->[0] } @{ $item[1] } ] ]
                      : undef;
                 }

    rerolling: 'r' ('o')(?) compare_point(s?)
    {
        $return =
          [ $item[3]->[0] ? $item[3]->[0] : [ '=', 1 ] ];
        push @{ $return->[0] }, $item[2]->[0];
    }

    keep_and_drop:   'kh' int { $return = [ 'keep_highest' => $item[2] ] }
                   | 'kl' int { $return = [ 'keep_lowest'  => $item[2] ] }
                   | 'k'  int { $return = [ 'keep_highest' => $item[2] ] }
                   | 'dh' int { $return = [ 'drop_highest' => $item[2] ] }
                   | 'dl' int { $return = [ 'drop_lowest'  => $item[2] ] }
                   | 'd'  int { $return = [ 'drop_lowest'  => $item[2] ] }

    successes_and_failures: successes failures(s?)
    {
        $return = [ successes => $item[1], failures => $item[2]->[0] ]
    }

    successes: compare_point

    failures: 'f' compare_point

    compounding: '!!' compare_point(s?)
    {
        $return =
          [ $item[0], $item[2]->[0] ? $item[2]->[0] : [ '=', $arg{sides} ] ]
    }

    penetrating: '!p' compare_point(s?)
    {
        $return = [
            $item[0], 1,
            'exploding', $item[2]->[0] ? $item[2]->[0] : [ '=', $arg{sides} ]
          ]
    }

    exploding: '!' compare_point(s?)
    {
        $return =
          [ $item[0], $item[2]->[0] ? $item[2]->[0] : [ '=', $arg{sides} ] ]
    }

    compare_point:   '<' int { [@item[1,2]] }
                   | '=' int { [@item[1,2]] }
                   | '>' int { [@item[1,2]] }
                   |     int { ['=',$item[1]] }

    count:   '(' expr ')' { $return = [$item[2]] }
           | int(s?)

    sides:   '(' expr ')' { $return = $item[2] }
           | int
           | 'F'

    int: /\d+/
};

my $parser = Parse::RecDescent->new($grammar);

sub roll {
    my ( $self, $spec ) = @_;
    return $parser->expr( $spec, 0, dice_obj => $self );
}

sub _reduce_list {
    my (@list) = @_;
    my $sum = shift(@list);
    while (@list) {
        my ( $op, $term ) = splice( @list, 0, 2 );
        if ( $op eq '+' ) { $sum += $term; }
        elsif ( $op eq '-' ) { $sum -= $term }
        elsif ( $op eq '*' ) { $sum *= $term }
        elsif ( $op eq '/' ) { $sum /= $term }
    }
    return $sum;
}

1;

__END__

=pod

=for HTML <a href="https://travis-ci.org/mdom/Games-Dice-Roll20"><img src="https://travis-ci.org/mdom/Games-Dice-Roll20.svg?branch=master"></a>

=for HTML <a href='https://coveralls.io/r/mdom/Games-Dice-Roll20?branch=master'><img src='https://coveralls.io/repos/mdom/Games-Dice-Roll20/badge.png?branch=master' alt='Coverage Status' /></a>

=head1 NAME

Games::Dice::Roll20 - Simulate dice rolls with Roll20's syntax

=head1 SYNOPSIS

  my $dice = Games::Dice::Roll20->new();
  say $dice->roll('3d20+5');
  say $dice->roll('d6*10+d6');
  say $dice->roll('10d6rk4>5');

=head1 DESCRIPTION

Games::Dice::Roll20 simulates dice rolls by using a syntax familiar to players
of role playing games. In contrast to many similar projects it does not only
support simple constructs like I<2d6+4> but aims to simulate complex dice
mechanics like exploding, re-rolling and keeping and dropping high or low dice.
It should be a almost complete implementation of the dice specification by
L<Roll20|https://wiki.roll20.net/Dice_Reference>. The supported features and
deviations from this specifications are listed in L<our own
specification|https://github.com/mdom/Games-Dice-Roll20/blob/master/lib/Games/Dice/Roll20/Spec.pod>.

=head1 METHODS

=head2 roll

  my $result = $dice->roll('3d20+5');

Parse the provided dice expression and returns the results as
integer. Returns undef if the expression can't be parsed.

=head1 COPYRIGHT AND LICENSE

Copyright 2015 Mario Domgoergen C<< <mario@domgoergen.com> >>

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.
=cut
