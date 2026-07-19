use strict;
use warnings;
use Test::More 0.98;

# The SWAPI (Star Wars API) schema from https://github.com/graphql/swapi-graphql:
# the canonical Relay-style example app (Node interface with global object
# IDs, 22 connection/edge type pairs generated from a helper like
# graphql-relay's connectionDefinitions, cursor pagination with
# first/after/last/before, and descriptions on every type and most fields).
# This test rebuilds the whole schema code-first and asserts it is identical
# to the vendored reference SDL (t/swapi-schema.graphql), then runs the app
# against an in-memory dataset on both the sync and async lanes.

use File::Basename qw(dirname);
use File::Spec ();
use MIME::Base64 qw(decode_base64 encode_base64);
use Scalar::Util qw(blessed);

use GraphQL::Houtou qw(build_native_runtime);
use GraphQL::Houtou::Schema;
use GraphQL::Houtou::Type::Interface;
use GraphQL::Houtou::Type::Object;
use GraphQL::Houtou::Type::Scalar qw($Boolean $Float $ID $Int $String);

# --------------------------------------------------------------------------
# A small in-memory slice of the SWAPI dataset. Record keys match the
# schema's field names so plain scalar fields need no explicit resolver;
# relation keys hold local ids that the connection resolvers expand.
# --------------------------------------------------------------------------
my %DATA = (
  films => {
    1 => { kind => 'films', id => 1, title => 'A New Hope', episodeID => 4,
           openingCrawl => 'It is a period of civil war.', director => 'George Lucas',
           producers => [ 'Gary Kurtz', 'Rick McCallum' ], releaseDate => '1977-05-25',
           created => '2014-12-10T14:23:31Z', edited => '2014-12-20T19:49:45Z',
           characters => [ 1, 2, 3, 4, 5 ], planets => [ 1, 2 ],
           starships => [ 1, 2 ], vehicles => [], species => [ 1, 2 ] },
    2 => { kind => 'films', id => 2, title => 'The Empire Strikes Back', episodeID => 5,
           director => 'Irvin Kershner', releaseDate => '1980-05-17',
           characters => [ 1, 2, 3, 4, 5 ], planets => [ 1 ],
           starships => [ 1 ], vehicles => [ 1 ], species => [ 1, 2 ] },
    3 => { kind => 'films', id => 3, title => 'Return of the Jedi', episodeID => 6,
           director => 'Richard Marquand', releaseDate => '1983-05-25',
           characters => [ 1, 2, 3, 5 ], planets => [ 1 ],
           starships => [ 1 ], vehicles => [], species => [ 1, 2 ] },
  },
  people => {
    1 => { kind => 'people', id => 1, name => 'Luke Skywalker', height => 172,
           mass => 77, hairColor => 'blond', skinColor => 'fair', eyeColor => 'blue',
           birthYear => '19BBY', gender => 'male', homeworld => 1,
           films => [ 1, 2, 3 ], starships => [ 1 ], vehicles => [ 1 ] },
    2 => { kind => 'people', id => 2, name => 'C-3PO', height => 167, mass => 75,
           gender => 'n/a', homeworld => 1, species => 2,
           films => [ 1, 2, 3 ], starships => [], vehicles => [] },
    3 => { kind => 'people', id => 3, name => 'R2-D2', height => 96, mass => 32,
           gender => 'n/a', species => 2,
           films => [ 1, 2, 3 ], starships => [], vehicles => [] },
    4 => { kind => 'people', id => 4, name => 'Darth Vader', height => 202,
           mass => 136, birthYear => '41.9BBY', gender => 'male', homeworld => 1,
           films => [ 1, 2, 3 ], starships => [ 2 ], vehicles => [] },
    5 => { kind => 'people', id => 5, name => 'Leia Organa', height => 150,
           mass => 49, birthYear => '19BBY', gender => 'female', homeworld => 2,
           films => [ 1, 2, 3 ], starships => [], vehicles => [ 1 ] },
  },
  planets => {
    1 => { kind => 'planets', id => 1, name => 'Tatooine', rotationPeriod => 23,
           orbitalPeriod => 304, diameter => 10465, climates => [ 'arid' ],
           gravity => '1 standard', terrains => [ 'desert' ], surfaceWater => 1,
           population => 200000, residents => [ 1, 2, 4 ], films => [ 1, 2, 3 ] },
    2 => { kind => 'planets', id => 2, name => 'Alderaan', climates => [ 'temperate' ],
           terrains => [ 'grasslands', 'mountains' ], population => 2000000000,
           residents => [ 5 ], films => [ 1 ] },
  },
  species => {
    1 => { kind => 'species', id => 1, name => 'Human', classification => 'mammal',
           designation => 'sentient', averageHeight => 180, averageLifespan => 120,
           language => 'Galactic Basic', people => [ 4, 5 ], films => [ 1, 2, 3 ] },
    2 => { kind => 'species', id => 2, name => 'Droid', classification => 'artificial',
           designation => 'sentient', language => 'n/a',
           people => [ 2, 3 ], films => [ 1, 2, 3 ] },
  },
  starships => {
    1 => { kind => 'starships', id => 1, name => 'X-wing', model => 'T-65 X-wing',
           starshipClass => 'Starfighter', manufacturers => [ 'Incom Corporation' ],
           costInCredits => 149999, length => 12.5, crew => '1', passengers => '0',
           maxAtmospheringSpeed => 1050, hyperdriveRating => 1, MGLT => 100,
           cargoCapacity => 110, consumables => '1 week',
           pilots => [ 1 ], films => [ 1, 2, 3 ] },
    2 => { kind => 'starships', id => 2, name => 'TIE Advanced x1',
           model => 'Twin Ion Engine Advanced x1', starshipClass => 'Starfighter',
           pilots => [ 4 ], films => [ 1 ] },
  },
  vehicles => {
    1 => { kind => 'vehicles', id => 1, name => 'Snowspeeder', model => 't-47 airspeeder',
           vehicleClass => 'airspeeder', manufacturers => [ 'Incom corporation' ],
           length => 4.5, crew => '2', passengers => '0', maxAtmospheringSpeed => 650,
           cargoCapacity => 10, consumables => 'none',
           pilots => [ 1, 5 ], films => [ 2 ] },
  },
);

