package Games::Lacuna::Task::Action::StarCacheReport;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose -traits => 'NoAutomatic';
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::Stars);

use Games::Lacuna::Task::Table;

sub description {
    return q[Report the star cache status];
}
sub run {
    my ($self) = @_;
    
    my $planet_stats = $self->my_body_status($self->home_planet_id);
    
    my $table = Games::Lacuna::Task::Table->new({
        columns     => ['State','Count','Min Distance','Max Distance','Avg Distance'],
    });
    
    my @states = (
        ['probed','is_probed = 1'],
        ['unprobed','is_probed = 0'],
        ['unknown','is_probed IS NULL'],
    );
    
    my $total = 0;
    
    foreach my $state (@states) {
        
        my ($count,$min,$max,$avg) = $self->client->storage_selectrow_array('SELECT 
                COUNT(1),
                MIN(distance_func(?,?,x,y)),
                MAX(distance_func(?,?,x,y)),
                AVG(distance_func(?,?,x,y))
            FROM star
            WHERE '.$state->[1],
            $planet_stats->{x},
            $planet_stats->{y},
            $planet_stats->{x},
            $planet_stats->{y},
            $planet_stats->{x},
            $planet_stats->{y},
        );
        
        $table->add_row({
            state           => $state->[0],
            count           => ($count || 0),
            min_distance    => ($min // 0),
            max_distance    => ($max // 0),
            avg_distance    => sprintf('%i',$avg),
        });
        
        $total += $count;
    }
    
    $table->add_row({
        state   => 'total',
        count   => $total
    });
    
    say $table->render_text;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;
