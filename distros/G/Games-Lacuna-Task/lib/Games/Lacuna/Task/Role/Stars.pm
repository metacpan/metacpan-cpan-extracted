package Games::Lacuna::Task::Role::Stars;

use 5.010;
our $VERSION = $Games::Lacuna::Task::VERSION;

use Moose::Role;

use List::Util qw(max min);

use Games::Lacuna::Task::Utils qw(normalize_name distance);

use LWP::Simple;
use Text::CSV;



after 'BUILD' => sub {
    my ($self) = @_;
    
    my ($star_count) = $self->client->storage_selectrow_array('SELECT COUNT(1) FROM star');
    
    if ($star_count == 0) {
        $self->fetch_all_stars(0);
    }
};

sub fetch_all_stars {
    my ($self,$check) = @_;
    
    $check //= 1;

    my $server = $self->client->client->uri;
    return
        unless $server =~ /^https?:\/\/([^.]+)\./;
    
    # Fetch starmap from server
    my $starmap_uri = 'http://'.$1.'.lacunaexpanse.com.s3.amazonaws.com/stars.csv';
    
    $self->log('info',"Fetching star map from %s. This will only happen once and might take a while.",$starmap_uri);
    my $content = get($starmap_uri);
    
    # Create temp table
    $self->storage_do('CREATE TEMPORARY TABLE temporary_star (id INTEGER NOT NULL)');
    
    # Prepare sql statements
    my $sth_check  = $self->storage_prepare('SELECT last_checked, is_probed, is_known FROM star WHERE id = ?');
    my $sth_insert = $self->storage_prepare('INSERT INTO star (id,x,y,name,zone,last_checked,is_probed,is_known) VALUES (?,?,?,?,?,?,?,?)');
    my $sth_temp   = $self->storage_prepare('INSERT INTO temporary_star (id) VALUES (?)');
    
    # Parse star map
    $self->log('debug',"Parsing new star map");
    my $csv = Text::CSV->new();
    open my $fh, "<:encoding(utf8)", \$content;
    $csv->column_names( $csv->getline($fh) );
    
    # Process star map
    my $count = 0;
    while( my $row = $csv->getline_hr( $fh ) ){
        $count++;
        my ($last_checked,$is_probed,$is_known);
        if ($check) {
            $sth_check->execute($row->{id});
            ($last_checked,$is_probed,$is_known) = $sth_check->fetchrow_array();
            $sth_check->finish();
        }

        $sth_temp->execute($row->{id});
        
        $sth_insert->execute(
            $row->{id},
            $row->{x},
            $row->{y},
            $row->{name},
            $row->{zone},
            $last_checked,
            $is_probed,
            $is_known
        );
        
        $self->log('debug',"Importing %i stars",$count)
            if $count % 500 == 0;
    }
    $self->log('debug',"Finished imporing %i stars",$count);
    
    # Cleanup star table
    $self->storage_do('DELETE FROM star WHERE id NOT IN (SELECT id FROM temporary_star)');
    $self->storage_do('DELETE FROM body WHERE star NOT IN (SELECT id FROM star)');
    $self->storage_do('DROP TABLE temporary_star');
    
    return;
}

sub _get_body_cache_for_star {
    my ($self,$star_data) = @_;
    
    my $star_id = $star_data->{id}; 
    
    return
        unless defined $star_id;
    
    my $sth = $self->storage_prepare('SELECT 
            body.id, 
            body.star,
            body.x,
            body.y,
            body.orbit,
            body.size,
            body.name,
            body.type,
            body.water,
            body.ore,
            body.empire,
            body.is_excavated,
            empire.id AS empire_id,
            empire.name AS empire_name,
            empire.alignment AS empire_alignment,
            empire.is_isolationist AS empire_is_isolationist
        FROM body
        LEFT JOIN empire ON (empire.id = body.empire)
        WHERE body.star = ?'
    );
    
    $sth->execute($star_data->{id});
    
    my @bodies;
    while (my $body = $sth->fetchrow_hashref) {
        push (@bodies,$self->_inflate_body($body,$star_data));
    }
    
    return @bodies;
}

sub _get_star_cache {
    my ($self,$query,@params) = @_;
    
    return
        unless defined $query;
    
    # Get star from cache
    my $star_cache = $self->client->storage_selectrow_hashref('SELECT 
            star.id,
            star.x,
            star.y,
            star.name,
            star.zone,
            star.last_checked,
            star.is_probed,
            star.is_known
        FROM star
        WHERE '.$query,
        @params
    );
    
    return
        unless defined $star_cache;
    
    return $self->_inflate_star($star_cache)
}

