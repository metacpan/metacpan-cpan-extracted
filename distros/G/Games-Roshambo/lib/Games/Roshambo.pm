##############################################################################
# Games::Roshambo - Object Oriented Rock/Paper/Scissors
# v1.01
# Copyright (c) 2008 Chris Thompson
##############################################################################
package Games::Roshambo;
$VERSION ="1.01";
use strict;
use Games::Roshambo::Thrownames;

sub new {
    my $class = shift;
    my %conf = @_;
    
    $conf{numthrows} = 3 unless defined $conf{numthrows};
    $conf{sortable} = 0 unless defined $conf{sortable};

    if (! ($conf{numthrows} % 2)) { 
		warn "Cannot use an even number of throws: " . $conf{numthrows};
		return undef;
	}


    $conf{thrownames} = Games::Roshambo::Thrownames::getnames($conf{numthrows});
    return bless {%conf}, $class;
}

sub gen_throw {
	my $self = shift;
	return int(rand($self->{numthrows})) + 1;
}

sub judge {
	my $self = shift;

       #######################################################################
       ### MADNESS!
       ### throws are passed to this function as $x->judge($player1, $player2)
       ### but I'm reversing them when I grab them here. Why? well, this whole
       ### set of logic was based on a "Higher Throw Wins" set of math. Since 
       ### I'm crazy enough to want this to play RPS-101 with throw names,
       ### and since I didn't realize that the whole RPS-101 is based on "Lower
       ### Throw Wins", I was resigned to rewriting the logic itself. 
       ### Chris Prather helped me realize, however, that simply swapping the
       ### values was the same thing. This is why he gets to work at a cool
       ###  job doing cool perl things, while I have to edit badly formed HTML.
       ########################################################################

	my $player2 = shift || $self->gen_throw;
	my $player1 = shift || $self->gen_throw;
	
	$player1 = $self->name_to_num($player1) unless ($player1 !~ m/\D+/);
	$player2 = $self->name_to_num($player2) unless ($player2 !~ m/\D+/);

	return undef unless ($player1 && $player2);
	
	my $numthrows = $self->{numthrows};
        my $winrange = ($numthrows - 1) / 2;

	return 0 if ($player1 == $player2);

	my $onewins = $self->{sortable} ? -1 : 1; 
	my $twowins = $self->{sortable} ? 1 : 2; 
	
    return $onewins if (($player1 >= $winrange) && 
				 (($player1 > $player2) && ($player1 - $winrange <= $player2))
				);
				
	return $onewins if (($player1 <= $winrange) && 
				 (($player1 > $player2) || ($numthrows - ($winrange - $player1) <= $player2))
				);
					
	return $twowins;
				
}

sub num_to_name {
	my $self = shift;
	my $thrownum = shift;
	
	return $self->{thrownames}->{_names}->[$thrownum];
	
}

sub name_to_num {
	my $self = shift;
	my $throwname = uc(shift);
	
	my $thrownum = $self->{thrownames}->{$throwname};
	warn "Invalid Throw Name $throwname, returning undef" unless defined $thrownum;
        return $thrownum;
}

sub getaction {
	my $self = shift;
	my $a = shift;
	my $b = shift;

        if ($a =~ m/\D/) {
	   $a = $self->name_to_num($a);
	}

        if ($b =~ m/\D/) {
	   $b = $self->name_to_num($a);
	}

        return "ties" if $a == $b;

	my $ret = $self->{thrownames}->{_actions}->{$a}->{$b} ||
	       $self->{thrownames}->{_actions}->{$b}->{$a};

	return $ret;
}


1;
__END__

=head1 NAME

Games::Roshambo - Perl OO Rock/Paper/Scissors

=head1 VERSION

This document describes Games::Roshambo version 1.01

=head1 SYNOPSIS

	#!/usr/bin/perl

	use Games::Roshambo;

	my $rps = Games::Roshambo->new();

	print $rps->judge("rock") . "\n";
	print $rps->judge("scissors", "rock") . "\n";

=head1 DESCRIPTION

This module manages a game of Rock/Paper/Scissors, aka Roshambo L<http://en.wikipedia.org/wiki/Rock,_Paper,_Scissors>

=head1 INTERFACE

=over

=item C<new(...)>

You can specify an optional hashref containing configuration items.

Valid configuration items are:

=over

=item C<numthrows>

The number of separate valid throws for a game, for example, in Rock, Paper, Scissors,
there are 3 throws, while in a spirited game of RPS-101, there are 101 valid throws.
If not specified, this defaults to 3.

=item C<sortable>

OPTIONAL: Behold the madness of Chris Prather. Passing a TRUE value to C<new> for this
item will cause the C<judge> method to return values of -1 if Player 1 wins, 0 for a
tie and 1 for Player 2, instead of the 0, 1 and 2 it does normally.

The entirely dubious benefit of this is that the function can be used in conjunction
with C<sort>. It's his fault. He asked for it. Any questions as to the relative
usefulness of this should be directed at him. The management disavows all
knowledge.

=back

=item C<judge(...)>

This method will judge a game of RPS, returning a 1 for Player 1 winning, a 2 for
Player 2, and a 0 for a tie. (See the C<sortable> option to C<new> above for a twist.)

It takes up to two arguments, indicating the throws for Player 1 and Player 2, as text representations.

If one or both arguments are omitted, the method will internally call $self->gen_throw to randomly generate one.

=item C<getaction>

When called with two throws, this will return the text of the action for this
combination. For example, if called as C<$rps->getaction("rock", "paper")> the
returned value will be "covers".

This module contains actions for three throw (Rock, Paper, Scissors) and 101 throw
games, in any other number of throws, this method will return undef.

=back

=head1 DEPENDENCIES

None.

=head1 RPS-101

This module exists solely because I was trying to come up with an algorithmic method
of judging a game of RPS-101. L<http://www.umop.com/rps101.htm>.

David Lovelace has done a bang-up job, some would say to the point of obsession, in
defining the throws and actions of a game of Roshambo with 101 separate throws. The
throw names and actions defined in this module are taken from his set of definitions. 

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-acme-rps@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.


=head1 AUTHOR

Chris Thompson <cpan@cthompson.com>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2008, Chris Thompson <cpan@cthompson.com>. All rights
reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
