package Games::Chess::Position::Unicode;

our $VERSION = '0.01';

use strict;
use utf8;

use Encode       ();
use Games::Chess ();

use base 'Games::Chess::Position';

sub to_text {
    my $self = shift;

    my $pos = $self->SUPER::to_text;
    $pos =~ tr/pnbrqkPNBRQK/♟♞♝♜♛♚♙♘♗♖♕♔/;

    return Encode::encode_utf8($pos);
}

1 && q[Queens Of The Stone Age - Long Slow Goodbye];

__END__
=head1 NAME

Games::Chess::Position::Unicode - Chess position with Unicode pieces

=head1 SYNOPSIS

    use Games::Chess::Position::Unicode;
    use feature 'say';

    my $p = Games::Chess::Position::Unicode->new;
    say $p->to_text;

=head1 SEE ALSO

L<Games::Chess::Position|http://metacpan.org/module/Games::Chess#CHESS-POSITIONS> - base class

L<Games::Chess::Referee> - play the game!

=head1 AUTHOR

Sergey Romanov, C<sromanov@cpan.org>.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013 by Sergey Romanov.

This library is free software; you can redistribute it and/or modify
it under the terms of the Artistic License version 2.0.

=cut
