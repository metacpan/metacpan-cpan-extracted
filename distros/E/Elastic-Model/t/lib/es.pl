#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Search::Elasticsearch;
use utf8;

our $es;

my $trace
    = !$ENV{TRACE}       ? undef
    : $ENV{TRACE} eq '1' ? 'Stderr'
    :                      [ 'File', $ENV{TRACE} ];

if ( $ENV{ES} ) {
    $es = Search::Elasticsearch->new(
        nodes    => $ENV{ES},
        trace_to => $trace,
        client   => '1_0::Direct'
    );
    my ($version) = ( $es->info->{version}{number} =~ /^(\d+)/ );
    if ( $version < 1 ) {
        $es = Search::Elasticsearch->new(
            nodes    => $ENV{ES},
            trace_to => $trace,
            client   => '0_90::Direct',
        );
    }
    eval { $es->ping } or do {
        diag $@;
        undef $es;
    };
}

if ($es) {
    $es->indices->delete( index => 'myapp*', ignore => 404 );
    wait_for_es();
    return $es;
}

plan skip_all => 'No ElasticSearch test server available';
exit;

#===================================
sub wait_for_es {
#===================================
    $es->cluster->health( wait_for_status => 'yellow' );
    $es->indices->refresh;
    sleep $_[0] if $_[0];
}

#===================================
sub create_users {
#===================================
    my $model = shift;
    my $ns    = $model->namespace('myapp');
    $ns->index('myapp2')->create;
    $ns->index('myapp3')->create;
    $ns->alias->to( 'myapp2', 'myapp3' );

    my @domains = ( map { $model->domain( "myapp" . $_ ) } qw(2 2 3) );
    my @users;
    my $i = 0;
    for ( names() ) {
        push @users,
            $domains[ $i % 3 ]->create( user => { name => $_, id => ++$i } );
    }
    $ns->alias->refresh;

    return @users;
}

#===================================
sub names {
#===================================
    return (
        "Aardwolf",             "Adam II",
        "Agent",                "Airborne",
        "Aldebron",             "Alpha Ray",
        "American Samurai",     "Ancient One",
        "Angela Del Toro",      "Anomaly",
        "Apalla",               "Araña",
        "Arena",                "Armadillo",
        "Asbestos Man",         "Atlas",
        "Avalanche",            "Bantam",
        "Barracuda",            "Beaubier, Jeanne-Marie",
        "Bengal",               "Bird-Brain",
        "Black Fox",            "Black Tarantula",
        "Blevins, Sally",       "Bloke",
        "Bloodwraith",          "Bombshell",
        "Box",                  "Bridge, George Washington",
        "Brynocki",             "Buzz",
        "Calypso",              "Cap 'N Hawk",
        "Carnage",              "Cat-Man",
        "Chaka",                "Chi Demon",
        "Cloud 9",              "Colleen Wing",
        "Contemplator",         "Corsair",
        "Crimebuster",          "Crown",
        "D'Ken",                "Dark Beast",
        "Deadpool",             "De La Fontaine, Valentina Allegra",
        "Destroyer of Demons",  "Discus",
        "Doctor Leery",         "Doop",
        "Dragonfly",            "Double Helix",
        "Paul Norbert Ebersol", "ElectroCute",
        "Empathoid",            "Eric the Red",
        "Everyman",             "Famine",
        "Fearmaster",           "Firebolt",
        "Flex",                 "Forrester, Lee",
        "Freakmaster",          "Fury",
        "Ganymede",             "Gaza",
        "Ghost Dancer",         "Gideon Mace",
        "Glorian",              "Gorgeous George",
        "Great Video",          "Grim Hunter",
        "Guthrie, Paige",       "Hammer, Justin",
        "Felicia Hardy",        "Havok",
        "Heimdall",             "H.E.R.B.I.E.",
        "Hitman",               "Horus",
        "Human Torch II",       "Hyperion",
        "Illusion",             "Inferno",
        "Iron Man 2020",        "Jack of Hearts",
        "Jarvis, Edwin",        "Jim Hammond",
        "Josten, Conrad",       "Justin Hammer",
        "Karnak",               "Khaos",
        "Cessily Kincaid",      "Klaatu",
        "Kragoff, Ivan",        "Kylun",
        "La Nuit",              "Left Hand",
        "Lifeforce",            "Live Wire",
        "Lizard",               "Loki",
        "Lucifer",              "Mace, Gideon",
        "Madam Slay",           "Magician",
        "Malice",               "Mandrill",
        "Mariko Yashida",       "Mar-Vell",
        "Mastermind",           "Max",
        "Meggan",               "Mesmero",
        "Miek",                 "Miss America",
        "Mockingbird",          "Monsoon",
        "Morgan Le Fay",        "Ms. Steed",
        "N'Gabthoth",           "Nebulon",
        "Neuronne",             "Nightmare",
        "MN-E (Ultraverse)",    "Nova, Cassandra",
        "Obliterator",          "Omega the Unknown",
        "Orikal",               "Ozymandias",
        "Paste-Pot Pete",       "Perseus",
        "Phastos",              "Pitt, Desmond",
        "Possessor",            "Power Skrull",
        "Proctor",              "Psyche",
        "Purple Girl",          "Rachel van Helsing",
        "Rancor",               "Rax",
        "Red Ronin",            "Reynolds, Katherine",
        "Ringleader",           "Rogers, Steve",
        "Rush",                 "Salvo",
        "Sayge",                "Schultz, Herman",
        "Sea Urchin",           "Shadow-Hunter",
        "Sharon Friedlander",   "Shiva",
        "Sigyn",                "Simpson, Frank",
        "Skullfire",            "Slither",
        "Smythe, Alistair",     "Space Phantom",
        "Spider-Girl",          "Sprite",
        "Stakar",               "Starr the Slayer",
        "Stephen Colbert",      "Storm, Johnny",
        "Stygorr",              "Sunfire",
        "Super Sabre",          "The Symbiote",
        "Tarr, Black Jack",     "Temugin",
        "Thane Ector",          "Threnody",
        "Time Bomb",            "Tomorrow Man",
        "Trapper",              "Tugun",
        "Typhoid Mary",         "Ultron",
        "Urthona",              "Vamp",
        "Vegas",                "Vibraxas",
        "Vivisector",           "Jennifer Walters",
        "Scott Washington",     "Whitemane, Aelfyre",
        "Wildpride",            "The Wink",
        "Worm",                 "Charles Xavier",
        "Ymir",                 "Zemo, Heinrich"
    );
}

1;
