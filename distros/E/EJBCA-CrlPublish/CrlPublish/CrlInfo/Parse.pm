package EJBCA::CrlPublish::CrlInfo::Parse;
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

EJBCA::CrlPublish::CrlInfo::Parse

=head1 SYNOPSIS

Parses the openssl command line tool's output to glean details about the CRL.

=cut


###############################################################################
# Library Dependencies

use EJBCA::CrlPublish::Logging;

our $VERSION = '0.60';


###############################################################################

=head1 CONSTRUCTOR

=head2 EJBCA::CrlPublish::CrlInfo::Publish->new( $fileHandle )

Argument must be an opened filehandle to openssl's output.

Returns a blessed, populated object reference, or undef on failure.

=cut

sub new {
	my ( $class, $fileHandle ) = @_;

	bless my $self = {}, $class;

	while ( my $txt = <$fileHandle> ) {
		chomp( $txt );
		return undef unless $self->parse( $txt );
	}

	return $self;
}


###############################################################################
# One Line Input Method

sub parse {
	my ( $self, $txt ) = @_;

	$txt =~ s/^\s+//;
	$txt =~ s/\s+$//;

	if ( my $value = $self->{_nextValue} ) {
		delete $self->{_nextValue};
		$self->{$value} = $txt;
		msgDebug "crlInfo parser found $value = $txt";
		goto success;
	}

	if ( my $check = $self->{_nextCheck} ) {
		delete $self->{_nextCheck};
		unless ( $txt eq $check ) {
			msgError "CrlInfo parser expected $check, got $txt";
			return 0;
		}
		$self->{_lastValue} = $txt;
		return 1;
	}

	if ( $txt =~ /Issuer:/ ) {
		$txt =~ s/^Issuer: \///;
		$txt =~ s/\//,/g;
		$self->{issuerDn} = $txt;
		msgDebug "crlInfo parser found issuerDn = $txt";
	}

	if ( $txt =~ /X509v3 CRL Number:/ ) {
		$self->{_nextValue} = 'crlNumber';
		goto success;
	}

	if ( $txt =~ /X509v3 Issuing Distr(i|u)bution Point/ ) {
		$self->{_nextCheck} = 'Full Name:';
		goto success;
	}

	if ( $txt =~ /URI:/ ) {
		my $last = $self->{_lastValue};
		unless ( $last and $last eq 'Full Name:' ) {
			msgError "CrlInfo encountered URI out of place.";
			return 0;
		}
		$self->parseIssuingUrl( $txt );
		msgDebug "crlInfo parser found $txt";
		goto success;
	}

success:
	delete $self->{_lastValue};
	return 1;
}


###############################################################################
# Pick Apart the Issuing URL

sub parseIssuingUrl {
	my ( $self, $whole ) = @_;

	my ( $dum0, $prot, $unc ) = split /:/, $whole, 3;

	my ( $dum1, $dum2, $host, $path ) = split /\//, $unc, 4;

	my @part = split /\//, $path;
	my $file = pop @part;
	$path = join( '/', @part );

	$self->{issuingFile} = $file;
	$self->{issuingPath} = $path;
	$self->{issuingHost} = $host;
	$self->{issuingUrl}  = $prot . ';' . $unc;

	return 1;
}


###############################################################################
# Push Contents Onto Object

sub apply {
	my ( $self, $target ) = @_;

	foreach my $key ( keys %$self ) {
		next if $key =~ /^_/;
		$target->$key( $self->{$key} );
	}

	return 1;
}


###############################################################################

=head1 AUTHOR

Kevin Cody-Little <kcody@cpan.org>

=cut


###############################################################################
####################################### EOF ###################################
###############################################################################
1;
