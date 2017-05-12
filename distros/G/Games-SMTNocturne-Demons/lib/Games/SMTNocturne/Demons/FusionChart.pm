package Games::SMTNocturne::Demons::FusionChart;
BEGIN {
  $Games::SMTNocturne::Demons::FusionChart::AUTHORITY = 'cpan:DOY';
}
$Games::SMTNocturne::Demons::FusionChart::VERSION = '0.02';
use strict;
use warnings;

use JSON::PP;

my %FUSION_DATA = %{ decode_json(do { local $/; <DATA> }) };
my %TYPES = %{ $FUSION_DATA{normal_fusions} };
my %SPECIAL = %{ $FUSION_DATA{special_fusions} };

sub fuse {
    my ($type1, $type2) = @_;

    die "unknown demon type $type1" unless $TYPES{$type1};
    die "unknown demon type $type2" unless $TYPES{$type2};

    return $TYPES{$type1}{fusions}{$type2};
}

sub unfuse {
    my ($type) = @_;

    die "unknown demon type $type" unless $TYPES{$type};

    my @combinations;
    for my $type1 (keys %TYPES) {
        for my $type2 (grep { $_ ge $type1 } keys %TYPES) {
            push @combinations, [ $type1, $type2 ]
                if ($TYPES{$type1}{fusions}{$type2} || '') eq $type;
        }
    }

    return @combinations;
}

sub fuse_element {
    my ($type) = @_;

    return $TYPES{$type}{self_fusion};
}

sub element_fusion {
    my ($type, $element) = @_;

    return $TYPES{$type}{element_fusions}{$element};
}

sub fuse_mitama {
    my ($element1, $element2) = @_;

    # XXX move this into actual data somewhere
    my %mitama_fusions = (
        Erthys => {
            Aeros => 'Nigi Mitama',
            Aquans => 'Ara Mitama',
            Flaemis => 'Kusi Mitama',
        },
        Aeros => {
            Erthys => 'Nigi Mitama',
            Aquans => 'Kusi Mitama',
            Flaemis => 'Ara Mitama',
        },
        Aquans => {
            Erthys => 'Ara Mitama',
            Aeros => 'Kusi Mitama',
            Flaemis => 'Saki Mitama',
        },
        Flaemis => {
            Erthys => 'Kusi Mitama',
            Aeros => 'Ara Mitama',
            Aquans => 'Saki Mitama',
        },
    );

    return $mitama_fusions{$element1}{$element2};
}

sub special_fusion {
    my ($demon1, $demon2, $options) = @_;

    my $find = sub {
        my ($need, @have) = @_;

        if (my $name = $need->{name}) {
            return (grep { $_->name eq $name } @have)[0];
        }
        elsif (my $type = $need->{type}) {
            my @types = ref($need->{type}) ? @$type : ($type);
            return (
                grep { my $d = $_; grep { $d->type eq $_ } @types } @have
            )[0];
        }
        else {
            return undef;
        }
    };

    DEMON: for my $demon (keys %SPECIAL) {
        my $conditions = $SPECIAL{$demon};

        if ($conditions->{deathstone}) {
            next unless $options->{deathstone};
        }

        if (my $phases = $conditions->{kagutsuchi}) {
            next unless defined $options->{kagutsuchi}
                     && grep { $_ == $options->{kagutsuchi} } @$phases;
        }

        if (my $sacrifice = $conditions->{sacrifice}) {
            next unless $find->(
                $sacrifice,
                ($options->{sacrifice} ? ($options->{sacrifice}) : ())
            );
        }

        if (my $target = $conditions->{target}) {
            if (my $type = $target->{type}) {
                my $fused_type = fuse($demon1->type, $demon2->type);
                next unless $fused_type && $fused_type eq $type;
            }
            elsif (my $name = $target->{name}) {
                require Games::SMTNocturne::Demons;
                my $fused = Games::SMTNocturne::Demons::fuse(
                    $demon1, $demon2, { %$options, basic => 1 }
                );
                next unless $fused && $fused->name eq $name;
            }
            else {
                next;
            }
        }

        my @have = ($demon1, $demon2);
        push @have, $options->{sacrifice}
            if $conditions->{demon3} && $options->{sacrifice};

        for my $key (qw(demon1 demon2 demon3)) {
            if ($conditions->{$key}) {
                my $found = $find->($conditions->{$key}, @have);
                next DEMON unless $found;
                @have = grep { $_ ne $found } @have;
            }
        }

        return $demon;
    }

    return;
}

sub special_fusion_for {
    my ($demon) = @_;

    return unless $SPECIAL{$demon};
    return { %{ $SPECIAL{$demon} } };
}

=for Pod::Coverage
  element_fusion
  fuse
  fuse_element
  fuse_mitama
  special_fusion
  special_fusion_for
  unfuse

=cut

1;

