=head1 NAME

Konstrukt::Handler - Base class for handlers that control the processing of the requests

=head1 SYNOPSIS

	use Konstrukt::Handler;
	
	#inherit new(), process() and emergency_exit()
	use base 'Konstrukt::Handler';
	
	#create handler sub. usually a bit more comprehensive. see existing handlers
	sub handler {
		my ($self) = @_;
		print $self->process();
	}
	
	#optional: overwrite method emergency_exit to provide some more info.
	sub emergency_exit {
		my ($self) = @_;
		#do something. e.g. print out error messages.
		die;
	}

=head1 DESCRIPTION

Base class for the Konstrukt handlers.

You should inherit from this class when building your own handler.

You will find the handlers currently available in the Konstrukt::Handler directory.

Plugins and other module may access some request-specific data:

	#the absolute path to the processed file
	$Konstrukt::Handler->{abs_filename}
	
	#the path to the processed file relative to the document root
	$Konstrukt::Handler->{filename}
	
	#the environment variables of this process as an hashref
	$Konstrukt::Handler->{ENV}
	
	#cookies as an hashref of cookie objects
	$Konstrukt::Handler->{cookies}
	#create new cookie:
	$Konstrukt::Handler->{cookies}->{foo} = CGI::Cookie->new(-name => 'foo', -value => 'bar');

=head1 CONFIGURATION

Defaults:

	#put the debug and error messages at the end of the output.
	#also print these messages on a critical error.
	handler/show_debug_messages 0
	handler/show_error_messages 1
	
=cut

package Konstrukt::Handler;

use strict;
use warnings;

use CGI;
use CGI::Cookie;
use Time::HiRes 'time';

use Konstrukt;
use Konstrukt::Cache;
use Konstrukt::DBI;
use Konstrukt::Debug;
use Konstrukt::Event;
use Konstrukt::File;
use Konstrukt::Lib;
use Konstrukt::Parser;
use Konstrukt::Plugin;
use Konstrukt::PrintRedirector;
use Konstrukt::Settings;
use Konstrukt::TagHandler::Plugin;

=head1 METHODS

=head2 new

Constructor of this class

B<Parameters>:

=over

=item * $root - The B<absolute> path of the document root

=item * $filename - The file to process (B<relative> to the document root)

=back

=cut
sub new {
	my ($class, $root, $filename) = @_;
	
	my $self = bless { ENV => \%ENV }, $class;
	$Konstrukt::Handler = $self;
	
	#file management
	die("No document root passed!") if not defined $root;
	die("No filename passed!")      if not defined $filename;
	$Konstrukt::File->set_root($root);
	
	$Konstrukt::Handler->{filename}     = $filename;
	$Konstrukt::Handler->{abs_filename} = $Konstrukt::File->absolute_path($filename);
	#warn "HTTP_COOKIE: " $Konstrukt::Handler->{ENV}->{HTTP_COOKIE}
	$Konstrukt::Handler->{cookies}      = CGI::Cookie->fetch(); #fetch cookies (hashref)
	
	#init some generally needed modules
	$Konstrukt::Settings->init();           #load settings
	
	#set default settings
	$Konstrukt::Settings->default('handler/show_debug_messages' => 0);
	$Konstrukt::Settings->default('handler/show_error_messages' => 1);
	#set default for the auto installation of some modules.
	$Konstrukt::Settings->default('autoinstall' => 0);
	
	$Konstrukt::Lib->init();                #set defaults
	$Konstrukt::CGI = CGI->new();           #gobal CGI object
	$Konstrukt::Debug->init();              #delete messages
	$Konstrukt::Cache->init();              #clear cache-list
	$Konstrukt::DBI->init();                #set defaults etc.
	$Konstrukt::Event->init();              #reset events
	$Konstrukt::Parser->init();             #set default settings
	$Konstrukt::PrintRedirector->init();    #deactivate
	$Konstrukt::TagHandler::Plugin->init(); #clear list of initialized plugins
	#init, load/set cookie, blah
	if ($Konstrukt::Settings->get('session/use')) {
		require Konstrukt::Session;
		$Konstrukt::Session->init();
	}
	
	#add additional paths to @INC
	my $lib = $Konstrukt::Settings->get('lib');
	unshift @INC, split /\s*;\s*/, $lib	if $lib;
	
	#the root _must_ be absolute! warn if it might be relative
	$Konstrukt::Debug->error_message("The supplied document root ('$root') _must_ be an absolute path but it looks like a relative path!")
		if Konstrukt::Debug::WARNING and $root !~ /^(\/|[a-z]\:[\\\/])/i;
	
	#the file name _must_ be relative! warn if it might be absolute
	$Konstrukt::Debug->error_message("The supplied filename ('$filename') _must_ be relative to the document root ('$root') but it looks like an absolute path!")
		if Konstrukt::Debug::WARNING and substr($filename, 0, length($root)) eq $root;
	
	return $self;
}

