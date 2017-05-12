package Game::TextPacMonster;

use strict;
use warnings;
use utf8;
use Carp;

use Game::TextPacMonster::Map;

our $VERSION = '0.03';

sub level1 {
    my $map = <<'EOF';
###########
#.V..#..H.#
#.##...##.#
#L#..#..R.#
#.#.###.#.#
#....@....#
###########
EOF

    return Game::TextPacMonster->new(
        {
            timelimit  => 50,
            map_string => $map
        }
    );

}

sub level2 {
    my $map = <<'EOF';
####################
###.....L..........#
###.##.##.##L##.##.#
###.##.##.##.##.##.#
#.L................#
#.##.##.##.##.##.###
#.##.##L##.##.##.###
#.................L#
#.#.#.#J####J#.#.#.#
#L.................#
###.##.##.##.##.##.#
###.##.##R##.##.##.#
#................R.#
#.##.##.##.##R##.###
#.##.##.##.##.##.###
#@....R..........###
####################
EOF

    return Game::TextPacMonster->new(
        {
            timelimit  => 300,
            map_string => $map
        }
    );

}

sub level3 {
    my $map = <<"EOF";
##########################################################
#........................................................#
#.###.#########.###############.########.###.#####.#####.#
#.###.#########.###############.########.###.#####.#####.#
#.....#########....J.............J.......###.............#
#####.###.......#######.#######.########.###.#######.#####
#####.###.#####J#######.#######.########.###.##   ##.#####
#####.###L#####.##   ##L##   ##.##    ##.###.##   ##.#####
#####.###..H###.##   ##.##   ##.########.###.#######J#####
#####.#########.##   ##L##   ##.########.###.###V....#####
#####.#########.#######.#######..........###.#######.#####
#####.#########.#######.#######.########.###.#######.#####
#.....................L.........########..........R......#
#L####.##########.##.##########....##....#########.#####.#
#.####.##########.##.##########.##.##.##.#########.#####.#
#.................##............##..@.##...............R.#
##########################################################
EOF

    return Game::TextPacMonster->new(
        {
            timelimit  => 700,
            map_string => $map
        }
    );
}

sub new {
    my ( $class, $map_info_ref ) = @_;

    my $wrong = Game::TextPacMonster->_do_input_validation($map_info_ref);
    if ($wrong) {
	croak $wrong;
    }

    chomp( $map_info_ref->{map_string} );

    my $self = { _map => Game::TextPacMonster::Map->new($map_info_ref) };

    bless $self, $class;
    return $self;
}


sub run {
    my $self = shift;
    my $map = $self->{_map};

    my $order = q{};
    my $win_message = 'You win';
    my $message = 'You lose!!!'; # lose message default

    while (1) {
	system('clear');

	print $map->get_string ."\n";
	print 'feed(s) left: ' . $map->count_feeds . "\n";
	print 'time left: ' . $map->get_left_time . "\n";
	print 'log: ' . $map->get_log . "\n";

	if ($map->is_lose || $map->is_win) {
	    $message = 'You win!!!' if $map->is_win;
	    last;
	}

        print 'Your turn [k/j/h/l/.]: ';
	$order = <STDIN>;
	chomp $order;
	$map->command_player($order);
    }

    print "$message\n";
    exit;
}




sub _do_input_validation {
    my ( $class, $input ) = @_;

    if ( !defined( $input->{timelimit} ) ) {
        return q/An input param 'timelimit' has not been set./;
    }

    if ( !defined( $input->{map_string} ) ) {
        return q/An input param 'map_string' has not been set./;
    }

    if ( $input->{timelimit} <= 0 ) {
        return q/An input param 'timelimit' should be lager than 0./;
    }

    if ( $input->{map_string} !~ qr/\./m ) {
        return q/An input param 'map_string' should include '.' ./;
    }

    if ( $input->{map_string} =~ qr/[^#VHLRJ@.\s]/m ) {
        return
q/An input param 'map_string' should be char set '#VHLRJ@.' and 'SPACE' ./;
    }

    my $match_num = scalar( () = $input->{map_string} =~ /@/g );
    if ( $match_num != 1 ) {
        return
          q/An input param 'map_string' should inculde just only one '@' ./;
    }

    # to make array like $map[height][width]
    chomp $input->{map_string};
    my @map = map {
        my @x_map = map { $_ } split( //, $_ );
        \@x_map;
    } split( /\n/, $input->{map_string} );

    my $width_valid = 1;
    my $w           = scalar( @{ $map[0] } );    # width
    my $h           = scalar(@map);              # height
    for (@map) {
        $width_valid = 0 if ( $w != scalar(@$_) );
    }

    my $surface_valid = 1;

    for ( 0 .. ( $w - 1 ) ) {
        $surface_valid = 0 if ( $map[0][$_] . $map[ $h - 1 ][$_] ne '##' );
    }

    for ( 0 .. ( $h - 1 ) ) {
        $surface_valid = 0 if ( $map[$_][0] . $map[$_][ $w - 1 ] ne '##' );
    }

    if ( !$width_valid ) {
        return q/An input param 'map_string' should shape square' ./;
    }

    if ( !$surface_valid ) {
        return q/An input param 'map_string' s 4 sides should be all '#'  ./;
    }

    return 0;
}

1;


__END__

=head1 NAME

Game::TextPacMonster - A Packman style game on Terminal

=head1 SYNOPSIS

  You can enjoy games called "level1", "level2" and "level3" by default.
  You may also create your own games.

  To play the game is as follows.

    use strict;
    use warnings;
    use Game::TextPacMonster;

    my $game = Game::TextPacMonster->level1; # level2 or level3
    $game->run;


  To make your original game is as follows.

     use strict;
     use warnings;
     use Game::TextPacMonster;

     my $map =<<'MAP';
     #############
     # . # . # R #
     #           #
     #           #
     # @ # . # . #
     #############
     MAP

     my $timelimit = 60;

     my $game = Game::TextPacMonster->new(
         {
             timelimit => $timelimit,
             map_string => $map
         }
     );

     $game->run;

=head1 DESCRIPTION

Game::TextPacMonster is a Packman style game on Terminal.
A player as "@" has to eat all "." while escape enemies "R", "L", "V", "H" and "J".

=head1 AUTHOR

Takashi Uesugi E<lt>tksuesg@gmail.comE<gt>

=head1 SEE ALSO

  http://blog.goo.ne.jp/80-cafe/e/f8fc7916cba530fb638a3983ece65a18
  http://www.geocities.co.jp/SiliconValley-Oakland/8742/gakken/puckm.html


=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


