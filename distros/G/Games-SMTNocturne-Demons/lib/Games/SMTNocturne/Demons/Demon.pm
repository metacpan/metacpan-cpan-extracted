package Games::SMTNocturne::Demons::Demon;
BEGIN {
  $Games::SMTNocturne::Demons::Demon::AUTHORITY = 'cpan:DOY';
}
$Games::SMTNocturne::Demons::Demon::VERSION = '0.02';
use strict;
use warnings;
use overload '""' => 'to_string', fallback => 1;
# ABSTRACT: an individual demon

use JSON::PP;


my %DEMONS_BY_NAME = %{ decode_json(do { local $/; <DATA> }) };
for my $name (keys %DEMONS_BY_NAME) {
    $DEMONS_BY_NAME{$name}{name} = $name;
    $DEMONS_BY_NAME{$name} = bless $DEMONS_BY_NAME{$name}, __PACKAGE__;
}
my @DEMONS = sort {
    $a->level <=> $b->level || $a->name cmp $b->name
} values %DEMONS_BY_NAME;

my %DEMONS_BY_TYPE;
for my $name (keys %DEMONS_BY_NAME) {
    my $demon = $DEMONS_BY_NAME{$name};
    push @{ $DEMONS_BY_TYPE{$demon->type} ||= [] }, $demon;
}
for my $type (keys %DEMONS_BY_TYPE) {
    my $demons = $DEMONS_BY_TYPE{$type};
    @$demons = sort { $a->level <=> $b->level } @$demons;
}

sub from_name {
    my ($class, $name) = @_;

    die "unknown demon $name" unless $DEMONS_BY_NAME{$name};

    return $DEMONS_BY_NAME{$name};
}

sub all_demons {
    my $class = shift;
    return @DEMONS;
}

sub from_fusion_stats {
    my ($class, $options) = @_;

    die "unknown type $options->{type}"
        unless $DEMONS_BY_TYPE{$options->{type}};

    my @possible = @{ $DEMONS_BY_TYPE{$options->{type}} };

    @possible = grep { $_->fusion_type eq $options->{fusion_type} } @possible
        if $options->{fusion_type};

    my %bosses = map { $_ => 1 } @{ $options->{bosses} || [] };
    @possible = grep { !$_->boss || $bosses{$_->name} } @possible;

    my $found_idx;
    for my $i (0..$#possible) {
        $found_idx = $i;
        my $demon = $possible[$i];
        last if $demon->level >= $options->{level};
    }

    if ($options->{offset}) {
        $found_idx += $options->{offset} eq 'up' ? 1 : -1;
        $found_idx = 0 if $found_idx < 0;
        $found_idx = $#possible if $found_idx > $#possible;
    }

    return $possible[$found_idx];
}

sub from_type {
    my ($class, $type) = @_;

    die "unknown type $type" unless $DEMONS_BY_TYPE{$type};

    return @{ $DEMONS_BY_TYPE{$type} };
}


sub boss        { $_[0]->{boss} }
sub fusion_type { $_[0]->{fusion_type} }
sub level       { $_[0]->{level} }
sub name        { $_[0]->{name} }
sub type        { $_[0]->{type} }

sub to_string {
    my $self = shift;
    return '<' . $self->type . ' ' . $self->name . ' (' . $self->level . ')>'
}


1;

=pod

=encoding UTF-8

=head1 NAME

Games::SMTNocturne::Demons::Demon - an individual demon

=head1 VERSION

version 0.02

=head1 SYNOPSIS

  use Games::SMTNocturne::Demons 'demon';

  my $pixie = demon('Pixie');
  say $pixie->name  # 'Pixie'
  say $pixie->level # 2
  say $pixie->type  # 'Fairy'

=head1 DESCRIPTION

This class represents an individual demon. You typically create instances of
this class via the functions in the L<Games::SMTNocturne::Demons> package, and
you can then look up various data using the accessors here. This class also
includes a stringification overload to display the information about the demon
in a readable form.

=head1 METHODS

=head2 boss

True if the demon is a boss (meaning that fusing it will not be possible until
it has been defeated).

=head2 fusion_type

How this demon can be created. Can be C<normal> for demons that can be fused
normally, C<evolve> for demons that must be evolved, C<special> for demons
that require special fusions, and C<deathstone> for demons that require a
deathstone in order to fuse.

=head2 level

