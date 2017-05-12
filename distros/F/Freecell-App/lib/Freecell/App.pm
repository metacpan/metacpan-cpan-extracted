package Freecell::App;
use version;
our $VERSION = '0.03';
use warnings;
use strict;
use Freecell::App::Tableau;
use Getopt::Long;
use Log::Log4perl;
use File::Slurp;
use List::Util qw(min);

my $QUIT_NOW = 0;
$SIG{'INT'} = sub { $QUIT_NOW = 1 };

my $cnt;              # new positions
my $dup;              # potential dupes
my $tot       = 0;
my $found     = 0;
my $depth     = 0;    # maxnodes estimates - sometimes better solution when higher
my $max_depth = 55;   # 2000   < 2GB,  5-10 mins to solve, perl x86 (32bit) ok
my $max_nodes = 2000; # 25000  ~ 2GB, 20-40 mins to solve, perl x64 (64bit) only
my $game_no   = 0;    # 100000 > 4GB, over 2 hrs to solve
my $log_stats = 0;    # 250000 > 16GB, out_of_memory!
my $show_all  = 0;
my $fcgsfile  = '';
my %stats;
my @solution;
my $position;         # seen layouts
my $logger;

sub getopts {

    my $result = GetOptions(
        "gameno:i"   => \$game_no,      #numeric
        "maxnodes:i" => \$max_nodes,    #numeric
        "winxp!"     => sub { Freecell::App::Tableau->winxp_opt($_[1]) },
        "showall!"   => \$show_all,     #boolean
        "maxdepth:i" => \$max_depth,    #numeric
        "logstats!"  => \$log_stats,    #boolean
        "analyze:s"  => \$fcgsfile,     #string
    );
    usage_quit(0) if !($result and ($game_no == -1 or $game_no >= 1 and $game_no <= 1_000_000 or $fcgsfile));

    sub usage_quit {

        # Emit usage message, then exit with given error code.
        print <<"END_OF_MESSAGE"; exit;

Usage:
freecell-solver  [switches]
This will solve a selected game of Freecell.
  
Switches:
 --gameno      number of freecell game to solve (required 1-1000000)
 --maxnodes    set maximum nodes per level to search (default 2000)
 --winxp       solve for windows xp (no supermove)(default --nowinxp)
 --showall     log all moves and layouts with solution (default --noshowall)
END_OF_MESSAGE
    }
}

sub initlog {

    #   Initialize Logger
    my $log_conf = q(
      log4perl.rootLogger              = DEBUG, LOG1, LOG2
      log4perl.appender.LOG1           = Log::Log4perl::Appender::File
      log4perl.appender.LOG1.filename  = fc_0_01.log
      log4perl.appender.LOG1.mode      = append
      log4perl.appender.LOG1.layout    = Log::Log4perl::Layout::PatternLayout
      log4perl.appender.LOG1.layout.ConversionPattern = %d %p %m %n

      log4perl.appender.LOG2           = Log::Log4perl::Appender::Screen
      log4perl.appender.LOG2.stderr    = 0
      log4perl.appender.LOG2.layout    = Log::Log4perl::Layout::PatternLayout
      log4perl.appender.LOG2.layout.ConversionPattern = %d %p %m %n
    );
    Log::Log4perl::init( \$log_conf );
    $logger = Log::Log4perl->get_logger();
}

sub stats {
    my $log = "stats\n";
    foreach my $depth ( sort { $a <=> $b } keys %stats ) {
        $log .= sprintf "%s\n", $depth;
        foreach my $score ( sort { $a <=> $b } keys %{ $stats{$depth} } ) {
            $log .= sprintf "\t%s\t%s\t%s\n", $score,
              map { defined($_) ? $_ : " " }
              @{ $stats{$depth}{$score} }[ 0, 1 ];
        }
    }
    $log;
}