sub _inflate_star {
    my ($self,$star_cache) = @_;
    
    # Build star data
    my $star_data = {
        (map { $_ => $star_cache->{$_} } qw(id x y zone name is_probed is_known last_checked)),
        cache_ok    => 0,
    };
    
    # Star was not checked yet
    return $star_data
        unless defined $star_cache->{last_checked};
    
    # Get cache status
    $star_data->{cache_ok} = ($star_cache->{last_checked} > (time() - $Games::Lacuna::Task::Constants::MAX_STAR_CACHE_AGE)) ? 1:0;
    
    # We have no bodies
    return $star_data
        if defined $star_data->{is_known} && $star_data->{is_known} == 0;
    
    # Get Bodies from cache
    my @bodies = $self->_get_body_cache_for_star($star_data);
    
    # Bodies ok
    if (scalar @bodies) {
        $star_data->{bodies} = \@bodies
    # Bodies missing 
    } else {
        $self->log('warn','Inconsitent cache state for star %i',$star_data->{id});
        $star_data = $self->_get_star_api($star_data->{id},$star_data->{x},$star_data->{y});
    }
    
    return $star_data;
}

sub _inflate_body {
    my ($self,$body,$star) = @_;
    
    return
        unless defined $body;
    
    my $star_data;
    
    if (defined $star) {
        $star_data = {
            star_id     => $star->{id},
            star_name   => $star->{name},
            zone        => $star->{zone},
        };
    } else {
        $star_data = {
            star_id     => $body->{star_id},
            star_name   => $body->{star_name},
            zone        => $body->{zone},
        };
    }
    
    my $body_data = {
        (map { $_ => $body->{$_} } qw(id x y orbit name type water size is_excavated)),
        ore         => $Games::Lacuna::Task::Storage::JSON->decode($body->{ore}), 
        %{$star_data},
    };
    
    if ($body->{empire_id}) {
        $body_data->{empire} = {
            alignment       => $body->{empire_alignment},
            is_isolationist => $body->{empire_is_isolationist},
            name            => $body->{empire_name},
            id              => $body->{empire_id},
        };
    }

    return $body_data;
}

sub _get_body_cache {
    my ($self,$query,@params) = @_;
    
    return
        unless defined $query;
    
    my $body = $self->client->storage_selectrow_hashref('SELECT 
            body.id, 
            body.star,
            body.x,
            body.y,
            body.orbit,
            body.size,
            body.name,
            body.type,
            body.water,
            body.ore,
            body.empire,
            body.is_excavated,
            star.id AS star_id,
            star.name AS star_name,
            star.zone AS zone,
            star.last_checked,
            star.is_probed,
            star.is_known,
            empire.id AS empire_id,
            empire.name AS empire_name,
            empire.alignment AS empire_alignment,
            empire.is_isolationist AS empire_is_isolationist
        FROM body
        INNER JOIN star ON (star.id = body.star)
        LEFT JOIN empire ON (empire.id = body.empire)
        WHERE '.$query,
        @params
    );
    
    return $self->_inflate_body($body);
}

sub get_body_by_id {
    my ($self,$id) = @_;
    
    return
        unless defined $id
        && $id =~ m/^\d+$/;
    
    return $self->_get_body_cache('body.id = ?',$id);
}

sub get_body_by_name {
    my ($self,$name) = @_;
    
    return
        unless defined $name;
    
    my $body_data = $self->_get_body_cache('body.name = ?',$name);
    
    return $body_data
        if $body_data;
        
    return $self->_get_body_cache('body.normalized_name = ?',normalize_name($name));
}

sub get_body_by_xy {
    my ($self,$x,$y) = @_;
    
    return
        unless defined $x
        && defined $y
        && $x =~ m/^-?\d+$/
        && $y =~ m/^-?\d+$/;
    
    return $self->_get_body_cache('body.x = ? AND body.y = ?',$x,$y);
    
#    my ($star_data) = $self->list_stars(
#        x       => $x,
#        y       => $y,
#        limit   => 1,
#        distance=> 1,
#    );
#    
#    return
#        unless defined $star_data
#        && defined $star_data->{bodies};
#    
#    foreach my $body_data (@{$star_data->{bodies}}) {
#        return $body_data
#            if $body_data->{x} == $x
#            && $body_data->{y} == $y;
#    }
    
    return;
}

