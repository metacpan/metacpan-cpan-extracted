use v5.38;
use lib ( 'lib', '../lib' );
use Logic::Probabilistic::Syntax;

=pod

Example from: https://dtai.cs.kuleuven.be/problog/tutorial/various/02_bousi.html

"Movie listings example"

%% DIRECTIVE
lambdaCut(0.5).

%% PROXIMITY RELATIONS
%% Location Distance Relationship
0.30::equals(beverly_hills,downtown).
0.45::equals(beverly_hills,santa_monica).
0.56::equals(beverly_hills,hollywood).
0.90::equals(beverly_hills,westwood).
0.45::equals(downtown,hollywood).
0.23::equals(downtown,santa_monica).
0.25::equals(downtown,westwood).
0.30::equals(hollywood,santa_monica).
0.45::equals(hollywood,westwood).
0.90::equals(santa_monica,westwood).

%% Category Relationship
0.6::equals(comedy,drama).
0.3::equals(comedy,adventure).
0.3::equals(comedy,suspense).
0.6::equals(drama,adventure).
0.6::equals(drama,suspense).
0.9::equals(adventure,suspense).

%% Films Table
%% film(Title, Director, Category)
film(four_feathers, korda, adventure).
film(modern_times, chaplin, comedy).
film(psycho, hitchcock, suspense).
film(rear_window, hitchcock, suspense).
film(robbery, yates, suspense).
film(star_wars, lucas, adventure).
film(surf_party, dexter, drama).

%% Theaters Table
%% theater(Name,Owner,Location).
theater(chinese,mann,hollywood).
theater(egyptian,va,westwood).
theater(music_hall,lae,beverly_hills).
theater(odeon,cineplex,santa_monica).
theater(rialto,independent,downtown).
theater(village,mann,westwood).

%% Engagements Table
%% engagement(Film,Theater)
engagement(modern_times,rialto).
engagement(start_wars,rialto).
engagement(star_wars,chinese).
engagement(rear_window,egyptian).
engagement(surf_party,village).
engagement(robbery,odeon).
engagement(modern_times,odeon).
engagement(four_feathers,music_hall).

%% SOFT RULES
equals(X,X).
equals(X,Y) :- equals(Y,X).

%% MAIN RULE
%% search(input, input, output, output)
search(Category, Location, Film, Theater) :-
    film(Film, _, Category2),
    engagement(Film, Theater),
    theater(Theater, _, Location2),
    equals(Category2, Category),
    equals(Location2, Location).

query(search(adventure, westwood, Film, Theater)).

=cut

prob_logic MovieListings {

    # the "lambdaCut(0.5)" will be applied on the output

    # proximity relations
    pfacts {
        # Location Distance Relationship
        0.30 => equals( 'Beverly Hills', 'Downtown' );
        0.45 => equals( 'Beverly Hills', 'Santa Monica' );
        0.56 => equals( 'Beverly Hills', 'Hollywood' );
        0.90 => equals( 'Beverly Hills', 'Westwood' );
        0.45 => equals( 'Downtown',      'Hollywood' );
        0.23 => equals( 'Downtown',      'Santa Monica' );
        0.25 => equals( 'Downtown',      'Westwood' );
        0.30 => equals( 'Hollywood',     'Santa Monica' );
        0.45 => equals( 'Hollywood',     'Westwood' );
        0.90 => equals( 'Santa Monica',  'Westwood' );

        # Category Relationship
        0.6 => equals( 'comedy',    'drama' );
        0.3 => equals( 'comedy',    'adventure' );
        0.3 => equals( 'comedy',    'suspense' );
        0.6 => equals( 'drama',     'adventure' );
        0.6 => equals( 'drama',     'suspense' );
        0.9 => equals( 'adventure', 'suspense' );
    }

    table 'equals/2';

    facts {
        # Films Table
        # film(Title, Director, Category)
        film( 'Four Feathers', 'Korda',     'adventure' );
        film( 'Modern Times',  'Chaplin',   'comedy' );
        film( 'Psycho',        'Hitchcock', 'suspense' );
        film( 'Rear Window',   'Hitchcock', 'suspense' );
        film( 'Robbery',       'Yates',     'suspense' );
        film( 'Star Wars',     'Lucas',     'adventure' );
        film( 'Surf Party',    'Dexter',    'drama' );

        # Theaters Table
        # theater(Name,Owner,Location).
        theater( 'Chinese',    'Mann',        'Hollywood' );
        theater( 'Egyptian',   'Va',          'Westwood' );
        theater( 'Music Hall', 'Lae',         'Beverly Hills' );
        theater( 'Odeon',      'Cineplex',    'Santa Monica' );
        theater( 'Rialto',     'Independent', 'Downtown' );
        theater( 'Village',    'Mann',        'Westwood' );

        # Engagements Table
        # engagement(Film,Theater)
        engagement( 'Modern Times',  'Rialto' );
        engagement( 'Star Wars',     'Rialto' );
        engagement( 'Star Wars',     'Chinese' );
        engagement( 'Rear Window',   'Egyptian' );
        engagement( 'Surf Party',    'Village' );
        engagement( 'Robbery',       'Odeon' );
        engagement( 'Modern Times',  'Odeon' );
        engagement( 'Four Feathers', 'Music Hall' );
    }

    rule equals( $x, $x ) { }
    rule equals( $x, $y ) {
        equals( $y, $x );
    }

    # MAIN RULE
    # search(input, input, output, output)
    rule search( $Category, $Location, $Film, $Theater ) {
        fresh my ( $s1, $s2, $Category2, $Location2 );
        film( $Film, $s1, $Category2 );
        engagement( $Film, $Theater );
        theater( $Theater, $s2, $Location2 );
        equals( $Category2, $Category );
        equals( $Location2, $Location );
    }

    # helper. This unifies the output vars "Film" and "Theater" into
    # one logical variable "listing" so that query_dist can work.
    rule search_listing( $category, $location, $listing ) {
        fresh my ( $film, $theater );
        search( $category, $location, $film, $theater );
        $listing := [ $film, $theater ];
    }
}

# query(search(adventure, westwood, Film, Theater)).
query_dist MovieListings::search_listing( 'adventure', 'Westwood', fresh my $listing ),
  method  => 'rejection',
  samples => 5000->my $dist;
say $dist;

# Applying the lambdaCut(0.5) threshold from the original Bousi~Prolog paper:
say "\n=== Apply lambdaCut(0.5) ===";
for my $outcome ( sort { $b->probability <=> $a->probability } $dist->outcomes ) {
    next if $outcome->probability < 0.5;
    printf "  %-32s : %0.4f (%4.1f%%)\n",
      "$outcome->[0] at $outcome->[1]",
      $outcome->probability,
      $outcome->pct;
}

