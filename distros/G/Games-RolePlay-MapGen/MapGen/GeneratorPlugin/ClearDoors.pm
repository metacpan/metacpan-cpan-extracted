# vi:tw=0 syntax=perl:

package Games::RolePlay::MapGen::GeneratorPlugin::BasicDoors;

use common::sense;
use Carp;

1;

# new {{{
sub new {
    my $class = shift;
    my $this  = [qw(post)]; # you have to be the types of things you hook

    return bless $this, $class;
}
# }}}
# post {{{
sub post {
    my $this   = shift;
    my $opts   = shift;
    my $map    = shift;
    my $groups = shift;

    for my $i ( 0 .. $#$map ) {
        my $jend = $#{ $map->[$i] };

        for my $j ( 0 .. $jend ) {
            my $t = $map->[$i][$j];

            $t->{od} = 1 if ref $t->{od};
        }
    }
}
# }}}

__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Games::RolePlay::MapGen::GeneratorPlugin::ClearDoors - Remove all doors from a map.

=head1 SYNOPSIS

    use Games::RolePlay::MapGen;

    my $map = new Games::RolePlay::MapGen;
    
    $map->add_generator_plugin( "ClearDoors" );

    # (NOTE: this is really intended to be used from the GRM Editor.)

=head1 DESCRIPTION

This module removes all the doors from a map.

=head1 SEE ALSO

Games::RolePlay::MapGen

=cut
