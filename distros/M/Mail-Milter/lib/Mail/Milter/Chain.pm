# $Id: Chain.pm,v 1.10 2004/04/23 15:51:39 tvierling Exp $
#
# Copyright (c) 2002-2004 Todd Vierling <tv@pobox.com> <tv@duh.org>
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
# 
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
# 
# 3. Neither the name of the author nor the names of contributors may be used
# to endorse or promote products derived from this software without specific
# prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

package Mail::Milter::Chain;

use 5.006;

use strict;
use warnings;

use Carp;
use Mail::Milter;
use Sendmail::Milter 0.18; # get needed constants
use UNIVERSAL;

our $VERSION = '0.03';

=pod

=head1 NAME

Mail::Milter::Chain - Perl extension for chaining milter callbacks

=head1 SYNOPSIS

    use Mail::Milter::Chain;

    my $chain = new Mail::Milter::Chain({ connect => \&foo, ... }, ...);
    $chain->register({ connect => \&bar, ... });
    $chain->register({ connect => \&baz, ... });

    $chain->accept_break(1);

    use Sendmail::Milter;
    ...
    Sendmail::Milter::register('foo', $chain, SMFI_CURR_ACTS);

=head1 DESCRIPTION

Mail::Milter::Chain allows multiple milter callback sets to be registered
in a single milter server instance, simulating multiple milters running in
separate servers.  This is typically much less resource intensive than
running each milter in its own server process.

Any contained milter returning SMFIS_REJECT, SMFIS_TEMPFAIL, or
SMFIS_DISCARD will terminate the entire chain and return the respective
code up to the containing chain or milter server.

Normally, a milter returning SMFIS_ACCEPT will remove only that milter
from the chain, allowing others to continue processing the message.  
Alternatively, SMFIS_ACCEPT can be made to terminate the entire chain as
is done for error results; see C<accept_break()> below.

A C<Mail::Milter::Chain> is itself a milter callback hash reference, and
can thus be passed directly to C<Sendmail::Milter::register()> or another
Mail::Milter::Chain container.  IMPORTANT CAVEAT:  Once this object has
been registered with a parent container (a milter or another chain), DO
NOT call C<register()> on this object any longer.  This will result in
difficult to diagnose problems at callback time.

=head1 METHODS

=over 4

=item new([HASHREF, ...])

Creates a Mail::Milter::Chain object.  For convenience, accepts one or
more hash references corresponding to individual callback sets that will
be registered with this chain.

=cut

sub new ($) {
	my $this = bless {}, shift;

	$this->{_acceptbreak} = 0;
	$this->{_chain} = [];

	# "connect" and "helo" use the global chain, and whittle out
	# callbacks to be ignored for the rest of the connection.

	$this->{connect} = sub {
		$this->{_curchain} = [ @{$this->{_chain}} ];

		$this->dispatch('connect', @_);
	};

	$this->{helo} = sub {
		my $rc = $this->dispatch('helo', @_);
		$this->{_connchain} = [ @{$this->{_curchain}} ];

		$rc;
	};

	# "envfrom" uses the chain whittled by "connect" and "helo"
	# each pass through.

	$this->{envfrom} = sub {
		$this->{_curchain} = [ @{$this->{_connchain}} ];

		$this->dispatch('envfrom', @_);
	};

	# "close" must use the global chain always, and must also
	# clean up any internal state.  Every callback must be called;
	# there are no shortcuts.

	$this->{close} = sub {
		my $ctx = shift;
		my $chain = $this->{_chain};

		for (my $i = 0; $i < scalar @$chain; $i++) {
			my $cb = $chain->[$i];
			$ctx->setpriv($cb->{_priv});
			&{$cb->{close}}($ctx, @_) if defined($cb->{close});
		}

		$ctx->setpriv(undef);
		SMFIS_CONTINUE;
	};

	foreach my $callbacks (@_) {
		$this->register($callbacks);
	}

	$this;
}

=pod

