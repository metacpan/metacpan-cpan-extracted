=head1 NAME

Konstrukt::Debug - Debug and error message handling 

=head1 SYNOPSIS
	
	use Konstrukt::Debug;
	$Konstrukt::Debug->debug_message("message") if Konstrukt::Debug::DEBUG;
	$Konstrukt::Debug->error_message("message") if Konstrukt::Debug::ERROR;

=head1 DESCRIPTION

This module offers two general classes of debug-messages: debug and error.
Additionally there are 5 constants (C<ERROR, WARNING, INFO, NOTICE, DEBUG>)
which determine how noisy the debug output will be.
See L</CONFIGURATION> for details on that.

This should be enough for most purposes. A too complex system like log4perl
would be overkill for our purposes.

This module will determine the package and method, from which the message has
been sent automatically and print it out.

The messages get collected and may be printed out on demand.

=head1 CONFIGURATION

Defaults:

	#warn() the messages. this may be useful to put them in a server log.
	debug/warn_debug_messages 0
	debug/warn_error_messages 1
	
	#don't provide additional information on the error source
	debug/short_messages      1
	
	#put the messages into a permanent log (using the log plugin)
	debug/log_debug_messages  0
	debug/log_error_messages  0

You can also define the "noisiness" of the debug messages.
In the head of the source of this module you can turn on (and off) these constants:

=over

=item * Konstrukt::Debug::ERROR

=item * Konstrukt::Debug::WARNING

=item * Konstrukt::Debug::INFO

=item * Konstrukt::Debug::NOTICE

=item * Konstrukt::Debug::DEBUG

=back

You should alsway use these constants as conditionals for your debug output
as described L<above|/SYNOPSIS>. This has the advantage that the code for
your debug messages will be completely removed during compilation when the
according debug constant is set to 0. This will lead to a major performance
increase.

As a default ERROR, WARNING and INFO are set to 1, the other ones are set to 0.

=cut

package Konstrukt::Debug;

use strict;
use warnings;

#set each constant to 1 to enable the specified debug level
use constant ERROR   => 1; #should never be set to 0
use constant WARNING => 1;
use constant INFO    => 0;
use constant NOTICE  => 0;
use constant DEBUG   => 0;

use Konstrukt::Settings;

=head1 METHODS

=head2 new

Constructor of this class

=cut
sub new {
	my ($class) = @_;
	return bless { debug_messages => [], error_messages => [] }, $class;
}
#= /new

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	
	#set default settings
	$Konstrukt::Settings->default('debug/warn_debug_messages' => 0);
	$Konstrukt::Settings->default('debug/warn_error_messages' => 1);
	$Konstrukt::Settings->default('debug/log_debug_messages'  => 0);
	$Konstrukt::Settings->default('debug/log_error_messages'  => 0);
	$Konstrukt::Settings->default('debug/short_messages'      => 1);
	
	#reset collections
	$self->{debug_messages} = [];
	$self->{error_messages} = [];
	
	return 1;
}
#= /init

=head2 error_message

Will put the error message on the stack and prevent caching of the current file
as there were errors.

B<Parameters>:

=over

=item * $message - The error message

=item * $exit - Should be true when there was a critical error and the further
processing should be interrupted.

=back

