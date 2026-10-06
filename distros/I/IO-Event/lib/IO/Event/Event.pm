
#
# Use Event for the IO::Event event handler
#

my $debug = $IO::Event::debug;
my $edebug = $IO::Event::edebug;
my $sdebug = $IO::Event::sdebug;

package IO::Event::Event;

# ABSTRACT: Use Event for the IO::Event event handler
our $VERSION = '0.814'; # VERSION

require IO::Event;
use strict;
use warnings;

use parent -norequire, 'IO::Event::Common';

sub import
{
    require IO::Event;
    IO::Event->import('no_emulate_Event');
}

sub new
{
    my ($pkg, @stuff) = @_;
    require Event;
    require Event::Watcher;
    $pkg->SUPER::new(@stuff);
}

sub loop
{
    require Event;
    Event::loop(@_);
}

sub unloop_all
{
    require Event;
    Event::unloop_all(@_);
}

sub timer
{
    require Event;
    shift;
    Event->timer(hard => 1, @_);
}

sub idle
{
    require Event;
    shift;
    Event->idle(@_);
}

sub set_write_polling
{
    my ($self, $new) = @_;
    my $event = ${*$self}{ie_event};
    if ($new) {
        $event->poll($event->poll | Event::Watcher::W());
    } else {
        $event->poll($event->poll & ~Event::Watcher::W());
    }
}

sub set_read_polling
{
    my ($self, $new) = @_;
    my $event = ${*$self}{ie_event};
    if ($new) {
        $event->poll($event->poll | Event::Watcher::R());
    } else {
        if ($event) {
            $event->poll($event->poll & ~Event::Watcher::R());
        }
    }
}

sub ie_register
{
    my ($self) = @_;
    my ($fh, $fileno) = $self->SUPER::ie_register();
    my $R = ${*$self}{ie_readclosed}
        ? 0
        : Event::Watcher::R();
    ${*$self}{ie_want_read_events} = ! ${*$self}{ie_readclosed};
    ${*$self}{ie_want_write_events} = '';
    ${*$self}{ie_event} = Event->io(
        fd  => $fileno,
        poll    => Event::Watcher::E()|Event::Watcher::T()|$R,
        cb  => [ $self, 'ie_dispatch' ],
        desc    => ${*$self}{ie_desc},
        edebug  => $edebug,
    );
    print STDERR "registered ${*$self}{ie_fileno}:${*$self}{ie_desc} $self $fh ${*$self}{ie_event}\n"
        if $debug;
}

sub ie_deregister
{
    my ($self) = @_;
    $self->SUPER::ie_deregister();
    ${*$self}{ie_event}->cancel
        if ${*$self}{ie_event};
    delete ${*$self}{ie_event};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

IO::Event::Event - Use Event for the IO::Event event handler

=head1 VERSION

version 0.814

=head1 AUTHORS

=over 4

=item *

David Muir Sharnoff <cpan@dave.sharnoff.org>

=item *

Graham Ollis <plicease@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2002-2026 by David Muir Sharnoff <muir@idiom.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
