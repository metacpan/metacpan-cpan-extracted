package Games::Bingo;

use strict;
use warnings;
use integer;
use POSIX qw(floor);
use vars qw($VERSION);
use Games::Bingo::Constants qw(NUMBER_OF_NUMBERS);

$VERSION = '0.18';

sub new {
	my $class = shift;
	my $ceiling = shift || NUMBER_OF_NUMBERS;
	
	my $self = bless {
		_numbers => [],
		_pulled  => [[],[],[],[],[],[],[],[],[],],
		game     => 1,
	}, $class;

	my @ary;
	$self->init(\@ary, $ceiling);
	push @{$self->{'_numbers'}}, @ary; 
	
	return $self;
}

sub init {
	my ($self, $numbers, $ceiling) = @_;
	
	for(my $i = 1; $i < ($ceiling + 1); $i++) { 
		push @{$numbers}, $i;
	}
	
	return 1;
}

sub play {
	my ($self, $numbers) = @_;

	my $number;
	if ($numbers) {
		my $index = $self->random(scalar @{$numbers});
		$number = $numbers->[$index];
		splice(@{$numbers},  $index, 1);	
	} else {	
		my $index = $self->random(scalar @{$self->{'_numbers'}});
		$number = $self->{'_numbers'}->[$index];
		splice(@{$self->{'_numbers'}},  $index, 1);
	}
	$self->pull($number);
	
	return $number;
}

sub pulled {
	my ($self, $number) = @_;
		
	my $found = 0;
	foreach my $n ($self->_all_pulled()) {
		if ($n == $number) {
			$found++;
			last;
		};
	}
		
	if ($found) {
		return 1;
	} else {
		return 0;
	}
}

sub _all_pulled {
	my $self = shift;
	
	my @pulled = ();
	foreach my $row (@{$self->{'_pulled'}}) {		
		foreach my $number (@{$row}) {
			push(@pulled, $number) if $number;
		}
	}
	
	return @pulled;
}

sub pull {
	my ($self, $number) = @_;
	
	return $self->take($self->{'_pulled'}, $number);
}

sub take {
	my ($self, $taken, $take) = @_;

    my ($x, $y, $take_modified) = $self->splitnumber($take);

    return $taken->[$x][$y] = $take_modified;
}

sub random {
	my ($self, $number) = @_;

	return POSIX::floor(rand($number));
}

sub splitnumber {
	my ($self, $number) = @_;
	
	my $modified = sprintf("%02d", $number);
    my ($x, $y) = $modified =~ m/^(\d{1})(\d{1})$/o;

	return ($x, $y, $modified);
}

1;

__END__

=pod

=begin markdown

