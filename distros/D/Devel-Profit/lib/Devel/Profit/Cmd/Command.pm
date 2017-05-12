package Devel::Profit::Cmd::Command;
use strict;
use warnings;
use Term::Size;

sub show {
    my ( $self, $usecs_db, $totusecs ) = @_;

    my ( $columns, $rows ) = Term::Size::chars;
    my $max = $rows - 2;

    foreach my $bit (
        sort { $usecs_db->{$b} <=> $usecs_db->{$a} }
        keys %$usecs_db
        )
    {
        my $usecs    = $usecs_db->{$bit};
        my $usecs_pc = $usecs * 100 / $totusecs;
        printf( "%4.0f%% %s\n", $usecs_pc, $bit );
        last unless --$max;
    }
}

1;
