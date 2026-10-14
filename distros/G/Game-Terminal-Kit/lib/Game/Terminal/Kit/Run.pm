package Game::Terminal::Kit::Run;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.05';

sub give_back {
	my (@held) = @_;
	for my $thing (@held) {
		next unless ref $thing;
		eval { $thing->leave_raw } if $thing->can('leave_raw');
		eval { $thing->restore } if $thing->can('restore');
	}
	return;
}

sub guard {
	my ($body, @held) = @_;
	local @SIG{qw(INT TERM HUP)};
	for my $sig (qw(INT TERM HUP)) {
		$SIG{$sig} = sub { give_back(@held); $SIG{$sig} = 'DEFAULT'; kill $sig, $$ };
	}
	my $list = wantarray;
	my @result;
	my $lived = eval {
		if ($list) {
			@result = $body->();
		} else {
			$result[0] = $body->();
		}
		1;
	};
	my $died = $@;
	give_back(@held);
	die $died unless $lived;
	return $list ? @result : $result[0];
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Run - give the terminal back on every way out

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Game::Terminal::Kit::Run;

    sub run {
        my ($class, @argv) = @_;
        my $terminal = $class->new(...);
        my $result = Game::Terminal::Kit::Run::guard(
            sub { $terminal->start },
            $terminal->keys, $terminal->screen,
        );
        return $result && $result->lost ? 1 : 0;
    }

=head1 DESCRIPTION

A game that reads a key at a time has changed the terminal, and has to change
it back however it stops: at the end, on an error, and when it is
interrupted. A terminal left as the game had it echoes nothing and shows no
cursor.

=head1 FUNCTIONS

Neither is exported.

=head2 guard

    my $result = Game::Terminal::Kit::Run::guard(\&body, @held);

Calls the body and returns what it returns, in the caller's context. Each of
C<@held> is an object with a C<leave_raw> method, a C<restore> method or
both, such as a L<Game::Terminal::Kit::Keys> and a
L<Game::Terminal::Kit::Screen>. They are given back when the body returns,
and when it dies, after which the error is thrown again unchanged.

While the body runs, C<INT>, C<TERM> and C<HUP> give them back too and then
arrive as they would have: the signal is raised again with its default
action, so the program still stops and its parent still sees why. The
handlers that were there before are there again afterwards.

=head2 give_back

    Game::Terminal::Kit::Run::give_back(@held);

The giving back on its own. An error from one object does not stop the next
from being given back.

=head1 SEE ALSO

L<Game::Terminal::Kit>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