=cut
sub error_message {
	my ($self, $message, $exit) = @_;
	
	#the returned data from caller() is a bit weird. the subroutine we want is stated in caller(1) and not 0.
	my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(0);
	$subroutine = (caller(1))[3] || '(unknown)';
	my $subonly = $subroutine;
	$subonly =~ s/.*::(.*?)$/$1/;
	
	$message = "(undef)" unless defined $message;
	$message = $package . "->" . $subonly . ": " . $message;
	chomp($message);
	$message = "$message (Requested file: $Konstrukt::Handler->{filename}"
		. (defined $Konstrukt::File->current_file() ? " - Current file: " . $Konstrukt::File->relative_path($Konstrukt::File->current_file()) : '')
		. " - Package: $package - Sub/Method: $subroutine - Source file: $filename @ line $line)"
		unless $Konstrukt::Settings->get('debug/short_messages');
	
	push @{$self->{error_messages}}, $message;
	
	#put server log entry
	warn "$message\n" if $Konstrukt::Settings->get('debug/warn_error_messages');
	
	$Konstrukt::Handler->emergency_exit() if $exit;
	
	#all operations after this point won't be executed on critical errors:
	
	#we don't want to cache a file with errors...
	#add the condition for each tracked file
	if (defined $Konstrukt::Cache and defined $Konstrukt::File) {
		foreach my $file ($Konstrukt::File->get_files()) {
			$Konstrukt::Cache->prevent_caching($file, 1) unless $Konstrukt::Cache->{$file}->{prevent_caching};
		}
	}
	
	#put permanent log entry. don't log on critical errors ^
	if ($Konstrukt::Settings->get('debug/log_error_messages')) {
		require Konstrukt::Plugin; #cannot C<use> this because this will lead into circular dependencies
		my $log = Konstrukt::Plugin::use_plugin('log');
		$log->put(__PACKAGE__ . '->error_message', $message);
	}
}
#= /error_message

=head2 debug_message

Collects some useful but not essentially neccessary information.

B<Parameters>:

=over

=item * $message - The debug message

=back

=cut
sub debug_message {
	my ($self, $message) = @_;
	
	#the returned data from caller() is a bit weird. the subroutine we want is stated in caller(1) and not 0.
	my ($package, $filename, $line, $subroutine, $hasargs, $wantarray, $evaltext, $is_require, $hints, $bitmask) = caller(0);
	$subroutine = (caller(1))[3] || '(unknown)';
	my $subonly = $subroutine;
	$subonly =~ s/.*::(.*?)$/$1/;
	
	$message = "(undef)" unless defined $message;
	$message = $package . "->" . $subonly . ": " . $message;
	chomp($message);
	$message = "$message (Requested file: $Konstrukt::Handler->{filename}"
		. (defined $Konstrukt::File->current_file() ? " - Current file: " . $Konstrukt::File->relative_path($Konstrukt::File->current_file()) : '')
		. " - Package: $package - Sub/Method: $subroutine - Source file: $filename @ line $line)"
		unless $Konstrukt::Settings->get('debug/short_messages');
	
	push @{$self->{debug_messages}}, $message;
	
	#put server log entry
	warn "$message\n" if $Konstrukt::Settings->get('debug/warn_debug_messages');
	
	#put permanent log entry
	if ($Konstrukt::Settings->get('debug/log_debug_messages')) {
		require Konstrukt::Plugin; #cannot C<use> this because this will lead into circular dependencies
		my $log = Konstrukt::Plugin::use_plugin('log');
		$log->put(__PACKAGE__ . '->debug_message', $message);
	}
}
#= /debug_message

=head2 format_error_messages

Joins all error messages in a string returns them.

=cut
sub format_error_messages {
	my ($self) = @_;

	my $errors = '';
	if (@{$self->{error_messages}}) {#do we have errors?
		$errors .= "Errors/Warnings:\n";
		foreach my $error (@{$self->{error_messages}}) {
			$errors .= $error . "\n";
		}
	}
	
	return $errors;
}
#= /format_error_messages

=head2 format_debug_messages

Joins all debug messages in a string returns them.

=cut
sub format_debug_messages {
	my ($self) = @_;
	
	my $debugs = '';
	if (@{$self->{debug_messages}}) {#do we have debug messages?
		$debugs .= "Debug messages:\n";
		foreach my $debug (@{$self->{debug_messages}}) {
			$debugs .= $debug . "\n";
		}
	}
	
	return $debugs;
}
#= /format_debug_messages

#create global object
sub BEGIN { $Konstrukt::Debug = __PACKAGE__->new() unless defined $Konstrukt::Debug; }

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt>

=cut
