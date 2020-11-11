#!/usr/bin/perl -I/home/phil/perl/cpan/DataTableText/lib/
#-------------------------------------------------------------------------------
# The Gearhart-Brenan Dita Topic Naming Standard
# Philip R Brenan at gmail dot com, Appa Apps Ltd Inc., 2019
#-------------------------------------------------------------------------------
# podDocumentation
# gbBinaryStandardFileName produces different results when given the file name versus the file content - it should be the same
package Dita::GB::Standard;
our $VERSION = 20201030;
require v5.16;
use warnings FATAL => qw(all);
use strict;
use Carp qw(confess);
use Data::Dump qw(dump);
use Data::Table::Text qw(:all);
use utf8;

sub useWords{0}                                                                 #r Use word representation of md5 sum if true

# Each word is 5 characters long so we can gain 5 bits per word using capitalization. There are 2177 words below or 11 bits - enough room to reach 16 bits per word with the 5 extra from capitalization.
my @words = qw(aback abate abbey abhor abide abort about above abuse abyss acorn acrid actor acute adage adapt adept admit adobe adopt adore adorn adult affix after again agent agile aging agony agree ahead aisle alarm album aleck alert algae alias alibi alien align alike alive allah allay alley allot allow alloy aloft aloha alone along aloof aloud altar alter amass amaze amber amble amend amiss among ample amply amuse angel anger angle anglo angry angst ankle annex annoy annul anvil apart apple apply april apron aptly ardor arena argue aries arise armed armor aroma arose array arrow arson artsy ashen ashes asian aside askew asset atlas attic audio audit aural avail avert avoid await awake award aware awash awful awoke axiom bacon badge badly bagel baggy baker balls balmy banal bandy bangs banjo barge baron bases basic basin basis batch bated bathe baton bawdy bayou beach beady beard beast bebop beech beefy befit began begin begun beige being belch belie belly below bench beret berry berth beset bible bigot biker billy bimbo binge bingo biped birch birth bison black blade blame bland blank blare blase blast blaze bleak bleed blend bless blimp blind blink bliss blitz block blond blood bloom blown blues bluff blunt blurb blurt blush board boast bogus bongo bonus booby books boost booth booty booze bored borne bosom bossy botch bough bound bowel boxer brace braid brain brake brand brash brass brave bravo brawl brawn bread break breed bribe brick bride brief brine bring brink briny brisk broad broil broke brood brook broom broth brown brunt brush brute buddy budge buggy bugle build built bulge bulky bully bumps bumpy bunch bunny burly burnt burst bushy butte buxom buyer bylaw byway cabby cabin cable cache cacti cadet cadre caged cagey camel cameo canal candy canny canoe caper carat cards cargo carne carol carry carte carve caste catch cater catty cause cease cedar cello chafe chain chair chalk champ chant chaos chaps charm chart chase chasm cheap cheat check cheek cheer chess chest chewy chick chide chief child chili chill chime chimp china chink chirp choir choke chord chore chose chuck chump chunk churn chute cider cigar cinch circa civic civil clack claim clamp clang clank clash clasp class claus clean clear cleat cleft clerk click cliff climb cling clink cloak clock clone close cloth cloud clout clove clown clubs cluck clump clung clunk coach coals coast cobra cocky cocoa colic colon color comet comfy comic comma condo coral corny corps cotta couch cough could count court cover covet cower crack craft cramp crane crank craps crash crass crate crave crawl craze crazy creak cream credo creed creek creep crepe crept crest crick crime crimp crisp croak crock crony crook croon cross crowd crown crude cruel crumb crush crust crypt cubic curio curly curry curse curve curvy cycle cynic daddy daily dairy daisy dally dance dandy darts dated daunt dazed dealt death debit debug debut decaf decal decay decor decoy decry defer deign deity delay delta delve demon denim dense depot depth derby deter detox devil diary dicey digit dimly diner dingy dirty disco ditch ditto ditty diver dixie dizzy dodge doggy dogma dolly donna donor dopey dorky doubt dough douse dowdy downy dowry dozen drabs draft drain drake drama drank drape drawl drawn dread dream dregs dress dribs dried drier drift drill drink drive droll drone drool droop drops drove drown drunk dryer dryly dummy dumpy dunce dusty dutch dwarf dwell dwelt dying eager eagle early earth easel eaten eater eaves ebony edict edify eerie eight eject elbow elder elect elegy elfin elite elope elude elves embed ember emcee emery empty enact endow enemy enjoy ensue enter entry envoy epoch equal equip erase erect erode error erupt essay ether ethic evade event every evict evoke exact exalt excel exert exile exist expel extol extra exude exult facet faint fairy faith false famed fancy fanny farce fatal fated fatty fault fauna favor feast fecal feces feign feint felon fence ferry fetal fetch fetid fetus fever fiber field fiend fiery fifth fifty fight filch filet filly filmy filth final finch first fishy fixed fizzy fjord flail flair flake flaky flame flank flare flash flask fleck fleet flesh flick flier fling flint flirt float flock flood floor flora floss flour flout flown fluff fluid fluke flung flunk flush flute foamy focal focus foggy foist folks folly foray force forge forgo forte forth forty forum found foyer frail frame franc frank fraud freak fresh friar fried fries frill frisk frizz frond front frost froth frown froze fruit fudge fully fumes funds fungi funky funny furor furry fussy fuzzy gabby gable gaffe gaily games gamut gassy gaudy gauge gaunt gauze gavel gawky geeky geese genre genus getup ghost ghoul giant giddy girth given gizmo glade gland glare glass glaze gleam glean glide glint glitz gloat globe gloom glory gloss glove gnash gnome godly gofer going golly goner gonna goods goody gooey goofy goose gorge gotta gouge gourd grace grade graft grain grand grant grape graph grasp grass grate grave gravy graze great greed greek green greet grief grill grime grimy grind gripe grits groan groin groom grope gross group grove growl grown gruel gruff grunt guard guess guest guide guild guile guilt guise gulch gully gumbo gummy gushy gusto gusty gutsy gypsy habit hairy halve handy happy hardy harem harsh haste hasty hatch hated haunt haven havoc hazel heads heady heard heart heave heavy hedge heels hefty heist hello hence heron hertz hiker hilly hindu hinge hippo hitch hives hoard hobby hoist hokey holly homer homey honey honor hoops horde horny horse hotel hotly hound hours house hovel hover howdy huffy human humid humor hunch hurry husky hutch hyena hyper icing ideal idiom idiot igloo image imbue impel imply inane incur index inept inert infer inlet inner input inter inuit irate irish irony islam issue itchy ivory jaded jaunt jazzy jeans jelly jerky jesus jetty jewel jiffy jinks johns joint joker jolly jowls judge juice juicy jumbo jumpy junta juror kaput karat karma kayak kelly khaki kiddo kinky kiosk kitty klutz knack knead kneel knelt knife knock knoll known koala koran kudos label labor laden ladle lance lanky lapel lapse large larva laser lasso latch later latex latin laugh layer leafy leaky leapt learn lease leash least leave ledge leech leery legal leggy legit lemon leper letup levee level lever libel libra light liken lilac limbo limit lined linen liner lines lingo lists liter lithe liven liver lives livid llama loads loath lobby local lodge lofty logic loner looks loony loose loser louse lousy lover lower lowly loyal lucid lucky lumpy lunar lunch lunge lurch lurid lusty lying lynch lyric macho macro madam madly mafia magic major maker mange mango mangy mania manic manly manor maori maple march mardi marks marry marsh mason masse match mater matte mauve maxim maybe mayor mccoy means meant meaty mecca medal media melee melon mercy merge merit merry messy metal meter metro midst might miles milky mimic mince miner minor minty minus mirth miser misty mixed mixer modal model modem moist molar moldy momma mommy money month mooch moody moose moped moral mores moron morse mossy motel motif motor motto mound mount mourn mouse mousy mouth mover movie mower mucus muddy muggy mulch mumbo mummy mumps munch mural murky mushy music musty muted muzak naive naked nanny nappy nasal nasty naval navel needs needy negro neigh nerdy nerve never newly newsy niche niece nifty night ninth nippy noble nobly noise noisy nomad noose north notch noted notes novel nudge nurse nutty nylon nymph oases oasis obese occur ocean oddly offer often oiled olden oldie olive onion onset opera opium optic orbit order organ oscar other otter ought ounce outdo outer ovary overt owing owner oxide ozone paddy padre pagan pager pages pains paint palsy panda panel panic pansy pants papal paper parka parts party passe pasta paste pasty patch patio patty pause payee peace peach pearl pecan pedal peeve penal penny peppy perch peril perky pesky petal peter petty phase phone phony photo piano picky piece piety piggy pilot pinch pinup pious pique pitch pithy pivot pixel pixie pizza place plaid plain plane plank plant plate plaza plead pleat plume plump plunk plush pluto poach point poise poker polar polio polka polls polyp pooch poppy porch posse potty pouch pound power prank prawn preen press price prick pride prima prime primp print prior prism privy prize probe promo prone prong proof prose proud prove prowl proxy prude prune psalm psych pubic pudgy puffy pulse punch pupil puppy puree purge purse pushy pussy putty pygmy pylon pyrex quack quail quake qualm quark quart quash queen queer quell query quest quick quiet quill quilt quirk quite quits quota quote rabbi rabid radar radii radio radon rains rainy raise rally ranch range ranks rapid raspy ratio raven rayon razor reach react ready realm rebel rebut recap recur redid refer regal rehab reign relax relay relic remit renew repay repel reply rerun resin retch revel revue rhino rhyme rider ridge rifle right rigid rigor rinse ripen risen riser risky ritzy rival river rivet roach roast robin robot rocky rodeo rogue roman roomy roost roots rotor rouge rough round rouse route rowdy royal ruddy rugby ruler rummy rumor runny rural rusty saber sadly saint salad sales salon salsa salty salve sandy santa sassy satan satin sauce saucy sauna saute saver savor savvy scads scald scale scalp scaly scant scare scarf scary scene scent scoff scold scoop scoot scope score scorn scour scout scowl scram scrap screw scrub scuba scuff sedan seedy seize sense serum serve setup seven sever sewer shack shade shady shaft shake shaky shall shame shape share shark sharp shave shawl sheaf shear sheen sheep sheer sheet sheik shelf shell shift shine shiny shirk shirt shoal shock shone shook shoot shore shorn short shout shove shown showy shred shrub shrug shuck shunt shush shyly sidle siege sieve sight silky silly since sinew singe sinus siren sissy sixth sixty skate skier skill skimp skirt skull skunk slack slain slake slang slant slash slate slave sleek sleep sleet slept slice slick slide slime slimy sling slink slope slosh sloth slump slung slunk slurp slush slyly smack small smart smash smear smell smile smirk smith smock smoke smoky snack snafu snail snake snare snarl sneak sneer snide sniff snipe snoop snore snort snout snowy snuck snuff soapy sober softy soggy solar solid solve sonic sorry sound south space spade spank spare spark spasm spate spawn speak spear speck speed spell spelt spend spent spice spicy spiel spike spill spine spire spite splat splay split spoil spoke spoof spook spool spoon sport spout spray spree sprig spurn spurt squad squat squid stack staff stage staid stain stair stake stale stalk stall stamp stand stank stare stark stars start stash state stave steak steal steam steel steep steer stern stick stiff still stilt sting stink stint stock stoic stoke stole stomp stone stony stood stool stoop store stork storm story stout stove strap straw stray strep strew strip strum strut stuck study stuff stump stung stunk stunt style suave suede sugar suite sulky sunny sunup super surge surly swamp swank swarm swear sweat sweep sweet swell swept swift swine swing swipe swirl swish swiss swoon swoop sword swore sworn swung synod syrup tabby table taboo tacit tacky taffy tails taint taken talks tally talon tango tangy taper tardy tarot tarry taste tasty taunt tawny teach tease teddy teens teeth tempo tempt tenet tenor tense tenth tepee tepid terms terra terse testy thank theft their theme there these thick thief thigh thing think third thong thorn those three threw throb throw thumb thump tiara tidal tiger tight timer times timid tinge tinny tipsy tired title tizzy toast today toefl token tongs tonic tooth topic torch torso total totem touch tough towel tower toxic toxin trace track tract trade trail train trait tramp trash trawl tread treat trend trial tribe trick trike trill tripe trite troll tromp troop trout truce truck truly trump trunk trust truth tubby tulip tummy tumor tuner tunic tutor twang tweak tweed tweet twerp twice twine twirl twist udder ulcer uncle uncut under undid undue unfit unify union unite unity untie until unzip upend upper upset urban usage usher usual usurp uteri utter vague valet valid valor value valve vapor vault vegan venom venue venus verge versa verse verve vibes video vigil vigor villa vinyl viola viper viral virgo virus visit visor vista vital vivid vocal vodka vogue voice vomit voter vouch vowel wacky wafer wager wages wagon waist waive waken waltz wanna wares waste watch water waver weary weave wedge weigh weird welsh whack whale wharf wheat wheel where which whiff while whine whirl whisk white whole whoop whose widen widow width wield wiles wimpy wince winch windy wings wiper wired wispy witch witty wives woken woman women woods woody wooly woozy words wordy works world worms worry worse worst worth would wound woven wrath wreak wreck wrest wring wrist write wrong wrote wrung wryly xerox yacht yearn years yeast yield yodel yokel young yours youth yucky yummy zebra);