sub _find_star {
    my ($self,$query,@params) = @_;
    
    return
        unless defined $query;
    
    # Query starmap/cache
    my $star_data = $self->_get_star_cache($query,@params);
    
    # No hit for query
    return
        unless $star_data;
    
    # Cache is valid
    return $star_data
        if $star_data->{cache_ok};
    return $self->_get_star_api($star_data->{id},$star_data->{x},$star_data->{y});
}

sub _get_star_api {
    my ($self,$star_id,$x,$y) = @_;
    
    my $step = int($Games::Lacuna::Task::Constants::MAX_MAP_QUERY / 2);
    
    # Fetch x and y unless given
    unless (defined $x && defined $y) {
        ($x,$y) = $self->client->storage_selectrow_array('SELECT x,y FROM star WHERE id = ?',$star_id);
    }
    
    return
        unless defined $x && defined $y;
    
    # Get area
    my $min_x = $x - $step;
    my $min_y = $y - $step;
    my $max_x = $x + $step;
    my $max_y = $y + $step;
    
    # Get star from api
    my $star_list = $self->_get_area_api_by_xy($min_x,$min_y,$max_x,$max_y);
    
    # Find star in list
    my $star_data;
    foreach my $element (@{$star_list}) {
        if ($element->{id} == $star_id) {
            $star_data = $element;
            last;
        }
    }
    
    # Get bodies from cache, even if system is not probed
    if (! defined $star_data->{bodies}
        && $star_data->{is_known} == 1) {
        
        my @bodies = $self->_get_body_cache_for_star($star_data);
        if (scalar @bodies) {
            $star_data->{bodies} = \@bodies;
        } else {
            $self->log('warn','Inconsitent cache state for star %i',$star_data->{id});
            $self->storage_do('UPDATE star SET is_known = ?, is_probed = 0 WHERE id = ?',0,0,$star_data->{id});
        }
    }
    
    
    return $star_data;
}


sub get_star_by_name {
    my ($self,$name) = @_;
    
    return
        unless defined $name;
    
    return $self->_find_star('star.name = ?',$name);
}

sub get_star_by_xy {
    my ($self,$x,$y) = @_;
    
    return
        unless defined $x
        && defined $y
        && $x =~ m/^-?\d+$/
        && $y =~ m/^-?\d+$/;
    
    return $self->_find_star('star.x = ? AND star.y = ?',$x,$y);
}

sub get_star {
    my ($self,$star_id) = @_;
    
    return
        unless defined $star_id && $star_id =~ m/^\d+$/;
    
    return $self->_find_star('star.id = ?',$star_id);
}

sub _get_area_api_by_xy {
    my ($self,$min_x,$min_y,$max_x,$max_y) = @_;
    
    my $bounds = $self->get_stash('star_map_size');
    return
        if $bounds->{x}[0] >= $max_x || $bounds->{x}[1] <= $min_x;
    return
        if $bounds->{y}[0] >= $max_y || $bounds->{y}[1] <= $min_y;
    
    $min_x = max($min_x,$bounds->{x}[0]);
    $max_x = min($max_x,$bounds->{x}[1]);
    $min_y = max($min_y,$bounds->{y}[0]);
    $max_y = min($max_y,$bounds->{y}[1]);
    
    # Fetch from api
    my $star_info = $self->request(
        object  => $self->build_object('Map'),
        params  => [ $min_x,$min_y,$max_x,$max_y ],
        method  => 'get_stars',
    );
    
    # Loop all stars in area
    my @return;
    foreach my $star_data (@{$star_info->{stars}}) {
        $self->set_star_cache($star_data);
        push(@return,$star_data);
    }
    
    return \@return;
}

sub set_star_cache {
    my ($self,$star_data) = @_;
    
    my $star_id = $star_data->{id};
    
    return
        unless defined $star_id;
    
    delete $star_data->{bodies}
        if (defined $star_data->{bodies} && scalar @{$star_data->{bodies}} == 0);
    $star_data->{last_checked} ||= time();
    $star_data->{cache_ok} //= 1;
    $star_data->{is_probed} //= (defined $star_data->{bodies} ? 1:0);
    $star_data->{is_known} //= 1
        if $star_data->{is_probed};
    
    unless (defined $star_data->{is_known}) {
        ($star_data->{is_known}) = $self->client->storage_selectrow_array('SELECT COUNT(1) FROM body WHERE star = ?',$star_id);
    }
    
    # Update star cache
    $self->storage_do(
        'UPDATE star SET is_probed = ?, is_known = ?, last_checked = ?, name = ? WHERE id = ?',
        $star_data->{is_probed},
        $star_data->{is_known},
        $star_data->{last_checked},
        $star_data->{name},
        $star_id
    );

    return
        unless defined $star_data->{bodies};
    
    $self->_set_star_cache_bodies($star_data);
}

