#!/usr/bin/perl

package Devel::STDERR::Indent;
use Moose;

no warnings 'recursion';

use Scalar::Util qw(weaken);

use namespace::clean -except => "meta";

use Sub::Exporter -setup => {
	exports => [qw(indent)],
};

our $VERSION = "0.06";

sub indent {
	my $h = __PACKAGE__->new(@_);
	$h->enter;
	return $h;
}

sub BUILDARGS {
	my ( $class, @args ) = @_;

	unshift @args, "message" if @args % 2 == 1;

	return {@args};
}

has message => (
	isa => "Str",
	is  => "ro",
	predicate => "has_message",
);

has indent_string => (
	isa => "Str",
	is  => "ro",
	default => "    ",
);

has enter_string => (
	isa => "Str",
	is  => "ro",
	default => " -> ",
);

has leave_string => (
	isa => "Str",
	is  => "ro",
	default => " <- ",
);

has _previous_hook => (
	is  => "rw",
	predicate => "_has_previous_hook",
);

has _active => (
	isa => "Bool",
	is  => "rw",
);	

sub DEMOLISH {
	my $self = shift;
	$self->leave;
}

sub enter {
	my $self = shift;

	return if $self->_active;

	$self->install;

	if ( $self->has_message ) {
		$self->emit( $self->enter_string . $self->message, "\n" );
	}

	$self->_active(1);
}

sub leave {
	my $self = shift;

	return unless $self->_active;

	if ( $self->has_message ) {
		$self->emit( $self->leave_string . $self->message, "\n" );
	}

	$self->uninstall;

	$self->_active(0);
}

sub warn {
	my ( $self, @output ) = @_;

	$self->emit( $self->format(@output) );
}

sub emit {
	my ( $self, @output ) = @_;

	if ( my $hook = $self->_previous_hook ) {
		$hook->(@output);
	} else {
		local $,;
		local $\;
		print STDERR @output;
	}
}

sub format {
	my ( $self, @str ) = @_;

	my $str = join "", @str;

	if ( $self->should_indent ) {
		my $indent = $self->indent_string;

		# indent every line
		$str =~ s/^/$indent/gm;

		return $str;
	} else {
		return $str;
	}
}

sub should_indent {
	my $self = shift;

	# always indent if there's an enter/leave message
	return 1 if $self->has_message;

	# indent if we're nested
	if ( $self->_has_previous_hook ) {
		my $hook = $self->_previous_hook;
		if ( blessed($hook) and $hook->isa("Devel::STDERR::Indent::Hook") ) {
			return 1;
		}
	}

	# otherwise we're at the top level, don't indent unnecessarily, it's distracting
	return;
}

sub install {
	my $self = shift;

	my $weak = $self;
	weaken($weak);

	if ( my $prev = $SIG{__WARN__} ) {
		$self->_previous_hook($prev);
	}

	$SIG{__WARN__} = bless sub { $weak->warn(@_) }, "Devel::STDERR::Indent::Hook";
}

sub uninstall {
	my $self = shift;

	if ( my $prev = $self->_previous_hook ) {
		$SIG{__WARN__} = $prev;
	} else {
		delete $SIG{__WARN__};
	}
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::STDERR::Indent - Indents STDERR to aid in print-debugging recursive algorithms.

=head1 SYNOPSIS

	use Devel::STDERR::Indent qw/indent/;

	sub factorial {
		my $h = indent; # causes indentation

		my $n = shift;
		warn "computing factorial $n"; # indented based on call depth

		if ($n == 0) {
			return 1
		} else {
			my $got = factorial($n - 1);
			warn "got back $got, multiplying by $n";
			return $n * $got;
		}
	}

=head1 DESCRIPTION

When debugging recursive code it's very usefl to indent traces, but often too
much trouble.

This module makes automates the indentation. When you call the C<indent>
function the indentation level is increased for as long as you keep the value
you got back. Once that goes out of scope the indentation level is decreased
again.

=head1 EXPORTS

All exports are optional, and may be accessed fully qualified instead.

=over 4

=head1 indent

Returns an object which you keep around for as long as you want another indent
level:

	my $h = $indent;
	# ... all warnings are indented by one additional level
	$h = undef; # one indentation level removed

Instantiates a new indentation guard and calls C<enter> on it before returning it.

Parameters are passed to C<new>:

	indent "foo"; # will print enter/leave messages too

=back

=head1 METHODS

=over1

=item new

Creates the indentation helper, but does not install it yet.

If given a single argument it is assumed to be for the C<message> attribute.

=item emit

Output a warning with the previous installed hook.

=item format

Indent a message.

=item warn

Calls C<format> and then C<emit>.

=item enter

Calls C<install> the hook and outputs the optional message.

=item leave

Calls C<uninstall> the hook and outputs the optional message.

=item install

Installs the hook in C<$SIG{__WARN__}>.

=item uninstall

Uninstalls the hook restoring the previous value.

=back

=head1 ATTRIBUTES

=over 4

=item message

If supplied will be printed in C<enter> prefixed by C<enter_string> and in
C<leave> prefixed by C<leave_string>.

=item indent_string

Defaults to C<'    '> (four spaces).

=item enter_string

Defaults to C<< ' -> ' >>.

=item leave_string

Defaults to C<< ' <- ' >>.

=back

=head1 VERSION CONTROL

L<http://nothingmuch.woobling.org/code>

=cut


