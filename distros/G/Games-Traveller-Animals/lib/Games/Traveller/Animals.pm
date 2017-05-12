package Games::Traveller::Animals;

use 5.008003;
use Games::Traveller::Animals::AnimalEncounter;
use YAML;
use strict;
use warnings;

our $VERSION = '0.50';

srand (time ^ (($$ << 15) + $$));

{
   sub new  { bless {}, shift }
   sub dice { $_[1] += int(rand(6)+1) for 1..$_[0]; return $_[1]; }

   my %terrainTables;

   sub terrainTables  :lvalue { $terrainTables{+shift} }
   
   #   get a list of the terrain types
   sub terrainTypes   { keys %{$terrainTables{+shift}}     }

   #   $self->encounterTable{ 'terrain type' }
   sub encounterTable { @{$terrainTables{+shift}->{$_[1]}} }   

   sub DESTROY
   {
     my $sref = 0+shift;
     delete $terrainTables{$sref};
   }
   
   my ($terrainTypes,$catalog) = YAML::Load( <<'...' );
--- 
Default attrs: [0,0,0,0,0,0,0,0,0,0,'f-6','f-6','f-3']
Terrain: 
   - { name: Clear     ,type:  3, mass:  0 }
   - { name: Prairie   ,type:  4, mass:  0 }
   - { name: Rough     ,type:  0, mass:  0 }
   - { name: Broken    ,type: -3, mass: -3 }
   - { name: Mountain  ,type:  0, mass:  0 }
   - { name: Forest    ,type: -4, mass: -4 }
   - { name: Jungle    ,type: -3, mass: -2 }
   - name: River
     type:  1
     mass:  1
     attrs: [0,0,'s1','a1',0,0,0,0,0,0,0,'f-6','f-5']
   - name: Swamp
     type: -2
     mass:  4
     attrs: [0,0,'s-3','a1','a1',0,0,0,0,0,0,'f-6','f-5']
   - name: Marsh
     type:  0
     mass: -1
     attrs: [0,0,'s-6','a2','a1',0,0,0,0,0,0,'f-6','f-5']
   - { name: Desert    ,type:  3, mass: -3 }
   - name: Beach 
     type:  3
     mass:  2
     attrs: [0,0,'s1','a2','a2',0,0,0,0,0,0,'f-6','f-5']
   - name: Surface 
     type:  2
     mass:  3
     attrs: [0,0,'s2','s2','s2','a2','a0','s1','s-1','t-7','t-6','f-6','f-5']
   - name: Shallows 
     type:  2
     mass:  2
     attrs: [0,0,'s2','s2','s2','a2','a0','s1','s-1','t-7','t-6','f-6','f-5']
   - { name: Depths    ,type: -4, mass:  0 }
   - { name: Bottom    ,type: -2, mass:  0 }
   - { name: Sea cave  ,type: -2, mass:  0 }
   - name: Sargasso
     type: -4
     mass: -2
     attrs: [0,0,'s2','s2','s2','a2','a0','s1','s-1','t-7','t-6','f-6','f-5']
   - { name: Ruins     ,type: -3, mass:  0 }
   - { name: Cave      ,type: -4, mass:  1 }
   - { name: Chasm     ,type: -1, mass: -3 }
   - { name: Crater    ,type:  0, mass: -1 }
--- 
Subtypes:
   - &flt { name: Filter,         F:  2, A: i, S: -5, flee first: true }
   - &int { name: Intermittent,   F:  3, A: 3, S: -4, flee first: true }
   - &grz { name: Grazer,         F: -1, A: 2, S: -2, flee first: true }
   - &gth { name: Gatherer,       A:  3, F: 2, S: -3 }
   - &hnt { name: Hunter,         A:  0, F: 2, S: -4 }
   - &etr { name: Eater,          A:  0, F: 3, S: -3 }
   - &pnc { name: Pouncer,        A:  s, F: s, S: -4 }
   - &chs { name: Chaser,         A:  m, F: 3, S: -2 }
   - &trp { name: Trapper,        A:  s, F: 2, S: -5 }
   - &srn { name: Siren,          A:  s, F: 3, S: -4 }
   - &kll { name: Killer,         A:  0, F: 3, S: -3 }
   - &hjc { name: Hijacker,       A:  1, F: 2, S: -4 }
   - &inm { name: Intimidator,    A:  2, F: 1, S: -4 }
   - &crr { name: Carrion Eater,  A:  3, F: 2, S: -3 }
   - &rdc { name: Reducer,        A:  3, F: 2, S: -4 }

Categories:
     - &scavenger
       name: Scavenger
       WeaponDM: 0
       ArmorDM:  1
       List:
          - [ *crr, 1 ]
          - [ *crr, 2 ]
          - [ *rdc, 1 ]
          - [ *hjc, 1 ]
          - [ *crr, 2 ]
          - [ *inm, 1 ]
          - [ *rdc, 0 ]
          - [ *crr, 1 ]
          - [ *rdc, 0 ]
          - [ *hjc, 0 ]
          - [ *inm, 0 ]
          - [ *rdc, 1 ]
          - [ *hjc, 0 ]
          - [ *inm, 1 ]
     - &omnivore
       name: Omnivore: 
       WeaponDM: 4
       ArmorDM:  0
       List:
          - [ *gth, 0 ]
          - [ *gth, 0 ]
          - [ *etr, 0 ]
          - [ *gth, 0 ]
          - [ *etr, 2 ]
          - [ *gth, 0 ]
          - [ *hnt, 0 ]
          - [ *hnt, 1 ]
          - [ *hnt, 0 ]
          - [ *gth, 0 ]
          - [ *etr, 1 ]
          - [ *hnt, 1 ]
          - [ *gth, 0 ]
          - [ *gth, 0 ]
     - &herbivore
       name: Herbivore
       WeaponDM: -3
       ArmorDM: 2
       List:
          - [ *flt, 1 ]
          - [ *flt, 0 ]
          - [ *flt, 0 ]
          - [ *int, 0 ]
          - [ *int, 0 ]
          - [ *int, 0 ]
          - [ *int, 0 ]
          - [ *grz, 0 ]
          - [ *grz, 0 ]
          - [ *grz, 1 ]
          - [ *grz, 2 ]
          - [ *grz, 3 ]
          - [ *grz, 4 ]
          - [ *grz, 5 ]
     - &carnivore
       name: Carnivore
       WeaponDM: 8
       ArmorDM: -1
       List:
          - [ *srn, 0 ]
          - [ *pnc, 0 ]
          - [ *srn, 0 ]
          - [ *pnc, 0 ]
          - [ *kll, 1 ]
          - [ *trp, 0 ]
          - [ *pnc, 0 ]
          - [ *chs, 0 ]
          - [ *chs, 3 ]
          - [ *chs, 0 ]
          - [ *kll, 0 ]
          - [ *chs, 2 ]
          - [ *srn, 0 ]
          - [ *chs, 1 ]
     - &event
       name: Event
       List:
         - Chameleon
         - Psionic Assaulters
         - Circling Flyers
         - Poisonous Pests
         - Stampede
         - Rutting Season
         - Lair
         - Hallucinogenic Pollen
         - Carnivorous Plants
         - Wirebrushes
         - Dense Fog
         - Sandstorm
         - Cold Snap
         - Tornado
         - Rainstorm
         - Prairie Fire
         - Flash Flood
         - Volcano
         - Seismic Quake
         - Broken Ground
         - Oasis
         - Crevasse
         - Radiation Area
         - Quicksand
         - Ford
         - Statues
         - Jungle Drums
         - Marsh Gas
         - Dust Pool
         - Solar Storm
         - Magnetic Anomaly
         - Tracks
         - Pressure Tent

Main Table:
   - *scavenger
   - *omnivore
   - *scavenger
   - *omnivore
   - *herbivore
   - *herbivore
   - *herbivore
   - *carnivore
   - *event
   - *carnivore
   - *carnivore

...
 

   sub toString
   {
      my $self   = shift;
      my $tables = $self->terrainTables;
      my @types  = $self->terrainTypes;
      my $out    = '';
      
      foreach my $terrain (@types)
      {
         my @list = @{$tables->{$terrain}};
         
         $out .= "\n\nTerrain: $terrain\n";
         $out .= "   Category         Size    Ht  Weapon    Mod Armor  Behaviour\n";
         $out .= '-' x 79, "\n";

         foreach my $entry (@list)
         {
            $out .= $entry->toString();
         }
      }
      return $out;
   }
   
   sub generateAnimalTable
   {
      my $self = shift;
      my $sref = 0+$self;
      my $worldSize = shift;
      my $worldAtmosphere = shift;
      
      my %terrainTables = ();
      
      foreach my $terrain (@{$terrainTypes->{Terrain}})
      {          
      	 my $name  = $terrain->{name};
      	 my $tdm   = $terrain->{type};
      	 my $wdm   = $terrain->{mass};
         my $attrs = $terrain->{attrs} || $terrainTypes->{'Default attrs'};
                  
#         print "\n\nTerrain: $name\n";
#         print "   Category         Size    Ht  Weapon    Mod Armor  Behaviour\n";
#         print '-' x 79, "\n";
         
         my @list = ();

         for my $index ( 2..12 )
         {
            my $encounter = new Games::Traveller::Animals::AnimalEncounter;
            
            my ($type, $category, $count, $wdm, $adm, $behaviour) = _getAnimal( $tdm );

            $encounter->index    = $index;
            $encounter->category = $type;
         
            if ( $category =~ /Event/ )
            {
               $encounter->attribute = 'Event';
               push @list, $encounter;
               
#               printf( "%2d   Event: $type\n", $index );              
               next;
            }

            my $attr = _attributes($worldSize, $worldAtmosphere, $attrs);
                     
            if ($attr =~ /(\w)(.+)/)
            {
               $encounter->attribute = $1;
#               $type  = "$1 $type";
               $wdm  += int($2);
            }
            else
            {
               $encounter->attribute = '';
#               $type = "  $type";
            }
         
            my ($mass, $hit, $dead, $weaponMod) = _weightEffects($wdm);
            my $weapon = _weaponryTable($wdm);
            my $armor  = _armorTable($adm);

            $encounter->mass        = $mass;
            $encounter->hits        = $hit;
            $encounter->dead        = $dead;
            $encounter->weapon      = $weapon;
            $encounter->damageMod   = $weaponMod;
            $encounter->armor       = $armor;
            $encounter->behavior    = $behaviour;
    
            push @list, $encounter;
                  
#            printf ("%2d%2s %-14s %4s %3.3s/%-2.2s %9.9s %3.3s %-7s %s\n", 
#               $index,
#               $encounter->attribute,
#               $encounter->category, 
#               $encounter->mass,
#               $encounter->hits,
#               $encounter->dead,
#               $encounter->weapon,
#               $encounter->damageMod,
#               $encounter->armor,
#               $encounter->behaviour);
            
         }
         $terrainTables{$name} = \@list;
      }
      $self->terrainTables = \%terrainTables;
   }
      
   sub _getAnimal
   {
      my $typeDM = shift || 0;
      
      my @types = @{$catalog->{'Main Table'}};
      
      my $categoryref = $types[ int(rand(6)) + int(rand(6)) ];
      my $category    = $categoryref->{name};
      my $wdm         = $categoryref->{WeaponDM};
      my $adm         = $categoryref->{ArmorDM};
      my @list        = @{$categoryref->{List}};
               
      my $roll = $typeDM + int(rand(6)) + int(rand(6));
         $roll =  0 if $roll < 0;
         $roll = 10 if $roll > 10;
      
      my $subtyperef = $list[ $roll ];
              
      return ( $subtyperef, 'Event' ) unless ref $subtyperef ;

      my ($subtyperef, $countIter) = @$subtyperef;

      my $type = $subtyperef->{name};
      
      my $a         = int(rand(6)+1) + $subtyperef->{A};
      my $f         = int(rand(6)+1) + $subtyperef->{F};
      my $s         = int(rand(6)+1) + $subtyperef->{S};
      
      $s = 0 if $s < 0;
      $a = 0 if $a < 0;
      $f = 0 if $f < 0;
      
      my $flee1st   = $subtyperef->{'flee first'};
      
      my $behaviour = "A$a F$f S$s";
         $behaviour = "F$f A$a S$s" if $flee1st;
      
      my $count = 0;
      $count += int(rand(6)+1) for( 1..$countIter );
      $count = 1 if $count == 0;
      
      return ($type, $category, $count, $wdm, $adm, $behaviour);
   }


   ########################################################
   #
   # sub : attributes
   #
   # desc: determines special attributes for animal
   #
   # in  : terrain type, world size (L/M/S), atmosphere (Thin/Dense/Exotic)
   #
   # out : attribute and DM
   #
   ########################################################
   sub _attributes
   {
   	  my $size = shift;
   	  my $atmosphere = shift;
   	  my $attrs = shift;
      
   	  my $dm = 0;
            
      $dm--  if $size       =~ /[89A]/;
      $dm++  if $size       =~ /[4567]/;
      $dm+=2 if $size       =~ /[0S123]/;
      $dm--  if $atmosphere =~ /[123]/;
      $dm+=2 if $atmosphere =~ /[9ABCDEF]/;
   
      my $roll = &dice(2, $dm);
      $roll = ($roll < 0 )?  0 : 
              ($roll > 12)? 12 : $roll;
    
      return $attrs->[ $roll ];
   }

   ########################################################
   #
   # sub : weightEffects
   #
   # desc: returns mass, hits, and wounds modifier
   #
   # in  : weight DM
   #
   # out : 
   #
   ########################################################
   sub _weightEffects
   {
      my $weightDM = shift;
    
      my @effects = 
      (  
   #
   #           hit  wound
   #
         '  1  1 0   -2d',
         '  3  1 1   -2d',
         '  6  1 2   -1d',
         ' 12  2 2    -',
         ' 25  3 2    -',
         ' 50  4 2    -',
         '100  5 2    -',
         '200  5 3   +1d',
         '400  6 3   +2d',
         '800  7 3   +3d',
         ' 2k  8 3   +4d',
         ' 3k  8 4   +5d',
         -1,
         ' 6k  9 4   x2',
         '12k 10 5   x2',
         '24k 12 6   x3',
         '30k 14 7   x4',
         '36k 15 7   x4',
         '40k 16 8   x5',
         '44k 17 9   x6'
      );
      
      my $roll = &dice(2, $weightDM - 2);
      $roll = 0 if $roll  < 0;
      $roll = 19 if $roll > 19;
   
      $roll = &dice(2, $weightDM + 6) while ($roll == 12) || ($roll > 19);
      
      my @effect = split(' ', $effects[$roll]);
   
      $effect[1] = &dice($effect[1]);
      $effect[2] = &dice($effect[2]);
    
      return @effect;
   }
   
   ########################################################
   #
   # sub : weaponryTable
   #
   # desc:
   #
   # in  : weapon DM
   #
   # out : weapons and hits
   #
   ########################################################
   sub _weaponryTable
   {
      my $wDM = shift;
   
      my @weaponTable =
      (  '',
         'Hrns,hvs ',
         'Horns    ',
         'Hvs,tth  ',
         'Hooves   ',
         'Hrns,tth ',
         'Thrasher ',
         'Clws,tth ',
         'Teeth    ',
         'Claws    ',
         'Claws    ',
         'Thrasher ',
         'Clws, tth',
         'Claws+1  ',
         'Stinger  ',
         'Clw/tth+1',
         'Teeth+1  ',
         'Blade(1d)',
         'Blade(2d)',
         'Pstl(4d) '
      );
     
      return $weaponTable[&dice(2, $wDM-2)];
   }
   
   
   ########################################################
   #
   # sub : armorTable
   #
   # desc: returns armor type
   #
   # in  : armor DM
   #
   # out :
   #
   ########################################################
   sub _armorTable
   {
      my $adm = shift;
   
      my @at = 
      (
         '', 6, '', '', 'jack', '','','','','', 'jack', '', 6,
         'mesh+1',
         'clth+1',
         'mesh',
         'cloth',
         'cbt+4',
         'reflec',
         'ablat',
         'battle'
      );
   
      my $roll = &dice(2, $adm-2);
      $roll = &dice(2, $adm+4) while ($at[$roll] eq '6');
   
      return $at[$roll];
   }
}