__DATA__
{
   "normal_fusions" : {
      "Avatar" : {
         "element_fusions" : {
            "Aeros" : null,
            "Aquans" : null,
            "Erthys" : null,
            "Flaemis" : null
         },
         "fusions" : {
            "Avatar" : null,
            "Avian" : "Holy",
            "Beast" : "Snake",
            "Brute" : "Kishin",
            "Deity" : "Megami",
            "Divine" : "Megami",
            "Dragon" : "Fury",
            "Element" : null,
            "Entity" : "Fury",
            "Fairy" : "Divine",
            "Fallen" : "Divine",
            "Femme" : "Kishin",
            "Fiend" : null,
            "Foul" : null,
            "Fury" : "Holy",
            "Genma" : "Kishin",
            "Haunt" : null,
            "Holy" : "Megami",
            "Jirae" : "Kishin",
            "Kishin" : "Holy",
            "Lady" : "Fury",
            "Megami" : "Deity",
            "Mitama" : "Avatar",
            "Night" : "Holy",
            "Raptor" : "Wilder",
            "Seraph" : "Deity",
            "Snake" : "Lady",
            "Tyrant" : null,
            "Vile" : "Deity",
            "Wargod" : "Deity",
            "Wilder" : null,
            "Yoma" : "Divine"
         },
         "self_fusion" : null
      },
      "Avian" : {
         "element_fusions" : {
            "Aeros" : null,
            "Aquans" : null,
            "Erthys" : null,
            "Flaemis" : null
         },
         "fusions" : {
            "Avatar" : "Holy",
            "Avian" : null,
            "Beast" : "Femme",
            "Brute" : "Kishin",
            "Deity" : "Megami",
            "Divine" : "Snake",
            "Dragon" : "Fury",
            "Element" : null,
            "Entity" : "Deity",
            "Fairy" : "Night",
            "Fallen" : "Snake",
            "Femme" : "Brute",
            "Fiend" : null,
            "Foul" : null,
            "Fury" : "Kishin",
            "Genma" : "Megami",
            "Haunt" : null,
            "Holy" : "Lady",
            "Jirae" : "Kishin",
            "Kishin" : "Lady",
            "Lady" : null,
            "Megami" : "Deity",
            "Mitama" : "Avian",
            "Night" : "Femme",
            "Raptor" : "Megami",
            "Seraph" : "Megami",
            "Snake" : "Kishin",
            "Tyrant" : null,
            "Vile" : null,
            "Wargod" : "Kishin",
            "Wilder" : null,
            "Yoma" : "Night"
         },
         "self_fusion" : null
      },
      "Beast" : {
         "element_fusions" : {
            "Aeros" : "up",
            "Aquans" : "down",
            "Erthys" : "down",
            "Flaemis" : "up"
         },
         "fusions" : {
            "Avatar" : "Snake",
            "Avian" : "Femme",
            "Beast" : "Element",
            "Brute" : "Femme",
            "Deity" : "Avatar",
            "Divine" : "Holy",
            "Dragon" : "Snake",
            "Element" : "Beast",
            "Entity" : "Holy",
            "Fairy" : "Divine",
            "Fallen" : "Night",
            "Femme" : "Foul",
            "Fiend" : "Night",
            "Foul" : "Wilder",
            "Fury" : "Avatar",
            "Genma" : "Fairy",
            "Haunt" : "Wilder",
            "Holy" : "Avatar",
            "Jirae" : "Yoma",
            "Kishin" : "Holy",
            "Lady" : "Snake",
            "Megami" : "Holy",
            "Mitama" : "Beast",
            "Night" : "Fairy",
            "Raptor" : "Wilder",
            "Seraph" : null,
            "Snake" : "Brute",
            "Tyrant" : "Night",
            "Vile" : "Foul",
            "Wargod" : "Holy",
            "Wilder" : "Jirae",
            "Yoma" : "Fallen"
         },
         "self_fusion" : "Aeros"
      },
      "Brute" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "up",
            "Erthys" : "up",
            "Flaemis" : "up"
         },
         "fusions" : {
            "Avatar" : "Kishin",
            "Avian" : "Kishin",
            "Beast" : "Femme",
            "Brute" : "Element",
            "Deity" : "Kishin",
            "Divine" : "Yoma",
            "Dragon" : "Night",
            "Element" : "Brute",
            "Entity" : "Fury",
            "Fairy" : "Night",
            "Fallen" : "Jirae",
            "Femme" : "Beast",
            "Fiend" : "Haunt",
            "Foul" : "Wilder",
            "Fury" : "Lady",
            "Genma" : "Divine",
            "Haunt" : "Foul",
            "Holy" : "Femme",
            "Jirae" : "Fairy",
            "Kishin" : "Snake",
            "Lady" : "Fury",
            "Megami" : "Femme",
            "Mitama" : "Brute",
            "Night" : "Kishin",
            "Raptor" : "Fury",
            "Seraph" : null,
            "Snake" : "Beast",
            "Tyrant" : "Haunt",
            "Vile" : "Haunt",
            "Wargod" : null,
            "Wilder" : "Fairy",
            "Yoma" : "Femme"
         },
         "self_fusion" : "Erthys"
      },
      "Deity" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "down",
            "Erthys" : "down",
            "Flaemis" : "down"
         },
         "fusions" : {
            "Avatar" : "Megami",
            "Avian" : "Megami",
            "Beast" : "Avatar",
            "Brute" : "Kishin",
            "Deity" : null,
            "Divine" : "Megami",
            "Dragon" : null,
            "Element" : "Deity",
            "Entity" : "Megami",
            "Fairy" : "Night",
            "Fallen" : "Fury",
            "Femme" : "Lady",
            "Fiend" : null,
            "Foul" : null,
            "Fury" : null,
            "Genma" : "Megami",
            "Haunt" : null,
            "Holy" : "Megami",
            "Jirae" : "Brute",
            "Kishin" : "Fury",
            "Lady" : null,
            "Megami" : null,
            "Mitama" : "Deity",
            "Night" : "Vile",
            "Raptor" : "Tyrant",
            "Seraph" : null,
            "Snake" : "Kishin",
            "Tyrant" : null,
            "Vile" : null,
            "Wargod" : "Kishin",
            "Wilder" : null,
            "Yoma" : "Megami"
         },
         "self_fusion" : null
      },
      "Divine" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "up",
            "Erthys" : "down",
            "Flaemis" : "up"
         },
         "fusions" : {
            "Avatar" : "Megami",
            "Avian" : "Snake",
            "Beast" : "Holy",
            "Brute" : "Yoma",
            "Deity" : "Megami",
            "Divine" : "Element",
            "Dragon" : "Megami",
            "Element" : "Divine",
            "Entity" : "Megami",
            "Fairy" : "Megami",
            "Fallen" : "Vile",
            "Femme" : "Beast",
            "Fiend" : "Vile",
            "Foul" : "Fairy",
            "Fury" : "Deity",
            "Genma" : "Megami",
            "Haunt" : "Jirae",
            "Holy" : "Fairy",
            "Jirae" : "Night",
            "Kishin" : "Vile",
            "Lady" : "Megami",
            "Megami" : "Holy",
            "Mitama" : "Divine",
            "Night" : "Snake",
            "Raptor" : "Foul",
            "Seraph" : "Megami",
            "Snake" : "Fairy",
            "Tyrant" : "Vile",
            "Vile" : "Fallen",
            "Wargod" : "Holy",
            "Wilder" : "Fallen",
            "Yoma" : "Snake"
         },
         "self_fusion" : "Aeros"
      },
      "Dragon" : {
         "element_fusions" : {
            "Aeros" : null,
            "Aquans" : null,
            "Erthys" : null,
            "Flaemis" : null
         },
         "fusions" : {
            "Avatar" : "Fury",
            "Avian" : "Fury",
            "Beast" : "Snake",
            "Brute" : "Night",
            "Deity" : null,
            "Divine" : "Megami",
            "Dragon" : null,
            "Element" : null,
            "Entity" : "Lady",
            "Fairy" : "Snake",
            "Fallen" : "Snake",
            "Femme" : "Night",
            "Fiend" : null,
            "Foul" : "Snake",
            "Fury" : null,
            "Genma" : "Holy",
            "Haunt" : null,
            "Holy" : "Snake",
            "Jirae" : "Kishin",
            "Kishin" : "Fury",
            "Lady" : null,
            "Megami" : "Avatar",
            "Mitama" : "Dragon",
            "Night" : "Femme",
            "Raptor" : null,
            "Seraph" : "Holy",
            "Snake" : "Lady",
            "Tyrant" : null,
            "Vile" : "Snake",
            "Wargod" : "Lady",
            "Wilder" : null,
            "Yoma" : "Avatar"
         },
         "self_fusion" : null
      },
      "Element" : {
         "element_fusions" : {
            "Aeros" : null,
            "Aquans" : null,
            "Erthys" : null,
            "Flaemis" : null
         },
         "fusions" : {
            "Avatar" : null,
            "Avian" : null,
            "Beast" : "Beast",
            "Brute" : "Brute",
            "Deity" : "Deity",
            "Divine" : "Divine",
            "Dragon" : null,
            "Element" : "Mitama",
            "Entity" : null,
            "Fairy" : "Fairy",
            "Fallen" : "Fallen",
            "Femme" : "Femme",
            "Fiend" : null,
            "Foul" : "Foul",
            "Fury" : "Fury",
            "Genma" : null,
            "Haunt" : "Haunt",
            "Holy" : "Holy",
            "Jirae" : "Jirae",
            "Kishin" : "Kishin",
            "Lady" : "Lady",
            "Megami" : "Megami",
            "Mitama" : "Element",
            "Night" : "Night",
            "Raptor" : null,
            "Seraph" : null,
            "Snake" : "Snake",
            "Tyrant" : "Tyrant",
            "Vile" : "Vile",
            "Wargod" : null,
            "Wilder" : "Wilder",
            "Yoma" : "Yoma"
         },
         "self_fusion" : null
      },
      "Entity" : {
         "element_fusions" : {
            "Aeros" : null,
            "Aquans" : null,
            "Erthys" : null,
            "Flaemis" : null
         },
         "fusions" : {
            "Avatar" : "Fury",
            "Avian" : "Deity",
            "Beast" : "Holy",
            "Brute" : "Fury",
            "Deity" : "Megami",
            "Divine" : "Megami",
            "Dragon" : "Lady",
            "Element" : null,
            "Entity" : null,
            "Fairy" : "Megami",
            "Fallen" : "Kishin",
            "Femme" : "Lady",
            "Fiend" : null,
            "Foul" : "Brute",
            "Fury" : "Lady",
            "Genma" : "Fury",
            "Haunt" : "Brute",
            "Holy" : "Kishin",
            "Jirae" : "Fury",
            "Kishin" : "Fury",
            "Lady" : "Fury",
            "Megami" : "Deity",
            "Mitama" : "Entity",
            "Night" : "Brute",
            "Raptor" : "Vile",
            "Seraph" : "Deity",
            "Snake" : "Fury",
            "Tyrant" : null,
            "Vile" : null,
            "Wargod" : "Fury",
            "Wilder" : "Brute",
            "Yoma" : "Megami"
         },
         "self_fusion" : null
      },
      "Fairy" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "up",
            "Erthys" : "up",
            "Flaemis" : "down"
         },
         "fusions" : {
            "Avatar" : "Divine",
            "Avian" : "Night",
            "Beast" : "Divine",
            "Brute" : "Night",
            "Deity" : "Night",
            "Divine" : "Megami",
            "Dragon" : "Snake",
            "Element" : "Fairy",
            "Entity" : "Megami",
            "Fairy" : "Element",
            "Fallen" : "Yoma",
            "Femme" : "Haunt",
            "Fiend" : "Night",
            "Foul" : "Haunt",
            "Fury" : "Brute",
            "Genma" : null,
            "Haunt" : "Night",
            "Holy" : "Megami",
            "Jirae" : "Yoma",
            "Kishin" : "Brute",
            "Lady" : "Yoma",
            "Megami" : "Fallen",
            "Mitama" : "Fairy",
            "Night" : "Snake",
            "Raptor" : "Haunt",
            "Seraph" : "Holy",
            "Snake" : "Yoma",
            "Tyrant" : "Night",
            "Vile" : "Night",
            "Wargod" : null,
            "Wilder" : "Yoma",
            "Yoma" : "Holy"
         },
         "self_fusion" : "Aeros"
      },
      "Fallen" : {
         "element_fusions" : {
            "Aeros" : "up",
            "Aquans" : "down",
            "Erthys" : "down",
            "Flaemis" : "up"
         },
         "fusions" : {
            "Avatar" : "Divine",
            "Avian" : "Snake",
            "Beast" : "Night",
            "Brute" : "Jirae",
            "Deity" : "Fury",
            "Divine" : "Vile",
            "Dragon" : "Snake",
            "Element" : "Fallen",
            "Entity" : "Kishin",
            "Fairy" : "Yoma",
            "Fallen" : "Element",
            "Femme" : "Wilder",
            "Fiend" : "Fury",
            "Foul" : "Vile",
            "Fury" : "Vile",
            "Genma" : "Lady",
            "Haunt" : "Night",
            "Holy" : "Beast",
            "Jirae" : "Brute",
            "Kishin" : "Night",
            "Lady" : "Fury",
            "Megami" : "Divine",
            "Mitama" : "Fallen",
            "Night" : "Haunt",
            "Raptor" : "Foul",
            "Seraph" : "Lady",
            "Snake" : "Beast",
            "Tyrant" : "Fury",
            "Vile" : "Brute",
            "Wargod" : "Lady",
            "Wilder" : "Night",
            "Yoma" : "Jirae"
         },
         "self_fusion" : "Erthys"
      },
      "Femme" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "up",
            "Erthys" : "up",
            "Flaemis" : "up"
         },
         "fusions" : {
            "Avatar" : "Kishin",
            "Avian" : "Brute",
            "Beast" : "Foul",
            "Brute" : "Beast",
            "Deity" : "Lady",
            "Divine" : "Beast",
            "Dragon" : "Night",
            "Element" : "Femme",
            "Entity" : "Lady",
            "Fairy" : "Haunt",
            "Fallen" : "Wilder",
            "Femme" : "Element",
            "Fiend" : "Lady",
            "Foul" : "Wilder",
            "Fury" : "Lady",
            "Genma" : "Night",
            "Haunt" : "Foul",
            "Holy" : "Lady",
            "Jirae" : "Wilder",
            "Kishin" : "Lady",
            "Lady" : "Kishin",
            "Megami" : "Fairy",
            "Mitama" : "Femme",
            "Night" : "Jirae",
            "Raptor" : "Foul",
            "Seraph" : null,
            "Snake" : "Kishin",
            "Tyrant" : "Lady",
            "Vile" : "Brute",
            "Wargod" : null,
            "Wilder" : "Fallen",
            "Yoma" : "Brute"
         },
         "self_fusion" : "Aquans"
      },
      "Fiend" : {
         "element_fusions" : {
            "Aeros" : null,
            "Aquans" : null,
            "Erthys" : null,
            "Flaemis" : null
         },
         "fusions" : {
            "Avatar" : null,
            "Avian" : null,
            "Beast" : "Night",
            "Brute" : "Haunt",
            "Deity" : null,
            "Divine" : "Vile",
            "Dragon" : null,
            "Element" : null,
            "Entity" : null,
            "Fairy" : "Night",
            "Fallen" : "Fury",
            "Femme" : "Lady",
            "Fiend" : null,
            "Foul" : "Haunt",
            "Fury" : "Deity",
            "Genma" : "Yoma",
            "Haunt" : "Foul",
            "Holy" : null,
            "Jirae" : "Wilder",
            "Kishin" : null,
            "Lady" : null,
            "Megami" : null,
            "Mitama" : "Fiend",
            "Night" : "Lady",
            "Raptor" : "Fury",
            "Seraph" : "Fallen",
            "Snake" : "Brute",
            "Tyrant" : null,
            "Vile" : "Fury",
            "Wargod" : null,
            "Wilder" : "Night",
            "Yoma" : "Night"
         },
         "self_fusion" : null
      },
      "Foul" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "up",
            "Erthys" : "down",
            "Flaemis" : "down"
         },
         "fusions" : {
            "Avatar" : null,
            "Avian" : null,
            "Beast" : "Wilder",
            "Brute" : "Wilder",
            "Deity" : null,
            "Divine" : "Fairy",
            "Dragon" : "Snake",
            "Element" : "Foul",
            "Entity" : "Brute",
            "Fairy" : "Haunt",
            "Fallen" : "Vile",
            "Femme" : "Wilder",
            "Fiend" : "Haunt",
            "Foul" : null,
            "Fury" : null,
            "Genma" : null,
            "Haunt" : "Brute",
            "Holy" : null,
            "Jirae" : "Femme",
            "Kishin" : null,
            "Lady" : "Vile",
            "Megami" : null,
            "Mitama" : "Foul",
            "Night" : "Brute",
            "Raptor" : "Vile",
            "Seraph" : "Fallen",
            "Snake" : "Fallen",
            "Tyrant" : "Haunt",
            "Vile" : "Haunt",
            "Wargod" : null,
            "Wilder" : "Beast",
            "Yoma" : "Snake"
         },
         "self_fusion" : null
      },
      "Fury" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "down",
            "Erthys" : "down",
            "Flaemis" : "down"
         },
         "fusions" : {
            "Avatar" : "Holy",
            "Avian" : "Kishin",
            "Beast" : "Avatar",
            "Brute" : "Lady",
            "Deity" : null,
            "Divine" : "Deity",
            "Dragon" : null,
            "Element" : "Fury",
            "Entity" : "Lady",
            "Fairy" : "Brute",
            "Fallen" : "Vile",
            "Femme" : "Lady",
            "Fiend" : "Deity",
            "Foul" : null,
            "Fury" : null,
            "Genma" : "Lady",
            "Haunt" : null,
            "Holy" : "Kishin",
            "Jirae" : "Femme",
            "Kishin" : "Lady",
            "Lady" : "Vile",
            "Megami" : "Deity",
            "Mitama" : "Fury",
            "Night" : "Lady",
            "Raptor" : "Tyrant",
            "Seraph" : "Vile",
            "Snake" : "Kishin",
            "Tyrant" : "Deity",
            "Vile" : "Tyrant",
            "Wargod" : "Deity",
            "Wilder" : null,
            "Yoma" : "Holy"
         },
         "self_fusion" : null
      },
      "Genma" : {
         "element_fusions" : {
            "Aeros" : null,
            "Aquans" : null,
            "Erthys" : null,
            "Flaemis" : null
         },
         "fusions" : {
            "Avatar" : "Kishin",
            "Avian" : "Megami",
            "Beast" : "Fairy",
            "Brute" : "Divine",
            "Deity" : "Megami",
            "Divine" : "Megami",
            "Dragon" : "Holy",
            "Element" : null,
            "Entity" : "Fury",
            "Fairy" : null,
            "Fallen" : "Lady",
            "Femme" : "Night",
            "Fiend" : "Yoma",
            "Foul" : null,
            "Fury" : "Lady",
            "Genma" : null,
            "Haunt" : null,
            "Holy" : "Yoma",
            "Jirae" : "Lady",
            "Kishin" : "Megami",
            "Lady" : "Femme",
            "Megami" : "Divine",
            "Mitama" : "Genma",
            "Night" : "Holy",
            "Raptor" : "Lady",
            "Seraph" : "Megami",
            "Snake" : "Femme",
            "Tyrant" : "Yoma",
            "Vile" : "Yoma",
            "Wargod" : "Holy",
            "Wilder" : "Yoma",
            "Yoma" : null
         },
         "self_fusion" : null
      },
      "Haunt" : {
         "element_fusions" : {
            "Aeros" : "up",
            "Aquans" : "down",
            "Erthys" : "down",
            "Flaemis" : "down"
         },
         "fusions" : {
            "Avatar" : null,
            "Avian" : null,
            "Beast" : "Wilder",
            "Brute" : "Foul",
            "Deity" : null,
            "Divine" : "Jirae",
            "Dragon" : null,
            "Element" : "Haunt",
            "Entity" : "Brute",
            "Fairy" : "Night",
            "Fallen" : "Night",
            "Femme" : "Foul",
            "Fiend" : "Foul",
            "Foul" : "Brute",
            "Fury" : null,
            "Genma" : null,
            "Haunt" : null,
            "Holy" : null,
            "Jirae" : "Vile",
            "Kishin" : null,
            "Lady" : "Vile",
            "Megami" : null,
            "Mitama" : "Haunt",
            "Night" : "Yoma",
            "Raptor" : "Vile",
            "Seraph" : "Fallen",
            "Snake" : "Brute",
            "Tyrant" : "Foul",
            "Vile" : "Foul",
            "Wargod" : null,
            "Wilder" : "Jirae",
            "Yoma" : "Jirae"
         },
         "self_fusion" : null
      },
      "Holy" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "down",
            "Erthys" : "down",
            "Flaemis" : "up"
         },
         "fusions" : {
            "Avatar" : "Megami",
            "Avian" : "Lady",
            "Beast" : "Avatar",
            "Brute" : "Femme",
            "Deity" : "Megami",
            "Divine" : "Fairy",
            "Dragon" : "Snake",
            "Element" : "Holy",
            "Entity" : "Kishin",
            "Fairy" : "Megami",
            "Fallen" : "Beast",
            "Femme" : "Lady",
            "Fiend" : null,
            "Foul" : null,
            "Fury" : "Kishin",
            "Genma" : "Yoma",
            "Haunt" : null,
            "Holy" : "Element",
            "Jirae" : "Beast",
            "Kishin" : "Lady",
            "Lady" : "Avatar",
            "Megami" : "Divine",
            "Mitama" : "Holy",
            "Night" : "Fairy",
            "Raptor" : "Wilder",
            "Seraph" : "Divine",
            "Snake" : "Kishin",
            "Tyrant" : null,
            "Vile" : null,
            "Wargod" : "Kishin",
            "Wilder" : null,
            "Yoma" : "Divine"
         },
         "self_fusion" : "Flaemis"
      },
      "Jirae" : {
         "element_fusions" : {
            "Aeros" : "up",
            "Aquans" : "down",
            "Erthys" : "up",
            "Flaemis" : "down"
         },
         "fusions" : {
            "Avatar" : "Kishin",
            "Avian" : "Kishin",
            "Beast" : "Yoma",
            "Brute" : "Fairy",
            "Deity" : "Brute",
            "Divine" : "Night",
            "Dragon" : "Kishin",
            "Element" : "Jirae",
            "Entity" : "Fury",
            "Fairy" : "Yoma",
            "Fallen" : "Brute",
            "Femme" : "Wilder",
            "Fiend" : "Wilder",
            "Foul" : "Femme",
            "Fury" : "Femme",
            "Genma" : "Lady",
            "Haunt" : "Vile",
            "Holy" : "Beast",
            "Jirae" : "Element",
            "Kishin" : "Snake",
            "Lady" : "Beast",
            "Megami" : "Lady",
            "Mitama" : "Jirae",
            "Night" : "Foul",
            "Raptor" : "Foul",
            "Seraph" : null,
            "Snake" : "Fallen",
            "Tyrant" : "Wilder",
            "Vile" : "Haunt",
            "Wargod" : "Kishin",
            "Wilder" : "Brute",
            "Yoma" : "Beast"
         },
         "self_fusion" : "Erthys"
      },
      "Kishin" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "down",
            "Erthys" : "up",
            "Flaemis" : "down"
         },
         "fusions" : {
            "Avatar" : "Holy",
            "Avian" : "Lady",
            "Beast" : "Holy",
            "Brute" : "Snake",
            "Deity" : "Fury",
            "Divine" : "Vile",
            "Dragon" : "Fury",
            "Element" : "Kishin",
            "Entity" : "Fury",
            "Fairy" : "Brute",
            "Fallen" : "Night",
            "Femme" : "Lady",
            "Fiend" : null,
            "Foul" : null,
            "Fury" : "Lady",
            "Genma" : "Megami",
            "Haunt" : null,
            "Holy" : "Lady",
            "Jirae" : "Snake",
            "Kishin" : null,
            "Lady" : "Fury",
            "Megami" : "Lady",
            "Mitama" : "Kishin",
            "Night" : "Femme",
            "Raptor" : "Tyrant",
            "Seraph" : "Divine",
            "Snake" : "Femme",
            "Tyrant" : null,
            "Vile" : null,
            "Wargod" : "Fury",
            "Wilder" : null,
            "Yoma" : "Femme"
         },
         "self_fusion" : null
      },
      "Lady" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "down",
            "Erthys" : "up",
            "Flaemis" : "down"
         },
         "fusions" : {
            "Avatar" : "Fury",
            "Avian" : null,
            "Beast" : "Snake",
            "Brute" : "Fury",
            "Deity" : null,
            "Divine" : "Megami",
            "Dragon" : null,
            "Element" : "Lady",
            "Entity" : "Fury",
            "Fairy" : "Yoma",
            "Fallen" : "Fury",
            "Femme" : "Kishin",
            "Fiend" : null,
            "Foul" : "Vile",
            "Fury" : "Vile",
            "Genma" : "Femme",
            "Haunt" : "Vile",
            "Holy" : "Avatar",
            "Jirae" : "Beast",
            "Kishin" : "Fury",
            "Lady" : null,
            "Megami" : "Fury",
            "Mitama" : "Lady",
            "Night" : "Kishin",
            "Raptor" : "Kishin",
            "Seraph" : "Deity",
            "Snake" : "Femme",
            "Tyrant" : null,
            "Vile" : null,
            "Wargod" : "Kishin",
            "Wilder" : "Haunt",
            "Yoma" : "Night"
         },
         "self_fusion" : null
      },
      "Megami" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "down",
            "Erthys" : "down",
            "Flaemis" : "down"
         },
         "fusions" : {
            "Avatar" : "Deity",
            "Avian" : "Deity",
            "Beast" : "Holy",
            "Brute" : "Femme",
            "Deity" : null,
            "Divine" : "Holy",
            "Dragon" : "Avatar",
            "Element" : "Megami",
            "Entity" : "Deity",
            "Fairy" : "Fallen",
            "Fallen" : "Divine",
            "Femme" : "Fairy",
            "Fiend" : null,
            "Foul" : null,
            "Fury" : "Deity",
            "Genma" : "Divine",
            "Haunt" : null,
            "Holy" : "Divine",
            "Jirae" : "Lady",
            "Kishin" : "Lady",
            "Lady" : "Fury",
            "Megami" : null,
            "Mitama" : "Megami",
            "Night" : "Fallen",
            "Raptor" : "Tyrant",
            "Seraph" : "Deity",
            "Snake" : "Fairy",
            "Tyrant" : null,
            "Vile" : "Fury",
            "Wargod" : "Deity",
            "Wilder" : "Vile",
            "Yoma" : "Kishin"
         },
         "self_fusion" : null
      },
      "Mitama" : {
         "element_fusions" : {
            "Aeros" : null,
            "Aquans" : null,
            "Erthys" : null,
            "Flaemis" : null
         },
         "fusions" : {
            "Avatar" : "Avatar",
            "Avian" : "Avian",
            "Beast" : "Beast",
            "Brute" : "Brute",
            "Deity" : "Deity",
            "Divine" : "Divine",
            "Dragon" : "Dragon",
            "Element" : "Element",
            "Entity" : "Entity",
            "Fairy" : "Fairy",
            "Fallen" : "Fallen",
            "Femme" : "Femme",
            "Fiend" : "Fiend",
            "Foul" : "Foul",
            "Fury" : "Fury",
            "Genma" : "Genma",
            "Haunt" : "Haunt",
            "Holy" : "Holy",
            "Jirae" : "Jirae",
            "Kishin" : "Kishin",
            "Lady" : "Lady",
            "Megami" : "Megami",
            "Mitama" : "Mitama",
            "Night" : "Night",
            "Raptor" : "Raptor",
            "Seraph" : "Seraph",
            "Snake" : "Snake",
            "Tyrant" : "Tyrant",
            "Vile" : "Vile",
            "Wargod" : "Wargod",
            "Wilder" : "Wilder",
            "Yoma" : "Yoma"
         },
         "self_fusion" : null
      },
      "Night" : {
         "element_fusions" : {
            "Aeros" : "up",
            "Aquans" : "down",
            "Erthys" : "down",
            "Flaemis" : "down"
         },
         "fusions" : {
            "Avatar" : "Holy",
            "Avian" : "Femme",
            "Beast" : "Fairy",
            "Brute" : "Kishin",
            "Deity" : "Vile",
            "Divine" : "Snake",
            "Dragon" : "Femme",
            "Element" : "Night",
            "Entity" : "Brute",
            "Fairy" : "Snake",
            "Fallen" : "Haunt",
            "Femme" : "Jirae",
            "Fiend" : "Lady",
            "Foul" : "Brute",
            "Fury" : "Lady",
            "Genma" : "Holy",
            "Haunt" : "Yoma",
            "Holy" : "Fairy",
            "Jirae" : "Foul",
            "Kishin" : "Femme",
            "Lady" : "Kishin",
            "Megami" : "Fallen",
            "Mitama" : "Night",
            "Night" : "Element",
            "Raptor" : "Vile",
            "Seraph" : "Fallen",
            "Snake" : "Fallen",
            "Tyrant" : "Lady",
            "Vile" : "Lady",
            "Wargod" : null,
            "Wilder" : "Beast",
            "Yoma" : "Divine"
         },
         "self_fusion" : "Erthys"
      },
      "Raptor" : {
         "element_fusions" : {
            "Aeros" : null,
            "Aquans" : null,
            "Erthys" : null,
            "Flaemis" : null
         },
         "fusions" : {
            "Avatar" : "Wilder",
            "Avian" : "Megami",
            "Beast" : "Wilder",
            "Brute" : "Fury",
            "Deity" : "Tyrant",
            "Divine" : "Foul",
            "Dragon" : null,
            "Element" : null,
            "Entity" : "Vile",
            "Fairy" : "Haunt",
            "Fallen" : "Foul",
            "Femme" : "Foul",
            "Fiend" : "Fury",
            "Foul" : "Vile",
            "Fury" : "Tyrant",
            "Genma" : "Lady",
            "Haunt" : "Vile",
            "Holy" : "Wilder",
            "Jirae" : "Foul",
            "Kishin" : "Tyrant",
            "Lady" : "Kishin",
            "Megami" : "Tyrant",
            "Mitama" : "Raptor",
            "Night" : "Vile",
            "Raptor" : null,
            "Seraph" : null,
            "Snake" : "Foul",
            "Tyrant" : "Fury",
            "Vile" : "Fury",
            "Wargod" : null,
            "Wilder" : "Vile",
            "Yoma" : "Haunt"
         },
         "self_fusion" : null
      },
      "Seraph" : {
         "element_fusions" : {
            "Aeros" : null,
            "Aquans" : null,
            "Erthys" : null,
            "Flaemis" : null
         },
         "fusions" : {
            "Avatar" : "Deity",
            "Avian" : "Megami",
            "Beast" : null,
            "Brute" : null,
            "Deity" : null,
            "Divine" : "Megami",
            "Dragon" : "Holy",
            "Element" : null,
            "Entity" : "Deity",
            "Fairy" : "Holy",
            "Fallen" : "Lady",
            "Femme" : null,
            "Fiend" : "Fallen",
            "Foul" : "Fallen",
            "Fury" : "Vile",
            "Genma" : "Megami",
            "Haunt" : "Fallen",
            "Holy" : "Divine",
            "Jirae" : null,
            "Kishin" : "Divine",
            "Lady" : "Deity",
            "Megami" : "Deity",
            "Mitama" : "Seraph",
            "Night" : "Fallen",
            "Raptor" : null,
            "Seraph" : "Element",
            "Snake" : null,
            "Tyrant" : "Fallen",
            "Vile" : "Divine",
            "Wargod" : "Kishin",
            "Wilder" : null,
            "Yoma" : "Megami"
         },
         "self_fusion" : "Flaemis"
      },
      "Snake" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "up",
            "Erthys" : "down",
            "Flaemis" : "up"
         },
         "fusions" : {
            "Avatar" : "Lady",
            "Avian" : "Kishin",
            "Beast" : "Brute",
            "Brute" : "Beast",
            "Deity" : "Kishin",
            "Divine" : "Fairy",
            "Dragon" : "Lady",
            "Element" : "Snake",
            "Entity" : "Fury",
            "Fairy" : "Yoma",
            "Fallen" : "Beast",
            "Femme" : "Kishin",
            "Fiend" : "Brute",
            "Foul" : "Fallen",
            "Fury" : "Kishin",
            "Genma" : "Femme",
            "Haunt" : "Brute",
            "Holy" : "Kishin",
            "Jirae" : "Fallen",
            "Kishin" : "Femme",
            "Lady" : "Femme",
            "Megami" : "Fairy",
            "Mitama" : "Snake",
            "Night" : "Fallen",
            "Raptor" : "Foul",
            "Seraph" : null,
            "Snake" : "Element",
            "Tyrant" : "Brute",
            "Vile" : "Kishin",
            "Wargod" : "Kishin",
            "Wilder" : "Night",
            "Yoma" : "Night"
         },
         "self_fusion" : "Aquans"
      },
      "Tyrant" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "down",
            "Erthys" : "down",
            "Flaemis" : "down"
         },
         "fusions" : {
            "Avatar" : null,
            "Avian" : null,
            "Beast" : "Night",
            "Brute" : "Haunt",
            "Deity" : null,
            "Divine" : "Vile",
            "Dragon" : null,
            "Element" : "Tyrant",
            "Entity" : null,
            "Fairy" : "Night",
            "Fallen" : "Fury",
            "Femme" : "Lady",
            "Fiend" : null,
            "Foul" : "Haunt",
            "Fury" : "Deity",
            "Genma" : "Yoma",
            "Haunt" : "Foul",
            "Holy" : null,
            "Jirae" : "Wilder",
            "Kishin" : null,
            "Lady" : null,
            "Megami" : null,
            "Mitama" : "Tyrant",
            "Night" : "Lady",
            "Raptor" : "Fury",
            "Seraph" : "Fallen",
            "Snake" : "Brute",
            "Tyrant" : null,
            "Vile" : "Fury",
            "Wargod" : null,
            "Wilder" : "Night",
            "Yoma" : "Night"
         },
         "self_fusion" : null
      },
      "Vile" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "down",
            "Erthys" : "down",
            "Flaemis" : "down"
         },
         "fusions" : {
            "Avatar" : "Deity",
            "Avian" : null,
            "Beast" : "Foul",
            "Brute" : "Haunt",
            "Deity" : null,
            "Divine" : "Fallen",
            "Dragon" : "Snake",
            "Element" : "Vile",
            "Entity" : null,
            "Fairy" : "Night",
            "Fallen" : "Brute",
            "Femme" : "Brute",
            "Fiend" : "Fury",
            "Foul" : "Haunt",
            "Fury" : "Tyrant",
            "Genma" : "Yoma",
            "Haunt" : "Foul",
            "Holy" : null,
            "Jirae" : "Haunt",
            "Kishin" : null,
            "Lady" : null,
            "Megami" : "Fury",
            "Mitama" : "Vile",
            "Night" : "Lady",
            "Raptor" : "Fury",
            "Seraph" : "Divine",
            "Snake" : "Kishin",
            "Tyrant" : "Fury",
            "Vile" : null,
            "Wargod" : "Kishin",
            "Wilder" : "Foul",
            "Yoma" : "Jirae"
         },
         "self_fusion" : null
      },
      "Wargod" : {
         "element_fusions" : {
            "Aeros" : null,
            "Aquans" : null,
            "Erthys" : null,
            "Flaemis" : null
         },
         "fusions" : {
            "Avatar" : "Deity",
            "Avian" : "Kishin",
            "Beast" : "Holy",
            "Brute" : null,
            "Deity" : "Kishin",
            "Divine" : "Holy",
            "Dragon" : "Lady",
            "Element" : null,
            "Entity" : "Fury",
            "Fairy" : null,
            "Fallen" : "Lady",
            "Femme" : null,
            "Fiend" : null,
            "Foul" : null,
            "Fury" : "Deity",
            "Genma" : "Holy",
            "Haunt" : null,
            "Holy" : "Kishin",
            "Jirae" : "Kishin",
            "Kishin" : "Fury",
            "Lady" : "Kishin",
            "Megami" : "Deity",
            "Mitama" : "Wargod",
            "Night" : null,
            "Raptor" : null,
            "Seraph" : "Kishin",
            "Snake" : "Kishin",
            "Tyrant" : null,
            "Vile" : "Kishin",
            "Wargod" : null,
            "Wilder" : null,
            "Yoma" : null
         },
         "self_fusion" : null
      },
      "Wilder" : {
         "element_fusions" : {
            "Aeros" : "down",
            "Aquans" : "up",
            "Erthys" : "down",
            "Flaemis" : "up"
         },
         "fusions" : {
            "Avatar" : null,
            "Avian" : null,
            "Beast" : "Jirae",
            "Brute" : "Fairy",
            "Deity" : null,
            "Divine" : "Fallen",
            "Dragon" : null,
            "Element" : "Wilder",
            "Entity" : "Brute",
            "Fairy" : "Yoma",
            "Fallen" : "Night",
            "Femme" : "Fallen",
            "Fiend" : "Night",
            "Foul" : "Beast",
            "Fury" : null,
            "Genma" : "Yoma",
            "Haunt" : "Jirae",
            "Holy" : null,
            "Jirae" : "Brute",
            "Kishin" : null,
            "Lady" : "Haunt",
            "Megami" : "Vile",
            "Mitama" : "Wilder",
            "Night" : "Beast",
            "Raptor" : "Vile",
            "Seraph" : null,
            "Snake" : "Night",
            "Tyrant" : "Night",
            "Vile" : "Foul",
            "Wargod" : null,
            "Wilder" : "Element",
            "Yoma" : "Beast"
         },
         "self_fusion" : "Aeros"
      },
      "Yoma" : {
         "element_fusions" : {
            "Aeros" : "up",
            "Aquans" : "up",
            "Erthys" : "down",
            "Flaemis" : "down"
         },
         "fusions" : {
            "Avatar" : "Divine",
            "Avian" : "Night",
            "Beast" : "Fallen",
            "Brute" : "Femme",
            "Deity" : "Megami",
            "Divine" : "Snake",
            "Dragon" : "Avatar",
            "Element" : "Yoma",
            "Entity" : "Megami",
            "Fairy" : "Holy",
            "Fallen" : "Jirae",
            "Femme" : "Brute",
            "Fiend" : "Night",
            "Foul" : "Snake",
            "Fury" : "Holy",
            "Genma" : null,
            "Haunt" : "Jirae",
            "Holy" : "Divine",
            "Jirae" : "Beast",
            "Kishin" : "Femme",
            "Lady" : "Night",
            "Megami" : "Kishin",
            "Mitama" : "Yoma",
            "Night" : "Divine",
            "Raptor" : "Haunt",
            "Seraph" : "Megami",
            "Snake" : "Night",
            "Tyrant" : "Night",
            "Vile" : "Jirae",
            "Wargod" : null,
            "Wilder" : "Beast",
            "Yoma" : "Element"
         },
         "self_fusion" : "Aquans"
      }
   },
   "special_fusions" : {
      "Amaterasu" : {
         "demon1" : {
            "name" : "Yatagarasu"
         },
         "demon2" : {
            "name" : "Mikazuchi"
         },
         "sacrifice" : {
            "name" : "Uzume"
         }
      },
      "Black Rider" : {
         "deathstone" : 1,
         "kagutsuchi" : [
            0
         ],
         "target" : {
            "type" : "Night"
         }
      },
      "Daisoujou" : {
         "deathstone" : 1,
         "kagutsuchi" : [
            5,
            6,
            7,
            8
         ],
         "target" : {
            "type" : "Night"
         }
      },
      "Gabriel" : {
         "demon1" : {
            "name" : "Throne"
         },
         "demon2" : {
            "name" : "Raphael"
         }
      },
      "Girimehkala" : {
         "sacrifice" : {
            "type" : "Vile"
         },
         "target" : {
            "name" : "Purski"
         }
      },
      "Gurr" : {
         "sacrifice" : {
            "type" : "Tyrant"
         },
         "target" : {
            "name" : "Sparna"
         }
      },
      "Hell Biker" : {
         "deathstone" : 1,
         "kagutsuchi" : [
            4,
            5,
            6,
            7
         ],
         "target" : {
            "type" : "Fairy"
         }
      },
      "Matador" : {
         "deathstone" : 1,
         "kagutsuchi" : [
            1,
            2,
            3,
            4
         ],
         "target" : {
            "type" : "Yoma"
         }
      },
      "Metatron" : {
         "demon1" : {
            "name" : "Michael"
         },
         "demon2" : {
            "type" : [
               "Divine",
               "Seraph"
            ]
         },
         "sacrifice" : {
            "type" : "Tyrant"
         }
      },
      "Michael" : {
         "demon1" : {
            "name" : "Uriel"
         },
         "demon2" : {
            "name" : "Gabriel"
         },
         "demon3" : {
            "name" : "Raphael"
         }
      },
      "Ongyo-Ki" : {
         "demon1" : {
            "name" : "Kin-Ki"
         },
         "demon2" : {
            "name" : "Sui-Ki"
         },
         "demon3" : {
            "name" : "Fuu-Ki"
         }
      },
      "Pale Rider" : {
         "deathstone" : 1,
         "kagutsuchi" : [
            0
         ],
         "target" : {
            "type" : "Tyrant"
         }
      },
      "Raphael" : {
         "demon1" : {
            "name" : "Dominion"
         },
         "demon2" : {
            "name" : "Uriel"
         }
      },
      "Red Rider" : {
         "deathstone" : 1,
         "kagutsuchi" : [
            0
         ],
         "target" : {
            "type" : "Fairy"
         }
      },
      "Sakahagi" : {
         "demon1" : {
            "type" : "Element"
         },
         "target" : {
            "name" : "Sakahagi"
         }
      },
      "Samael" : {
         "sacrifice" : {
            "type" : "Vile"
         },
         "target" : {
            "name" : "Throne"
         }
      },
      "Shiva" : {
         "demon1" : {
            "name" : "Rangda"
         },
         "demon2" : {
            "name" : "Barong"
         }
      },
      "The Harlot" : {
         "deathstone" : 1,
         "kagutsuchi" : [
            4
         ],
         "target" : {
            "type" : "Tyrant"
         }
      },
      "Trumpeter" : {
         "deathstone" : 1,
         "kagutsuchi" : [
            8
         ],
         "target" : {
            "type" : "Tyrant"
         }
      },
      "White Rider" : {
         "deathstone" : 1,
         "kagutsuchi" : [
            0
         ],
         "target" : {
            "type" : "Yoma"
         }
      }
   }
}
