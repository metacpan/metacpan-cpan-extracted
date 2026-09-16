package Game::Backgammon::Error;

use strict;
use warnings;

use Object::Proto::Sugar -types;

our $VERSION = '0.01';

my %MESSAGE = (
	game_over    => 'the game is over',
	not_legal    => 'the rules do not offer that turn',
	not_notation => 'that is not backgammon notation',
	no_seed      => 'a game needs a seed',
);

has code => (
	is => 'ro',
	isa => Str
);

has detail => (
	is => 'ro',
	isa => Any
);

sub message {
	my ($self) = @_;
	my $base = $MESSAGE{ $self->code } // $self->code;
	my $detail = $self->detail;
	return $base unless defined $detail && !ref $detail && length $detail;
	$detail =~ s/\s+\z//;
	return "$base: $detail";
}

sub stringify { return $_[0]->code . ': ' . $_[0]->message }

1;

__END__

=head1 NAME

Game::Backgammon::Error - what the rules refuse, with a code

=head1 SYNOPSIS

    my $turn = $game->play('8/5 6/5');
    if (!$turn) {
        my $e = $@;
        $e->code;        # 'not_legal'
        $e->message;     # 'the rules do not offer that turn'
    }

=head1 DESCRIPTION

The engine returns its refusals rather than throwing them, so a caller can
map C<code> onto its own vocabulary. C<die> is reserved for programmer
error: a malformed position, a bad argument.

=head1 METHODS

=head2 code

The machine-readable reason.

=head2 detail

Whatever extra the refusal carried, or undef.

=head2 message

One sentence for a person, with the detail appended when there is one.

=head2 stringify

C<code: message>.

=cut