!useWords or @words > 2**11 or confess "Not enough words";

sub hex4ToBits($)                                                               #P Represent 4 hex digits as (1, 1, 1, 1, 1, 12) bits
 {my ($h) = @_;
  my $n   = hex($h);
  my $n11 = $n % 2**11;
  my $n12 = ($n>>11) % 2;
  my $n13 = ($n>>12) % 2;
  my $n14 = ($n>>13) % 2;
  my $n15 = ($n>>14) % 2;
  my $n16 = ($n>>15) % 2;
 ($n16, $n15, $n14, $n13, $n12, $n11);
 }

sub hexAsWords($)                                                               #P Given a hex string represent it as words at a rate of 16 bits per word
 {my ($hex) = @_;

  my $d     = length($hex) % 4;
     $hex  .= '0' x (4-$d) if $d;

  my @w;

  for my $p(1..length($hex) / 4)                                                # Each block of hex representing 16 bits
   {my ($a, $b, $c, $d, $e, $r) = hex4ToBits(substr($hex, 4*($p-1), 4));
    my $w = $words[$r];
       $w =                  uc(substr($w, 0, 1)).substr($w, 1) if $a;
       $w = substr($w, 0, 1).uc(substr($w, 1, 1)).substr($w, 2) if $b;
       $w = substr($w, 0, 2).uc(substr($w, 2, 1)).substr($w, 3) if $c;
       $w = substr($w, 0, 3).uc(substr($w, 3, 1)).substr($w, 4) if $d;
       $w = substr($w, 0, 4).uc(substr($w, 4, 1)).substr($w, 5) if $e;
    push @w, $w;
   }

  join '_', @w;
 }

#D1 Make and manage utf8 files                                                  # Make and manage files that conform to the L<GBStandard> and are coded in utf8.

sub gbStandardFileName($$%)                                                     #E Return the L<GBStandard> file name given the content and extension of a proposed file.
 {my ($content, $extension, %options) = @_;                                     # Content, extension, options
  defined($content) or confess "Content must be defined";
  $content     =~ s(\s*xtr[cf]="[^"]*") ()gs;                                   # Suppress xtrc|f attributes as we use them to hold file names and line numbers during a conversion but they are not germane to the final result and thus prevent files from being collapsed.

  $extension && ($extension =~ m(\A\S{2,}\Z)s) or
    confess "Extension must be non blank and at least two characters long";
  my $name = $options{g} || nameFromStringRestrictedToTitle($content, %options);# Human readable component either as supplied in exceptional cases, or ideally, as taken from the title tag according to the prescription of the Monroe Title Method.
  my $md5  = $options{md5} // stringMd5Sum($content);                           # Md5 sum either as supplied or computed

  fpe($name.q(_).(&useWords ? hexAsWords($md5) : $md5),                         # Add extension
      fe($extension)||$extension);                                              # fe returns blank given an extension name without a .
 }

sub gbStandardCompanionFileName($)                                              #E Return the name of the L<Companion File> given a file whose name complies with the L<GBStandard>.
 {my ($file) = @_;                                                              # L<GBStandard> file name
  setFileExtension($file);                                                      # Remove extension to get companion file name
 }

sub gbStandardCompanionFileContent($)                                           #E Return the content of the L<Companion File> given a file whose name complies with the L<GBStandard>.
 {my ($file) = @_;                                                              # L<GBStandard> file name
  readFile(gbStandardCompanionFileName($file))                                  # L<GBStandard> companion file name content
 }

sub gbStandardCreateFile($$$%)                                                  #E Create a file in the specified B<$Folder> whose name is the L<GBStandard> name for the specified B<$content> and return the file name,  A L<Companion File> can, optionally, be  created with the specified B<$companionContent>
 {my ($Folder, $content, $extension, %options) = @_;                            # Target folder or a file in that folder, content of the file, file extension, options.
  my $folder = fp $Folder;                                                      # Normalized folder name
  my $file   = gbStandardFileName($content, $extension, %options);              # Entirely satisfactory

  my $out    = fpf($folder, $file);                                             # Output file
  overWriteFile($out, $content);                                                # Write file content

  if (my $content = $options{companionContent})                                 # Write a companion file if some content for it has been supplied
   {my $comp = gbStandardCompanionFileName($out);                               # Companion file name
    if (!-e $comp)                                                              # Do not overwrite existing companion file
     {writeFile($comp, $content);                                               # Write companion file
     }
    else
     {lll "Companion file already exists:\n$comp\n";
     }
   }
  $out
 }

sub gbStandardRename($%)                                                        #E Check whether a file needs to be renamed to match the L<GBStandard>. Return the correct name for the file or  B<undef> if the name is already correct.
 {my ($file, %options) = @_;                                                    # File to check, options
  my $content  = readFile($file);                                               # Content of proposed file
  my $ext      = fe($file);                                                     # Extension of proposed file
  my $proposed = gbStandardFileName($content, $ext, %options);                  # Proposed name according to the L<GBStandard>
  my $base     = fne($file);                                                    # The name of the current file minus the path
  return undef if $base eq $proposed;                                           # Success - the names match
  $proposed                                                                     # Fail - the name should be this
 }