=item accept_break(FLAG)

If FLAG is 0 (the default), SMFIS_ACCEPT will only remove the current
milter from the list of callbacks, thus simulating a completely
independent milter server.

If FLAG is 1, SMFIS_ACCEPT will terminate the entire chain and propagate
SMFIS_ACCEPT up to the parent chain or milter server.  This allows a
milter to provide a sort of "whitelist" effect, where SMFIS_ACCEPT speaks
for the entire chain rather than just one milter callback set.

This method returns a reference to the object itself, allowing this
method call to be chained.

=cut

sub accept_break ($$) {
	my $this = shift;
	my $flag = shift;

	croak 'accept_break: flag argument is undef' unless defined($flag);
	$this->{_acceptbreak} = $flag;

	$this;
}

# internal method to add dispatch closure hook as a callback
sub create_callback ($$) {
	my $this = shift;
	my $cbname = shift;

	return 0 if defined($this->{$cbname});

	$this->{$cbname} = sub {
		$this->dispatch($cbname, @_);
	};

	1;
}

# internal method to dispatch a callback
sub dispatch ($$;@) {
	my $this = shift;
	my $cbname = shift;
	my $ctx = shift;
	# @_ is remaining args

	my $chain = $this->{_curchain};
	my $rc = SMFIS_CONTINUE;

	for (my $i = 0; $i < scalar @$chain; $i++) {
		my $cb = $chain->[$i];
		$ctx->setpriv($cb->{_priv});

		my $newrc = defined($cb->{$cbname}) ?
			&{$cb->{$cbname}}($ctx, @_) :
			$rc;

		if ($newrc == SMFIS_TEMPFAIL || $newrc == SMFIS_REJECT) {
			# If "envrcpt", these are special and don't nuke.
			$rc = $newrc;
			@$chain = () unless $cbname eq 'envrcpt';
		} elsif ($newrc == SMFIS_DISCARD) {
			$rc = $newrc;
			@$chain = ();
		} elsif ($newrc == SMFIS_ACCEPT) {
			if ($this->{_acceptbreak}) {
				@$chain = ();
			} else {
				splice(@$chain, $i, 1);
				$i--;
			}
		} elsif ($newrc != SMFIS_CONTINUE) {
			warn "chain element returned invalid result $newrc\n";

			$rc = SMFIS_TEMPFAIL;
			@$chain = ();
		}

		$cb->{_priv} = $ctx->getpriv();
	}

	# If we're still at SMFIS_CONTINUE and the chain is empty,
	# convert to a SMFIS_ACCEPT to bubble up to the parent.
	$rc = SMFIS_ACCEPT if ($rc == SMFIS_CONTINUE && !scalar @$chain);

	$ctx->setpriv(undef);
	$rc;
}

=pod

=item register(HASHREF)

Registers a callback set with this chain.  Do not call after this chain
has itself been registered with a parent container (chain or milter
server).

=cut

sub register ($$) {
	my $this = shift;
	my $callbacks = shift;
	my $pkg = caller;

	croak 'register: callbacks is undef' unless defined($callbacks);
	croak 'register: callbacks not hash ref' unless UNIVERSAL::isa($callbacks, 'HASH');

	# make internal copy, and convert to code references
	my $ncallbacks = {};

	foreach my $cbname (keys %Sendmail::Milter::DEFAULT_CALLBACKS) {
		my $cb = $callbacks->{$cbname};
		next unless defined($cb);

		$ncallbacks->{$cbname} = Mail::Milter::resolve_callback($cb, $pkg);
		$this->create_callback($cbname);
	}

	# add to chain
	push(@{$this->{_chain}}, $ncallbacks);

	1;
}

1;
__END__

=back

=head1 AUTHOR

Todd Vierling, E<lt>tv@duh.orgE<gt> E<lt>tv@pobox.comE<gt>

=head1 SEE ALSO

L<Mail::Milter>, L<Sendmail::Milter>

=cut
