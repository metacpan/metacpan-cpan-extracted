# -*- perl -*-

#
# Author: Slaven Rezic
#
# Copyright (C) 2017,2018 Slaven Rezic. All rights reserved.
# This package is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.
#
# Mail: slaven@rezic.de
# WWW:  http://www.rezic.de/eserte/
#

package Doit::WinRPC;

use strict;
use warnings;
our $VERSION = '0.011';

our @ISA = ('Doit::RPC');

use constant STATE_LENGTH => 1;
use constant STATE_BODY   => 2;
use constant STATE_CLOSED => 3;

sub debug {
    my $self = shift;
    if ($self->{debug}) {
	Doit::Log::info($self->{label} . ': ' . $_[0]);
    }
}

sub start_receive_data {
    my($self) = @_;
    $self->{_buffer} = '';
    $self->{_state} = STATE_LENGTH;
    $self->{_curr_length} = undef;
}

sub receive_data {
    my($self) = @_;
    my $pipe = $self->{pipe};

    while() {
	$self->debug(" waiting for line from pipe");
	my $received_data = $pipe->Read;
	if (!defined $received_data) {
	    $self->debug(" disconnect and close");
	    $pipe->Disconnect;
	    $pipe->Close;
	    $self->{_state} = STATE_CLOSED;
	    return;
	}

	$self->{_buffer} .= $received_data;
    BUFFER_LOOP: while () {
	    if ($self->{_state} == STATE_LENGTH) {
		if (length($self->{_buffer}) >= 4) {
		    $self->{_curr_length} = unpack("N", substr($self->{_buffer}, 0, 4));
		    $self->{_buffer} = substr($self->{_buffer}, 4);
		    $self->{_state} = STATE_BODY;
		} else {
		    last BUFFER_LOOP;
		}
	    }
	    if ($self->{_state} == STATE_BODY) {
		if (length($self->{_buffer}) >= $self->{_curr_length}) {
		    my $return_buffer = substr($self->{_buffer}, 0, $self->{_curr_length});
		    $self->{_buffer} = substr($self->{_buffer}, $self->{_curr_length});
		    $self->{_state} = STATE_LENGTH;
		    return $return_buffer;
		} else {
		    last BUFFER_LOOP;
		}
	    }
	}
    }
}

{
    package Doit::WinRPC::Server;

    our @ISA = ('Doit::WinRPC');

    sub new {
	my($class, $runner, $pipename, %options) = @_;

	my $debug = delete $options{debug};
	die "Unhandled options: " . join(" ", %options) if %options;

	bless {
	       runner   => $runner,
	       pipename => $pipename,
	       debug    => $debug,
	       label    => 'WORKER',
	      }, $class;
    }

    sub run {
	my($self) = @_;

	require Win32::Pipe;

	$self->debug("Start worker ($$)...");
	my $pipename = $self->{pipename};
	my $pipe = Win32::Pipe->new($pipename)
	    or die "WORKER: Can't create named pipe '$pipename'";
	$self->{pipe} = $pipe;
	$self->debug("named pipe was created");

	$self->debug("waiting for client");
	if (!$pipe->Connect) {
	    die "WORKER: error while Connect()";
	}
	$self->debug("connected");

	$self->start_receive_data;
	while () {
	    my $buffer = $self->receive_data;
	    my($context, @data);
	    if (defined $buffer) {
		($context, @data) = @{ Storable::thaw($buffer) };
	    }
	    if (!defined $buffer || $data[0] =~ m{^exit$}) {
		if (!defined $buffer) {
		    $self->debug(" got closed connection");
		} else {
		    $self->debug(" got exit command");
		    $self->send_data('r', 'bye-bye');
		}
		$pipe->Disconnect;
		$pipe->Close;
		return;
	    }
	    $self->debug(" calling method $data[0]");
	    my($rettype, @ret) = $self->runner->call_wrapped_method($context, @data);
	    $self->debug(" sending result back");
	    $self->send_data($rettype, @ret);
	}
    }

    sub send_data {
	my($self, @cmd) = @_;
	my $data = Storable::nfreeze(\@cmd);
	my $pipe = $self->{pipe};
	$pipe->Write(pack("N", length($data)));
	$pipe->Write($data); # XXX check result?
    }

}

{
    package Doit::WinRPC::Comm;

    our @ISA = ('Doit::WinRPC');

    sub new {
	my($class, $pipename, %options) = @_;

	die "Please specify pipe name" if !defined $pipename;
	my $debug = delete $options{debug};
	die "Unhandled options: " . join(" ", %options) if %options;

	bless {
	       pipename => $pipename,
	       debug    => $debug,
	       label    => 'COMM',
	      }, $class;
    }

    sub run {
	my($self) = @_;
	my $pipename = $self->{pipename};

	my $full_client_pipename = "\\\\.\\pipe\\$pipename";

	my $infh = \*STDIN;
	my $outfh = \*STDOUT;
	binmode $infh;
	binmode $outfh;

	require Win32::Pipe;

	$self->debug("Start communication process (pid $$)...");

	my $tries = 20;
	my $pipe_err;
	my $pipe = Doit::RPC::gentle_retry(
	    code => sub {
		my(%opts) = @_;
		my $pipe = Win32::Pipe->new($full_client_pipename);
		return $pipe if $pipe;
		${$opts{fail_info_ref}} = "(peer=$full_client_pipename)";
		undef;
	    },
	    retry_msg_code => sub {
		my($seconds) = @_;
		$self->debug("can't connect, sleep for $seconds seconds");
	    },
	    fail_info_ref => \$pipe_err,
	);
	if (!$pipe) {
	    die "COMM: Can't connect to named pipe (after $tries retries) $pipe_err";
	}
	$self->debug("named pipe to worker was created");
	$self->{pipe} = $pipe;

	my $get_and_send_to_pipe = sub ($$$) {
	    my($infh, $inname, $outname) = @_;

	    my $length_buf;
	    read $infh, $length_buf, 4 or die "COMM: reading data from $inname failed (getting length): $!";
	    my $length = unpack("N", $length_buf);
	    $self->debug("starting getting data from $inname, length is $length");
	    my $buf = '';
	    while (1) {
		my $got = read($infh, $buf, $length, length($buf));
		last if $got == $length;
		die "COMM: Unexpected error $got > $length" if $got > $length;
		$length -= $got;
	    }
	    $self->debug("finished reading data from $inname");

	    $pipe->Write($length_buf)
		or die "Error writing to pipe (length data)";
	    $pipe->Write($buf)
		or die "Error writing to pipe (body data)";
	    $self->debug("finished sending data to $outname");
	};

	my $get_from_pipe_and_send = sub ($$$) {
	    my($outfh, $inname, $outname) = @_;

	    my $buf = $self->receive_data;
	    die "COMM: Unexpected error (lost connection?)" if !defined $buf;
	    $self->debug("finished reading data from $inname");

	    print $outfh pack("N", length($buf));
	    print $outfh $buf;
	    $self->debug("finished sending data to $outname");
	};

	$outfh->autoflush(1);
	$self->debug("about to enter loop");
	$self->start_receive_data;
	while () {
	    $self->debug("seen eof from local"), last if eof($infh);
	    $get_and_send_to_pipe->($infh, "local", "worker");
	    $get_from_pipe_and_send->($outfh, "worker", "local");
	}
	$self->debug("exited loop");
    }

}

1;

__END__
