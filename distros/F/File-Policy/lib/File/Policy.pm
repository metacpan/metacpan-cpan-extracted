###############################################################################
# Purpose : Interface to File I/O policies
# Author  : John Alden
# Created : March 2005
# CVS     : $Id: Policy.pm,v 1.5 2005/05/18 15:58:21 johna Exp $
###############################################################################

package File::Policy;

use strict;
use vars qw($VERSION $Aliased);

$VERSION = sprintf"%d.%03d", q$Revision: 1.5 $ =~ /: (\d+)\.(\d+)/;
$Aliased = 0;

sub import {
	my $package = shift;
	
	#Allow default implementation to be set in a config module
	my $default_implementation = 'Default';
	eval {
		require File::Policy::Config;
		$default_implementation = &File::Policy::Config::IMPLEMENTATION;	
	};
	
	my $impl = $default_implementation; #Currently no way of overriding default - could be extended later
	die("Invalid File::Policy package - $impl") unless($impl =~ /^[\w:]+$/); #Sanitize package name
	$impl = "File::Policy::" . $impl;
	TRACE("File::Policy Implementation: ". $impl);
	
	#Export symbols to caller
	eval "require $impl";
	die("Unable to compile $impl - $@") if($@);
	++ local $Exporter::ExportLevel; #Bypass this module in caller()
	$impl->import(@_);
		
	#Alias symbols into this package too for fully qualified access
	unless($Aliased) {
		foreach(qw(check_safe get_log_dir get_temp_dir)) {
			no strict 'refs';
			*{"File::Policy::$_"} = *{"${impl}::$_"};
		}
		$Aliased = 1;
	}
}

#Stubs compatible with Log::Trace
sub TRACE{}
sub DUMP{}

1;

=head1 NAME

File::Policy - Site policy for file I/O functions

=head1 SYNOPSIS

	use File::Policy;
	use File::Policy qw/check_safe/;   # to import a specific subroutine
	use File::Policy qw/:all/;         # to import all subroutines

	#Checking I/O policy
	check_safe($filename, 'r');
	check_safe($filename, 'w');

	#Preferred directory locations
	$logdir = get_log_dir();
	$tmpdir = get_temp_dir();

=head1 DESCRIPTION

This defines the policy for file I/O with modules such as File::Slurp::WithinPolicy.
The purpose is to allow systems administrators to define locations and restrictions
for applications' file I/O and give app developers a policy to follow.  Note that the
module doesn't ENFORCE the policy - application developers can choose to ignore it 
(and systems administrators can choose not to install their applications if they do!).

You may control which policy gets applied by creating a File::Policy::Config module
with an IMPLEMENTATION constant. You may write your own policy as a module within the File::Policy:: namespace.

By default (if no File::Policy::Config is present), the File::Policy::Default policy gets applied which doesn't impose
any restrictions and provides reasonable default locations for temporary and log files.

The motivation behind this module was a standard, flexible approach to allow a site wide file policy to be defined.  This will be most useful in large environments where a few sysadmins are responsible for code written by many other people.  Simply ensuring that submitted code calls check_safe() ensures file access is sane, reducing the amount of effort required to do a security audit.

If your code is not security audit'd, or you are the only developer at your site, this might be overkill. However you may consider it good practise regardless and protection against paths in your code getting corrupted accidently or maliciously in the future.

There are two major benefits of using this module.  One, sites that do implement a policy can more easily integrate your code in a standard way.  If you have a file policy at your site, you can apply different policies (via File::Policy::Config) in different environments (production, integration test, development) and the appropriate policy is automatically applied without having to change your code or configs.

=head1 FUNCTIONS

=over 4

=item check_safe

	check_safe( FILENAME , MODE );

Checks FILENAME is safe - dies if not.  MODE is r (read) or w (write).

=item get_temp_dir

	$temporary_directory = get_temp_dir();

Returns the path to temporary directory.  Note that any return value will have been cleared of a trailing slash.

=item get_log_dir

	$log_directory = get_log_dir();

Returns the path to log directory.  Note that any return value will have been cleared of a trailing slash.

=back

=head1 DEFINING YOUR OWN POLICY

To implement your own custom policy

  cp File/Policy/Default.pm File/Policy/YourPolicy.pm
  
and modify YourPolicy accordingly.  Then, create File/Policy/Config.pm contaning:

  use constant IMPLEMENTATION => 'YourPolicy';

Now having used File::Policy, calling check_safe in your scripts will enforce your policy 
(as well as give you access to log and temp paths in locations you recommend).

=head1 SEE ALSO

L<File::Policy::Default>, L<Safe>

=head1 VERSION

$Revision: 1.5 $ on $Date: 2005/05/18 15:58:21 $ by $Author: johna $

=head1 AUTHOR

John Alden <cpan _at_ bbc _dot_ co _dot_ uk>

=head1 COPYRIGHT

(c) BBC 2005. This program is free software; you can redistribute it and/or modify it under the GNU GPL.

See the file COPYING in this distribution, or http://www.gnu.org/licenses/gpl.txt 

=cut
