# vi:tw=0 syntax=perl:

# package ::_interconnected_map {{{
package Games::RolePlay::MapGen::_disallow_autoviv;

use common::sense;
use Tie::Array;
use parent -norequire => 'Tie::StdArray';
use Carp;

1;

sub TIEARRAY {
    my $class = shift;
    my $this  = bless [], $class;
    my $that  = shift;

    @$this = @$that;

    $this;
}

sub FETCH {
    my $this = shift;
    
    croak "autovivifing new rows and columns is disabled ($_[0]>$#$this)" if $_[0] > $#$this;

    $this->SUPER::FETCH(@_);
}

package Games::RolePlay::MapGen::_interconnected_map;

use common::sense;
use Carp;

1;

# interconnect_map {{{
sub interconnect_map {
    my $map = shift;

    # This interconnected array stuff is _REALLY_ handy, but it needs to be cleaned up, so it gets it's own class

    for($map, @$map) {
        my @a;
        tie @a, "Games::RolePlay::MapGen::_disallow_autoviv", $_;
        $_ = \@a;
    }

    for my $i (0 .. $#$map) {
        my $jend = $#{ $map->[$i] };

        for my $j (0 .. $jend) {
            $map->[$i][$j]->{nb} = {}; # clear it all out
            $map->[$i][$j]->{nb}{s} = $map->[$i+1][$j] unless $i == $#$map;
            $map->[$i][$j]->{nb}{n} = $map->[$i-1][$j] unless $i == 0;
            $map->[$i][$j]->{nb}{e} = $map->[$i][$j+1] unless $j == $jend;
            $map->[$i][$j]->{nb}{w} = $map->[$i][$j-1] unless $j == 0;
        }
    }

    # check
    for my $y (0 .. $#$map) {
        for my $x (0 .. $#{ $map->[$y] }) {
            for my $d (qw(n e s w)) {
                my $o = {n=>"s", s=>"n", e=>"w", w=>"e"}->{$d};

                my $t = $map->[$y][$x];
                my $n = $t->{nb}{$d};

                next unless $n;

                warn "od issues with ($x, $y):$d-$o" unless $t->{od}{$d} == $n->{od}{$o};
                warn "nb issues with ($x, $y):$d-$o" unless $n->{nb}{$o} == $t;
            }
        }
    }
}
# }}}
# disconnect_map {{{
sub disconnect_map {
    my $map = shift;

    local $@;

    eval {
        untie @$_ for grep {tied $_} @$map;
        untie @$map if tied $map;

        for my $i (0 .. $#$map) {
            my $jend = $#{ $map->[$i] };

            for my $j (0 .. $jend) {
                # Destroying the map wouldn't destroy the tiles if they're self
                # referencing like this.  That's not a problem because of the
                # global destructor, *whew*; except that each new map generated,
                # until perl exits, would eat up more memory.  

                delete $map->[$i][$j]{nb}; # So we have to break the self-refs here.
            }
        }
    };

    if( $@ ) {
        # NOTE: The above emits a fatal under global destruction for some
        # reason, probably the bless+tie gets cleaned up in the wrong order or
        # something.  It doesn't really matter since we're already exiting perl
        # anyway.  This assumption may be false under win32, where it may
        # create a memory leak.  Does windows clean up when a process exits?
        # It really aught to, but I have my doubts.

        die $@ unless $@ =~ m/global destruction/;
    }

    # You can test to make sure the tiles are dying when a map goes out of
    # scope by setting the VERBOSE_TILE_DEATH environment variable to a true
    # value.  If they fail to die when they go out of scope, it would say so on
    # the warning line.  If you'd really really like to see that, change the
    # {nb} above to {nb_borked} and you'll see what I mean.

    # Lastly, if you'd like to read a lengthy dissertation on this subject,
    # search for "Two-Phased" in the perlobj man page.
}
# }}}
# new {{{
sub new {
    my $class = shift;
    my $arg   = shift;
    my $map   = bless $arg, $class;

    $map->interconnect_map; # also used by save_map()

    return $map;
}
# }}}
# DESTROY {{{
sub DESTROY {
    my $map = shift;

    $map->disconnect_map; # also used by save_map()
}
# }}}

# }}}
# package ::_group; {{{
package Games::RolePlay::MapGen::_group;

use common::sense;

