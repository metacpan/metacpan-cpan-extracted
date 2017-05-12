###############################################################################
# Purpose : Very Simple File IO policies
# Author  : Murray Walker
# Created : May 2005
# CVS     : $Id: Simple.pm,v 1.1 2005/05/18 15:56:45 johna Exp $
###############################################################################

package File::Policy::Default;

use strict;
use File::Spec::Functions;
use Carp;

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA);
@ISA = qw(Exporter);
@EXPORT_OK = qw(get_temp_dir get_log_dir check_safe);
%EXPORT_TAGS = ('all' => \@EXPORT_OK);
$VERSION = sprintf"%d.%03d", q$Revision: 1.1 $ =~ /: (\d+)\.(\d+)/;

sub get_temp_dir {
	return $ENV{TEMP} || File::Spec::Functions::tmpdir();
}

sub get_log_dir {
	return $ENV{LOGDIR} || File::Spec::Functions::curdir();
}

sub check_safe {
	my ($name, $mode) = @_;
	croak("mode must be r, w or a")
		unless($mode eq 'r' || $mode eq 'w' || $mode eq 'a');

	# Don't allow writing to any file in /etc
	if ( ($mode eq 'w' || $mode eq 'a') and ($name =~ /^\/etc\//) ) {
		die("you are not allowed to write to files in /etc/ : '$name'");
	}

	# Don't allow passwd files to be read
	if (
		($mode eq 'r' || $mode eq 'a') and
		($name =~ /^\/etc\/passwd/ || $name =~ /^\/etc\/shadow/)
	) {
		die("you are not allowed to read passwd files");
	}

	# Don't allow any access to any .configuration files in
	# users home directories
	if ($name =~ /^\/home\/[^\/]+\/\./) {
		die("you cannot access users . files (eg, .pinerc)");
	}

	return 1;
}

1;

=head1 NAME

File::Policy::Simple - Simple policy for file I/O functions

=head1 SYNOPSIS

	use File::Policy;
	use File::Policy qw/check_safe/;   # to import a specific subroutine
	use File::Policy qw/:all/;         # to import all subroutines

	# Ensure File::Policy::Config is updated with the appropriate
	# default policy.  For example
	#		package File::Policy::Config;
	#		use constant IMPLEMENTATION => 'Simple';
	#		1; 

	#Checking I/O policy
	check_safe($filename, 'r'); # Check it is okay for reading
	check_safe($filename, 'w'); # Check it is okay for writing to
	check_safe($filename, 'a'); # Check it is okay for both reading & writing

	#Portable directory locations
	$logdir = get_log_dir();
	$tmpdir = get_temp_dir();

=head1 DESCRIPTION

This defines a simple policy for file I/O with modules such as File::Slurp::WithinPolicy.

Use IN NO WAY implies any safety to your file I/O, it is simply provided to help
demonstrate how you might implement a File Policy at your site.

=head1 FUNCTIONS

=over 4

=item check_safe

	check_safe( FILENAME , MODE );

Checks a filename is safe - dies if not.  MODE is r, w, or a

Using File::Policy::Simple will prevent code that calls check_safe from:

* Writing to any file under /etc/
* Reading from /etc/passwd or /etc/shadow
* Accessing in any way a .configuration file in a users home directory

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

$Revision: 1.1 $ on $Date: 2005/05/18 15:56:45 $ by $Author: johna $

=head1 AUTHOR

Murray Walker <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
