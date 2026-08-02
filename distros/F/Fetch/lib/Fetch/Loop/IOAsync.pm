package Fetch::Loop::IOAsync;

use strict;
use warnings;

our $VERSION = '0.03';

use parent -norequire, 'Fetch::Loop';
use Fetch::Loop ();

sub new {
    my ($class, $loop) = @_;
    $loop ||= do { require IO::Async::Loop; IO::Async::Loop->new };
    return bless { loop => $loop, fd => {} }, $class;
}

sub loop { $_[0]{loop} }

sub _ft_arm {
    my ($self, $fd, $mask, $cv) = @_;
    my $loop = $self->{loop};
    my $st   = $self->{fd}{$fd};

    if (!$mask) {
        if ($st) {
            $loop->unwatch_io(handle => $st->{fh},
                on_read_ready => 1, on_write_ready => 1);
            delete $self->{fd}{$fd};
        }
        return;
    }

    $st ||= $self->{fd}{$fd} = { fh => $self->_fh_for_fd($fd), mask => 0 };
    my $cur = $st->{mask};

    my %add;
    $add{on_read_ready}  = $cv if ($mask & Fetch::Loop::FT_READ)  && !($cur & Fetch::Loop::FT_READ);
    $add{on_write_ready} = $cv if ($mask & Fetch::Loop::FT_WRITE) && !($cur & Fetch::Loop::FT_WRITE);
    $loop->watch_io(handle => $st->{fh}, %add) if %add;

    my %del;
    $del{on_read_ready}  = 1 if ($cur & Fetch::Loop::FT_READ)  && !($mask & Fetch::Loop::FT_READ);
    $del{on_write_ready} = 1 if ($cur & Fetch::Loop::FT_WRITE) && !($mask & Fetch::Loop::FT_WRITE);
    $loop->unwatch_io(handle => $st->{fh}, %del) if %del;

    $st->{mask} = $mask;
    return;
}

sub _ft_timer {
    my ($self, $secs, $cv) = @_;
    my $g = { cancelled => 0 };
    $g->{id} = $self->{loop}->watch_time(after => $secs,
        code => sub { $cv->() unless $g->{cancelled} });
    return $g;
}

sub _ft_untimer {
    my ($self, $g) = @_;
    return unless ref $g;
    $g->{cancelled} = 1;
    $self->{loop}->unwatch_time($g->{id}) if defined $g->{id};
    return;
}

sub install_await {
    my ($self) = @_;
    my $loop = $self->{loop};
    $Fetch::Future::AWAIT = sub {
        my ($f) = @_;
        $loop->loop_once until $f->is_ready;
    };
    return $self;
}

1;

__END__

=head1 NAME

Fetch::Loop::IOAsync - run Fetch on an IO::Async::Loop

=head1 SYNOPSIS

    use IO::Async::Loop;
    use Fetch;

    my $loop = IO::Async::Loop->new;
    my $ua   = Fetch->new(loop => $loop);      # auto-wrapped
    my $f    = $ua->get('https://example.com/');
    $loop->loop_once until $f->is_ready;
    print $f->get->content;

=head1 DESCRIPTION

Adapts an L<IO::Async::Loop> so Fetch's requests run as part of an existing
IO::Async program, sharing its one loop. Pass a raw C<IO::Async::Loop> as
C<< Fetch->new(loop => ...) >> and it is wrapped automatically, or construct
this adapter directly.

=head2 new([$io_async_loop])

Wrap the given loop, or make a fresh C<< IO::Async::Loop->new >>.

=head2 loop

The underlying C<IO::Async::Loop>.

=head2 install_await

Install C<$Fetch::Future::AWAIT> so a bare C<< $future->get >> pumps the loop
(via C<loop_once>) until the future is ready.

=head1 AUTHOR

LNATION C<< <email@lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION. This is free software, licensed
under the Artistic License 2.0.

=cut
