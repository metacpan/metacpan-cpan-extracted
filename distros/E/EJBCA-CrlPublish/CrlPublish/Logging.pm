package EJBCA::CrlPublish::Logging;
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

EJBCA::CrlPublish::Logging

=head1 SYNOPSIS

Central logging implementation.

Exports &msgDebug &msgError

=cut


###############################################################################
# Library Dependencies

use base 'Exporter';

our @EXPORT  = qw( msgDebug msgError );
our $VERSION = '0.60';
our $DODEBUG = 0;


###############################################################################
# Intercept STDIO if they aren't terminals.

sub BEGIN {

	no strict 'vars';

	unless ( -t STDOUT ) {
		open STDOUT, ">> /var/log/crlpublish.log";
		open STDERR, ">&1"
	}

}


###############################################################################
# 

sub msgDebug {
	return unless $DODEBUG;
	warn 'DEBUG: ', @_, "\n";
}

sub msgError {
	warn 'ERROR: ', @_, "\n";
}


###############################################################################

=head1 AUTHOR

Kevin Cody-Little <kcody@cpan.org>

=cut


###############################################################################
####################################### EOF ###################################
###############################################################################
1;
