#!/bin/echo This is a perl module and should not be run

package Meta::Chess::Game;

use strict qw(vars refs subs);
use Meta::Ds::Array qw();

our($VERSION,@ISA);
$VERSION="0.28";
@ISA=qw(Meta::Ds::Array);

#sub new($);
#sub set_white($$);
#sub get_white($);
#sub set_black($$);
#sub get_black($);
#sub set_date($$);
#sub get_date($);
#sub set_site($$);
#sub get_site($);
#sub set_event($$);
#sub get_event($);
#sub set_round($$);
#sub get_round($);
#sub set_result($$);
#sub get_result($);
#sub set_timecontrol($$);
#sub get_timecontrol($);
#sub set_extra($$);
#sub get_extra($);
#sub set_whiteelo($$);
#sub get_whiteelo($);
#sub set_blackelo($$);
#sub get_blackelo($);
#sub pgn_write($$);
#sub pgn_read($$);
#sub TEST($);

#__DATA__

sub new($) {
	my($class)=@_;
	my($self)={};
	bless($self,$class);
	$self->{BLACK}=defined;
	$self->{WHITE}=defined;
	$self->{DATE}=defined;
	$self->{SITE}=defined;
	$self->{EVENT}=defined;
	$self->{ROUND}=defined;
	$self->{RESULT}=defined;
	$self->{WHITEELO}=defined;
	$self->{BLACKELO}=defined;
	$self->{TIMECONTROL}=defined;
	$self->{EXTRA}=defined;
	return($self);
}

sub set_white($$) {
	my($self,$white)=@_;
	$self->{WHITE}=$white;
}

sub get_white($) {
	my($self)=@_;
	return($self->{WHITE});
}

sub set_black($$) {
	my($self,$black)=@_;
	$self->{BLACK}=$black;
}

sub get_black($) {
	my($self)=@_;
	return($self->{BLACK});
}

sub set_date($$) {
	my($self,$date)=@_;
	$self->{DATE}=$date;
}

sub get_date($) {
	my($self)=@_;
	return($self->{DATE});
}

sub set_site($$) {
	my($self,$val)=@_;
	$self->{SITE}=$val;
}

sub get_site($) {
	my($self)=@_;
	return($self->{SITE});
}

sub set_event($$) {
	my($self,$val)=@_;
	$self->{EVENT}=$val;
}

sub get_event($) {
	my($self)=@_;
	return($self->{EVENT});
}

sub set_round($$) {
	my($self,$val)=@_;
	$self->{ROUND}=$val;
}

sub get_round($) {
	my($self)=@_;
	return($self->{ROUND});
}

sub set_result($$) {
	my($self,$val)=@_;
	$self->{RESULT}=$val;
}

sub get_result($) {
	my($self)=@_;
	return($self->{RESULT});
}

sub set_timecontrol($$) {
	my($self,$val)=@_;
	$self->{TIMECONTROL}=$val;
}

sub get_timecontrol($) {
	my($self)=@_;
	return($self->{TIMECONTROL});
}

sub set_extra($$) {
	my($self,$val)=@_;
	$self->{EXTRA}=$val;
}

sub get_extra($) {
	my($self)=@_;
	return($self->{EXTRA});
}

sub set_whiteelo($$) {
	my($self,$val)=@_;
	$self->{WHITEELO}=$val;
}

sub get_whiteelo($) {
	my($self)=@_;
	return($self->{WHITEELO});
}

sub set_blackelo($$) {
	my($self,$val)=@_;
	$self->{BLACKELO}=$val;
}

sub get_blackelo($) {
	my($self)=@_;
	return($self->{BLACKELO});
}

sub pgn_write($$) {
	my($self,$file)=@_;
	print $file "[Event \"".$self->get_event()."\"]\n";
	print $file "[Site \"".$self->get_site()."\"]\n";
	print $file "[Date \"".$self->get_date()."\"]\n";
	print $file "[Round \"".$self->get_round()."\"]\n";
	print $file "[White \"".$self->get_white()."\"]\n";
	print $file "[Black \"".$self->get_black()."\"]\n";
	print $file "[Result \"".$self->get_result()."\"]\n";
	print $file "[WhiteElo \"".$self->get_whiteelo()."\"]\n";
	print $file "[BlackElo \"".$self->get_blackelo()."\"]\n";
	print $file "[TimeControl \"".$self->get_timecontrol()."\"]\n\n";
	for(my($i)=0;$i<$self->size();$i++) {
		print $file $i."\. ";
		$self->get_elem($i)->print(*FILE);
	}
	print $file "{".$self->get_extra()."} ".$self->get_result()."\n";
}

