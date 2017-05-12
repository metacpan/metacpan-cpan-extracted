#!/usr/bin/perl
#===============================================================================
#
#     ABSTRACT:  perl implementation of bayrate.cpp
#      PODNAME:  bayrate.pl
#
#       AUTHOR:  Reid Augustin
#        EMAIL:  reid@hellosix.com
#      CREATED:  06/15/2011 01:54:58 PM
#===============================================================================

use strict;
use warnings;
# this test apparently isn't smart enough to tell difference between object
#    attribute access and real hash-refs:
## no critic (ProhibitAccessOfPrivateData)
use Readonly;
use DBI;
use Carp;
use IO::File;

use Getopt::Long;
use Math::GSL::Errno ( ':all' ); # for various constants like $GSL_SUCCESS
use Math::GSL::Multimin ( 'gsl_multimin_fdfminimizer_minimum' );
use Math::GSL::BLAS ( 'gsl_blas_dnrm2' );
use Games::Go::AGA::BayRate::GSL::Multimin qw(
    raw_gsl_multimin_fminimizer_fval
    raw_gsl_multimin_fdfminimizer_gradient
);
use Games::Go::AGA::BayRate::Collection;

our $VERSION = '0.119'; # VERSION

# # column offset in games table
# Readonly my $Game_ID              => 0 ;
# Readonly my $Game_Tournament_Code => 1 ;
# Readonly my $Game_Date            => 2 ;
# Readonly my $Game_Round           => 3 ;
# Readonly my $Game_Pin_Player_1    => 4 ;
# Readonly my $Game_Color_1         => 5 ;
# Readonly my $Game_Rank_1          => 6 ;
# Readonly my $Game_Pin_Player_2    => 7 ;
# Readonly my $Game_Color_2         => 8 ;
# Readonly my $Game_Rank_2          => 9 ;
# Readonly my $Game_Handicap        => 10;
# Readonly my $Game_Komi            => 11;
# Readonly my $Game_Result          => 12;
# Readonly my $Game_Online          => 13;
# Readonly my $Game_Exclude         => 14;
# Readonly my $Game_Rated           => 15;
# Readonly my $Game_Elab_Date       => 16;
# # column offset in ratings table
# Readonly my $Pin_Player           => 0;
# Readonly my $Name                 => 1;
# Readonly my $Rating               => 2;
# Readonly my $Sigma                => 3;
# Readonly my $Player_Elab_Date     => 4;
# # column offset in tournaments table
# Readonly my $Tournament_Code      => 0;
# Readonly my $Tournament_Descr     => 1;
# Readonly my $Tournament_Date      => 2;

# used in game query in getTournamentInfo
Readonly my $g_pin_player_1       => 0;
Readonly my $g_rank_1             => 1;
Readonly my $g_color_1            => 2;
Readonly my $g_pin_player_2       => 3;
Readonly my $g_rank_2             => 4;
Readonly my $g_color_2            => 5;
Readonly my $g_handicap           => 6;
Readonly my $g_komi               => 7;
Readonly my $g_result             => 8;

my %parse_init_skip = (
    set    => 1,
    unlock => 1,
    drop   => 1,
    lock   => 1,
);
my %parse_init_do = (
    insert => \&parse_insert,
    create => \&parse_create,
);

my $usage = qq{
usage: bayrate.pl [ mysql ] [ sqlite filename ]
Options:
    -mysql              connect to MySQL database (default: SQLite)
    -sqlite filename    filename for SQLite database (default is
                           database.sql) if filename does not exist,
                           this script creates a new database from
                           testdata.sql.dump
    -strict_compliance  turn on strict compliance with original
                           bayrate C++ code
    -commit             commit changes to database (default: no commits)
};

my $mysql;                      # use MySQL database?
my $sqlite = 'database.sql';    # default SQLite filename
my $commit = 0;
my $db_initfile = 'testdata.sql.dump';
my $strict_compliance = 0;      # as close to original bayrate C++ code as possible

