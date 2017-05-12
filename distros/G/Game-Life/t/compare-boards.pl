#!/usr/bin/perl -w

sub compare_boards {
    my ( $board1, $board2 ) = @_;
    return 0 if ( @$board1 != @$board2 );
    my $i = 0;
    foreach my $line ( @$board1 ) {
	return 0 if ( $line ne $$board2[$i] );
	$i++;
    }
    return 1;

}

42;

