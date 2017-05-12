# Festival::Client::Async:  Non-blocking interface to a Festival server
#
# Copyright (c) 2000 Cepstral LLC. All rights Reserved.
#
# This module is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# Written by David Huggins-Daines <dhd@cepstral.com>

package Festival::Client::Async;
use strict;
use IO::Socket;
use Fcntl;

BEGIN {
    unless (defined &DEBUG) {
	*DEBUG = sub () { 0 }
    }
};

use vars qw($VERSION @ISA @EXPORT_OK);
$VERSION = 0.03_03;
@ISA = qw(Exporter);
@EXPORT_OK = qw(parse_lisp);

sub parse_lisp {
    my $lisp = shift;

    my (@stack, $top);
    $top = [];
    @stack = ($top);
    while ($lisp =~ m{(
		       [()]
		      |
		       "(?:[^"\\]+|\\.)*"
		      |
		       \#<[^>]+>
		      |
		       [^()\s]+
		       )}xg) {
	my $tok = $1;
	if ($tok eq '(') {
	    my $newtop = [];
	    push @$top, $newtop;
	    push @stack, ($top = $newtop);
	} elsif ($tok eq ')') {
	    pop @stack;
	    $top = $stack[-1];
	    die "stack underflow" unless defined $top;
	} else {
	    push @$top, $tok;
	}
    }

    return $top->[0];
}

sub new {
    my $this = shift;
    my $class = ref $this || $this;

    my ($host, $port) = @_;

    my $s = IO::Socket::INET->new(Proto     => 'tcp',
				  PeerAddr  => $host || 'localhost',
				  PeerPort  => $port || 1314)
	or return undef;
    binmode $s;

    my $self = bless {
		      blocked => 0,
		      sock => $s,
		      outbuf => "",
		      outq => {
			       LP => [],
			      },
		      intag => "",
		      inbuf => "",
		      inq => {
			      LP => [],
			      WV => [],
			      OK => [],
			      ER => [],
			     },
		     }, $class;
    $self->unblock;
    return $self;
}

sub fh {
    my $self = shift;
    return $self->{sock};
}

sub block {
    my $self = shift;
    my $flags = 0;
    fcntl $self->{sock}, F_GETFL, $flags
	or die "fcntl(F_GETFL) failed: $!";
    fcntl $self->{sock}, F_SETFL, $flags & ~O_NONBLOCK
	or die "fcntl(F_SETFL) failed: $!";
    $self->{blocked} = 1;
}

sub unblock {
    my $self = shift;
    my $flags = 0;
    fcntl $self->{sock}, F_GETFL, $flags
	or die "fcntl(F_GETFL) failed: $!";
    fcntl $self->{sock}, F_SETFL, $flags | O_NONBLOCK
	or die "fcntl(F_SETFL) failed: $!";
    $self->{blocked} = 0;
}

# Protocol encoding
use constant KEY     => "ft_StUfF_key";
use constant KEYLEN  => length KEY;

sub write_more {
    my $self = shift;

    while (defined(my $expr = shift @{$self->{outq}{LP}})) {
	$self->{outbuf} .= $expr;
    }

    my $count;
    while (defined(my $b = syswrite($self->{sock}, $self->{outbuf}, 4096))) {
	print "wrote $b bytes\n" if DEBUG;
	last if $b == 0;

	$count += $b;
	substr($self->{outbuf}, 0, $b) = "";
	last if $self->{blocked} and $b < 4096;
    }

    return $count;
}