if (not GetOptions(
    'mysql!'             => \$mysql,
    'sqlite=s'           => \$sqlite,
    'strict_compliance!' => \$strict_compliance,
    'commit'             => \$commit,
    'help'               => sub { print $usage; exit 0; },
)) {
    print $usage;
    exit 0;
}

if (not $strict_compliance) {
    print "Note: -strict_compliance not specified, expect\n",
          "      small variances from the C++ results\n";
}
my $dbh;
if ($mysql) {
    $dbh = DBI->connect('DBI:mysql:usgo_agagd', 'aga', 'aga')
                or die "Couldn't connect to database: " . DBI->errstr;
}
else {  # SQLite
    my $need_init = not -f $sqlite;
    $dbh = DBI->connect(          # connect to your database, create if needed
        "dbi:SQLite:dbname=$sqlite", # DSN: dbi, driver, database file
        "",                          # no user
        "",                          # no password
        {
            AutoCommit => 1,
            RaiseError => 1,         # complain if something goes wrong
        },
    );
    init_db() if ($need_init);
}

excludeBogusGameData($dbh);
#show_excludes($dbh);
my ($tournamentCascadeDate, $tournamentUpdateList) = getTournamentUpdateList($dbh);

croak("No tournaments to update") if (not @{$tournamentUpdateList});

print "Updating all tournaments after $tournamentCascadeDate\n";

my $tdList = getTDList($dbh, $tournamentCascadeDate);

print "Downloaded TDList\n";

foreach my $t (@{$tournamentUpdateList}) {

    print "Processing $t\n";
    my $collection = getTournamentInfo($dbh, $t);
    next if (not $collection);

    $collection->initSeeding($tdList);

    $collection->calc_ratings;
    # Copy the new ratings into the internal TDList for the next tournament update
    foreach my $c_player (@{$collection->players}) {
        my $id = $c_player->get_id;
        $tdList->{$id} ||= {};    # create if not already there
        my $t_player = $tdList->{$id};

        $t_player->{rating}         = $c_player->{rating};
        $t_player->{sigma}          = $c_player->{sigma};
        $t_player->{lastRatingDate} = $collection->tournamentDate_ymd;
        $t_player->{ratingUpdated}  = 1;

        printf("%s\t% .24g (delta=% .24g, sigma=% .24g)\n",
            $id, $c_player->get_rating,
            $c_player->get_crating - $c_player->get_cseed,
            $c_player->{sigma});
    }
    print "\n";

    # Update database
    if ($commit) {
        print "Committing results to database...";
        syncNewRatings($dbh, $collection);
        print "done.\n";
    }
# last if ($t eq 'tourn0'); # TODO
}
print "Done ratings\n";

foreach my $id (sort { $a <=> $b } keys %{$tdList}) {
    my $player = $tdList->{$id};
    if ($player->{ratingUpdated}) {
        printf("%s\t% .24g (sigma=% .24g)\n", $id, $player->{rating}, $player->{sigma});
    }
}

$dbh->disconnect;



sub show_excludes {
    my ($dbh) = @_;
    my $sth = $dbh->prepare('SELECT * FROM games WHERE exclude = 1')
                or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute()     # Execute the query
        or die "Couldn't execute statement: " . $sth->errstr;

    my $ii = 0;
    while (my @data = $sth->fetchrow_array) {
        print join(', ', @data), "\n" if ($ii++ < 6);
    }
    print "$ii excluded games\n";
    $sth->finish;
}

sub excludeBogusGameData {
    my ($dbh) = @_;

    foreach my $cond (
        qq{NOT (rank_1 LIKE '%k%' OR rank_1 LIKE '%K%' OR rank_1 LIKE '%d%' OR rank_1 LIKE '%D%')},
        qq{NOT (rank_2 LIKE '%k%' OR rank_2 LIKE '%K%' OR rank_2 LIKE '%d%' OR rank_2 LIKE '%D%')},
        qq{(rank_1 = '0k' OR rank_1 = '0K' OR rank_1 = '0d' OR rank_1 = '0D')},
        qq{(rank_2 = '0k' OR rank_2 = '0K' OR rank_2 = '0d' OR rank_2 = '0D')},
        qq{handicap>9},
        qq{handicap>=2 and komi>=10},
        qq{handicap>=2 and komi<=-10},
        qq{(handicap=0 or handicap=1) and komi<=-20},
        qq{(handicap=0 or handicap=1) and komi<=-20},   # BUGBUG: >= 20 ?
        qq{(game_date < '1900-01-01')},
        qq{pin_player_1 = 0 or pin_player_2 = 0},
        ) {
        $dbh->do("UPDATE games SET exclude = 1 WHERE $cond")
           or die "Couldn't do statement: " . $dbh->errstr;
    }
}

