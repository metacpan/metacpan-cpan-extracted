package Games::Lacuna::Task::Action::EmpireFind;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose -traits => 'NoAutomatic';
extends qw(Games::Lacuna::Task::Action);
with qw(Games::Lacuna::Task::Role::Stars);

use Games::Lacuna::Task::Utils qw(normalize_name format_date);
use Games::Lacuna::Task::Table;

has 'empire' => (
    is              => 'rw',
    isa             => 'ArrayRef[Str]',
    required        => 1,
    documentation   => 'Empire name you are looking for [Required, Multiple]',
);

sub description {
    return q[Get all available data for a given empire];
}

sub run {
    my ($self) = @_;
    
    my (@query_parts,@query_params);
    foreach my $empire (@{$self->empire}) {
        push(@query_parts,'name = ?');
        push(@query_parts,'normalized_name = ?');
        push(@query_params,$empire);
        push(@query_params,normalize_name($empire));
    }
    
    my $sth_empire = $self->storage_prepare('SELECT 
            id,
            name,
            alignment,
            is_isolationist,
            alliance,
            colony_count,
            level,
            date_founded,
            affinity,
            last_checked
        FROM empire 
        WHERE '.join(' OR ',@query_parts));
    
    my $found = 0;
    $sth_empire->execute(@query_params);
    
    while (my $empire = $sth_empire->fetchrow_hashref) {
        $empire->{affinity} = $Games::Lacuna::Task::Storage::JSON->decode($empire->{affinity})
            if defined $empire->{affinity};
        $self->empire_info($empire);
        $found++;
    }
    
    $self->abort('No empires found')
        unless $found;
}

sub empire_info {
    my ($self,$empire) = @_;
    
    say "-" x $Games::Lacuna::Task::Constants::SCREEN_WIDTH;
    say "Empire ".$empire->{name};
    say "-" x $Games::Lacuna::Task::Constants::SCREEN_WIDTH;
    unless (defined $empire->{colony_count}) {
        say "No empire information available";
        say "Please run 'lacuna_run empire_cache' first";
    } else {
        say "Alliance:        ".($empire->{alliance} ? 'Yes':'No');
        if ($empire->{alliance}) {
            my ($alliance_size,$alliance_avg_level,$alliance_max_level) = $self->client->storage_selectrow_array('SELECT 
                COUNT(1),AVG(level),MAX(level) 
                FROM empire 
                WHERE alliance = ?',$empire->{alliance});
            say "Alliance size:   $alliance_size";
            say "Alliance level:  $alliance_avg_level(avg) / $alliance_max_level(max)";
        }
        say "Alignment:       ".$empire->{alignment};
        say "Is isolationist: ".($empire->{is_isolationist} ? 'Yes':'No');
        say "Colony count:    ".$empire->{colony_count};
        say "Level:           ".$empire->{level};
        say "Date founded:    ".format_date($empire->{date_founded});
    }
    say "";
    $self->empire_affinity($empire);
    $self->empire_body($empire);
    
}

sub empire_affinity {
    my ($self,$empire) = @_;
    
    return
        unless defined $empire->{affinity};
    
    my $my_affinity = $self->my_affinity;
    
    my $table = Games::Lacuna::Task::Table->new({
        headline    => 'Affinity report',
        columns     => ['Affinity','Level','My Level','Delta'],
    });
    
    while (my ($affinity,$level) = each %{$empire->{affinity}}) {
        next
            if $affinity eq 'name' || $affinity eq 'description';
        my $label = $affinity;
        $label =~ s/_affinity$//;
        $table->add_row({
            affinity    => $label,
            level       => $level,
            my_level    => $my_affinity->{$affinity},
            delta       => $level - $my_affinity->{$affinity},
        });
    }
    
    say $table->render_text;
}

sub empire_body {
    my ($self,$empire) = @_;
    
    my $planet_stats = $self->my_body_status($self->home_planet_id);
    
    my $sth_body = $self->storage_prepare('SELECT 
          body.id,
          body.x,
          body.y,
          body.orbit,
          body.size,
          body.name,
          body.type,
          body.empire,
          star.name AS star,
          distance_func(body.x,body.y,?,?) AS distance
        FROM body
        INNER JOIN star ON (body.star = star.id)
        WHERE empire = ?
        ORDER BY distance ASC');
    
    $sth_body->execute($planet_stats->{x},$planet_stats->{y},$empire->{id});
    
    my $table = Games::Lacuna::Task::Table->new({
        headline    => 'Body report',
        columns     => ['Name','X','Y','Type','Orbit','Size','Star','Distance'],
    });
    
    while (my $body = $sth_body->fetchrow_hashref) {
        $table->add_row({
            (map { ($_ => $body->{$_}) } qw(name x y orbit type orbit size star distance)),
        });
    }
    
    say $table->render_text;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;