sub out {
    my ( $game_no, $max_nodes, @solution ) = @_;
    my $depth = @solution;
    my $file = sprintf "#%s %s %sk %s", $game_no, $depth, $max_nodes / 1000,
      ( Freecell::App::Tableau->winxp_opt() ? "xp" : Freecell::App::Tableau->winxp_warn() ? "w7" : "all" );
    my $log = "\n\n";
    my $std = "\n\n#$game_no\n";
    my $cnt = 0;
    my $htm = <<"eof";
<!DOCTYPE html><head><title>Freecell in Miniature $file</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<style>
<!--
table  {border-collapse: collapse;}
th, td {border: 1px solid #ddd;}
th     {background-color: #e7f6f8; font-weight: bold;}
td     {background-color: #f4f4f4; text-align: center;}
caption {background: #f4f4f4;  font-weight: bold;}
-->
</style></head><body>
eof
    $htm .=
        "<table><caption>Game #$game_no (Windows "
      . ( Freecell::App::Tableau->winxp_opt() || !Freecell::App::Tableau->winxp_warn() ? "XP, " : "" )
      . "Vista, 7)</caption>\n";
    $htm .= "<tr><th>No<th>SN<th>Move<th>To<th>Autoplay to home\n";

    foreach (@solution) {
        my ( $layout, $score0, $score1, @note ) = split /\t/, $_, 8;
        $stats{ $note[0] - 1 }{$score0}[1] = scalar @solution;
        $log .= "($score0) @note\n\n$layout";
        $std .= $note[1] . ( ++$cnt % 8 ? " " : "\n" );
        $htm .=
          join( "", "<tr>", map "<td>" . ( $_ ? $_ : "&nbsp;" ), @note ) . "\n";
    }
    $htm .= "</table></body></html>";
    $htm =~ s/([A2-9TJQK])([DCHS])/($1 eq 'T'?10:$1)."<image src=$2.png>"/gse;
    $file =~ s/ /_/g;
    write_file "fc$file.htm", $htm;
    $logger->info( $std, $log ) if $show_all;
    $logger->info( stats() ) if $log_stats;
}

sub std_notation {
    map {
        my ( $src_col, $src_row, $dst_col, $dst_row ) = @$_;
        push @$_,
          (   $src_row > 0 ? $src_col + 1
            : $src_col > 3 ? "h"
            :                qw(a b c d) [$src_col] )
          . ( $dst_row > -1 ? $dst_col + 1
            : $dst_col > 3 ? "h"
            :                qw(a b c d) [$dst_col] );
    } @{ $_[0] };
}

sub analyze
{    # move to empty column always moves max cards - potential problem !
    my @recs = split /\s+/, read_file $fcgsfile;
    ( $game_no = shift @recs ) =~ s/#//;
    die "Invalid std notation: # + gameno" unless $game_no =~ /^\d+$/;
    map { die "Invalid std notation: [1-8abcdh]{2}" unless /[1-8abcdh]{2}/ }
      @recs;
    my $tableau = Freecell::App::Tableau->new()->from_deal($game_no);
    my ( $key, $token ) = $tableau->to_token();
    my $score = $tableau->heuristic();
    $stats{$depth}{ $score->[0] }[0]++;
    $position->{$key} = [ 0, $token, [], $score, 0 ];

    foreach my $note (@recs) {
        my $list = search($tableau);
        map { std_notation($_) } @{$list};
        my @move = grep $_->[0][5] eq $note, @{$list};
        map $tableau->play($_), @{ $move[-1] };
        $depth++;
    }
}

sub backtrack {
    my $key = shift;
    my $tableau;
    while (1) {
        my ( $depth, $token, $move ) = @{ $position->{$key} };
        last unless $depth;
        $tableau = Freecell::App::Tableau->new()->from_token( $key, $token );
        $tableau->undo($move);
        ( $key, $token ) = $tableau->to_token();
        my @score = @{ $position->{$key}[3] };
        my @node = $tableau->notation($move);
        push @solution,
          join( "\t", $tableau->to_string, @score, $depth, @node );
    }
}

sub search {
    my $tableau  = shift;
    my $nodelist = $tableau->generate_nodelist();
    if ( @$nodelist > 0 ) {
        foreach my $node (@$nodelist) {
            foreach my $move (@$node) {
                $tableau->play($move);
            }
            $tableau->autoplay($node);    # append autoplay to node
            my ( $key, $token ) = $tableau->to_token();
            if ( !exists( $position->{$key} ) ) {
                $cnt++;
                my $score = $tableau->heuristic();
                $stats{ $depth + 1 }{ $score->[0] }[0]++;
                $position->{$key} = [ $depth + 1, $token, $node, $score, 0 ];
                my $state = join "", map Freecell::App::Tableau::rank( $_->[0] ),
                  @$tableau;
                if ( "000013131313" eq $state ) {
                    backtrack($key);
                    out( $game_no, $max_nodes, reverse @solution );
                    $found = 1;
                }
            }
            $dup++;
            $tot++;
            $tableau->undo($node);
            if ($found) { last }
            if ($QUIT_NOW) { $max_depth = $depth; last }
        }
    }
    $nodelist;
}

sub solve {

    #617 with 4 moves left (Xp invalid!)
    my $input = <<eof;
KS 7C 9S 6S 5D 4C 5H 4S
7D 9C 5C KC 5S 8C KH 7S
TD    QD QH 6D 8H QC
TH    JC JS    8D JD
KD             7H TC
QS             6H 9D
JH             6C 8S
TS
9H
eof

    my $tableau = ( $game_no == -1 )
      ? Freecell::App::Tableau->new()->from_string($input)
      : Freecell::App::Tableau->new()->from_deal($game_no);

    my ( $key, $token ) = $tableau->to_token();
    my $score = $tableau->heuristic();
    undef %stats;
    $stats{$depth}{ $score->[0] }[0]++;
    undef $position;
    $position->{$key} = [ $depth, $token, [], $score, 0 ];
    undef @solution;

    $logger->info();
    $logger->info( ". . .Starting --gameno $game_no --maxnodes $max_nodes ",
        Freecell::App::Tableau->winxp_opt() ? "--winxp" : "--nowinxp" );
    $logger->info();

    while ( $depth < $max_depth && !$found ) {
        ( $cnt, $dup ) = (0) x 2;

        # splice top maxnodes positions

        my @s = sort { $position->{$a}[3][0] <=> $position->{$b}[3][0] }
          grep { $depth == $position->{$_}[0] } keys %$position;
        my $level_cnt = scalar @s;
        my $mid_index = min( $max_nodes, $level_cnt ) - 1;
        my @mid_score;
        $mid_score[0] = $position->{ $s[$mid_index] }[3][0];
        @s = sort { $position->{$a}[3][1] <=> $position->{$b}[3][1] } @s;
        $mid_score[1] = $position->{ $s[$mid_index] }[3][1];

        #print Dumper \@mid_score;
        my $lo_score = $position->{ $s[0] }[3][0];
        my $hi_score = $position->{ $s[-1] }[3][0];

        # mark all kept positions

        my @stack;
        foreach (@s) {
            my $k         = $_;
            my $pos_score = $position->{$k}[3];
            if (   $pos_score->[0] > $mid_score[0]
                && $pos_score->[1] > $mid_score[1] )
            {
                next;
            }
            push @stack, [ $k, $position->{$k}[1] ];
            while (1) {
                my ( $d, $t, $m, $s, $l ) = @{ $position->{$k} };
                if ( $depth == $l ) { last }
                $position->{$k}[4] = $depth;
                if ( $depth == 0 ) { last }
                my $tableau = Freecell::App::Tableau->new()->from_token( $k, $t );
                $tableau->undo($m);
                ( $k, $t ) = $tableau->to_token();
            }
        }

        # delete all unmarked positions

        foreach my $k ( keys %$position ) {
            unless ( $position->{$k}[4] == $depth ) {
                delete $position->{$k};
            }
        }

        # search for new positions

        foreach (@stack) {
            $tableau = Freecell::App::Tableau->new()->from_token(@$_);
            search($tableau);
        }
        my $log =
          sprintf
          "d=%3d, s=%3d -%3d -%3d, l=%7d (%3d%%), cnt=%9d (%3d%%), p=%7d",
          $depth, $lo_score, $mid_score[0], $hi_score, $level_cnt,
          int( 100 * @stack / $level_cnt ), $dup,
          int( 100 * $cnt / ( $dup || 1 ) ), scalar( keys %$position );
        $logger->info($log);
        $depth++;
    }
}

sub run {
    getopts();
    initlog();

    if ($fcgsfile) {
        $max_nodes = 0;
        $show_all  = 1;
        analyze($fcgsfile);
    }
    else {
        solve();
    }
    unless ($QUIT_NOW){
        $logger->info( sprintf "%-41s tot=%9d", 
            Freecell::App::Tableau->winxp_warn() ? ". . .Game solution not valid for XP!" : "", $tot )
    }
}
run() unless caller;

__END__

=head1 NAME

Freecell::App - A simple Freecell solver.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Please run the script C<freecell-solver> to call this module.

=head1 EXPORT

none.

=head1 SUBROUTINES/METHODS

=head2 solve()

The solver is a breadth-first search using an A* heuristic to score
the tableau so that the number of positions on the stack can be trimmed
to the maxnodes by their score. This is necessary to prevent out_of_memory.

=over 4

=item * First, pick all the positions for the current depth and sort by their score.
        Pick the mid_score at position maxnodes or last if not at maxnodes yet.

=item * Second, push onto the stack all those positions up to mid_score.

=item * Third, now using each position in the stack, backtrack to the initial position
        marking the level attribute with the current depth.

=item * Forth, delete all entries in the position hash where level is not equal current to 
        depth

=item * Fifth, using the stack, search for all the new positions.

=back

=head2 search()

Call C<generate_nodelist()> then C<play()> each node and append the C<autoplay()> moves.
Store the new Tableau in the position hash if it is not a duplicate. The key for
the position hash is create by C<to_token()> and the fields stored in the position
hash are C<[ depth, token, node, score, 0> (place holder for level used later during trim) C<]>
If one of the new positons solve the hand, then call C<backtrack()> to build the
solution array and then call C<out()> to write the html. Set found to true.

=head2 backtrack($key)

This takes the final key and calls C<undo()> until the initial position is reached
and pushes each node onto the solutions array.

=head2 out(@solution)

Writes the html solution to disk.

=head3 private

=over 4

=item * analyze

=item * getopts

=item * initlog

=item * run

=item * stats

=item * std_notation

=item * usage_quit

=back

=head1 AUTHOR

Shirl Hart, C<< <shirha at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-freecell-app at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Freecell-App>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Freecell::App


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Freecell-App>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Freecell-App>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Freecell-App>

=item * Search CPAN

L<http://search.cpan.org/dist/Freecell-App/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Shirl Hart.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=begin Analyze

input file sn#4003.txt

#4003
3a 37 35 2b 13 21 2c 78 7h 2d
25 27 d7 37 c2 52 52 82 45 34
34 35 53 13 15 14 1c 51 41 61
53 8h 45 4d 45 75 7a 86 8c


perl freecell-solver --analyze sn#4003.txt --showall --logstats

=end Analyze

=cut

1; # End of Freecell::App