sub getTournamentUpdateList {
    my ($dbh) = @_;

    my $sth = $dbh->prepare("SELECT MIN(Game_Date) AS date FROM games WHERE Game_Date>'1900-01-01' AND NOT (Online OR Exclude OR Rated)")
           or die "Couldn't prepare statement: " . $dbh->errstr;

    $sth->execute()     # Execute the query
        or die "Couldn't execute statement: " . $sth->errstr;
    my $ii = 0;
    my @data = $sth->fetchrow_array;
    my $tournamentCascadeDate = $data[0];
    $sth->finish;

    my @tournamentUpdateList = ();
    $sth = $dbh->prepare("SELECT Tournament_Code FROM tournaments WHERE Tournament_Date>=? ORDER BY Tournament_Date, Tournament_Code")
           or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($tournamentCascadeDate)     # Execute the query
        or die "Couldn't execute statement: " . $sth->errstr;
    while (my @data = $sth->fetchrow_array) {
        push @tournamentUpdateList , $data[0];
    }
    $sth->finish;
# print join "\n", 'Update list:', @tournamentUpdateList;
    return ($tournamentCascadeDate , \@tournamentUpdateList);
}

# TODO this returns nothing?
sub getTDList {
    my ($dbh, $tournamentCascadeDate) = @_;

    my (undef,undef,undef,$mday,$mon,$year,undef,undef,undef) = localtime(time);
    my $today = sprintf '%4d-%2d-%2d', $year, $mon + 1, $mday;

    my $sth = $dbh->prepare("SELECT name, x.pin_player, x.rating, x.sigma, x.elab_date FROM ratings x, players, (SELECT MAX(elab_date) AS maxdate, pin_player FROM ratings WHERE elab_date < ? GROUP BY pin_player) AS maxresults WHERE x.pin_player=maxresults.pin_player AND x.elab_date=maxresults.maxdate and x.pin_player=players.pin_player and x.pin_player!=0")
                or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($tournamentCascadeDate)     # Execute the query
        or die "Couldn't execute statement: " . $sth->errstr;

    my %tdList;
    while (my @data = $sth->fetchrow_array) {
        my ($name, $id, $rating, $sigma, $elab_date) = @data;
        my $date = '1900-01-01';
        if ($elab_date ne '0000-00-00') {
            $date = $today;
        }
        $tdList{$id} = {
            id             => $id,
            rating         => $rating,
            sigma          => $sigma,
            name           => $name,
            lastRatingDate => $date,
            ratingUpdated  => 0,
        };
    }
    $sth->finish;
    return \%tdList;
}

