package Game::Terminal::Kit::Test::Screen;

use 5.014;
use strict;
use warnings;

use Exporter 'import';
use Game::Terminal::Kit::Keys;
use Game::Terminal::Kit::Screen;

our $VERSION = '0.05';

our @EXPORT_OK = qw/keysource capture typed kit within/;

sub keysource {
	my ($bytes) = @_;
	my @chars = split //, defined $bytes ? $bytes : '';
	return sub { return shift @chars };
}

sub capture {
	my $text = '';
	open my $out, '>', \$text or die "cannot open the screen: $!";
	return ($out, \$text);
}

sub typed {
	my (@lines) = @_;
	my $script = join '', map { m/\n\z/ ? $_ : "$_\n" } @lines;
	open my $in, '<', \$script or die "cannot read the script: $!";
	return $in;
}

sub kit {
	my (%option) = @_;
	my $bytes = delete $option{keys};
	my $lines = delete $option{typed};
	my ($out, $text) = capture();
	my $keys = Game::Terminal::Kit::Keys->new(
		in => typed(@{ $lines || [] }),
		(defined $bytes ? (keysource => keysource($bytes)) : ()),
	);
	my $screen = Game::Terminal::Kit::Screen->new(
		out => $out,
		interactive => 0,
		colour => 0,
		ascii => 1,
		%option,
	);
	return ($keys, $screen, $text);
}

sub within {
	my ($seconds, $body) = @_;
	my $late = "it did not end in $seconds seconds\n";
	my @result;
	my $lived = eval {
		local $SIG{ALRM} = sub { die $late };
		alarm $seconds;
		@result = $body->();
		alarm 0;
		1;
	};
	my $died = $@;
	eval { alarm 0 };
	return wantarray ? @result : $result[0] if $lived;
	die $died unless $died eq $late;
	require Test::Builder;
	Test::Builder->new->ok(0, "ended within $seconds seconds");
	return;
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Test::Screen - a keyboard and a screen for a test

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Test::More;
    use Game::Terminal::Kit::Test::Screen qw/kit within/;

    my ($keys, $screen, $text) = kit(keys => "\e[B\e[B\r");

    my $terminal = Game::Checkers::Terminal->new(keys => $keys, screen => $screen);
    my $move = within(10, sub { $terminal->choose_move });

    is $move->notation, '11-15', 'down twice and enter chose the third move';
    like ${$text}, qr/^> 11-15$/m, 'and it was under the cursor';

=head1 DESCRIPTION

What a test of a terminal game needs in place of a terminal: keys that come
from a string, a screen that goes into a string, and a limit on how long a
game that is waiting for a key nobody will press may wait.

Nothing here touches a real terminal and L<Term::ReadKey> is not needed.

=head1 FUNCTIONS

Each is exported on request.

=head2 keysource

    my $source = keysource("\e[A\rq");

A C<keysource> for L<Game::Terminal::Kit::Keys> that hands out the string a
character at a time and then undef. An arrow key is typed as the escape
sequence a terminal sends for it.

=head2 capture

    my ($out, $text) = capture();

A handle to write to and a reference to everything written to it.

=head2 typed

    my $in = typed('e3 d4', 'quit');

A handle to read from, holding those lines.

=head2 kit

    my ($keys, $screen, $text) = kit(keys => "\r", typed => ['yes']);

A L<Game::Terminal::Kit::Keys> and a L<Game::Terminal::Kit::Screen> wired to
the above, and the reference to what the screen was sent. C<keys> is the
string of keys and C<typed> the lines; with no C<keys> there is no keyboard
and the game is line by line. The screen is not a terminal, has no colour and
is ASCII, so what a test matches is what was meant and nothing else; any
other argument is the screen's and overrides that.

=head2 within

    my $result = within($seconds, sub { $terminal->start });

Runs the body and returns what it returns. A body still running when the
time is up is stopped and counted as one failed test, and nothing is
returned: a test that hangs tells nobody anything. Any other error is thrown
on.

=head1 SEE ALSO

L<Game::Terminal::Kit::Test::Handle>, L<Game::Terminal::Kit>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
