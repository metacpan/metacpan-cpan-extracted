package Games::Lacuna::Task::Action::EmpireCache;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose -traits => 'NoAutomatic';
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::Stars);

use Games::Lacuna::Task::Utils qw(normalize_name parse_date);

our $MAX_EMPIRE_CACHE_TIME = 60 * 60 * 24 * 31 * 3;

sub description {
    return q[Build the empire info cache];
}

sub run {
    my ($self) = @_;
    
    $self->query_empire_stats();
    $self->query_species_affinity();
}

sub query_species_affinity {
    my ($self) = @_;

    foreach my $planet_stats ($self->my_planets) {
        my $library = $self->find_building($planet_stats,'LibraryOfJith');
        
        next
            unless defined $library;
        
        $self->log('debug','Found Library of Jith at %s',$planet_stats->{name}); 

        return $self->query_library($library);
    }

    $self->log('debug','Could not find Library of Jith to query species affinity');
}

sub query_library {
    my ($self,$library) = @_;

    my $library_object = $self->build_object($library);

    $self->log('info','Fetching species affinities');

    my $sth = $self->storage_prepare('SELECT id,name
        FROM empire 
        WHERE affinity IS NULL 
        OR last_checked < ?');
    
    $sth->execute(time - $MAX_EMPIRE_CACHE_TIME);

    while (my ($id,$name) = $sth->fetchrow_array) {
        my $response = $self->request(
            object  => $library_object,
            method  => 'research_species',
            params  => [$id],
        );
        
        unless (defined $response->{species}) {
            $self->log('warn','Empire %s not found',$name);
            $self->remove_empire($id);
            next;
        }

        $self->storage_do('UPDATE empire SET affinity = ? WHERE id = ?',$response->{species},$id);
    }
}

sub query_empire_stats {
    my ($self) = @_;

    $self->log('info','Fetching empire stats');

    my $sth = $self->storage_prepare('SELECT id,name,level
        FROM empire 
        WHERE last_checked IS NULL 
        OR last_checked < ?');
    
    $sth->execute(time - $MAX_EMPIRE_CACHE_TIME);

    my $empire_object = $self->build_object('Empire');

    while (my ($id,$name,$level) = $sth->fetchrow_array) {
        my $response = $self->request(
            object      => $empire_object,
            method      => 'view_public_profile',
            params      => [ $id ],
            catch       => [
                [
                    '1002',
                    'The empire you wish to view does not exist.',
                    sub {
                        $self->remove_empire($id,$name);
                        return 0;
                    },
                ],
            ],
        );
        
        next
            unless defined $response;

        my $empire_data = $response->{profile};

        $level //= 1;
        foreach my $medal (values %{$empire_data->{medals}}) {
            if ($medal->{image} =~ m/^building(\d+)$/) {
                $level = $1
                    if ($1 > $level);
            }
            # TODO get level based on ships and buildings
            # TODO calculate threat level based on num of ships
        }
 
        my %update = (
            name            => $empire_data->{name},
            normalized_name => normalize_name($empire_data->{name}),
            alliance        => (defined $empire_data->{alliance} ? $empire_data->{alliance}{id} : undef),
            colony_count    => $empire_data->{colony_count},
            date_founded    => parse_date($empire_data->{date_founded}),
            level           => $level,
            last_checked    => time(),
        );

        my (@pairs,@bind,$pairs);
        foreach my $key (keys %update) {
            push(@pairs,"$key = ?");
            push(@bind,$update{$key});
        }
        $pairs = join(',',@pairs);

        $self->storage_do("UPDATE empire SET $pairs WHERE id = ?",@bind,$id);
    }
}

sub remove_empire {
    my ($self,$id,$name) = @_;

    $self->log('debug','Removing empire %s from cache',$name);
   
    $self->storage_do('DELETE FROM empire WHERE id = ?',$id);
    $self->storage_do('UPDATE body SET empire = NULL WHERE empire = ?',$id);
}