1;

# new {{{
sub new {
    my $class = shift;
    my $this  = bless {name=>"?", type=>"?", loc=>[], size=>[], loc_size=>"n/a"}, $class;

    if( @_ ) {
        my $h = {@_};
        $this->{name} = $h->{name} if exists $h->{name};
        $this->{type} = $h->{type} if exists $h->{type};
    }

    $this
}
# }}}
# name {{{
sub name {
    my $this = shift;
       $this->{name} = $_[0] if @_;

    $this->{name};
}
# }}}
# type {{{
sub type {
    my $this = shift;
       $this->{type} = $_[0] if @_;

    $this->{type};
}
# }}}
# desc {{{
sub desc {
    my $this = shift;

    $this->{loc_size};
}
# }}}
# add_rectangle {{{
sub add_rectangle {
    my $this = shift;
    my $loc  = shift;
    my $size = shift;
    my $mapo = shift;

    if( $loc and $size ) {
        push @{$this->{loc}},  $loc;
        push @{$this->{size}}, $size;
    }

    my @i = map  { $_->[0] }
            sort { $b->[1]<=>$a->[2] }
            map  { my $t = $this->{size}[$_]; [$_, $t->[0]*$t->[1]] }
            0 .. $#{$this->{loc}};

    my @to_kill; # remove these, they don't say anything
    my %points;  # don't count the same tiles over and over
    my $sloc    = [0,0];
    my $mloc    = [@{$this->{loc}[0]}];
    my $Mloc    = [@{$this->{loc}[0]}];
    my $nloc    = 0;
    for my $i (@i) {
        my $l = $this->{loc}[$i];
        my $s = $this->{size}[$i];

        my $x = $l->[0];
        my $y = $l->[1];

        my $i_count = 0;

        for my $xi (0 .. $s->[0]-1) {
        for my $yi (0 .. $s->[1]-1) {
            my $xc = $x + $xi;
            my $yc = $y + $yi;

            unless( $points{$xc}{$yc} ) {
                $points{$xc}{$yc} = 1;
                $i_count ++;

                $sloc->[0] += $xc;
                $sloc->[1] += $yc;
                $nloc ++;

                $mloc->[0] = $xc if $xc < $mloc->[0];
                $mloc->[1] = $yc if $yc < $mloc->[1];
                $Mloc->[0] = $xc if $xc > $Mloc->[0];
                $Mloc->[1] = $yc if $yc > $Mloc->[1];

                $mapo->[ $yc ][ $xc ]{group} = $this if $mapo;
            }

        }}

        push @to_kill, $i unless $i_count>0;
    }

    for my $kill (sort {$b<=>$a} @to_kill) {
        splice @{$this->{loc}},  $kill, 0;
        splice @{$this->{size}}, $kill, 0;
    }

    my $cloc = [0,0]; 
       $cloc = [ int($sloc->[0]/$nloc),  int($sloc->[1]/$nloc) ] if $nloc > 0;

    my $extent = [ $Mloc->[0]-$mloc->[0]+1, $Mloc->[1]-$mloc->[1]+1 ];

    $this->{loc_size} = "($cloc->[0], $cloc->[1]) $extent->[0]x$extent->[1]";
    $this->{extents}  = [ @$mloc, @$Mloc ];
}
# }}}
# enumerate_tiles {{{
sub enumerate_tiles {
    my $this = shift;

    my @i = map  { $_->[0] }
            sort { $b->[1]<=>$a->[2] }
            map  { my $t = $this->{size}[$_]; [$_, $t->[0]*$t->[1]] }
            0 .. $#{$this->{loc}};

    my @ret;
    my %points;  # don't count the same tiles over and over
    for my $i (@i) {
        my $l = $this->{loc}[$i];
        my $s = $this->{size}[$i];

        my $x = $l->[0];
        my $y = $l->[1];

        for my $xi (0 .. $s->[0]-1) {
        for my $yi (0 .. $s->[1]-1) {
            my $xc = $x + $xi;
            my $yc = $y + $yi;

            unless( $points{$xc}{$yc} ) {
                $points{$xc}{$yc} = 1;

                push @ret, [$xc,$yc];
            }

        }}
    }

    @ret;
}
# }}}
# enumerate_extents {{{
sub enumerate_extents {
    my $this = shift;

    @{ $this->{extents} };
}
# }}}

