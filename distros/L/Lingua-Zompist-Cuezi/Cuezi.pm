package Lingua::Zompist::Cuezi;
# vim:set sw=2 et encoding=utf-8 fileencoding=utf-8 keymap=cuezi:

use 5.005;
use strict;

require Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS %verb);
@ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Lingua::Zompist::Cuezi ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
%EXPORT_TAGS = (
  'all' => [ qw(
    %verb
    inf
    part
    noun
    root
    adj
    comp
    comb
  ) ],
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

@EXPORT = qw(
	
);
$VERSION = '0.01';


my @persons = qw(sēo/sēi led/lei tāu/tāi tazū/letazū māux cayū);

my @cases = qw(nom gen acc dat abl ins);

my @numbers = qw(sing pl);

my @genders = qw(masc neut fem);

my $voiced    = qr/[bdgvzmn]/;  # stops don't assimilate before laterals l r,
                                # according to Mark
my $unvoiced  = qr/[ptcfsx]/;
my $consonant = qr/[ptcbdgfsxvzmnlr]/;
my $stop      = qr/[ptcbdg]/;
my $vstop     = qr/[bdg]/;
my $ustop     = qr/[ptc]/;
my $labial    = qr/[mbpl]/;
my $dental    = qr/[tdcgx]/;
my $vowel     = qr/[aeiou]/;
my $anyvowel  = qr/(?:[aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)/;
my $vlong     = qr/(?:ā|ē|ī|ō|ū)/;
my $vcirc     = qr/(?:â|ê|î|ô|û)/;
my $alteri    = qr/[tcgx]/;
my $altere    = qr/[tcg]/;
my $altered   = qr/[syc]/;

my %voiced = (
  'p' => 'b',
  't' => 'd',
  'c' => 'g',
  'f' => 'v',
  's' => 'z',
);

my %unvoiced = reverse %voiced;

my %alter = (
  't' => 's',
  'c' => 's',
  'g' => 'y',
  'x' => 'c',
);

# change root to...
my %rootchange = (
  s => {
    'orbesiu' => 'c',  # noun
    'lusi' => 't',     # noun
    'brisê' => 't',    # verb
    'babrisê' => 't',  # verb
    'cammisi' => 'c',  # adjective
    'dosi' => 't',     # noun
    'lācasi' => 't',   # noun
    'lusi' => 't',     # noun
    'pīsi' => 't',     # verb
    'bapīsi' => 't',   # verb
    'pose' => 't',     # adjective
    'rāsi' => 't',     # noun
    'ruyise' => 't',   # adjective
    'salese' => 't',   # verb
    'basalese' => 't', # verb
    'sāsi' => 'c',     # verb
    'basāsi' => 'c',   # verb
    'xosê' => 't',     # verb
    'baxosê' => 't',   # verb
  },
  y => {
    'bêyi' => 'g',     # verb
    'babêyi' => 'g',   # verb
    'clāye' => 'g',    # verb
    'baclāye' => 'g',  # verb
    'creyê' => 'g',    # verb
    'bacreyê' => 'g',  # verb
    'drayê' => 'g',    # verb
    'badrayê' => 'g',  # verb
    'exdrayê' => 'g',  # verb
    'baexdrayê' => 'g',# verb
    'fabēyi' => 'g',   # verb
    'bafabēyi' => 'g', # verb
    'usayi' => 'g',    # noun
    'xlayê' => 'g',    # verb
    'baxlayê' => 'g',  # verb
    'yayê' => 'g',     # verb
    'bayayê' => 'g',   # verb
  },
  c => {
    '' => 'x',
  },
);


# Which conjugation is a specific verb?

my %conj = (
  'alirê' => 1,
  'ambrozâ' => 2,
  'aviê' => 1,
  'ayisâ' => 2,
  'bâ' => 2,
  'babrivori' => 4,
  'bamoêli' => 4,
  'banilerê' => 3,
  'bapomi' => 4,
  'barīdi' => 4,
  'bēre' => 1,
  'bēse' => 1,
  'bêti' => 4,
  'bêyi' => 4,
  'brinâ' => 2,
  'brisê' => 3,
  'brosivê' => 1,
  'brozâ' => 2,
  'būga' => 2,      # before front vowels: ūg --> ūi! (TODO)
  'cadi' => 4,
  'cāpi' => 4,
  'cāurê' => 1,
  'cisi' => 4,
  'civê' => 1,
  'clāye' => 5,     # y --> g
  'coêli' => 4,
  'cōli' => 4,      # cīli is a misconversion, according to Mark
  'cranivê' => 1,
  'crêsi' => 4,
  'creyê' => 3,     # y --> g
  'curi' => 4,
  'dâ' => 2,
  'dei' => 4,
  'diazami' => 4,
  'drâcê' => 3,
  'dralāda' => 2,
  'drayê' => 3,     # y --> g
  'drogâ' => 2,     # g -> y TODO
  'drouvê' => 1,
  'duli' => 4,
  'duni' => 4,
  'duntracê' => 3,
  'êcuri' => 4,
  'embesê' => 1,    # this has a question mark in the document
# 'esc' => 2,
  'exdrayê' => 1,   # y --> g
  'fabēyi' => 4,
  'fāsi' => 4,
  'faleriê' => 3,
  'fi' => 4,
  'fūra' => 2,
  'gāema' => 2,
  'gâsi' => 4,
  'gobrinâ' => 2,
  'gocivê' => 1,
  'gocuri' => 4,
# 'goes' => 2,      # conjugates like esc
  'golôdi' => 4,
  'îcâ' => 2,
  'lāda' => 2,
  'lanê' => 1,
  'lerê' => 3,
  'lerisuê' => 3,
  'lûre' => 5,
  'lūve' => 1,
  'mê' => 1,
  'mētuda' => 2,
  'mētulerê' => 3,
  'missê' => 1,
  'mizida' => 2,
  'mûstolê' => 3,
  'nalerê' => 3,
  'namâsiê' => 3,
  'natēre' => 5,
  'nîê' => 3,
  'nizanê' => 3,
  'nōue' => 5,
  'nure' => 5,
# 'ogonê' => 'P',   # passive voice only
  'ōibâ' => 2,      # or ōiba? It's from ōi + bâ
  'ōicopa' => 2,
  'ōinote' => 5,
  'ōisizi' => 4,
# 'omê' => 'P',     # passive voice only; < mê (1)
# 'onê' => 'P',     # passive voice only
  'ori' => 4,
  'pelê' => 1,
  'pêtâ' => 2,
  'pisi' => 4,
  'pīsi' => 4,
  'rēne' => 3,
  'rêsê' => 3,
  'retê' => 3,
  'ridi' => 4,
  'ripâ' => 2,
  'risoni' => 4,
  'rīxa' => 2,      # x --> c  TODO?
  'rōci' => 4,
  'rusê' => 1,
  'sālāda' => 2,
  'salese' => 5,    # s --> t  TODO
  'sāsi' => 4,
  'selirê' => '1',
  'sile' => 5,
  'sisi' => 4,
  'sizi' => 4,
  'sofusê' => 3,
  'somâ' => 2,
  'sonure' => 5,
  'sûduni' => 4,
  'sulāda' => 2,
  'sûmissê' => 1,
  'sunutāne' => 3,
  'sunōibâ' => 2,
  'taige' => 5,
  'tâsi' => 4,
  'tēre' => 5,
# 'ties' => 2,      # conjugates like esc
  'tolê' => 3,
  'tôsê' => 3,
  'usāle' => 3,
  'utāne' => 3,
  'vissê' => 1,
  'vissivê' => 1,
  'vûne' => 3,
  'xēcuvissê' => 1, # or xēcuvisse? < xēcu + vissê
  'xlayê' => 1,     # y --> g
  'xosê' => 1,      # s --> t  TODO
  'yayê' => 3,      # y --> g
  'zamêrê' => 3,
  'zicuê' => 3,
  'zīde' => 3,
);


# And now, the gigantic horror structure that is the Cuêzi verb!

# the actual structure itself.
%verb = (
  normal => {
    active => {
      perfect => {
        definite => {
          present => sub {
            # normal active perfect definite present
            my($verb, $conj) = @_;
            my $stem = $verb;
            my $table;

            return [ qw( sāi sēi ê zāmo zāzi zota ) ] if $verb eq 'esc';

            # Try to look up the conjugation if we're supposed to guess
            $conj ||= $conj{$verb};

            # Do we still not know? Try to guess from the ending
            # This only works for conjugations 2 (â a) and 4 (i)
            # -e could be any of 1 3 5; -ê either of 1 3
            unless(defined $conj) {
              if($verb =~ m/(?:â|a)$/) {
                $conj = 2;
              } elsif($verb =~ m/i$/) {
                $conj = 4;
              } else {
                return;
              }
            }

            if($conj == 1) {
              $stem =~ s/(?:ê|e)$//;
              # īmo īzi are misconversions, according to Mark
              $table = [ map "$stem$_", qw( āo ēo e ōmo ōzi ota ) ];
            } elsif($conj == 2) {
              $stem =~ s/(?:â|a)$//;
              $table = [ map "$stem$_", qw( āi ēi e āmo āzi ota ) ];
            } elsif($conj == 3) {
              $stem =~ s/(?:ê|e)$//;
              $table = [ map "$stem$_", qw( āi ēi e āmo āzi itu ) ];
            } elsif($conj == 4) {
              $stem =~ s/i$//;
              $table = [ map "$stem$_", qw( āu ēu i umo uzi itu ) ];
            } elsif($conj == 5) {
              $stem =~ s/e$//;
              $table = [ map "$stem$_", qw( āu ēu e umo uzi uta ) ];
            } else {
              return;
            }

            for(@$table) {
              # change root consonant before -e and -i
              # except when preceded by another consonant or a circumflexed vowel
              if(/$alteri(?:i(?:tu)?)$/o
                 && !/(?:$vcirc|$consonant)(?:$alteri)(?:i(?:tu)?)$/o) {
                s/($alteri)(?=(?:i(?:tu)?)$)/$alter{$1}/o;
              }
              if(/$altere(?:e|ē[oiu])$/o
                 && !/(?:$vcirc|$consonant)(?:$altere)(?:e|ē[oiu])$/o) {
                s/($altere)(?=(?:e|ē[oiu])$)/$alter{$1}/o;
              }

              # restore original root consonant before -a -o -u
              if(/([syc])(?:ō(?:mo|zi)|ota|ā(?:[oiu]|mo|zi)|u(?:mo|zi|ta))$/
                 && exists $rootchange{$1}{$verb})
              {
                s/([syc])(?=(?:ō(?:mo|zi)|ota|ā(?:[oiu]|mo|zi)|u(?:mo|zi|ta))$)/$rootchange{$1}{$verb}/;
              }
            }

            return $table;
          },
          past => sub {
            # normal active perfect definite past
            my($verb, $conj) = @_;
            my $stem = $verb;
            my $table;

            # īmo īzi are misconversions, according to Mark
            return [ qw( sio sio sā sōmo sōzi sītu ) ] if $verb eq 'esc';

            # Try to look up the conjugation if we're supposed to guess
            $conj ||= $conj{$verb};

            # Do we still not know? Try to guess from the ending
            # This only works for conjugations 2 (â a) and 4 (i)
            # -e could be any of 1 3 5; -ê either of 1 3
            unless(defined $conj) {
              if($verb =~ m/(?:â|a)$/) {
                $conj = 2;
              } elsif($verb =~ m/i$/) {
                $conj = 4;
              } else {
                return;
              }
            }

            if($conj == 1) {
              $stem =~ s/(?:ê|e)$//;
              $table = [ map "$stem$_", qw( iu iu ū ūmo ūzi ūta ) ];
            } elsif($conj == 2) {
              $stem =~ s/(?:â|a)$//;
              # īmo īzi are misconversions, according to Mark
              $table = [ map "$stem$_", qw( io io ā ōmo ōzi ītu ) ];
            } elsif($conj == 3) {
              $stem =~ s/(?:ê|e)$//;
              # īmo īzi are misconversions, according to Mark
              $table = [ map "$stem$_", qw( io io ā ōmo ōzi ītu ) ];
            } elsif($conj == 4) {
              $stem =~ s/i$//;
              $table = [ map "$stem$_", qw( ie ie ē ēmo ēzi ītu ) ];
            } elsif($conj == 5) {
              $stem =~ s/e$//;
              $table = [ map "$stem$_", qw( ie ie ē ēmo ēzi ītu ) ];
            } else {
              return;
            }

            for(@$table) {
              # change root consonant before -e and -i
              # except when preceded by another consonant or a circumflexed vowel
              # iu io ie ē ēmo ēzi ītu
              if(/$alteri(?:i[uoe]|ītu)$/o
                 && !/(?:$vcirc|$consonant)(?:$alteri)(?:i[uoe]|ītu)$/o) {
                s/($alteri)(?=(?:i[uoe]|ītu)$)/$alter{$1}/o;
              }
              if(/$altere(?:ē(?:mo|zi)?)$/o
                 && !/(?:$vcirc|$consonant)(?:$altere)(?:ē(?:mo|zi)?)$/o) {
                s/($altere)(?=(?:ē(?:mo|zi)?)$)/$alter{$1}/o;
              }

              # restore original root consonant before -a -o -u
              # ū ūmo ūzi ūta ōmo ōzi ā
              if(/([syc])(?:ō(?:mo|zi)|ā|ū(?:mo|zi|ta)?)$/
                 && exists $rootchange{$1}{$verb})
              {
                s/([syc])(?=(?:ō(?:mo|zi)|ā|ū(?:mo|zi|ta)?)$)/$rootchange{$1}{$verb}/;
              }
            }

            return $table;
          },
          'past anterior' => sub {
            # normal active perfect definite past anterior
            my($verb, $conj) = @_;
            my $stem = $verb;
            my $table;

            ($conj, $verb, $stem) = (2, 'zâ', 'zâ') if $verb eq 'esc';

            # Try to look up the conjugation if we're supposed to guess
            $conj ||= $conj{$verb};

            # Do we still not know? Try to guess from the ending
            # This only works for conjugations 2 (â a) and 4 (i)
            # -e could be any of 1 3 5; -ê either of 1 3
            unless(defined $conj) {
              if($verb =~ m/(?:â|a)$/) {
                $conj = 2;
              } elsif($verb =~ m/i$/) {
                $conj = 4;
              } else {
                return;
              }
            }

            if($conj == 1) {
              $stem =~ s/(?:ê|e)$/er/;
              if($stem =~ /$altere(?:er)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:er)$/o) {
                $stem =~ s/($altere)(?=er$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( iu iu ū ūmo ūzi ūta ) ];
            } elsif($conj == 2) {
              $stem =~ s/(?:â|a)$/er/;
              if($stem =~ /$altere(?:er)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:er)$/o) {
                $stem =~ s/($altere)(?=er$)/$alter{$1}/o;
              }
              # īmo īzi are misconversions, according to Mark
              $table = [ map "$stem$_", qw( io io ā ōmo ōzi ītu ) ];
            } elsif($conj == 3) {
              $stem =~ s/(?:ê|e)$/er/;
              if($stem =~ /$altere(?:er)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:er)$/o) {
                $stem =~ s/($altere)(?=er$)/$alter{$1}/o;
              }
              # īmo īzi are misconversions, according to Mark
              $table = [ map "$stem$_", qw( io io ā ōmo ōzi ītu ) ];
            } elsif($conj == 4) {
              $stem =~ s/i$/ir/;
              if($stem =~ /$alteri(?:ir)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$alteri)(?:ir)$/o) {
                $stem =~ s/($alteri)(?=ir$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( ie ie ē ēmo ēzi ītu ) ];
            } elsif($conj == 5) {
              $stem =~ s/e$/er/;
              if($stem =~ /$altere(?:er)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:er)$/o) {
                $stem =~ s/($altere)(?=er$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( ie ie ē ēmo ēzi ītu ) ];
            } else {
              return;
            }

            return $table;
          },
          future => sub {
            # normal active perfect definite future
            my($verb, $conj) = @_;
            my $stem = $verb;
            my $table;

            ($conj, $verb, $stem) = (2, 'zâ', 'zâ') if $verb eq 'esc';

            # Try to look up the conjugation if we're supposed to guess
            $conj ||= $conj{$verb};

            # Do we still not know? Try to guess from the ending
            # This only works for conjugations 2 (â a) and 4 (i)
            # -e could be any of 1 3 5; -ê either of 1 3
            unless(defined $conj) {
              if($verb =~ m/(?:â|a)$/) {
                $conj = 2;
              } elsif($verb =~ m/i$/) {
                $conj = 4;
              } else {
                return;
              }
            }

            if($conj == 1) {
              $stem =~ s/(?:ê|e)$/il/;
              if($stem =~ /$alteri(?:il)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$alteri)(?:il)$/o) {
                $stem =~ s/($alteri)(?=il$)/$alter{$1}/o;
              }
              # īmo īzi are misconversions, according to Mark
              $table = [ map "$stem$_", qw( āo ēo e ōmo ōzi ota ) ];
            } elsif($conj == 2) {
              $stem =~ s/(?:â|a)$/al/;
              if($stem =~ /([syc])al$/
                 && exists $rootchange{$1}{$verb})
              {
                $stem =~ s/([syc])(?=al$)/$rootchange{$1}{$verb}/;
              }
              $table = [ map "$stem$_", qw( āi ēi e āmo āzi ota ) ];
            } elsif($conj == 3) {
              $stem =~ s/(?:ê|e)$/il/;
              if($stem =~ /$alteri(?:il)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$alteri)(?:il)$/o) {
                $stem =~ s/($alteri)(?=il$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( āi ēi e āmo āzi itu ) ];
            } elsif($conj == 4) {
              $stem =~ s/i$/il/;
              if($stem =~ /$alteri(?:il)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$alteri)(?:il)$/o) {
                $stem =~ s/($alteri)(?=il$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( āu ēu i umo uzi itu ) ];
            } elsif($conj == 5) {
              $stem =~ s/e$/il/;
              if($stem =~ /$alteri(?:il)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$alteri)(?:il)$/o) {
                $stem =~ s/($alteri)(?=il$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( āu ēu e umo uzi uta ) ];
            } else {
              return;
            }

            return $table;
          },
        },
        remote => {
          present => sub {
            # normal active perfect remote present
            my($verb, $conj) = @_;
            my $stem = $verb;
            my $table;

            return [ qw( zetāu zesēu zesê zetumi zetezi zesitu ) ] if $verb eq 'esc';

            # esc is nearly regular, except for zesê instead of zesi.
            # ($conj, $verb, $stem) = (4, 'zi', 'zi') if $verb eq 'esc';

            # Try to look up the conjugation if we're supposed to guess
            $conj ||= $conj{$verb};

            # Do we still not know? Try to guess from the ending
            # This only works for conjugations 2 (â a) and 4 (i)
            # -e could be any of 1 3 5; -ê either of 1 3
            unless(defined $conj) {
              if($verb =~ m/(?:â|a)$/) {
                $conj = 2;
              } elsif($verb =~ m/i$/) {
                $conj = 4;
              } else {
                return;
              }
            }

            if($conj == 1) {
              $stem =~ s/(?:ê|e)$//;
              if($stem =~ /$altere$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)$/o) {
                $stem =~ s/($altere)(?=$)/$alter{$1}/o;
              }
              # This is -etīmo and -etīzi in the document, but they are
              # misconversions of -ō- according to Mark.
              $table = [ map "$stem$_", qw( etāo esēo ese etōmo etōzi etota ) ];
            } elsif($conj == 2) {
              $stem =~ s/(?:â|a)$//;
              if($stem =~ /$altere$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)$/o) {
                $stem =~ s/($altere)(?=$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( ināi inēi ine ināmo ināzi inota ) ];
            } elsif($conj == 3) {
              $stem =~ s/(?:ê|e)$//;
              if($stem =~ /$altere$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)$/o) {
                $stem =~ s/($altere)(?=$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( ināi inēi ine ināmo ināzi initu ) ];
            } elsif($conj == 4) {
              $stem =~ s/i$//;
              if($stem =~ /$altere$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)$/o) {
                $stem =~ s/($altere)(?=$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( etāu esēu esi etumo etuzi esitu ) ];
            } elsif($conj == 5) {
              $stem =~ s/e$//;
              if($stem =~ /$altere$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)$/o) {
                $stem =~ s/($altere)(?=$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( etāu esēu ese etumo etuzi etuta ) ];
            } else {
              return;
            }

            return $table;
          },
          past => sub {
            # normal active perfect remote past
            my($verb, $conj) = @_;
            my $stem = $verb;
            my $table;

            ($conj, $verb, $stem) = (4, 'zi', 'zi') if $verb eq 'esc';

            # Try to look up the conjugation if we're supposed to guess
            $conj ||= $conj{$verb};

            # Do we still not know? Try to guess from the ending
            # This only works for conjugations 2 (â a) and 4 (i)
            # -e could be any of 1 3 5; -ê either of 1 3
            unless(defined $conj) {
              if($verb =~ m/(?:â|a)$/) {
                $conj = 2;
              } elsif($verb =~ m/i$/) {
                $conj = 4;
              } else {
                return;
              }
            }

            if($conj == 1) {
              $stem =~ s/(?:ê|e)$//;
              if($stem =~ /$altere$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)$/o) {
                $stem =~ s/($altere)(?=$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( esiu esiu etū etūmo etūzi etūta ) ];
            } elsif($conj == 2) {
              $stem =~ s/(?:â|a)$//;
              if($stem =~ /$altere$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)$/o) {
                $stem =~ s/($altere)(?=$)/$alter{$1}/o;
              }
              # īmo īzi are misconversions, according to Mark
              $table = [ map "$stem$_", qw( inio inio inā inōmo inōzi inītu ) ];
            } elsif($conj == 3) {
              $stem =~ s/(?:ê|e)$//;
              if($stem =~ /$altere$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)$/o) {
                $stem =~ s/($altere)(?=$)/$alter{$1}/o;
              }
              # īmo īzi are misconversions, according to Mark
              $table = [ map "$stem$_", qw( inio inio inā inōmo inōzi inītu ) ];
            } elsif($conj == 4) {
              $stem =~ s/i$//;
              if($stem =~ /$altere$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)$/o) {
                $stem =~ s/($altere)(?=$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( esie esie esē esēmo esēzi esītu ) ];
            } elsif($conj == 5) {
              $stem =~ s/e$//;
              if($stem =~ /$altere$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)$/o) {
                $stem =~ s/($altere)(?=$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( esie esie esē esēmo esēzi esītu ) ];
            } else {
              return;
            }

            return $table;
          },
          'past anterior' => sub {
            # normal active perfect remote past anterior
            my($verb, $conj) = @_;
            my $stem = $verb;
            my $table;

            ($conj, $verb, $stem) = (4, 'zi', 'zi') if $verb eq 'esc';

            # Try to look up the conjugation if we're supposed to guess
            $conj ||= $conj{$verb};

            # Do we still not know? Try to guess from the ending
            # This only works for conjugations 2 (â a) and 4 (i)
            # -e could be any of 1 3 5; -ê either of 1 3
            unless(defined $conj) {
              if($verb =~ m/(?:â|a)$/) {
                $conj = 2;
              } elsif($verb =~ m/i$/) {
                $conj = 4;
              } else {
                return;
              }
            }

            if($conj == 1) {
              $stem =~ s/(?:ê|e)$/er/;
              if($stem =~ /$altere(?:er)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:er)$/o) {
                $stem =~ s/($altere)(?=er$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( esiu esiu etū etūmo etūzi etūta ) ];
            } elsif($conj == 2) {
              $stem =~ s/(?:â|a)$/er/;
              if($stem =~ /$altere(?:er)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:er)$/o) {
                $stem =~ s/($altere)(?=er$)/$alter{$1}/o;
              }
              # īmo īzi are misconversions, according to Mark
              $table = [ map "$stem$_", qw( inio inio inā inōmo inōzi inītu ) ];
            } elsif($conj == 3) {
              $stem =~ s/(?:ê|e)$/er/;
              if($stem =~ /$altere(?:er)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:er)$/o) {
                $stem =~ s/($altere)(?=er$)/$alter{$1}/o;
              }
              # īmo īzi are misconversions, according to Mark
              $table = [ map "$stem$_", qw( inio inio inā inōmo inōzi inītu ) ];
            } elsif($conj == 4) {
              $stem =~ s/i$/ir/;
              if($stem =~ /$alteri(?:ir)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$alteri)(?:ir)$/o) {
                $stem =~ s/($alteri)(?=ir$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( esie esie esē esēmo esēzi esītu ) ];
            } elsif($conj == 5) {
              $stem =~ s/e$/er/;
              if($stem =~ /$altere(?:er)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:er)$/o) {
                $stem =~ s/($altere)(?=er$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( esie esie esē esēmo esēzi esītu ) ];
            } else {
              return;
            }

            return $table;
          },
          future => sub {
            # normal active perfect remote future
            my($verb, $conj) = @_;
            my $stem = $verb;
            my $table;

            ($conj, $verb, $stem) = (4, 'zi', 'zi') if $verb eq 'esc';

            # Try to look up the conjugation if we're supposed to guess
            $conj ||= $conj{$verb};

            # Do we still not know? Try to guess from the ending
            # This only works for conjugations 2 (â a) and 4 (i)
            # -e could be any of 1 3 5; -ê either of 1 3
            unless(defined $conj) {
              if($verb =~ m/(?:â|a)$/) {
                $conj = 2;
              } elsif($verb =~ m/i$/) {
                $conj = 4;
              } else {
                return;
              }
            }

            if($conj == 1) {
              $stem =~ s/(?:ê|e)$/il/;
              if($stem =~ /$alteri(?:il)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$alteri)(?:il)$/o) {
                $stem =~ s/($alteri)(?=il$)/$alter{$1}/o;
              }
              # īmo īzi are misconversions, according to Mark
              $table = [ map "$stem$_", qw( etāo esēo ese etōmo etōzi etota ) ];
            } elsif($conj == 2) {
              $stem =~ s/(?:â|a)$/al/;
              if($stem =~ /([syc])al$/
                 && exists $rootchange{$1}{$verb})
              {
                $stem =~ s/([syc])(?=al$)/$rootchange{$1}{$verb}/;
              }
              $table = [ map "$stem$_", qw( ināi inēi ine ināmo ināzi inota ) ];
            } elsif($conj == 3) {
              $stem =~ s/(?:ê|e)$/il/;
              if($stem =~ /$alteri(?:il)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$alteri)(?:il)$/o) {
                $stem =~ s/($alteri)(?=il$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( ināi inēi ine ināmo ināzi initu ) ];
            } elsif($conj == 4) {
              $stem =~ s/i$/il/;
              if($stem =~ /$alteri(?:il)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$alteri)(?:il)$/o) {
                $stem =~ s/($alteri)(?=il$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( etāu esēu esi etumo etuzi esitu ) ];
            } elsif($conj == 5) {
              $stem =~ s/e$/il/;
              if($stem =~ /$alteri(?:il)$/o
                 && $stem !~ /(?:$vcirc|$consonant)(?:$alteri)(?:il)$/o) {
                $stem =~ s/($alteri)(?=il$)/$alter{$1}/o;
              }
              $table = [ map "$stem$_", qw( etāu esēu ese etumo etuzi etuta ) ];
            } else {
              return;
            }

            return $table;
          },
        },
      },
      imperfect => {
        definite => {
          present => \&imperfect,
          past => \&imperfect,
          'past anterior' => \&imperfect,
          future => \&imperfect,
        },
        remote => {
          present => \&imperfect,
          past => \&imperfect,
          'past anterior' => \&imperfect,
          future => \&imperfect,
        },
      },
    },
    passive => {
      perfect => {
        definite => {
          present => sub {
            # normal passive perfect definite present
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            # TODO - Passive root of xuêsi is oxês- not oxuês-
            # (All passive forms are affected)

            return if $verb eq 'esc';

            # Passive root of xuêsi is oxês- not oxuês-
            $stem =~ s/xuês/xês/ if $verb eq 'xuêsi' || $verb eq 'baxuêsi';

            # Replace an initial vowel with o-, or add an o-
            $stem =~ s/^(?:[aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)/o/ || $stem =~ s/^/o/;

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î)$//;

            $table = [ map "$stem$_", qw( āl ēl el mal sal tal ) ];

            for(@$table) {
              # change root consonant before -e
              # except when preceded by another consonant or a circumflexed vowel
              if(/$altere(?:el|ēl)$/o
                 && !/(?:$vcirc|$consonant)(?:$altere)(?:el|ēl)$/o) {
                s/($altere)(?=(?:el|ēl)$)/$alter{$1}/o;
              }

              # restore original root consonant before -ā or consonant
              if(/([syc])(?:āl|[mst]al)$/
                 && exists $rootchange{$1}{$verb})
              {
                s/([syc])(?=(?:āl|[mst]al)$)/$rootchange{$1}{$verb}/;
              }
            }

            return $table;
          },
          past => sub {
            # normal passive perfect definite past
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            return if $verb eq 'esc';

            # Passive root of xuêsi is oxês- not oxuês-
            $stem =~ s/xuês/xês/ if $verb eq 'xuêsi' || $verb eq 'baxuêsi';

            # Replace an initial vowel with o-, or add an o-
            $stem =~ s/^(?:[aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)/o/ || $stem =~ s/^/o/;

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î)$//;

            $table = [ map "$stem$_", qw( il il āl mul sul tul ) ];

            for(@$table) {
              # change root consonant before -i
              # except when preceded by another consonant or a circumflexed vowel
              if(/$alteri(?:il)$/o
                 && !/(?:$vcirc|$consonant)(?:$alteri)(?:il)$/o) {
                s/($alteri)(?=(?:il)$)/$alter{$1}/o;
              }

              # restore original root consonant before -ā or consonant
              if(/([syc])(?:āl|[mst]ul)$/
                 && exists $rootchange{$1}{$verb})
              {
                s/([syc])(?=(?:āl|[mst]ul)$)/$rootchange{$1}{$verb}/;
              }
            }

            return $table;
          },
          'past anterior' => sub {
            # normal passive perfect definite past anterior
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            return if $verb eq 'esc';

            # Passive root of xuêsi is oxês- not oxuês-
            $stem =~ s/xuês/xês/ if $verb eq 'xuêsi' || $verb eq 'baxuêsi';

            # Replace an initial vowel with o-, or add an o-
            $stem =~ s/^(?:[aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)/o/ || $stem =~ s/^/o/;

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î)$//;

            if($stem =~ /$altere$/o
               && $stem !~ /(?:$vcirc|$consonant)(?:$altere)$/o) {
              s/($altere)(?=$)/$alter{$1}/o;
            }

            $table = [ map "$stem$_", qw( eril eril erāl ermul erzul erdul ) ];

            return $table;
          },
          future => sub {
            # normal passive perfect definite future
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            # Passive root of xuêsi is oxês- not oxuês-
            $stem =~ s/xuês/xês/ if $verb eq 'xuêsi' || $verb eq 'baxuêsi';

            return if $verb eq 'esc';

            # Replace an initial vowel with o-, or add an o-
            $stem =~ s/^(?:[aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)/o/ || $stem =~ s/^/o/;

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î)$//;

            if($stem =~ /([syc])$/
               && exists $rootchange{$1}{$verb})
            {
              $stem =~ s/([syc])(?=$)/$rootchange{$1}{$verb}/;
            }

            $table = [ map "$stem$_", qw( alāl alēl alel almal alzal aldal ) ];

            return $table;
          },
        },
        remote => {
          present => sub {
            # normal passive perfect remote present
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            return if $verb eq 'esc';

            # Passive root of xuêsi is oxês- not oxuês-
            $stem =~ s/xuês/xês/ if $verb eq 'xuêsi' || $verb eq 'baxuêsi';

            # Replace an initial vowel with o-, or add an o-
            $stem =~ s/^(?:[aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)/o/ || $stem =~ s/^/o/;

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î)$//;

            if($stem =~ /$alteri$/o
               && $stem !~ /(?:$vcirc|$consonant)(?:$alteri)$/o) {
              s/($alteri)(?=$)/$alter{$1}/o;
            }

            $table = [ map "$stem$_", qw( ināl inēl inel imal izal idal ) ];

            return $table;
          },
          past => sub {
            # normal passive perfect remote past
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            return if $verb eq 'esc';

            # Passive root of xuêsi is oxês- not oxuês-
            $stem =~ s/xuês/xês/ if $verb eq 'xuêsi' || $verb eq 'baxuêsi';

            # Replace an initial vowel with o-, or add an o-
            $stem =~ s/^(?:[aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)/o/ || $stem =~ s/^/o/;

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î)$//;

            if($stem =~ /$alteri$/o
               && $stem !~ /(?:$vcirc|$consonant)(?:$alteri)$/o) {
              s/($alteri)(?=$)/$alter{$1}/o;
            }

            $table = [ map "$stem$_", qw( inil inil ināl imul izul idul ) ];

            return $table;
          },
          'past anterior' => sub {
            # normal passive perfect remote past anterior
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            return if $verb eq 'esc';

            # Passive root of xuêsi is oxês- not oxuês-
            $stem =~ s/xuês/xês/ if $verb eq 'xuêsi' || $verb eq 'baxuêsi';

            # Replace an initial vowel with o-, or add an o-
            $stem =~ s/^(?:[aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)/o/ || $stem =~ s/^/o/;

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î)$//;

            if($stem =~ /$altere$/o
               && $stem !~ /(?:$vcirc|$consonant)(?:$altere)$/o) {
              s/($altere)(?=$)/$alter{$1}/o;
            }

            $table = [ map "$stem$_", qw( erinil erinil erināl erimul erizul eridul ) ];

            return $table;
          },
          future => sub {
            # normal passive perfect remote future
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            return if $verb eq 'esc';

            # Passive root of xuêsi is oxês- not oxuês-
            $stem =~ s/xuês/xês/ if $verb eq 'xuêsi' || $verb eq 'baxuêsi';

            # Replace an initial vowel with o-, or add an o-
            $stem =~ s/^(?:[aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)/o/ || $stem =~ s/^/o/;

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î)$//;

            if($stem =~ /([syc])$/
               && exists $rootchange{$1}{$verb})
            {
              $stem =~ s/([syc])(?=$)/$rootchange{$1}{$verb}/;
            }

            $table = [ map "$stem$_", qw( alināl alinēl alinel alimal alizal alidal ) ];

            return $table;
          },
        },
      },
      imperfect => {
        definite => {
          present => \&passive_imperfect,
          past => \&passive_imperfect,
          'past anterior' => \&passive_imperfect,
          future => \&passive_imperfect,
        },
        remote => {
          present => \&passive_imperfect,
          past => \&passive_imperfect,
          'past anterior' => \&passive_imperfect,
          future => \&passive_imperfect,
        },
      },
    },
  },
  causative => {
    active => {
      perfect => {
        definite => {
          present => sub {
            # causative active perfect definite present
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            ($verb, $stem) = ('ezâ', 'ezâ') if $verb eq 'esc';

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î|û)$//;

            $table = [ map "$stem$_", qw( ū ū u īmo īzi īzu ) ];

            for(@$table) {
              # change root consonant before -i
              # except when preceded by another consonant or a circumflexed vowel
              if(/$alteri(?:ī(?:mo|z[iu]))$/o
                 && !/(?:$vcirc|$consonant)(?:$alteri)(?:ī(?:mo|z[iu]))$/o) {
                s/($alteri)(?=(?:ī(?:mo|z[iu]))$)/$alter{$1}/o;
              }

              # restore original root consonant before -u
              if(/([syc])(?:ū|u)$/
                 && exists $rootchange{$1}{$verb})
              {
                s/([syc])(?=(?:ū|u)$)/$rootchange{$1}{$verb}/;
              }
            }

            return $table;
          },
          past => sub {
            # causative active perfect definite past
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            ($verb, $stem) = ('ezâ', 'ezâ') if $verb eq 'esc';

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î|û)$/eb/;

            if($stem =~ /$altere(?:eb)$/o
               && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:eb)$/o) {
              $stem =~ s/($altere)(?=eb$)/$alter{$1}/o;
            }

            $table = [ map "$stem$_", qw( ū ū u īmo īzi īzu ) ];

            return $table;
          },
          'past anterior' => sub {
            # causative active perfect definite past anterior
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            ($verb, $stem) = ('ezâ', 'ezâ') if $verb eq 'esc';

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î|û)$/er/;

            if($stem =~ /$altere(?:er)$/o
               && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:er)$/o) {
              $stem =~ s/($altere)(?=er$)/$alter{$1}/o;
            }

            $table = [ map "$stem$_", qw( ū ū u īmo īzi īzu ) ];

            return $table;
          },
          future => sub {
            # causative active perfect definite future
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            ($verb, $stem) = ('ezâ', 'ezâ') if $verb eq 'esc';

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î|û)$/al/;

            if($stem =~ /([syc])(?:al)$/
               && exists $rootchange{$1}{$verb})
            {
              $stem =~ s/([syc])(?=(?:al)$)/$rootchange{$1}{$verb}/;
            }

            $table = [ map "$stem$_", qw( ū ū u īmo īzi īzu ) ];

            return $table;
          },
        },
        remote => {
          present => sub {
            # causative active perfect remote present
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            ($verb, $stem) = ('ezâ', 'ezâ') if $verb eq 'esc';

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î|û)$/et/;

            if($stem =~ /$altere(?:et)$/o
               && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:et)$/o) {
              $stem =~ s/($altere)(?=et$)/$alter{$1}/o;
            }

            $table = [ map "$stem$_", qw( ū ū u īmo īzi īzu ) ];

            return $table;
          },
          past => sub {
            # causative active perfect remote past
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            ($verb, $stem) = ('ezâ', 'ezâ') if $verb eq 'esc';

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î|û)$/eseb/;

            if($stem =~ /$altere(?:eseb)$/o
               && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:eseb)$/o) {
              $stem =~ s/($altere)(?=eseb$)/$alter{$1}/o;
            }

            $table = [ map "$stem$_", qw( ū ū u īmo īzi īzu ) ];

            return $table;
          },
          'past anterior' => sub {
            # causative active perfect remote past anterior
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            ($verb, $stem) = ('ezâ', 'ezâ') if $verb eq 'esc';

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î|û)$/eser/;

            if($stem =~ /$altere(?:eser)$/o
               && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:eser)$/o) {
              $stem =~ s/($altere)(?=eser$)/$alter{$1}/o;
            }

            $table = [ map "$stem$_", qw( ū ū u īmo īzi īzu ) ];

            return $table;
          },
          future => sub {
            # causative active perfect remote future
            my($verb) = @_;
            my $stem = $verb;
            my $table;

            ($verb, $stem) = ('ezâ', 'ezâ') if $verb eq 'esc';

            # Delete the final vowel
            $stem =~ s/(?:[eai]|ê|â|î|û)$/etal/;

            if($stem =~ /$altere(?:etal)$/o
               && $stem !~ /(?:$vcirc|$consonant)(?:$altere)(?:etal)$/o) {
              $stem =~ s/($altere)(?=etal$)/$alter{$1}/o;
            }

            $table = [ map "$stem$_", qw( ū ū u īmo īzi īzu ) ];

            return $table;
          },
        },
      },
      imperfect => {
        definite => {
          present => \&causative_imperfect,
          past => \&causative_imperfect,
          'past anterior' => \&causative_imperfect,
          future => \&causative_imperfect,
        },
        remote => {
          present => \&causative_imperfect,
          past => \&causative_imperfect,
          'past anterior' => \&causative_imperfect,
          future => \&causative_imperfect,
        },
      },
    },
    passive => {
      perfect => {
        definite => {
          present => \&causative_passive_perfect,
          past => \&causative_passive_perfect,
          'past anterior' => \&causative_passive_perfect,
          future => \&causative_passive_perfect,
        },
        remote => {
          present => \&causative_passive_perfect,
          past => \&causative_passive_perfect,
          'past anterior' => \&causative_passive_perfect,
          future => \&causative_passive_perfect,
        },
      },
      imperfect => {
        definite => {
          present => \&causative_imperfect,
          past => \&causative_imperfect,
          'past anterior' => \&causative_imperfect,
          future => \&causative_imperfect,
        },
        remote => {
          present => \&causative_imperfect,
          past => \&causative_imperfect,
          'past anterior' => \&causative_imperfect,
          future => \&causative_imperfect,
        },
      },
    },
  },
  inceptive => {
    active => {
      perfect => {
        definite => {
          present => \&inceptive,
          past => \&inceptive,
          'past anterior' => \&inceptive,
          future => \&inceptive,
        },
        remote => {
          present => \&inceptive,
          past => \&inceptive,
          'past anterior' => \&inceptive,
          future => \&inceptive,
        },
      },
      imperfect => {
        definite => {
          present => \&inceptive,
          past => \&inceptive,
          'past anterior' => \&inceptive,
          future => \&inceptive,
        },
        remote => {
          present => \&inceptive,
          past => \&inceptive,
          'past anterior' => \&inceptive,
          future => \&inceptive,
        },
      },
    },
    passive => {
      perfect => {
        definite => {
          present => \&inceptive,
          past => \&inceptive,
          'past anterior' => \&inceptive,
          future => \&inceptive,
        },
        remote => {
          present => \&inceptive,
          past => \&inceptive,
          'past anterior' => \&inceptive,
          future => \&inceptive,
        },
      },
      imperfect => {
        definite => {
          present => \&inceptive,
          past => \&inceptive,
          'past anterior' => \&inceptive,
          future => \&inceptive,
        },
        remote => {
          present => \&inceptive,
          past => \&inceptive,
          'past anterior' => \&inceptive,
          future => \&inceptive,
        },
      },
    },
  },
);


