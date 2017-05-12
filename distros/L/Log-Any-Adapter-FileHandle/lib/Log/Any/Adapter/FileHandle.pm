package Log::Any::Adapter::FileHandle;
$Log::Any::Adapter::FileHandle::VERSION = '0.010';
=head1 NAME

Log::Any::Adapter::FileHandle - A basic Log::Any::Adapter to forward messages to a filehandle

=head1 VERSION

version 0.010

=head1 SYNOPSIS

  use Log::Any qw($log);
  use Log::Any::Adapter;

  # Send all logs to Log::Any::Adapter::FileHandle
  Log::Any::Adapter->set('FileHandle');

  $log->info("Hello world");
 
=head1 DESCRIPTION

This module is a basic adapter that will simply forward log messages to a filehandle, or any object that
supports a 'print' method (L<IO::String>, L<IO::Socket::INET>, Plack's $env->{psgi.errors} object, etc).

I've created it so that my scripts running under damontools or runit can output
messages to locally defined logs.  It does not timestamp messages, that responsbility  is
delegated to the external log capture mechanism.

You can override the default configuration by passing extra arguments to the
C<Log::Any> set_adapter method:

=over 

=item fh

Pass in your IO::Handle-like object here.  If this isn't specified, it will
default to opening STDERR.  If the object supports an autoflush method,
autoflush will be enabled, unless no_autoflush is set.

=item no_autoflush

Disable automatically turning on autoflush on the fh object.

=item format

A sprintf string that controls the formatting of the message.  It is supplied 2
arguments: the log level as supplied by Log::Any (usually all-lowercase), and
the message to be logged.  The default is "[%s] %s\n".  This value should
contain the log record terminator, such as a newline.

=item escape

one of 'none' (default), 'newline', or 'nonascii'.  Controls how messages are
pre-filtered before passing them to a filehandle. This is handy if you want do
smoosh messages into a single line (for easier filtering + processing), or if
you want to filter non ascii characters for safe terminal printing.

=back


=head1 COPYRIGHT AND LICENSE

Copyright 2014 by Jason Jay Rodrigues <jasonjayr+oss@gmail.com>

Log::Any::Adapter::FileHandle is provided "as is" and without any express or
implied warranties, including, without limitation, the implied warranties of
merchantibility and fitness for a particular purpose.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut


use strict;
use warnings;
use Log::Any::Adapter::Util qw(make_method);
use Scalar::Util qw(blessed);
use IO::Handle;
use base qw(Log::Any::Adapter::Base);

sub init {
	my ($self, %attr) = @_;
	
	# if no fh object is set, we default to STDERR.
	if(!exists($self->{fh})) { 
		$self->{fh} = IO::Handle->new_from_fd(fileno(STDERR),'w');
	}

	if($self->{fh}->can('autoflush') && !$self->{no_autoflush}) { 
		$self->{fh}->autoflush(1);
	}
	
	# if no format is set, we default to a reasonable sane default.
	if(!exists($self->{format})) { 
		$self->{format} = "[%s] %s\n";
	}

	if(!exists($self->{escape})) { 
		$self->{escape} = 'none';
	}
}


{ 
	# setup logging methods, that simply print to the given io object.
	my $escapere;
	eval q# $escapere = qr/\P{ASCII}|\p{PosixCntrl}/; "test" =~ $escapere #;
	if($@) {
		# Older versions of perl don't have PosixCntrl. 
		# Since I need to support 5.8.8 for my own use, we have to use compatible RegExp
		$escapere = qr/\P{ASCII}/;
	}

	foreach my $method ( Log::Any->logging_methods() ) {
		my $logger = sub {
			my $self = shift;
			my $message = join('',@_);
			if($self->{escape} eq 'newline' || $self->{escape} eq 'nonascii') { 
				$message =~ s/\n/\\n/sg;
				$message =~ s/\r/\\r/sg;
			}
			if($self->{escape} eq 'nonascii') { 
				$message =~ s/($escapere)/sprintf("\\x{%x}",ord($1))/eg;
			}
			if($self->{fh}) { 
				$self->{fh}->print(sprintf($self->{format}, $method, $message));
			}
		};
		make_method($method, $logger);
	}

	my $true = sub { 1 };

	# In FileHandle, we log *everything*, and let the 
	# log seperation happen in external programs.
	foreach my $method ( Log::Any->detection_methods() ) {
		make_method($method, $true);
	}
}



1;