sub getTournamentInfo {
    my ($dbh, $tournament_code) = @_;

    my $sth = $dbh->prepare("SELECT Tournament_Date, Tournament_Descr FROM tournaments WHERE tournament_code=? LIMIT 1")
                or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth->execute($tournament_code)     # Execute the query
        or die "Couldn't execute statement: " . $sth->errstr;
    my @data = $sth->fetchrow_array;
    return if ($data[0] eq '0000-00-00');

    $sth->finish;
    my $tournamentDate = $data[0];
    my $tournamentName = $data[1];

    $sth = $dbh->prepare("SELECT pin_player_1, rank_1, color_1, pin_player_2, rank_2, color_2, handicap, komi, result FROM games WHERE Tournament_Code=? AND NOT (Online OR Exclude)")
                or die "Couldn't prepare statement: " . $dbh->errstr;

    $sth->execute($tournament_code)     # Execute the query
        or die "Couldn't execute statement: " . $sth->errstr;

    my (@games, %player_seeds_by_id);
    while (my @data = $sth->fetchrow_array) {
        # Process and locally store the game information
        my %game;
        if ($data[$g_color_1] eq 'W') {
            $game{white} = $data[$g_pin_player_1];
            $game{black} = $data[$g_pin_player_2];
        }
        elsif ($data[$g_color_1] eq 'B') {
            $game{white} = $data[$g_pin_player_2];
            $game{black} = $data[$g_pin_player_1];
        }
        else {
            croak("unknown player colour:  $data[$g_color_1]\n");
        }

        if ($data[$g_result] eq 'W') {
            $game{whiteWins} = 1;
        }
        elsif ($data[$g_result] eq 'B') {
            $game{whiteWins} = 0;
        }
        else {
            croak("unknown game result: $data[$g_result]\n");
        }

        $game{handicap}  = $data[$g_handicap];
        $game{komi}      = $data[$g_komi];

        push @games, \%game;

        # Process and locally store the player information
        foreach my $which (0 .. 1) {
            my $pin_idx  = $which ? $g_pin_player_2 : $g_pin_player_1;
            my $rank_idx = $which ? $g_rank_2 : $g_rank_1;
            my $id = $data[$pin_idx];
            next if (exists $player_seeds_by_id{$id});

            my $rank = $data[$rank_idx];
            if (my ($rating, $range) = $rank =~ m/^(\d+)([KDkd])$/) {
                $rating += 0.5; # make e.g: 5d = 5.5
                $player_seeds_by_id{$id} = (uc $range eq 'D') ? $rating : -$rating;
            }
            else {
                croak("Illegal rank: " . $data["\$g_rank_$which"]);
            }
        }
    }
    $sth->finish;
    return if (not @games);

    my $collection = Games::Go::AGA::BayRate::Collection->new(
            iter_hook         => \&iter_hook,
            tournamentDate    => $tournamentDate,
            strict_compliance => $strict_compliance, # match original bayrate C++ code exactly
            #f_iterations     => 50,
            #fdf_iterations   => 50,
    );

    # enter all the players who were in a game
    my %players_by_id;
    foreach my $id (sort { $a <=> $b } keys %player_seeds_by_id) {
        $players_by_id{$id} = $collection->add_player(
            id     => $id,
            seed   => $player_seeds_by_id{$id},
            sigma  => 6.0,  # will get changed later
        );
    }

    # enter all the games
    foreach my $game (@games) {
        $collection->add_game(
            white     => $players_by_id{$game->{white}},
            black     => $players_by_id{$game->{black}},
            whiteWins => $game->{whiteWins},
            handicap  => $game->{handicap},
            komi      => $game->{komi},
        );
    }

    printf("%s\t%s\t%s (%d players in %d games)\n",
        $tournament_code,
        $collection->tournamentDate_ymd,
        $tournamentName,
        scalar (keys %players_by_id),
        scalar @games,
    );

    return $collection;
}

