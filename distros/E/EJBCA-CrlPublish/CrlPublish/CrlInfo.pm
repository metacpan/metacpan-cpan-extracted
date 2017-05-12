package EJBCA::CrlPublish::CrlInfo;
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

EJBCA::CrlPublish::CrlInfo

=head1 SYNOPSIS

Retrives details from a CRL file and presents them as accessor methods.

Calls the openssl binary and parses the output to get its job done.

=cut


###############################################################################
# Library Dependencies

use EJBCA::CrlPublish::CrlInfo::Parse;
use EJBCA::CrlPublish::Logging;

our $VERSION = '0.60';


###############################################################################

=head1 CONSTRUCTOR

=head2 EJBCA::CrlPublish::CrlInfo->new( $crlFile )

Argument must be a path to a plain, readable CRL file in DER or PEM format.

Returns a blessed, populated object reference, or undef on failure.

=cut

sub new {
	my ( $class, $crlFile ) = @_;

	bless my $self = {}, $class;

	msgDebug "Analyzing CRL file $crlFile";

	$self->crlFile( $crlFile );

	unless ( $self->importIssuerDn ) {
		msgError "Could not parse issuerDn from CRL.";
		return undef;
	}

	unless ( $self->importIssuingUrl ) {
		msgError "Could not retrieve CRL information.";
		return undef;
	};

	msgDebug "CRL file is in ", $self->crlFormat, " format.";

	return $self;
}

sub retrieve {
	my ( $class, $crlFileHandle ) = @_;

	bless my $self = {}, $class;

	msgDebug "Analyzing remote CRL file";

	my $t = EJBCA::CrlPublish::CrlInfo::Parse->new( $crlFileHandle );

	unless ( $t ) {
		msgError "Failed to parse CRL.";
		return undef;
	}

	unless ( $t->apply( $self ) ) {
		msgError "Failed to apply parsed CRL values.";
		return undef;
	}

	return $self;
}


###############################################################################
# Data Import Methods

sub importIssuerDn {
	my ( $self ) = @_;
	my ( $f, $s );

	my $crlFile = $self->crlFile;

	$f = 'openssl crl -issuer -inform %s -noout -in "%s" 2>/dev/null';

	$s = sprintf $f, 'DER', $crlFile;
	return 1 if $self->tryImportIssuerDn( 'DER', $s );

	$s = sprintf $f, 'PEM', $crlFile;
	return 1 if $self->tryImportIssuerDn( 'PEM', $s );

	msgError "Invalid CRL file '$crlFile'\n";

	return 0;
}

sub tryImportIssuerDn {
	my ( $self, $crlFormat, $string ) = @_;

	return 0 unless my $rawIssuer = `$string`;
	chomp $rawIssuer;

	$self->crlFormat( $crlFormat );

	$rawIssuer =~ s/^issuer=\///;
	$rawIssuer =~ s/\//,/g;

	$self->issuerDn( $rawIssuer );

	return 1;
}

sub importIssuingUrl {
	my ( $self ) = @_;

	my $s = 'openssl crl'
		. ' -in '     . $self->crlFile
		. ' -inform ' . $self->crlFormat
		. ' -noout -text'
		. ' 2> /dev/null';

	my $fh;
	unless ( open $fh, "$s |" ) {
		msgError "open(openssl|): $!";
		return undef;
	}

	my $t = EJBCA::CrlPublish::CrlInfo::Parse->new( $fh );

	unless ( $t ) {
		msgError "Failed to parse CRL.";
		return undef;
	}

	unless ( $t->apply( $self ) ) {
		msgError "Failed to apply parsed CRL values.";
		return undef;
	}

	return 1;
}


###############################################################################

=head1 ACCESSOR METHODS

=head2 $self->crlFile

Returns the CRL filename supplied to the constructor.

=cut

sub crlFile {
	my ( $self, $crlFile ) = @_;

	if ( defined $crlFile ) {
		$self->{crlFile} = $crlFile;
	}

	return $self->{crlFile};
}

=head2 $self->crlFormat

Returns 'PEM' or 'DER'.

=cut

sub crlFormat {
	my ( $self, $crlFormat ) = @_;

	if ( defined $crlFormat ) {
		$self->{crlFormat} = $crlFormat;
	}

	return $self->{crlFormat};
}

=head2 $self->crlNumber

Returns the integer crlNumber from the CRL.

=cut

sub crlNumber {
	my ( $self, $crlNumber ) = @_;

	if ( defined $crlNumber ) {
		$self->{crlNumber} = $crlNumber;
	}

	return $self->{crlNumber};
}

=head2 $self->issuerDn

Returns the CRL issuer distinguished name.

=cut

sub issuerDn {
	my ( $self, $issuerDn ) = @_;

	if ( defined $issuerDn ) {
		$self->{issuerDn} = $issuerDn;
	}

	return $self->{issuerDn};
}

=head2 $self->issuingFile

Returns the file portion of the issuing distribution point URL.

=cut

sub issuingFile {
	my ( $self, $issuingFile ) = @_;

	if ( defined $issuingFile ) {
		$self->{issuingFile} = $issuingFile;
	}

	return $self->{issuingFile};
}

=head2 $self->issuingPath

Returns the path portion of the issuing distribution point URL.

=cut

sub issuingPath {
	my ( $self, $issuingPath ) = @_;

	if ( defined $issuingPath ) {
		$self->{issuingPath} = $issuingPath;
	}

	return $self->{issuingPath};
}

=head2 $self->issuingHost

Returns the host portion of the issuing distribution point URL.

=cut

sub issuingHost {
	my ( $self, $issuingHost ) = @_;

	if ( defined $issuingHost ) {
		$self->{issuingHost} = $issuingHost;
	}

	return $self->{issuingHost};
}

=head2 $self->issuingUrl

Returns the entire issuing distribution point URL.

=cut

sub issuingUrl {
	my ( $self, $issuingUrl ) = @_;

	if ( defined $issuingUrl ) {
		$self->{issuingUrl} = $issuingUrl;
	}

	return $self->{issuingUrl};
}


###############################################################################

=head1 AUTHOR

Kevin Cody-Little <kcody@cpan.org>

=cut


###############################################################################
####################################### EOF ###################################
###############################################################################
1;
