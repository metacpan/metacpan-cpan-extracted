#!/bin/echo This is a perl module and should not be run

package Meta::Chess::Position;

use strict qw(vars refs subs);
use Meta::Geo::Pos2d qw();

our($VERSION,@ISA);
$VERSION="0.18";
@ISA=qw(Meta::Geo::Pos2d);

#sub BEGIN();
#sub new($);
#sub cget_x($);
#sub cset_x($$);
#sub cget_y($);
#sub cset_y($$);
#sub cprint($$);
#sub TEST($);

#__DATA__

my($hash_horz,$hash_vert,$horz_hash,$vert_hash)=({},{},{},{});

sub BEGIN() {
	$hash_horz->{"a"}=0;
	$hash_horz->{"b"}=1;
	$hash_horz->{"c"}=2;
	$hash_horz->{"d"}=3;
	$hash_horz->{"e"}=4;
	$hash_horz->{"f"}=5;
	$hash_horz->{"g"}=6;
	$hash_horz->{"h"}=7;

	$horz_hash->{"0"}="a";
	$horz_hash->{"1"}="b";
	$horz_hash->{"2"}="c";
	$horz_hash->{"3"}="d";
	$horz_hash->{"4"}="e";
	$horz_hash->{"5"}="f";
	$horz_hash->{"6"}="g";
	$horz_hash->{"7"}="h";

	$hash_vert->{"1"}=0;
	$hash_vert->{"2"}=1;
	$hash_vert->{"3"}=2;
	$hash_vert->{"4"}=3;
	$hash_vert->{"5"}=4;
	$hash_vert->{"6"}=5;
	$hash_vert->{"7"}=6;
	$hash_vert->{"8"}=7;

	$vert_hash->{"0"}=1;
	$vert_hash->{"1"}=2;
	$vert_hash->{"2"}=3;
	$vert_hash->{"3"}=4;
	$vert_hash->{"4"}=5;
	$vert_hash->{"5"}=6;
	$vert_hash->{"6"}=7;
	$vert_hash->{"7"}=8;
}

sub new($) {
	my($class)=@_;
	my($self)=Meta::Geo::Pos2d->new();
	bless($self,$class);
	return($self);
}

sub cget_x($) {
	my($self)=@_;
	return($horz_hash->{$self->get_x()});
}

sub cset_x($$) {
	my($self,$val)=@_;
	Meta::Development::Assert::assert_true(exists($hash_horz->{$val}),"position not valid");
	$self->set_x($hash_horz->{$val});
}

sub cget_y($) {
	my($self)=@_;
	return($vert_hash->{$self->get_y()});
}

sub cset_y($$) {
	my($self,$val)=@_;
	Meta::Development::Assert::assert_true(exists($hash_vert->{$val}),"position not valid");
	$self->set_y($hash_vert->{$val});
}

sub cprint($$) {
	my($self,$file)=@_;
	print $file $self->cget_x().$self->cget_y();
}

sub TEST($) {
	my($context)=@_;
	return(1);
}

1;

__END__

=head1 NAME

Meta::Chess::Position - a chess position object.

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

	MANIFEST: Position.pm
	PROJECT: meta
	VERSION: 0.18

=head1 SYNOPSIS

	package foo;
	use Meta::Chess::Position qw();
	my($position)=Meta::Chess::Position->new();
	$position->set("e","2");

=head1 DESCRIPTION

This is a position object.
It inherits from a general 2d position.
special stuff that it does:
Print itself in chess format.
It does self verification.
It knows when its off the board.
It offers new set routine with checks.

=head1 FUNCTIONS

	BEGIN()
	new($)
	cget_x($)
	cset_x($$)
	cget_y($)
	cset_y($$)
	cprint($$)
	TEST($)

=head1 FUNCTION DOCUMENTATION

=over 4

=item B<$hash_horz,$hash_vert,$horz_hash,$vert_hash>

These hashs store mappings to horizontal and vertical positions.

=item B<BEGIN()>

This is the begin block which initialized the static hashes.

=item B<new($)>

This will give you a new Position object.

=item B<cget_x($)>

This will give you the x part of a position in chess notation.

=item B<cset_x($$)>

This will set the x part of a position.

=item B<cget_y($)>

This will give you the y part of a position in chess notation.

=item B<cset_y($$)>

This will set the y value of a position.

=item B<cprint($$)>

This will print the current position in chess style.

=item B<TEST($)>

Test suite for this object.

=back

=head1 SUPER CLASSES

Meta::Geo::Pos2d(3)

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

Meta::Geo::Pos2d(3), strict(3)

=head1 TODO

Nothing.