sub pgn_read($$) {
	my($self,$file)=@_;
	my($parser)=Meta::Utils::Parse::Text->new();
	$parser->init_file($file);
	my($state)="before_headers";
	while(!$parser->get_over()) {
		my($curr)=$parser->get_line();
		if($state eq "before_headers") {
			if($curr eq "") {
				$state="in_game";
			} else {
				if($curr=~/^\[.* \".*\"\]$/) {
					my($key,$val)=($curr=~/^\[(.*) \"(.*)\"\]$/);
					my($found)=0;
					if($key eq "Event") {
						$self->set_event($val);
						$found=1;
					}
					if($key eq "Site") {
						$self->set_site($val);
						$found=1;
					}
					if($key eq "Date") {
						$self->set_date($val);
						$found=1;
					}
					if($key eq "Round") {
						$self->set_round($val);
						$found=1;
					}
					if($key eq "White") {
						$self->set_white($val);
						$found=1;
					}
					if($key eq "Black") {
						$self->set_black($val);
						$found=1;
					}
					if($key eq "Result") {
						$self->set_result($val);
						$found=1;
					}
					if($key eq "WhiteElo") {
						$self->set_whiteelo($val);
						$found=1;
					}
					if($key eq "BlackElo") {
						$self->set_blackelo($val);
						$found=1;
					}
					if($key eq "TimeControl") {
						$self->set_timecontrol($val);
						$found=1;
					}
					if(!$found) {
						throw Meta::Error::Simple("what kind of key is [".$key."]");
					}
				} else {
					throw Meta::Error::Simple("what kind of line is [".$curr."]");
				}
			}
		}
		if($state eq "in_game") {
			if($curr=~/^{/) {
				$state="game_over";
				my($extra)=($curr=~/^{(.*)}.*$/);
				$self->set_extra($extra);
			} else {
				my(@fields)=split(" ",$curr);
				for(my($i)=0;$i<$#fields+1;$i+=3) {
					my($inde)=$fields[$i];
					my($white)=$fields[$i+1];
					my($black)=$fields[$i+2];
					#analyze and add a move to the list
					#of moves.
				}
			}
		}
		if($state eq "game_over") {
			# do nothing for now
		}
		$parser->next();
	}
	$parser->fini();
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Chess::Game - data structure that represents a chess game.

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

	MANIFEST: Game.pm
	PROJECT: meta
	VERSION: 0.28

=head1 SYNOPSIS

	package foo;
	use Meta::Chess::Game qw();
	my($game)=Meta::Chess::Game->new();
	$game->set_white("kasparov");
	$game->set_black("karpov");
	$game->set_date("1.1.70");
	$game->push($my_move);
	$game->pgn_write(FILE);

=head1 DESCRIPTION

This is a library to create chess game objects. The chess game object store
board positions for every move using the board object and those are chached
(calculated on demand and remmembered...). The object can read and store
itself from a pgn file.

=head1 FUNCTIONS

	new($)
	set_white($$)
	get_white($)
	set_black($$)
	get_black($)
	set_date($$)
	get_date($)
	set_site($$)
	get_site($)
	set_event($$)
	get_event($)
	set_round($$)
	get_round($)
	set_result($$)
	get_result($)
	set_timecontrol($$)
	get_timecontrol($)
	set_extra($$)
	get_extra($)
	set_whiteelo($$)
	get_whiteelo($)
	set_blackelo($$)
	get_blackelo($)
	pgn_write($$)
	pgn_read($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<new($)>

Gives you a new Game object.

=item B<set_white($$)>

This will set the white side for the game.

=item B<get_white($)>

This will give you the name of the white player.

=item B<set_black($$)>

This will set the black side for the game.

=item B<get_black($)>

This will give you the name of the black player.

=item B<set_date($$)>

This will set the date for the game.

=item B<get_date($)>

This will give you the date of the game.

=item B<set_site($$)>

This will set the site for the game.

=item B<get_site($)>

This will give you the site of the game.

=item B<set_event($$)>

This will set the event for the game.

=item B<get_event($)>

This will give you the event of the game.

=item B<set_round($$)>

This will set the round for the game.

=item B<get_round($)>

This will give you the round of the game.

=item B<set_result($$)>

This will set the result for the game.

=item B<get_result($)>

This will give you the result of the game.

=item B<set_timecontrol($$)>

This will set the timecontrol for the game.

=item B<get_timecontrol($)>

This will give you the timecontrol of the game.

=item B<set_extra($$)>

This will set the extra for the game.

=item B<get_extra($)>

This will give you the extra of the game.

=item B<set_whiteelo($$)>

This will set the whiteelo for the game.

=item B<get_whiteelo($)>

This will give you the whiteelo of the game.

=item B<set_blackelo($$)>

This will set the blackelo for the game.

=item B<get_blackelo($)>

This will give you the blackelo of the game.

=item B<pgn_write($$)>

This will write the file game to a pgn file for you.

=item B<pgn_read($$)>

This will read a pgn file into the current object.

=item B<TEST($)>

Test suite for this module.

=back

=head1 SUPER CLASSES

Meta::Ds::Array(3)

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV initial code brought in
	0.01 MV bring databases on line
	0.02 MV Another change
	0.03 MV make quality checks on perl code
	0.04 MV more perl checks
	0.05 MV check that all uses have qw
	0.06 MV fix todo items look in pod documentation
	0.07 MV perl code quality
	0.08 MV more perl quality
	0.09 MV chess and code quality
	0.10 MV more perl quality
	0.11 MV perl documentation
	0.12 MV more perl quality
	0.13 MV perl qulity code
	0.14 MV more perl code quality
	0.15 MV revision change
	0.16 MV languages.pl test online
	0.17 MV perl packaging
	0.18 MV PDMT
	0.19 MV md5 project
	0.20 MV database
	0.21 MV perl module versions in files
	0.22 MV movies and small fixes
	0.23 MV thumbnail user interface
	0.24 MV more thumbnail issues
	0.25 MV website construction
	0.26 MV web site automation
	0.27 MV SEE ALSO section fix
	0.28 MV md5 issues

=head1 SEE ALSO

Meta::Ds::Array(3), strict(3)

=head1 TODO

Nothing.
