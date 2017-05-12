#!/usr/bin/perl
package Mail::SpamCannibal::PidUtil;

use strict;
#use diagnostics;
use vars qw($VERSION @ISA @EXPORT_OK %EXPORT_TAGS);

use Proc::PidUtil qw(:all);

require Exporter;
@ISA = qw(Exporter);

$VERSION = do { my @r = (q$Revision: 0.06 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };

%EXPORT_TAGS	= %Proc::PidUtil::EXPORT_TAGS;
@EXPORT_OK	= @Proc::PidUtil::EXPORT_OK;

# As of version 0.06, this code has all been moved to Proc::PidUtil

=head1 NAME

Mail::SpamCannibal::PidUtil - PID file management utilities

=head1 SYNOPSIS

  use Mail::SpamCannibal::PidUtil qw(
	if_run_exit
	is_running
	make_pidfile
	zap_pidfile
	get_script_name
	:all
  );

=head1 DESCRIPTION

B<Mail::SpamCannibal::PidUtil> provides utilities to manage PID files

=over 2

=item * $rv = if_run_exit('path',$message);

This routine checks for a file named:

  '(scriptname).pid

in the the $path directory. If a file is found and the PID found in the file
is currently a running job, there is no return, the subroutine prints
the (scriptname): $pid, $message to STDERR and exits.

If there is no file or the PID does not match a running job, run_exit
returns true.

  input:	path for pidfiles
  return:	true if not running
		else exits

Note: also exits if $path is false

=item * $rv = is_running('path2pidfile');

Check that the job described by the pid file is running.

  input:	path 2 pid file
  returns:	pid or false (0) if not running

=item * $rv = make_pidfile('path2pidfile',$pid);

Open a pid file and insert the pid value.

  input:	path 2 pid file,
		pid value || $$
  returns:	pid or false (0) on error

=item * $rv = zap_pidfile($path);

  input:	path for pidfiles
  returns:	return value of 'unlink'

=item * $me = get_script_name();

This function returns the script name portion of the path found in $0;

  input:	none
  returns:	script name

  i.e.  if the script name is:
  /usr/local/spamcannibal/scripts/sc_admin.pl

  $me = get_script_name();

  returns ('sc_admin.pl')

=back

=head1 DEPENDENCIES

	Proc::PidUtil
  
=head1 EXPORT_OK

	if_run_exit
        is_running
        make_pidfile
	zap_pidfile
        get_script_name

=head1 EXPORT_TAGS

	:all

=head1 COPYRIGHT

Copyright 2003 - 2004, Michael Robinton <michael@bizsystems.com>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or 
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of 
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the  
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

=head1 AUTHOR

Michael Robinton <michael@bizsystems.com>

=cut

1;
