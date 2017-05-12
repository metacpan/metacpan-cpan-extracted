#!/bin/echo This is a perl module and should not be run

package Meta::Utils::Text::Counter;

use strict qw(vars refs subs);
use Meta::Utils::Parse::Text qw();
use Meta::Utils::Output qw();
use Meta::Baseline::Aegis qw();

our($VERSION,@ISA);
$VERSION="0.02";
@ISA=qw();

#sub count($$);
#sub TEST($);

#__DATA__

sub count($$) {
	my($file,$rege)=@_;
	my($parser)=Meta::Utils::Parse::Text->new();
	$parser->init_file($file);
	my($res)=0;
	while(!$parser->get_over()) {
		my($curr)=$parser->get_line();
		if($curr=~/$rege/) {
			$res++;
		}
		$parser->next();
	}
	$parser->fini();
	return($res);
}

sub TEST($) {
	my($context)=@_;
	my($pgn_file)=Meta::Baseline::Aegis::which("pgnx/games.pgn");
	my($number_of_games)=count($pgn_file,"Event");
	Meta::Utils::Output::print("number of games is [".$number_of_games."]\n");
	return(1);
}

1;

__END__

=head1 NAME

Meta::Utils::Text::Counter - counter number of regexp matches in a file.

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

	MANIFEST: Counter.pm
	PROJECT: meta
	VERSION: 0.02

=head1 SYNOPSIS

	package foo;
	use Meta::Utils::Text::Counter qw();
	my($number_of_games)=Meta::Utils::Text::Counter::count("mypgnfile.pgn","Event");

=head1 DESCRIPTION

This module helps you to quickly count the number of appearances of a certain regexp in a certain
file.

=head1 FUNCTIONS

	count($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<count($$)>

This method receives:
1. file - file to grep in.
2. regexp - regexp to look for.

=item B<TEST($)>

A test suite for this module. The idea is to count number of games in a GNU pgn game.

=back

=head1 SUPER CLASSES

None.

=head1 BUGS

None.

=head1 AUTHOR

	Name: Mark Veltzer
	Email: mailto:veltzer@cpan.org
	WWW: http://www.veltzer.org
	CPAN id: VELTZER

=head1 HISTORY

	0.00 MV web site automation
	0.01 MV SEE ALSO section fix
	0.02 MV md5 issues

=head1 SEE ALSO

Meta::Baseline::Aegis(3), Meta::Utils::Output(3), Meta::Utils::Parse::Text(3), strict(3)

=head1 TODO

Nothing.
