package IPC::RunExternal;

=head1 NAME

IPC::RunExternal - Execute external (shell) command and gather stdout and stderr

=head1 VERSION

Version 0.09


=head1 SYNOPSIS

    use IPC::RunExternal;

	my $external_command = 'ls -r /'; # Any normal Shell command line
	my $stdin = q{}; # STDIN for the command. Must be an initialized string, e.g. q{}.
	my $timeout = 60; # Maximum number of seconds before forced termination.
	my %parameter_tags = (print_progress_indicator => 1);
	# Parameter tags:
	# print_progress_indicator [1/0]. Output something on the terminal every second during
			# the execution, to tell user something is still going on.
	# progress_indicator_char [*], What to print, default is '#'.
	# execute_every_second [&], instead of printing the same everytime,
			# execute a function. The first parameters to this function is the number of seconds passed.

    my ($exit_code, $stdout, $stderr, $allout) 
    		= runexternal($external_command, $stdin, $timeout, \%parameter_tags);

    my ($exit_code, $stdout, $stderr, $allout) 
    		= runexternal($external_command, $stdin, $timeout, {progress_indicator_char => '#'});

	# Print `date` at every 10 seconds during execution
	my $print_date_function = sub {
		my $secs_run = shift;
		if($secs_run % 10 == 0) {
			print `/bin/date`;
		}
	};
	($exit_code, $stdout, $stderr, $allout) = runexternal($external_command, $stdin, $timeout, 
			{ execute_every_second => $print_date_function
			});


=head1 DESCRIPTION

IPC::RunExternal is for executing external operating system programs 
more conveniently that with `` (backticks) or exec/system, and without all the hassle of IPC::Open3.

IPC::RunExternal allows:
1) Capture STDOUT and STDERR in scalar variables.
2) Capture both STDOUT and STDERR in one scalar variable, in the correct order.
3) Use timeout to break the execution of a program running too long.
4) Keep user happy by printing something (e.g. '.' or '#') every second.
5) Not happy with simply printing something? Then execute your own code (function) at 
	every second while the program is running.


=head1 DEPENDENCIES

Requires Perl version 5.6.2.

Requires the following modules:

=over 4

English
Carp
IPC::Open3;
IO::Select
Symbol

=back


=cut

require 5.6.2;
use strict;
use warnings;
use utf8;

use English '-no_match_vars';
use Carp 'croak';
use IPC::Open3;
use IO::Select; # for select
use Symbol 'gensym'; # for gensym

BEGIN {
	use Exporter ();
	our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);

	$VERSION     = 0.09;

	@ISA         = qw(Exporter DynaLoader);
	@EXPORT      = qw(runexternal);
	%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],
	@EXPORT_OK   = qw(runexternal);
}
our @EXPORT_OK;

# CONSTANTS for this module
my $TRUE = 1;
my $FALSE = 0;
my $EMPTY_STR = q{};

my $DEFAULT_PRINT_PROGRESS_INDICATOR = $FALSE;
my $DEFAULT_PROGRESS_INDICATOR_CHARACTER = q{.};
my $DEFAULT_EXECUTE_EVERY_SECOND_ROUTINE_POINTER = $FALSE;
my $EXIT_STATUS_OK = 1;
my $EXIT_STATUS_TIMEOUT = 0;
my $EXIT_STATUS_FAILED = -1;

# GLOBALS
# No global variables



=head1 EXPORT

Exports routine runexternal().

=head1 SUBROUTINES/METHODS

=over 4

=item runexternal

Run an external (operating system) command.
Parameters:
1. command, a system executable.
2. input (STDIN), for the command, must be an initialized string,
	if no input, string should be empty.
3. timeout, 0 (no timeout) or greater. 
4. parameter tags (a hash)
      print_progress_indicator: 1/0 (TRUE/FALSE), default FALSE
      progress_indicator_char: default "."; printed every second.
      execute_every_second: parameter to a function, executed every second.
Return values (an array of four items):
1. exit_status, an integer, 
	1 = OK
	0 = timeout (process killed). "Timeout" added to $output_error and $output_all.
	-1 = couldn't execute (IPC:Open3 failed, other reason). Reason (given by shell) in $output_error.
2. $output_std (what the command returned)
3. $output_error (what the command returned)
4. $output_all: $output_std and $output_error mixed in order of occurrence.

=back

=cut


