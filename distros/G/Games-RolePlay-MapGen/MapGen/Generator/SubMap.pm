# vi:tw=0 syntax=perl:

package Games::RolePlay::MapGen::Generator::SubMap;

use common::sense;
use Carp;
use parent q(Games::RolePlay::MapGen::Generator);
use Games::RolePlay::MapGen::Tools qw( _group _tile _door );

1;

sub genmap {
    my $this = shift;
    my $opts = shift;

    my $map    = [];
    my $groups = [];

    my @X = ( sort {$a<=>$b} ($opts->{upper_left}[0], $opts->{lower_right}[0]) );
    my @Y = ( sort {$a<=>$b} ($opts->{upper_left}[1], $opts->{lower_right}[1]) );

    my $smap = $opts->{map_input}{_the_map};

    $opts->{$_} = $opts->{map_input}{$_} for qw(tile_size cell_size);
    $opts->{x_size} = my $xs = 2+($X[1]-$X[0])+1;
    $opts->{y_size} = my $ys = 2+($Y[1]-$Y[0])+1;
    $opts->{bounding_box} = $xs . "x" . $ys;

    for my $x ( 0 .. $xs-1 ) { my $y = 0;     $map->[ $y ][ $x ] = &_tile( x=>$x, y=>$y, type=>'fog' );
                                  $y = $ys-1; $map->[ $y ][ $x ] = &_tile( x=>$x, y=>$y, type=>'fog' ); }

    for my $y ( 1 .. $ys-2 ) { my $x = 0;     $map->[ $y ][ $x ] = &_tile( x=>$x, y=>$y, type=>'fog' );
                                  $x = $xs-1; $map->[ $y ][ $x ] = &_tile( x=>$x, y=>$y, type=>'fog' ); }

    ## DEBUG ## # disable mistakes:
    ## DEBUG ## tie @$_, "Games::RolePlay::MapGen::_disallow_autoviv", $_ for $map, @$map;

    for my $x1 ( $X[0] .. $X[1] ) { my $x2 = 1 + ($x1-$X[0]);
    for my $y1 ( $Y[0] .. $Y[1] ) { my $y2 = 1 + ($y1-$Y[0]);
        my $otile = $smap->[ $y1 ][ $x1 ];

        my $ntile = $map->[ $y2 ][ $x2 ] = &_tile( x=>$x2, y=>$y2, (exists $otile->{type} ? (type=>$otile->{type}) :()) );
        for my $d (qw(n e s w)) {
            my $ood = $otile->{od}{$d};

            my @ops = ($x2,$y2);
               $ops[0] ++ if $d eq "e";
               $ops[0] -- if $d eq "w";
               $ops[1] ++ if $d eq "s";
               $ops[1] -- if $d eq "n";

            ## DEBUG ## do { local $" = ","; warn "($x2,$y2):$d -> (@ops)" };

            my $opp = $Games::RolePlay::MapGen::opp{$d};
            if( my $nt = $map->[ $ops[1] ][ $ops[0] ] ) {
                if( ref $ood ) {
                    $nt->{od}{$opp} = $ntile->{od}{$d} = &_door(
                        map {($_ => $ood->{$_})} qw(locked stuck secret open),
                        open_dir => { map {($ood->{open_dir}{$_})} qw(major minor) },
                    );

                } elsif($ood) {
                    $nt->{od}{$opp} = $ntile->{od}{$d} = 1;
                }
            }
        }
    }}

    $map = new Games::RolePlay::MapGen::_interconnected_map( $map );
     
    for my $row (@$map) {
        for my $tile (@$row) {
            next unless $tile and exists $tile->{type} and $tile->{type} eq "fog";
            for my $d (qw(n w)) {
                if( my $n = $tile->{nb}{$d} ) {
                    next unless $n and exists $n->{type} and $n->{type} eq "fog";
                    my $o = $Games::RolePlay::MapGen::opp{$d};
                    $n->{od}{$o} = $tile->{od}{$d} = 1;
                }
            }
        }
    }

    return ($map, $groups);
}

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::RolePlay::MapGen::Generator::SubMap - Given a MapGen object and some co-ordinates, generate a sub-map

=head1 SYNOPSIS

    use Games::RolePlay::MapGen;

    my $map = new Games::RolePlay::MapGen;
       $map->set_generator( "XMLImport" );
       $map->generate( xml_input_file => "map.xml" );

    my $sub_map = new Games::RolePlay::MapGen;
       $sub_map->set_generator( "SubMap" );
       $sub_map->generate( map_input => $map, upper_left=>[5,5], lower_right=>[10,10] );

The MapGen base object also knows a shortcut to perform the above:

    my $submap = Games::RolePlay::MapGen->sub_map($map, [5,5], [10,10]);

=head1 SEE ALSO

Games::RolePlay::MapGen

=cut
