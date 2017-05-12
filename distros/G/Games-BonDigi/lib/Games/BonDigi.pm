# $Id: BonDigi.pm 17 2008-01-13 14:23:52Z Cosimo $

package Games::BonDigi;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.02';

use constant HEADER      => 0;
use constant PAYLOAD     => 1;
use constant REPEAT_WORD => 0;
use constant REPEAT_SEQ  => 1;


#
# Class constructor
#
sub new
{
    my($class) = @_;
    $class = ref($class) || $class;
    my $self = [];
    bless $self, $class;
}

#
# Build and return an iterator for the Bon-Digi-... sequence
# Every time you call it, it gives you the right word
# to be said. Hopefully.
#
# Sequence is: Bon, Digi, Bon, Digi (header)
#              Bon, Bon, Digi, Digi (payload x 2),
#              Bon, Digi, Bon, Digi (header again),
#              Bon, Bon, Bon, Digi, Digi, Digi (payload x 3),
#              Bon, Digi, Bon, Digi (header again),
#              <...> (payload x 4),
#              <...>
#              <...> (payload x n),
#              
sub sequence
{
    my($self, $start, $end, @words) = @_;
    $start = 2 unless defined $start;
    $end   = 0 unless defined $end;
    @words = qw(bon digi) unless @words;

    #
    # Message structure is composed of:
    #
    # [HEADER] (fixed: "bon digi bon digi") +
    # [PAYLOAD] (grows over time: "bon bon digi digi", "bon bon bon digi digi digi")
    #
    my @repeats = (
        # This is the HEADER definition. Each word is repeated once,
        # 2 repeats of entire sequence (ex. "bon digi bon digi")
        [1, 2],

        # This is the PAYLOAD definition
        # each word is repeated '$start' times (and that keeps growing)
        # only 1 repeat of entire sequence (ex.: "bon bon digi digi")
        [$start, 1],
    );

    #
    # Define static vars for the iterator sub
    #
    my $rep  =
    my $word =
    my $i    =
    my $seq  = 0;

    my $iterator = sub
    {
        SEQUENCE: while($seq < $repeats[$rep][REPEAT_SEQ])
        {
            while($word < @words)
            {
                while($i++ < $repeats[$rep][REPEAT_WORD])
                {
                    return $words[$word];
                }
                $i = 0;
                $word++;
            }
            $seq++;
            $i = 0;
            $word = 0;
        }

        # Reinitialize sequence and restart 
        $rep = 1 - $rep;
        $seq = $i = $word = 0;

        # Payload now must grow by 1
        if($rep == HEADER)
        {
            $repeats[PAYLOAD][REPEAT_WORD]++;

            # Check for sequence termination.
            # We don't want to generate more than `$end' repetitions
            # If $end == 0, sequence is unterminated
            if($end > 0 && $repeats[PAYLOAD][REPEAT_WORD] > $end)
            {
                return undef;
            }
        }

        # Yes, a GOTO here
        goto SEQUENCE;
    };

    return $iterator;
}

1;

__END__

=head1 NAME

Games::BonDigi

=head1 ABSTRACT

This is a crazy experiment in game algorithms and list iterators.
And the algorithm to generate BonDigi sequences is quite interesting...

=head1 SYNOPSIS

    use Games::BonDigi;

    my $iter = Games::BonDigi->sequence();

    while(my $word = $iter->())
    {
        print $word, '!', "\n";
        # Wait for other players...
        sleep(1);
    }

=cut

=head1 DESCRIPTION

This is a crazy, crazy, crazy, crazy, *crazy* module.
There is absolutely *no* reason to download it.
Please, stay away from it, by any means!

Ok, I've warned you.

If you don't know what Bon-Digi is, you are really lucky.

Actually, this is a quite interesting experiment in
software design of clever algorithms. Either I'm stupid
or generating the sequence of "Bon" "Digi" words is
really much harder than I thought at first.

Try to think of an algorithm and to build *elegant* and
*concise* code. You will find that is not so easy...

For any meaning of elegant and concise, of course.

=head1 DEDICATION

Esteban, I promised to do that... And there it is!

=head1 THE GAME ITSELF

  This is (did I say it?) rather crazy. I will describe it as an
  RFC and then give you an example.

  BonDigi works with its own internal protocol. The protocol
  consists of a HEADER ("fixed part"), and a PAYLOAD ("the part
  that grows").

  HEADER is *always*: "Bon", "Digi", "Bon", "Digi"

  PAYLOAD is "Bon", "Bon", "Digi", "Digi" (2 repeats the first
  time, then it grows with 3, 4, 5, you get it)

=head1 FULL GRAMMAR

  <PROTOCOL> := "" | <HEADER> <PAYLOAD> <PROTOCOL>

  <HEADER>   := "Bon" "Digi" "Bon" "Digi"

  <PAYLOAD>  := "Bon" (<n> times) "Digi" (<n> times)
                where <n> grows over time

Mmmh, a recursive stateful grammar. Gets hard.
Ok, just kidding...

=head1 EXAMPLE

Suppose you are ten people in the same room, drinking beers
or something. Then someone starts this *crazy* game.

At turn, each of you must say the next word in the sequence.
If you say the wrong word, you must drink beer, write
Games::BonDigi, make yourself foolish, and so on...

Sequence starts like this:

    Bon, Digi, Bon, Digi, /*header*/, Bon, Bon, Digi, Digi, /*payload x 2*/,
    Bon, Digi, Bon, Digi, /*header*/, Bon, Bon, Bon, Digi, Digi, Digi, /*payload x 3*/
    ...

and you got it.
Right?

=head1 SEE ALSO

I didn't find any serious information about this game on the
internet. If you find it, please tell me about.

=head1 METHODS

=over

=item C<new()>

Just a class constructor, useless anyway.
If you want to use it, please do. Otherwise, you can use class name.

=item C<sequence( [$start [,$end [,@words]]] )>

Returns an iterator that generates the BonDigi(tm) sequence of words.
Without any parameters, the iterator will return words forever, in an 
endless crazy sequence of BonDigi words.

Parameters are:

=over

=item C<$start>

Start of repeats sequence. Default is 2. Means that the payload
starts by repeating each word C<$start> times.

=item C<$end>

End of repeats sequence. Just puts a cruel end to insane fun. Why?
By default, there's no end. If you set C<$end>, iterator will stop
exactly when the payload reaches C<$end> length in repeats.

=item C<@words>

If you supply your own words, the game won't really be B<BonDigi> anymore.
I warned you. Don't do evil.

=back

=back


=head1 SUPPORT

You are kidding me?

=head1 AUTHOR

Cosimo Streppone <cosimo@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 Cosimo Streppone.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The full text of the licenses can be found in the F<Artistic> and
F<COPYING> files included with this module, or in L<perlartistic> and
L<perlgpl> in Perl 5.8.1 or later.

=cut
