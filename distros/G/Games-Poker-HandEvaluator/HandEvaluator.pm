package Games::Poker::HandEvaluator;

use 5.006;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [ qw(
	evaluate handval
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw();
our $VERSION = '1.1';

require XSLoader;
XSLoader::load('Games::Poker::HandEvaluator', $VERSION);

sub evaluate {
    my $hand = shift;
    if (UNIVERSAL::isa($hand, "Games::Cards::CardSet")) {
        $hand = $hand->print;
        $hand =~ s/.*://; $hand =~ s/\s+/ /g;
        $hand =~ s/10/T/g;
    }
    return 0 unless $hand;
    _evaluate($hand);
}

# Preloaded methods go here.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Games::Poker::HandEvaluator - Evaluate poker hands

=head1 SYNOPSIS

   use Games::Poker::HandEvaluator qw(handval evaluate);
   use Games::Cards;
   my $Poker = new Games::Cards::Game;
   my $Deck = new Games::Cards::Deck ($Poker, "Deck");
   $Deck->shuffle;

   # Deal out the hands
   my $hand = Games::Cards::Hand->new($Poker, "Hand") ;
   $Deck->give_cards($hand, 7);

   print $hand->print("short"), "\n";
   # Hand:  JC   7C   8C   JH   3C   7S   5C  

   print handval(evaluate($hand)), "\n";
   # Flush (J 8 7 5 3)

Or just:

   my $hand_a = evaluate("Jc 7c 8c Jh 3c 7s 5c");
   my $hand_b = evaluate("9d 5d Ks 7h 5s 7s 4c");
   if ($hand_a > $hand_b) {
      print handval($hand_a), " beats ", handval($hand_b);
      # Flush (J 8 7 5 3) beats TwoPair (7 5 K)
   }
    
=head1 DESCRIPTION

This is an XS wrapper around the C<libpoker> library, found at 
L<http://www.pokersource.org/>. 

It provides two functions, which are not exported by default,
C<evaluate> and C<handval>. C<evaluate> turns a hand, as described
either by a C<Games::Card::CardSet> object or a simple string, into
an integer representing the best poker play for that hand. If the
hand cannot be parsed, 0 is returned. This integer value can be compared
with other hand evaluations; the higher the integer, the better the
hand.

C<handval> turns that value into a short textual description.

=head1 SEE ALSO

http://www.pokersource.org/

=head1 AUTHOR

Simon Cozens, E<lt>simon@kasei.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2003 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
