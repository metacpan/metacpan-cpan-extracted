use strict;
use Test;
use Games::RolePlay::MapGen;
use Games::RolePlay::MapGen::MapQueue;
use Data::Dumper; $Data::Dumper::Indent = $Data::Dumper::Sortkeys = 1;

my @POI = sort {(rand)<=>(rand)} ([0,0], [3,7], [11,9], [11,19], [34,6], [21,17], [33,23]);
   @POI = @POI[ 0 .. 1 ];

my $map = new Games::RolePlay::MapGen;
   $map->set_generator( "XMLImport" ); print STDERR " [xml]";
   $map->generate( xml_input_file => "vis1.map.xml" ); 

my $queue = new Games::RolePlay::MapGen::MapQueue( $map );

@POI = $queue->all_open_locations if $ENV{MASSIVE_COMPLETE};
print STDERR " MASSIVE_COMPLETE=1 for *long* test" unless $ENV{MASSIVE_COMPLETE};
   
# count {{{
for my $loc ($queue->all_open_locations) {
    for my $dir (qw(n e s w)) {
        if( $queue->is_door( @$loc, $dir ) and not $queue->is_door_open( @$loc, $dir ) ) {
            $queue->open_door( @$loc, $dir );
        }
    }
}

my @pairs;
my $ipoi = int @POI;

if( -f "$ipoi.vis1.ap" ) {
    print STDERR " [loading pairs]";
    eval "use Storable qw(retrieve)";
    my $ar = eval 'retrieve("$ipoi.vis1.ap")'; die $@ if $@;
    @pairs = @$ar;

} else {
    my $c = 0;
    print STDERR " [gen pairs]";
    for my $lhs (@POI) { $c ++;
        our $lp = 0 unless defined $lp;
        my $p = int (100*($c/(int @POI)));

        if( $p =~ m/0$/ and $p ne $lp ) {
            print STDERR " $p%" if $p =~ m/0$/;
            $lp = $p;
        }

        for my $rhs ($queue->_locations_in_line_of_sight($lhs)) {
            next if "@$lhs" eq "@$rhs";
            push @pairs, [$lhs=>$rhs];
        }
    }

    eval "use Storable qw(store)";
    unless( $@ ) {
        eval 'store(\@pairs, "$ipoi.vis1.ap")'; die $@ if $@;
    }
}

my $count = int @pairs;

print STDERR " [pairs=$count]";

# }}}

plan tests => 3*$count;

# distance {{{
sub distance {
    my ($p1, $p2) = @_;

    return sqrt( (($p2->[0]-$p1->[0])**2) + (($p2->[1]-$p1->[1])**2) );
}
# }}}
# is_actually_open {{{
sub is_actually_open {
    my ($p1, $p2) = @_;
    my $p1_tile = $map->{_the_map}[ $p1->[1] ][ $p1->[0] ];

    if( $p1->[0] == $p2->[0] ) {
        if( $p1->[1] < $p2->[1] ) {
            my $o = $p1_tile->{od}{s}; $o = $o->{'open'} if ref $o;
            return $o;

        } else {
            my $o = $p1_tile->{od}{n}; $o = $o->{'open'} if ref $o;
            return $o;
        }

    } elsif( $p1->[1] == $p2->[1] ) {
        if( $p1->[0] < $p2->[0] ) {
            my $o = $p1_tile->{od}{e}; $o = $o->{'open'} if ref $o;
            return $o;

        } else {
            my $o = $p1_tile->{od}{w}; $o = $o->{'open'} if ref $o;
            return $o;
        }

    } else {
        my @d = (
            ($p1->[0] < $p2->[0] ? 'e' : 'w'),
            ($p1->[1] < $p2->[1] ? 's' : 'n'),
        );

        my $o;
        if( $o = $p1_tile->{od}{$d[0]} ) {
            $o = $o->{'open'} if ref $o;

            if( $o ) {
                if( $o = $p1_tile->{nb}{$d[0]}{od}{$d[1]} ) {
                    $o = $o->{'open'} if ref $o;
                    return 1 if $o;
                }
            }
        }

        if( $o = $p1_tile->{od}{$d[1]} ) {
            $o = $o->{'open'} if ref $o;

            if( $o ) {
                if( $o = $p1_tile->{nb}{$d[1]}{od}{$d[0]} ) {
                    $o = $o->{'open'} if ref $o;
                    return 1 if $o;
                }
            }
        }
    }

    return 0; # FAIL!
}
# }}}

warn "\n";
PAIR: for my $pair (sort { (rand)<=>(rand) } @pairs) {
    my @path = $queue->_locations_in_path(@$pair);

    my $ok = 1;
    PATH: for my $i (0 .. $#path-1) {
        my ($p1, $p2) = @path[$i, $i+1];

        if( &distance($p1, $p2) > 1.4142135623731 ) {
            warn " while plotting (@{$pair->[0]})->(@{$pair->[1]}), |(@$p1)->(@$p2)| is too long\n";
            ok( 0 );
            $ok = 0;

            our $fail ++;
            die "that's too many failures to bother continuing" if $fail > 15;
            last PATH;
        }
    }

    ok( $ok );

    $ok = 1;
    OPEN_DIRECTION: for my $i (0 .. $#path-1) {
        my ($p1, $p2) = @path[$i, $i+1];

        if( "@$p1" =~ m/\./ or "@$p2" =~ m/\./ ) {
            die "\n path has floating point tile numbers \n" . Dumper(\@path) . "\n\n";
        }

        unless( &is_actually_open($p1, $p2) ) {
            warn " while plotting (@{$pair->[0]})->(@{$pair->[1]}), (@$p1)->(@$p2) seems to go through a wall\n";
            ok( 0 );
            $ok = 0;

            our $fail ++;
            die "that's too many failures to bother continuing" if $fail > 15;
            last OPEN_DIRECTION;
        }
    }

    ok( $ok );

    my @lhs1 = @{$pair->[0]};
    my @rhs1 = @{$pair->[1]};
    my @lhs2 = @{$path[0]};
    my @rhs2 = @{$path[$#path]};

    ENDPOINTS: if( "@lhs1" ne "@lhs2" or "@rhs1" ne "@rhs2" ) {
        warn " pair (@lhs1)->(@rhs1) != path endpoints (@lhs2)->(@rhs2)\n";
        ok( 0 );

        our $fail ++;
        die "that's too many failures to bother continuing" if $fail > 15;

    } else {
        ok(1)
    }
}