=head2 process

Processes the request. Returns the result.

=cut
sub process {
	my ($self) = @_;
	
	#benchmarking
	my ($starttime, $duration_prepare, $duration_execute);
	$starttime = time();

	#frequently used variables
	my $filename     = $Konstrukt::Handler->{filename};
	my $abs_filename = $Konstrukt::Handler->{abs_filename};

	#activate print redirector
	$Konstrukt::PrintRedirector->activate();
	
	#parse against plugins only
	my $actions = { '&' => $Konstrukt::TagHandler::Plugin };
	#check for an existing cache
	my $prepared = $Konstrukt::Cache->get_cache($abs_filename);
	if (not $prepared) {
		#no cached results available
		#read the input file
		my $input = $Konstrukt::File->read_and_track($filename);
		#prepare
		if (defined($input)) {
			$Konstrukt::Debug->debug_message("=== preparing ===\n") if Konstrukt::Debug::DEBUG;
			$prepared = $Konstrukt::Parser->prepare(\$input, $actions);
			#cache results
			$Konstrukt::Cache->write_cache($abs_filename, $prepared);
		} else {
			$Konstrukt::Debug->error_message("Input file \"$filename\" empty or not readable", 1);
		}
	}
	$duration_prepare = time() - $starttime;
	$Konstrukt::Debug->debug_message("=== prepared ===\n" . $prepared->tree_to_string()) if Konstrukt::Debug::DEBUG;
	$Konstrukt::Debug->debug_message(sprintf("$filename prepared in %.6f seconds.", $duration_prepare)) if Konstrukt::Debug::INFO;
	$Konstrukt::Cache->prevent_caching($abs_filename, 3);
	#execute
	$Konstrukt::Debug->debug_message("=== executing ===\n") if Konstrukt::Debug::DEBUG;
	$starttime = time();
	my $executed = $Konstrukt::Parser->execute($prepared, $actions);
	$duration_execute = time() - $starttime;
	$Konstrukt::Debug->debug_message("=== executed ===\n" . $executed->tree_to_string()) if Konstrukt::Debug::DEBUG;
	$Konstrukt::Debug->debug_message(sprintf("$filename executed in %.6f seconds.", $duration_execute)) if Konstrukt::Debug::INFO;
	$Konstrukt::Debug->debug_message(sprintf("$filename processed in %.6f seconds.", $duration_prepare + $duration_execute)) if Konstrukt::Debug::INFO;
	
	#deactivate print redirection
	$Konstrukt::PrintRedirector->deactivate();
	
	#return result
	return $executed->children_to_string();
}
#= /handler

=head2 emergency_exit

Will be called on a critical error. You should clean up here, put out the
error messages and abort the further processing ("die").

This method should be overwritten by the inheriting class.

=cut
sub emergency_exit {
	my ($self) = @_;
	
	#print $Konstrukt::Debug->format_error_messages();
	#print $Konstrukt::Debug->format_debug_messages();
	
	die __PACKAGE__."->emergency_exit: Critical error.";
}

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Handler::Apache>, L<Konstrukt::Handler::CGI>, L<Konstrukt::Handler::File>, L<Konstrukt>

=cut