# --------------------------------------------------------------------------
# Relay helpers: global object IDs and the connectionFromArray algorithm
# from graphql-relay-js (offset cursors, first/after/last/before slicing).
# --------------------------------------------------------------------------
sub to_global_id { encode_base64("$_[0]:$_[1]", '') }

sub from_global_id {
  my ($kind, $local) = split /:/, decode_base64($_[0] // ''), 2;
  return ($kind, $local);
}

sub offset_from_cursor {
  my ($cursor) = @_;
  return undef if !defined $cursor;
  my $decoded = decode_base64($cursor);
  return $decoded =~ /\Aarrayconnection:(\d+)\z/ ? $1 : undef;
}

sub connection_from_array {
  my ($items, $args) = @_;
  my $length = scalar @$items;
  my $after_offset = offset_from_cursor($args->{after});
  my $before_offset = offset_from_cursor($args->{before});

  my $start = defined $after_offset ? $after_offset + 1 : 0;
  $start = $length if $start > $length;
  my $end = defined $before_offset && $before_offset < $length ? $before_offset : $length;
  $end = $start if $end < $start;
  if (defined $args->{first}) {
    $end = $start + $args->{first} if $start + $args->{first} < $end;
  }
  if (defined $args->{last}) {
    $start = $end - $args->{last} if $end - $args->{last} > $start;
  }

  my @edges = map {
    +{ node => $items->[$_], cursor => to_global_id(arrayconnection => $_) }
  } $start .. $end - 1;
  my $lower_bound = defined $after_offset ? $after_offset + 1 : 0;
  my $upper_bound = defined $before_offset && $before_offset < $length ? $before_offset : $length;
  return {
    edges => \@edges,
    totalCount => $length,
    pageInfo => {
      startCursor => @edges ? $edges[0]{cursor} : undef,
      endCursor => @edges ? $edges[-1]{cursor} : undef,
      hasPreviousPage => defined $args->{last} ? ($start > $lower_bound ? 1 : 0) : 0,
      hasNextPage => defined $args->{first} ? ($end < $upper_bound ? 1 : 0) : 0,
    },
  };
}

# --------------------------------------------------------------------------
# Schema builder. Descriptions are transcribed verbatim from the reference
# schema; the SDL-equality subtest below holds every one of them to it.
# $args{entity_fetcher} lets connections load through a DataLoader on the
# async lane; the default fetches synchronously.
# --------------------------------------------------------------------------
sub desc { join "\n", @_ }

my $TOTAL_COUNT_DESC = desc(
  'A count of the total number of objects in this connection, ignoring pagination.',
  'This allows a client to fetch the first five objects by passing "5" as the',
  'argument to "first", then fetch the total count so it could display "5 of 83",',
  'for example.',
);
my $SHORTCUT_DESC = desc(
  'A list of all of the objects returned in the connection. This is a convenience',
  'field provided for quickly exploring the API; rather than querying for',
  '"{ edges { node } }" when no edge data is needed, this field can be be used',
  'instead. Note that when clients like Relay need to fetch the "cursor" field on',
  'the edge to enable efficient pagination, this shortcut cannot be used, and the',
  'full "{ edges { node } }" version should be used instead.',
);
my $CREATED_DESC = 'The ISO 8601 date format of the time that this resource was created.';
my $EDITED_DESC = 'The ISO 8601 date format of the time that this resource was edited.';
my $ID_DESC = 'The ID of an object';

sub build_schema {
  my (%args) = @_;
  my $fetch = $args{entity_fetcher} || sub {
    my ($kind, $ids) = @_;
    return [ map { $DATA{$kind}{$_} } @$ids ];
  };

  my $PageInfo = GraphQL::Houtou::Type::Object->new(
    name => 'PageInfo',
    description => 'Information about pagination in a connection.',
    fields => {
      hasNextPage => { type => $Boolean->non_null,
        description => 'When paginating forwards, are there more items?' },
      hasPreviousPage => { type => $Boolean->non_null,
        description => 'When paginating backwards, are there more items?' },
      startCursor => { type => $String,
        description => 'When paginating backwards, the cursor to continue.' },
      endCursor => { type => $String,
        description => 'When paginating forwards, the cursor to continue.' },
    },
  );

  my $Node = GraphQL::Houtou::Type::Interface->new(
    name => 'Node',
    description => 'An object with an ID',
    fields => {
      id => { type => $ID->non_null, description => 'The id of the object.' },
    },
    tag_resolver => sub { $_[0]{kind} },
  );

  # connectionDefinitions from graphql-relay: every connection/edge pair
  # shares the same shape and boilerplate descriptions, plus swapi's
  # totalCount and node-list shortcut extras.
  my $make_connection = sub {
    my ($prefix, $node_type, $shortcut) = @_;
    my $edge = GraphQL::Houtou::Type::Object->new(
      name => "${prefix}Edge",
      description => 'An edge in a connection.',
      fields => {
        node => { type => $node_type, description => 'The item at the end of the edge' },
        cursor => { type => $String->non_null, description => 'A cursor for use in pagination' },
      },
    );
    return GraphQL::Houtou::Type::Object->new(
      name => "${prefix}Connection",
      description => 'A connection to a list of items.',
      fields => {
        pageInfo => { type => $PageInfo->non_null,
          description => 'Information to aid in pagination.' },
        edges => { type => $edge->list, description => 'A list of edges.' },
        totalCount => { type => $Int, description => $TOTAL_COUNT_DESC },
        $shortcut => { type => $node_type->list, description => $SHORTCUT_DESC,
          resolve => sub { [ map { $_->{node} } @{ $_[0]{edges} || [] } ] } },
      },
    );
  };

  my $connection_args = sub {
    return {
      after => { type => $String },
      first => { type => $Int },
      before => { type => $String },
      last => { type => $Int },
    };
  };

  # A paginated field over related entities: expand the id list on the
  # source record through $fetch (sync array or promise of one).
  my $connection_field = sub {
    my ($prefix, $node_type, $shortcut, $kind, $key) = @_;
    return {
      type => $make_connection->($prefix, $node_type, $shortcut),
      args => $connection_args->(),
      resolve => sub {
        my ($source, $args) = @_;
        my $fetched = $fetch->($kind, [ @{ $source->{$key} || [] } ]);
        return $fetched->then(sub { connection_from_array($_[0], $args) })
          if blessed $fetched && $fetched->can('then');
        return connection_from_array($fetched, $args);
      },
    };
  };

  my $global_id_field = sub {
    my ($kind) = @_;
    return {
      type => $ID->non_null,
      description => $ID_DESC,
      resolve => sub { to_global_id($kind, $_[0]{id}) },
    };
  };

  my $single_ref = sub {
    my ($kind, $key) = @_;
    return sub {
      my ($source) = @_;
      return defined $source->{$key} ? $DATA{$kind}{ $source->{$key} } : undef;
    };
  };

  my ($Film, $Person, $Planet, $Species, $Starship, $Vehicle);

  $Film = GraphQL::Houtou::Type::Object->new(
    name => 'Film',
    description => 'A single film.',
    interfaces => sub { [ $Node ] },
    runtime_tag => 'films',
    fields => sub {
      return {
        title => { type => $String, description => 'The title of this film.' },
        episodeID => { type => $Int, description => 'The episode number of this film.' },
        openingCrawl => { type => $String,
          description => 'The opening paragraphs at the beginning of this film.' },
        director => { type => $String, description => 'The name of the director of this film.' },
        producers => { type => $String->list,
          description => 'The name(s) of the producer(s) of this film.' },
        releaseDate => { type => $String,
          description => 'The ISO 8601 date format of film release at original creator country.' },
        speciesConnection => $connection_field->('FilmSpecies', $Species, 'species', species => 'species'),
        starshipConnection => $connection_field->('FilmStarships', $Starship, 'starships', starships => 'starships'),
        vehicleConnection => $connection_field->('FilmVehicles', $Vehicle, 'vehicles', vehicles => 'vehicles'),
        characterConnection => $connection_field->('FilmCharacters', $Person, 'characters', people => 'characters'),
        planetConnection => $connection_field->('FilmPlanets', $Planet, 'planets', planets => 'planets'),
        created => { type => $String, description => $CREATED_DESC },
        edited => { type => $String, description => $EDITED_DESC },
        id => $global_id_field->('films'),
      };
    },
  );

  $Person = GraphQL::Houtou::Type::Object->new(
    name => 'Person',
    description => 'An individual person or character within the Star Wars universe.',
    interfaces => sub { [ $Node ] },
    runtime_tag => 'people',
    fields => sub {
      return {
        name => { type => $String, description => 'The name of this person.' },
        birthYear => { type => $String, description => desc(
          'The birth year of the person, using the in-universe standard of BBY or ABY -',
          'Before the Battle of Yavin or After the Battle of Yavin. The Battle of Yavin is',
          'a battle that occurs at the end of Star Wars episode IV: A New Hope.') },
        eyeColor => { type => $String, description => desc(
          'The eye color of this person. Will be "unknown" if not known or "n/a" if the',
          'person does not have an eye.') },
        gender => { type => $String, description => desc(
          'The gender of this person. Either "Male", "Female" or "unknown",',
          '"n/a" if the person does not have a gender.') },
        hairColor => { type => $String, description => desc(
          'The hair color of this person. Will be "unknown" if not known or "n/a" if the',
          'person does not have hair.') },
        height => { type => $Int, description => 'The height of the person in centimeters.' },
        mass => { type => $Float, description => 'The mass of the person in kilograms.' },
        skinColor => { type => $String, description => 'The skin color of this person.' },
        homeworld => { type => $Planet,
          description => 'A planet that this person was born on or inhabits.',
          resolve => $single_ref->(planets => 'homeworld') },
        filmConnection => $connection_field->('PersonFilms', $Film, 'films', films => 'films'),
        species => { type => $Species,
          description => 'The species that this person belongs to, or null if unknown.',
          resolve => $single_ref->(species => 'species') },
        starshipConnection => $connection_field->('PersonStarships', $Starship, 'starships', starships => 'starships'),
        vehicleConnection => $connection_field->('PersonVehicles', $Vehicle, 'vehicles', vehicles => 'vehicles'),
        created => { type => $String, description => $CREATED_DESC },
        edited => { type => $String, description => $EDITED_DESC },
        id => $global_id_field->('people'),
      };
    },
  );

  $Planet = GraphQL::Houtou::Type::Object->new(
    name => 'Planet',
    description => desc(
      'A large mass, planet or planetoid in the Star Wars Universe, at the time of',
      '0 ABY.'),
    interfaces => sub { [ $Node ] },
    runtime_tag => 'planets',
    fields => sub {
      return {
        name => { type => $String, description => 'The name of this planet.' },
        diameter => { type => $Int,
          description => 'The diameter of this planet in kilometers.' },
        rotationPeriod => { type => $Int, description => desc(
          'The number of standard hours it takes for this planet to complete a single',
          'rotation on its axis.') },
        orbitalPeriod => { type => $Int, description => desc(
          'The number of standard days it takes for this planet to complete a single orbit',
          'of its local star.') },
        gravity => { type => $String, description => desc(
          'A number denoting the gravity of this planet, where "1" is normal or 1 standard',
          'G. "2" is twice or 2 standard Gs. "0.5" is half or 0.5 standard Gs.') },
        population => { type => $Float,
          description => 'The average population of sentient beings inhabiting this planet.' },
        climates => { type => $String->list, description => 'The climates of this planet.' },
        terrains => { type => $String->list, description => 'The terrains of this planet.' },
        surfaceWater => { type => $Float, description => desc(
          'The percentage of the planet surface that is naturally occurring water or bodies',
          'of water.') },
        residentConnection => $connection_field->('PlanetResidents', $Person, 'residents', people => 'residents'),
        filmConnection => $connection_field->('PlanetFilms', $Film, 'films', films => 'films'),
        created => { type => $String, description => $CREATED_DESC },
        edited => { type => $String, description => $EDITED_DESC },
        id => $global_id_field->('planets'),
      };
    },
  );

  $Species = GraphQL::Houtou::Type::Object->new(
    name => 'Species',
    description => 'A type of person or character within the Star Wars Universe.',
    interfaces => sub { [ $Node ] },
    runtime_tag => 'species',
    fields => sub {
      return {
        name => { type => $String, description => 'The name of this species.' },
        classification => { type => $String,
          description => 'The classification of this species, such as "mammal" or "reptile".' },
        designation => { type => $String,
          description => 'The designation of this species, such as "sentient".' },
        averageHeight => { type => $Float,
          description => 'The average height of this species in centimeters.' },
        averageLifespan => { type => $Int,
          description => 'The average lifespan of this species in years, null if unknown.' },
        eyeColors => { type => $String->list, description => desc(
          'Common eye colors for this species, null if this species does not typically',
          'have eyes.') },
        hairColors => { type => $String->list, description => desc(
          'Common hair colors for this species, null if this species does not typically',
          'have hair.') },
        skinColors => { type => $String->list, description => desc(
          'Common skin colors for this species, null if this species does not typically',
          'have skin.') },
        language => { type => $String,
          description => 'The language commonly spoken by this species.' },
        homeworld => { type => $Planet,
          description => 'A planet that this species originates from.',
          resolve => $single_ref->(planets => 'homeworld') },
        personConnection => $connection_field->('SpeciesPeople', $Person, 'people', people => 'people'),
        filmConnection => $connection_field->('SpeciesFilms', $Film, 'films', films => 'films'),
        created => { type => $String, description => $CREATED_DESC },
        edited => { type => $String, description => $EDITED_DESC },
        id => $global_id_field->('species'),
      };
    },
  );

  $Starship = GraphQL::Houtou::Type::Object->new(
    name => 'Starship',
    description => 'A single transport craft that has hyperdrive capability.',
    interfaces => sub { [ $Node ] },
    runtime_tag => 'starships',
    fields => sub {
      return {
        name => { type => $String,
          description => 'The name of this starship. The common name, such as "Death Star".' },
        model => { type => $String, description => desc(
          'The model or official name of this starship. Such as "T-65 X-wing" or "DS-1',
          'Orbital Battle Station".') },
        starshipClass => { type => $String, description => desc(
          'The class of this starship, such as "Starfighter" or "Deep Space Mobile',
          'Battlestation"') },
        manufacturers => { type => $String->list,
          description => 'The manufacturers of this starship.' },
        costInCredits => { type => $Float,
          description => 'The cost of this starship new, in galactic credits.' },
        length => { type => $Float,
          description => 'The length of this starship in meters.' },
        crew => { type => $String,
          description => 'The number of personnel needed to run or pilot this starship.' },
        passengers => { type => $String,
          description => 'The number of non-essential people this starship can transport.' },
        maxAtmospheringSpeed => { type => $Int, description => desc(
          'The maximum speed of this starship in atmosphere. null if this starship is',
          'incapable of atmosphering flight.') },
        hyperdriveRating => { type => $Float,
          description => 'The class of this starships hyperdrive.' },
        MGLT => { type => $Int, description => desc(
          'The Maximum number of Megalights this starship can travel in a standard hour.',
          'A "Megalight" is a standard unit of distance and has never been defined before',
          'within the Star Wars universe. This figure is only really useful for measuring',
          'the difference in speed of starships. We can assume it is similar to AU, the',
          'distance between our Sun (Sol) and Earth.') },
        cargoCapacity => { type => $Float,
          description => 'The maximum number of kilograms that this starship can transport.' },
        consumables => { type => $String, description => desc(
          'The maximum length of time that this starship can provide consumables for its',
          'entire crew without having to resupply.') },
        pilotConnection => $connection_field->('StarshipPilots', $Person, 'pilots', people => 'pilots'),
        filmConnection => $connection_field->('StarshipFilms', $Film, 'films', films => 'films'),
        created => { type => $String, description => $CREATED_DESC },
        edited => { type => $String, description => $EDITED_DESC },
        id => $global_id_field->('starships'),
      };
    },
  );

  $Vehicle = GraphQL::Houtou::Type::Object->new(
    name => 'Vehicle',
    description => 'A single transport craft that does not have hyperdrive capability',
    interfaces => sub { [ $Node ] },
    runtime_tag => 'vehicles',
    fields => sub {
      return {
        name => { type => $String, description => desc(
          'The name of this vehicle. The common name, such as "Sand Crawler" or "Speeder',
          'bike".') },
        model => { type => $String, description => desc(
          'The model or official name of this vehicle. Such as "All-Terrain Attack',
          'Transport".') },
        vehicleClass => { type => $String,
          description => 'The class of this vehicle, such as "Wheeled" or "Repulsorcraft".' },
        manufacturers => { type => $String->list,
          description => 'The manufacturers of this vehicle.' },
        costInCredits => { type => $Float,
          description => 'The cost of this vehicle new, in Galactic Credits.' },
        length => { type => $Float,
          description => 'The length of this vehicle in meters.' },
        crew => { type => $String,
          description => 'The number of personnel needed to run or pilot this vehicle.' },
        passengers => { type => $String,
          description => 'The number of non-essential people this vehicle can transport.' },
        maxAtmospheringSpeed => { type => $Int,
          description => 'The maximum speed of this vehicle in atmosphere.' },
        cargoCapacity => { type => $Float,
          description => 'The maximum number of kilograms that this vehicle can transport.' },
        consumables => { type => $String, description => desc(
          'The maximum length of time that this vehicle can provide consumables for its',
          'entire crew without having to resupply.') },
        pilotConnection => $connection_field->('VehiclePilots', $Person, 'pilots', people => 'pilots'),
        filmConnection => $connection_field->('VehicleFilms', $Film, 'films', films => 'films'),
        created => { type => $String, description => $CREATED_DESC },
        edited => { type => $String, description => $EDITED_DESC },
        id => $global_id_field->('vehicles'),
      };
    },
  );

  my %node_types = (
    films => $Film, people => $Person, planets => $Planet,
    species => $Species, starships => $Starship, vehicles => $Vehicle,
  );

  my $all_field = sub {
    my ($prefix, $node_type, $shortcut, $kind) = @_;
    return {
      type => $make_connection->($prefix, $node_type, $shortcut),
      args => $connection_args->(),
      resolve => sub {
        my (undef, $args) = @_;
        my @items = map { $DATA{$kind}{$_} } sort { $a <=> $b } keys %{ $DATA{$kind} };
        return connection_from_array(\@items, $args);
      },
    };
  };

  # rootFieldByID from swapi-graphql: look up either by global `id` or by
  # the raw SWAPI numeric id (`filmID`, `personID`, ...).
  my $single_field = sub {
    my ($node_type, $kind, $local_arg) = @_;
    return {
      type => $node_type,
      args => {
        id => { type => $ID },
        $local_arg => { type => $ID },
      },
      resolve => sub {
        my (undef, $args) = @_;
        return $DATA{$kind}{ $args->{$local_arg} } if defined $args->{$local_arg};
        return undef if !defined $args->{id};
        my ($decoded_kind, $local) = from_global_id($args->{id});
        return undef if !defined $local || ($decoded_kind // '') ne $kind;
        return $DATA{$kind}{$local};
      },
    };
  };

  my $Root = GraphQL::Houtou::Type::Object->new(
    name => 'Root',
    fields => {
      allFilms => $all_field->('Films', $Film, 'films', 'films'),
      film => $single_field->($Film, films => 'filmID'),
      allPeople => $all_field->('People', $Person, 'people', 'people'),
      person => $single_field->($Person, people => 'personID'),
      allPlanets => $all_field->('Planets', $Planet, 'planets', 'planets'),
      planet => $single_field->($Planet, planets => 'planetID'),
      allSpecies => $all_field->('Species', $Species, 'species', 'species'),
      species => $single_field->($Species, species => 'speciesID'),
      allStarships => $all_field->('Starships', $Starship, 'starships', 'starships'),
      starship => $single_field->($Starship, starships => 'starshipID'),
      allVehicles => $all_field->('Vehicles', $Vehicle, 'vehicles', 'vehicles'),
      vehicle => $single_field->($Vehicle, vehicles => 'vehicleID'),
      node => {
        type => $Node,
        description => 'Fetches an object given its ID',
        args => {
          id => { type => $ID->non_null, description => $ID_DESC },
        },
        resolve => sub {
          my (undef, $args) = @_;
          my ($kind, $local) = from_global_id($args->{id});
          return undef if !defined $local || !$DATA{$kind // ''};
          return $DATA{$kind}{$local};
        },
      },
    },
  );

  return GraphQL::Houtou::Schema->new(
    query => $Root,
    types => [ $Node, $PageInfo, values %node_types ],
  );
}

my $schema = build_schema();
my $runtime = build_native_runtime($schema);

sub run_query {
  my ($query, %opts) = @_;
  return $runtime->execute_document($query, %opts);
}

my $reference_sdl = do {
  my $path = File::Spec->catfile(dirname(__FILE__), 'swapi-schema.graphql');
  open my $fh, '<', $path or die "cannot read $path: $!";
  local $/;
  <$fh>;
};

# --------------------------------------------------------------------------
# Conformance: the code-first schema must be indistinguishable from the
# reference SDL once both are canonicalized through to_doc.
# --------------------------------------------------------------------------
subtest 'code-first schema reproduces the reference SDL exactly' => sub {
  my $reference = GraphQL::Houtou::Schema->from_doc($reference_sdl);
  my $got_types = $schema->name2type;
  my $want_types = $reference->name2type;
  my %seen = map { ($_ => 1) } keys %$got_types, keys %$want_types;
  my @names = grep { !/\A__/ && $_ !~ /\A(?:Int|Float|String|Boolean|ID)\z/ } sort keys %seen;

  is scalar(grep { $_ =~ /Connection\z/ } @names), 22, 'all 22 connection types present';
  for my $name (@names) {
    ok $got_types->{$name}, "code-first schema defines $name" or next;
    ok $want_types->{$name}, "reference schema defines $name" or next;
    is $got_types->{$name}->to_doc, $want_types->{$name}->to_doc,
      "$name matches the reference definition (fields, args, descriptions)";
  }
  is $schema->to_doc, $reference->to_doc, 'whole-document SDL is identical';
};

subtest 'argument descriptions survive code-first construction' => sub {
  # to_doc does not emit argument descriptions, so check the one the
  # reference schema carries (Root.node.id) structurally.
  my $node_field = $schema->query->fields->{node};
  is $node_field->{description}, 'Fetches an object given its ID', 'field description';
  is $node_field->{args}{id}{description}, 'The ID of an object', 'argument description';
};

# --------------------------------------------------------------------------
# Running the app: pagination, global IDs, cross-entity traversal.
# --------------------------------------------------------------------------
subtest 'allFilms connection with totalCount, edges and pageInfo' => sub {
  my $result = run_query(q~
    { allFilms { totalCount edges { node { title episodeID } cursor }
        pageInfo { hasNextPage hasPreviousPage } films { director } } }
  ~);
  ok !exists $result->{errors}, 'no errors';
  my $conn = $result->{data}{allFilms};
  is $conn->{totalCount}, 3, 'totalCount ignores pagination';
  is_deeply [ map { $_->{node}{title} } @{ $conn->{edges} } ],
    [ 'A New Hope', 'The Empire Strikes Back', 'Return of the Jedi' ], 'edge nodes';
  is_deeply [ map { $_->{director} } @{ $conn->{films} } ],
    [ 'George Lucas', 'Irvin Kershner', 'Richard Marquand' ],
    'shortcut list mirrors the edges';
  ok !$conn->{pageInfo}{hasNextPage}, 'no next page without first';
};

subtest 'forward and backward pagination over allPeople' => sub {
  my $page1 = run_query('{ allPeople(first: 2) { totalCount edges { node { name } cursor } pageInfo { hasNextPage endCursor } } }');
  ok !exists $page1->{errors}, 'no errors';
  my $conn1 = $page1->{data}{allPeople};
  is $conn1->{totalCount}, 5, 'totalCount is the full set';
  is_deeply [ map { $_->{node}{name} } @{ $conn1->{edges} } ],
    [ 'Luke Skywalker', 'C-3PO' ], 'first page';
  ok $conn1->{pageInfo}{hasNextPage}, 'first page has a next page';

  my $cursor = $conn1->{pageInfo}{endCursor};
  my $page2 = run_query(
    'query Next($after: String) { allPeople(first: 2, after: $after) { edges { node { name } } pageInfo { hasNextPage } } }',
    variables => { after => $cursor },
  );
  is_deeply [ map { $_->{node}{name} } @{ $page2->{data}{allPeople}{edges} } ],
    [ 'R2-D2', 'Darth Vader' ], 'second page continues after the cursor';
  ok $page2->{data}{allPeople}{pageInfo}{hasNextPage}, 'one more page remains';

  my $tail = run_query('{ allPeople(last: 2) { edges { node { name } } pageInfo { hasPreviousPage } } }');
  is_deeply [ map { $_->{node}{name} } @{ $tail->{data}{allPeople}{edges} } ],
    [ 'Darth Vader', 'Leia Organa' ], 'last two people';
  ok $tail->{data}{allPeople}{pageInfo}{hasPreviousPage}, 'tail page has a previous page';
};

subtest 'single lookups and cross-entity traversal' => sub {
  my $result = run_query(q~
    {
      film(filmID: "1") {
        title
        characterConnection(first: 3) { totalCount characters { name } }
        planetConnection { planets { name residentConnection { residents { name } } } }
      }
      luke: person(personID: "1") {
        name
        homeworld { name }
        starshipConnection { starships { name pilotConnection { pilots { name } } } }
      }
    }
  ~);
  ok !exists $result->{errors}, 'no errors';
  my $film = $result->{data}{film};
  is $film->{title}, 'A New Hope', 'film by raw SWAPI id';
  is $film->{characterConnection}{totalCount}, 5, 'connection totalCount';
  is_deeply [ map { $_->{name} } @{ $film->{characterConnection}{characters} } ],
    [ 'Luke Skywalker', 'C-3PO', 'R2-D2' ], 'characters shortcut with first';
  is_deeply $film->{planetConnection}{planets}[1]{residentConnection}{residents},
    [ { name => 'Leia Organa' } ], 'planet residents via nested connections';

  my $luke = $result->{data}{luke};
  is $luke->{homeworld}{name}, 'Tatooine', 'single reference field';
  is_deeply $luke->{starshipConnection}{starships}[0]{pilotConnection}{pilots},
    [ { name => 'Luke Skywalker' } ], 'cyclic person -> starship -> pilot traversal';
};

subtest 'node interface refetch with global IDs' => sub {
  my $ids = run_query('{ luke: person(personID: "1") { id } film(filmID: "2") { id } }');
  my $luke_id = $ids->{data}{luke}{id};
  my $film_id = $ids->{data}{film}{id};
  is $luke_id, to_global_id(people => 1), 'global id is base64("kind:id")';

  my $result = run_query(q~
    query Refetch($lukeId: ID!, $filmId: ID!) {
      luke: node(id: $lukeId) {
        id __typename
        ... on Person { name homeworld { name } }
      }
      film: node(id: $filmId) {
        __typename
        ... on Film { title }
      }
    }
  ~, variables => { lukeId => $luke_id, filmId => $film_id });
  ok !exists $result->{errors}, 'no errors';
  is_deeply $result->{data}{luke}, {
    id => $luke_id,
    __typename => 'Person',
    name => 'Luke Skywalker',
    homeworld => { name => 'Tatooine' },
  }, 'node() dispatches to Person';
  is_deeply $result->{data}{film}, { __typename => 'Film', title => 'The Empire Strikes Back' },
    'node() dispatches to Film';

  my $missing = run_query('{ node(id: "bm9wZTo5OTk=") { id } }'); # base64("nope:999")
  is_deeply $missing, { data => { node => undef } },
    'unknown global id resolves to null';
};

subtest 'lookup by global id on typed root fields' => sub {
  my $result = run_query(
    'query ($id: ID!, $wrong: ID!) { a: starship(id: $id) { name } b: vehicle(id: $wrong) { name } }',
    variables => { id => to_global_id(starships => 2), wrong => to_global_id(starships => 2) },
  );
  is_deeply $result, {
    data => { a => { name => 'TIE Advanced x1' }, b => undef },
  }, 'global id matches its own root field only';
};

subtest 'introspection exposes the transcribed descriptions' => sub {
  my $result = run_query(q~
    {
      __schema { queryType { name } }
      __type(name: "Film") {
        description
        fields { name description }
      }
    }
  ~);
  ok !exists $result->{errors}, 'no errors';
  is $result->{data}{__schema}{queryType}{name}, 'Root', 'query root is Root';
  is $result->{data}{__type}{description}, 'A single film.', 'type description';
  my %field_desc = map { ($_->{name} => $_->{description}) } @{ $result->{data}{__type}{fields} };
  is $field_desc{title}, 'The title of this film.', 'field description';
  is $field_desc{id}, 'The ID of an object', 'relay id field description';
};

# --------------------------------------------------------------------------
# The same app on the async lane: connections fetch entities through a
# per-request DataLoader and the envelopes must match the sync lane.
# --------------------------------------------------------------------------
subtest 'async lane with DataLoader-backed connections matches sync' => sub {
  eval { require Promise::XS; require GraphQL::Houtou::DataLoader; 1 }
    or plan skip_all => 'Promise::XS not available';

  my (%loaders, @batches);
  my $async_schema = build_schema(
    entity_fetcher => sub {
      my ($kind, $ids) = @_;
      my $loader = $loaders{$kind} ||= GraphQL::Houtou::DataLoader->new(batch => sub {
        push @batches, [ $kind, @{ $_[0] } ];
        return [ map { $DATA{$kind}{$_} } @{ $_[0] } ];
      });
      return $loader->load_many([ @$ids ]);
    },
  );
  my $async_runtime = build_native_runtime($async_schema, async => 1);
  # like on_stall_for, but over loaders that are created lazily mid-request
  my $on_stall = sub {
    my $round;
    do {
      $round = 0;
      $round += $_->dispatch for values %loaders;
    } while ($round);
  };

  for my $query (
    '{ allFilms { totalCount films { title characterConnection { characters { name } } } } }',
    '{ film(filmID: "1") { planetConnection { planets { name residentConnection { residents { name } } } } } }',
    '{ allPeople(first: 3) { edges { node { name filmConnection(last: 1) { films { title } } } } } }',
  ) {
    %loaders = ();
    @batches = ();
    my $async_result = $async_runtime->execute_document($query, on_stall => $on_stall);
    my $sync_result = run_query($query);
    is_deeply $async_result, $sync_result, "async matches sync for $query";
  }

  # dependency-wave batching: the three films' characterConnections issue
  # a single people batch even though they are sibling subtrees
  %loaders = ();
  @batches = ();
  $async_runtime->execute_document(
    '{ allFilms { films { characterConnection { characters { name } } } } }',
    on_stall => $on_stall,
  );
  my @people_batches = grep { $_->[0] eq 'people' } @batches;
  is scalar @people_batches, 1, 'sibling connections collapse into one people batch';
  is_deeply [ sort { $a <=> $b } @{ $people_batches[0] }[ 1 .. $#{ $people_batches[0] } ] ],
    [ 1, 2, 3, 4, 5 ], 'the batch carries the union of character ids';
};

done_testing;
