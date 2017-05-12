package EJBCA::CrlPublish::Target;
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

EJBCA::CrlPublish::Target

=head1 SYNOPSIS

A flexible attribute container class, used for collecting the right
configuration values for a given certificate revocation list, and given to
the EJBCA::CrlPublish::Method class as its sole argument.

=cut


###############################################################################
# Library dependencies.

use Carp;

our $VERSION = '0.60';


###############################################################################

=head1 CONSTRUCTOR

=head2 EJBCA::CrlPublish::Target->new( %attributes );

Creates a new empty object. Any arguments supplied as a hash will be applied
to the object before returning. These arguments will not behave any differently
than those supplied as attribute method calls, see below.

Note: you probably want the find constructor, see below.

Returns a blessed EJBCA::CrlPublish::Target reference.

=cut

sub new {
	my ( $class, %args ) = @_;

	$class = ref( $class ) if ref( $class );

	unless ( $class->isa( __PACKAGE__ ) ) {
		confess "Asinine construction of $class";
	}

	bless my $self = {}, $class;

	foreach my $arg ( keys %args ) {
		$self->$arg( $args{$arg} );
	}

	return $self;
}


###############################################################################
# Copy Constructor

sub copyObject {
	my $self = shift;

	my $obj = bless { %$self }, ref( $self );

	return $obj;
}


###############################################################################

=head1 SEARCH CONSTRUCTOR

=head2 EJBCA::CrlPublish::Target->find( $crlInfo );

Given an EJBCA::CrlPublish::CrlInfo argument, returns a list of Target objects
representing each publishing target, with each containing all known relevant
configuration attributes.

Returns a list of blessed, populated EJBCA::CrlPublish::Target references.

=cut

sub find {
	my ( $class, $crlInfo ) = @_;

	my $issuerDn = $crlInfo->issuerDn;

	my $targ = $class->new(
			crlInfo  => $crlInfo,
			issuerDn => $issuerDn );
	
	# apply fixed defaults
	$targ->publishMethod( 'scp' );

	# apply crlInfo details
	if ( $crlInfo->issuingUrl ) {
		$targ->issuingUrl( $crlInfo->issuingUrl );
		$targ->remoteHost( $crlInfo->issuingHost );
		$targ->remotePath( $crlInfo->issuingPath );
		$targ->remoteFile( $crlInfo->issuingFile );
	}

	# apply defaults section
	EJBCA::CrlPublish::Config->applySection( 'defaults', $targ );

	# apply issuerDn specific section
	EJBCA::CrlPublish::Config->applySection( $issuerDn, $targ );

	# apply target host specific section
	EJBCA::CrlPublish::Config->applySection( $targ->remoteHost, $targ );

	my @targets;
	foreach my $remoteHost ( split /\s*,\s*/, $targ->remoteHost ) {
		my $target = $targ->copyObject;
		$target->remoteHost( $remoteHost );
		push @targets, $target;
	}

	return @targets;
}


###############################################################################

=head1 FIXED ATTRIBUTES

=head2 $self->crlFile

An alias for $self->crlInfo->crlFile

=cut

sub crlFile {
	my $self = shift;
	return undef unless $self->crlInfo;
	return $self->crlInfo->crlFile;
}


###############################################################################

=head1 OTHER ATTRIBUTES

=head2 $self->attrib( "attributeName" );

=head2 $self->attrib( "attributeName", "value" );

A generic attribute accessor/mutator.

This should not be called directly; it is used by AUTOLOAD to create closures.

Just call $self->attributeName and $self->attributeName( "value" ) and this
module will take care of the rest.

=cut

sub attrib {
	my ( $self, $name, $value ) = @_;

	if ( defined $value ) {
		$self->{$name} = $value;
	}

	return $self->{$name};
}


###############################################################################
# Automagic attribute mutator method generator

our $AUTOLOAD;

sub AUTOLOAD {
	my $this = shift;
	my $name = $AUTOLOAD;

	# only function for instance calls
	unless ( ref( $this ) and $this->isa( __PACKAGE__ ) ) {
		confess "Method $name not found";
	}

	# strip off the "fully qualified" part of the method name
	$name =~ s/.*://;

	# bail immediately if it's looking for a destructor
	return if $name eq 'DESTROY';

	my $func = sub {
		my $self = shift;
		return $self->attrib( $name, shift );
	};

	{
		no strict 'refs';
		*$AUTOLOAD = $func;
	}

	return &$func( $this, @_ );
}


###############################################################################

=head1 AUTHOR

Kevin Cody-Little <kcody@cpan.org>

=cut


###############################################################################
####################################### EOF ###################################
###############################################################################
1;
