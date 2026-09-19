package Game::Oware::Test::Play;

use strict;
use warnings;

use Game::Oware::Notation;

our $VERSION = '0.01';

sub TIEHANDLE {
	my ($class, %options) = @_;
	return bless {
		game  => $options{game},
		seat  => $options{seat} || 'p1',
		pick  => $options{pick} || sub { $_[0]->[0] },
		lines => $options{lines} || [],
		asked => 0,
	}, $class;
}

sub READLINE {
	my ($self) = @_;

	return shift @{ $self->{lines} } if @{ $self->{lines} };

	$self->{asked}++;
	return "quit\n" if $self->{asked} > 400;

	my $legal = $self->{game}->legal($self->{seat});
	return "quit\n" unless @$legal;

	my $house = $self->{pick}->($legal);
	return Game::Oware::Notation->letter_of($house) . "\n";
}

sub asked { return $_[0]->{asked} }

sub BINMODE { return 1 }
sub FILENO  { return -1 }
sub CLOSE   { return 1 }
sub EOF     { return 0 }

1;

__END__

=head1 NAME

Game::Oware::Test::Play - an input handle that always answers with a legal move

=head1 DESCRIPTION

A scripted list of moves desyncs into nonsense the moment anything about the
loop changes, and then fails for a reason that has nothing to do with the
change. This asks the game what is legal and answers with one of those, so a
whole game can be driven in process without the test knowing the moves in
advance.

C<lines> is a list of literal answers to give first, for the cases a test wants
to script: a bad letter, a command, a quit.

=cut
