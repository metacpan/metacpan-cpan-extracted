# vi:tw=0 syntax=perl:

package Games::RolePlay::MapGen::Generator::Blank;

use common::sense;
use Carp;
use parent 'Games::RolePlay::MapGen::Generator';
use Games::RolePlay::MapGen::Tools qw( _tile );

1;

sub create_tiles {
    my $this = shift;
    my $opts = shift;
    my @map  = ();

    for my $i (0 .. $opts->{y_size}-1) {
        my $a = [];

        for my $j (0 .. $opts->{x_size}-1) {
            $opts->{t_cb}->() if exists $opts->{t_cb};

            push @$a, &_tile(x=>$j, y=>$i);
        }

        push @map, $a;
    }

    return @map;
}

sub genmap {
    my $this   = shift;
    my $opts   = shift;
    my @map    = $this->create_tiles( $opts );
    my $map    = new Games::RolePlay::MapGen::_interconnected_map(\@map);
    my $groups = [];

    return ($map, $groups);
}

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::RolePlay::MapGen::Generator::Blank - The basic random bounded dungeon generator

=head1 SYNOPSIS

    use Games::RolePlay::MapGen;

    my $map = new Games::RolePlay::MapGen;
    
    $map->set_generator( "Blank" );

    generate $map;

=head1 DESCRIPTION

This module generates an empty map.

=head1 SEE ALSO

Games::RolePlay::MapGen

=cut
