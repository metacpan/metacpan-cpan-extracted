# vi:tw=0 syntax=perl:

package Games::RolePlay::MapGen::Exporter::Text;

use common::sense;
use Carp;

1;

# new {{{
sub new {
    my $class = shift;
    my $this  = bless {o => {@_}}, $class;

    return $this;
}
# }}}
# go {{{
sub go {
    my $this = shift;
    my $opts = {@_};

    for my $k (keys %{ $this->{o} }) {
        $opts->{$k} = $this->{o}{$k} if not exists $opts->{$k};
    }

    croak "ERROR: fname is a required option for " . ref($this) . "::go()" unless $opts->{fname};
    croak "ERROR: _the_map is a required option for " . ref($this) . "::go()" unless ref($opts->{_the_map});

    my $map = $this->genmap($opts);
    unless( $opts->{fname} eq "-retonly" ) {
        open _MAP_OUT, ">$opts->{fname}" or die "ERROR: couldn't open $opts->{fname} for write: $!";
        print _MAP_OUT $map;
        close _MAP_OUT;
    }

    return $map;
}
# }}}
# _show_by_od {{{
sub _show_by_od {
    my $this = shift;
    my $tile = shift;
    my $dir  = shift;
    my $od   = $tile->{od}{$dir};

    our $nocolor;

    if( $od == 1 ) {
        return " ";

    } elsif( $od ) {
        # A door!
        my $color = ( ($od->{locked} and $od->{stuck}) ? "[35m" : $od->{locked} ? "[31m" : $od->{stuck} ? "[m" : "[33m" );
        my $reset = "[m";

        $color = $reset = "" if $nocolor;

        if( $od->{secret} ) {
            my $wall = {n=>"-", s=>"-", e=>"|", w=>"|"}->{$dir};

            return "$color$wall$reset";

        } else {
            return "$color+$reset";
        }

    } else {
        return {n=>"-", s=>"-", e=>"|", w=>"|"}->{$dir};
    }

    return "?"; # this should be visually borked looking.
}
# }}}
# genmap {{{
sub genmap {
    my $this = shift;
    my $opts = shift;
    my $m    = $opts->{_the_map};
    my $g    = $opts->{_the_groups};

    our $nocolor = $opts->{nocolor};

    my @above    = ();
    my $map      = "[m"; $map = "" if $nocolor;
    my $rooms    = "";
       $rooms   .= "$_->{name} $_->{loc_size}\n" for (grep /^room$/, @$g);

    for my $i (0 .. $#$m) {
        my $p     = $1 if $i =~ m/(\d)$/;
        my $jend  = $#{ $m->[$i] };

        unless( $i ) {
            $map .= "  ";
            for my $j (0 .. $jend) {
                my $p = $1 if $j =~ m/(\d)$/;

                $map .= " $p";
            }
            $map .= " \n";
        }

        $map .= "  ";
        for my $j (0 .. $jend) {
            my $tile = $m->[$i][$j];

            $opts->{t_cb}->() if exists $opts->{t_cb};

            if( my $type = $tile->{type} ) {
                $map .= " " . $this->_show_by_od($tile, "n");
                $map .= " " if $j == $jend;

            } elsif( $above[$j] ) {
                $map .= " " . $this->_show_by_od($above[$j], "s");
                $map .= " " if $j == $jend;

            } else {
                $map .= ($j == $jend ? "   " : "  ");
            }
        }
        $map .= "\n$p ";

        for my $j (0 .. $jend) {
            my $tile  = $m->[$i][$j];

            if( my $type = $tile->{type} ) {
                $map .= $this->_show_by_od($tile, "w") . ".";
                $map .= $this->_show_by_od($tile, "e") if $j == $jend;
                $above[$j] = $tile;

            } elsif( $j>0 and $above[$j-1] ) {
                $map .= $this->_show_by_od($above[$j-1], "e") . " ";
                $map .= " " if $j == $jend;
                $above[$j] = undef;

            } else {
                $above[$j] = undef;
                $map .= ($j == $jend ? "   " : "  ");
            }
        }
        $map .= "\n";

        if( $i == $#$m ) {
            $map .= "  ";
            for my $j (0 .. $jend) {
                my $tile  = $m->[$i][$j];

                if( my $type = $tile->{type} ) {
                    $map .= " " . $this->_show_by_od($tile, "s");
                    $map .= " " if $j == $jend;

                } elsif( $above[$j] ) {
                    $map .= " " . $this->_show_by_od($above[$j], "s");
                    $map .= " " if $j == $jend;

                } else {
                    $map .= ($j == $jend ? "   " : "  ");
                }
            }
            $map .= "\n";
        }

    }

    return $map . $rooms;
}
# }}}

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::RolePlay::MapGen::Exporter::Text - A pure text mapgen exporter.

=head1 SYNOPSIS

    use Games::RolePlay::MapGen;

    my $map = new Games::RolePlay::MapGen;
    
    $map->set_exporter( "Text" );

    generate  $map;
    export    $map( "filename.txt" );

=head1 DESCRIPTION

This is how they'd look in a rogue-like... Unfortunately, this design won't
work with a cell based map... It'll have to look more like that below.

                 #.#         #.#  
                 #.#         #.#  
    ##############+###########+#########
    ....................................
    ##############+###########+#########
               #.....#       #.#
               #.....#       #.#
               #.....#       #.#########
               #######       #..........
                             ###########

Sadly, since every cell has up to 4 exits and adjacent cells aren't necessarilly open to eachother, 
the text based map has to have a little more space init.

                 |.|             |.| 
                   
                 |.|             |.| 
    - - - - - - - + - - - - - - - + - - - 
    . . . . . . . . . . . . . . . . . . .
    - - - - - - - + - - - - - - - + - - - 
             |. . . . .|         |.|

             |. . . . .|         |.|
                                    - - -
             |. . . . .|         |. . . .
              - - - - -           - - - - 

Also, there's really no good visual way to show what kind of door we're looking at.  I've chosen to use ANSI colors.

    brown   - a door
    red     - locked
    blue    - stuck
    magenta - locked and stuck

=head1 SEE ALSO

Games::RolePlay::MapGen

=cut
