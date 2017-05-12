package Games::Go::Cinderblock;

# ABSTRACT: Implementing a myriad of Go rulesets


our $VERSION = '0.13';

1;

__END__

=head1 NAME

Games::Go::Cinderblock - An engine for Go & Go variants.

=head1 Description

Well, for starters, you want a L<Rulemap|Games::Go::Cinderblock::Rulemap>.
For your initial board state, you might want to generate a
L<State|Games::Go::Cinderblock::State> with 
L<< $rulemap->initial_state|Games::Go::Cinderblock::Rulemap/initial_state >>.
then you might want to test a bunch of moves with 
L<< $state->attempt_move|Games::Go::Cinderblock::State/attempt_move >>.
The results & state changes, if any, would be packaged in a 
L<< MoveResult|Games::Go::Cinderblock::MoveResult >>.
When it's time to score, you get yourself a 
L<< Scorable|Games::Go::Cinderblock::Scorable >> with
L<< $state->scorable|Games::Go::Cinderblock::State/scorable >>,
mess with that for a while, and it tells you who wins or something.

=begin html

<img
src="http://cinderblock.zpmorgan.com/w.png"
alt="foo" width="72" height="72"
/>
<img
src="http://cinderblock.zpmorgan.com/b.png"
alt="foo" width="72" height="72"
/>
<img
src="http://cinderblock.zpmorgan.com/w.png"
alt="foo" width="72" height="72"
/>
<img
src="http://cinderblock.zpmorgan.com/b.png"
alt="foo" width="72" height="72"
/>

=end html

=head1 AUTHOR

    Zach Morgan

    <zpmorgan@gmail.com>

=head1 BUGS

Why would there be bugs?

=head1 NOTES

Go is also known as baduk & weiqi & igo

=head1 COPYRIGHT & LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. Or any terms that you like.

Really, it doesn't matter.

=cut