sub gbStandardCopyFile($%)                                                      #E Copy a file to the specified B<$target> folder renaming it to the L<GBStandard>.  If no B<$Target> folder is specified then rename the file in its current folder so that it does comply with the L<GBStandard>.
 {my ($source, %options) = @_;                                                  # Source file, options
  -e $source && !-d $source or                                                  # Check that the source file exists and is a file
    confess "Source file to normalize does not exist:\n$source";

  my $target = $options{target};                                                # The target folder (or a file in it) to which to copy this file
  my $correctName = gbStandardRename($source, %options);                        # Get the correct name for the file

  if ($target and $target ne fp($source))                                       # New target folder specified
   {my $t = fpf($target, fne($correctName//$source));                           # Target of copy
    copyFile($source, $t);                                                      # Copy file
    my $cs = gbStandardCompanionFileName($source);                              # Companion file source
    my $ct = gbStandardCompanionFileName($t);                                   # Companion file target
    if (-e $cs)                                                                 # Copy companion source file if it exists
     {copyFile($cs, $ct);                                                       # Copy companion source file
     }
    else                                                                        # Create companion target file if it does not exist
     {dumpFile($ct, {source=>$source});                                         # Write source file name to companion file target
     }
    return $t;
   }
  elsif ($correctName)                                                          # Rename file to match L<GBStandard>
   {my $t = fpf(fp($source), fne $correctName);                                     # Full file name
    rename $source, $t;                                                         # Rename file so it matches L<GBStandard>
    return $t;
   }
  undef
 }

sub gbStandardDelete($)                                                         #E Delete a file and its companion file if there is one.
 {my ($file) = @_;                                                              # File to delete
  my $comp   = gbStandardCompanionFileName($file);
  unlink $_ for $comp, $file;
 }

#D1 Make and manage binary files                                                # Make and manage files that conform to the L<GBStandard> and are in plain binary.

sub gbBinaryStandardFileName($$)                                                #E Return the L<GBStandard> file name given the content and extension of a proposed file.
 {my ($content, $extension) = @_;                                               # Content a file or a string, extension
  defined($content) or confess "Content must be defined";

  my $e = fe($extension) || $extension;                                         # File extension - if given an extension without a leading . fe will return blank
  $e =~ m(\A\S{2,}\Z)s or
    confess "Extension must be non blank and at least two characters long: ".
    dump([$e, $extension]);
  my $name   = lc $e;                                                           # Human readable component was taken from the file content but this produced long garbled names as there was no useful ascii content at the start of most image files.  Substituted the extension lower case instead to separate the images out in directory listings.
  my $md5    = stringMd5Sum($content);                                          # Md5 sum
  fpe($name.q(_).(&useWords ? hexAsWords($md5) : $md5), $e)                     # Add extension
 }

sub gbBinaryStandardCompanionFileName($)                                        #E Return the name of the companion file given a file whose name complies with the L<GBStandard>.
 {my ($file) = @_;                                                              # L<GBStandard> file name
  setFileExtension($file);                                                      # Remove extension to get companion file name
 }

sub gbBinaryStandardCompanionFileContent($)                                     #E Return the content of the L<Companion File> given a file whose name complies with the binary L<GBStandard>.
 {my ($file) = @_;                                                              # L<GBStandard> file name
  readFile(gbStandardCompanionFileName($file))                                  # L<GBStandard> companion file name content
 }

sub gbBinaryStandardCreateFile($$$;$)                                           #E Create a file in the specified B<$Folder> whose name is the L<GBStandard> name for the specified B<$content> and return the file name,  A L<Companion File> can, optionally, be  created with the specified B<$companionContent>.
 {my ($Folder, $content, $extension, $companionContent) = @_;                   # Target folder or a file in that folder, content of the file, file extension, contents of the companion file.
  my $folder = fp $Folder;                                                      # Normalized folder name
  my $file   = gbBinaryStandardFileName($content, $extension);                  # Entirely satisfactory

  my $out    = fpf($folder, $file);                                             # Output file
  overWriteBinaryFile($out, $content);                                          # Write file content

  if (defined $companionContent)                                                # Write a companion file if some content for it has been supplied
   {my $comp = gbBinaryStandardCompanionFileName($out);                         # Companion file name
    if (!-e $comp)                                                              # Do not overwrite existing companion file
     {writeBinaryFile($comp, $companionContent);                                # Write companion file
     }
    else
     {lll "Companion file already exists:\n$comp\n";
     }
   }
  $out
 }

sub gbBinaryStandardRename($)                                                   #E Check whether a file needs to be renamed to match the L<GBStandard>. Return the correct name for the file or  B<undef> if the name is already correct.
 {my ($file)   = @_;                                                            # File to check
  my $content  = readBinaryFile($file);                                         # Content of proposed file
  my $proposed = gbBinaryStandardFileName($content, $file);                     # Proposed name according to the L<GBStandard>
  my $base     = fne($file);                                                    # The name of the current file minus the path
  return undef if $base eq $proposed;                                           # Success - the names match
  $proposed                                                                     # Fail - the name should be this
 }

sub gbBinaryStandardCopyFile($;$)                                               #E Copy a file to the specified B<$target> folder renaming it to the L<GBStandard>.  If no B<$Target> folder is specified then rename the file in its current folder so that it does comply with the L<GBStandard>.
 {my ($source, $target) = @_;                                                   # Source file, target folder or a file in the target folder
  -e $source && !-d $source or                                                  # Check that the source file exists and is a file
    confess "Source file to normalize does not exist:\n$source";
  my $correctName = gbBinaryStandardRename($source);                            # Get the correct name for the file
  if ($target and $target ne fp($source))                                       # New target folder specified
   {my $t = fpf($target, fne($correctName // $source));                         # Target of copy
    copyBinaryFile($source, $t);                                                # Copy file
    my $cs = gbBinaryStandardCompanionFileName($source);                        # Companion file source
    my $ct = gbBinaryStandardCompanionFileName($t);                             # Companion file target

    if (-e $cs)                                                                 # Copy companion source file if it exists
     {copyFile($cs, $ct);                                                       # Copy companion source file
     }
    else                                                                        # Create companion target file if it does not exist
     {dumpFile($ct, {source=>$source});                                         # Write source file name to companion file target
     }
    return $t;
   }
  elsif ($correctName)                                                          # Rename file to match L<GBStandard>
   {my $t = fpf(fp($source), fne $correctName);                                 # Full file name
    rename $source, $t;                                                         # Rename file so it matches L<GBStandard>
    return $t;
   }
  undef
 }

sub gbBinaryStandardDelete($)                                                   #E Delete a file and its L<Companion File> if there is one.
 {my ($file) = @_;                                                              # File to delete
  my $comp   = gbBinaryStandardCompanionFileName($file);
  unlink $_ for $comp, $file;
 }

#Doff

say STDERR "gbStandard Exportable Methods:\n",
 formatTable(reportExportableMethods($0)) if 0;

#-------------------------------------------------------------------------------
# Export
#-------------------------------------------------------------------------------

use Exporter qw(import);

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

@ISA          = qw(Exporter);
@EXPORT_OK    = qw(
gbBinaryStandardCompanionFileContent
gbBinaryStandardCompanionFileName
gbBinaryStandardCopyFile
gbBinaryStandardCreateFile
gbBinaryStandardDelete
gbBinaryStandardFileName
gbBinaryStandardRename
gbStandardCompanionFileContent
gbStandardCompanionFileName
gbStandardCopyFile
gbStandardCreateFile
gbStandardDelete
gbStandardFileName
gbStandardRename
);
%EXPORT_TAGS  = (all=>[@EXPORT, @EXPORT_OK]);

# podDocumentation

my $nameFromStringMaximumLength = Data::Table::Text::nameFromStringMaximumLength;

my $documentationSynopsis = <<END;

The L<GBStandard> is a means of naming L<Dita> topic files to enable global
collaboration through uncoordinated content sharing.

The L<GBStandard> creates a human readable, deterministic file name which
depends solely on the content to be stored in that file. Such file names are
guaranteed to differ between files that contain differing content while being
identical for files that contain identical content by the use of an L<md5> in
the file name.

The L<GBStandard> name looks like this:

  human_readable_part_derived_from_content + _ + md5_sum_of_content + extension

The human readable part from content is derived solely from the content of the
file by interpreting the file content as L<unicode> encoded as L<utf8>, then:

 - replacing instances of xml tags with underscores

 - replacing all characters other than a-z,A-Z,0-9 with underscores

 - replacing runs of underscores with a single underscore

 - removing any leading or trailing underscores

 - truncating the component if it extends beyond $nameFromStringMaximumLength characters.

The original file name for the content is not considered as part of the content
of the file and so plays no part in choosing the L<GBStandard> name for that
content.

If the file contains a B<title> tag then only the content of the B<title> tag
is processed as described above to obtain the human readable component of the
file name. If any of the following L<Dita> tags are found in a source file
which also contains a B<title> tag then the following codes are prefixed to
this file name as well:

  Code      Tag
  bm_       bookmap
  c_        concept
  r_        reference
  t_        task

The L<md5> component of the file name is calculated from the content of the
file and presented as lowercase hexadecimal.

The file extension component is obtained from:
L<https://en.wikipedia.org/wiki/List_of_filename_extensions>

Thus if a B<dita> file has content:

 <concept>
   <title>abc 𝝰𝝱𝝲</title>
   <conbody/>
 </concept>

then the L<GBStandard> name for the file is:

  c_abc_8551cffdb92932637d952e04447783c8.dita

If the option to present the L<md5> as five letter English words is chosen
then the standardized name for this content becomes:

  c_abc_Plume_VApoR_CaPER_eqUAl_qUAIL_saInT_mEdia_Irony.dita

`head2 Benefits

The file names generated by the L<GBStandard> can be exploited in numerous ways
to simplify the creation, conversion, management and sharing of large
repositories of documents written to the L<dita> standard:

`head3 Parallel Processing

Complex long running document transformations can be speeded up by running the
transformations in parallel.

The file name generated by the L<GBStandard> is unique when computed by
competing parallel processes so files that have the same name have the same
content and can be safely overwritten by another process without attempting to
coordinate names between processes.  Likewise files that have different names
are guarenteed to have different content and so can be written out without
checking for an existing file of that name.

Alternative systems relying on coordination between the parallel processes to
choose names to avoid collisions and reuse identical content perform ever more
badly as the number of files increases because there are ever more files to
check for matching content and names.  Coordination between parallel processes
stops the processes from running fully in parallel. Conversely, eliminating the
need for coordination between parallel processes allows each process to run
more fully in parallel.

As a consequence, the L<GBStandard> enables parallel L<Dita> conversions to
scale effectively.

`head3 File Flattening

Files are automatically flattened by the L<GBStandard> as files with the same
content have the same name and so can safely share one global folder without
fear of name collisions or having multiple names for identical content.

`head3 Testing

The name of each file reflects only its content making it easier to write tests
for software build around the L<GBStandard>: it is no longer necessary to test
that the content of the file is as expected when it is sufficent just to test
the base name of the file.

One could, of course, compute the L<md5> of the file easily during testing
but: the fact that one is computing such a sum at all shows just how useful
such a sum is, which implies that it should be the one and only piece of meta
data encoded in the file name.  All othermeta data should reside within the
file rather then being encoded in the file name so that said meta data is not
destroyed by renaming the file.

`head3 Mixed Multiple Conversions

When converting documents to L<Dita> it is a standard practice to perform the
conversion in batches by source document type, perhaps B<html> files first, then
B<docbook> files, then L<word> files. Thus leaves the problem of merging the
results into one corpus after each individual conversion.  The L<GBStandard>
resolves this problem by guaranteeing the uniqueness of the converted
files allowing them to be merged into one results folder without collisions.

`head3 No Relative Paths in References

If all the topic files share one global folder there is no need for complicated
path expressions in references such as:

  <image href="../../../image\x{200B}files/size\x{200B}large/aaa.png"/>

Extended path names that are repeated across many references are, in effect, a
form of boiler plate which can be avoided by applying this standard.

`head3 Relocating Dita References After Folder Restructuring

In the ideal implementation all files named with the L<GBStandard> occupy one
global folder.  In circumstances where this is not possible, such files can
easily be moved into sub folders without fear of collisions, although, any Dita
references between such files might have to be updated.  This update is easily
performed because only the path component has to be updated and the value of
the new path can easily be found by searching for the base component of the
topic file name using a utility such as L<find>.  For a more efficient method,
see L<Data::Edit::Xml::Xref>.

`head3 Similar Files Tend To Appear Close Together In Directory Listings.

Imagine the user has several files in different folders all starting:

  <title>License Agreement</title>

The L<GBStandard> computes the human readable component of the name in a
consistent way using only the contents of each file.  Once the name has been
standardized, all these files can be placed in B<one> folder to get a directory
listing like:

  license_agreement_a6e3...
  license_agreement_b532...
  license_agreement_c65d...

This grouping signals that these files are potentially similar to each other
and thus might be better merged into one shareable file.

As the L<GBStandard> is applied to ever more such files, ever more such matches
occur.

`head3 Copying And Moving Files For Global Interoperability

Users can copy files named using the L<GBStandard> around from folder to folder
without fear of collisions or duplication obviating the need for the time
consuming checks and reportage otherwise required before performing such
actions.  The meta data in the L<Companion File> can also be copied in a similar
fearless manner.

If two users wish to share content: their files named using the L<GBStandard>
can be incorporated directly into the other user's file system without fear of
collisions or duplicating content thus promoting global content sharing and
collaboration of L<Dita> content.

`head3 Guidization For Content Management Systems

Self constructed Content Management Systems using BitBucket, GitHub or Gitlab
that rely on guidization to differentiate files placed in these repositories
benefit immensely: the L<guid> to use can be easily derived from the L<md5> sum
in the L<GBStandard> file name.

`head3 No need for authors to coordinate topic file names

The L<GBStandard> is relevant to the administration of a production document
corpus. A production corpus being a corpus of documents that is B<evolving>
over time under the control of an administrator.

If an author is developing a document from scratch, in splendid isolation,
then, initially, the author might well wish to use topic file names of their
own choice to contain their topics as this will speed their efforts.

For example, it is not uncommon for an author to create a file called:

  introduction.xml

to hold the introduction to the new document they are writing.

At some point the system administrator will wish to incorporate the topic files
comprising the new document produced by the author into the production corpus.

The chance that any of the file names that the author has chosen will conflict
with the existing names in the production corpus as generated by the
L<GBStandard> is negligible. It is thus safe for the administrator to copy the
author's topic files directly into the production corpus without renaming any
of them.  Sooner or later, however, the administrator might wish to run an
automated scan of the entire production corpus to rename such recent additions
to the L<GBStandard>, to update all the references between these files that
would otherwise be invalidated by such changes and thereby to clear the
production corpus to make it ready to receive other new documents whose topic
file names, being chosen by humans, would otherwise very likely conflict with
existing topic file names already in the production corpus.

Thus clearing the production corpus by applying the L<GBStandard> obviates the
need for authors to coordinate the names of the files that they choose for
their topics with those choosen by other authors allowing each author to
proceed efficiently in isolated parallelism, spending more time writing and
less time in meetings with other authors discussing their latest file naming
strategy.

`head3 Using Dita Tags To Describe Content

The L<GBStandard> encourages L<Dita> users to use meta data tags to describe
their documents so that content can be found by searching with L<grep> rather
than encoding file meta data in file names then searching for the required file
using L<find>.  Such file names quickly become very long and unmanageable: on
the one hand they need spaces in them to make them readable, but on the other
hand, the spaces make such files difficult to cut and paste or use from the
L<commandLine>.

`head3 Cut And Paste

As there are no spaces in the files names created using the L<GBStandard> such
file names can be selected by a mouse double click and thus easily copied and
pasted into other documents.

Conversely, one has to use cut and paste to manipulate such file names making
it impossible to mistype such file names in other documents.

`head3 CSV files

Files named using the L<GBStandard> can be safely included in B<.csv> files
because they have no spaces in them!

`head3 Automatic File Versioning

Files named to the L<GBStandard> File names change when their content changes.
So if the content of a file changes its name must change as well. Thus an
attempt to present an out-of-date version of a file produces a file name that
cannot be found.

`head3 Enhanced Command Line Processing

As file names named with the L<GBStandard> do not have spaces in them (such as
L<zeroWidthSpace>) they work well on the L<commandLine> and with the many
L<commandLine> tools that are used to manipulate such files enhancing the
productivity leverage that L<commandLine> has always had versus L<GUI>
processing.

`head3 Locating Files by Their Original Names Or Other Meta-Data

Each file produced by the L<GBStandard> can have a L<Companion File> of the same
name but without an extension.  The L<Companion File> contains meta-data about the
file such as its original location etc. which can be searched by L<grep> or
similar.

To find such a file use L<grep> to find the L<Companion File> containing the
searched for content, paste that file name into the L<commandLine> after
entering any command such as B<ll> and then press B<.> followed by the L<tab>
key to have the L<shell> expand it to locate the L<GBStandard> file that
corresponds to the located L<Companion File>.  For example:

  \\grep -r 'SR-dashboard-ds.png'

  png_f940c7db293fe377e7d49c4e0c654cb2:  source => "/home/phil/r/pureStorage/docBook/download/OE_User_Guide/SRRBeta/images/screenshots/dashboard/SR-dashboard-ds.png",

  ls png_f940c7db293fe377e7d49c4e0c654cb2.png

`head3 Use with AWS Simple Storage Service

Viewing files held in L<s3> is made much easier if they are all in one flat
folder with uniqwue base names as there is no folder structure to navigate over
a nework.  Simply type the start of the B<G> part, the Human Readdable
Component, and press enter to see the possible candidates.

`head2 Companion File

Each file named using the L<GBStandard> may be accompanied by a
L<Companion File> that contains meta data describing the file, said data
formatted as a L<Perl> data structure.

The name of the L<Companion File> is obtained by removing the extension from the
file named using the L<GBStandard>.

As the content of the companion files is in plain text, such text is easy to
search using L<grep> or other textual search tools.

A common use of the companion file is to record the orginal file name and
author of the content in question:

  {source=>q(C:/my documents/dita files/content.dita),
   author=>q(A. N. Mouse),
  }

`head2 Alternate File Names

Most operating systems allow the use of links to supply alternate names for a
file. Consequently, users who wish to impose a different file naming scheme
might care to consider using links to implement their own file naming system on
top of the L<GBStandard> without disrupting the integrity of the L<GBStandard>.

For example: L<xref> produces B<Oxygen Project Files> which provide a virtual
hierarchical folder view of an otherwise flat folder.

`head2 Implementation

The L<GBStandard> has been implemented as a L<Perl> package at:

L<http://metacpan.org/pod/Dita::GB::Standard>

`head2 Binary vs Utf8

Files that are expected to contain data encoded with L<utf8> (eg .dita, .xml)
should use method names that start with:

 gbStandard

Files that are expected to contain binary data (eg .png, .jpg) should use
method names that start with:

 gbBinaryStandard

The binary standard forms file names by prefixing the L<md5> value with the
extension of the file in lower case and an underscore to prevent the long
garbled file names that would otherwise be chosen if the normal standard were
applied directly to naming such content and to group such files close together
in directory listings.

Consequently, a B<png> file with content:

  q(\0abc\1)

will be represented by the name:

  png_2786f1147a331ec6ebf60c1ba636a458.png

`head2 Documentation Copyright

The documentation for this module is dual licensed with the L<gnuFDL> as well
as the L<perlAL> in the hope that this will encourage its further dissemination
as a universal standard.

END

my $removedSections = <<END;
`head3 Using Longer Titles To Describe Content

The L<GBStandard> encourages L<Dita> writers to choose better titles for their
topics.  A title of B<Introduction> is fine as far as a single document goes,
the subject matter to which we are being introduced is presumably the title of
the containing book, perhaps: B<The Art of Making Pasta>.

But suppose you are creating a library with millions of searchable books?
Problems start to arise:  many other books will have introductions too; many of
these introductions will share similar sentiments and content.  If, like
L<sws>, you are in the business of selling paper, this is a good thing. If you
are management trying to make it easy for readers to find relevant articles
while reducing writing costs, then a different approach might be indicated.

A first step would be to insist that the proper topic title is more self
contained so it can be found in isolation:

  Introduction to the Art of Making Pasta

and that the file that contains this topic starts with a name easily and
consistently derived from the title:

  Introduction_to_the_Art_of_Making_Pasta ....

so that it can be more easily found by both readers and writers.

A second step might be to standardize introductions as much as possible to
reduce their number and to enable the production of targeted variants such as:

  Introduction to the Art of Making Pasta for Beginners

or

  Introduction to the Art of Making Pasta for Visitors from Italy

by mixing and matching standardized content from elsewhere.

The L<GBStandard> facilitates both of these actions by grouping the
introduction files close together further differentiated by an L<md5>
on the right.

An instinctive desire to push the L<md5> further to the right where it is less
visible encourages the writer to choose a longer more explicit and hopefully
unique title.

As the file name is derived from the title it is easy for a reader to find a
file given the title especially when the title is unique.

The fact that the library has millions of topics called B<Introduction> is made
abundantly clear to management when the folder holding these files is printed
out alphabetically, placed on their desks and they try looking for a topic
about B<Jam>, The difficulties encountered in getting past B<I> encourages
management to ask: "Why do we have so many slightly different introductions"?

END

=pod

=encoding utf-8

=head1 Name

Dita::GB::Standard - The Gearhart-Brenan Dita Topic Naming Standard.

=head1 Synopsis

The L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> is a means of naming L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> topic files to enable global
collaboration through uncoordinated content sharing.

The L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> creates a human readable, deterministic file name which
depends solely on the content to be stored in that file. Such file names are
guaranteed to differ between files that contain differing content while being
identical for files that contain identical content by the use of an L<md5 sum|https://en.wikipedia.org/wiki/MD5> in
the file name.

The L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> name looks like this:

  human_readable_part_derived_from_content + _ + md5_sum_of_content + extension

The human readable part from content is derived solely from the content of the
file by interpreting the file content as L<Unicode|https://en.wikipedia.org/wiki/Unicode> encoded as L<utf8|https://en.wikipedia.org/wiki/UTF-8>, then:

 - replacing instances of xml tags with underscores

 - replacing all characters other than a-z,A-Z,0-9 with underscores

 - replacing runs of underscores with a single underscore

 - removing any leading or trailing underscores

 - truncating the component if it extends beyond $nameFromStringMaximumLength characters.

The original file name for the content is not considered as part of the content
of the file and so plays no part in choosing the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> name for that
content.

If the file contains a B<title> tag then only the content of the B<title> tag
is processed as described above to obtain the human readable component of the
file name. If any of the following L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> tags are found in a source file
which also contains a B<title> tag then the following codes are prefixed to
this file name as well:

  Code      Tag
  bm_       bookmap
  c_        concept
  r_        reference
  t_        task

The L<md5 sum|https://en.wikipedia.org/wiki/MD5> component of the file name is calculated from the content of the
file and presented as lowercase hexadecimal.

The file extension component is obtained from:
L<https://en.wikipedia.org/wiki/List_of_filename_extensions>

Thus if a B<dita> file has content:

 <concept>
   <title>abc 𝝰𝝱𝝲</title>
   <conbody/>
 </concept>

then the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> name for the file is:

  c_abc_8551cffdb92932637d952e04447783c8.dita

If the option to present the L<md5 sum|https://en.wikipedia.org/wiki/MD5> as five letter English words is chosen
then the standardized name for this content becomes:

  c_abc_Plume_VApoR_CaPER_eqUAl_qUAIL_saInT_mEdia_Irony.dita

=head2 Benefits

The file names generated by the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> can be exploited in numerous ways
to simplify the creation, conversion, management and sharing of large
repositories of documents written to the L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> standard:

=head3 Parallel Processing

Complex long running document transformations can be speeded up by running the
transformations in parallel.

The file name generated by the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> is unique when computed by
competing parallel processes so files that have the same name have the same
content and can be safely overwritten by another process without attempting to
coordinate names between processes.  Likewise files that have different names
are guarenteed to have different content and so can be written out without
checking for an existing file of that name.

Alternative systems relying on coordination between the parallel processes to
choose names to avoid collisions and reuse identical content perform ever more
badly as the number of files increases because there are ever more files to
check for matching content and names.  Coordination between parallel processes
stops the processes from running fully in parallel. Conversely, eliminating the
need for coordination between parallel processes allows each process to run
more fully in parallel.

As a consequence, the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> enables parallel L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> conversions to
scale effectively.

=head3 File Flattening

Files are automatically flattened by the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> as files with the same
content have the same name and so can safely share one global folder without
fear of name collisions or having multiple names for identical content.

=head3 Testing

The name of each file reflects only its content making it easier to write tests
for software build around the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>: it is no longer necessary to test
that the content of the file is as expected when it is sufficent just to test
the base name of the file.

One could, of course, compute the L<md5 sum|https://en.wikipedia.org/wiki/MD5> of the file easily during testing
but: the fact that one is computing such a sum at all shows just how useful
such a sum is, which implies that it should be the one and only piece of meta
data encoded in the file name.  All othermeta data should reside within the
file rather then being encoded in the file name so that said meta data is not
destroyed by renaming the file.

=head3 Mixed Multiple Conversions

When converting documents to L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> it is a standard practice to perform the
conversion in batches by source document type, perhaps B<html> files first, then
B<docbook> files, then L<word|https://en.wikipedia.org/wiki/Doc_(computing)> files. Thus leaves the problem of merging the
results into one corpus after each individual conversion.  The L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>
resolves this problem by guaranteeing the uniqueness of the converted
files allowing them to be merged into one results folder without collisions.

=head3 No Relative Paths in References

If all the topic files share one global folder there is no need for complicated
path expressions in references such as:

  <image href="../../../image{200B}files/size{200B}large/aaa.png"/>

Extended path names that are repeated across many references are, in effect, a
form of boiler plate which can be avoided by applying this standard.

=head3 Relocating Dita References After Folder Restructuring

In the ideal implementation all files named with the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> occupy one
global folder.  In circumstances where this is not possible, such files can
easily be moved into sub folders without fear of collisions, although, any Dita
references between such files might have to be updated.  This update is easily
performed because only the path component has to be updated and the value of
the new path can easily be found by searching for the base component of the
topic file name using a utility such as L<find|https://en.wikipedia.org/wiki/Find_(Unix)>.  For a more efficient method,
see L<Data::Edit::Xml::Xref>.

=head3 Similar Files Tend To Appear Close Together In Directory Listings.

Imagine the user has several files in different folders all starting:

  <title>License Agreement</title>

The L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> computes the human readable component of the name in a
consistent way using only the contents of each file.  Once the name has been
standardized, all these files can be placed in B<one> folder to get a directory
listing like:

  license_agreement_a6e3...
  license_agreement_b532...
  license_agreement_c65d...

This grouping signals that these files are potentially similar to each other
and thus might be better merged into one shareable file.

As the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> is applied to ever more such files, ever more such matches
occur.

=head3 Copying And Moving Files For Global Interoperability

Users can copy files named using the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> around from folder to folder
without fear of collisions or duplication obviating the need for the time
consuming checks and reportage otherwise required before performing such
actions.  The meta data in the L<Companion File> can also be copied in a similar
fearless manner.

If two users wish to share content: their files named using the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>
can be incorporated directly into the other user's file system without fear of
collisions or duplicating content thus promoting global content sharing and
collaboration of L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> content.

=head3 Guidization For Content Management Systems

Self constructed Content Management Systems using BitBucket, GitHub or Gitlab
that rely on guidization to differentiate files placed in these repositories
benefit immensely: the L<guid|https://en.wikipedia.org/wiki/Universally_unique_identifier> to use can be easily derived from the L<md5 sum|https://en.wikipedia.org/wiki/MD5> sum
in the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> file name.

=head3 No need for authors to coordinate topic file names

The L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> is relevant to the administration of a production document
corpus. A production corpus being a corpus of documents that is B<evolving>
over time under the control of an administrator.

If an author is developing a document from scratch, in splendid isolation,
then, initially, the author might well wish to use topic file names of their
own choice to contain their topics as this will speed their efforts.

For example, it is not uncommon for an author to create a file called:

  introduction.xml

to hold the introduction to the new document they are writing.

At some point the system administrator will wish to incorporate the topic files
comprising the new document produced by the author into the production corpus.

The chance that any of the file names that the author has chosen will conflict
with the existing names in the production corpus as generated by the
L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> is negligible. It is thus safe for the administrator to copy the
author's topic files directly into the production corpus without renaming any
of them.  Sooner or later, however, the administrator might wish to run an
automated scan of the entire production corpus to rename such recent additions
to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>, to update all the references between these files that
would otherwise be invalidated by such changes and thereby to clear the
production corpus to make it ready to receive other new documents whose topic
file names, being chosen by humans, would otherwise very likely conflict with
existing topic file names already in the production corpus.

Thus clearing the production corpus by applying the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> obviates the
need for authors to coordinate the names of the files that they choose for
their topics with those choosen by other authors allowing each author to
proceed efficiently in isolated parallelism, spending more time writing and
less time in meetings with other authors discussing their latest file naming
strategy.

=head3 Using Dita Tags To Describe Content

The L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> encourages L<Dita|http://docs.oasis-open.org/dita/dita/v1.3/os/part2-tech-content/dita-v1.3-os-part2-tech-content.html> users to use meta data tags to describe
their documents so that content can be found by searching with L<grep|https://en.wikipedia.org/wiki/Grep> rather
than encoding file meta data in file names then searching for the required file
using L<find|https://en.wikipedia.org/wiki/Find_(Unix)>.  Such file names quickly become very long and unmanageable: on
the one hand they need spaces in them to make them readable, but on the other
hand, the spaces make such files difficult to cut and paste or use from the
L<command line|https://en.wikipedia.org/wiki/Command-line_interface>.

=head3 Cut And Paste

As there are no spaces in the files names created using the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> such
file names can be selected by a mouse double click and thus easily copied and
pasted into other documents.

Conversely, one has to use cut and paste to manipulate such file names making
it impossible to mistype such file names in other documents.

=head3 CSV files

Files named using the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> can be safely included in B<.csv> files
because they have no spaces in them!

=head3 Automatic File Versioning

Files named to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> File names change when their content changes.
So if the content of a file changes its name must change as well. Thus an
attempt to present an out-of-date version of a file produces a file name that
cannot be found.

=head3 Enhanced Command Line Processing

As file names named with the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> do not have spaces in them (such as
L<zero width space|https://en.wikipedia.org/wiki/Zero-width_space>) they work well on the L<command line|https://en.wikipedia.org/wiki/Command-line_interface> and with the many
L<command line|https://en.wikipedia.org/wiki/Command-line_interface> tools that are used to manipulate such files enhancing the
productivity leverage that L<command line|https://en.wikipedia.org/wiki/Command-line_interface> has always had versus L<graphical user interface|https://en.wikipedia.org/wiki/Graphical_user_interface>
processing.

=head3 Locating Files by Their Original Names Or Other Meta-Data

Each file produced by the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> can have a L<Companion File> of the same
name but without an extension.  The L<Companion File> contains meta-data about the
file such as its original location etc. which can be searched by L<grep|https://en.wikipedia.org/wiki/Grep> or
similar.

To find such a file use L<grep|https://en.wikipedia.org/wiki/Grep> to find the L<Companion File> containing the
searched for content, paste that file name into the L<command line|https://en.wikipedia.org/wiki/Command-line_interface> after
entering any command such as B<ll> and then press B<.> followed by the L<tab|https://en.wikipedia.org/wiki/Tab_key>
key to have the L<shell|https://en.wikipedia.org/wiki/Shell_(computing)> expand it to locate the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> file that
corresponds to the located L<Companion File>.  For example:

  \\grep -r 'SR-dashboard-ds.png'

  png_f940c7db293fe377e7d49c4e0c654cb2:  source => "/home/phil/r/pureStorage/docBook/download/OE_User_Guide/SRRBeta/images/screenshots/dashboard/SR-dashboard-ds.png",

  ls png_f940c7db293fe377e7d49c4e0c654cb2.png

=head3 Use with AWS Simple Storage Service

Viewing files held in L<S3|https://s3.console.aws.amazon.com/s3/home> is made much easier if they are all in one flat
folder with uniqwue base names as there is no folder structure to navigate over
a nework.  Simply type the start of the B<G> part, the Human Readdable
Component, and press enter to see the possible candidates.

=head2 Companion File

Each file named using the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> may be accompanied by a
L<Companion File> that contains meta data describing the file, said data
formatted as a L<Perl|http://www.perl.org/> data structure.

The name of the L<Companion File> is obtained by removing the extension from the
file named using the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

As the content of the companion files is in plain text, such text is easy to
search using L<grep|https://en.wikipedia.org/wiki/Grep> or other textual search tools.

A common use of the companion file is to record the orginal file name and
author of the content in question:

  {source=>q(C:/my documents/dita files/content.dita),
   author=>q(A. N. Mouse),
  }

=head2 Alternate File Names

Most operating systems allow the use of links to supply alternate names for a
file. Consequently, users who wish to impose a different file naming scheme
might care to consider using links to implement their own file naming system on
top of the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> without disrupting the integrity of the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

For example: L<Xref|https://metacpan.org/pod/Data::Edit::Xml::Xref> produces B<Oxygen Project Files> which provide a virtual
hierarchical folder view of an otherwise flat folder.

=head2 Implementation

The L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> has been implemented as a L<Perl|http://www.perl.org/> package at:

L<http://metacpan.org/pod/Dita::GB::Standard>

=head2 Binary vs Utf8

Files that are expected to contain data encoded with L<utf8|https://en.wikipedia.org/wiki/UTF-8> (eg .dita, .xml)
should use method names that start with:

 gbStandard

Files that are expected to contain binary data (eg .png, .jpg) should use
method names that start with:

 gbBinaryStandard

The binary standard forms file names by prefixing the L<md5 sum|https://en.wikipedia.org/wiki/MD5> value with the
extension of the file in lower case and an underscore to prevent the long
garbled file names that would otherwise be chosen if the normal standard were
applied directly to naming such content and to group such files close together
in directory listings.

Consequently, a B<png> file with content:

  q(\0abc\1)

will be represented by the name:

  png_2786f1147a331ec6ebf60c1ba636a458.png

=head2 Documentation Copyright

The documentation for this module is dual licensed with the L<GNU Free Documentation License|https://en.wikipedia.org/wiki/Wikipedia:Text_of_the_GNU_Free_Documentation_License> as well
as the L<Perl Artistic Licence|https://dev.perl.org/licenses/artistic.html> in the hope that this will encourage its further dissemination
as a universal standard.

=head1 Description

The Gearhart-Brenan Dita Topic Naming Standard.


Version 20190901.


The following sections describe the methods in each functional area of this
module.  For an alphabetic listing of all methods by name see L<Index|/Index>.



=head1 Make and manage utf8 files

Make and manage files that conform to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> and are coded in utf8.

=head2 gbStandardFileName($$%)

Return the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> file name given the content and extension of a proposed file.

     Parameter   Description
  1  $content    Content
  2  $extension  Extension
  3  %options    Various ingenious options designed by Micaela

B<Example:>


  if (1) {
    if (useWords)
     {ok 𝗴𝗯𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗙𝗶𝗹𝗲𝗡𝗮𝗺𝗲(<<END, q(dita)) eq q(c_abc_Plume_VApoR_CaPER_eqUAl_qUAIL_saInT_mEdia_Irony.dita);
  <concept>
    <title>abc 𝝰𝝱𝝲</title>
    <conbody/>
  </concept>
  END
     }
    else
     {ok 𝗴𝗯𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗙𝗶𝗹𝗲𝗡𝗮𝗺𝗲(<<END, q(c_abc.dita)) eq q(c_abc_8551cffdb92932637d952e04447783c8.dita);
  <concept xtrf="A">
    <title>abc 𝝰𝝱𝝲</title>
    <conbody/>
  </concept>
  END
     }
   }


This method can be imported via:

  use Dita::GB::Standard qw(gbStandardFileName)


=head2 gbStandardCompanionFileName($)

Return the name of the L<Companion File> given a file whose name complies with the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

     Parameter  Description
  1  $file      L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> file name

B<Example:>


  ok 𝗴𝗯𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗖𝗼𝗺𝗽𝗮𝗻𝗶𝗼𝗻𝗙𝗶𝗹𝗲𝗡𝗮𝗺𝗲(q(a/b.c)) eq q(a/b);


This method can be imported via:

  use Dita::GB::Standard qw(gbStandardCompanionFileName)


=head2 gbStandardCompanionFileContent($)

Return the content of the L<Companion File> given a file whose name complies with the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

     Parameter  Description
  1  $file      L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> file name

B<Example:>


  if (1) {
    my $s = qq(\0abc\1);
    my $S = q(Hello World);
    my $d = temporaryFolder;
    my $D = temporaryFolder;
    clearFolder($_, 10) for $d, $D;

    my $f = gbBinaryStandardCreateFile($d, $s, q(xml), $S);                       # Create file
    ok -e $f;
    ok readFile($f) eq $s;

    my $c = gbBinaryStandardCompanionFileName($f);                                # Check companion file
    ok -e $c;
    ok 𝗴𝗯𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗖𝗼𝗺𝗽𝗮𝗻𝗶𝗼𝗻𝗙𝗶𝗹𝗲𝗖𝗼𝗻𝘁𝗲𝗻𝘁($c) eq $S;

    ok gbBinaryStandardCompanionFileContent($f) eq $S;                            # Check companion file content

    my $F = gbBinaryStandardCopyFile($f, $D);                                     # Copy file
    ok -e $F;
    ok readFile($F) eq $s;

    my $C = gbBinaryStandardCompanionFileName($F);                                # Check companion file
    ok -e $C;
    ok gbBinaryStandardCompanionFileContent($C) eq $S;

    ok 𝗴𝗯𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗖𝗼𝗺𝗽𝗮𝗻𝗶𝗼𝗻𝗙𝗶𝗹𝗲𝗖𝗼𝗻𝘁𝗲𝗻𝘁($F) eq $S;                                  # Check companion file content

    ok !gbBinaryStandardRename($F);                                               # No rename required to standardize file name

    gbBinaryStandardDelete($F);                                                   # Delete file and its companion file
    ok !-e $F;
    ok !-e $C;

    clearFolder($_, 10) for $d, $D;
   }


This method can be imported via:

  use Dita::GB::Standard qw(gbStandardCompanionFileContent)


=head2 gbStandardCreateFile($$$%)

Create a file in the specified B<$Folder> whose name is the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> name for the specified B<$content> and return the file name,  A L<Companion File> can, optionally, be  created with the specified B<$companionContent>

     Parameter   Description
  1  $Folder     Target folder or a file in that folder
  2  $content    Content of the file
  3  $extension  File extension
  4  %options    Options.

B<Example:>


  if (1) {
    my $s = q(abc 𝝰𝝱𝝲);
    my $S = q(Hello World);
    my $d = temporaryFolder;
    my $D = temporaryFolder;
    clearFolder($_, 10) for $d, $D;

    my $f = 𝗴𝗯𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗖𝗿𝗲𝗮𝘁𝗲𝗙𝗶𝗹𝗲($d, $s, q(xml), companionContent=>$S);           # Create file
    ok -e $f;
    ok readFile($f) eq $s;

    my $c = gbStandardCompanionFileName($f);                                      # Check companion file
    ok -e $c;
    ok readFile($c) eq $S;

    my $F = gbStandardCopyFile($f, target=>$D);                                   # Copy file
    ok -e $F;
    ok readFile($F) eq $s;

    my $C = gbStandardCompanionFileName($F);                                      # Check companion file
    ok -e $C;
    ok readFile($C) eq $S;

    ok !gbStandardRename($F);                                                     # No rename required to standardize file name

    gbStandardDelete($F);                                                         # Delete file and its companion file
    ok !-e $F;
    ok !-e $C;

    clearFolder($_, 10) for $d, $D;
   }


This method can be imported via:

  use Dita::GB::Standard qw(gbStandardCreateFile)


=head2 gbStandardRename($%)

Check whether a file needs to be renamed to match the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>. Return the correct name for the file or  B<undef> if the name is already correct.

     Parameter  Description
  1  $file      File to check
  2  %options   Options

B<Example:>


  if (1) {
    my $s = q(abc 𝝰𝝱𝝲);
    my $S = q(Hello World);
    my $d = temporaryFolder;
    my $D = temporaryFolder;
    clearFolder($_, 10) for $d, $D;

    my $f = gbStandardCreateFile($d, $s, q(xml), companionContent=>$S);           # Create file
    ok -e $f;
    ok readFile($f) eq $s;

    my $c = gbStandardCompanionFileName($f);                                      # Check companion file
    ok -e $c;
    ok readFile($c) eq $S;

    my $F = gbStandardCopyFile($f, target=>$D);                                   # Copy file
    ok -e $F;
    ok readFile($F) eq $s;

    my $C = gbStandardCompanionFileName($F);                                      # Check companion file
    ok -e $C;
    ok readFile($C) eq $S;

    ok !𝗴𝗯𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗥𝗲𝗻𝗮𝗺𝗲($F);                                                     # No rename required to standardize file name

    gbStandardDelete($F);                                                         # Delete file and its companion file
    ok !-e $F;
    ok !-e $C;

    clearFolder($_, 10) for $d, $D;
   }


This method can be imported via:

  use Dita::GB::Standard qw(gbStandardRename)


=head2 gbStandardCopyFile($%)

Copy a file to the specified B<$target> folder renaming it to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.  If no B<$Target> folder is specified then rename the file in its current folder so that it does comply with the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

     Parameter  Description
  1  $source    Source file
  2  %options   Options

B<Example:>


  if (1) {
    my $s = q(abc 𝝰𝝱𝝲);
    my $S = q(Hello World);
    my $d = temporaryFolder;
    my $D = temporaryFolder;
    clearFolder($_, 10) for $d, $D;

    my $f = gbStandardCreateFile($d, $s, q(xml), companionContent=>$S);           # Create file
    ok -e $f;
    ok readFile($f) eq $s;

    my $c = gbStandardCompanionFileName($f);                                      # Check companion file
    ok -e $c;
    ok readFile($c) eq $S;

    my $F = 𝗴𝗯𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗖𝗼𝗽𝘆𝗙𝗶𝗹𝗲($f, target=>$D);                                   # Copy file
    ok -e $F;
    ok readFile($F) eq $s;

    my $C = gbStandardCompanionFileName($F);                                      # Check companion file
    ok -e $C;
    ok readFile($C) eq $S;

    ok !gbStandardRename($F);                                                     # No rename required to standardize file name

    gbStandardDelete($F);                                                         # Delete file and its companion file
    ok !-e $F;
    ok !-e $C;

    clearFolder($_, 10) for $d, $D;
   }


This method can be imported via:

  use Dita::GB::Standard qw(gbStandardCopyFile)


=head2 gbStandardDelete($)

Delete a file and its companion file if there is one.

     Parameter  Description
  1  $file      File to delete

B<Example:>


  if (1) {
    my $s = q(abc 𝝰𝝱𝝲);
    my $S = q(Hello World);
    my $d = temporaryFolder;
    my $D = temporaryFolder;
    clearFolder($_, 10) for $d, $D;

    my $f = gbStandardCreateFile($d, $s, q(xml), companionContent=>$S);           # Create file
    ok -e $f;
    ok readFile($f) eq $s;

    my $c = gbStandardCompanionFileName($f);                                      # Check companion file
    ok -e $c;
    ok readFile($c) eq $S;

    my $F = gbStandardCopyFile($f, target=>$D);                                   # Copy file
    ok -e $F;
    ok readFile($F) eq $s;

    my $C = gbStandardCompanionFileName($F);                                      # Check companion file
    ok -e $C;
    ok readFile($C) eq $S;

    ok !gbStandardRename($F);                                                     # No rename required to standardize file name

    𝗴𝗯𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗗𝗲𝗹𝗲𝘁𝗲($F);                                                         # Delete file and its companion file
    ok !-e $F;
    ok !-e $C;

    clearFolder($_, 10) for $d, $D;
   }


This method can be imported via:

  use Dita::GB::Standard qw(gbStandardDelete)


=head1 Make and manage binary files

Make and manage files that conform to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> and are in plain binary.

=head2 gbBinaryStandardFileName($$)

Return the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> file name given the content and extension of a proposed file.

     Parameter   Description
  1  $content    Content
  2  $extension  Extension

B<Example:>


  if (1) {
    if (useWords)
     {ok 𝗴𝗯𝗕𝗶𝗻𝗮𝗿𝘆𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗙𝗶𝗹𝗲𝗡𝗮𝗺𝗲(qq(\0abc\1), q(png)) eq q(png_thInk_BUSHy_dRYER_spaCE_KNOwN_lepeR_SeNse_MaJor.png);
     }
    else
     {ok 𝗴𝗯𝗕𝗶𝗻𝗮𝗿𝘆𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗙𝗶𝗹𝗲𝗡𝗮𝗺𝗲(qq(\0abc\1), q(png)) eq q(png_2786f1147a331ec6ebf60c1ba636a458.png);
     }
   }


This method can be imported via:

  use Dita::GB::Standard qw(gbBinaryStandardFileName)


=head2 gbBinaryStandardCompanionFileName($)

Return the name of the companion file given a file whose name complies with the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

     Parameter  Description
  1  $file      L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> file name

B<Example:>


  ok 𝗴𝗯𝗕𝗶𝗻𝗮𝗿𝘆𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗖𝗼𝗺𝗽𝗮𝗻𝗶𝗼𝗻𝗙𝗶𝗹𝗲𝗡𝗮𝗺𝗲(q(a/b.c)) eq q(a/b);


This method can be imported via:

  use Dita::GB::Standard qw(gbBinaryStandardCompanionFileName)


=head2 gbBinaryStandardCompanionFileContent($)

Return the content of the L<Companion File> given a file whose name complies with the binary L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

     Parameter  Description
  1  $file      L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> file name

B<Example:>


  if (1) {
    my $s = qq(\0abc\1);
    my $S = q(Hello World);
    my $d = temporaryFolder;
    my $D = temporaryFolder;
    clearFolder($_, 10) for $d, $D;

    my $f = gbBinaryStandardCreateFile($d, $s, q(xml), $S);                       # Create file
    ok -e $f;
    ok readFile($f) eq $s;

    my $c = gbBinaryStandardCompanionFileName($f);                                # Check companion file
    ok -e $c;
    ok gbStandardCompanionFileContent($c) eq $S;

    ok 𝗴𝗯𝗕𝗶𝗻𝗮𝗿𝘆𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗖𝗼𝗺𝗽𝗮𝗻𝗶𝗼𝗻𝗙𝗶𝗹𝗲𝗖𝗼𝗻𝘁𝗲𝗻𝘁($f) eq $S;                            # Check companion file content

    my $F = gbBinaryStandardCopyFile($f, $D);                                     # Copy file
    ok -e $F;
    ok readFile($F) eq $s;

    my $C = gbBinaryStandardCompanionFileName($F);                                # Check companion file
    ok -e $C;
    ok 𝗴𝗯𝗕𝗶𝗻𝗮𝗿𝘆𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗖𝗼𝗺𝗽𝗮𝗻𝗶𝗼𝗻𝗙𝗶𝗹𝗲𝗖𝗼𝗻𝘁𝗲𝗻𝘁($C) eq $S;

    ok gbStandardCompanionFileContent($F) eq $S;                                  # Check companion file content

    ok !gbBinaryStandardRename($F);                                               # No rename required to standardize file name

    gbBinaryStandardDelete($F);                                                   # Delete file and its companion file
    ok !-e $F;
    ok !-e $C;

    clearFolder($_, 10) for $d, $D;
   }


This method can be imported via:

  use Dita::GB::Standard qw(gbBinaryStandardCompanionFileContent)


=head2 gbBinaryStandardCreateFile($$$$)

Create a file in the specified B<$Folder> whose name is the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> name for the specified B<$content> and return the file name,  A L<Companion File> can, optionally, be  created with the specified B<$companionContent>.

     Parameter          Description
  1  $Folder            Target folder or a file in that folder
  2  $content           Content of the file
  3  $extension         File extension
  4  $companionContent  Contents of the companion file.

B<Example:>


  if (1) {
    my $s = qq(\0abc\1);
    my $S = q(Hello World);
    my $d = temporaryFolder;
    my $D = temporaryFolder;
    clearFolder($_, 10) for $d, $D;

    my $f = 𝗴𝗯𝗕𝗶𝗻𝗮𝗿𝘆𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗖𝗿𝗲𝗮𝘁𝗲𝗙𝗶𝗹𝗲($d, $s, q(xml), $S);                       # Create file
    ok -e $f;
    ok readFile($f) eq $s;

    my $c = gbBinaryStandardCompanionFileName($f);                                # Check companion file
    ok -e $c;
    ok gbStandardCompanionFileContent($c) eq $S;

    ok gbBinaryStandardCompanionFileContent($f) eq $S;                            # Check companion file content

    my $F = gbBinaryStandardCopyFile($f, $D);                                     # Copy file
    ok -e $F;
    ok readFile($F) eq $s;

    my $C = gbBinaryStandardCompanionFileName($F);                                # Check companion file
    ok -e $C;
    ok gbBinaryStandardCompanionFileContent($C) eq $S;

    ok gbStandardCompanionFileContent($F) eq $S;                                  # Check companion file content

    ok !gbBinaryStandardRename($F);                                               # No rename required to standardize file name

    gbBinaryStandardDelete($F);                                                   # Delete file and its companion file
    ok !-e $F;
    ok !-e $C;

    clearFolder($_, 10) for $d, $D;
   }


This method can be imported via:

  use Dita::GB::Standard qw(gbBinaryStandardCreateFile)


=head2 gbBinaryStandardRename($)

Check whether a file needs to be renamed to match the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>. Return the correct name for the file or  B<undef> if the name is already correct.

     Parameter  Description
  1  $file      File to check

B<Example:>


  if (1) {
    my $s = qq(\0abc\1);
    my $S = q(Hello World);
    my $d = temporaryFolder;
    my $D = temporaryFolder;
    clearFolder($_, 10) for $d, $D;

    my $f = gbBinaryStandardCreateFile($d, $s, q(xml), $S);                       # Create file
    ok -e $f;
    ok readFile($f) eq $s;

    my $c = gbBinaryStandardCompanionFileName($f);                                # Check companion file
    ok -e $c;
    ok gbStandardCompanionFileContent($c) eq $S;

    ok gbBinaryStandardCompanionFileContent($f) eq $S;                            # Check companion file content

    my $F = gbBinaryStandardCopyFile($f, $D);                                     # Copy file
    ok -e $F;
    ok readFile($F) eq $s;

    my $C = gbBinaryStandardCompanionFileName($F);                                # Check companion file
    ok -e $C;
    ok gbBinaryStandardCompanionFileContent($C) eq $S;

    ok gbStandardCompanionFileContent($F) eq $S;                                  # Check companion file content

    ok !𝗴𝗯𝗕𝗶𝗻𝗮𝗿𝘆𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗥𝗲𝗻𝗮𝗺𝗲($F);                                               # No rename required to standardize file name

    gbBinaryStandardDelete($F);                                                   # Delete file and its companion file
    ok !-e $F;
    ok !-e $C;

    clearFolder($_, 10) for $d, $D;
   }


This method can be imported via:

  use Dita::GB::Standard qw(gbBinaryStandardRename)


=head2 gbBinaryStandardCopyFile($$)

Copy a file to the specified B<$target> folder renaming it to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.  If no B<$Target> folder is specified then rename the file in its current folder so that it does comply with the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

     Parameter  Description
  1  $source    Source file
  2  $target    Target folder or a file in the target folder

B<Example:>


  if (1) {
    my $s = qq(\0abc\1);
    my $S = q(Hello World);
    my $d = temporaryFolder;
    my $D = temporaryFolder;
    clearFolder($_, 10) for $d, $D;

    my $f = gbBinaryStandardCreateFile($d, $s, q(xml), $S);                       # Create file
    ok -e $f;
    ok readFile($f) eq $s;

    my $c = gbBinaryStandardCompanionFileName($f);                                # Check companion file
    ok -e $c;
    ok gbStandardCompanionFileContent($c) eq $S;

    ok gbBinaryStandardCompanionFileContent($f) eq $S;                            # Check companion file content

    my $F = 𝗴𝗯𝗕𝗶𝗻𝗮𝗿𝘆𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗖𝗼𝗽𝘆𝗙𝗶𝗹𝗲($f, $D);                                     # Copy file
    ok -e $F;
    ok readFile($F) eq $s;

    my $C = gbBinaryStandardCompanionFileName($F);                                # Check companion file
    ok -e $C;
    ok gbBinaryStandardCompanionFileContent($C) eq $S;

    ok gbStandardCompanionFileContent($F) eq $S;                                  # Check companion file content

    ok !gbBinaryStandardRename($F);                                               # No rename required to standardize file name

    gbBinaryStandardDelete($F);                                                   # Delete file and its companion file
    ok !-e $F;
    ok !-e $C;

    clearFolder($_, 10) for $d, $D;
   }


This method can be imported via:

  use Dita::GB::Standard qw(gbBinaryStandardCopyFile)


=head2 gbBinaryStandardDelete($)

Delete a file and its L<Companion File> if there is one.

     Parameter  Description
  1  $file      File to delete

B<Example:>


  if (1) {
    my $s = qq(\0abc\1);
    my $S = q(Hello World);
    my $d = temporaryFolder;
    my $D = temporaryFolder;
    clearFolder($_, 10) for $d, $D;

    my $f = gbBinaryStandardCreateFile($d, $s, q(xml), $S);                       # Create file
    ok -e $f;
    ok readFile($f) eq $s;

    my $c = gbBinaryStandardCompanionFileName($f);                                # Check companion file
    ok -e $c;
    ok gbStandardCompanionFileContent($c) eq $S;

    ok gbBinaryStandardCompanionFileContent($f) eq $S;                            # Check companion file content

    my $F = gbBinaryStandardCopyFile($f, $D);                                     # Copy file
    ok -e $F;
    ok readFile($F) eq $s;

    my $C = gbBinaryStandardCompanionFileName($F);                                # Check companion file
    ok -e $C;
    ok gbBinaryStandardCompanionFileContent($C) eq $S;

    ok gbStandardCompanionFileContent($F) eq $S;                                  # Check companion file content

    ok !gbBinaryStandardRename($F);                                               # No rename required to standardize file name

    𝗴𝗯𝗕𝗶𝗻𝗮𝗿𝘆𝗦𝘁𝗮𝗻𝗱𝗮𝗿𝗱𝗗𝗲𝗹𝗲𝘁𝗲($F);                                                   # Delete file and its companion file
    ok !-e $F;
    ok !-e $C;

    clearFolder($_, 10) for $d, $D;
   }


This method can be imported via:

  use Dita::GB::Standard qw(gbBinaryStandardDelete)



=head1 Index


1 L<gbBinaryStandardCompanionFileContent|/gbBinaryStandardCompanionFileContent> - Return the content of the L<Companion File> given a file whose name complies with the binary L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

2 L<gbBinaryStandardCompanionFileName|/gbBinaryStandardCompanionFileName> - Return the name of the companion file given a file whose name complies with the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

3 L<gbBinaryStandardCopyFile|/gbBinaryStandardCopyFile> - Copy a file to the specified B<$target> folder renaming it to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

4 L<gbBinaryStandardCreateFile|/gbBinaryStandardCreateFile> - Create a file in the specified B<$Folder> whose name is the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> name for the specified B<$content> and return the file name,  A L<Companion File> can, optionally, be  created with the specified B<$companionContent>.

5 L<gbBinaryStandardDelete|/gbBinaryStandardDelete> - Delete a file and its L<Companion File> if there is one.

6 L<gbBinaryStandardFileName|/gbBinaryStandardFileName> - Return the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> file name given the content and extension of a proposed file.

7 L<gbBinaryStandardRename|/gbBinaryStandardRename> - Check whether a file needs to be renamed to match the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

8 L<gbStandardCompanionFileContent|/gbStandardCompanionFileContent> - Return the content of the L<Companion File> given a file whose name complies with the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

9 L<gbStandardCompanionFileName|/gbStandardCompanionFileName> - Return the name of the L<Companion File> given a file whose name complies with the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

10 L<gbStandardCopyFile|/gbStandardCopyFile> - Copy a file to the specified B<$target> folder renaming it to the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.

11 L<gbStandardCreateFile|/gbStandardCreateFile> - Create a file in the specified B<$Folder> whose name is the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> name for the specified B<$content> and return the file name,  A L<Companion File> can, optionally, be  created with the specified B<$companionContent>

12 L<gbStandardDelete|/gbStandardDelete> - Delete a file and its companion file if there is one.

13 L<gbStandardFileName|/gbStandardFileName> - Return the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard> file name given the content and extension of a proposed file.

14 L<gbStandardRename|/gbStandardRename> - Check whether a file needs to be renamed to match the L<GB Standard|http://metacpan.org/pod/Dita::GB::Standard>.



=head1 Exports

All of the following methods can be imported via:

  use Dita::GB::Standard qw(:all);

Or individually via:

  use Dita::GB::Standard qw(<method>);



1 L<gbBinaryStandardCompanionFileContent|/gbBinaryStandardCompanionFileContent>

2 L<gbBinaryStandardCompanionFileName|/gbBinaryStandardCompanionFileName>

3 L<gbBinaryStandardCopyFile|/gbBinaryStandardCopyFile>

4 L<gbBinaryStandardCreateFile|/gbBinaryStandardCreateFile>

5 L<gbBinaryStandardDelete|/gbBinaryStandardDelete>

6 L<gbBinaryStandardFileName|/gbBinaryStandardFileName>

7 L<gbBinaryStandardRename|/gbBinaryStandardRename>

8 L<gbStandardCompanionFileContent|/gbStandardCompanionFileContent>

9 L<gbStandardCompanionFileName|/gbStandardCompanionFileName>

10 L<gbStandardCopyFile|/gbStandardCopyFile>

11 L<gbStandardCreateFile|/gbStandardCreateFile>

12 L<gbStandardDelete|/gbStandardDelete>

13 L<gbStandardFileName|/gbStandardFileName>

14 L<gbStandardRename|/gbStandardRename>

=head1 Installation

This module is written in 100% Pure Perl and, thus, it is easy to read,
comprehend, use, modify and install via B<cpan>:

  sudo cpan install Dita::GB::Standard

=head1 Author

L<philiprbrenan@gmail.com|mailto:philiprbrenan@gmail.com>

L<http://www.appaapps.com|http://www.appaapps.com>

=head1 Copyright

Copyright (c) 2016-2019 Philip R Brenan.

This module is free software. It may be used, redistributed and/or modified
under the same terms as Perl itself.

=cut



# Tests and documentation

sub test
 {my $p = __PACKAGE__;
  binmode($_, ":utf8") for *STDOUT, *STDERR;
  return if eval "eof(${p}::DATA)";
  my $s = eval "join('', <${p}::DATA>)";
  $@ and die $@;
  eval $s;
  $@ and die $@;
  1
 }

test unless caller;

1;
# podDocumentation
__DATA__
use Test::More;
use warnings FATAL=>qw(all);
use strict;
use Data::Table::Text qw(:all);

makeDieConfess;

if ($^O !~ m(bsd|linux)i)
 {plan skip_all => 'Not supported';
 }

Test::More->builder->output("/dev/null")                                        # Show only errors during testing
  if ((caller(1))[0]//'Dita::GB::Standard') eq "Dita::GB::Standard";

is_deeply [hex4ToBits(q(0001))],  [0,0,0,0,0,1];
is_deeply [hex4ToBits(q(c001))],  [1,1,0,0,0,1];
is_deeply [hex4ToBits(q(c002))],  [1,1,0,0,0,2];
is_deeply [hex4ToBits(q(d010))],  [1,1,0,1,0,16];
is_deeply [hex4ToBits(q(e010))],  [1,1,1,0,0,16];
is_deeply [hex4ToBits(q(f011))],  [1,1,1,1,0,17];
is_deeply [hex4ToBits(q(8010))],  [1,0,0,0,0,16];
is_deeply [hex4ToBits(q(4011))],  [0,1,0,0,0,17];

ok hexAsWords(q(0000)) eq q(aback);
ok hexAsWords(q(0001)) eq q(abate);
ok hexAsWords(q(1001)) eq q(abaTe);

ok hexAsWords(q(0010)) eq q(adept);
ok hexAsWords(q(0810)) eq q(adepT);
ok hexAsWords(q(1010)) eq q(adePt);
ok hexAsWords(q(2010)) eq q(adEpt);
ok hexAsWords(q(3010)) eq q(adEPt);
ok hexAsWords(q(4010)) eq q(aDept);
ok hexAsWords(q(8010)) eq q(Adept);
ok hexAsWords(q(C010)) eq q(ADept);

ok gbStandardCompanionFileName(q(a/b.c)) eq q(a/b);

if (1) {                                                                        #TgbStandardFileName
  if (useWords)
   {ok gbStandardFileName(<<END, q(dita)) eq q(c_abc_Plume_VApoR_CaPER_eqUAl_qUAIL_saInT_mEdia_Irony.dita);
<concept>
  <title>abc 𝝰𝝱𝝲</title>
  <conbody/>
</concept>
END
   }
  else
   {ok gbStandardFileName(<<END, q(c_abc.dita)) eq q(c_abc_8551cffdb92932637d952e04447783c8.dita);
<concept xtrf="A">
  <title>abc 𝝰𝝱𝝲</title>
  <conbody/>
</concept>
END
   }
 }

ok gbStandardCompanionFileName(q(a/b.c)) eq q(a/b);                             #TgbStandardCompanionFileName

if (1) {                                                                        #TgbStandardCreateFile #TgbStandardCopyFile #TgbStandardDelete #TgbStandardRename
  my $s = q(abc 𝝰𝝱𝝲);
  my $S = q(Hello World);
  my $d = temporaryFolder;
  my $D = temporaryFolder;
  clearFolder($_, 10) for $d, $D;

  my $f = gbStandardCreateFile($d, $s, q(xml), companionContent=>$S);           # Create file
  ok -e $f;
  ok readFile($f) eq $s;

  my $c = gbStandardCompanionFileName($f);                                      # Check companion file
  ok -e $c;
  ok readFile($c) eq $S;

  my $F = gbStandardCopyFile($f, target=>$D);                                   # Copy file
  ok -e $F;
  ok readFile($F) eq $s;

  my $C = gbStandardCompanionFileName($F);                                      # Check companion file
  ok -e $C;
  ok readFile($C) eq $S;

  ok !gbStandardRename($F);                                                     # No rename required to standardize file name

  gbStandardDelete($F);                                                         # Delete file and its companion file
  ok !-e $F;
  ok !-e $C;

  clearFolder($_, 10) for $d, $D;
 }

if (1) {                                                                        #TgbBinaryStandardFileName
  if (useWords)
   {ok gbBinaryStandardFileName(qq(\0abc\1), q(png)) eq q(png_thInk_BUSHy_dRYER_spaCE_KNOwN_lepeR_SeNse_MaJor.png);
   }
  else
   {ok gbBinaryStandardFileName(qq(\0abc\1), q(png)) eq q(png_2786f1147a331ec6ebf60c1ba636a458.png);
   }
 }

ok gbBinaryStandardCompanionFileName(q(a/b.c)) eq q(a/b);                       #TgbBinaryStandardCompanionFileName

if (1) {                                                                        #TgbBinaryStandardCreateFile #TgbBinaryStandardCopyFile #TgbBinaryStandardDelete #TgbBinaryStandardRename #TgbStandardCompanionFileContent  #TgbBinaryStandardCompanionFileContent
  my $s = qq(\0abc\1);
  my $S = q(Hello World);
  my $d = temporaryFolder;
  my $D = temporaryFolder;
  clearFolder($_, 10) for $d, $D;

  my $f = gbBinaryStandardCreateFile($d, $s, q(xml), $S);                       # Create file
  ok -e $f;
  ok readFile($f) eq $s;

  my $c = gbBinaryStandardCompanionFileName($f);                                # Check companion file
  ok -e $c;
  ok gbStandardCompanionFileContent($c) eq $S;

  ok gbBinaryStandardCompanionFileContent($f) eq $S;                            # Check companion file content

  my $F = gbBinaryStandardCopyFile($f, $D);                                     # Copy file
  ok -e $F;
  ok readFile($F) eq $s;

  my $C = gbBinaryStandardCompanionFileName($F);                                # Check companion file
  ok -e $C;
  ok gbBinaryStandardCompanionFileContent($C) eq $S;

  ok gbStandardCompanionFileContent($F) eq $S;                                  # Check companion file content

  ok !gbBinaryStandardRename($F);                                               # No rename required to standardize file name

  gbBinaryStandardDelete($F);                                                   # Delete file and its companion file
  ok !-e $F;
  ok !-e $C;

  clearFolder($_, 10) for $d, $D;
 }

ok &gbStandardFileName(qw(aaa dita g bbb)) eq                                   # Override the G component in an awkward manner designed to discourage such usage
   q(bbb_47bce5c74f589f4867dbd57e9ca9f808.dita);

done_testing;