sub imperfect {
  # normal active imperfect
  my($verb, $conj, $info) = @_;
  my $orig = $verb;
  my $table;

  if($verb eq 'esc'
#     && $info->{type}  eq 'normal'
#     && $info->{voice} eq 'active'
#     && $info->{mood}  eq 'definite'
  ) {
#    if($info->{tense} eq 'present') {
#      return [ qw( fuāi fuēi fuē fuāmo fuāzu fuota ) ];
#    } elsif($info->{tense} eq 'past') {
#      # īmo īzi are misconversions, according to Mark
#      return [ qw( fuio fuio fuā fuōmo fuōzi fuītu ) ];
#    }
    ($conj, $verb) = (2, 'fuâ');
  }

  # form the normal active perfect tense
  $table = $verb{$info->{type}}
             -> {$info->{voice}}
             -> {perfect}
             -> {$info->{mood}}
             -> {$info->{tense}}
             -> ($verb, $conj, { %$info, aspect => 'perfect' });

  return unless defined $table;

  # imperfect of 'esc' looks like the perfect of 'fuâ'
  # so don't make any changes from here on
  return $table if $orig eq 'esc';

  # change -mo to -bo in I.pl., except for present and
  # past definite
  $table->[3] =~ s/mo$/bo/
    unless     $info->{mood} eq 'definite'
           && (   $info->{tense} eq 'present'
               || $info->{tense} eq 'past');

  # add a final -r -r -re -r -r -r
  for(@$table) {
    $_ .= 'r';
  }
  $table->[2] .= 'e';

  return $table;
};

