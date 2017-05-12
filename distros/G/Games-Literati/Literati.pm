package Games::Literati;
use warnings;
use strict;
use Carp;

use 5.006;
require Exporter;

our @ISA            = qw(Exporter);
our @EXPORT_GAMES   = qw(scrabble superscrabble literati wordswithfriends);
our @EXPORT_CONFIG  = qw($WordFile $MinimumWordLength);
our @EXPORT_OTHER   = qw(find %valid);
our @EXPORT_INFO    = qw(n_rows n_cols numTilesPerHand);
our @EXPORT_CUSTOMIZER  = (@EXPORT_INFO, 'var_init');
our @EXPORT_OK      = (@EXPORT_GAMES, @EXPORT_CONFIG, @EXPORT_OTHER, @EXPORT_INFO, @EXPORT_CUSTOMIZER);
our %EXPORT_TAGS    = (
    'allGames'      => [@EXPORT_GAMES],
    'configGame'    => [@EXPORT_CONFIG],
    'infoFunctions' => [@EXPORT_INFO],
    'customizer'    => [@EXPORT_CUSTOMIZER],
    'all'           => [@EXPORT_OK],
);  # v0.032007: add the tags

our $VERSION = 0.040;
our %valid = ();
our @bonus;
our @onboard;
our %values;
our %solutions;
our $words;
our $bingo_bonus;
our @wilds;
our $WordFile = './wordlist';
our $GameName = '';
our $BoardCols = 15;    # v0.032001
our $BoardRows = 15;    # v0.032001
our $MinimumWordLength = 2; # v0.032003
our $BingoHandLength = 7;   # v0.032005

sub scrabble {
    var_init(15,15,7);
    _scrabble_init();
    display();
    search(shift, shift);
}

sub superscrabble {     # v0.032002
    var_init(21,21,7);
    _superscrabble_init();
    display();
    search(shift, shift);
}

sub literati {
    var_init(15,15,7);
    _literati_init();
    display();
    search(shift, shift);
}

sub wordswithfriends {
    var_init(15,15,7);
    _wordswithfriends_init();
    display();
    search(shift, shift);
}

sub set_rows($) { $BoardRows = shift if defined $_[0]; }
sub set_cols($) { $BoardCols = shift if defined $_[0]; }
sub n_cols() { return $BoardCols; }
sub n_rows() { return $BoardRows; }
sub _max_col() { return $BoardCols-1; }
sub _max_row() { return $BoardRows-1; }
sub _center_col() { return _max_col()/2; }  # v0.032003
sub _center_row() { return _max_row()/2; }  # v0.032003
sub numTilesPerHand() { return $BingoHandLength; }   # v0.032005

sub var_init {
    set_rows($_[0]) if (defined $_[0]);
    set_cols($_[1]) if (defined $_[1]);
    croak "INVALID rows=$BoardRows, cols=$BoardCols:\n\tFor now, must be an odd square board, such as 15x15 or 17x17, not 16x16 or 15x17.\n"  unless ($BoardRows==$BoardCols) && ($BoardRows % 2 == 1);   # v0.032003 this restriction prevents difficult calcs for the center square
    $BingoHandLength = ($_[2])  if (defined $_[2]);

    %values = ();
    undef $words;
    undef @bonus;
    undef %solutions;   # v0.032002 = prevents accidentally combining solution sets from multiple games

    foreach my $r (0.._max_row) {
        foreach my $c (0.._max_col) {
            undef $bonus[$r][$c];
        }
    }

    print "Hashing words...\n";
    my $fh;
    open( $fh, $WordFile ) || croak "Cannot open words file \"$WordFile\"\n\t$!";
    while (<$fh>) {
        chomp;
        next if length($_) < $MinimumWordLength;    # ignore short words (v0.032003)
        $valid{$_} = 1;
        push @{$words->[length $_]}, $_;
    }
    close $fh;
}

sub check {
    my @wordlist    = @{ pop @_ };
    for my $w (@wordlist) {
        if ($valid{$w} == 1) {
            print qq|"$w" is valid.\n|;
        }
        else {
            print qq|"$w" is invalid.\n|;
        }
    }
}

