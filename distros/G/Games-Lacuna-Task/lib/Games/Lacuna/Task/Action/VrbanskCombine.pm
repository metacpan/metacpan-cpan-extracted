package Games::Lacuna::Task::Action::VrbanskCombine;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose;
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::PlanetRun);

use Games::Lacuna::Client::Types qw(ore_types);

our @RECIPIES = (
    [qw(goethite halite gypsum trona)],
    [qw(gold anthracite uraninite bauxite)],
    [qw(kerogen methane sulfur zircon)],
    [qw(monazite fluorite beryl magnetite)],
    [qw(rutile chromite chalcopyrite galena)],
);

has 'keep_gylphs' => (
    isa             => 'Int',
    is              => 'rw',
    required        => 1,
    documentation   => 'Keep N-gylps in storage (do not combine them) [Default: 5]',
    default         => 5,
);

sub description {
    return q[Cobine glyphs to get Halls of Vrbansk plans];
}

sub process_planet {
    my ($self,$planet_stats) = @_;

    # Get archaeology ministry
    my $archaeology_ministry = $self->find_building($planet_stats->{id},'Archaeology');
    
    return
        unless defined $archaeology_ministry;

    # Get all glyphs
    my $archaeology_ministry_object = $self->build_object($archaeology_ministry);
    my $gylph_data = $self->request(
        object  => $archaeology_ministry_object,
        method  => 'get_glyphs',
    );

    my $available_gylphs = { map { $_ => [] } ore_types() };
    
    foreach my $glyph (@{$gylph_data->{glyphs}}) {
        push(@{$available_gylphs->{$glyph->{type}}},$glyph->{id});
    }

    # Sutract keep_glyphs
    foreach my $glyph (keys %$available_gylphs) {
        for (1..$self->keep_gylphs) {
            pop(@{$available_gylphs->{$glyph}});
        }
    }
    
    # Get possible recipies
    RECIPIES: 
    foreach my $recipie (@RECIPIES) {
        while (1) {
            my (@recipie,@recipie_name);
            foreach my $glyph (@{$recipie}) {
                next RECIPIES
                    unless scalar @{$available_gylphs->{$glyph}};
            }
            foreach my $glyph (@{$recipie}) {
                push(@recipie_name,$glyph);
                push(@recipie,pop(@{$available_gylphs->{$glyph}}));
            }
             
            $self->log('notice','Combining glyphs %s',join(', ',@recipie_name));
                       
            $self->request(
                object  => $archaeology_ministry_object,
                method  => 'assemble_glyphs',
                params  => [\@recipie],
            );
        }
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;