sub passive_imperfect {
  # normal passive imperfect
  my($verb, $conj, $info) = @_;
  my $table;

  return if $verb eq 'esc';

  # form the normal passive perfect tense
  $table = $verb{$info->{type}}
             -> {$info->{voice}}
             -> {perfect}
             -> {$info->{mood}}
             -> {$info->{tense}}
             -> ($verb, $conj, { %$info, aspect => 'perfect' });

  return unless defined $table;

  # Change the final -l to -r
  for(@$table) {
    s/l$/r/;
  }
  # Should III.sg. end in -r or -re?
  # $table->[2] .= 'e';
  # Mark says it shouldn't.

  return $table;
};

sub causative_imperfect {
  # causative (active or passive) imperfect
  my($verb, $conj, $info) = @_;
  my $table;

  # form the causative perfect tense
  $table = $verb{$info->{type}}
             -> {$info->{voice}}
             -> {perfect}
             -> {$info->{mood}}
             -> {$info->{tense}}
             -> ($verb, $conj, { %$info, aspect => 'perfect' });

  return unless defined $table;

  # Add final -r/-re (for active) or change final -l to -r (for passive)
  if($info->{voice} eq 'active') {
    for(@$table) {
      $_ .= 'r';
    }
    $table->[2] .= 'e';
  } elsif($info->{voice} eq 'passive') {
    for(@$table) {
      s/l$/r/;
    }
  } else {
    return;
  }

  return $table;
};

