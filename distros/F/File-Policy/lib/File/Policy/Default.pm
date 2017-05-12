###############################################################################
# Purpose : Default (unrestricted) File I/O policies
# Author  : John Alden
# Created : March 2005
# CVS     : $Id: Default.pm,v 1.6 2005/05/18 15:57:28 johna Exp $
###############################################################################

package File::Policy::Default;

use strict;
use File::Spec::Functions;
use Carp;

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA);
@ISA = qw(Exporter);
@EXPORT_OK = qw(get_temp_dir get_log_dir check_safe);
%EXPORT_TAGS = ('all' => \@EXPORT_OK);
$VERSION = sprintf"%d.%03d", q$Revision: 1.6 $ =~ /: (\d+)\.(\d+)/;

sub get_temp_dir {
	return $ENV{TEMP} || File::Spec::Functions::tmpdir();
}

sub get_log_dir {
	return $ENV{LOGDIR} || File::Spec::Functions::curdir();
}

sub check_safe {
	my ($name, $mode) = @_;
	croak("mode must be r or w") unless($mode eq 'r' || $mode eq 'w');
	return 1;
}

1;

=head1 NAME

File::Policy::Default - Default policy for file I/O functions

=head1 SYNOPSIS

	use File::Policy;
	use File::Policy qw/check_safe/;   # to import a specific subroutine
	use File::Policy qw/:all/;         # to import all subroutines

	#Checking I/O policy
	check_safe($filename, 'r');
	check_safe($filename, 'w');

	#Portable directory locations
	$logdir = get_log_dir();
	$tmpdir = get_temp_dir();

=head1 DESCRIPTION

This defines the default (unrestricted) policy for file I/O with modules such as File::Slurp::WithinPolicy.
You may replace this default policy with one for your organisation.

=head1 FUNCTIONS

=over 4

=item check_safe

	check_safe( FILENAME , MODE );

Checks a filename is safe - dies if not.  MODE is r (read) or w (write).
Default is no restrictions on file I/O.

=item get_temp_dir

	$temporary_directory = get_temp_dir();

Returns the path to temporary directory from the TEMP environment variable or File::Spec::Functions::tmpdir().
Note that any return value will have been cleared of a trailing slash.

=item get_log_dir

	$log_directory = get_log_dir();

Returns the path to log directory from the LOGDIR environment variable or the current directory.
Note that any return value will have been cleared of a trailing slash.

=back

=head1 VERSION

$Revision: 1.6 $ on $Date: 2005/05/18 15:57:28 $ by $Author: johna $

=head1 AUTHOR

John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