sub read_more {
    my $self = shift;
    my $fh = $self->{sock};

    my $count = 0;
    my $burf = sysread $fh, my($rbuf), 4096;
    print "read $burf bytes\n" if DEBUG;
    $self->{inbuf} .= $rbuf;

 CHUNK:
    while (length($self->{inbuf}) > 0) {
	# In the middle of a tag?
	if ($self->{intag}) {
	    # Look for the stuff key
	    if ((my $i = index($self->{inbuf}, KEY)) != $[-1) {
		if (substr($self->{inbuf}, $i+KEYLEN, 1) eq 'X') {
		    # If there's an X at the end, it's literal
		    substr($self->{inbuf}, $i+KEYLEN, 1) = "";
		} else {
		    # Otherwise, we've got a complete waveform/expr/whatever
		    push @{$self->{inq}{$self->{intag}}},
			substr($self->{inbuf}, 0, $i);
		    print "queued $i bytes of $self->{intag}\n" if DEBUG;
		    substr($self->{inbuf}, 0, $i+KEYLEN) = "";
		    $self->{intag} = "";
		    $count += $i;
		}
	    } else {
		# Maybe we got *part* of the stuff key at the end of
		# this block.  Stranger things have happened.
		my $leftover = "";
	    PARTIAL:
		for my $sub (1..KEYLEN-1) {
		    my $foo = \substr($self->{inbuf}, -$sub);
		    my $bar = substr(KEY, 0, $sub);
		    if ($$foo eq $bar) {
			$$foo = "";
			$leftover = $bar;
			last PARTIAL;
		    }
		}

		# In any case we don't have any more data
		push @{$self->{inq}{$self->{intag}}}, $self->{inbuf};
		print "queued ", length($self->{inbuf}), " bytes of $self->{intag}\n"
		    if DEBUG;
		$count += length($self->{inbuf});
		$self->{inbuf} = $leftover;

		# But don't keep looping if we left some stuff in there!
		last CHUNK if $leftover;
	    }
	} else {
	    if ($self->{inbuf} =~ s/^(WV|LP|ER|OK)\n//) {
		print "got tag $1\n" if DEBUG;
		$count += length($1);
		# We got a tag, so a new type of data is coming
		if ($1 eq 'OK') {
		    push @{$self->{inq}{OK}}, time;
		} elsif ($1 eq 'ER') {
		    push @{$self->{inq}{ER}}, time;
		} else {
		    $self->{intag} = $1;
		}
	    } else {
		# Should not actually be fatal, it's always possible
		# we just got the middle of a tag.
		last CHUNK;
	    }
	}
    }

    return $count;
}

sub server_eval_sync {
    my ($self, $lisp, $actions) = @_;
    $self->block;
    $self->server_eval($lisp);

    unless ($self->write_more) {
	$self->unblock;
	return undef;
    }
    while ($self->read_more) {
	while (defined(my $wav = $self->dequeue_wave)) {
	    $actions->{WV}->($wav) if exists $actions->{WV};
	}
	while (defined(my $lisp = $self->dequeue_lisp)) {
	    $actions->{LP}->($lisp) if exists $actions->{LP};
	}
	if (defined($self->dequeue_error)) {
	    $self->unblock;
	    return undef;
	}
	if (defined($self->dequeue_ok)) {
	    last;
	}
    }
    $self->unblock;
    return 1;
}

# Don't mix this with async operations :(
sub server_eval_sync_old {
    my ($self, $lisp, $actions) = @_;
    my $fh = $self->{sock};
    $self->block;

    local $|=1;

    my ($rbuf, $rest, $tag);
    print $fh $lisp;
    while (defined($rbuf = $rest) or defined($rbuf = <$fh>)) {
	undef $rest;
	if ($rbuf =~ s/^(WV|LP|ER|OK)\n$//s) {
	    $tag = $1;
	    last if $tag eq 'OK' or $tag eq 'ER';
	}

	if ((my $i = index($rbuf, KEY)) != $[-1) {
	    if (substr($rbuf, $i+KEYLEN, 1) eq 'X') {
		substr($rbuf, $i+KEYLEN, 1) = "";
	    } else {
		$rest = substr($rbuf, $i+KEYLEN);
		substr($rbuf, $i) = "";
	    }
	}

	if (defined $tag and exists $actions->{$tag}) {
	    $actions->{$tag}->($rbuf);
	}
    }

    $self->unblock;
    return defined($tag) && ($tag eq 'OK');
}

sub server_eval {
    my $self = shift;
    push @{$self->{outq}{LP}}, @_;
}

sub write_pending {
    my $self = shift;
    return @{$self->{outq}{LP}};
}

sub wave_pending {
    my $self = shift;
    return @{$self->{inq}{WV}};
}

sub lisp_pending {
    my $self = shift;
    return @{$self->{inq}{LP}};
}

sub ok_pending {
    my $self = shift;
    return @{$self->{inq}{OK}};
}

sub error_pending {
    my $self = shift;
    return @{$self->{inq}{ER}};
}

sub dequeue_wave {
    my $self = shift;
    shift @{$self->{inq}{WV}};
}

sub dequeue_lisp {
    my $self = shift;
    shift @{$self->{inq}{LP}};
}

sub dequeue_ok {
    my $self = shift;
    shift @{$self->{inq}{OK}};
}

sub dequeue_error {
    my $self = shift;
    shift @{$self->{inq}{ER}};
}

1;
__END__

=head1 NAME

Festival::Client::Async - Non-blocking interface to a Festival server

=head1 SYNOPSIS

  use Festival::Client::Async qw(parse_lisp);

  my $fest = Festival::Client::Async->new($host, $port);
  $fest->server_eval_sync($lisp, \%actions); # blocking
  $fest->server_eval($lisp); # just queues $lisp for writing
  if ($fest->write_pending) {
      while (defined(my $b = $fest->write_more)) {
          last if $b == 0;
      }
  }
  while (defined(my $b = $fest->read_more)) {
      last if $b == 0;
  }
  if ($fest->error_pending) {
      # Oops
  }
  while ($fest->wave_pending) {
      my $waveform_data = $fest->dequeue_wave;

      # Do something with it
  }
  while ($fest->lisp_pending) {
      my $lisp = $fest->dequeue_lisp
      my $arr = parse_lisp($lisp);

      # Do something with it
  }

=head1 DESCRIPTION

This module provides Yet Another interface to a Festival speech
synthesis server.

Why should you use this module instead of the already existing ones?

=over 4

=item 1

Non-blocking operation.  This means that this module can interoperate
with a Tk, Gtk, Event, or POE event loop without the need to fork a
separate process.

=item 2

More flexible interface for blocking operation.  You can register
separate callbacks to handle the results of Scheme evaluation,
waveform data, and OK/error messages.

=item 3

This module is simply a very thin wrapper around Festival's Scheme
read-evaluate-print loop.  If you don't know what that is, you may not
want this module.  If you do know what that is, this will allow you to
use this module to do basically anything you could do at the actual
Festival interpreter prompt.  You are not limited to doing
simple text-to-speech to the local audio device.

=back

=head1 USAGE

=over 4

=item C<new>

  my $fest = Festival::Client::Async->new($host, $port)
      or die "couldn't connect: $!";

The C<$host> and C<$port> parameters are optional, and default to
'localhost' and 1314, respectively.

If the connection to the server fails, this returns undef.

=item C<fh>

  $kernel->select_read($fest->fh, 'foo_state');

This method returns the actual filehandle for the socket connection to
the server.  You'll probably need it for non-blocking operation.

=back

Now that you've connected to the server, what do you do with it?  As
mentioned above, this module is just a client for the Festival repl.
Therefore, the answer to the question is 'evaluate S-expressions'.
This is accomplished using the C<server_eval_sync> and C<server_eval>
methods, described below.

A few S-expressions you might want to evaluate are:

  (Parameter.set 'Wavefiletype 'raw) ;; send back raw wave data
  (tts_textall "$text" nil) ;; text-to-speech and send the waveform
  (SayText "$text") ;; text-to-speech to the local audio device
  (voice_$foo) ;; switch to the $foo voice

The Festival server can send you back a few things:

=over 4

=item Results of evaluation

These are accessed via the C<LP> callback for blocking operation, or
the C<lisp_pending>/C<dequeue_lisp> methods in non-blocking operation.
The server sends back a single result on a line by itself, followed by
an empty line. (Note: I'm not sure if this is actually guaranteed
anywhere in the Festival code, and you can probably get it rather
confused if you embed newlines in strings and such.  Just Don't Do
That.)

C<Festival::Client::Async> exports (or rather, can export - you will
have to specify it explicitly in the C<use> statement) one subroutine,
C<parse_lisp>, which is a convenience function for de-lisp-ifying
results sent back from Festival.  It tries its best to create Perl
data structures approximating the Lisp ones spat out by Festival.
Symbols, numbers, and strings are all converted to scalars, while
lists are turned into arrays.  For example,

  ((foo 123) ("bar" "baz") ())

will be parsed as:

  [["foo" 123] ["bar" "baz"] []]

=item Waveform data

These are accessed via the C<WV> callback for blocking operation, or
the C<waveform_pending>/C<dequeue_wave> methods in non-blocking
operation.  They will be in whatever format is set in the
C<Wavefiletype> parameter in the Festival server.  By default this is
NIST audio files, which contain some metadata that will sound funny if
you try to play it to an audio device.

Unfortunately there is no way to find out what sample rate Festival is
going to send at you except by examining the headers in the audio data
it sends.  The individual voices each have their own sampling rate,
which is typically 16000Hz, but can vary.  So, if this bothers you,
you must either use a headered file format (NIST is textual and thus
easy to parse), or if you use raw data, you must know ahead of time
what rates your voices use, or build an utterance structure manually
and resample it to the desired rate.  Here's an example of a Scheme
expression that will synthesize some text, resample it, and send the
waveform to the client (substitute your text and sampling rate for
$text and $sampling_rate, obviously):

  (let ((utt (Utterance Text "$text")))
    (begin
      (utt.synth utt)
      (utt.wave.resample utt $sampling_rate)
      (utt.send.wave.client utt)))

You might need to resample anyway if you're stuck with, say, an Intel
on-board audio device that only does 48kHz.  Resampling is expensive,
don't do it if you can help it.

=item Acknowledgements or errors

After sending the results of evaluation, Festival will send an OK.
You can't capture this in the blocking mode, since it just gets
translated into the return value of the C<server_eval_sync> method.
In non-blocking mode, this gets queued as a timestamp.

If an error occurs, you may not get results of evaluatoin, and you
certainly won't get an OK, but rather an error.  Again, this gets
translated to the return value in blocking mode, but is queued as a
timestamp (since Festival doesn't actually send you any meaningful
data with the error message).

=back

There is no method to call to disconnect from the server.  This will
just happen automatically if the client object goes out of scope; you
can also force it to occur by calling C<undef> on that variable.

=head2 Blocking Operation

  $fest->server_eval_sync($sexp,
                          {
			    LP => sub {
				     my $lisp = shift;
				     # .. etc ...
			    },
			    WV => sub {
				     my $wave = shift;
				     # .. etc ...
			    }
                          }) or die "error from server";

The blocking mode of operation will evaluate a single S-expression on
the server, and wait for it to complete.  Access to the results of
that expression is done by giving callbacks to the C<server_eval_sync>
method.  These callbacks will be called with the individual chunks of
Lisp or waveform data as they come in.

There are no callbacks for acknowledgements or errors, since only one
S-expression can be evaluated at a time.  Instead, the method will
return a true value for a successful evaluation, or C<undef> for
failure (unfortunately there's no good way to find out exactly what
failed, since the server won't tell you).

=head2 Non-blocking Operation

The following example is kind of long-winded ... bear with me.

  use IO::Select;
  my $s = IO::Select->new($fest->fh);

  $fest->server_eval($sexp);

  # In a real event loop, you'd want to make sure $fest->fh is being
  # watched for ability to accept output at this point.

  EVENT:
  while (1) {
      if ($s->can_write) {
          my $b = $fest->write_more;
          if ($b == 0) {
              # In a real event loop, you'd want to stop or suspend
              # watching $fest->fh for output at this point.
          }
      }

      if ($s->can_read) {
          my $b = $fest->read_more;
	  last EVENT if $b == 0;

	  if ($fest->waveform_pending) {
	      while (defined(my $wav = $fest->dequeue_wave)) {
		  # ... do something ...
	      }
	  }
	  if ($fest->lisp_pending) {
	      while (defined(my $lisp = $fest->dequeue_wave)) {
		  if ($lisp) {
		      # ... do something ...
		  } else {
		      # That was the end of one evaluation, if you're
		      # keeping track
		  }
	      }
	  }
	  if ($fest->ok_pending) {
	      while (defined(my $ok_time = $fest->dequeue_ok)) {
		  # ... do something ...
	      }
	  }
	  if ($fest->error_pending) {
	      while (defined(my $error_time = $fest->dequeue_error)) {
		  # ... do something ...
	      }
	  }
      }
  }

This mode of operation is meant to be used from a C<select> loop, or
some more sophisticated event loop, such as the POE or Gtk ones, which
has the ability to watch filehandles for activity.

To use it, you will want to add the filehandle for the Festival client
object (obtained using the C<fh> method) to your set of filehandles
being watched for input and output (urgent data is not used, so there
is no need to watch it for exceptions).  Then, you want to call the
C<read_more> and C<write_more> methods in response to read and write
ready events, respectively.

C<read_more> will return zero if the server closes the connection, or
if it fails to read any data.  It is guaranteed (I hope) that it will
successfully read data if called in the manner described above.

C<write_more> will return zero if there is no more data to be written.
At this point, you'll want to stop watching the filehandle for output
until you have more data to write; otherwise you'll spin endlessly
since the filehandle will continue to be ready for output, thus
causing your C<select> call to be woken up.

To start evaluation, call the C<server_eval> method.  This doesn't
actually send anything to the server, but places an S-expression on
the output queue.

After calling C<read_more>, you can check to see if there are any
results available using the various C<foo_pending> methods, and get
the available data using the various C<dequeue_foo> methods, as shown
above (the example shows them all, I'm not going to repeat them here).

=head1 BUGS

The non-blocking mode does no tracking of which Lisp result
corresponds to which expression; it's trivial to do this in a higher
level (and in fact, C<POE::Component::Festival> does this), but
arguably it should be in this module.

People might want convenience functions to shield them from all that
nasty Lisp.

It's probably possible to confuse the protocol handling in here with
things like Lisp results containing embedded newlines; the Festival
client-to-server protocol is kind of wonky.

=head1 SEE ALSO

The Festival web site (http://www.cstr.ed.ac.uk/projects/festival/),
the Festvox website (http://www.festvox.org/), the documentation
included in the Festival distribution, L<IO::Select>, and perl(1p).

=head1 AUTHOR

David Huggins-Daines <dhd@cepstral.com>

=cut