# }}}
# package ::_tile; {{{
package Games::RolePlay::MapGen::_tile;

use common::sense;

1;

sub dup {
    my $that  = shift;
    my $class = $that->{__c};
    my $this  = bless {od=>{n=>1, s=>1, e=>1, w=>1}}, $class;

    $this->{$_}     = $that->{$_}     for grep {not ref $that->{$_}} keys %$that;
    $this->{od}{$_} = $that->{od}{$_} for keys %{ $that->{od} };
    $this->{group}  = $that->{group};
    $this->{_dup} = 1;

    return $this;
}

sub new { my $class = shift; bless { @_, __c=>$class, v=>0, od=>{n=>0, s=>0, e=>0, w=>0} }, $class }
sub DESTROY { warn "tile verbosely dying" if $ENV{VERBOSE_TILE_DEATH} }  # search for VERBOSE above...
# }}}
# package ::_door; {{{
package Games::RolePlay::MapGen::_door;

use common::sense;

1;

sub new {
    my $class = shift; 
    my $this  = bless { @_ }, $class; 

    $this->{locked}   = 0 unless $this->{locked};
    $this->{stuck}    = 0 unless $this->{stuck};
    $this->{secret}   = 0 unless $this->{secret};
    $this->{open_dir} = { major=>undef, minor=>undef } unless ref($this->{open_dir});
    $this->{'open'}   = 0 unless $this->{'open'};

    return $this;
}

# }}}

package Games::RolePlay::MapGen::Tools;

use common::sense;
use Carp;
use parent q(Exporter);

our @EXPORT_OK = qw(choice roll random irange range str_eval _group _tile _door);

1;

# helper functions
# choice {{{
sub choice {
    return $_[&random(int @_)] || "";
}
# }}}
# roll {{{
sub roll {
    my ($num, $sides) = @_;
    my $roll = 0; 
    
    $roll += int rand $sides for 1 .. $num;
    $roll += $num;

    return $roll;
}
# }}}
# random {{{
sub random {
    return int rand shift;
}
# }}}
# range {{{
sub range {
    my $lhs = shift;
    my $rhs = shift;
    my $correlation = shift;

    ($lhs, $rhs) = ($rhs, $lhs) if $rhs < $lhs;

    my $rand;
    if( $correlation ) {
        croak "correlated range without previous value!!" unless defined $global::last_rand;

        if( $correlation == 1 ) {
            $rand = $global::last_rand;

        } elsif( $correlation == -1 ) {
            $rand = 1000000.0 - $global::last_rand;

        } else {
            croak "unsupported correlation value";
        }

    } else {
        $rand = rand 1000000.0;
        $global::last_rand = $rand;

    }

    $rand /= 1000000.0;

    my $diff = $rhs  - $lhs;
       $rand = $rand * $diff;

    return $lhs + $rand;
}
# }}}
# irange {{{
sub irange {
    my $il = shift;
    my $ir = shift;

    $il -= 0.4999999999;
    $ir += 0.4999999999;

    my $s = sprintf('%0.0f', range($il, $ir, @_));

    $s = 0 if $s eq "-0";

    return $s;
}
# }}}
# str_eval {{{
sub str_eval {
    my $str = shift;

    return int $str if $str =~ m/^\d+$/;

    $str =~ s/^\s*(\d+)d(\d+)\s*$/&roll($1, $2)/eg;
    $str =~ s/^\s*(\d+)d(\d+)\s*([\+\-])\s*(\d+)$/&roll($1, $2) + ($3 eq "+" ? $4 : 0-$4)/eg;

    return undef if $str =~ m/\D/;
    return int $str;
}
# }}}

sub _group { return new Games::RolePlay::MapGen::_group(@_) }
sub _tile  { return new Games::RolePlay::MapGen::_tile(@_) }
sub _door  { return new Games::RolePlay::MapGen::_door(@_) }

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::RolePlay::MapGen::Tools - Some support tools and objects for the mapgen suite

