#!perl
use strict;
use warnings;
use Game::LevelMap;
use Test::Most;

my $lm;

# not really useful but is the default
lives_ok { $lm = Game::LevelMap->new };
is( $lm->to_string, $/ );

my $dots3x3 = [ [qw(. . .)] x 3 ];

$lm = Game::LevelMap->new( level => $dots3x3 );
my $s = $lm->to_string;
is( $s, "...$/...$/...$/" );

$lm->from_string($s);
eq_or_diff( $lm->level, $dots3x3 );

$lm = Game::LevelMap->new( from_string => $s );
eq_or_diff( $lm->level, $dots3x3 );

# uneven column lengths are not permitted
dies_ok { Game::LevelMap->new( level       => [ [qw(. .)], [qw(.)] ] ) };
dies_ok { Game::LevelMap->new( from_string => "..$/." ) };

# better coverage purity
dies_ok { Game::LevelMap->new( from_string => $s, level => $dots3x3 ) };

# some complications around testing output that goes to a terminal
my ( $buf, $want );

sub buf2hex { diag sprintf "got,want\n%vx\n%vx\n", $buf, $want }

sub capture (&) {
    $buf = '';
    open( my $fh, '>', \$buf ) or die "could not open in-memory fh?? $!";
    #$fh->autoflush(1);
    my $stdout = select $fh;
    $_[0]->();
    select $stdout;
    return $buf;
}

$want = "\e[1;1H...\e[2;1H...\e[3;1H...";
ok( capture { $lm->to_terminal( 1, 1 ) } eq $want ) or buf2hex;

$want = "\e[2;5H...\e[3;5H...\e[4;5H...";
ok( capture { $lm->to_terminal( 5, 2 ) } eq $want ) or buf2hex;

# this though is a shallow copy so something with objects...
my $clone = $lm->clone;
$lm->level->[0][0] = 'x';
eq_or_diff( $clone->level,  $dots3x3 );
eq_or_diff( $lm->to_string, "x..$/...$/...$/" );

# to_panel
$lm = Game::LevelMap->new( from_string => <<'EOF' );
#######
#.....#
#.....#
#.....#
#.....#
#.....#
#.....#
#######
EOF

my @offs = ( 1, 1 );
my @size = ( 3, 3 );

$want = "\e[1;1H   \e[2;1H ##\e[3;1H #.";
ok( capture { $lm->to_panel( @offs, @size, 0, 0 ) } eq $want ) or buf2hex;

$want = "\e[1;1H###\e[2;1H#..\e[3;1H#..";
ok( capture { $lm->to_panel( @offs, @size, 1, 1 ) } eq $want ) or buf2hex;

# custom out-of-bounds character
$want = "\e[1;1Hqqq\e[2;1Hq##\e[3;1Hq#.";
ok( capture {
        $lm->to_panel( @offs, @size, 0, 0, sub { 'q' } )
    }
      eq $want
) or buf2hex;

# level map wraps around
$lm = Game::LevelMap->new( from_string => <<'EOF' );
XabcdeY
0xj.rg1
9.....2
8.....3
7.....4
6YJ.RN5
WuvwxyZ
EOF

@size = ( 5, 5 );

$want = "\e[1;1H..7..\e[2;1HRN6YJ\e[3;1HdeXab\e[4;1Hrg0xj\e[5;1H..9..";
ok( capture {
        $lm->to_panel(
            @offs, @size, 0, 0,
            sub {
                my ( $lm, $col, $row, $mcols, $mrows ) = @_;
                return $lm->[ $row % $mrows ][ $col % $mcols ];
            }
        )
    }
      eq $want
) or buf2hex;

$want = "\e[2;6Ha\e[3;7Hj";
ok( capture { $lm->update_terminal( 5, 2, [ 1, 0 ], [ 2, 1 ] ) } eq $want )
  or buf2hex;

# display point must not lie outside level map
for my $i ( -5, 999 ) {
    dies_ok { $lm->to_panel( @offs, @size, $i, 0 ) };
    dies_ok { $lm->to_panel( @offs, @size, 0,  $i ) };
}

done_testing 21
