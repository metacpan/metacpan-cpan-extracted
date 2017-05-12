#!/bin/echo This is a perl module and should not be run

package Meta::Chess::State;

use strict qw(vars refs subs);
use Meta::Chess::Board qw();
use Meta::Chess::Side qw();
use Meta::Chess::Tuple qw();

our($VERSION,@ISA);
$VERSION="0.18";
@ISA=qw(Meta::Chess::Board);

#sub new($);
#sub add_piece_insane($$$$$);
#sub set_to_move($$);
#sub start_game($);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)=Meta::Chess::Board->new();
	bless($self,$class);
	return($self);
}

sub add_piece_insane($$$$$) {
	my($self,$side,$piece,$x,$y)=@_;
	my($tuple)=Meta::Chess::Tuple->new();
	$tuple->set($side,$piece,$x,$y);
	$self->get_side_pieces($side)->insert($tuple);
	$self->get_type_pieces($side,$piece)->insert($tuple);
	$self->set_elem($x,$y,$tuple);
}

sub set_to_move($$) {
	my($self,$side)=@_;
	$self->{TO_MOVE}=Meta::Chess::Side->new();
	$self->{TO_MOVE}->set($side);
}

sub start_game($) {
	my($self)=@_;
	$self->add_piece_insane("White","Pawn",0,1);
	$self->add_piece_insane("White","Pawn",1,1);
	$self->add_piece_insane("White","Pawn",2,1);
	$self->add_piece_insane("White","Pawn",3,1);
	$self->add_piece_insane("White","Pawn",4,1);
	$self->add_piece_insane("White","Pawn",5,1);
	$self->add_piece_insane("White","Pawn",6,1);
	$self->add_piece_insane("White","Pawn",7,1);
	$self->add_piece_insane("White","Rook",0,1);
	$self->add_piece_insane("White","Knight",1,1);
	$self->add_piece_insane("White","Bishop",2,1);
	$self->add_piece_insane("White","King",3,1);
	$self->add_piece_insane("White","Queen",4,1);
	$self->add_piece_insane("White","Bishop",5,1);
	$self->add_piece_insane("White","Knight",6,1);
	$self->add_piece_insane("White","Rook",7,1);
	$self->add_piece_insane("Black","Pawn",0,6);
	$self->add_piece_insane("Black","Pawn",1,6);
	$self->add_piece_insane("Black","Pawn",2,6);
	$self->add_piece_insane("Black","Pawn",3,6);
	$self->add_piece_insane("Black","Pawn",4,6);
	$self->add_piece_insane("Black","Pawn",5,6);
	$self->add_piece_insane("Black","Pawn",6,6);
	$self->add_piece_insane("Black","Pawn",7,6);
	$self->add_piece_insane("Black","Rook",0,7);
	$self->add_piece_insane("Black","Knight",1,7);
	$self->add_piece_insane("Black","Bishop",2,7);
	$self->add_piece_insane("Black","King",3,7);
	$self->add_piece_insane("Black","Queen",4,7);
	$self->add_piece_insane("Black","Bishop",5,7);
	$self->add_piece_insane("Black","Knight",6,7);
	$self->add_piece_insane("Black","Rook",7,7);
	$self->set_to_move("White");
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Chess::State - a state of a chess game.

=head1 COPYRIGHT

Copyright (C) 2001, 2002 Mark Veltzer;
All rights reserved.

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111, USA.

=head1 DETAILS

	MANIFEST: State.pm
	PROJECT: meta
	VERSION: 0.18

=head1 SYNOPSIS

	package foo;
	use Meta::Chess::State qw();
	my($object)=Meta::Chess::State->new();
	my($result)=$object->start_game();

=head1 DESCRIPTION

This is a class which represents a state of the game.
You may add pieces to the board, remove pieces from the board,
sanity chess the state, and apply a move.

=head1 FUNCTIONS

	new($)
	add_piece_insane($$$$$)
	set_to_move($$)
	start_game($)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

This is the construction for the State.pm object.

=item B<add_piece_insane($$$$$)>

This will add a piece to the board without doing sanity checks.

=item B<set_to_move($$)>

This will set the side which is supposed to move.

=item B<start_game($)>

This will setup the initial board position and will mark whites turn to move.

=item B<TEST($)>

Test suite for this object.

=back

=head1 SUPER CLASSES

Meta::Chess::Board(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV chess and code quality
	0.01 MV more perl quality
	0.02 MV perl documentation
	0.03 MV more perl quality
	0.04 MV perl qulity code
	0.05 MV more perl code quality
	0.06 MV revision change
	0.07 MV languages.pl test online
	0.08 MV perl packaging
	0.09 MV md5 project
	0.10 MV database
	0.11 MV perl module versions in files
	0.12 MV movies and small fixes
	0.13 MV thumbnail user interface
	0.14 MV more thumbnail issues
	0.15 MV website construction
	0.16 MV web site automation
	0.17 MV SEE ALSO section fix
	0.18 MV md5 issues

=head1 SEE ALSO

Meta::Chess::Board(3), Meta::Chess::Side(3), Meta::Chess::Tuple(3), strict(3)

=head1 TODO

Nothing.