sub _set_star_cache_bodies {
    my ($self,$star_data) = @_;
    
    my $star_id = $star_data->{id};
    
    # Get excavate status
    my %is_excavated;
    my $sth_excavate = $self->storage_prepare('SELECT id,is_excavated FROM body WHERE star = ? AND is_excavated IS NOT NULL');
    $sth_excavate->execute($star_id);
    while (my ($body_id,$is_excavated) = $sth_excavate->fetchrow_array) {
        $is_excavated{$body_id} = $is_excavated;
    }
    
    # Remove all bodies
    $self->storage_do('DELETE FROM body WHERE star = ?',$star_id);
    
    # Insert or update empire
    my $sth_empire = $self->storage_prepare('INSERT OR REPLACE INTO empire
        (id,name,normalized_name,alignment,is_isolationist) 
        VALUES
        (?,?,?,?,?)');
    
    # Insert new bodies
    my $sth_insert = $self->storage_prepare('INSERT INTO body 
        (id,star,x,y,orbit,size,name,normalized_name,type,water,ore,empire,is_excavated) 
        VALUES
        (?,?,?,?,?,?,?,?,?,?,?,?,?)');
    
    # Cache bodies
    foreach my $body_data (@{$star_data->{bodies}}) {
        my $empire = $body_data->{empire} || {};
        
        $body_data->{is_excavated} = $is_excavated{$body_data->{id}};
        
        my $ore = $body_data->{ore};
        $ore = $Games::Lacuna::Task::Storage::JSON->encode($ore)
            if ref $ore eq 'HASH';
        
        $sth_insert->execute(
            $body_data->{id},
            $star_id,
            $body_data->{x},
            $body_data->{y},
            $body_data->{orbit},
            $body_data->{size},
            $body_data->{name},
            normalize_name($body_data->{name}),
            $body_data->{type},
            $body_data->{water},
            $ore,
            $empire->{id},
            $body_data->{is_excavated},
        );
        
        if (defined $empire->{id}) {
            $sth_empire->execute(
                $empire->{id},
                $empire->{name},
                normalize_name($empire->{name}),
                $empire->{alignment},
                $empire->{is_isolationist},
            );
        }
    }
}

sub search_stars_callback {
    my ($self,$callback,%params) = @_;
    
    my @sql_where;
    my @sql_params;
    my @sql_extra;
    my @sql_fields = qw(star.id star.x star.y star.name star.zone star.last_checked star.is_probed star.is_known);
    
    # Order by distance
    if (defined $params{distance}
        && defined $params{x}
        && defined $params{y}) {
        push(@sql_fields,'distance_func(star.x,star.y,?,?) AS distance');
        push(@sql_params,$params{x}+0,$params{y}+0);
        # Does not seem to work for some stronge reason
        #if (defined $params{min_distance}) {
        #    push(@sql_where,'distance >= ?');
        #    push(@sql_params,$params{min_distance}+0);
        #}
        #if (defined $params{max_distance}) {
        #    push(@sql_where,'distance <= ?');
        #    push(@sql_params,$params{max_distance}+0);
        #}
        push(@sql_extra," ORDER BY distance ".($params{distance} ? 'ASC':'DESC'));
    }
    # Only probed/unprobed or unknown
    if (defined $params{is_probed}) {
        push(@sql_where,'(star.last_checked < ? OR star.is_probed = ? OR star.is_probed IS NULL)');
        push(@sql_params,(time - $Games::Lacuna::Task::Constants::MAX_STAR_CACHE_AGE),$params{is_probed});
    } elsif (exists $params{is_probed}) {
        push(@sql_where,'(star.last_checked < ? OR star.is_probed IS NULL)');
        push(@sql_params,(time - $Games::Lacuna::Task::Constants::MAX_STAR_CACHE_AGE));
    }
    # Only known/unknown 
    if (defined $params{is_known}) {
        push(@sql_where,'(star.is_known = ? OR star.is_known IS NULL)');
        push(@sql_params,$params{is_known});
    }
    # Zone
    if (defined $params{zone}) {
        push(@sql_where,'star.zone = ?');
        push(@sql_params,$params{zone});
    }
    ## Limit results
    #if (defined $params{limit}) {
    #    push(@sql_extra," LIMIT ?");
    #    push(@sql_params,$params{limit});
    #}
    
    # Build sql
    my $sql = "SELECT ".join(',',@sql_fields). " FROM star ";
    $sql .= ' WHERE '.join(' AND ',@sql_where)
        if scalar @sql_where;
    $sql .= join(' ',@sql_extra);
    
    my $sth = $self->storage_prepare($sql);
    $sth->execute(@sql_params)
        or $self->abort('Could not execute SQL command "%s": %s',$sql,$sth->errstr);
    
    my $count = 0;
    # Loop all results
    while (my $star_cache = $sth->fetchrow_hashref) {
        # Filter distance
        next
            if defined $params{min_distance} && $star_cache->{distance} < $params{min_distance};
        next
            if defined $params{max_distance} && $star_cache->{distance} > $params{max_distance};
        
        # Inflate star data
        my $star_data;
        if (defined $star_cache->{last_checked} 
            && $star_cache->{last_checked} > (time - $Games::Lacuna::Task::Constants::MAX_STAR_CACHE_AGE)) {
            $star_data = $self->_inflate_star($star_cache);
        } else {
            $star_data = $self->_get_star_api($star_cache->{id},$star_cache->{x},$star_cache->{y});
        }
        
        # Check definitve probed status
        next
            if (defined $params{is_probed} && $star_data->{is_probed} != $params{is_probed});
        
        # Check definitve known status
        next
            if (defined $params{is_known} && $star_data->{is_known} != $params{is_known});
        
        # Set distance
        $star_data->{distance} = $star_cache->{distance}
            if defined $star_cache->{distance};
        
        $count ++;
        
        # Run callback
        my $return = $callback->($star_data);
        
        last
            unless $return;
        last
            if defined $params{limit} && $count >= $params{limit};
    }
    
    $sth->finish();
    
    return;
}

sub set_body_excavated {
    my ($self,$body_id,$is_excavated) = @_;
    
    $is_excavated //= 1;
    $self->storage_do('UPDATE body SET is_excavated = ? WHERE id = ?',$is_excavated,$body_id);
}

no Moose::Role;
1;

=encoding utf8

=head1 NAME

Games::Lacuna::Task::Role::Stars - Astronomy helper methods

=head1 SYNOPSIS

    package Games::Lacuna::Task::Action::MyTask;
    use Moose;
    extends qw(Games::Lacuna::Task::Action);
    with qw(Games::Lacuna::Task::Role::Stars);
    
=head1 DESCRIPTION

This role provides astronomy-related helper methods.

=head1 METHODS

=head2 get_star

 $star_data = $self->get_star($star_id);

Fetches star data from the API or local cache for the given star id

=head2 get_star_by_name

 $star_data = $self->get_star_by_name($star_name);

Fetches star data from the API or local cache for the given star name

=head2 get_star_by_xy

 $star_data = $self->get_star_by_name($x,$y);

Fetches star data from the API or local cache for the given star coordinates

=head2 fetch_all_stars

 $self->fetch_all_stars();

Populates the star cache. Usually takes several minutes to complete and thus
should not be called regularly.

=head2 get_body_by_id

 $body_data = $self->get_body_by_id($body_id);

Fetches body data from the local cache for the given body id

=head2 get_body_by_name

 $body_data = $self->get_body_by_name($body_name);

Fetches body data from the local cache for the given body name
Ignores case and accents so that eg. 'Hà Nôi' equals 'HA NOI'.

=head2 get_body_by_xy

 $body_data = $self->get_body_by_name($x,$y);

Fetches body data from the local cache for the given body coordinates

=head2 set_body_excavated

 $self->set_body_excavated($body_id,$is_excavated);

Mark body as excavated

=head2 set_star_cache

 $self->set_star_cache($api_star_data);

Create star cache for given api response data

=head2 search_stars_callback

 $self->search_stars_callback(
    sub {
        my $star_data = shift;
        ...
    },
    %search_params
 );

Searches all stars acording to the given search parameters and executes the 
callback for every matching star.

Valid search options are

=over

=item * is_probed (0 = unprobed, 1 = probed)

=item * is_known (0 = body data not available, 1 = body data available)

=item * max_distance

=item * min_distance

=item * distance (1 = ascending, 0 = descending)

=item * zone

=item * x,y (refernce coordinates for distance calculations)

=back

=cut
