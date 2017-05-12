#!/usr/bin/perl

use Moose ();
use Moose::Role ();

BEGIN { $^P |= 0x01 }

package Devel::Events::Generator::SubTrace;
use Moose;

with qw/Devel::Events::Generator/;

use Scalar::Util ();

my ( $SINGLETON );
our ( $IGNORE, $DEPTH ); # can't local a lexical ;_;

BEGIN { $DEPTH = -1 };

{
	package DB;

	our $sub;

	sub sub {
		local $DEPTH = $DEPTH + 1;

		unless ( $SINGLETON
			and  !$IGNORE,
			and  $sub !~ /^Devel::Events::/
		) {
			no strict 'refs';
			goto &$sub;
		}

		my @ret;
		my $ret;

		my $tsub ="$sub";
		$tsub = 'main' unless $tsub;

		my @args = (
			'name'      => "$tsub",
			'code'      => \&$tsub,
			'args'      => [ @_ ],
			'depth'     => $DEPTH,
			'wantarray' => wantarray(),
		);

		push @args, autoload => do { no strict 'refs'; $$tsub }
			if (( length($tsub) > 10) && (substr( $tsub, -10, 10 ) eq '::AUTOLOAD' ));

		$SINGLETON->enter_sub(@args);

		{
			no strict 'refs';

			if (wantarray) {
				@ret = &$sub;
			}
			elsif (defined wantarray) {
				$ret = &$sub;
			}
			else {
				&$sub;
			}
		}

		$SINGLETON->leave_sub(
			@args,
			ret => (wantarray) ? \@ret : defined(wantarray) ? $ret : undef,
		);

		return (wantarray) ? @ret : defined(wantarray) ? $ret : undef;
	}
}

sub enter_sub {
	my ( $self, @data ) = @_;
	local $IGNORE = 1;

	$self->send_event( enter_sub => @data );
}

sub leave_sub {
	my ( $self, @data ) = @_;
	local $IGNORE = 1;

	$self->send_event( leave_sub => @data );
}

sub enable {
	my $self = shift;
	local $IGNORE = 1;
	$SINGLETON = $self;
	Scalar::Util::weaken($SINGLETON);
}

sub disable {
	$SINGLETON = undef;
}

__PACKAGE__;

__END__


=pod

=head1 NAME

Devel::Events::Generator::SubTrace - generate C<executing_line> events using
the perl debugger api.

=head1 SYNOPSIS

	my $g = Devel::Events::Generator::SubTrace->new( handler => $h );

	$g->enable();

	# every subroutine will have two events fired, on entry and exit

	$g->disable();

=head1 DESCRIPTION

This L<Devel::Events> generator will fire sub tracing events using C<DB::sub>,
a perl debugger hook.

Only one instance may be enabled at a given time. Use
L<Devel::Events::Handler::Multiplex> to deliver events to multiple handlers.

Subroutines inside the L<Devel::Events> namespace or it's children will be
skipped.

=head1 EVENTS

=over 4

=item enter_sub

When the generator is enabled, this event will fire for every subroutine, just
before it is executed.

Subroutines in a package starting with C<Devel::Events::> will not be reported.

=over 4

=item name

The name of the subroutine (or it's C<overload::StrVal> if it has none).

=item code

A code reference to the subroutine.

=item args

A copy of the arguments list. C<\@_> causes segfaults but C<[ @_ ]> does not.
Bummer ;-)

=item depth

The current depth of the call stack.

=item wantarray

The context of the call as given by C<wantarray>

=back

=item leave_sub

Exactly like C<enter_sub>, but fired just after leaving the subroutine.

=over 4

All the fields of C<enter_sub> are passed.

Additional fields:

=item ret

The return value of the subroutine.

=back

=back

=head1 METHODS

=over 4

=item enable

Enable this generator instance, disabling any other instance of
L<Devel::Events::Generator::SubTrace>.

=item disable

Stop firing events.

=item enter_sub

Called by C<DB::sub>. Sends the C<enter_sub> event.

=item leave_sub

Called by C<DB::sub>. Sends the C<leave_sub> event.

=back

=head1 SEE ALSO

L<perldebguts>, L<Devel::CallTrace>, L<DB>, L<Devel::ebug>, L<perl5db.pl>

=cut