=head1 SYNOPSIS

    use Games::RolePlay::MapGen::Tools qw( choice roll random range str_eval );

    my $r1 = roll(1, 20);                   # 1d20, 1-20
    my $r2 = random(20);                    # 0-19
    my $r3 = range(50, 100);                # some number between 50 and 100 (not an integer!)
    my $r4 = range(9000, 10000, 1);         # 100% positively correlated with the last range (ie, not random at all)
    my $r5 = range(7, 12, -1);              # 100% negatively correlated with the last range (ie, not random at all)
    my $ri = irange(0, 7);                  # An integer between 0 and 7
    my $e  = choice(qw(test this please));  # picks one of test, this, and please at random
    my $v  = str_eval("1d8");               # returns int(roll(1,8)) -- returns undef on parse error

    # This package also exports _group and _tile, which are shortcut functions for new
    # Games::RolePlay::MapGen::_tile and ::_group objects.

=head1 Games::RolePlay::MapGen::_group

At this time, the ::_group object is just a blessed hash that contains some
variables that need to be set by the ::Generator objects.

   ## 1.0.3 ## $group->{name}     = "Room #$rn";
   ## 1.0.3 ## $group->{loc_size} = "$size[0]x$size[1] ($spot[0], $spot[1])";
   ## 1.0.3 ## $group->{type}     = "room";
   ## 1.0.3 ## $group->{size}     = [@size];
   ## 1.0.3 ## $group->{loc}      = [@spot];

   # Starting with 1.1.0, rooms can have irregular shapes made up of
   # rectangles.  The rectangles start at @start = @{$group->{loc}[$i]} and
   # have @size = @{$group->{size}[$i]}.

   $group->{name} = "Room #$rn";
   $group->{type} = "room";
   $group->{loc}  = [\@spot, \@another_spot, ...];
   $group->{size} = [\@size, \@another_size, ...];

   # The loc_size description became problematic in 1.1.x.  It will now
   # indicate the maximum extent (x-diff x y-diff) and the "center of mass"
   # (average location).

   $group->{loc_size} = "($center[0], $center[1]) $extent[0]x$extent[1]";

   Happily, there is a new method to add a rectangle that does all the work:

   $group->add_rectangle(\@loc, \@size);

   If you pass the map object, it will mark the appropriate tiles its $self

   $group->add_rectangle(\@loc, \@size, $the_map);
    # marks $mapo->[ $y ][ $x ]{group} = $group;
    # (can be called without arguments to recalculate {loc_size})

   # There is also a new $group->{extents}, which describes the min and max
   # locations.  They are really only useful for truely rectangular rooms.

   # These new methods can be used to access the group's tiles and extents:
   my @tiles   = $group->enumerate_tiles;
   my @extents = $group->enumerate_extents;

   # lastly,
   my $desc = $group->desc; # returns the {loc_size} calculated by add_rectangle

=head1 Games::RolePlay::MapGen::_tile

At this time, the ::_tile object is just a blessed hash that the
::Generators instantiate at every map location.  There are no required
variables at this time.

    v=>0, 
    od=>{n=>0, s=>0, e=>0, w=>0}

Though, for convenience, visited is set to 0 and "open directions" is set to
all zeros.

=head1 Games::RolePlay::MapGen::_interconnected_map

This object interconnects all the tiles in a map array, so 
$tile = $map->[$y][$x] and $tile->{nb} is an array of neighboring tiles.
Example: $east_neighbor = $map->[$y][$x]->{nb}{e};

(It also cleans up self-referencing loops at DESTROY time.)

=head1 Games::RolePlay::MapGen::_door

A simple object that stores information about a door.  Example:

    my $door = &_door(
        stuck    => 0,
        locked   => 0,
        secret   => 0,
        open_dir => {
            major => "n", # the initial direction of the opening door
            minor => "w", # the final direction of the opening door (think 90 degree swing)
        },
    );

    print "The door is locked.\n" if $door->{locked};

=head1 AUTHOR

Jettero Heller <japh@voltar-confed.org>

Jet is using this software in his own projects...
If you find bugs, please please please let him know. :)

Actually, let him know if you find it handy at all.
Half the fun of releasing this stuff is knowing 
that people use it.

=head1 COPYRIGHT

Copyright (c) 2008 Paul Miller -- LGPL [Software::License::LGPL_2_1]

    perl -MSoftware::License::LGPL_2_1 -e '$l = Software::License::LGPL_2_1->new({holder=>"Paul Miller"});
          print $l->fulltext' | less

=head1 SEE ALSO

perl(1)

=cut