sub runexternal {

	# Parameters
	my ($command, $input, $timeout, $parameter_tags) = @_;

	if(!defined $command) {
		croak("Parameter 'command' is not initialized!");
	}
	if(!defined $input) {
		croak("Parameter 'input' is not initialized!");
	}
	if($timeout < 0) {
		croak("Parameter 'timeout' is not valid!");
	}

	my $print_progress_indicator = $DEFAULT_PRINT_PROGRESS_INDICATOR;
	if(exists $parameter_tags->{'print_progress_indicator'}) {
		if($parameter_tags->{'print_progress_indicator'} == $FALSE ||
				$parameter_tags->{'print_progress_indicator'} == $TRUE) {
			$print_progress_indicator = $parameter_tags->{'print_progress_indicator'};
		}
		else {
			croak("Parameter 'print_progress_indicator' is not valid (must be 1/0)!");
		}
	}

	my $progress_indicator_char = $DEFAULT_PROGRESS_INDICATOR_CHARACTER;
	if(exists $parameter_tags->{'progress_indicator_char'}) {
		$progress_indicator_char = $parameter_tags->{'progress_indicator_char'};
	}

	my $execute_every_second = $DEFAULT_EXECUTE_EVERY_SECOND_ROUTINE_POINTER;
	if(exists $parameter_tags->{'execute_every_second'}) {
		if(ref($parameter_tags->{'execute_every_second'}) eq 'CODE') {
			$execute_every_second = $parameter_tags->{'execute_every_second'};
		}
		else {
			croak("Parameter execute_every_second is not a code reference!");
		}
	}

	# Variables
	my $command_exit_status = $EXIT_STATUS_OK;
	my $output_std = $EMPTY_STR;
	my $output_error = $EMPTY_STR;
	my $output_all = $EMPTY_STR;

	# Validity check
	if(
			$command ne $EMPTY_STR
			#&& defined($input)
			&& $timeout >= 0
	)
	{
		$OUTPUT_AUTOFLUSH = $TRUE; # Equals to var $|. Flushes always after writing.
		my ($infh,$outfh,$errfh); # these are the FHs for our child
		$errfh = gensym(); # we create a symbol for the errfh
		                   # because open3 will not do that for us
		my $pid;
		my $eval_ret = eval{
			$pid = open3($infh, $outfh, $errfh, $command);
		};
		if(!$EVAL_ERROR) {
			print $infh $input;
			close $infh;
			my $sel = new IO::Select; # create a select object to notify
			                          # us on reads on our FHs
			$sel->add($outfh,$errfh); # add the FHs we're interested in
			my $out_handles_open = 2;
			for(my $slept_secs = -1; $out_handles_open > 0 && $slept_secs < $timeout; $slept_secs++) {
				while(my @ready = $sel->can_read(1)) { # read ready, timeout after 1 second.
					foreach my $fh (@ready) {
						my $line = <$fh>;        # read one line from this fh
						if( !(defined $line) ){   # EOF on this FH
							$sel->remove($fh);   # remove it from the list
							$out_handles_open -= 1;
							next;                # and go handle the next FH
						}
						if($fh == $outfh) {      # if we read from the outfh
							$output_std .= $line;
							$output_all .= $line;
						} elsif($fh == $errfh) { # do the same for errfh
							$output_error .= $line;
							$output_all .= $line;
						} else {                 # we read from something else?!?!
							croak "Shouldn't be here!\n";
						}
					}
				}
				if($timeout == 0) {
					# No timeout, so we lower the counter by one to keep it forever under 0.
					# Only the closing of the output handles ($out_handles_open == 0) can break the loop
					$slept_secs--;
				}
				if($print_progress_indicator == $TRUE && $out_handles_open > 0) {
					print STDOUT $progress_indicator_char;
				}
				if($execute_every_second && $out_handles_open > 0) {
					&$execute_every_second($slept_secs);
				}
			}
			my $killed = kill 9, $pid; # It is safe to kill in all circumstances. Anyway, we must reap the child process.
			my $command_return_status = $? >> 8;
			if($out_handles_open > 0) {
				$output_error .= 'Timeout';
				$output_all .= 'Timeout';
				$command_exit_status = $EXIT_STATUS_TIMEOUT;
			}
		}
		else {
			# open3 failed!
			$output_error .= 'Could not run command';
			$output_all .= 'Could not run command';
			$command_exit_status = $EXIT_STATUS_FAILED;
		}
	}
	else {
		# Parameter check
		$output_error .= 'Invalid parameters';
		$output_all .= 'Invalid parameters';
		$command_exit_status = $EXIT_STATUS_FAILED;
	}

	return ($command_exit_status, $output_std, $output_error, $output_all);
}


=head1 INCOMPATIBILITIES

Working in MSWin not guaranteed, might also not work in other Unices / OpenVMS / other systems. Tested only in Linux.
Depends mostly on IPC::Open3 working in the system.


=head1 AUTHOR

ikko Koivunalho, C<< <mikko.koivunalho at iki.fi> >>


=head1 BUGS

Please report any bugs or feature requests to C<bug-ipc-runexternal at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=IPC-RunExternal>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IPC::RunExternal


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=IPC-RunExternal>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/IPC-RunExternal>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/IPC-RunExternal>

=item * Search CPAN

L<http://search.cpan.org/dist/IPC-RunExternal/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Mikko Koivunalho.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of IPC::RunExternal