[![CPAN version](https://badge.fury.io/pl/Games-Bingo.svg)](http://badge.fury.io/pl/Games-Bingo)
[![Build Status](https://travis-ci.org/jonasbn/Games-Bingo.svg?branch=master)](https://travis-ci.org/jonasbn/Games-Bingo)
[![Coverage Status](https://coveralls.io/repos/jonasbn/Games-Bingo/badge.png?branch=master)](https://coveralls.io/r/jonasbn/Games-Bingo?branch=master)

=end markdown

=head1 NAME

Games::Bingo - a bingo game Perl implementation

=head1 SYNOPSIS

	use Games::Bingo;
	my $bingo = Games::Bingo-E<gt>new(90);
	
	my $bingo = Games::Bingo-E<gt>new();

90 is actually the default

	my $number = $bingo-E<gt>play(); >>

	my @taken;

	$bingo-E<gt>pull(\@pulled, $number);

or

	use Games::Bingo;
	my $bingo = Games::Bingo-E<gt>new();

	my @numbers;
	$bingo-E<gt>init(\@numbers, 90);

	my $number = $bingo-E<gt>play(\@numbers);
	my @taken;

	$bingo-E<gt>take(\@taken, $number);

=head1 DESCRIPTION

This is a simple game of bingo. The program can randomly call out the
numbers. The game will be get more features in the future, please refer
to the B<TODO> section (below).

=head1 METHODS

This are the central methods of Games::Bingo

=head2 new

The constructor is quite simple. It can either be called without any
paramters and then followed by a call to B<init> see below or the
ceiling for the numbers (stored internally) can be given as a
parameter, the latter is the recommeded use.

If no indicator of the number of numbers you want in your bingo game is
given the game defaults to 90. This can be overwritten if using the old
API, please refer to the B<SYNOPSIS>.

The attributes of the class are the following:

=over 4

=item _numbers

The list holding all the numbers in the pull pool.
		
=item _numbers_pulled

A list holding the numbers which have been pulled.
		
=item game

A flag indicating where the game currently are and how it should be run.

These are the different values:

=over 4

=item * 0

Game is over

=item * 1

full card (the default)

=item * 2

2 rows

=item * 3

1 row

=back

=back

=head2 init

This method takes two parameters. An array reference and a ceiling, the
method will push numbers onto the array reference from 1 to ceiling
(including the ceiling). Initializing the numbers for the game.

The use of init is not recommended, use the constructor in the
recommended way instead.

Returns 1 upon success.

=head2 play

The B<play> is one of the essential methods in the game, it takes an
array reference and returns a random number from the array referenced
to. The reference shrinks with one with each call.

The recommended way is though to use the internally stored array, where
play then takes no arguments, please refer to B<new> and B<init> and
the B<SYNOPSIS>.

=head2 take

The B<take> method is the memory of the game. It takes to parameters, a
reference to an array of arrays (the memory), and additionaly the number
picked by e.g. the B<play> method.

Since the first program to use the class/module was a console based the
take method organizes the numbers in an array of array for a nicer
presentation. This will probably be changed later (if necessary).

=head2 random

The encapsulation of the rand function. Takes a number as a paramtere
and returns a number between 0 and the number given as a parameter just
as rand (% perldoc -f rand).

The result is rounded down using POSIX::floor

=head2 pulled

A method which return 1 or 0 indicating true or false, whether the
number given as a parameter has been pulled. 

=head2 _all_pulled

A method which returns all pulled numbers as an array.

=head2 pull

A clumsy alias/"overload" implementation of the take method.

=head2 splitnumber

Takes a number (prepends 0 its a single digit number) and returns it
split in two (We use this for identifying the column it belongs to).

=head1 SEE ALSO

=over

=item L<Games::Bingo::Column>

=item L<Games::Bingo::ColumnCollection>

=item L<Games::Bingo::Print>

=item L<Games::Bingo::Card>

=item L<Games::Bingo::Bot>

=item F<bin/bingo.pl>

=back

=head1 TODO

The TODO file contains a complete list for the whole Games::Bingo
project.

=head1 BUGS

Please report issues via CPAN RT:

  http://rt.cpan.org/NoAuth/Bugs.html?Dist=Games-Bingo

or by sending mail to

  bug-Games-Bingo@rt.cpan.org

=head1 TEST COVERAGE

	---------------------------- ------ ------ ------ ------ ------ ------ ------
	File                           stmt   bran   cond    sub    pod   time  total
	---------------------------- ------ ------ ------ ------ ------ ------ ------
	blib/lib/Games/Bingo.pm       100.0  100.0  100.0  100.0  100.0   22.3  100.0
	blib/lib/Games/Bingo/Card.pm  100.0  100.0   66.7  100.0  100.0   21.5   99.4
	...lib/Games/Bingo/Column.pm  100.0  100.0    n/a  100.0  100.0   24.3  100.0
	...Bingo/ColumnCollection.pm   92.5   84.6   33.3  100.0  100.0   31.4   90.6
	.../Games/Bingo/Constants.pm  100.0    n/a    n/a  100.0    n/a    0.4  100.0
	Total                          98.2   94.1   62.5  100.0  100.0  100.0   97.4
	---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 AUTHOR

jonasbn E<lt>jonasbn@cpan.orgE<gt>

=head1 ACKNOWLEDGEMENTS

This is a compilation of all the people have helped me, their names are also
scattered all over the modules where appropriate.

=over

=item * Rikke Gornitzka for inviting me to the real bingo game, which
started all this

=item * Matt Sergeant (MSERGEANT) for suggesting using PDFLib

=item * Allan Juul algoritms and code help

=item * Michael Legart (LEGART) trying to understand my problems

=item * Lars Thegler (THEGLER) for several bug reports

=item * Casper Warming (WARMING), for helping with the OSX client

=item * The remaining Copenhagen Perl Mongers for testing the IRC game

=item * Mike Castle for his POD patch

=item * All the ppl who have commented on my journal coming with
suggestions etc.

=back

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Games-Bingo is (C) by Jonas B. Nielsen, (jonasbn) 2003-2015

Games-Bingo is released under the artistic license 2.0

=cut
