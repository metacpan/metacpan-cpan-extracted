package Fetch::Loop::AnyEvent;

use strict;
use warnings;

our $VERSION = '0.03';

use parent -norequire, 'Fetch::Loop';
use Fetch::Loop ();

sub new {
    my ($class) = @_;
    require AnyEvent;
    return bless { w => {} }, $class;
}

sub _ft_arm {
    my ($self, $fd, $mask, $cv) = @_;
    my $w = $self->{w}{$fd} ||= {};

    if ($mask & Fetch::Loop::FT_READ) {
        $w->{r} ||= AE::io($fd, 0, sub { $cv->() });
    } else {
        delete $w->{r};
    }
    if ($mask & Fetch::Loop::FT_WRITE) {
        $w->{w} ||= AE::io($fd, 1, sub { $cv->() });
    } else {
        delete $w->{w};
    }
    delete $self->{w}{$fd} unless %$w;
    return;
}

sub _ft_timer {
    my ($self, $secs, $cv) = @_;
    my $g = { cancelled => 0 };
    $g->{w} = AE::timer($secs, 0, sub { $cv->() unless $g->{cancelled} });
    return $g;
}

sub _ft_untimer {
    my ($self, $g) = @_;
    return unless ref $g;
    $g->{cancelled} = 1;
    delete $g->{w};     # dropping the guard cancels the timer
    return;
}

sub install_await {
    my ($self) = @_;
    $Fetch::Future::AWAIT = sub {
        my ($f) = @_;
        return if $f->is_ready;
        my $cv = AE::cv();
        $f->on_ready(sub { $cv->send });
        $cv->recv;
    };
    return $self;
}

1;

__END__

=head1 NAME

Fetch::Loop::AnyEvent - run Fetch under AnyEvent

=head1 SYNOPSIS

    use AnyEvent;
    use Fetch;

    my $ua = Fetch->new(loop => 'AnyEvent');
    my $f  = $ua->get('https://example.com/');
    my $cv = AE::cv;
    $f->on_ready(sub { $cv->send });
    $cv->recv;
    print $f->get->content;

=head1 DESCRIPTION

Adapts AnyEvent so Fetch cooperates with whatever event loop AnyEvent is
driving (EV, Perl, etc.). Pass C<< loop => 'AnyEvent' >> to C<< Fetch->new >>
and this adapter is used.

=head2 new

Load AnyEvent and build the adapter.

=head2 install_await

Install C<$Fetch::Future::AWAIT> so a bare C<< $future->get >> waits on an
AnyEvent condvar that the future signals when ready.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
