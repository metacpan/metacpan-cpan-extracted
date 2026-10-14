package Game::Terminal::Kit::Test::Handle;

use 5.014;
use strict;
use warnings;

our $VERSION = '0.05';

sub TIEHANDLE {
	my ($class) = @_;
	return bless {}, $class;
}

sub PRINT {
	die "wrote to a handle\n";
}

sub PRINTF {
	die "wrote to a handle\n";
}

sub WRITE {
	die "wrote to a handle\n";
}

sub READLINE {
	die "read from a handle\n";
}

sub READ {
	die "read from a handle\n";
}

sub GETC {
	die "read from a handle\n";
}

sub EOF {
	die "read from a handle\n";
}

sub OPEN {
	die "opened a handle\n";
}

sub BINMODE {
	return 1;
}

sub FILENO {
	return undef;
}

sub CLOSE {
	return 1;
}

1;

__END__

=head1 NAME

Game::Terminal::Kit::Test::Handle - a filehandle that refuses to be one

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Test::More;
    use Game::Terminal::Kit::Test::Handle;

    {
        tie local *STDOUT, 'Game::Terminal::Kit::Test::Handle';
        tie local *STDIN, 'Game::Terminal::Kit::Test::Handle';
        my $moves = eval { $game->legal_moves };
        is $@, '', 'the rules print nothing and read nothing';
    }

=head1 DESCRIPTION

For a test that the part of a game which is not its terminal does no input
or output. Tie C<STDOUT> or C<STDIN> to this class and anything that writes
to the one dies with C<wrote to a handle>, anything that reads from the
other dies with C<read from a handle>, and reopening either dies with
C<opened a handle>. C<binmode> and C<close> are let through.

The test's own results still get out: L<Test::More> writes to a copy of
C<STDOUT> it took before the tie.

=head1 SEE ALSO

L<Game::Terminal::Kit::Test::Screen>.

=head1 AUTHOR

LNATION, C<< <email at lnation.org> >>

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2026 by LNATION.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