sub find {
    no warnings;
    my $args     = shift;
    my $letters  = $args->{letters};
    my $re       = $args->{re} || "//";
    my $internal = $args->{internal} || 0;
    my $len;
    my $hint;
    my $check_letters;
    my @results;
    my ($min_len, $max_len) = (split ",", $args->{len});
    $min_len ||= 2;
    $max_len ||= 7;

    croak "Not enough letters.\n" unless (length($letters) > 1);


    LINE: for (keys %valid) {
        $len = length $_;
        next LINE if ($len > $max_len || $len < $min_len);
        $check_letters = $letters;

        next LINE unless (eval $re);
        $hint = "";

        for my $l (split //, $_) {
            next LINE unless ( $check_letters =~ s/$l// or
                               ($check_letters =~ s/\?// and $hint .= "($l)") );
        }
        unless ($internal) {
            print "$_ $hint\n";
        }
        else {
            push @results, $_;
        }

    }
    return \@results if $internal;
}

sub _find {
    my $letters  = shift;
    my $len      = shift;
    my $re       = shift;
    my $check_letters;
    my @results;
    my @v;

  LINE: for (@{$words->[$len]}) {
      $check_letters = $letters;

      next LINE unless /^$re$/;

      @v = ();
      for my $l (split //, $_) {
            next LINE unless ( ( $check_letters =~ s/$l// and push @v, $values{$l} ) or
                               ( $check_letters =~ s/\?// and push @v, 0 ) );
        }


        push @results, { "trying" => $_, "values" => [ @v ] };
    }
    return \@results;
}

sub display {
    my $f = shift;
    my ($t, $r, $c) = @_;

    print "\nBoard:\n";
    for my $row (0.._max_row) {
        print sprintf "%02d ", $row if $f;
        for my $col (0.._max_col) {
            $onboard[$row][$col] ||= '.';
            print $onboard[$row][$col];
        }
        print "\n";
    }
    print "\n";

}

# 0.02: separate input() from search(), to make it easier to override the input() function (for example, with possible future Games::Literati::WebInterface)
sub input {
    my $input = "";

  INPUT:
    while(1) {
        for my $row (0.._max_row) {
            print "row $row:\n";
            $input = <STDIN>;
            chomp $input;
            if (length($input) > n_cols) {
                printf "over board: %d columns is more than %d\n", length($input), n_cols;
                next INPUT;
            }
            $onboard[$row]=[split //, $input];
        }
        print "---------$GameName----------\n";
        display();

        $input = "";
        while( $input !~ /^(yes|no)$/ ) {
            print "Is the above correct?\n";
            $input = <STDIN>;
            chomp $input;
        }

        last INPUT if $input =~ /^yes$/;
    }

  WILD:
    while(1) {
        print "wild tiles are at:[Row1,Col1 Row2,Col2 ...]\n";
        $input = <STDIN>;
        chomp $input;

        @wilds = ();
        last WILD unless $input;
        my @w = (split /\s/, $input);
        for (@w) {
            my ($r, $c) = split (/,/, $_);
            unless (defined $onboard[$r][$c] && $onboard[$r][$c] ne '.') {
                print "Invalid wild tile positions, please re-enter.\n";
                next WILD;
            }
            $wilds[$r][$c] = 1;
        }
        last WILD;
    }

  TILES:
    while(1) {
        print "Enter tiles:\n";
        $input = <STDIN>;
        chomp $input;
        last TILES unless length($input) > $BingoHandLength;
    }
    return lc $input;  # v0.032006 = convert to lower case
}

sub search {
    my $use_min = shift;
    my $use     = shift;
    my $input;
    my $best = 0;

    $input = input();

    print "\nLooking for solutions for $input(in X axis)...\n";
    display();
    _mathwork($input, "x", $use_min, $use);
    _rotate_board();

    print "\nLooking for solutions for $input(in Y axis)...\n";
    _mathwork($input, "y", $use_min, $use);
    _rotate_board();

    my @args;
    for my $key (sort { ($solutions{$b} <=> $solutions{$a}) || ($a cmp $b) } keys %solutions) { # sort by score, then alphabetically by solution
        last if ++$best > 10;

        print "Possible Top Ten Solution $best: $key, score $solutions{$key}\n";

    }

}

sub _mathwork {
    no warnings;
    $|=1;
    my %found;
    my $letters = shift;
    my @letters = split //, $letters;
    my $rotate  = ($_[0] eq "y");
    my $use_min = $_[1] || 1;
    my $use     = $_[2] || scalar @letters;
    my $go_on   = 0;
    my $actual_letters;
    my $solution;

    while ($use >= $use_min) {
        print "using $use tiles:\n";

        for my $row (0.._max_row) {
            for my $col (0..n_rows-$use) {
                next if $onboard[$row][$col] ne '.';    # skip populated tiles
                $go_on = 0;
                $actual_letters = $letters;
                my @thisrow = @{$onboard[$row]};

                my $count   = $use;
                my $column  = $col;

                # make sure that number of letters (count=use) will fit on the board
                while ($count) {
                    if ($column > _max_col) {$go_on = 0; last};

                    unless ($go_on) {
                        if (
                            ($onboard[$row][$col] ne '.')   ||
                            ($column > 0         && $onboard[$row][$column-1] ne '.')  ||
                            ($column < _max_col  && $onboard[$row][$column+1] ne '.')  ||
                            ($row > 0            && $onboard[$row-1][$column] ne '.')  ||
                            ($row < _max_row     && $onboard[$row+1][$column] ne '.')  ||
                            ($row == _center_row && $column == _center_col)
                        ) {
                            $go_on = 1;
                        }
                    }
                    if ( $thisrow[$column] eq '.' ) {
                        $thisrow[$column] = '/';            # use slash to indicate a letter we want to use
                        $count --;
                    }
                    $column ++;
                } # $count down to 0
                next if $column > n_cols;  # next starting-col if this column has extended beyond the board
                next unless $go_on == 1;    # next starting-col if we determined that we should stop this attempt

                # if we made it here, there's enough room for a word of length==$use;
                # we have a string that's comprised of
                #   . dots indicating empty spots on the board
                #   / slashes indicating empty spots that we will fill with our new tiles
                #   t letters indicating the letter that's already in that space
                my $str = "";
                my $record;
                map { $str .= $_ } @thisrow;    # aka $str = join('',@thisrow);

                # split into pieces of the row: each piece is surrounded by empties
                #   look for the piece that includes the contiguous slashes and letters
                for (split (/\./, $str)) {
                    next unless /\//;           # if this piece of the row isn't part of our new word, skip it
                    $record = $str = $_;
                    ~s/\//./g;
                    $str =~ s/\///g;
                    $actual_letters .= $str;

                    my $length  = length $_;

                    # look for real words based on the list of 'actual letters', which combines
                    #   the tiles in your hand with those letters already in this row.
                    # also grab the point values of each of the tiles in the word
                    unless (defined $found{"$actual_letters,$_"}) {
                        $found{"$actual_letters,$_"} = _find($actual_letters, $length, $_);
                    }

                    for my $tryin (@{$found{"$actual_letters,$_"}}) {

                        my @values = @{ $tryin->{values} };
                        my $index  = index ($record, "/");      # where the first tile I'm trying is located
                        my $fail   = 0;
                        my $replace;
                        my $score  = 0;
                        my $v      = 0;
                        my $trying = $tryin->{trying};

                        # cycle thru each of the the crossing-words (vertical words that intersect the horizontal word I'm laying down)
                        for my $c ($col..$col + $length - 1 - $index) {
                            $str = '';

                            # build up the full column-string one character at a time (vertical slice of the board)
                            # this will allow us to check for words that cross with our attempted word
                            for my $r (0.._max_row) {
                                if ($r == $row) {       # if it's the current row, use the replacement character rather than the '.' that's in the real board
                                    $str    .= substr ($record, $index, 1);
                                    $replace = substr ($trying, $index, 1);     # this is the character from $trying that is taking the place of the slash for this column
                                    $v       = $values[$index++];
                                }
                                else {                  # otherwise use the character from the real board
                                    $str .= $onboard[$r][$c];
                                }
                            } # r row loop

                            # find the sub-word of the column-string that is bounded by the array ends or a . on one side or another, and look for the
                            #   subword that contains the / (ie, the row where I'm laying down the new tiles
                            for (split /\./, $str) {
                                next unless /\//;                       # if this sub-word doesn't contain the new-tile row, continue
                                next if (length($_) == 1);              # if this sub-word contains the new-tile row, but is only one character long, don't score the crossing-word for this column
                                # if it makes it here, I actually found that I'm making a vertical word when I lay down my horizontal tiles, so start scoring
                                my $t_score = 0;                        # "t" means temporary; in this block, t_score holds the score for the tiles already laid down in the vertical word
                                my $vstart = $row - index($_, "/");     # the current vertical word ($_) starts at the board's row=$vstart

                                # loop thru the already existing tiles in the crossing-word; add in their non-bonus score if they are not wild
                                #   (non-bonus, because they were laid down in a previous turn, so their bonus has been used up)
                                while (/(\w)/g) {
                                    # BUGFIX (pcj): use vrow as the row of the current letter of the vertical word
                                    #   if it's a wild, 0 points, else add its non-bonus value
                                    my $vrow = $vstart + pos() - 1;    # vstart is the start of the vertical word; pos is the 1-based position in the vertical word; -1 adjusts for the 1-based to get the row of the current \w character $1
                                    my ($wr,$wc) = ($rotate) ? ($vrow, $c) : ($c, $vrow);  # swap row and column for wilds[][] array, since wilds[][] wasn't transposed.

                                    unless ( $wilds[$vrow][$c] ) {
                                        $t_score += $values{$1};
                                    }


                                }; # end of vertical-word's real-letter score
                                s/\//$replace/;

                                # if my vertical cross-word for this column is a valid word, continue scoring by adding the score for the new tile in this column,
                                #   including bonuses activated by the new tile
                                if ($valid{$_}) {
                                    if ($bonus[$row][$c] eq "TL") {
                                        $score += $t_score + $v * 3;
                                    }
                                    elsif ($bonus[$row][$c] eq "DL") {
                                        $score += $t_score + $v * 2;
                                    }
                                    elsif ($bonus[$row][$c] eq "DW") {
                                        $score += ($t_score + $v) * 2;
                                    }
                                    elsif ($bonus[$row][$c] eq "TW") {
                                        $score += ($t_score + $v) * 3;
                                    }
                                    elsif ($bonus[$row][$c] =~ /^(\d+)L$/) { # v0.032002
                                        $score += $t_score + $v * $1;
                                    }
                                    elsif ($bonus[$row][$c] =~ /^(\d+)W$/) { # v0.032002
                                        $score += ($t_score + $v) * $1;
                                    }
                                    else {
                                        $score += $t_score + $v;
                                    }
                                } # end if valid
                                else {  # else invalid
                                    $fail = 1;      # fail indicates it's not a valid word
                                } # end else invalid
                            } # for split
                            last if $fail;          # since (at least) one of the verticals isn't a valid word, the whole horizontal placement is bad, so we can stop trying more columns
                                                    # future: might replace the $fail flag with named loops, so the else { $fail=1 } above would become else { last FOR_MY_C; }

                        } # $c
                        next if $fail;              # next tryin

                        my $col_index = 0 - index ($record, "/");
                        my $t_score = 0;            # different lexical scope; this temp score is the score for just the new horizontal word; it will be added to the existing $score above after all bonuses are applied
                        my $t_flag  = '';
                        my $cc = 0;

                        # this is the scoring for the word I just laid down
                        for (split //, $trying) {
                            if ($onboard[$row][$col+$col_index] eq '.') {           # if new tile
                                if ($bonus[$row][$col+$col_index] eq "TL") {
                                    $t_score += $values[$cc] * 3;
                                }
                                elsif ($bonus[$row][$col+$col_index] eq "DL") {
                                    $t_score += $values[$cc] * 2;
                                }
                                elsif ($bonus[$row][$col+$col_index] =~ /^(\d+)L$/) { # v0.032002
                                    $t_score += $values[$cc] * $1;  # multiply tile by the number that prefixes the L
                                }
                                elsif ($bonus[$row][$col+$col_index] eq "DW") {
                                    $t_score += $values[$cc];
                                    $t_flag .=  "*2";
                                }
                                elsif ($bonus[$row][$col+$col_index] eq "TW") {
                                    $t_score += $values[$cc];
                                    $t_flag .=  "*3";
                                }
                                elsif ($bonus[$row][$col+$col_index] =~ /^(\d+)W$/) { # v0.032002
                                    $t_score += $values[$cc];
                                    $t_flag .=  "*$1";  # multiply word by the number that prefixes the W
                                }
                                else {
                                    $t_score += $values[$cc];
                                }
                            } # end if new tile
                            else { # else tile already there
                                my ($wr, $wc) = ($row, $col + $col_index);
                                ($wc, $wr) = ($wr, $wc) if $rotate; # swap row and column for wilds[][] array, since wilds[][] wasn't transposed.
                                unless ($wilds[$wr][$wc]) {
                                    $t_score += $values{$_};
                                }
                            } # end else already a tile there
                            $cc ++;
                            $col_index ++;
                        } # foreach split trying

                        $score += eval "$t_score$t_flag";                   # add in the bonus-enabled horizontal score to the pre-calculated veritcal scores
                                                                            # POSSIBLY CLEARER: if $t_flag is just changed to $word_multiplier with an integer value starting at 1,
                                                                            #   then this could be $t_score * $word_multiplier;
                        $score += $bingo_bonus if $use == $BingoHandLength; # add in bingo-bonus if all tiles used (v0.032005: configurable)

                        $solution = ($rotate?"column" : "row") .
                            " $row become: '$trying' starting at " .
                            ($rotate?"row" : "column") .
                            " $col " .
                            ($use == $BingoHandLength ? "(BINGO!!!!)" : "");  # v0.032005 = configurable

                        print "($score)\t$solution\n";
                        $solutions{"$solution using $use tile(s)"} = $score;

                    } # end for my tryin
                } # end for split

            } # end col
        } # end row
        $use --;
    } # end use

}


sub _rotate_board {

    for my $row (0..(_max_row-1))  {
        for my $col ($row+1.._max_col) {
            ($onboard[$col][$row], $onboard[$row][$col]) = ($onboard[$row][$col], $onboard[$col][$row]);
        }
    }
    ($BoardRows, $BoardCols) = ($BoardCols, $BoardRows);
}

sub _init {
    _scrabble_init();
}

sub set_bonus_4quad {   # v0.032009
    # _set_bonus_4quad(r,c,b) will set the bonus array based on the row, column, and bonus text supplied
    #   it puts them in the four quadrants (r,c), (#-r,c), (r,#-c), (#-r,#-c) to keep a perfectly-balanced
    #   board
    my $ra = shift || 0;
    my $ca = shift || 0;
    my $b  = shift || '';

    my $rb = _max_row - $ra;
    my $cb = _max_col - $ca;

    $bonus[$ra][$ca] = $b;
    $bonus[$rb][$ca] = $b;
    $bonus[$ra][$cb] = $b;
    $bonus[$rb][$cb] = $b;

    return $b;
}

sub _scrabble_init {

    $GameName = "Scrabble";
    ##########################################################################
    # Scrabble                                                               #
    ##########################################################################
    #      0   1   2   3   4   5   6   7   8   9   10  11  12  13  14        #
    # 0   [TW][__][__][DL][__][__][__][TW][__][__][__][DL][__][__][TW] # 0   #
    # 1   [__][DW][__][__][__][TL][__][__][__][TL][__][__][__][DW][__] # 1   #
    # 2   [__][__][DW][__][__][__][DL][__][DL][__][__][__][DW][__][__] # 2   #
    # 3   [DL][__][__][DW][__][__][__][DL][__][__][__][DW][__][__][DL] # 3   #
    # 4   [__][__][__][__][DW][__][__][__][__][__][DW][__][__][__][__] # 4   #
    # 5   [__][TL][__][__][__][TL][__][__][__][TL][__][__][__][TL][__] # 5   #
    # 6   [__][__][DL][__][__][__][DL][__][DL][__][__][__][DL][__][__] # 6   #
    # 7   [TW][__][__][DL][__][__][__][DW][__][__][__][DL][__][__][TW] # 7   #
    # 8   [__][__][DL][__][__][__][DL][__][DL][__][__][__][DL][__][__] # 8   #
    # 9   [__][TL][__][__][__][TL][__][__][__][TL][__][__][__][TL][__] # 9   #
    # 10  [__][__][__][__][DW][__][__][__][__][__][DW][__][__][__][__] # 10  #
    # 11  [DL][__][__][DW][__][__][__][DL][__][__][__][DW][__][__][DL] # 11  #
    # 12  [__][__][DW][__][__][__][DL][__][DL][__][__][__][DW][__][__] # 12  #
    # 13  [__][DW][__][__][__][TL][__][__][__][TL][__][__][__][DW][__] # 13  #
    # 14  [TW][__][__][DL][__][__][__][TW][__][__][__][DL][__][__][TW] # 14  #
    #      0   1   2   3   4   5   6   7   8   9   10  11  12  13  14        #
    ##########################################################################

    set_bonus_4quad(0,0,'TW');
    set_bonus_4quad(0,7,'TW');  # middle column
    set_bonus_4quad(7,0,'TW');  # middle row

    set_bonus_4quad(1,1,'DW');
    set_bonus_4quad(2,2,'DW');
    set_bonus_4quad(3,3,'DW');
    set_bonus_4quad(4,4,'DW');
    set_bonus_4quad(7,7,'DW');  #center

    set_bonus_4quad(0,3,'DL');
    set_bonus_4quad(2,6,'DL');
    set_bonus_4quad(3,0,'DL');
    set_bonus_4quad(3,7,'DL');
    set_bonus_4quad(6,2,'DL');
    set_bonus_4quad(6,6,'DL');
    set_bonus_4quad(7,3,'DL');  #middle row

    set_bonus_4quad(1,5,'TL');
    set_bonus_4quad(5,1,'TL');
    set_bonus_4quad(5,5,'TL');

    for my $row (0.._max_row) {
        for my $col (0.._max_col) {
            $onboard[$row][$col] = '.';
        }
    }

    %values = (
        a=>1,
        b=>3,
        c=>3,
        d=>2,
        e=>1,
        f=>4,
        g=>2,
        h=>4,
        i=>1,
        j=>8,
        k=>5,
        l=>1,
        m=>3,
        n=>1,
        o=>1,
        p=>3,
        q=>10,
        r=>1,
        s=>1,
        t=>1,
        u=>1,
        v=>4,
        w=>4,
        x=>8,
        y=>4,
        z=>10
               );
    $bingo_bonus = 50;
}

sub _superscrabble_init {       # v0.032002

    $GameName = "SuperScrabble";

    ##################################################################################################
    # SuperScrabble                                                                                  #
    ##################################################################################################
    #      0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16  17  18  19  20        #
    # 0   [4W][__][__][2L][__][__][__][3W][__][__][2L][__][__][3W][__][__][__][2L][__][__][4W] # 0   #
    # 1   [__][2W][__][__][3L][__][__][__][2W][__][__][__][2W][__][__][__][3L][__][__][2W][__] # 1   #
    # 2   [__][__][2W][__][__][4L][__][__][__][2W][__][2W][__][__][__][4L][__][__][2W][__][__] # 2   #
    # 3   [2L][__][__][3W][__][__][2L][__][__][__][3W][__][__][__][2L][__][__][3W][__][__][2L] # 3   #
    # 4   [__][3L][__][__][2W][__][__][__][3L][__][__][__][3L][__][__][__][2W][__][__][3L][__] # 4   #
    # 5   [__][__][4L][__][__][2W][__][__][__][2L][__][2L][__][__][__][2W][__][__][4L][__][__] # 5   #
    # 6   [__][__][__][2L][__][__][2W][__][__][__][2L][__][__][__][2W][__][__][2L][__][__][__] # 6   #
    # 7   [3W][__][__][__][__][__][__][2W][__][__][__][__][__][2W][__][__][__][__][__][__][3W] # 7   #
    # 8   [__][2W][__][__][3L][__][__][__][3L][__][__][__][3L][__][__][__][3L][__][__][2W][__] # 8   #
    # 9   [__][__][2W][__][__][2L][__][__][__][2L][__][2L][__][__][__][2L][__][__][2W][__][__] # 9   #
    # 10  [2L][__][__][3W][__][__][2L][__][__][__][2W][__][__][__][2L][__][__][3W][__][__][2L] # 10  #
    # 11  [__][__][2W][__][__][2L][__][__][__][2L][__][2L][__][__][__][2L][__][__][2W][__][__] # 11  #
    # 12  [__][2W][__][__][3L][__][__][__][3L][__][__][__][3L][__][__][__][3L][__][__][2W][__] # 12  #
    # 13  [3W][__][__][__][__][__][__][2W][__][__][__][__][__][2W][__][__][__][__][__][__][3W] # 13  #
    # 14  [__][__][__][2L][__][__][2W][__][__][__][2L][__][__][__][2W][__][__][2L][__][__][__] # 14  #
    # 15  [__][__][4L][__][__][2W][__][__][__][2L][__][2L][__][__][__][2W][__][__][4L][__][__] # 15  #
    # 16  [__][3L][__][__][2W][__][__][__][3L][__][__][__][3L][__][__][__][2W][__][__][3L][__] # 16  #
    # 17  [2L][__][__][3W][__][__][2L][__][__][__][3W][__][__][__][2L][__][__][3W][__][__][2L] # 17  #
    # 18  [__][__][2W][__][__][4L][__][__][__][2W][__][2W][__][__][__][4L][__][__][2W][__][__] # 18  #
    # 19  [__][2W][__][__][3L][__][__][__][2W][__][__][__][2W][__][__][__][3L][__][__][2W][__] # 19  #
    # 20  [4W][__][__][2L][__][__][__][3W][__][__][2L][__][__][3W][__][__][__][2L][__][__][4W] # 20  #
    #      0   1   2   3   4   5   6   7   8   9   10  11  12  13  14  15  16  17  18  19  20        #
    ##################################################################################################


    set_bonus_4quad( 0, 0,'4W');

    set_bonus_4quad( 0, 7,'3W');
    set_bonus_4quad( 3, 3,'3W');
    set_bonus_4quad( 3,10,'3W');    # middle column
    set_bonus_4quad( 7, 0,'3W');
    set_bonus_4quad(10, 3,'3W');    # middle row

    set_bonus_4quad( 1, 1,'2W');
    set_bonus_4quad( 1, 8,'2W');
    set_bonus_4quad( 2, 2,'2W');
    set_bonus_4quad( 2, 9,'2W');
    set_bonus_4quad( 4, 4,'2W');
    set_bonus_4quad( 5, 5,'2W');
    set_bonus_4quad( 6, 6,'2W');
    set_bonus_4quad( 7, 7,'2W');
    set_bonus_4quad( 8, 1,'2W');
    set_bonus_4quad( 9, 2,'2W');
    set_bonus_4quad(10,10,'2W');    # center

    set_bonus_4quad( 2, 5,'4L');
    set_bonus_4quad( 5, 2,'4L');

    set_bonus_4quad( 1, 4,'3L');
    set_bonus_4quad( 4, 1,'3L');
    set_bonus_4quad( 4, 8,'3L');
    set_bonus_4quad( 8, 4,'3L');
    set_bonus_4quad( 8, 8,'3L');

    set_bonus_4quad( 0, 3,'2L');
    set_bonus_4quad( 0,10,'2L');    # middle column
    set_bonus_4quad( 3, 0,'2L');
    set_bonus_4quad( 3, 6,'2L');
    set_bonus_4quad( 5, 9,'2L');
    set_bonus_4quad( 6, 3,'2L');
    set_bonus_4quad( 6,10,'2L');    # middle column
    set_bonus_4quad( 9, 5,'2L');
    set_bonus_4quad( 9, 9,'2L');
    set_bonus_4quad(10, 0,'2L');    # middle row
    set_bonus_4quad(10, 6,'2L');    # middle row

    for my $row (0.._max_row) {
        for my $col (0.._max_col) {
            $onboard[$row][$col] = '.';
        }
    }

    %values = (
        a=>1,
        b=>3,
        c=>3,
        d=>2,
        e=>1,
        f=>4,
        g=>2,
        h=>4,
        i=>1,
        j=>8,
        k=>5,
        l=>1,
        m=>3,
        n=>1,
        o=>1,
        p=>3,
        q=>10,
        r=>1,
        s=>1,
        t=>1,
        u=>1,
        v=>4,
        w=>4,
        x=>8,
        y=>4,
        z=>10
               );
    $bingo_bonus = 50;
}

sub _literati_init {

    $GameName = "Literati";

    ##########################################################################
    # Literati                                                               #
    ##########################################################################
    #      0   1   2   3   4   5   6   7   8   9   10  11  12  13  14        #
    # 0   [__][__][__][3W][__][__][3L][__][3L][__][__][3W][__][__][__] # 0   #
    # 1   [__][__][2L][__][__][2W][__][__][__][2W][__][__][2L][__][__] # 1   #
    # 2   [__][2L][__][__][2L][__][__][__][__][__][2L][__][__][2L][__] # 2   #
    # 3   [3W][__][__][3L][__][__][__][2W][__][__][__][3L][__][__][3W] # 3   #
    # 4   [__][__][2L][__][__][__][2L][__][2L][__][__][__][2L][__][__] # 4   #
    # 5   [__][2W][__][__][__][3L][__][__][__][3L][__][__][__][2W][__] # 5   #
    # 6   [3L][__][__][__][2L][__][__][__][__][__][2L][__][__][__][3L] # 6   #
    # 7   [__][__][__][2W][__][__][__][__][__][__][__][2W][__][__][__] # 7   #
    # 8   [3L][__][__][__][2L][__][__][__][__][__][2L][__][__][__][3L] # 8   #
    # 9   [__][2W][__][__][__][3L][__][__][__][3L][__][__][__][2W][__] # 9   #
    # 10  [__][__][2L][__][__][__][2L][__][2L][__][__][__][2L][__][__] # 10  #
    # 11  [3W][__][__][3L][__][__][__][2W][__][__][__][3L][__][__][3W] # 11  #
    # 12  [__][2L][__][__][2L][__][__][__][__][__][2L][__][__][2L][__] # 12  #
    # 13  [__][__][2L][__][__][2W][__][__][__][2W][__][__][2L][__][__] # 13  #
    # 14  [__][__][__][3W][__][__][3L][__][3L][__][__][3W][__][__][__] # 14  #
    #      0   1   2   3   4   5   6   7   8   9   10  11  12  13  14        #
    ##########################################################################

    set_bonus_4quad(0,3,'3W');
    set_bonus_4quad(3,0,'3W');

    set_bonus_4quad(1,5,'2W');
    set_bonus_4quad(3,7,'2W');  # middle column
    set_bonus_4quad(5,1,'2W');
    set_bonus_4quad(7,3,'2W');  # middle row

    set_bonus_4quad(0,6,'3L');
    set_bonus_4quad(3,3,'3L');
    set_bonus_4quad(5,5,'3L');
    set_bonus_4quad(6,0,'3L');

    set_bonus_4quad(1,2,'2L');
    set_bonus_4quad(2,1,'2L');
    set_bonus_4quad(2,4,'2L');
    set_bonus_4quad(4,2,'2L');
    set_bonus_4quad(4,6,'2L');
    set_bonus_4quad(6,4,'2L');

    $bingo_bonus   = 35;

    for my $row (0.._max_row) {
        for my $col (0.._max_col) {
            $onboard[$row][$col] = '.';
        }
    }

    %values = (
        a=>1,
        b=>2,
        c=>1,
        d=>1,
        e=>1,
        f=>3,
        g=>1,
        h=>2,
        i=>1,
        j=>5,
        k=>3,
        l=>1,
        m=>1,
        n=>1,
        o=>1,
        p=>2,
        q=>5,
        r=>1,
        s=>1,
        t=>1,
        u=>1,
        v=>4,
        w=>4,
        x=>5,
        y=>3,
        z=>5
    );

}

sub _wordswithfriends_init {

    $GameName = "Words With Friends";

    ##########################################################################
    # Words With Friends                                                     #
    ##########################################################################
    #      0   1   2   3   4   5   6   7   8   9   10  11  12  13  14        #
    # 0   [__][__][__][3W][__][__][3L][__][3L][__][__][3W][__][__][__] # 0   #
    # 1   [__][__][2L][__][__][2W][__][__][__][2W][__][__][2L][__][__] # 1   #
    # 2   [__][2L][__][__][2L][__][__][__][__][__][2L][__][__][2L][__] # 2   #
    # 3   [3W][__][__][3L][__][__][__][2W][__][__][__][3L][__][__][3W] # 3   #
    # 4   [__][__][2L][__][__][__][2L][__][2L][__][__][__][2L][__][__] # 4   #
    # 5   [__][2W][__][__][__][3L][__][__][__][3L][__][__][__][2W][__] # 5   #
    # 6   [3L][__][__][__][2L][__][__][__][__][__][2L][__][__][__][3L] # 6   #
    # 7   [__][__][__][2W][__][__][__][__][__][__][__][2W][__][__][__] # 7   #
    # 8   [3L][__][__][__][2L][__][__][__][__][__][2L][__][__][__][3L] # 8   #
    # 9   [__][2W][__][__][__][3L][__][__][__][3L][__][__][__][2W][__] # 9   #
    # 10  [__][__][2L][__][__][__][2L][__][2L][__][__][__][2L][__][__] # 10  #
    # 11  [3W][__][__][3L][__][__][__][2W][__][__][__][3L][__][__][3W] # 11  #
    # 12  [__][2L][__][__][2L][__][__][__][__][__][2L][__][__][2L][__] # 12  #
    # 13  [__][__][2L][__][__][2W][__][__][__][2W][__][__][2L][__][__] # 13  #
    # 14  [__][__][__][3W][__][__][3L][__][3L][__][__][3W][__][__][__] # 14  #
    #      0   1   2   3   4   5   6   7   8   9   10  11  12  13  14        #
    ##########################################################################

    set_bonus_4quad(0,3,'3W');
    set_bonus_4quad(3,0,'3W');

    set_bonus_4quad(1,5,'2W');
    set_bonus_4quad(3,7,'2W');  # middle column
    set_bonus_4quad(5,1,'2W');
    set_bonus_4quad(7,3,'2W');  # middle row

    set_bonus_4quad(0,6,'3L');
    set_bonus_4quad(3,3,'3L');
    set_bonus_4quad(5,5,'3L');
    set_bonus_4quad(6,0,'3L');

    set_bonus_4quad(1,2,'2L');
    set_bonus_4quad(2,1,'2L');
    set_bonus_4quad(2,4,'2L');
    set_bonus_4quad(4,2,'2L');
    set_bonus_4quad(4,6,'2L');
    set_bonus_4quad(6,4,'2L');

    $bingo_bonus   = 35;

    for my $row (0.._max_row) {
        for my $col (0.._max_col) {
            $onboard[$row][$col] = '.';
        }
    }

    %values = (
        a=>1,
        b=>4,
        c=>4,
        d=>2,
        e=>1,
        f=>4,
        g=>3,
        h=>3,
        i=>1,
        j=>10,
        k=>5,
        l=>2,
        m=>4,
        n=>2,
        o=>1,
        p=>4,
        q=>10,
        r=>1,
        s=>1,
        t=>1,
        u=>2,
        v=>5,
        w=>4,
        x=>8,
        y=>3,
        z=>10
    );

}

sub _text_bonus_board { # v0.032010
    my $str = "";
    my ($row, $col);
    $str .= "    ##" . "#"x4 . "####"x(n_rows) . "#"x8 . "\n";
    $str .= sprintf "    # %-*s #\n", (4*n_rows+10), $GameName;
    $str .= "    ##" . "#"x4 . "####"x(n_rows) . "#"x8 . "\n";
    $str .= sprintf "    # %-4s", '';
    $str .= join '', map { sprintf " %-3d", $_ } @{[0 .. _max_col]};
    $str .= " "x7 . "#\n";
    for $row (0.._max_row) {
        $str .= sprintf "    # %-4d", $row;
        for $col (0.._max_col) {
            $str .= sprintf "[%2s]", $bonus[$row][$col]||'__';
        }
        $str .= sprintf " # %-4d#\n", $row;
    }
    $str .= sprintf "    # %-4s", '';
    $str .= join '', map { sprintf " %-3d", $_ } @{[0 .. _max_col]};
    $str .= " "x7 . "#\n";
    $str .= "    ##" . "#"x4 . "####"x(n_rows) . "#"x8 . "\n";
    return $str;
}

1;


=pod

=head1 NAME

Games::Literati - For word games like Literati (or Scrabble, or Words With Friends), find the best-scoring solution(s) for a board and hand of tiles.

=head1 SYNOPSIS

    use Games::Literati qw/:allGames/;
    literati();
    wordswithfriends();
    scrabble();
    superscrabble();

=head2 Export Tags

=over

=item :allGames => C<literati()>, C<wordswithfriends()>, C<scrabble()>, C<superscrabble()>

=item :configGame => C<$WordFile>, C<$MinimumWordLength>

=item :infoFunctions => C<n_rows()>, C<n_cols()>, C<numTilesPerHand()>

=begin comments

=item :customizer => C<:infoFunctions>, C<var_init()>

=end comments

=back

=head1 DESCRIPTION

B<Games::Literati> helps you find out I<all> solutions for a given
board and tiles.  It can be used to play
L<Scrabble|https://en.wikipedia.org/wiki/Scrabble> (the original 15x15 grid),
L<Super Scrabble|https://en.wikipedia.org/wiki/Super_Scrabble> (the official 21x21 extended grid),
L<Literati|http://internetgames.about.com/library/weekly/aa120802a.htm> (an old Yahoo! Games 15x15 grid, from which B<Games::Literati> derives its name), and
L<Words With Friends|https://www.zynga.com/games/words-friends> (a newer 15x15 grid).
By overriding or extending the package, one could implement other similar letter-tile grids,
with customizable bonus placements.

To use this module to play the games, a one-liner such as the
following can be used:

        perl -MGames::Literati=literati -e "literati();"

Enter the data prompted then the best 10 solutions will be displayed.

=head2 Board Input

The game will prompt you for each row of the board, one row at a time

    row 0:
    row 1:
    ...
    row 14:

And will expect you to enter the requested row's data.  It expects one
character for each column on the board.  Thus, on a standard 15x15 board,
it will expect each row to contain 15 characters.  The `C<.>' character
represents an empty square.  Individual letters (in lower case) represent
tiles that have already been laid on the board.  (Don't worry about
indicating wild tiles just yet; that will come momentarily.)  An example
input row could be:

    .......s.header

After requesting the last row, the B<Games::Literati> will display the
board as it received it, and ask you

    Is the above correct?

At this point, it is expecting you to type either `C<yes>' or `C<no>'.
If you answer `C<yes>', the game will progress.  If you answer `C<no>',
it will start over asking for C<row 0:>.  If you answer with anything
else, it will ask you again if everything is correct.

Once you have entered `C<yes>', B<Games::Literati> will ask you for
the coordinates of the any wild tiles already on the board

    wild tiles are at:[Row1,Col1 Row2,Col2 ...]

C<Row#> and C<Col#> are 0-referenced, so the upper left of the board
is C<0,0>, and the lowe right of the standard board is C<14,14>.
Multiple wild tiles are space-separated.  If there have not been any
wild tiled played yet, just hit C<ENTER>, giving it an empty input.
If you have wilds, with one at one-tile diagonally from the upper right
and the second two tiles diagonally from the lower-left, you would
enter

    1,13 12,2

If your coordinates resolve to an empty tile (C<.>) or a tile that's
not on the board, you will be notified:

    Invalid wild tile positions, please re-enter.
    wild tiles are at:[Row1,Col1 Row2,Col2 ...]

Finally, after receiving a valid input for the wilds, B<Games::Literati>
will ask you for what tiles are in your hand.

    Enter tiles:

You should enter anywhere from 1 to 7 tiles (for a standard game).
Letter tiles should be in lower case; wild tiles are indicated by a
question mark `C<?>'.

    ?omment

It is recommended to pre-write everything into a file. and run the
program via command-line.  See the L</SAMPLE TURNS>, below.

=head1 SAMPLE TURNS

These samples will use input file F<t>, to help ensure the correct
input format.

As described above, the first 15 lines represent board situation, followed
with "yes", followed by wild tile positions, if none, place a empty
line here, then followed by tiles (can be less than 7), use ? to
represent wild tiles.  Please make sure the last line in your file
ends with a full NEWLINE character on your system (it's safest to add
a blank line after the list of tiles).

I<Make sure to put `F<./wordlist>' in the working directory when running
the program, or to set C<$WordFile> to the path to your dictionary.>

=head2 First Turn

Create game file named F<t>, like this:

    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    yes

    ?omment
    <file end with a CR>

Run the game from the command line:

    perl -MGames::Literati=literati -e'literati()' < t

The output will be (depending on word list)

    [...]
    using 7 tiles:
    (47)    row 7 become: 'comment' starting at column 1 (BINGO!!!!)
    (47)    row 7 become: 'memento' starting at column 1 (BINGO!!!!)
    (47)    row 7 become: 'metonym' starting at column 1 (BINGO!!!!)
    (47)    row 7 become: 'momenta' starting at column 1 (BINGO!!!!)
    (47)    row 7 become: 'momento' starting at column 1 (BINGO!!!!)
    [...]
    Possible Ten Best Solution 1: row 7 become: 'metonym' starting at column 5 (BINGO!!!!) using 7 tile(s), score 47
    Possible Ten Best Solution 2: row 7 become: 'moments' starting at column 6 (BINGO!!!!) using 7 tile(s), score 47
    Possible Ten Best Solution 3: row 7 become: 'momenta' starting at column 6 (BINGO!!!!) using 7 tile(s), score 47
    Possible Ten Best Solution 4: column 7 become: 'omentum' starting at row 7 (BINGO!!!!) using 7 tile(s), score 47
    Possible Ten Best Solution 5: column 7 become: 'memento' starting at row 7 (BINGO!!!!) using 7 tile(s), score 47
    Possible Ten Best Solution 6: column 7 become: 'memento' starting at row 1 (BINGO!!!!) using 7 tile(s), score 47
    Possible Ten Best Solution 7: row 7 become: 'comment' starting at column 3 (BINGO!!!!) using 7 tile(s), score 47
    Possible Ten Best Solution 8: row 7 become: 'omentum' starting at column 7 (BINGO!!!!) using 7 tile(s), score 47
    Possible Ten Best Solution 9: row 7 become: 'omentum' starting at column 1 (BINGO!!!!) using 7 tile(s), score 47
    Possible Ten Best Solution 10: column 7 become: 'memento' starting at row 5 (BINGO!!!!) using 7 tile(s), score 47

If you run the same board with the Scrabble engine:

    $ perl -MGames::Literati=scrabble -e'scrabble()' < t

You will get

    [...]
    (76)    row 7 become: 'comment' starting at column 1 (BINGO!!!!)
    (76)    row 7 become: 'memento' starting at column 1 (BINGO!!!!)
    (72)    row 7 become: 'metonym' starting at column 1 (BINGO!!!!)
    [...]
    Possible Ten Best Solution 1: column 7 become: 'memento' starting at row 1 (BINGO!!!!) using 7 tile(s), score 76
    Possible Ten Best Solution 2: column 7 become: 'momento' starting at row 1 (BINGO!!!!) using 7 tile(s), score 76
    Possible Ten Best Solution 3: row 7 become: 'metonym' starting at column 5 (BINGO!!!!) using 7 tile(s), score 76
    Possible Ten Best Solution 4: row 7 become: 'momenta' starting at column 1 (BINGO!!!!) using 7 tile(s), score 76
    [...]

=head2 Intermediate Turn

For most turns, you input file the F<t> containing a partially
populated game, such as:

    ...............
    ...............
    ...............
    .......c.......
    ......ai.......
    .......s.header
    .......t....r..
    ...jurors..soup
    .......o....p.h
    .upsilon.f..pea
    .......speering
    .........s..n.e
    .........t..g..
    .........e.....
    ........broils.
    yes
    7,8 10,14 7,14
    eurmsss
    <file end with a CR>

Run the game from the command line:

    perl -MGames::Literati=literati -e'literati()' < t

The output will be (depending on word list)

    [....]
    using 7 tiles:
    using 6 tiles:
    (9)     row 3 become: 'cussers' starting at column 8
    (9)     row 12 become: 'russets' starting at column 4
    using 5 tiles:
    (8)     row 3 become: 'cruses' starting at column 8
    (8)     row 3 become: 'curses' starting at column 8

    [...]
    Possible Ten Best Solution 1: column 3 become: 'susses' starting at row 10  using 5 tile(s), score 24
    Possible Ten Best Solution 2: column 3 become: 'serums' starting at row 10  using 5 tile(s), score 24
    [...]

If you run the same board with the Scrabble engine:

    perl -MGames::Literati=scrabble -e'scrabble()' < t

You will get

    [...]
    Possible Ten Best Solution 1: row 14 become: 'embroils' starting at column 6  using 2 tile(s), score 36
    Possible Ten Best Solution 2: row 6 become: 'stems' starting at column 6  using 4 tile(s), score 23
    Possible Ten Best Solution 3: column 2 become: 'spumes' starting at row 8  using 5 tile(s), score 22
    [...]

Good luck!:)

=head1 PUBLIC FUNCTIONS

=over 4

=item literati([I<min>[, I<max>]])

=item wordswithfriends([I<min>[, I<max>]])

=item scrabble([I<min>[, I<max>]])

=item superscrabble([I<min>[, I<max>]])

These functions execute each of the games.  As shown in the L</SYNOPSIS>
and L</SAMPLE TURNS>, each turn generally requires just one call to
the specific game function.  Each function implements the appropriate
15x15 (or 20x20 for superscrabble) grid of bonus scores.

There are two optional arguments to the game functions:

=over 4

=item I<min>

The minimum number of tiles to play, which defaults to C<1>.  If you
want to only allow your computer player (I<ie>, the B<Games::Literati>
module) to play 3 or more tiles, you would set I<min>=C<3>.

If you specify C<0> or negative, the magic of perl will occur, and it
will internally use the default of I<min>=C<1>.

=item I<max>

The maximum number of tiles to play, which defaults to all the tiles
in the given hand.  If you want to restrict your computer player to play 5
or fewer tiles, you would set I<max>=C<5>.  It will check to ensure that
I<max> is bounded by the C<numTilesPerHand()>..

If you want to specify I<max>, you B<must> also specify a I<min>.

If you specify I<max> less than I<min>, B<Games::Literati> will not play
any tiles.

=back

Thus, specifying C<literati(3,5)> will restrict the computer Literati
player to using 3, 4, or 5 tiles on this turn.

=item find(I<\%args>) or find(I<$args>)

Finds possible valid words, based on the hashref provided.  When playing
the automated game using the above functions, this is not needed, but it
is provided to give you access to a function similar to the internal function,
but it outputs extra information to the user.

=over 4

=item \%args or $args

A reference to a hash containing the keys C<letters>, C<re>, and
C<internal>.

=over 4

=item $args->{etters}

This is the list of letters available to play.

=item $args->{re}

This is a string which will be evaluated into a perl regular
expression that is evaluated to determine. Note: this requres the
full regex syntax, so use C<'/c.t/'> to indicate you are looking
for valid letters to put between a `c' and a `t'.

=item $args->{internal}

(Boolean) If set to a true value, find() will be quiet (not print
to standard output) and will return an array-reference of possible
solutions. If false, find() will print suggested words to STDOUT.

=back

=back

B<Note>: The I<find()> function is not under active development, and changes to the
internal function might not be replicated to this public function.  (It is
documented and left exportable to be backward compatible with the original
B<Games::Literati 0.01> release.)


=back

=head1 PUBLIC VARIABLES

These variables are exportable, so can be fully qualified as
C<%Games::Literati::valid>, or if included in the export list
when you C<use> the module, you can reference them directly,
as

    use Games::Literati qw/literati $WordFile/;
    $WordFile = '/usr/share/dict/words';

=over 4

=item $WordFile

The C<$WordFile> points to a text document, which lists one valid word per line.

The variable defaults to './wordfile'.  (in version 0.01, that was the
only value, and there was no variable.)

You may change the default wordfile by setting this variable to the path
to find the list.

    $Games::Literati::WordFile = '/usr/dict/words';


Sources for C<$WordFile>

=over

=item * Your OS may include a builtin dictionary (such as F</usr/dict/words> or
F</usr/share/dict/words>).  Beware: these often have numbers or
punctuation (periods, hyphens), which may interfere with proper functioning

=item * ENABLE (Enhanced North American Benchmark Lexicon): a
public-domain list with more than 173,000 words, available at a variety of locations,
including in an old L<google code
repository|https://code.google.com/archive/p/dotnetperls-controls/downloads>
as
"L<enable1.txt|https://storage.googleapis.com/google-code-archive-downloads/v2/code.google.com/dotnetperls-controls/enable1.txt>"
The ENABLE dictionary is used by a variety of online tools, and is
the primary source for the official L<Words With Friends|http://www.zyngawithfriends.com/wordswithfriends/support/WWF_Rulebook.html> dictionary.

=item * Anthony Tan has delved into the Words With Friends app, and
has compared their internal list to the original ENABLE list at
L<http://www.greenworm.net/notes/2011/05/02/words-friends-wordlist>

=back

If you want to use one of the lists from a website, you will need
to download the list to a file, and set C<$WordFile> to the path
to your downloaded list.

=item %valid

For each I<word> that B<Games::Literati> parses from the C<$WordList>
file, it will set C<$valid{I<word>}> to C<1>.

=item $MinimumWordLength

Default = 2. This is used when parsing the dictionary file (during C<var_init>)
to ignore words that are too short.  Most of these games don't allow
single-letter words ("I", "a").

=back

=begin comment

=head1 CUSTOMIZATION

You can override the private internal functions to get your own
functionality.  This might be useful if you would like to make
a sub-package (maybe that use a GUI interface), or if you'd like to
build a script on your webserver that will host a game where you
can play against B<Games::Literati>.

These brief notes are intended as hints for how to get started.

For a sub-package, B<Games::Literati::MyGooeyInterface>, you could
inherit from B<Games::Literati>, and define your own
package-specific I<input()> and I<output()> functions, which
you could then ask if you could add to the B<Games::Literati>
distribution.

For a standalone application, F<mywebapp.pl>, you could just C<use
Games::Literati> and override the default functions, such as
defining your own C<sub Games::Literati::display> function.

=over 4

=item sub display()

This subroutine displays the current state of the board.

By default, it outputs the board to STDOUT as a 15x15 grid:

    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............
    ...............

Override the subroutine to change the style of output

   sub Games::Literati::display { # overrides default behavior
       my $f = shift;

       print "\nBoard:\n";
       for my $row (0..14) {
           print sprintf "%02d ", $row if $f;
           for my $col (0..14) {
               # use _ instead of .
               my $c = $Games::Literati::onboard[$row][$col] || '_';
               $c =~ s/\./_/g;
               print $c;
           }
           print "\n";
       }
       print "\n";
   }

=item input()

Ask for the current board data: existing tile positions,
wild-tile positions, and the tiles in your hand, and initiate the search
for valid words using the existing board and your hand.

Overriding sub Games::Literati::input (similarly to display, above)
will allow a change in input method, such as via CGI.  Look at the source
code for the default input(), so you know what globals need to be set,
and what to return.

=item var_init(I<numRows>, I<numCols>, I<numTilesPerHand>)

Initialize the board setup, including number of rows and number of columns,
and the number of tiles in a (full) hand.  Bingos occur when the number of
tiles played equals I<numTilesPerHand>).

This is used when manually defining a new game.  For example, if you wanted
to define a game called C<tinyscrabble> with a 7x7 board, and only 5 tiles
dealt to each player, the "game engine routine" would be defined as

    # run the game:
    sub tinyscrabble {
        var_init(7,7,5);
        _tinyscrabble_init();
        display();
        search(shift, shift);
    }

=item define your own board

When creating your own custom game, you need a subroutine to
define the game.  Pattern it similar to the following:

    # define the board:
    use Games::Literati;    # COMING SOON: the use Games::Literati qw/:customizer/
                            # which will make it easy to get rid of all the $Games::Literati:: prefixes
    sub _tinyscrabble_init {
        # name the game
        $Games::Literati::GameName = "TinyScrabble";

        # define the bonuses
        $Games::Literati::bonus[0][0] = 'DW';
        # ...
        $Games::Literati::bonus[6][6] = 'DW';

        for my $row (0.._max_row) {
            for my $col (0.._max_col) {
                $onboard[$row][$col] = '.';
            }
        }

        %Games::Literati::values = (
            a => 1,
            z => 1000,
        )

        $Games::Literati::bingo_bonus = 5000;
    }

=back

=end comment

=head1 BUGS AND FEATURE REQUESTS

Please report any bugs or feature requests emailing C<bug-Games-Literati AT rt.cpan.org>
or thru the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Games-Literati>.

A simple interface (with examples) for play your own custom grid is in the works.  Studying
the source code may point you in the right direction if you want a custom grid before the
customization features are made public.

=head1 AUTHOR

Chicheng Zhang C<E<lt>chichengzhang AT hotmail.comE<gt>> wrote the original code.

Peter C. Jones C<E<lt>petercj AT cpan.orgE<gt>> has added various feature
and made bug fixes.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2003, Chicheng Zhang.  Copyright (C) 2016 by Peter C. Jones

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut
