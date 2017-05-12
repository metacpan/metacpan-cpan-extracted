#!/usr/bin/perl

BEGIN { $^P |= 0x02 }

package Devel::Events::Generator::LineTrace;
use Moose;

with qw/Devel::Events::Generator/;

use Scalar::Util qw/weaken/;

my $SINGLETON;

sub DB::DB {
	if ( $SINGLETON ) {
		my ( $package, $file, $line ) = caller;
		return if $package =~ /^Devel::Events::/;
		$SINGLETON->line( package => $package, file => $file, line => $line );
	}
}

sub enable {
	my $self = shift;
	$SINGLETON = $self;
	weaken($SINGLETON);
}

sub disable {
	$SINGLETON = undef;
}

sub line {
	my ( $self, @args ) = @_;
	$self->send_event( executing_line => @args );
}

__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Generator::LineTrace - generate C<executing_line> events using
the perl debugger api.

=head1 SYNOPSIS

	my $g = Devel::Events::Generator::LineTrace->new( handler => $h );

	$g->enable();

	# every line of code will fire an event until

	$g->disable();

=head1 DESCRIPTION

This L<Devel::Events> generator will fire line tracing events using C<DB::DB>,
a perl debugger hook.

Only one instance may be enabled at a given time. Use
L<Devel::Events::Handler::Multiplex> to deliver events to multiple handlers.

=head1 EVENTS

=over 4

=item executing_line

When the generator is enabled, this event will fire for every line of code just
before it is executed.

Lines in a package starting with C<Devel::Events::> will not be reported.

=over 4

=item package

The package the line is in.

=item file

The file of the line being executed.

=item line

The line number of the line being executed.

=back

=back

=head1 METHODS

=over 4

=item enable

Enable this generator instance, disabling any other instance of
L<Devel::Events::Generator::LineTrace>.

=item disable

Stop firing events.

=item line

Called by C<DB::DB>. Used to generate the event.

=back

=head1 CAVEATS

Apparently this must be run under C<perl -d>. This is very strange, since
L<Devel::Events::Generator::SubTrace> doesn't need the C<-d> flag set.

The L<Enbugger> module can help overcome this limitation.

=head1 SEE ALSO

L<perldebguts>, L<Devel::LineTrace>, L<DB>, L<Devel::ebug>, L<perl5db.pl>

=cut
