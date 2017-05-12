package Game::Life::NDim;

# Created on: 2010-01-04 18:52:01
# Create by:  Ivan Wills
# $Id$
# $Revision$, $HeadURL$, $Date$
# $Revision$, $Source$, $Date$

use Moose;
use warnings;
use version;
use Carp;
use Scalar::Util;
use List::Util qw/sum/;
#use List::MoreUtils;
use Data::Dumper qw/Dumper/;
use English qw/ -no_match_vars /;
use Game::Life::NDim::Board;

use overload '""' => \&to_string;

our $VERSION     = version->new('0.0.4');
our @EXPORT_OK   = qw/game_of_life/;
our %EXPORT_TAGS = ();

has board => (
    is       => 'rw',
    isa      => 'Game::Life::NDim::Board',
    required => 1,
);

has rules => (
    is       => 'rw',
    isa      => 'ArrayRef',
    default  => sub {[]},
);

sub game_of_life {
    my %params = @_;

    my $board = Game::Life::NDim::Board->new(%params);
    die "Where's my wrap? " . Dumper \%params, $board if $params{wrap} && !$board->wrap;
    my %new = (board => $board);
    $new{types} = $params{types} if $params{types};

    return __PACKAGE__->new(%new);
}

sub add_rule {
    my ($self, @rules) = @_;

    while (@rules) {
        my $rule = shift @rules;
        if (ref $rule eq 'CODE') {
            push @{ $self->rules }, $rule;
        }
        else {
            my $value = shift @rules;
            push @{ $self->rules },
                  $rule eq 'live' ? sub {  $_[0] ? undef : ( sum $_[0]->surround ) > $value ? 1 : undef }
                : $rule eq 'die'  ? sub { !$_[0] ? undef : ( sum $_[0]->surround ) < $value ? 0 : undef }
                :                   die "The rule \"$rule\" is unknown\n";
        }
    }

    return $self;
}

sub process {
    my ($self) = @_;

    while ( defined ( my $life = $self->board->next_life() ) ) {
        $life->process($self->rules);
    }

    return $self;
}

sub set {
    my ($self) = @_;

    while ( defined ( my $life = $self->board->next_life() ) ) {
        $life->set();
    }

    return $self;
}

sub to_string {
    my ($self) = @_;

    return $self->board->to_string();
}

1;

__END__

=head1 NAME

Game::Life::NDim - Infrastructure for playing Conway's game of life with support for multiple cell types and 2D or 3D boards.

=head1 VERSION

This documentation refers to Game::Life::NDim version 0.0.4.

=head1 SYNOPSIS

   use Game::Life::NDim;

   # Brief but working code example(s) here showing the most common usage(s)
   # This section will be as far as many users bother reading, so make it as
   # educational and exemplary as possible.


=head1 DESCRIPTION

TODO

=head1 SUBROUTINES/METHODS

=head2 Exportable Functions

=head2 C<game_of_life ( %params )>

=head2 Class Methods

=head3 C<new ( %params )>

Param: C<dims> - array of ints - The dimensions of the game (in zero based form ie [1,1] for a 2x2 board

Param: C<rand> - bool - If true sets the board with random life types

Param: C<types> - hash ref - List of types (keys) and their relative likely hood to be found default {0=> ,1=> }

=head2 Object Methods

=head3 C<add_rule ( )>

=head3 C<process ()>

=head3 C<set ()>

=head3 C<to_string ()>

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

There are no known bugs in this module.

Please report problems to Ivan Wills (ivan.wills@gmail.com).

Patches are welcome.

=head1 AUTHOR

Ivan Wills - (ivan.wills@gmail.com)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010 Ivan Wills (14 Mullion Close, Hornsby Heights, NSW Australia 2077).
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. See L<perlartistic>.  This program is
distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

=cut
