package EJBCA::CrlPublish;
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

EJBCA::CrlPublish

=head1 SYNOPSIS

High level API for publishing new CRLs.

Exports: &publishCrl &processQueue

=cut


###############################################################################
# Global Configuration

my $globalOldConfig = '/etc/crlpublisher';
my $invokeOldConfig = $ENV{HOME} . '/.crlpublisher';
my $globalNewConfig = '/etc/crlpublish';
my $invokeNewConfig = $ENV{HOME} . '/.crlpublish';


###############################################################################
# Library Dependencies

use EJBCA::CrlPublish::Config;
use EJBCA::CrlPublish::CrlInfo;
use EJBCA::CrlPublish::Logging;
use EJBCA::CrlPublish::Method;
use EJBCA::CrlPublish::Target;

our $VERSION = '0.60';

use base 'Exporter';
our @EXPORT = qw( publishCrl processQueue );


###############################################################################
# Configuration Loader

sub loadConfiguration() {
	my $rc = 1;

	$rc &&= EJBCA::CrlPublish::Config->importAllFiles( $globalNewConfig );
	$rc &&= EJBCA::CrlPublish::Config->importAllFiles( $globalOldConfig );
	$rc &&= EJBCA::CrlPublish::Config->importAllFiles( $invokeNewConfig );
	$rc &&= EJBCA::CrlPublish::Config->importAllFiles( $invokeOldConfig );

	unless ( $rc ) {
		msgError "Configuration errors detected. Aborting.";
	}

	return $rc;
}


###############################################################################
# CRL Handler

sub _publishOneCrl($) {
	my $crlFile = shift;

	my $crlInfo = EJBCA::CrlPublish::CrlInfo->new( $crlFile );

	unless ( $crlInfo ) {
		msgError "Unable to parse CRL. Aborting.";
		return 0;
	}

	my @targets = EJBCA::CrlPublish::Target->find( $crlInfo );

	unless ( scalar( @targets ) ) {
		msgError "Could not find any publishing targets. Aborting.";
		return 0;
	}

	my $rc = 1;
	foreach my $target ( @targets ) {
		msgDebug "Publishing to target ", $target->remoteHost;
		# TODO: implement asynchronous queueing
		$rc &&= EJBCA::CrlPublish::Method->execute( $target );
	}

	if ( $rc ) {
		msgDebug "Publishing succeeded.";
	}

	else {
		msgError "Publishing failed.";
	}

	return $rc;
}

=head1 CRL PUBLISHING FUNCTION

=head2 publishCrl( $crlFile );

=head2 publishCrl( @crlFiles );

Publishes the given CRL file, which must be a readable plain file, and
must be a valid certificate revocation list in PEM or DER format.

Supplying a list of crlFile names is supported, but only recommended when
asynchronous publishing is in use. Otherwise, the caller will not be able to
tell which CRL might have failed, and will have to republish them all.

Returns true if all supplied crlFiles were published or queued successfully,
and returns false if any single crlFile failed to publish or enqueue.

=cut

sub publishCrl(@) {

	loadConfiguration()
		or return 0;

	my $rc = 1;
	while ( my $crlFile = shift ) {
		$rc &&= _publishOneCrl( $crlFile );
	}

	return $rc;
}


###############################################################################
# Cron Despooler

=head1 QUEUE FLUSH FUNCTION

=head2 processQueue();

Examines the local spool directory and attempts to push any pending CRL
updates to their destinations. Upon failure, the CRL will remain in the queue
for another attempt.

By default, the queue directory is in /var/spool/crlpublish.

=cut

sub processQueue() {

	loadConfiguration()
		or return 0;

#	my $dir = $cfg->spooldirectory
#		or die "Asynchronous publishing is not configured.\n";

	# look through spooldirectory; push then remove

	return 0;
}


###############################################################################

=head1 AUTHOR

Kevin Cody-Little <kcody@cpan.org>

=cut


###############################################################################
####################################### EOF ###################################
###############################################################################
1;