The base level of the demon. This level is what is used in the fusion process,
regardless of the experience level of the actual demon in your party.

=head2 name

The name of the demon.

=head2 type

The type of the demon (C<Fairy>, C<Yoma>, etc).

=for Pod::Coverage all_demons
  from_fusion_stats
  from_name
  from_type
  to_string

=head1 AUTHOR

Jesse Luehrs <doy@tozt.net>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Jesse Luehrs.

This is free software, licensed under:

  The MIT (X11) License

=cut

__DATA__
{
   "Abaddon" : {
      "fusion_type" : "normal",
      "level" : "69",
      "type" : "Tyrant"
   },
   "Aciel" : {
      "boss": true,
      "fusion_type" : "evolve",
      "level" : "77",
      "type" : "Tyrant"
   },
   "Aeros" : {
      "fusion_type" : "normal",
      "level" : "11",
      "type" : "Element"
   },
   "Albion" : {
      "fusion_type" : "evolve",
      "level" : "64",
      "type" : "Entity"
   },
   "Amaterasu" : {
      "fusion_type" : "special",
      "level" : "56",
      "type" : "Deity"
   },
   "Angel" : {
      "fusion_type" : "normal",
      "level" : "11",
      "type" : "Divine"
   },
   "Apsaras" : {
      "fusion_type" : "normal",
      "level" : "8",
      "type" : "Yoma"
   },
   "Aquans" : {
      "fusion_type" : "normal",
      "level" : "15",
      "type" : "Element"
   },
   "Ara Mitama" : {
      "fusion_type" : "normal",
      "level" : "25",
      "type" : "Mitama"
   },
   "Arahabaki" : {
      "fusion_type" : "evolve",
      "level" : "30",
      "type" : "Vile"
   },
   "Archangel" : {
      "fusion_type" : "normal",
      "level" : "18",
      "type" : "Divine"
   },
   "Atavaka" : {
      "fusion_type" : "normal",
      "level" : "47",
      "type" : "Deity"
   },
   "Atropos" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "67",
      "type" : "Femme"
   },
   "Badb Catha" : {
      "fusion_type" : "normal",
      "level" : "23",
      "type" : "Beast"
   },
   "Baihu" : {
      "fusion_type" : "normal",
      "level" : "43",
      "type" : "Holy"
   },
   "Baphomet" : {
      "fusion_type" : "normal",
      "level" : "33",
      "type" : "Vile"
   },
   "Barong" : {
      "fusion_type" : "normal",
      "level" : "60",
      "type" : "Avatar"
   },
   "Beelzebub" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "84",
      "type" : "Tyrant"
   },
   "Beelzebub (Fly)" : {
      "boss": true,
      "fusion_type" : "evolve",
      "level" : "95",
      "type" : "Tyrant"
   },
   "Beiji-Weng" : {
      "fusion_type" : "normal",
      "level" : "61",
      "type" : "Fury"
   },
   "Berith" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "37",
      "type" : "Fallen"
   },
   "Bicorn" : {
      "fusion_type" : "normal",
      "level" : "15",
      "type" : "Wilder"
   },
   "Bishamon" : {
      "fusion_type" : "normal",
      "level" : "72",
      "type" : "Kishin"
   },
   "Black Frost" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "66",
      "type" : "Night"
   },
   "Black Ooze" : {
      "fusion_type" : "normal",
      "level" : "28",
      "type" : "Foul"
   },
   "Black Rider" : {
      "boss": true,
      "fusion_type" : "deathstone",
      "level" : "61",
      "type" : "Fiend"
   },
   "Blob" : {
      "fusion_type" : "normal",
      "level" : "16",
      "type" : "Foul"
   },
   "Cai-Zhi" : {
      "fusion_type" : "normal",
      "level" : "26",
      "type" : "Avatar"
   },
   "Cerberus" : {
      "fusion_type" : "normal",
      "level" : "61",
      "type" : "Beast"
   },
   "Chatterskull" : {
      "fusion_type" : "normal",
      "level" : "20",
      "type" : "Haunt"
   },
   "Chimera" : {
      "fusion_type" : "normal",
      "level" : "55",
      "type" : "Holy"
   },
   "Choronzon" : {
      "fusion_type" : "normal",
      "level" : "11",
      "type" : "Haunt"
   },
   "Clotho" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "58",
      "type" : "Femme"
   },
   "Cu Chulainn" : {
      "fusion_type" : "evolve",
      "level" : "52",
      "type" : "Genma"
   },
   "Daisoujou" : {
      "boss": true,
      "fusion_type" : "deathstone",
      "level" : "37",
      "type" : "Fiend"
   },
   "Dakini" : {
      "fusion_type" : "normal",
      "level" : "52",
      "type" : "Femme"
   },
   "Datsue-Ba" : {
      "fusion_type" : "normal",
      "level" : "7",
      "type" : "Femme"
   },
   "Decarabia" : {
      "fusion_type" : "normal",
      "level" : "58",
      "type" : "Fallen"
   },
   "Dionysus" : {
      "fusion_type" : "normal",
      "level" : "44",
      "type" : "Fury"
   },
   "Dis" : {
      "fusion_type" : "normal",
      "level" : "23",
      "type" : "Yoma"
   },
   "Dominion" : {
      "fusion_type" : "normal",
      "level" : "50",
      "type" : "Divine"
   },
   "Efreet" : {
      "fusion_type" : "evolve",
      "level" : "52",
      "type" : "Yoma"
   },
   "Eligor" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "29",
      "type" : "Fallen"
   },
   "Erthys" : {
      "fusion_type" : "normal",
      "level" : "7",
      "type" : "Element"
   },
   "Feng Huang" : {
      "fusion_type" : "normal",
      "level" : "36",
      "type" : "Holy"
   },
   "Flaemis" : {
      "fusion_type" : "normal",
      "level" : "20",
      "type" : "Element"
   },
   "Flauros" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "68",
      "type" : "Fallen"
   },
   "Fomor" : {
      "fusion_type" : "normal",
      "level" : "18",
      "type" : "Night"
   },
   "Forneus" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "20",
      "type" : "Fallen"
   },
   "Futomimi" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "63",
      "type" : "Kishin"
   },
   "Fuu-Ki" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "66",
      "type" : "Brute"
   },
   "Gabriel" : {
      "boss": true,
      "fusion_type" : "special",
      "level" : "87",
      "type" : "Seraph"
   },
   "Ganesha" : {
      "fusion_type" : "evolve",
      "level" : "58",
      "type" : "Wargod"
   },
   "Garuda" : {
      "fusion_type" : "evolve",
      "level" : "63",
      "type" : "Avian"
   },
   "Girimehkala" : {
      "boss": true,
      "fusion_type" : "special",
      "level" : "58",
      "type" : "Vile"
   },
   "Gogmagog" : {
      "fusion_type" : "normal",
      "level" : "55",
      "type" : "Jirae"
   },
   "Gui Xian" : {
      "fusion_type" : "evolve",
      "level" : "24",
      "type" : "Dragon"
   },
   "Gurr" : {
      "fusion_type" : "special",
      "level" : "63",
      "type" : "Raptor"
   },
   "Hanuman" : {
      "fusion_type" : "evolve",
      "level" : "46",
      "type" : "Genma"
   },
   "Hell Biker" : {
      "boss": true,
      "fusion_type" : "deathstone",
      "level" : "42",
      "type" : "Fiend"
   },
   "High Pixie" : {
      "fusion_type" : "evolve",
      "level" : "10",
      "type" : "Fairy"
   },
   "Horus" : {
      "fusion_type" : "normal",
      "level" : "38",
      "type" : "Deity"
   },
   "Hresvelgr" : {
      "fusion_type" : "normal",
      "level" : "75",
      "type" : "Wilder"
   },
   "Hua Po" : {
      "fusion_type" : "normal",
      "level" : "5",
      "type" : "Jirae"
   },
   "Ikusa" : {
      "fusion_type" : "normal",
      "level" : "44",
      "type" : "Brute"
   },
   "Incubus" : {
      "fusion_type" : "normal",
      "level" : "25",
      "type" : "Night"
   },
   "Inugami" : {
      "fusion_type" : "normal",
      "level" : "13",
      "type" : "Beast"
   },
   "Isora" : {
      "fusion_type" : "normal",
      "level" : "14",
      "type" : "Yoma"
   },
   "Jack Frost" : {
      "fusion_type" : "normal",
      "level" : "7",
      "type" : "Fairy"
   },
   "Jinn" : {
      "fusion_type" : "normal",
      "level" : "44",
      "type" : "Yoma"
   },
   "Jikoku" : {
      "fusion_type" : "normal",
      "level" : "52",
      "type" : "Kishin"
   },
   "Kaiwan" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "47",
      "type" : "Night"
   },
   "Kali" : {
      "fusion_type" : "normal",
      "level" : "67",
      "type" : "Lady"
   },
   "Karasu" : {
      "fusion_type" : "evolve",
      "level" : "28",
      "type" : "Yoma"
   },
   "Kelpie" : {
      "fusion_type" : "normal",
      "level" : "26",
      "type" : "Fairy"
   },
   "Kikuri-Hime" : {
      "fusion_type" : "normal",
      "level" : "24",
      "type" : "Lady"
   },
   "Kin-Ki" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "59",
      "type" : "Brute"
   },
   "Kodama" : {
      "fusion_type" : "normal",
      "level" : "3",
      "type" : "Jirae"
   },
   "Koppa" : {
      "fusion_type" : "normal",
      "level" : "19",
      "type" : "Yoma"
   },
   "Koumoku" : {
      "fusion_type" : "normal",
      "level" : "33",
      "type" : "Kishin"
   },
   "Kurama" : {
      "fusion_type" : "evolve",
      "level" : "38",
      "type" : "Genma"
   },
   "Kushinada" : {
      "fusion_type" : "normal",
      "level" : "41",
      "type" : "Lady"
   },
   "Kusi Mitama" : {
      "fusion_type" : "normal",
      "level" : "32",
      "type" : "Mitama"
   },
   "Lachesis" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "63",
      "type" : "Femme"
   },
   "Laksmi" : {
      "fusion_type" : "normal",
      "level" : "54",
      "type" : "Megami"
   },
   "Legion" : {
      "fusion_type" : "normal",
      "level" : "49",
      "type" : "Haunt"
   },
   "Lilim" : {
      "fusion_type" : "normal",
      "level" : "8",
      "type" : "Night"
   },
   "Lilith" : {
      "fusion_type" : "evolve",
      "level" : "80",
      "type" : "Night"
   },
   "Loa" : {
      "fusion_type" : "normal",
      "level" : "53",
      "type" : "Night"
   },
   "Loki" : {
      "fusion_type" : "normal",
      "level" : "52",
      "type" : "Tyrant"
   },
   "Long" : {
      "fusion_type" : "evolve",
      "level" : "44",
      "type" : "Dragon"
   },
   "Mada" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "83",
      "type" : "Vile"
   },
   "Makami" : {
      "fusion_type" : "evolve",
      "level" : "22",
      "type" : "Avatar"
   },
   "Matador" : {
      "boss": true,
      "fusion_type" : "deathstone",
      "level" : "30",
      "type" : "Fiend"
   },
   "Metatron" : {
      "boss": true,
      "fusion_type" : "special",
      "level" : "95",
      "type" : "Seraph"
   },
   "Michael" : {
      "fusion_type" : "special",
      "level" : "90",
      "type" : "Seraph"
   },
   "Mikazuchi" : {
      "fusion_type" : "normal",
      "level" : "45",
      "type" : "Kishin"
   },
   "Minakata" : {
      "fusion_type" : "normal",
      "level" : "17",
      "type" : "Kishin"
   },
   "Mithra" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "78",
      "type" : "Deity"
   },
   "Mizuchi" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "34",
      "type" : "Snake"
   },
   "Momunofu" : {
      "fusion_type" : "normal",
      "level" : "20",
      "type" : "Brute"
   },
   "Mot" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "91",
      "type" : "Tyrant"
   },
   "Mothman" : {
      "fusion_type" : "normal",
      "level" : "43",
      "type" : "Wilder"
   },
   "Mou-Ryo" : {
      "fusion_type" : "normal",
      "level" : "7",
      "type" : "Foul"
   },
   "Naga" : {
      "fusion_type" : "normal",
      "level" : "28",
      "type" : "Snake"
   },
   "Nekomata" : {
      "fusion_type" : "normal",
      "level" : "18",
      "type" : "Beast"
   },
   "Nigi Mitama" : {
      "fusion_type" : "normal",
      "level" : "29",
      "type" : "Mitama"
   },
   "Nozuchi" : {
      "fusion_type" : "normal",
      "level" : "14",
      "type" : "Snake"
   },
   "Nue" : {
      "fusion_type" : "normal",
      "level" : "31",
      "type" : "Wilder"
   },
   "Nyx" : {
      "fusion_type" : "normal",
      "level" : "70",
      "type" : "Night"
   },
   "Oberon" : {
      "fusion_type" : "normal",
      "level" : "46",
      "type" : "Fairy"
   },
   "Odin" : {
      "fusion_type" : "normal",
      "level" : "65",
      "type" : "Deity"
   },
   "Okuninushi" : {
      "fusion_type" : "normal",
      "level" : "39",
      "type" : "Kishin"
   },
   "Ongyo-Ki" : {
      "boss": true,
      "fusion_type" : "special",
      "level" : "81",
      "type" : "Brute"
   },
   "Oni" : {
      "fusion_type" : "normal",
      "level" : "25",
      "type" : "Brute"
   },
   "Onkot" : {
      "fusion_type" : "normal",
      "level" : "37",
      "type" : "Yoma"
   },
   "Orthrus" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "34",
      "type" : "Beast"
   },
   "Ose" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "45",
      "type" : "Fallen"
   },
   "Pale Rider" : {
      "boss": true,
      "fusion_type" : "deathstone",
      "level" : "63",
      "type" : "Fiend"
   },
   "Parvati" : {
      "fusion_type" : "evolve",
      "level" : "57",
      "type" : "Lady"
   },
   "Pazuzu" : {
      "fusion_type" : "normal",
      "level" : "45",
      "type" : "Vile"
   },
   "Phantom" : {
      "fusion_type" : "normal",
      "level" : "42",
      "type" : "Foul"
   },
   "Pisaca" : {
      "fusion_type" : "normal",
      "level" : "28",
      "type" : "Haunt"
   },
   "Pixie" : {
      "fusion_type" : "normal",
      "level" : "2",
      "type" : "Fairy"
   },
   "Power" : {
      "fusion_type" : "normal",
      "level" : "33",
      "type" : "Divine"
   },
   "Preta" : {
      "fusion_type" : "normal",
      "level" : "4",
      "type" : "Haunt"
   },
   "Principality" : {
      "fusion_type" : "normal",
      "level" : "28",
      "type" : "Divine"
   },
   "Purski" : {
      "fusion_type" : "normal",
      "level" : "48",
      "type" : "Yoma"
   },
   "Pyro Jack" : {
      "fusion_type" : "normal",
      "level" : "19",
      "type" : "Fairy"
   },
   "Queen Mab" : {
      "fusion_type" : "evolve",
      "level" : "56",
      "type" : "Night"
   },
   "Quetzalcoatl" : {
      "fusion_type" : "normal",
      "level" : "55",
      "type" : "Snake"
   },
   "Raiju" : {
      "fusion_type" : "normal",
      "level" : "25",
      "type" : "Wilder"
   },
   "Raja Naga" : {
      "fusion_type" : "evolve",
      "level" : "37",
      "type" : "Snake"
   },
   "Rakshasa" : {
      "fusion_type" : "normal",
      "level" : "63",
      "type" : "Haunt"
   },
   "Rangda" : {
      "fusion_type" : "normal",
      "level" : "72",
      "type" : "Femme"
   },
   "Raphael" : {
      "boss": true,
      "fusion_type" : "special",
      "level" : "84",
      "type" : "Seraph"
   },
   "Red Rider" : {
      "boss": true,
      "fusion_type" : "deathstone",
      "level" : "55",
      "type" : "Fiend"
   },
   "Sakahagi" : {
      "boss": true,
      "fusion_type" : "special",
      "level" : "45",
      "type" : "Foul"
   },
   "Saki Mitama" : {
      "fusion_type" : "normal",
      "level" : "35",
      "type" : "Mitama"
   },
   "Samael" : {
      "boss": true,
      "fusion_type" : "special",
      "level" : "73",
      "type" : "Vile"
   },
   "Sarasvati" : {
      "fusion_type" : "normal",
      "level" : "30",
      "type" : "Megami"
   },
   "Sarutahiko" : {
      "fusion_type" : "normal",
      "level" : "35",
      "type" : "Jirae"
   },
   "Sati" : {
      "fusion_type" : "normal",
      "level" : "48",
      "type" : "Megami"
   },
   "Scathach" : {
      "fusion_type" : "normal",
      "level" : "64",
      "type" : "Megami"
   },
   "Senri" : {
      "fusion_type" : "evolve",
      "level" : "27",
      "type" : "Holy"
   },
   "Setanta" : {
      "fusion_type" : "normal",
      "level" : "43",
      "type" : "Fairy"
   },
   "Shadow" : {
      "fusion_type" : "normal",
      "level" : "52",
      "type" : "Foul"
   },
   "Shiisaa" : {
      "fusion_type" : "normal",
      "level" : "13",
      "type" : "Holy"
   },
   "Shiki-Ouji" : {
      "fusion_type" : "normal",
      "level" : "54",
      "type" : "Brute"
   },
   "Shikigami" : {
      "fusion_type" : "normal",
      "level" : "4",
      "type" : "Brute"
   },
   "Shikome" : {
      "fusion_type" : "normal",
      "level" : "32",
      "type" : "Femme"
   },
   "Shiva" : {
      "fusion_type" : "special",
      "level" : "95",
      "type" : "Fury"
   },
   "Skadi" : {
      "boss": true,
      "fusion_type" : "evolve",
      "level" : "74",
      "type" : "Lady"
   },
   "Slime" : {
      "fusion_type" : "normal",
      "level" : "6",
      "type" : "Foul"
   },
   "Sparna" : {
      "fusion_type" : "normal",
      "level" : "54",
      "type" : "Beast"
   },
   "Succubus" : {
      "fusion_type" : "normal",
      "level" : "37",
      "type" : "Night"
   },
   "Sudama" : {
      "fusion_type" : "normal",
      "level" : "13",
      "type" : "Jirae"
   },
   "Sui-Ki" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "62",
      "type" : "Brute"
   },
   "Surt" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "74",
      "type" : "Tyrant"
   },
   "Tao Tie" : {
      "fusion_type" : "normal",
      "level" : "65",
      "type" : "Vile"
   },
   "Taraka" : {
      "fusion_type" : "normal",
      "level" : "20",
      "type" : "Femme"
   },
   "The Harlot" : {
      "boss": true,
      "fusion_type" : "deathstone",
      "level" : "69",
      "type" : "Fiend"
   },
   "Thor" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "76",
      "type" : "Kishin"
   },
   "Throne" : {
      "fusion_type" : "normal",
      "level" : "64",
      "type" : "Divine"
   },
   "Titan" : {
      "fusion_type" : "normal",
      "level" : "49",
      "type" : "Jirae"
   },
   "Titania" : {
      "fusion_type" : "normal",
      "level" : "57",
      "type" : "Fairy"
   },
   "Troll" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "38",
      "type" : "Fairy"
   },
   "Trumpeter" : {
      "boss": true,
      "fusion_type" : "deathstone",
      "level" : "77",
      "type" : "Fiend"
   },
   "Unicorn" : {
      "fusion_type" : "normal",
      "level" : "21",
      "type" : "Holy"
   },
   "Uriel" : {
      "boss": true,
      "fusion_type" : "evolve",
      "level" : "73",
      "type" : "Seraph"
   },
   "Uzume" : {
      "fusion_type" : "normal",
      "level" : "18",
      "type" : "Megami"
   },
   "Valkyrie" : {
      "fusion_type" : "evolve",
      "level" : "33",
      "type" : "Wargod"
   },
   "Virtue" : {
      "fusion_type" : "normal",
      "level" : "41",
      "type" : "Divine"
   },
   "Vishnu" : {
      "fusion_type" : "normal",
      "level" : "93",
      "type" : "Deity"
   },
   "White Rider" : {
      "boss": true,
      "fusion_type" : "deathstone",
      "level" : "52",
      "type" : "Fiend"
   },
   "Will o' Wisp" : {
      "fusion_type" : "normal",
      "level" : "1",
      "type" : "Foul"
   },
   "Wu Kong" : {
      "fusion_type" : "evolve",
      "level" : "54",
      "type" : "Fury"
   },
   "Yaka" : {
      "fusion_type" : "normal",
      "level" : "17",
      "type" : "Haunt"
   },
   "Yaksini" : {
      "boss": true,
      "fusion_type" : "normal",
      "level" : "43",
      "type" : "Femme"
   },
   "Yatagarasu" : {
      "fusion_type" : "normal",
      "level" : "46",
      "type" : "Avatar"
   },
   "Yurlungur" : {
      "fusion_type" : "normal",
      "level" : "66",
      "type" : "Snake"
   },
   "Zhen" : {
      "fusion_type" : "normal",
      "level" : "6",
      "type" : "Wilder"
   },
   "Zouchou" : {
      "fusion_type" : "normal",
      "level" : "27",
      "type" : "Kishin"
   }
}
