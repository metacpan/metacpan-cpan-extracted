package Devel::Events::Handler::Log::Memory;
# vim: set ts=2 sw=2 noet nolist :
# ABSTRACT: An optional base role for event generators.
our $VERSION = '0.10';
use Moose;

with qw/Devel::Events::Handler/;

use Devel::Events::Match;

has matcher => (
	isa => "Devel::Events::Match",
	is  => "rw",
	default => sub { Devel::Events::Match->new },
	handles => sub {
		my ( $attr, $meta ) = @_;
		
		my %mapping;

		foreach my $method ( $meta->get_method_list ) {
			next if $method =~ /^ (?: compile_cond | match ) $/x;
			next if __PACKAGE__->can($method);

			$mapping{$method} ||= sub {
				my ( $self, @args ) = @_;
				unshift @args, "match" if @args == 1;
				$self->matcher->$method( events => scalar($self->events), @args );
			}
		}

		return %mapping;
	}
);

has events => (
	isa => "ArrayRef",
	is  => "ro",
	default    => sub { [] },
	auto_deref => 1,
  traits => ['Array'],
  handles => {
    clear => 'clear',
    add_event => 'push',
  },
);

sub new_event {
	my ( $self, @event ) = @_;
	$self->add_event(\@event);
}

sub replay {
	my ( $self, $handler ) = @_;
	$handler->new_event( @$_ ) for $self->events;
}

__PACKAGE__;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::Events::Handler::Log::Memory - An optional base role for event generators.

=head1 VERSION

version 0.10

=head1 SYNOPSIS

	use Devel::Events::Handler::Log::Memory;

	my $log = Devel::Events::Handler::Log::Memory->new();

	Some::Geneator->new( handler => $log );

=head1 DESCRIPTION

This convenience role provides a basic C<send_event> method, useful for
implementing generators.

=head1 ATTRIBUTES

=over 4

=item events

The list of events.

Auto derefs.

=item matcher

The L<Devel::Events::Match> instance used for event matching.

=back

=head1 METHODS

=over 4

=item clear

Remove all events from the log.

Provided by L<MooseX::AttributeHelpers>.

=item first $cond

=item first %args

Return the first event that matches a certain condition.

Delegates to L<Devel::Events::Match>.

=item grep $cond

=item grep %args

Return the list of events that match a certain condition.

Delegates to L<Devel::Events::Match>.

=item limit from => $cond, to => $cond, %args

Return events between two events. If if C<from> or C<to> is omitted then it
returns all the events up to or from the other filter.

Delegates to L<Devel::Events::Match>.

=item chunk $marker

=item chunk %args

Cuts the event log into chunks. When C<$marker> matches a new chunk is opened.

Delegates to L<Devel::Events::Match>.

=item new_event @event

Log the event to the C<events> list by calling C<add_event>.

=item add_event \@event

Provided by L<MooseX::AttributeHelpers>.

=item replay $handler

Replay all the events in the log to $handler.

Useful if C<$handler> does heavy analysis that you want to delay.

There isn't much to it:

	$handler->new_event(@$_) for $self->events;

So obviously you can replay subsets of events manually.

=back

=head1 CAVEATS

If any references are present in the event data then they will be preserved
till the log is clear. This may cause leaks.

To overcome this problem use L<Devel::Events::Filter::Stringify>. It will not
allow overloading unless asked to, so it's safe to use without side effects.

=head1 TODO

Add an option to always hash all the event data for convenience.

Make C<grep> and C<limit> into exportable functions, too.

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-Events>
(or L<bug-Devel-Events@rt.cpan.org|mailto:bug-Devel-Events@rt.cpan.org>).

=head1 AUTHOR

יובל קוג'מן (Yuval Kogman) <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by יובל קוג'מן (Yuval Kogman).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
