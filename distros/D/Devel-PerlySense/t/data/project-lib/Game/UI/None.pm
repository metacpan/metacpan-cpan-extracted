=head1 NAME

Game::UI::None - Spoof UI for the game. Does nothing 
whatsoever.

=head1 SYNOPSIS

Nah...

=cut





package Game::UI::None;





use strict;





=head1 PROPERTIES

=head1 METHODS

=head2 new($oLawn)

Create new bogus UI

=cut
sub new { my $pkg = shift;
    my ($oLawn) = @_;

    my $self = {};
    bless $self, $pkg;

    return($self);
}






=head2 AUTOLOAD()

Return 1.

=cut
sub AUTOLOAD { my $self = shift;
    return(1);
}




1;





#EOF