# hook called for each F(DF)Minimzer iteration
sub iter_hook {
    my ($collection, $state, $iter, $status) = @_;

    if (ref $state eq 'Math::GSL::Multimin::gsl_multimin_fminimizer') {
        my $f = # gsl_multimin_fminimizer_fval($state),    # hmm, struct member, not a function
                # ok, do it this way instead:
            raw_gsl_multimin_fminimizer_fval($state),
        my $size = gsl_multimin_fminimizer_size($state);
        printf("F Iteration %d\tf() = %g\tsimplex size = %g\n", $iter, $f, $size);
        if ($status == $GSL_SUCCESS) {
            printf "\nConverged to minimum. f() = %g\n", $f;
        }
    }
    elsif (ref $state eq 'Math::GSL::Multimin::gsl_multimin_fdfminimizer') {
        my $gradient = raw_gsl_multimin_fdfminimizer_gradient($state);
        my $minimum = gsl_multimin_fdfminimizer_minimum($state);
        printf("FDF Iteration %d\tf() = %g\tnorm = %g\tStatus = %d\n",
            $iter,
            $minimum,
            gsl_blas_dnrm2($gradient),
            $status);
        if ($status == $GSL_SUCCESS) {
            printf "\nConverged to minimum. Norm(gradient) = %g\n",
                gsl_blas_dnrm2($gradient),
        }

 #      printf "%s %5d  f()=%2.5e  Norm=%2.5e %s",
 #          ($status == $GSL_SUCCESS)
 #              ?  "Converged:"
 #              :  "Iteration:",
 #          $iter,
 #          $state->minimum,
 #          $state->gradient->blas_dnrm2,
 #          ($status == $GSL_CONTINUE) ? '' : errno_to_description($status);
    }
    else {
        die(sprintf("Unknown minimizer state type: %s", ref $state));
    }
#   my $max_diff = my $max_inc_diff = -1000000;
#   my $min_diff = my $min_inc_diff =  1000000;
#   if ($iter > 1) {
#       foreach my $p (@{$collection->{players_array}}) {
#           my $diff = $p->get_cseed - $p->get_crating;
#           $max_diff = $diff if ($diff > $max_diff);
#           $min_diff = $diff if ($diff < $min_diff);
#           my $inc_diff = $p->{prev_crating} - $p->get_cseed;
#           $max_inc_diff = $inc_diff if ($inc_diff > $max_inc_diff);
#           $min_inc_diff = $inc_diff if ($inc_diff < $min_inc_diff);
#       }
#       printf(" max=%1.3e min=%1.3e  max_inc=%1.3e min_inc=%1.3e",
#           $max_diff, $min_diff, $max_inc_diff, $min_inc_diff);
#   }
#   foreach my $p (@{$collection->{players_array}}) {
#       $p->{prev_crating} = $p->get_crating;
#   }
}

sub init_db {

    my $fh = IO::File->new($db_initfile, 'r')
        or die "Can't open $db_initfile for reading: $!";
    my $cmd = '';
    $dbh->do('BEGIN');
    while(my $line = <$fh>) {
        chomp $line;
        $line =~ s/--.*//;              # remove comments
        $line =~ s/\/\*.*\*\///;        # remove comments
        next if (not $line =~ m/\S/);   # skip blank lines
        $cmd .= $line;
        while ($cmd =~ s/(.*);//) {
            parse_init_cmd($1);
        }
    }
    $dbh->do('COMMIT');
}

sub parse_init_cmd {
    my ($line) = @_;

    if ($line =~ m/^\s*(\w*)\s*/) {
        my $cmd = $1;
        return if (not $cmd);             # empty command line
        return if ($parse_init_skip{lc $cmd});  # commands to skip
        if ($parse_init_do{lc $cmd}) {          # commands to do
          # print "do $cmd\n";
            $line =~ s/\b(unsigned|auto_increment)\b//ig;
            $line =~ s/\bcharacter\s+set\s+\S+\b//ig;
            $line =~ s/\bcollate\s+\S+//ig;
            $line =~ s/\bunique\s+key\s*\S+\s*\([^)]*\)//ig;
            $line =~ s/\bengine\s*=\s*\w*\s*=\s*\w*//ig;
            $line =~ s/\bengine\s*=\s*\w*//ig;
            $line =~ s/\bdefault\s+charset\s*=\s*\w*//ig;
            $line =~ s/(\bprimary\s+)?\bkey\b.*?\(.*?\)\s*,?//ig;
            $line =~ s/,\s*\)/)/ig;
            $line =~ s/["`]/'/g;
            &{$parse_init_do{lc $cmd}}($line);
            return;
        }
        print "UNKNOWN $cmd\n";
    }
}

sub parse_create {
    my ($line) = @_;

    $dbh->do($line);
}

sub parse_insert {
    my ($line) = @_;

    my (@inserts) = split /\),\s*\(/, $line;
    $inserts[0] =~ s/([^(]*)//;
    my $prefix = $1;
    $inserts[0]  =~ s/\(//;
    $inserts[-1] =~ s/\)\s*$//;
    foreach my $insert (@inserts) {
        $dbh->do("$prefix($insert)");
    }
}