sub causative_passive_perfect {
  # causative passive perfect
  my($verb, $conj, $info) = @_;
  my $table;

  return if $verb eq 'esc';

  # form the causative active perfect tense
  $table = $verb{$info->{type}}
             -> {active}
             -> {$info->{aspect}}
             -> {$info->{mood}}
             -> {$info->{tense}}
             -> ($verb, $conj, { %$info, voice => 'active' });

  return unless defined $table;

  # Replace an initial vowel with o-, or add an o-
  # Suffix an -l
  for(@$table) {
    s/^(?:[aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)/o/ || s/^/o/;
    s/$/l/;

    # Passive root of xuêsi is oxês- not oxuês-
    s/xuês/xês/ if $verb eq 'xuêsi';
  }

  return $table;
}

sub inceptive {
  # inceptive (active or passive) (perfect or imperfect)
  my($verb, $conj, $info) = @_;
  my $table;

  if($verb eq 'esc') {
    # form the normal tense
    $table = $verb{normal}
               -> {$info->{voice}}
               -> {$info->{aspect}}
               -> {$info->{mood}}
               -> {$info->{tense}}
               -> ($verb, $conj, { %$info, type => 'normal' });

    # and add 'ba'
    for(@$table) {
      s/^/ba/;
    }

    return $table;
  }

  if($info->{aspect} eq 'perfect') {
    # Add 'ba' or change 'o-' to 'oba-'
    if($verb eq 'ogonî' ||
       $verb eq 'omî' ||
       $verb eq 'onî') {
      substr($verb, 1, 0) = 'ba';
    } else {
      substr($verb, 0, 0) = 'ba';
    }

    # form the normal tense
    $table = $verb{normal}
               -> {$info->{voice}}
               -> {$info->{aspect}}
               -> {$info->{mood}}
               -> {$info->{tense}}
               -> ($verb, $conj, { %$info, type => 'normal' });
  } elsif($info->{aspect} eq 'imperfect') {
    # form the perfect form
    # (this will result in a recursive call to this function)
    $table = $verb{$info->{type}}
               -> {$info->{voice}}
               -> {perfect}
               -> {$info->{mood}}
               -> {$info->{tense}}
               -> ($verb, $conj, { %$info, aspect => 'perfect' });
  } else {
    return;
  }

  return unless defined $table;

  if($info->{aspect} eq 'perfect') {
    # Remove final vowel if there are two
    # (only active; perfect passive is exactly the same as normal)
    if($info->{voice} eq 'active') {
      for(@$table) {
        s/([aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)(?:[aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)$/$1/;
      }
    }
  } elsif($info->{aspect} eq 'imperfect') {
    # Add final -r/-re (for active) or change final -l to -r (for passive)
    if($info->{voice} eq 'active') {
      for(@$table) {
        $_ .= 'r';
      }
      $table->[2] .= 'e';
    } elsif($info->{voice} eq 'passive') {
      for(@$table) {
        s/l$/r/;
      }
    } else {
      return;
    }
  } else {
    return;
  }

  return $table;
};


sub inf {
  my $verb = shift;
  my($active, $passive, $causative, $inceptive, $incpass);

  # active infinitive is simply the base form,
  # except for passive-only and causative-only verbs
  $active = $verb unless $verb eq 'ogonî'
                      || $verb eq 'omî'
                      || $verb eq 'onî'
                      || $verb eq 'ēxlûrtû'
                       ;

  # passive infinitive is o- + root + -i (with long vowel) or -î (otherwise)
  # except for causative-only verbs
  if($verb ne 'ēxlûrtû') {
    for($passive = $verb) {
      s/^(?:[aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)/o/ || s/^/o/;
      s/(?:[eai]|ê|â)$/î/;
      s/î$/i/ if /(?:ā|ē|ī|ō|ū)/;

      s/xuês/xês/ if $verb eq 'xuêsi' || $verb eq 'baxuêsi';
    }
  }

  # causative infinitive is -û or -u, except esc --> ezû
  if($verb eq 'esc') {
    $causative = 'ezû';
  } elsif($verb eq 'ēxlûrtû') {
    $causative = $verb;
  } else {
    for($causative = $verb) {
      s/(?:[eai]|ê|â)$/û/;
      s/û$/u/ if /(?:ā|ē|ī|ō|ū)/;
    }
  }

  # inceptive active infinitive is ba- + normal infinitive,
  # except for passive-only and causative-only verbs, which have none
  if($verb ne 'ēxlûrtû'
     && $verb ne 'ogonî'
     && $verb ne 'omî'
     && $verb ne 'onî'
  ) {
    for($inceptive = $verb) {
      s/^/ba/;
    }
  }

  # inceptive passive infinitive is oba- + normal infinitive + i^/i,
  # except for passive-only (oba-) and causative-only (none) verbs
  if($verb ne 'ēxlûrtû') {
    for($incpass = $verb) {
      s/^ogonî$/obagonî/ ||
      s/^omî$/obamî/ ||
      s/^onî$/obanî/ ||
      s/^/oba/;
      s/(?:[eai]|ê|â)$/î/;
      s/î$/i/ if /(?:ā|ē|ī|ō|ū)/;

      s/xuês/xês/ if $verb eq 'xuêsi' || $verb eq 'baxuêsi';
    }
  }

  return wantarray ? ($active, $passive, $causative, $inceptive, $incpass)
                   : {
                       active => $active,
                       passive => $passive,
                       causative => $causative,
                       inceptive => $inceptive,
                       incpass => $incpass,
                     };
}


sub part {
  my $verb = shift;

  my($active, $passive, $agent, $causative) = ($verb) x 4;

  # esc forms its participles from the root ez-,
  # and it's nominally 2nd declension in -â.
  ($active, $passive, $agent, $causative) = ('ezâ') x 4 if $verb eq 'esc';

  if($verb eq 'ogonî' ||
     $verb eq 'omî' ||
     $verb eq 'onî' ||
     $verb eq 'ēxlûrtû'
  ) {
    $active = undef;
  } else {
    # active is e- + root + -eto
    # e- changes to am- before b
    # ee- and eê- both go to ē-
    for($active) {
      s/^b/amb/ || s/^e/ē/ || s/^ê/ē/ || s/^/e/;
      s/(?:[eai]|ê|â)$/eto/;
      if(/$altere(?:eto)$/o
         && !/(?:$vcirc|$consonant)(?:$altere)(?:eto)$/o) {
        s/($altere)(?=(?:eto)$)/$alter{$1}/o;
      }
    }
  }

  # passive is o- + root + -elo
  # The o- replaces any initial vowel
  # o- changes to om- before b
  if($verb eq 'ēxlûrtû' ||
     $verb eq 'esc') {
    $passive = undef;
  } else {
    for($passive) {
      s/^(?:[aeiou]|ā|ē|ī|ō|ū|â|ê|î|ô|û)/o/ || s/^/o/;
      s/^ob/omb/;
      s/(?:[eai]|ê|â|î)$/elo/;
      if(/$altere(?:elo)$/o
         && !/(?:$vcirc|$consonant)(?:$altere)(?:elo)$/o) {
        s/($altere)(?=(?:elo)$)/$alter{$1}/o;
      }

      s/xuês/xês/ if $verb eq 'xuêsi' || $verb eq 'baxuêsi';
    }
  }

  if($verb eq 'ogonî' ||
     $verb eq 'omî' ||
     $verb eq 'onî' ||
     $verb eq 'ēxlûrtû'
  ) {
    $agent = undef;
  } else {
    # agent is e- + root + -as/-ei
    # e- changes to am- before b
    # ee- and eê- both go to ē-
    for($agent) {
      s/^b/amb/ || s/^e/ē/ || s/^ê/ē/ || s/^/e/;
      s/(?:[eai]|ê|â)$//;
    }
    # TODO - keep track of root alternations
    # e.g. pīsi --> epī*t*as, epīsei
    $agent = [ $agent . 'as', $agent . 'ei' ];

    if($agent->[0] =~ /([syc])(?:as)$/
       && exists $rootchange{$1}{$verb})
    {
      $agent->[0] =~ s/([syc])(?=(?:as)$)/$rootchange{$1}{$verb}/;
    }

    if($agent->[1] =~ /$altere(?:ei)$/o
       && $agent->[1] !~ /(?:$vcirc|$consonant)(?:$altere)(?:ei)$/o) {
      $agent->[1] =~ s/($altere)(?=(?:ei)$)/$alter{$1}/o;
    }
  }

  if($verb eq 'ogonî' ||
     $verb eq 'omî' ||
     $verb eq 'onî'
  ) {
    $causative = undef;
  } else {
    # causative is e- + root + -ūzo
    # e- changes to am- before b
    # ee- and eê- both go to ē-
    for($causative) {
      s/^b/amb/ || s/^e/ē/ || s/^ê/ē/ || s/^ē/ē/ || s/^/e/;
      s/(?:[eai]|ê|â|û)$/ūzo/;
      if(/([syc])(?:ūzo)$/
         && exists $rootchange{$1}{$verb})
      {
        s/([syc])(?=(?:ūzo)$)/$rootchange{$1}{$verb}/;
      }
    }
  }

  return wantarray ? ( $active, $passive, $agent, $causative )
                   : [ $active, $passive, $agent, $causative ];
}



my %masc = (
  'beire' => 1,
  'ferêde' => 1,
  'geōre' => 1, # geīre in the lexicon, but it's a misconversion according to Mark
  'lūvore' => 1,
  'nōre' => 1, # nīre in the morphology, but it's a misconversion according to Mark
  'Inibē' => 1,
  'sāclore' => 1,
  'sārene' => 1,
  'sāule' => 1,
  'suale' => 1,
  'tīble' => 1,
  'yine' => 1,
);

my %neut = (
);

my %aetas = (
  'āetas' => 1,
  'creidas' => 1,
  'crindas' => 1,
  'dēnedas' => 1,
  'mavordas' => 1,
  'motas' => 1,
  'sambas' => 1,
  'sindas' => 1,
  'sonurdas' => 1,
  'Sūās' => 1,
  'tōuresambas' => 1,
  'ulidas' => 1,
);

# t -> s, c -> s, g -> y before -e and -i; x -> c before -i
my %changenoun = (
  'āeca' => 1,
  'āetas' => 1,
  'ambecā' => 1,
  'bāxe' => 1,
  'brexos' => 1,
  'erēineca' => 1,
  'fūca' => 1,
  'gāex' => 1,
  'lācato' => 1,   # actually an adjective
  'rūtas' => 1,
  'sīxe' => 1,
  'tauca' => 1,
  'usūta' => 1,
  'xuecos' => 1,
);

my %noun = (
  # personal pronouns
  'sēo'    => [ qw( sēo    soex    etu   sēnu    sētu    sēco   ), (undef) x @cases ],
  'sēi'    => [ qw( sēi    soē     etu   sēnu    sēdi    sēlu   ), (undef) x @cases ],
  'led'    => [ qw( led    loex    ēr    linu    letu    leco   ), (undef) x @cases ],
  'lei'    => [ qw( lei    loē     ēr    linu    ledi    lelu   ), (undef) x @cases ],
  'tāu'    => [ qw( tāu    tāuex   tāua  tāunu   tāutu   tāuco  ), (undef) x @cases ],
  'tāi'    => [ qw( tāi    tāyē    tāya  tāinu   tāidi   tāilu  ), (undef) x @cases ],
  'tazū'   => [ qw( tazū   tazuē   tāe   tānu    tātu    tāco   ), (undef) x @cases ],
  'letazū' => [ qw( letazū lotazuē ertāe litānu  letātu  letāco ), (undef) x @cases ],
  'māux'   => [ qw( māux   muē     mū    mūna    mūta    mūco   ), (undef) x @cases ],
  'cayū'   => [ qw( cayū   cayuē   caē   caēnu   caētu   caēco  ), (undef) x @cases ],
  'rāe'    => [ qw( rāe    rāex    rā    rāenu   rāetu   rāeco
                    radē   radaē   rade  radanu  radatu  radaco ), ],

  # tīble has sg.acc. tībal instead of *tībl,
  # and an epenthetic vowel in singular dat. abl. ins.
  'tīble'  => [ qw( tīble  tīblex  tībal tīblanu tīblatu tīblaco
                    tībli  tībliē  tīblī tīblinu tīblitu tīblico ) ],
);

sub noun {
  my $noun = shift;
  my $stem = $noun;
  my $type = 'fem';
  my $table;

  $type = 'masc' if exists $masc{$noun} || exists $aetas{$noun};
  $type = 'neut' if exists $neut{$noun};

  return $noun{$noun} if exists $noun{$noun};

  # masculine
  if($stem =~ m/[pbtdcgfvzxmnlr]$/) {
    $type = 'masc';
    $table = [ map "$stem$_", '',   'ex', '',  qw( nu  tu  co    i iē i inu itu ico ) ];
  } elsif($type eq 'masc' && $stem =~ s/re$//) {
    $table = [ map "$stem$_", 're', 'rex','r', qw( rnu rtu rco   i iē ī inu itu ico ) ];
  } elsif($type eq 'masc' && $stem =~ s/([nld])?e$/$1/) {
    $table = [ map "$stem$_", 'e',  'ex', '',  qw( nu  tu  co    i iē ī inu itu ico ) ];
  } elsif($type eq 'masc' && $stem =~ s/ē$//) {
    $table = [ map "$stem$_", qw( ē ēx e enu etu eco   ei eiē eii einu eitu eico ) ];
  } elsif($stem =~ s/os$//) {
    $type = 'masc';
    $table = [ map "$stem$_", 'os', 'ex', '',  qw( nu  tu  co    i iē i inu itu ico ) ];
  } elsif(exists $aetas{$noun} && $stem =~ s/as$//) {
    $table = [ map "$stem$_", qw( as ex  a anu atu aco   āe aē āe ānu ātu āco ) ];
  } elsif(exists $aetas{$noun} && $stem =~ s/ās$//) {
    $table = [ map "$stem$_", qw( ās aex ā ānu ātu āco   aāe āē aāe aānu aātu aāco ) ];
  } elsif($stem =~ s/as$//) {
    $type = 'masc';
    $table = [ map "$stem$_", 'as', 'ex', '',  qw( nu  tu  co    i iē i inu itu ico ) ];
  }

  # neuter
  elsif($stem =~ s/iu$//) {
    $type = 'neut';
    $table = [ map "$stem$_", qw( iu iex i inu itu ico   iū uē ū ūna ūta ūco ) ];
  } elsif($stem =~ s/āu$//) {
    $type = 'neut';
    $table = [ map "$stem$_", qw( āu aex â anu ato aco   ū  uē ū ūna ūta ūco ) ];
  } elsif($stem =~ s/u$//) {
    $type = 'neut';
    $table = [ map "$stem$_", qw( u  ex  u nu  tu  uco   ū  uē ū ūna ūta ūco ) ];
  } elsif($stem =~ s/o$//) {
    $type = 'neut';
    $table = [ map "$stem$_", qw( o  ex  o onu otu oco   ō  oē ō ōna ōta ōco ) ];
  }

  # feminine
  elsif($stem =~ s/a$//) {
    $type = 'fem';
    $table = [ map "$stem$_", qw( a aē ā anu adi alu   ē eē ē ēnu ēdi ēlu ) ];
  } elsif($stem =~ s/â$//) {
    $type = 'fem';
    $table = [ map "$stem$_", qw( â aē ā ânu âdi âlu   ē eē ē ēnu ēdi ēlu ) ];
  } elsif($stem =~ s/ā$//) {
    $type = 'fem';
    $table = [ map "$stem$_", qw( ā aē ā ānu ādi ālu   ē eē ē ēnu ēdi ēlu ) ];
  } elsif($type eq 'fem' && $stem =~ s/e$//) {
    $table = [ map "$stem$_", qw( e eē ê inu edi elu   ē eē ē ēnu ēdi ēco ) ];
  } elsif($type eq 'fem' && $stem =~ s/ê$//) {
    $table = [ map "$stem$_", qw( ê eē ê inu êdi êlu   ē eē ē ēnu ēdi ēco ) ];
  } elsif($type eq 'fem' && $stem =~ s/ē$//) {
    $table = [ map "$stem$_", qw( ē eē ē ēnu ēdi ēco   ē eē ē ēnu ēdi ēco ) ];
  } elsif($stem =~ s/i$//) {
    $type = 'fem';
    $table = [ map "$stem$_", qw( i iē a inu idi iu    ā aē ā ānu ādi ālu ) ];
  }

  else {
    return;
  }

  if($type eq 'masc') {
    # change root consonant before -ex sg.gen. and -i plural
    # except when preceded by another consonant or a long or circumflexed vowel
    for(@$table) {
      if(/$alteri(?:i(?:ē|i|[nt]u|co)?)$/o
         && !/(?:$vlong|$vcirc|$consonant)(?:$alteri)(?:i(?:ē|i|[nt]u|co)?)$/o) {
        s/($alteri)(?=i(?:ē|i|[nt]u|co)?$)/$alter{$1}/o;
      }
      if(/$altere(?:ex)$/o
         && !/(?:$vlong|$vcirc|$consonant)(?:$altere)(?:ex)$/o) {
        s/($altere)(?=ex$)/$alter{$1}/o;
      }
    }

    # change -vas to -f- in the singular except genitive
    if($noun =~ /vas$/) {
      for(@{$table}[2..5]) {
        s/v(?=(?:[nt]u|co)?$)/f/;
      }
    }

    # change -zos to -s-, ditto
    if($noun =~ /zos$/) {
      for(@{$table}[2..5]) {
        s/z(?=(?:[nt]u|co)?$)/s/;
      }
    }

    # assimilate voicing and place of articulation for -nu, -tu, -co forms
    for(@{$table}[3..5]) {
      s/($ustop)(?=$voiced)/$voiced{$1}/g;
      s/($vstop)(?=$unvoiced)/$unvoiced{$1}/g;
      s/n(?=$labial)/m/g;
      s/m(?=$dental)/n/g;
    }
  } elsif($type eq 'neut') {
    # change root consonant before -ex sg.gen. and -ī plural
    # except when preceded by another consonant or a long or circumflexed vowel
    for(@$table) {
      if(/$alteri(?:ī(?:[nt]a|co)?)$/o
         && !/(?:$vlong|$vcirc|$consonant)(?:$alteri)(?:ī(?:[nt]a|co)?)$/o) {
        s/($alteri)(?=ī(?:[nt]a|co)?$)/$alter{$1}/o;
      }
      if(/$altere(?:ex)$/o
         && !/(?:$vlong|$vcirc|$consonant)(?:$altere)(?:ex)$/o) {
        s/($altere)(?=ex$)/$alter{$1}/o;
      }
    }

    # change -Viu and -Viū to -Vyu and -Vyū in nom.sg. and nom.pl. of -iu nouns
    # also, change altered root consonants back in the plural gen..ins
    if($noun =~ /iu$/) {
      $table->[0] =~ s/($vowel)iu$/$1yu/;
      $table->[6] =~ s/($vowel)iū$/$1yū/;

      for(@{$table}[7..11]) {
        if(/($altered)(?:uē|ū(?:[nt]a|co)?)$/o && exists $rootchange{$1}{$noun}) {
          s/($altered)(?=(?:uē|ū(?:[nt]a|co)?)$)/$rootchange{$1}{$noun}/o;
        }
      }
    }
  } elsif($type eq 'fem') {
    # change root consonant before -e or -ē plurals of -a nouns
    # except when preceded by another consonant or a long or circumflexed vowel
    if($noun =~ /a$/) {
      for(@{$table}[6..11]) {
        if(/$altere(?:eē|ē(?:[nl]u|di)?)$/o
           && !/(?:$vlong|$vcirc|$consonant)(?:$altere)(?:eē|ē(?:[nl]u|di)?)$/o) {
          s/($altere)(?=(?:eē|ē(?:[nl]u|di)?)$)/$alter{$1}/o;
        }
      }
    }

    # change -Viē to -Vyē in sg.gen. of -i nouns
    # also, change altered root consonants back in the sg.acc. and plural
    elsif($noun =~ /i$/) {
      $table->[1] =~ s/($vowel)iē$/$1yē/;

      for(@{$table}[2,6..11]) {
        if(/($altered)(?:aē|ā(?:[nl]u|di)?)$/o && exists $rootchange{$1}{$noun}) {
          s/($altered)(?=(?:aē|ā(?:[nl]u|di)?)$)/$rootchange{$1}{$noun}/o;
        }
      }
    }
  }

  return $table;
}

my %root = (
);

sub root {
  my $noun = shift;
  my $stem = $noun;
  my $type = 'fem';
  my $table;

  $type = 'masc' if exists $masc{$noun};
  $type = 'neut' if exists $neut{$noun};

  return $root{$noun} if exists $root{$noun};

  # masculine
  if($stem =~ m/[pbtdcgfvzxmnlr]$/) {
    $table = $stem . 'i-';
  } elsif($type eq 'masc' && $stem =~ s/e$//) {
    $table = $stem . 'i-';
  } elsif($stem =~ s/os$//) {
    $table = $stem . 'i-';
  } elsif(exists $aetas{$noun} && $stem =~ s/as$//) {
    $table = $stem . 'a-';
  } elsif($stem =~ s/as$//) {
    $table = $stem . 'i-';
  }

  # neuter
  elsif($stem =~ s/iu$//) {
    $table = $stem . 'i-';
  } elsif($stem =~ s/u$//) {
    $table = $stem . 'u-';
  } elsif($stem =~ s/o$//) {
    $table = $stem . 'o-';
  } elsif($stem =~ s/āu$//) {
    $table = $stem . 'a-';
  }

  # feminine
  elsif($stem =~ s/a$// || $stem =~ s/â$// || $stem =~ s/ā$//) {
    $table = $stem . 'e-';
  } elsif($type eq 'fem' && $stem =~ s/e$//) {
    $table = $stem . 'i-';
  } elsif($stem =~ s/i$//) {
    $table = $stem . 'i-';
  }

  else {
    return;
  }

  for($table) {
    # change root consonant before -e and -i
    # except when preceded by another consonant or a circumflexed vowel
    if(/$alteri(?:i-)$/o
       && !/(?:$vcirc|$consonant)(?:$alteri)(?:i-)$/o) {
      s/($alteri)(?=(?:i-)$)/$alter{$1}/o;
    }
    if(/$altere(?:e-)$/o
       && !/(?:$vcirc|$consonant)(?:$altere)(?:e-)$/o) {
      s/($altere)(?=(?:e-)$)/$alter{$1}/o;
    }

    # restore original root consonant before -a -o -u
    if(/([syc])[aou]-$/
       && exists $rootchange{$1}{$noun})
    {
      s/([syc])[aou]-$/$rootchange{$1}{$noun}/;
    }
  }

  return $table;
}

my %adj = (
);

sub adj {
  my $adj = shift;
  my $stem = $adj;
  my $table;

  return $adj{$adj} if exists $adj{$adj};

  if($stem =~ s/o$//) {
    $table = [ [ map "$stem$_", qw( e ex  e  nu  tu  co   i  iē i  inu  itu  ico  ) ],
               [ map "$stem$_", qw( o ex  o onu otu oco   ō  oē ō  ōna  ōta  ōco  ) ],
               [ map "$stem$_", qw( a aē  a anu adi alu   ē  eē ē  ēnu  ēdi  ēlu  ) ], ];
  } elsif($stem =~ s/e$//) {
    $table = [ [ map "$stem$_", qw( e ex  e  nu  tu  co   i  iē i  inu  itu  ico  ) ],
               [ map "$stem$_", qw( e ex  e inu etu eco   ēi eē ēi ēinu ēitu ēico ) ],
               [ map "$stem$_", qw( e eē  e inu edi elu   ē  eē ē  ēnu  ēdi  ēlu  ) ], ];
  } elsif($stem =~ s/ê$//) {
    $table = [ [ map "$stem$_", qw( ê ex  ê  nu  tu  co   i  iē i  inu  itu  ico  ) ],
               [ map "$stem$_", qw( ê ex  ê inu êtu êco   ēi eē ēi ēinu ēitu ēico ) ],
               [ map "$stem$_", qw( ê eē  ê inu êdi êlu   ē  eē ē  ēnu  ēdi  ēlu  ) ], ];
  } elsif($stem =~ s/i$//) {
    $table = [ [ map "$stem$_", qw( i iex i inu itu ico   ū  uē ū  ūna  ūta  ūco  ) ],
               [ map "$stem$_", qw( i iex i inu itu ico   ū  uē ū  ūna  ūta  ūco  ) ],
               [ map "$stem$_", qw( i iē  i inu idi iu    ā  aē ā  ānu  ādi  ālu  ) ], ];
  } else {
    return;
  }

  # TODO - add root changes e.g. -si --> -c- in the plural

  return $table;
}


my %comp = (
);

sub comp {
  my $adj = shift;
  my $stem = $adj;
  my $word;

  return $comp{$adj} if exists $comp{$adj};

  if($stem =~ s/o$//) {
    if($stem =~ /$vlong/o) {
      $word = $stem . 'ate';
    } else {
      $word = $stem . 'âte';
    }
  } elsif($stem =~ s/e$//) {
    if($stem =~ /$vlong/o) {
      $word = $stem . 'ase';
    } else {
      $word = $stem . 'âse';
    }
  } elsif($stem =~ s/i$//) {
    if($stem =~ /$vlong/o) {
      $word = $stem . 'ise';
    } else {
      $word = $stem . 'îse';
    }
  } else {
    return;
  }

  return $word;
}


my %comb = (
);

sub comb {
  my $adj = shift;
  my $stem = $adj;

  return $comb{$adj} if exists $comb{$adj};

  if($stem =~ m/o$/) {
    return $stem;
  } elsif($stem =~ s/e$//) {
    return $stem . 'i';
  } elsif($stem =~ m/i$/) {
    return $stem;
  } else {
    return;
  }
}


my %long = (
  'a'  => 'ā',
  'e'  => 'ē',
  'i'  => 'ī',
  'o'  => 'ō',
  'u'  => 'ū',
  'A'  => 'Ā',
  'E'  => 'Ē',
  'I'  => 'Ī',
  'O'  => 'Ō',
  'U'  => 'Ū',
);

sub assimilate {
  return unless ref $_[0];
  # Apply sound changes
  for(@{$_[0]}) {
    # 1. A stop assimilates to a following consonant in voicing
    s/($ustop)(?=$voiced)/$voiced{$1}/g;
    s/($vstop)(?=$unvoiced)/$unvoiced{$1}/g;

    # 2. n before m, b, p, l --> m; m before t, d, c, g, x --> n
    s/n(?=$labial)/m/g;
    s/m(?=$dental)/n/g;

    # 3. aa --> ā, etc:
    s/($vowel)\1/$long{$vowel}/g;

    # 4. y before a consonant becomes i;
    #    i between two other vowels becomes y
    s/y(?=$consonant)/i/g;
    s/($vowel)i(?=$vowel)/$1y/g;
  }
}


1;
__END__

=head1 NAME

Lingua::Zompist::Cuezi - Inflect Cuezi nouns, verbs, and adjectives

=head1 VERSION

This document refers to version 0.01 of Lingua::Zompist::Cuezi.

=head1 SYNOPSIS

  # no imports; using fully qualified function names
  use Lingua::Zompist::Cuezi;
  $i_am = Lingua::Zompist::Cuezi::demeric('ESAN')->[0];

  # import specific functions into the current namespace
  use Lingua::Zompist::Cuezi qw( demeric crifel );
  $you_know = demeric('SCRIFEC')->[1];
  $they_had = crifel('TENEC')->[5];

  # import all functions into the current namespace
  use Lingua::Zompist::Cuezi ':all';
  $i_am = demeric('ESAN')->[0];

  $table = noun('CUONOS');  # nouns
  $table = noun('SEO');     # pronouns
  $table = noun('KETTOS');  # pronouns
  $table = adj('KHALTES');  # adjectives

  # verbs -- separate functions
  $table = demeric('SCRIFEC');     # (static definite) present
  $table = scrifel('SCRIFEC');     # (static definite) past
  $table = izhcrifel('SCRIFEC');   # (static definite) past anterior
  $table = budemeric('SCRIFEC');   # (static) remote present
  $table = buscrifel('SCRIFEC');   # (static) remote past
  $table = bubefel('SCRIFEC');     # (static remote) imperative

  # dynamic definite present
  $table = dynamic('SCRIFEC', 'prilise', 'demeric');
  $table = dynamic('SCRIFEC', 'definite', 'present');
  # dynamic remote past
  $table = dynamic('SCRIFEC', 'buprilise', 'scrifel');
  $table = dynamic('SCRIFEC', 'remote', 'past');

  ($present, $past, $gerund) = part('SCRIFEC'); # participles

  # verbs -- via the %verb hash -- in English
  $table = $verb{static}{definite}{present}->('SCRIFEC');
  $table = $verb{dynamic}{remote}{past}->('SCRIFEC');

  # verbs -- via the %verb hash -- in Verdurian/Cuezi
  $table = $verb{static}{prilise}{demeric}->('SCRIFEC');
  $table = $verb{dynamic}{buprilise}{scrifel}->('SCRIFEC');

=head1 DESCRIPTION

=head2 Overview

Lingua::Zompist::Cuezi is a module which allows you to inflect CuE<ecirc>zi
words. You can conjugate verbs and decline nouns, pronouns, adjectives, and the
definite article.

There is one function to inflect nouns and pronouns. There are also functions
for inflect adjectives and to form comparative and superlative forms as well as
adverbs from them. Finally, there are several functions to inflect verbs,
depending on the aspect, mood, and tense, and a function to form the
participles of a verb.

There is also a hash which you can ask to import which may make the maze of
verb-inflecting functions a little easier to use.

=head2 Exports

Lingua::Zompist::Cuezi exports no functions by default, in order to avoid
namespace pollution. This enables, for example, Lingua::Zompist::Cuezi and
Lingua::Zompist::Verdurian to be used in the same program, since otherwise some
of the function names would clash. However, all functions listed here can be
imported explicitly by naming them, or they can be imported all together by
using the tag ':all'.

You can also ask to import the hash C<%verb>. This hash is not imported by
default, even if you ask for ':all'; you have to ask for it by name. For
example:

  use Lingua::Zompist::Cuezi qw(:all %verb);
  # or
  use Lingua::Zompist::Cadhionr '%verb';

=head2 Capitalisation and character set

This module expects all input to be in upper case and will return all output
in upper case. You should use the standard Latin transcription method for
CuE<ecirc>zi (with "TH" for I<ten>, "DH" for I<edh>, and "KH" for I<kodh>).

In the future, this module may expect and produce the charset used by the
F<Maraille> font. At that point, the module Lingua::Zompist::Convert is
expected to be available, which should be able to convert between that charset
and standard charsets such as iso-8859-1 and utf-8.

=head2 noun

This function allows you to inflect nouns and pronouns (including personal
pronouns such as I<SEO> and I<LET> and relative and interrogative pronouns
such as I<KEDIE>, I<PSIAT>, and I<KETTOS>).

It takes one argument, the noun or pronoun to inflect, and returns an arrayref
on success, or C<undef> or the empty list on failure (for example, because it
could not determine which conjugation a noun belonged to).

In general, the arrayref will have ten elements, in the following order:
nominative singular, genitive singular, accusative singular, dative singular,
ablative singular, nominative plural, genitive plural, accusative plural,
dative plural, ablative plural. In some cases, some of those elements may be
C<undef> (especially in the plural of non-personal pronouns such as I<KETTOS>
or I<THIKEDIE> -- but not I<KAE>).

The function should determine the gender and declension of the noun or pronoun
automatically. Nouns ending in I<-IS> are taken to be feminine unless they are
on an internal list of neuter nouns in I<-IS>. If you find a neuter noun
in I<-IS> which is not recognised correctly, please send me email.

=over 4

=item Note

The personal pronouns I<TAS>, I<MUKH>, and I<CAI>, as well as the forms
I<ZAHIE, ZAHAM, ZAHAN, ZAHATH> are not recognised by this function; rather,
they are returned as part of I<SEO>, I<LET>, I<TU>, and I<ZE> respectively. So
to find out the genitive of I<we>, look for the genitive plural of I<I>. The
pseudo-nominative corresponding to the accusative I<ZETH> is I<ZE> (borrowed
from Verdurian).

=back

=head2 adj

This function inflects adjectives (including I<AELU> and I<ILLU>).  It expects
one argument (the adjective to decline) and returns an arrayref on success, or
C<undef> or the empty list on failure.

The arrayref will itself contain three arrayrefs, each with ten elements. The
first arrayref will contain the masculine forms, the second arrayref will
contain the neuter forms, and the third arrayref will contain the feminine
forms. The forms are in the same order as in the arrayref returned by the
L<noun|/"noun"> function. Briefly, this order is nominative - genitive -
accusative - dative - ablative in singular and plural.

This function should determine the declension of an adjective automatically.

There is currently no function which returns the declension of an adjective
(partly because the matter is so simple -- first declension adjectives end in
-<cons>/-O/-A, second declension in -ES/-E/-IES, and third declension in
-IS/-IS/-IS; however, if there is popular demand for such a function it could
be quickly added.

=head2 comp

Blah blah blah.

=head2 inf

Blah blah blah.

=head2 root

Blah blah blah.

=head2 comb

Blah blah blah.

=head2 part

This function returns the three participles of a verb. It takes the verb as an
argument and returns an arrayref (in scalar context) or a list (in list
context) of three elements: the present (nominative) participle, the past
(accusative) participle, and the gerund (participle of need; "to be
E<lt>verbE<gt>ed"). On failure, it returns C<undef> or the empty list.

Specifically, the form returned for each participle is the masculine nominative
singular form of the participle (which can be considered the citation form).
Since participles decline like regular adjectives, the other forms of the
participles may be obtained by calling the L<adj|/"adj"> function, if desired.

=head2 %verb

To ease the confusion caused by the different verbal functions (remembering
to use a 'bu-' function for the remote tense, or the different interface
in the dynamic aspect), it is also possible to inflect verbs by importing the
hash C<%verb> into the current namespace.

This hash contains references to subroutines which only need to be passed
the name of the verb to be inflected.

To fully qualify a tense, use the aspect, mood, and tense in that order, for
example:

  $table = $verb{static}{remote}{present}->('SCRIFEC');

This will place an arrayref with the forms of the static remote present of
the verb "SCRIFEL" in C<$table>. It is also possible to use the
Verdurian/CuE<ecirc>zi names of the moods and tenses:

  $table = $verb{static}{buprilise}{demeric}->('SCRIFEC');

For convenience, it is also possible to use an abbreviated notation. Since
I suppose that the most common aspect is the static aspect, and the most
common mood the definite mood, you can leave off those aspects and moods
if you wish. So the following should all yield the same result:

  $table = $verb{static}{definite}{past}->('SCRIFEC');
  $table = $verb{definite}{past}->('SCRIFEC');
  $table = $verb{static}{past}->('SCRIFEC');
  $table = $verb{past}->('SCRIFEC');
  $table = $verb{static}{prilise}{scrifel}->('SCRIFEC');
  $table = $verb{prilise}{scrifel}->('SCRIFEC');
  $table = $verb{static}{scrifel}->('SCRIFEC');
  $table = $verb{scrifel}->('SCRIFEC');

As a special nod to laziness, if you use {imperative} or {befel} without
specifying a mood, remote rather than the definite mood is chosen, since there
is no definite imperative in CuE<ecirc>zi. So C<< $verb{befel}->('CREGEN')->[1] >>
and C<< $verb{static}{imperative}->('CREGEN')->[1] >> give you the equivalent
of C<< $verb{static}{remote}{imperative}->('CREGEN')->[1] >> rather than the
equivalent of C<< $verb{static}{definite}{imperative}->('CREGEN')->[1] >>.

On the other hand, you may find this interface to be more confusing than
calling the different functions directly. Take your pick and use whichever
you prefer :-).

=head1 BUGS

This module should handle irregular words correctly. However, if there is a
word that is inflected incorrectly, please send me email and notify me.

However, please make sure that you have checked against a current version of
http://www.zompist.com/native.htm or F<PreCadh.doc>, or that you asked Mark
Rosenfelder himself; the grammar occasionally changes as small errors are found
or words change.

=head1 SEE ALSO

L<Lingua::Zompist::Kebreni>, L<Lingua::Zompist::Verdurian>,
L<Lingua::Zompist::Cadhinor>, F<PreCadh.doc> (available from
http://www.zompist.com/embassy.htm#learning )

=head1 AUTHOR

Philip Newton, E<lt>pne@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2001 by Philip Newton.  All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

=over 4

=item *

Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer. 

=item *

Redistributions in binary form must reproduce the above copyright notice, this
list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution. 

=back

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut
