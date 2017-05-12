package EJBCA::CrlPublish::Method;
use warnings;
use strict;
#
# crlpublish
#
# Copyright (C) 2014, Kevin Cody-Little <kcody@cpan.org>
#
# Portions derived from crlpublisher.sh, original copyright follows:
#
# Copyright (C) 2011, Branko Majic <branko@majic.rs>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
###############################################################################

=head1 NAME

EJBCA::CrlPublish::Method

=head1 SYNOPSIS

Base class for flexible publishing methods.

This is invoked by EJBCA::CrlPublish to actually transfer a CRL.

=cut


###############################################################################
# Library dependencies

use Carp;
use EJBCA::CrlPublish::Logging;

our $VERSION = '0.60';


###############################################################################

=head1 INVOCATION

=head2 EJBCA::CrlPublish::Method->execute( $target )

Argument must be a single EJBCA::CrlPublish::Target object.

This is the only function that should be called directly, except by subclasses.

=cut

sub execute {
	my ( $class, $target ) = @_;

	$class = ref( $class ) if ref( $class );

	unless ( $class->isa( __PACKAGE__ ) ) {
		confess "Asinine construction of $class";
	}

	unless ( $target->isa( 'EJBCA::CrlPublish::Target' ) ) {
		confess 'Expecting Target object, got ' . ref( $target );
	}

	my $meth = $target->publishMethod;

	unless ( $meth ) {
		msgError "Unable to determine publishing method.";
		return undef;
	}

	my $oclass = __PACKAGE__ . '::' . $meth;
	my $classp = __PACKAGE__ . '::' . $meth . '.pm';
	$classp =~ s/::/\//g;

	unless ( require $classp ) {
		msgError "Publishing method $meth not found.";
		return undef;
	}

	bless my $self = {}, $oclass;

	$self->{target}  = $target;

	unless ( $self->validate ) {
		msgError "Publishing pre-validation failed.";
		return undef;
	}

	return $self->publish;
}


###############################################################################

=head1 HELPER METHODS

These are used by subclasses that implement specific publishing methods.

=head2 $self->target

Returns the EJBCA::CrlPublish::Target object that was passed to execute, above.

=cut

sub target {
	return (shift)->{target};
}

=head2 $self->argMustExist( @argNames )

Croaks if the target object is missing any of the supplied attribute names.

=cut

sub argMustExist {
	my $self = shift;

	while ( my $arg = shift ) {
		next if $self->target->$arg;
		msgError "Required attribute '$arg' not present.";
		return 0;
	}

	return 1;
}

=head2 $self->checkFileType( $name, $path )

First argument is used to prefix error messages, second is a path to a file.

Croaks if the file isn't present, plain, and readable.

=cut

sub checkFileType {
	my ( $self, $name, $path ) = @_;

	unless ( -e $path ) {
		msgError "$name file '$path' not found.";
		return 0;
	}

	unless ( -f $path ) {
		msgError "$name file '$path' not a file.";
		return 0;
	}

	unless ( -r $path ) {
		msgError "$name file '$path' not readable.";
		return 0;
	}

	return 1;
}


###############################################################################

=head1 ABSTRACT METHODS

Subclasses implementing specific publishing methods must provide these.

=head2 $self->validate

Croaks if it doesn't like something about the supplied Target object.

=cut

sub validate {
	my $self = shift;

	confess "Abstract method invocation";

}

=head2 $self->publish

Accomplish the publish. Called only if $self->validate succeeds.

=cut

sub publish {
	my $self = shift;

	confess "Abstract method invocation";

}


###############################################################################

=head1 AUTHOR

Kevin Cody-Little <kcody@cpan.org>

=cut


###############################################################################
####################################### EOF ###################################
###############################################################################
1;