1;

__END__

=head1 NAME

   Games::Traveller::Animals -- the Traveller Animal Encounter matrix
   
=head1 SYNOPSIS

   use Games::Traveller::UWP;
   use Games::Traveller::Animals;
   use Games::Traveller::Animals::AnimalEncounter;
   
   my $uwp1 = new Games::Traveller::UWP;

   $uwp1->readUwp( 'Reference 0140 A887887-A B Ri Cp      323 Im K7 V' );

   my $at = new Games::Traveller::Animals;

   #
   #   Given a world's physical data, generate an animal table.
   #
   $at->generateAnimalTable( $uwp1->size, $uwp1->atmosphere, $uwp1->hydrosphere );
   
   #
   #   Fetch the list of terrain types.
   #
   print $at->terrainTypes, "\n";

   #
   #   Dump the encounter tables in ASCII.
   #
   print $at->toString();
   
   #
   #   Access the data individually.
   #
   my @terrainTypes = $at->terrainTypes;
   
   foreach my $terrain (@terrainTypes)
   {
      print "$terrain\n";
      my @encounterTable = @{$at->terrainTables->{$terrain}};
      
      foreach my $encounter (@encounterTable)
      {
         #
         #  $encounter is of type Games::Traveller::Animals::AnimalEncounter,
         #  which has a bunch of convenient accessors in it.
         #
         printf ("%2d%2s %-14s %4s %3.3s/%-2.2s %9.9s %3.3s %-7s %s\n", 
                 $self->index,
                 $self->attribute || '',
                 $self->category, 
                 $self->mass,
                 $self->hits,
                 $self->dead,
                 $self->weapon,
                 $self->damageMod,
                 $self->armor,
                 $self->behaviour);

      }
   }

=head1 AUTHOR

  Pasuuli Immuguna

=head1 COPYRIGHT

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AVAILABILITY

The latest version of this library is likely to be available from CPAN.

=cut
