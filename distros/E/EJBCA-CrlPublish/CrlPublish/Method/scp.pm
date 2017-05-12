package EJBCA::CrlPublish::Method::scp;
use warnings;
use strict;
#
# crlpublish
#
# Copyright (C) 2014, Kevin Cody-Little <kcodyjr@gmail.com>
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

EJBCA::CrlPublish::Method::scp

=head1 SYNOPSIS

Implements publishing via scp.

Updates are atomic; that is, CRLs are transferred to a temporary file and
then renamed into place, so there is no period of time that an intact CRL
cannot be retrieved from the server.

=cut


###############################################################################
# Library Dependencies

use base 'EJBCA::CrlPublish::Method';

use EJBCA::CrlPublish::Logging;

our $VERSION = '0.60';


###############################################################################
# Implementation

sub validate {
	my $self = shift;

	$self->argMustExist( qw( crlFile remoteHost remotePath remoteFile ) );

	my $host = $self->target->remoteHost;
	my $path = $self->target->remotePath;
	my $file = $self->target->remoteFile;

	my $user = $self->target->remoteUser;
	my $pkey = $self->target->privateKeyFile;
	my $args = $self->target->scpExtraArgs;

	my @args = qw( -o BatchMode=yes );

	if ( $pkey ) {
		$self->checkFileType( 'SSH private key', $pkey )
			or return undef;
		push @args, '-i', $pkey;
	}

	if ( $args ) {
		push @args, split /\s+/, $args;
	}

	my $t_host  = $user ? $user . '@' : '';
	   $t_host .= $host;
	my $t_file  = $path . '/' . $file;
	my $t_temp  = $t_file . '.new';

	$self->target->targetArgs( \@args );
	$self->target->targetHost( $t_host );
	$self->target->targetFile( $t_file );
	$self->target->targetTemp( $t_temp );

	return 1;
}

sub publish {
	my $self = shift;

	unless ( $self->publish_pre ) {
		msgError "Failed pre-publish sanity check.";
		return 0;
	}

	if ( my $t = $self->target->targetCrlNumber ) {
		my $u = $self->target->crlInfo->crlNumber;
		unless ( $u > $t ) {
			msgDebug "Target already has the newest CRL, skipping.";
			return 1;
		}
		return 1 unless $u > $t;
	}

	unless ( $self->publish_scp ) {
		msgError "Failed to securely copy CRL file.";
		return 0;
	}

	unless ( $self->publish_smv ) {
		msgError "Failed to activate new CRL file.";
		return 0;
	}

	return 1;
}

sub publish_pre {
	my $self = shift;

	my $args   = $self->target->targetArgs;
	my $t_host = $self->target->targetHost;
	my $t_file = $self->target->targetFile;
	my $t_temp = $self->target->targetTemp;

	my @trucall = ( 'ssh', @$args, $t_host, '/bin/true' );

	unless ( system( @trucall ) == 0 ) {
		msgError "Failed to ssh $t_host /bin/true: $?";
		return 0;
	}

	my @sslcall = ( 'ssh', @$args, $t_host,
			'openssl', 'crl',
			'-in', $t_file,
			'-inform', $self->target->crlInfo->crlFormat,
			'-noout', '-text' );

	open my $fh, '-|', @sslcall
		or return 1;

	my $t = EJBCA::CrlPublish::CrlInfo->retrieve( $fh )
		or return 1;

	return 1 unless $t->crlNumber;

	$self->target->targetCrlNumber( $t->crlNumber );

	return 1;
}

sub publish_scp {
	my $self = shift;

	my $args   = $self->target->targetArgs;
	my $t_host = $self->target->targetHost;
	my $t_temp = $self->target->targetTemp;

	my $source = $self->target->crlFile;
	my $target = $t_host . ':' . $t_temp;

	$self->checkFileType( 'CRL file', $source )
		or return 0;

	my @scpcall = ( 'scp', @$args, $source, $target );

	unless ( system( @scpcall ) == 0 ) {
		msgError "Failed to scp $source $target: $?";
		return 0;
	}

	return 1;
}

sub publish_smv {
	my $self = shift;

	my $args   = $self->target->targetArgs;
	my $t_host = $self->target->targetHost;
	my $t_temp = $self->target->targetTemp;
	my $t_file = $self->target->targetFile;

	my @smvcall = ( 'ssh', @$args, $t_host, 'mv', $t_temp, $t_file );

	unless ( system( @smvcall ) == 0 ) {
		msgError "Failed to ssh $t_host mv $t_temp $t_file: $?";
		return 0;
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
