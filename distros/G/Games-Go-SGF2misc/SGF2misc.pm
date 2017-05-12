package Games::Go::SGF2misc;

use strict;
no warnings;

use Carp;
use Parse::Lex;
use Data::Dumper;
use Compress::Zlib;
use CGI qw(escapeHTML);

our $VERSION = 0.9782;

1;

# main calls
# new {{{
sub new {
    my $this = shift;
       $this = bless {}, $this;

    if( $ENV{DEBUG} > 0 ) {
        use Number::Format;
        use Devel::Size qw(total_size);
        use Time::HiRes qw(time);

        $this->{frm} = new Number::Format;
    }

    return $this;
}
# }}}
# parse {{{
sub parse {
    my $this = shift;
    my $file = shift;

    if( -f $file ) {
        local $/;  # Enable local "slurp" ... ie, by unsetting $/ for this local scope, it will not end lines on \n
        open SGFIN, $file or die "couldn't open $file: $!";

        our $FILENAME = $file;

        return $this->parse_internal(\*SGFIN);
    }

    $this->{error} = "Parse Error reading $file: unknown";
    return 0;
}
# }}}
# parse_string {{{
sub parse_string {
    my $this = shift;
    my $string = shift;

    our $FILENAME = "STRING";

    return $this->parse_internal($string);
}
# }}}
# parse_internal {{{
sub parse_internal {
    my $this = shift;
    my $file = shift;

    our $FILENAME;

    for my $k (keys %$this) {
        delete $this->{$k} unless {Time=>1, frm=>1}->{$k};
    }
    $global::lex_error = undef;

    $this->_time("parse");

    my @rules = (
        VALUE  => '(?:\[\]|\[(?s:.*?[^\x5c])\])',

        BCOL   => '\(',                   # begin collection
        ECOL   => '\)',                   # end collection
        PID    => '(?:CoPyright|[A-Z]+)', # property identifier (CoPyright is the spurious IGS tag, assholes)
        NODE   => ';',                    # new node
        WSPACE => '[\s\r\n]',

        qw(ERROR  .*), sub {
            $global::lex_error = "Parse Error reading $FILENAME: $_[1]\n";
        }
    );

    Parse::Lex->trace if $ENV{DEBUG} > 30;

    my $lex = Parse::Lex->new(@rules); $^W = 0; no warnings;
       $lex->from($file);

    $this->{parse} = { p => undef, n => [], c=>[] }; # p => parent, n => nodes, c => child Collections

    my $ref = $this->{parse};  # our current position

    # parse rules:
    my $nos = -1;  # the current node (array position).  -1 when we're not in a node
    my $pid = 0;   # 0 unless we just got a pid; otherwise, node array position

    TOKEN: while (1) {
        my $token = $lex->next;

        if (not $lex->eoi) {
            my $C = $token->name;
            my $V = $token->text;

            if( $C eq "ERROR" or defined $global::lex_error ) {
                $global::lex_error = "Parse Error reading $FILENAME: unknown"; # TODO: this $file should be ... the name of it instead
                $this->{error} = $global::lex_error;
                return 0;
            }

            if( $C eq "BCOL" ) { 
                push @{ $ref->{c} }, { p=>$ref, n=>[], c=>[] };
                $ref = $ref->{c}[$#{ $ref->{c} }];
                $nos = -1;

            } elsif( $C eq "ECOL" ) { 
                $ref = $ref->{p};
                $nos = -1;

            } elsif( $C eq "NODE" ) {
                push @{ $ref->{n} }, [];
                $nos = $#{ $ref->{n} };

            } 
            
            # this get's it's own if block for the $pid
            if( $C eq "PID" ) {
                if( $nos == -1 ) {
                    $this->{error} = "Parse Error reading $FILENAME: property identifier ($V) in strange place";
                    return 0;
                }
                push @{ $ref->{n}[$nos] }, {P=>$V};
                $pid = $#{ $ref->{n}[$nos] };

            } elsif( $C eq "VALUE" ) {
                $V =~ s/^\[//ms; $V =~ s/\]$//ms;
                $V =~ s/\\(.)/$1/msg;

                if( $nos == -1 or $pid == -1 ) {
                    $this->{error} = "Parse Error reading $FILENAME: property value ($V) in strange place";
                    return 0;
                }
                if( defined $ref->{n}[$nos][$pid]{V} ) {
                    push @{ $ref->{n}[$nos] }, {P=>$ref->{n}[$nos][$pid]{P}};
                    $pid = $#{ $ref->{n}[$nos] };
                }

                $ref->{n}[$nos][$pid]{V} = $V;

            } elsif( $C eq "WSPACE" ) {
                # don't set pid to -1 here (2006-5-12)

            } else {
                $pid = -1;
            }

        } else {
            last TOKEN;
        }
    }

    $this->_time("parse");

    print STDERR "SGF Parsed!  Calling internal _parse() routine\n" if $ENV{DEBUG} > 0;
    print STDERR "\$this size (before _parse)= ", $this->{frm}->format_bytes(total_size( $this )), "\n" if $ENV{DEBUG} > 0;

    $this->_time("_parse");

    my $r = $this->_parse(0, $this->{parse});

    $this->_time("_parse");

    print STDERR "\$this size (after _parse)= ", $this->{frm}->format_bytes(total_size( $this )), "\n" if $ENV{DEBUG} > 0;

    print STDERR "rebuilding {refdb} (for ref2id/id2ref)\n" if $ENV{DEBUG} > 0;

    $this->_time("_nodelist");

    $this->{nodelist} = { map {$this->_ref2id($_) => $this->_nodelist([], $_)} @{$this->{gametree}} };

    $this->_time("_nodelist");

    print STDERR "\$this size (after _nodelist())= ", $this->{frm}->format_bytes(total_size( $this )), "\n" if $ENV{DEBUG} > 0;

    $this->_time("nuke(gametree and parse)");
    my @to_nuke;
    
    push @to_nuke, (@{$this->{gametree}}) if ref($this->{gametree}) eq "ARRAY";
    push @to_nuke, $this->{parse}         if ref($this->{parse})    eq "HASH";

    while( @to_nuke ) {
        my $ref = shift @to_nuke;
        for my $k (qw(p c kids parent)) {
            if( my $v = $ref->{$k} ) {
                if( ref($v) eq "ARRAY" ) {
                    push @to_nuke, @$v;
                }

                delete $ref->{$k};
            }
        }
    }
    $this->_time("nuke(gametree and parse)");

    $this->_show_timings if $ENV{DEBUG} > 0;

    return $r;
}
# }}}
# freeze {{{
sub freeze {
    my $this = shift;

    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Purity = 1;

    my $fm = {};
    for my $k (qw(nodelist refdb)) {
        $fm->{$k} = $this->{$k};
    }

    $this->_time("freeze Dumper");
    my $buf = Dumper( $fm );
    $this->_time("freeze Dumper");

    return Compress::Zlib::memGzip( $buf );
}
# }}}
# thaw {{{
sub thaw {
    my $this = shift;
    my $frz  = shift;
    my ($VAR1);

    if( ref($frz) eq "GLOB" ) {
        $this->_time("gzreads");
        my $gz = gzopen($frz, "r"); 

        $frz = "";

        my $x;
        while( my $r = $gz->gzread($x, 32768) ) {
            $frz .= $x;
        }
        $gz->gzclose;

        $this->_time("gzreads");

        $this->_time("eval");
        eval $frz;
        $this->_time("eval");
    } else {
        $this->_time("memgunzip/eval");
        eval Compress::Zlib::memGunzip( $frz );
        $this->_time("memgunzip/eval");
        if( $@ ) {
            $this->{error} = $@;
            return 0;
        }
    }

    $this->_time("assign refs");
    for my $k (keys %$VAR1) {
        $this->{$k} = $VAR1->{$k};
    }
    $this->_time("assign refs");

    $this->_show_timings if $ENV{DEBUG} > 0;

    return 1;
}
# }}}
# errstr {{{
sub errstr {
    my $this = shift;

    $this->{error} =~ s/[\r\n\s]$//msg;

    return $this->{error};
}
# }}}

# tools -- can croak()!
# sgfco2numco {{{
sub sgfco2numco {
    my $this = shift;
    my $gref = shift;
    my $co   = shift;

    my ($sz, $ff);
    if( ref($gref) eq "HASH" and ref($gref->{game_properties}) eq "HASH" ) {
        $sz = $gref->{game_properties}{SZ};
        $ff = $gref->{game_properties}{FF};

        unless( $sz and $ff ) {
            croak "Error: sgfco2numco needs FF and SZ properties to function, sorry.\n";
        }
    } else {
        croak "Syntax Error: You must pass a game reference to sgfco2numco because it needs the FF and SZ properties.\n";
    }

    if( $co =~ m/\w{2}\:\w{2}/ ) {
        croak "Parsed Stupidly: SGF2misc.pm doesn't handle compressed co-ordinates ($co) yet... *sigh*\n";
    }

    my $inty = sub {
        my $x = -1;

        $x = int(hex(unpack("H*", $_[0]))) - 97 if $_[0] =~ m/[a-z]/;
        $x = int(hex(unpack("H*", $_[0]))) - 65 if $_[0] =~ m/[A-Z]/;

        die "unexpected error reading column identifier" unless $x > -1;

        return $x;
    };

    if( not $co or ($co eq "tt" and ($ff == 3 or $sz<=19)) ) {
        return (wantarray ? (qw(PASS PASS)) : [qw(PASS PASS)]);
    }

    if( $co =~ m/^([a-zA-Z])([a-zA-Z])$/ ) {
        my ($row, $col) = ($1, $2);

        return (wantarray ? ($inty->($col), $inty->($row)) : [ $inty->($col), $inty->($row) ]);
    }

    croak "Parse Error: co-ordinate not understood ($co)\n";
}
# }}}

# outputers
# parse_hash {{{
sub parse_hash {
    my $this = shift;

    return $this->{parse};
}
# }}}
# nodelist {{{
sub nodelist {
    my $this  = shift;

    return $this->{nodelist};
}
# }}}
# is_node {{{
sub is_node {
    my $this = shift;
    my $node = shift;

    return ($this->{refdb}{$node} ? 1:0);
}
# }}}
# as_perl {{{
sub as_perl {
    my $this = shift;
    my $node = shift;
    my $soft = shift;

    if( $node ) {
        if( my $ref = $this->{refdb}{$node} ) {
            return $ref;
        }
    }

    $this->{error} = "no such node: $node";
    return 0 if $soft;

    croak $this->{error};
}
# }}}
# as_text {{{
sub as_text {
    my $this = shift;
    my $node = shift;

    $node = $this->as_perl( $node, 1 ) or croak $this->errstr;

    my $board = $node->{board};

    my $x = "";
    for my $i (0..$#{ $board }) {
        for my $j (0..$#{ $board->[$i] }) {
            $x .= " " . { ' '=>'.', 'W'=>'O', 'B'=>'X' }->{$board->[$i][$j]};
        }
        $x .= "\n";
    }

    return $x;
}
# }}}
# _mark_alg {{{
sub _mark_alg {
    my $this = shift;
    my ($mark, $img) = @_;

    return "bt.gif" if $mark eq "TR" and $img eq "b.gif";
    return "wt.gif" if $mark eq "TR" and $img eq "w.gif";
    return "bc.gif" if $mark eq "CR" and $img eq "b.gif";
    return "wc.gif" if $mark eq "CR" and $img eq "w.gif";
    return "bq.gif" if $mark eq "SQ" and $img eq "b.gif";
    return "wq.gif" if $mark eq "SQ" and $img eq "w.gif";

    if( ($mark = int($mark)) > 0 and $mark <= 100 ) {
        return "b$mark.gif" if $img =~ "b[tcq]?.gif";
        return "w$mark.gif"
    }

    return $img;
}
# }}}
# _crazy_moku_alg {{{
sub _crazy_moku_alg {
    my $this = shift;
    my ($i, $j, $size) = @_;

    our $cma_size;
    our $hoshi;

    if( $size != $cma_size or not $hoshi ) {
        $hoshi = {};
        if( $size == 19 ) {
            $hoshi = { "3 3" => 1, "3 15" => 1, "15 3" => 1, "15 15" => 1,
                "9 3" => 1, "9 15" => 1, "3 9" => 1, "15 9" => 1, "9 9" => 1, };
        } elsif( $size == 13 ) {
            $hoshi = { "3 3" => 1, "9 9" => 1, "3 9" => 1, "9 3" => 1,
                "6 3" => 1, "3 6" => 1, "9 6" => 1, "6 9" => 1, "6 6" => 1, };
        } elsif( $size == 9 ) {
            $hoshi = { "2 2" => 1, "2 6" => 1, "6 6" => 1, "6 2" => 1, "4 4" => 1, };
        }
    }

    return "ulc.gif" if $i == 0     and $j == 0;
    return "urc.gif" if $i == 0     and $j == $size;
    return "llc.gif" if $i == $size and $j == 0;
    return "lrc.gif" if $i == $size and $j == $size;
    return "ts.gif"  if $i == 0     and $j != 0 and $j != $size;
    return "bs.gif"  if $i == $size and $j != 0 and $j != $size;
    return "ls.gif"  if $j == 0     and $i != 0 and $i != $size;
    return "rs.gif"  if $j == $size and $i != 0 and $i != $size;

    return "h.gif" if $hoshi->{"$i $j"};
    return "p.gif",
}
# }}}
# as_html {{{
sub as_html {
    my $this  = shift;
    my $node  = shift;
    my $dir   = shift;
       $dir   = "./img" unless $dir;
    my $id    = shift;
    my $onode = $node;

    $node = $this->as_perl( $node, 1 ) or croak $this->errstr;

    # use Data::Dumper; $Data::Dumper::Indent = 0;
    # warn Dumper( $node );

    my $gref      = $this->as_perl(1);
    my $game_info = $gref->{game_properties};
     
=cut
game_properties' => {'FF' => 4,'PB' => 'Orien Vandenbergh
(nichus)','GM' => 1,'KM' => '6.5','SZ' => 19,'PC' => 'Dragon Go Server: http://www.dragongoserver.net','RE' => 'W+29.5','RU' =>
'Japanese','BR' => '13 kyu','GN' => 'jettero-nichus-20041229.sgf','GC' => 'Game ID: 85389','DT' => '2004-10-29,2004-12-29','PW' =>
'Jettero Heller (jettero)','WR' => '13 kyu','OT' => '30 days + 1 day/10 periods Japanese byoyomi'}
=cut

    my $board = $node->{board};
    my $size  = @{$board->[0]}; # inaccurate?
       $size--;

    my %marks = ();
    for my $m (@{ $node->{marks} }) {
        $marks{"$m->[1] $m->[2]"} = ($m->[0] eq "LB" ? $m->[4] : $m->[0]);
    }

    my @letters = qw(A B C D E F G H J K L M N O P Q R S T);
    my $arow = "<tr align='center'><td>" . join("", map("<td>$_", @letters[0..$size])) . "<td>";

    my $x = "<table class='sgf2miscboard' cellpadding=0 cellspacing=0>$arow\n";

    for my $i (0..$#{ $board }) {
        $x .= "<tr><td>". (($size+1)-$i);
        for my $j (0 .. $#{ $board->[$i] }) {
            my $iid = "";
               $iid = " id='$id.$i.$j'" if $id;

            my $c = { 
                'B' => "b.gif",
                'W' => "w.gif",
            }->{$board->[$i][$j]};

            $c = "wc.gif" if $c eq "w.gif" and $node->{moves}[0][1] == $i and $node->{moves}[0][2] == $j;
            $c = "bc.gif" if $c eq "b.gif" and $node->{moves}[0][1] == $i and $node->{moves}[0][2] == $j;

            $c = $this->_crazy_moku_alg($i, $j, $size) unless $c;
            $c = $this->_mark_alg($marks{"$i $j"}, $c);

            $c  = "$dir/$c"; 
            $x .= "<td><img$iid src=\"$c\">";
        }
        $x .= "<td align='right'>". (($size+1)-$i) . "\n";
    }

    my $cpid = "";
       $cpid = " id='$id.state'" if $id;

    my $p = "<tr><td$cpid colspan='21' class='sgf2misccaps'><br/>W.Caps: $node->{captures}->{W}\&nbsp; \&nbsp;B.Caps: $node->{captures}->{B}";

    if( $node->{other} ) {
        my $TB = $node->{other}->{TB};
        my $TW = $node->{other}->{TW};

        if ($TB and $TW) {
            my $cb = $node->{captures}->{B};
            my $cw = $node->{captures}->{W};
            my $km = $game_info->{KM};

            my ($tb, $tw) = (0, 0);
            for my $r (@$TB) {
                my @a = $this->sgfco2numco($gref, $r);

                $tb ++;
                $cb ++ if $board->[$a[0]][$a[1]] eq "W";
            }

            for my $r (@$TW) {
                my @a = $this->sgfco2numco($gref, $r);

                $tw ++;
                $cw ++ if $board->[$a[0]][$a[1]] eq "B";
            }

            my $f = ($tw + $cw + $km) - ($tb + $cb);
               $f = ($f<0 ? "B+".abs($f) : "W+$f");

            $p = "<tr><td$cpid colspan='21' class='sgf2miscresult'><br/>W($tw t + $cw c + $km k), B($tb t + $cb c): $f";
        }
    }

    my $cmid = "";
       $cmid = " id='$id.comment'" if $id;

    my $comments = "";
       $comments .= escapeHTML($_) for @{$node->{comments}};
       $comments =~ s/[\r\n]/<br\/>/sg;

    return "$x$arow$p</table><!--MATCHME--><div$cmid class='sgf2misccomment'>$comments</div>";
}
# }}}
# as_js {{{
sub as_js {
    my $this  = shift;
    my $node  = shift;

    $node = $this->as_perl( $node, 1 ) or croak $this->errstr;

    my $gref      = $this->as_perl(1);
    my $game_info = $gref->{game_properties};

    my $board = $node->{board};
    my $size  = @{$board->[0]}; # inaccurate?
       $size--;

    my %marks = ();
    for my $m (@{ $node->{marks} }) {
        $marks{"$m->[1] $m->[2]"} = ($m->[0] eq "LB" ? $m->[4] : $m->[0]);
    }

    my @board  = ();
    for my $i (0..$#{ $board }) {
        my $row = [];
        for my $j (0 .. $#{ $board->[$i] }) {
            my $c = { 
                'B' => "b.gif",
                'W' => "w.gif",
            }->{$board->[$i][$j]};

            $c = "wc.gif" if $c eq "w.gif" and $node->{moves}[0][1] == $i and $node->{moves}[0][2] == $j;
            $c = "bc.gif" if $c eq "b.gif" and $node->{moves}[0][1] == $i and $node->{moves}[0][2] == $j;

            $c = $this->_crazy_moku_alg($i, $j, $size) unless $c;
            $c = $this->_mark_alg($marks{"$i $j"}, $c);

            push @$row, $c;
        }

        push @board, $row;
    }

    local $Data::Dumper::Indent = 0;
    my $board = Dumper(\@board);
       $board =~ s/^\$VAR1\s*=\s*//s;
       $board =~ s/\s*\;\s*$//s;
       $board =~ s/\.gif//sg;

    my $p = "<br/>W.Caps: $node->{captures}->{W}\&nbsp; \&nbsp;B.Caps: $node->{captures}->{B}";

    if( $node->{other} ) {
        my $TB = $node->{other}->{TB};
        my $TW = $node->{other}->{TW};

        if ($TB and $TW) {
            my $cb = $node->{captures}->{B};
            my $cw = $node->{captures}->{W};
            my $km = $game_info->{KM};

            my ($tb, $tw) = (0, 0);
            for my $r (@$TB) {
                my @a = $this->sgfco2numco($gref, $r);

                $tb ++;
                $cb ++ if $board->[$a[0]][$a[1]] eq "W";
            }

            for my $r (@$TW) {
                my @a = $this->sgfco2numco($gref, $r);

                $tw ++;
                $cw ++ if $board->[$a[0]][$a[1]] eq "B";
            }

            my $f = ($tw + $cw + $km) - ($tb + $cb);
               $f = ($f<0 ? "B+".abs($f) : "W+$f");

            $p = "<br/>W($tw t + $cw c + $km k), B($tb t + $cb c): $f";
        }
    }

    my $comments = "";
       $comments .= escapeHTML($_) for @{$node->{comments}};
       $comments =~ s/[\r\n]/<br\/>/sg;

           $p =~ s/"/\\"/sg;
    $comments =~ s/"/\\"/sg;

    return "{ board: $board, status: \"$p\", comment: \"$comments\" }";
}
# }}}
# as_image {{{
sub as_image {
    my $this = shift;
    my $node = shift; my $nm = $node;
    my $argu = shift;
    my %opts = (imagesize=>256, antialias=>0);

    $node = $this->as_perl( $node, 1 ) or croak $this->errstr;

    my $board = $node->{board};
    my $size  = @{$board->[0]}; # inaccurate?

    if( ref($argu) ne "HASH" ) {
        croak 
        "as_image() takes a hashref argument... e.g., {imagesize=>256, etc=>1} or nothing at all.";
    }

    my $package = $argu->{'use'} || 'Games::Go::SGF2misc::GD';
    if ($package =~ /svg/i) {
        $opts{'imagesize'} = '256px';
    }

    @opts{keys %$argu}  = (values %$argu);
    $opts{boardsize}    = $size;
    $opts{filename}     = "$nm.png" unless $opts{filename};

    my $image;
    eval qq( use $package; \$image = $package->new(%opts); );

    $image->drawGoban();

    # draw moves
    for my $i (0..$#{ $board }) {
        for my $j (0..$#{ $board->[$i] }) {
            if( $board->[$i][$j] =~ m/([WB])/ ) {
                if( $ENV{DEBUG} > 0 ) {
                    print STDERR "placeStone($1, [$i, $j])\n";
                }

                # SGFs are $y, $x, the matrix is $x, $y ...
                $image->placeStone(lc($1), [reverse( $i, $j )]);  
            }
        }
    }

    my $marks = 0;
    # draw marks
    for my $m (@{ $node->{marks} }) {
        $image->addCircle($m->[3])   if $m->[0] eq "CR";
        $image->addSquare($m->[3])   if $m->[0] eq "SQ";
        $image->addTriangle($m->[3]) if $m->[0] eq "TR";

        $image->addLetter($m->[3], 'X', "./times.ttf") if $m->[0] eq "MA";
        $image->addLetter($m->[3], $m->[4], "./times.ttf") if $m->[0] eq "LB";
        $marks++;
    }

    if ($argu->{'automark'}) {
        unless ($marks) {
            my $moves = $node->{moves};
            foreach my $m (@$moves) {
                $image->addCircle($m->[3]) unless $m->[3];
            }
        }
    }

    if ($package =~ /svg/i) {
        if( $opts{filename} =~ m/.png$/ ) {
            $image->export($opts{'filename'});
        } else {
            $image->save($opts{filename});
        }
    } else {
        if( $opts{filename} =~ m/^\-\.(\w+)$/ ) {
            return $image->dump($1);
        }

        $image->save($opts{filename});
    }
}
# }}}
# as_freezerbag {{{
sub as_freezerbag {
    my $this = shift;
    my $file = shift or croak "You must name your freezerbag.";
    my $code = shift;
       $code = "# your code here\n" unless $code;
    my $perl = shift;

    if( not $perl ) {
        for my $try (qw{ /usr/bin/perl /usr/local/bin/perl }) {
            $perl = $try if -x $try;
        }
        croak "couldn't find perl" unless -x $perl;
    }
    
    open  OUTMF, ">$file" or croak "Couldn't open freezerbag ($file) for output: $!";
    print OUTMF "#!$perl\n# vi:fdm=marker fdl=0:\n\nuse strict;\nno warnings;\nuse Games::Go::SGF2misc;\n\n";
    print OUTMF "my \$sgf = new Games::Go::SGF2misc;\n";
    print OUTMF "   \$sgf->thaw(\\*DATA);\n\n$code\n\n# freezer DATA {\{\{\n__DATA__\n";

    $this->_time("print freeze");
    print OUTMF $this->freeze;
    $this->_time("print freeze");

    close OUTMF;

    $this->_show_timings if $ENV{DEBUG} > 0;
}
# }}}

# internals
# _show_timings {{{
sub _show_timings {
    my $this = shift;

    my @times = ();
    for my $k (keys %{ $this->{Time} }) {
        my $x   = $this->{Time}{$k}{diffs};  next unless ref($x) eq "ARRAY";
        my $n   = int @$x;
        my $sum = 0;
           $sum += $_ for @$x;

        push @times, [ $k, $sum, $n, ($sum/$n) ];
    }

    for my $x (sort {$b->[1] <=> $a->[1]} @times) {
        printf('%-35s: sum=%3.4fs cardinality=%5d avg=%3.2fs%s', @$x, "\n");
    }

    delete $this->{Time};
}
# }}}
# _time {{{
sub _time {
    return unless $ENV{DEBUG} > 0;

    my $this = shift; 
    my $tag  = shift;

    if( $ENV{DEBUG} == 1.2 ) {
        my @a;

        for (sort keys %{ $this->{Time} }) {
           push @a, $_ if $this->{Time}{$_}{start};
        }

        print STDERR "clocks: @a\n";
    }

    if( defined $this->{Time}{$tag}{start} ) {
        push @{ $this->{Time}{$tag}{diffs} }, (time - $this->{Time}{$tag}{start});
        delete $this->{Time}{$tag}{start};
    } else {
        $this->{Time}{$tag}{start} = time;
    }
}
# }}}
# _nodelist {{{
sub _nodelist {
    my $this = shift;
    my $list = shift;
    my $cur  = shift;

    # $this->{nodelist} = { map {$this->_ref2id($_) => $this->_nodelist([], $_)} @{$this->{gametree}} };

    for my $kid (@{ $cur->{kids} }) {
        my $id = $this->_ref2id( $kid );

        die "problem parsing node id" unless $id =~ m/(\d+)\.(\d+)\-(.+)/;

        my ($g, $v, $m) = ($1, $2, $3);

        if( $v > @{ $list } ) {
            my $x = [];
            push @$list, $x;
            for (1..$m) {
                push @$x, undef;
            }
        }

        push @{ $list->[$v-1] }, $id;

        $this->_nodelist($list, $kid);
    }

    return $list;
}
# }}}
# _parse (aka, the internal parse) {{{
sub _parse {
    my $this   = shift;
    my $level  = shift;
    my $pref   = shift;
    my $gref   = shift;
    my $parent = shift;

    if( $ENV{DEBUG} > 1 ) {
        print STDERR "\t_parse($level)";
        print STDERR " ... variation = $gref->{variations} " if ref($gref) and defined $gref->{variations};
        print STDERR "\n";
    }

    my $gm_pr_reg = qr{^(?:GM|SZ|CA|AP|RU|KM|HA|FF|PW|PB|RE|TM|OT|BR|WR|DT|PC|AN|BT|CP|EV|GN|GC|ON|RO|SO|US)$};

    if( $level == 0 ) { 
        # The file level... $gref is most certainly undefined...
        # We're also starting the gametree from scratch here

        $this->{gametree} = [];

        if( int(@{ $this->{parse}{n} }) ) {
            $this->{error} = "Parse Error: nodes found at top level... very strange.";
            return 0;
        }

        for my $c (@{ $this->{parse}{c} }) {
            $this->_parse($level+1, $c, undef) or return 0;
        }

        return 1;

    } elsif( $level == 1 ) { 
        # Every collection should be a new game
        # At this $level, all we do is make a game and look for game properties.
        # Then we re _parse() at our current position

        $gref = { variations=>1, kids=>[] }; push @{ $this->{gametree} }, $gref;
        $gref->{gnum} = int @{ $this->{gametree} };

        my $pnode = $pref->{n}[0];
        for my $p (@$pnode) {
            if( $p->{P} =~ m/$gm_pr_reg/ ) {
                $gref->{game_properties}{$p->{P}} = $p->{V};
            }
            if( $p->{P} eq "CoPyright" ) {
                $gref->{game_properties}{FF} = 4;
            }
        }

        unless( $gref->{game_properties}{GM} == 1 ) {
            $this->{error} = "Parse Error: Need GM[1] property in the first node of the game... not found.";
            return 0;
        }

        unless( $gref->{game_properties}{FF} == 3 or $gref->{game_properties}{FF} == 4 ) {
            unless( $ENV{ALLOW_STRANGE_FFs} ) {
                $this->{error} = "Parse Error: Need FF[3] or FF[4] property in the first node of the game... not found.";
                return 0;
            }
        }

        if( $gref->{game_properties}{SZ} < 3 ) {
            $this->{error} = "Parse Error: SZ must be set and be greater than 2 (SZ was $gref->{game_properties}{SZ})";
            return 0;
        }

        if( $gref->{game_properties}{FF} == 3 and $gref->{game_properties}{SZ} > 19 ) {
            $this->{error} = "Parse Error: In FF[3] a move of B[tt] is a pass and therefore, SZ must be less than 20 " .
                "(SZ was $gref->{game_properties}{SZ}).";
            return 0;
        }

        if( $gref->{game_properties}{FF} == 4 and $gref->{game_properties}{SZ} > 52 ) {
            $this->{error} = "Parse Error: In FF[4] the size of the board must be no greater than 52" .
                "(SZ was $gref->{game_properties}{SZ})";
            return 0;
        }

        $this->_parse($level+1, $pref, $gref) or return 0;

        return 1;

    } elsif( defined $gref ) { 
        # OK, now we're getting into some serious parsing.

        my $gnode;  # this has the effect of forking the variations off the last node in the collection.
                    # is that correct?

        for my $i (0..$#{ $pref->{n} }) {
            my $pnode = $pref->{n}[$i];

            $parent = ($gnode ? $gnode : $parent ? $parent : $gref);

            $gnode = { variation=>$gref->{variations}, kids=>[] };
            push @{ $parent->{kids} }, $gnode;

            $gnode->{board} = $this->_copy_board_matrix( $parent->{board} ) if $parent->{board};
            $gnode->{board} = $this->_new_board_matrix( $gref ) unless $gnode->{board};

            $gnode->{captures} = { B=>0, W=>0 };
            if( ref($parent) and ref(my $pc = $parent->{captures}) ) {
                $gnode->{captures}{B} += $pc->{B};
                $gnode->{captures}{W} += $pc->{W};
            }

            for my $p (@$pnode) {
                if( $p->{P} =~ m/^([BW])$/) {
                    my $c = $1;
                    my @c = $this->sgfco2numco($gref, $p->{V});

                    print STDERR "\t\tmove: $c($p->{V}) == [@c]\n" if $ENV{DEBUG} >= 4;

                    push @{ $gnode->{moves} }, [ $c, @c, $p->{V} ];

                    unless( $c[0] eq "PASS" ) {
                        # fix up board
                        $gnode->{board}[$c[0]][$c[1]] = $c;

                        # check for captures
                        $this->_check_for_captures($gref->{game_properties}{SZ}, $gnode, @c );
                    }

                } elsif( $p->{P} =~ m/^A([WBE])$/ ) {
                    my $c = $1;
                    my @c = $this->sgfco2numco($gref, $p->{V});

                    push @{ $gnode->{edits} }, [ $c, @c, $p->{V} ];

                    # fix up board
                    # do NOT check for captures
                    if( $c eq "E" ) {
                        $gnode->{board}[$c[0]][$c[1]] = ' ';
                    } else {
                        $gnode->{board}[$c[0]][$c[1]] = $c;
                    }
                } elsif( $p->{P} =~ m/^C$/ ) {
                    push @{ $gnode->{comments} }, $p->{V};

                } elsif( $p->{P} =~ m/^(?:CR|TR|SQ)$/ ) {
                    my @c = $this->sgfco2numco($gref, $p->{V});

                    push @{ $gnode->{marks} }, [ $p->{P}, @c, $p->{V} ];

                    # It's tempting to put the marks ON THE BOARD Do not do
                    # this.  They'd need to get handled in _copy, and also,
                    # whosoever get's the $board out of the $gnode, can
                    # also get the $marks!

                } elsif( $p->{P} =~ m/^(?:LB)$/ and $p->{V} =~ m/^(..)\:(.+)$/ ) {
                    push @{ $gnode->{marks} }, [ "LB", $this->sgfco2numco($gref, $1), $1, $2 ];

                } elsif( not $p->{P} =~ m/$gm_pr_reg/ ) {
                    push @{ $gnode->{other}{$p->{P}} }, $p->{V};
                }
            }

            $gnode->{gnum}    = $parent->{gnum};
            $gnode->{move_no} = 
                  (ref($gnode->{moves}) ? int(@{ $gnode->{moves} }) : 0)
                + (ref($parent) and defined $parent->{move_no} ? $parent->{move_no} : 0);
        }

        my $j = @{ $pref->{c} };
        if( $j > 1 ) {
            # pretend we're in the node with move #12
             
            # The first fork is still this variation, and contains move #13
            $this->_parse($level+1, $pref->{c}[0], $gref, $gnode) or return 0;

            # Every other fork is an alternate move #13
            for my $i (1..$#{ $pref->{c} }) {
                $gref->{variations}++;
                $this->_parse($level+1, $pref->{c}[$i], $gref, $gnode) or return 0;
            }
        } elsif( $j == 1 ) {
            $this->{error} = "Parse Error: the author didn't think this condition could come up ... ";
            return 0;
        }

        return 1;
    }

    $this->{error} = "Parse Error: unknown parse depth ($level) or broken reference(s) ($pref, $gref)... error unknown";
    return 0;
}
# }}}
# _ref2id {{{
sub _ref2id {
    my $this = shift;
    my $ref  = shift;

    croak "invalid ref given to _ref2id()" unless ref($ref) eq "HASH";

    unless( defined $this->{refdb2}{$ref} ) {
        my $id;
        my $c = 2;
        if( defined($ref->{variation}) and defined($ref->{move_no}) ) {
            $id = "$ref->{gnum}." . 
                   $ref->{variation} . "-" . ($ref->{move_no} ? $ref->{move_no} : "root");
            my $cur = $id;
            while( defined $this->{refdb}{$cur} ) {
                $cur = $id . "-" . $c++;
            }
            $id = $cur;
        } else {
            $id = ++$this->{games};
        }

        print STDERR "$ref 2 id: $id\n" if $ENV{DEBUG} >= 10;

        $this->{refdb2}{$ref} = $id;

        for my $k (qw(comments board marks moves other captures game_properties variations)) {
            $this->{refdb}{$id}{$k} = $ref->{$k} if defined $ref->{$k};
        }

        for my $k (qw(gnum kids)) {
            delete $this->{refdb}{$id}{$k};
        }

        if( $ENV{DEBUG} > 20 ) {
            print STDERR "\$this\->\{refdb\}\{\$ref($ref)\} = $this->{refdb2}{$ref} ",
                        "/ \$this\-\>\{refdb\}\{\$id($id)\} = $this->{refdb}{$id}\n";
        }
    }

    return $this->{refdb2}{$ref};
}
# }}}
# _new_board_matrix {{{
sub _new_board_matrix {
    my $this = shift;
    my $gref = shift;

    $this->_time("_new_board_matrix");

    my $board = [];

    my $size = $gref->{game_properties}{SZ};
    croak "Syntax Error: You must pass a game reference to sgfco2numco because it needs the FF and SZ properties.\n" unless $size;

    for my $i (1..$size) {
        my $row = [];
        for my $j (1..$size) {
            push @$row, ' ';
        }
        push @$board, $row;
    }

    $this->_time("_new_board_matrix");

    return $board;
}
# }}}
# _copy_board_matrix {{{
sub _copy_board_matrix {
    my $this = shift;
    my $tocp = shift;

    $this->_time("_copy_board_matrix");

    my $board = [];

    my $double_check = int @$tocp;
    for (@$tocp) {
        my @a = @{ $_ }; 
        push @$board, \@a;

        die "Problem copying board (" . (int @a) . " vs $double_check)!" unless int @a == $double_check;
    }

    $this->_time("_copy_board_matrix");

    return $board;
}
# }}}

# _check_for_captures {{{
sub _check_for_captures {
    my ($this, $SZ, $node, @p) = @_;
    my $board = $node->{board};
    my $caps  = $node->{captures};

    $this->_time("_check_for_captures");

    my $tc = $board->[$p[0]][$p[1]];

    croak "crazy unexpected error: checking for caps, and current pos doesn't have a stone.  Two times double odd, and fatal" 
        unless $tc =~ m/^[WB]$/;

    my $oc = ($tc eq "W" ? "B" : "W");

    # 1. Find groups for all adjacent stones.  

    $this->_time("for(_find_group)");

    my %checked = ();
    my @groups  = ();
    for my $p ( [$p[0]-1, $p[1]+0], [$p[0]+1, $p[1]+0], [$p[0]+0, $p[1]-1], [$p[0]+0, $p[1]+1] ) {
        my @g = $this->_find_group( \%checked, $SZ, $oc, $board, @$p );

        push @groups, [ @g ] if @g;
    }

    $this->_time("for(_find_group)");
    $this->_time("for(\@groups), _count_liberties");

    if( @groups ) {
        # 2. Any groups without liberties are toast!
        print STDERR "_check_for_captures() found ", int(@groups), " neighboring groups:" if $ENV{DEBUG} > 3 and int(@groups);

        for my $group (@groups) {
            my $l = $this->_count_liberties( $SZ, $board, @$group );

            print STDERR " liberties($l)" if $ENV{DEBUG}>3;
            if( $l < 1 ) {
                print STDERR "-killed! " if $ENV{DEBUG}>3;
                for my $p (@$group) {
                    $caps->{$tc}++;
                    $board->[$p->[0]][$p->[1]] = ' ';
                }
            }
        }

        print STDERR "\n" if $ENV{DEBUG} > 3;
    }

    $this->_time("for(\@groups), _count_liberties");
    $this->_time("_find_group/_count_liberties of me");

    # 3. Check my own liberties, I may be toast
    %checked = ();
    my @me_group = $this->_find_group( \%checked, $SZ, $tc, $board, @p );
    my $me_lifec = $this->_count_liberties( $SZ, $board, @me_group );
    print STDERR "_check_for_captures() me_group ", int(@me_group), " stones: " if $ENV{DEBUG} > 3;
    print STDERR " me liberties($me_lifec)" if $ENV{DEBUG}>3;
    if( $me_lifec < 1 ) {
        print STDERR "-killed! " if $ENV{DEBUG}>3;
        for my $p (@me_group) {
            $caps->{$oc}++;
            $board->[$p->[0]][$p->[1]] = ' ';
        }
    }
    print STDERR "\n" if $ENV{DEBUG}>3;

    $this->_time("_find_group/_count_liberties of me");
    $this->_time("_check_for_captures");
}
# }}}
# _count_liberties {{{
sub _count_liberties {
    my ($this, $SZ, $board, @group) = @_;

    $this->_time("_count_liberties");

    my %checked = ();
    my $count   = 0;

    for my $g (@group) {
        for my $p ( [$g->[0]-1, $g->[1]+0], [$g->[0]+1, $g->[1]+0], [$g->[0]+0, $g->[1]-1], [$g->[0]+0, $g->[1]+1] ) {
            if( not $checked{"@$p"} ) {
                $checked{"@$p"} = 1;
                unless( ($p->[0] < 0 or $p->[0] > ($SZ-1)) or ($p->[1] < 0 or $p->[1] > ($SZ-1)) ) {
                    if( $board->[$p->[0]][$p->[1]] eq ' ' ) {
                        $count++;
                    }
                }
            }
        }
    }

    $this->_time("_count_liberties");

    return $count;
}
# }}}
# _find_group {{{
sub _find_group {
    my ($this, $checked, $SZ, $oc, $board, @p) = @_;

    $this->_time("_find_group");

    print STDERR "\t_find_group(@p)" if $ENV{DEBUG}>12;
    my @g;

    if( not $checked->{"@p"} ) {
        $checked->{"@p"} = 1;
        print STDERR "." if $ENV{DEBUG}>12;
        unless( ($p[0] < 0 or $p[0] > ($SZ-1)) or ($p[1] < 0 or $p[1] > ($SZ-1)) ) {
            print STDERR ".." if $ENV{DEBUG}>12;
            if( $board->[$p[0]][$p[1]] eq $oc ) {
                print STDERR " !" if $ENV{DEBUG}>12;
                push @g, [ @p ];
                for my $p ( [$p[0]-1, $p[1]+0], [$p[0]+1, $p[1]+0], [$p[0]+0, $p[1]-1], [$p[0]+0, $p[1]+1] ) {
                    push @g, $this->_find_group( $checked, $SZ, $oc, $board, @$p );
                }
            }
        }
    }
    print STDERR "\n" if $ENV{DEBUG}>12;

    $this->_time("_find_group");

    return @g;
}
# }}}

