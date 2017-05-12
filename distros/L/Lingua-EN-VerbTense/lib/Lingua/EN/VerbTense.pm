###################################
#
# Parse (v3) Parses English verb structures.
# Copyright (C) 2000 Chris Meyer
# chris@mytechs.com
# 1143 5th Street East
# Altoona, WI 54720
# 
# Simple Modal Support Added: July 19, 2000
# Sept 28, Josiah Bryan, jdb@wcoil.com:
#	-	Converted all verb, modal, and state files 
#		to be stored in module file.
#	-	Cleaned up certain parts of the code.
#	-	Added verb().   
#	-	Added simple POD docs
#
# Future:
#	- Josiah: Plans to convert the verb and modal
#			  tables to be loaded from Linga::EN::SimpleDict
#			  database files transport. (SimpleDict is not yet
#			  released - still under development.)
#	- Josiah: Plans to allow the system to 'guess' and save
#			  its guess internally for future useage on verbs
#			  not in its internal databases.
#	
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
###################################

package Lingua::EN::VerbTense;

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
'all' => [qw(verb verb_tense sFormPartInf sInfPartForm sIsModal sIsInfinitive sIsThird sIsPast sIsGerund sIsPart)],
'basic' => [qw(verb verb_tense)],
'tests' => [qw(sFormPartInf sInfPartForm sIsModal sIsInfinitive sIsThird sIsPast sIsGerund sIsPart)]
);
@EXPORT_OK = (
@{$EXPORT_TAGS{'all'}},
@{$EXPORT_TAGS{'tests'}},
@{$EXPORT_TAGS{'basic'}}, 
qw(verb verb_tense sFormPartInf sInfPartForm sIsModal sIsInfinitive sIsThird sIsPast sIsGerund sIsPart));

@EXPORT = qw(verb_tense);

$VERSION = '3.003';

use strict;

my %hModal = ( 
	can		=>	'Ability',
	could	=>	'Subjunctive Ability',
	shall	=>	'Future',
	should	=>	'Necessity',
	will	=>	'Future',
	would	=>	'Subjunctive',
	must	=>	'Requirement',
	may		=>	'Permission',
	might	=>	'Possibility',
	really	=>	'Affirmative',
);

my %hMastVerb;
my %hVerbIdx;

my $DEBUG = 0;

my $Modality;	# Global for discovered modality
my $Tense;		# Global for discovered Tense
my $Inf;		# Global for infinitive of discovered Verb

# fixed vars to make reading the indexs easier
my $INFINITIVE = 0;
my $THIRD = 1;
my $PAST = 2;
my $PART = 3;
my $GERUND = 4;

# Load States Table into hash variables
sub sLoadStates {
	no strict 'refs';
	my $hState;
	my $L;
	my @F;
	my $W;
	
	while ($L = <DATA>)	{
		chomp $L;
		$L =~ s/\s+$//;
		if ($L =~ /^:/) {
			$L =~ s/^://;
			$hState = $L;
			$L = <DATA>;
			chop $L;
			$L =~ s/\s+$//;
			$$hState{state} = $L;
			next;
		}
	
		# Load tests
		if ($L =~ /^Tests/) {
			@F = split(/,/,$L);
			$W = shift @F;
			$$hState{$W} = [@F];	
			my $aTest = $$hState{Tests};
			next;                                  
		}
	
		if ($L =~ /,/) {
			@F = split(/,/,$L);
			$$hState{$F[0]} = $F[1];
		}
	}
}

sub verb {
	my $vInfinitive;
	my @F=@_;
	$vInfinitive = $F[$INFINITIVE];
    $hMastVerb{$vInfinitive}{Infinitive} = $F[$INFINITIVE];
    $hMastVerb{$vInfinitive}{Third} = $F[$THIRD];
    $hMastVerb{$vInfinitive}{Past} = $F[$PAST];
    $hMastVerb{$vInfinitive}{Part} = $F[$PART];
    $hMastVerb{$vInfinitive}{Gerund} = $F[$GERUND];
    $hVerbIdx{$F[$THIRD]}{Third} = $vInfinitive;
    $hVerbIdx{$F[$PAST]}{Past} = $vInfinitive;
    $hVerbIdx{$F[$PART]}{Part} = $vInfinitive;
    $hVerbIdx{$F[$GERUND]}{Gerund} = $vInfinitive;
	$hVerbIdx{$F[$INFINITIVE]}{Infinitive} = $vInfinitive;
}
#
# utility routines for accessing the verb 'tables
#

# usage sFormPart("going","Gerund") returns "go"
# if form of verb '
sub sFormPartInf {
    my $Form = shift (@_);
	my $Part = shift (@_);
	
	return ($hVerbIdx{$Form}->{$Part});
}

# usage sInfPartForm("go","Gerund") returns "going"
sub sInfPartForm {
    my $Inf = shift (@_);
	my $Part = shift (@_);
	
	return ($hMastVerb{$Inf}->{$Part});
}

#
# Test routines listed in the state tables.  If successful, they return
# the name of the thing tested for which in turn, passes control on to the
# next state.
#   
sub sIsModal {
    my $W = shift @_;
	my $M;
	
	print "W = $W in sIsModal\n" if $DEBUG;
	if ($M = $hModal{$W}) {
		$Modality = $M;
		return "Modal";
	}
	print "M = #$M# in sIsModal\n" if $DEBUG;
	return "";
}

sub sIsInfinitive {
    my $W = shift @_;
	my $I;
	
	if (my $I = sFormPartInf($W,"Infinitive")) {
		$Inf = $I;
		return "Infinitive";
	}
	return "";
}

sub sIsThird {
    my $W = shift @_;
	
	if (my $I = sFormPartInf($W,"Third")) {
		$Inf = $I;
		return "Third";
	}
	return "";
}

sub sIsPast {
    my $W = shift @_;
	
	if (my $I = sFormPartInf($W,"Past")) {
		$Inf = $I;
		return "Past";
	}
	return "";
}

sub sIsGerund {
    my $W = shift @_;
	
	if (my $I = sFormPartInf($W,"Gerund")) {
		$Inf = $I;
		return "Gerund";
	}
	return "";
}

sub sIsPart {
    my $W = shift @_;
	if (my $I = sFormPartInf($W,"Part")) {
		$Inf = $I;
		return "Part";
	}
	return "";
}
    
sub verb_tense {    
	no strict 'refs';
    my $self = shift if(substr($_[0],0,4) eq 'AI::');
	my $S = shift @_;
	my $W;
	my @aW;
	my $hStart = "start";
	my $Form;
	my $sTest;
	my $apTest;
	my $Test;
	
	$Modality = "None";
	
	@aW = split(/\s+/,$S);
	foreach $W (@aW) {
		print "state: $hStart\n" if $DEBUG;
		if (exists $$hStart{$W}) {
			$hStart = $$hStart{$W};
			next;
		}
	
		$apTest = $$hStart{Tests};
		foreach $sTest (@$apTest) {
			$Test = &$sTest($W);
			if ($Test ne "") {
				$hStart = $$hStart{$Test};
				last;	
			}
		} 
	}
	
	$Tense = $$hStart{state};
	
	# adjust for event of bare helping verb 'in which case be or have returned
	# at end of tense description
	if ($Tense =~ /\sHave$/) {
		$Inf = "have";
		$Tense =~ s/\s+Have$//;
	}
	if ($Tense =~ /\sBe$/) {
		$Inf = "be";
		$Tense =~ s/\s+Be$//;
	}
	return ($Modality, $Tense, $Inf); 
}

sLoadStates();

no strict 'subs';
verb 'accept','accepts','accepted','accepted','accepting';
verb 'add','adds','added','added','adding';
verb 'admire','admires','admired','admired','admiring';
verb 'admit','admits','admited','admited','admiting';
verb 'advise','advises','advised','advised','advising';
verb 'afford','affords','afforded','afforded','affording';
verb 'agree','agrees','agreed','agreed','agreeing';
verb 'alert','alerts','alerted','alerted','alerting';
verb 'allow','allows','allowed','allowed','allowing';
verb 'amuse','amuses','amused','amused','amusing';
verb 'analyse','analyses','analysed','analysed','analysing';
verb 'announce','announces','announced','announced','announcing';
verb 'annoy','annoys','annoyed','annoyed','annoying';
verb 'answer','answers','answered','answered','answering';
verb 'apologise','apologises','apologised','apologised','apologising';
verb 'appear','appears','appeared','appeared','appearing';
verb 'applaud','applauds','applauded','applauded','applauding';
verb 'appreciate','appreciates','appreciated','appreciated','appreciating';
verb 'approve','approves','approved','approved','approving';
verb 'argue','argues','argueed','argueed','argueing';
verb 'arrange','arranges','arranged','arranged','arranging';
verb 'arrest','arrests','arrested','arrested','arresting';
verb 'arrive','arrives','arrived','arrived','arriving';
verb 'ask','asks','asked','asked','asking';
verb 'attach','attaches','attached','attached','attaching';
verb 'attack','attacks','attacked','attacked','attacking';
verb 'attempt','attempts','attempted','attempted','attempting';
verb 'attend','attends','attended','attended','attending';
verb 'attract','attracts','attracted','attracted','attracting';
verb 'avoid','avoids','avoided','avoided','avoiding';
verb 'back','backs','backed','backed','backing';
verb 'bake','bakes','baked','baked','baking';
verb 'balance','balances','balanced','balanced','balancing';
verb 'ban','bans','banned','banned','banning';
verb 'bang','bangs','banged','banged','banging';
verb 'bare','bares','bared','bared','baring';
verb 'bat','bats','batted','batted','batting';
verb 'bathe','bathes','bathed','bathed','bathing';
verb 'battle','battles','battled','battled','battling';
verb 'be','is','were','been','being';
verb 'beam','beams','beamed','beamed','beaming';
verb 'bear','bears','bore','born','bearing';
verb 'beat','beats','beat','beaten','beating';
verb 'beg','begs','begged','begged','begging';
verb 'behave','behaves','behaved','behaved','behaving';
verb 'belong','belongs','belonged','belonged','belonging';
verb 'bend','bends','bent','bent','bending';
verb 'bid','bids','bade','bidden','bidding';
verb 'bind','binds','bound','bound','binding';
verb 'bite','bites','bit','bitten','biting';
verb 'bleach','bleaches','bleached','bleached','bleaching';
verb 'bleed','bleeds','bled','bled','bleeding';
verb 'bless','blesses','blessed','blessed','blessing';
verb 'blind','blinds','blinded','blinded','blinding';
verb 'blink','blinks','blinked','blinked','blinking';
verb 'blot','blots','blotted','blotted','blotting';
verb 'blow','blows','blew','blown','blowwing';
verb 'blush','blushes','blushed','blushed','blushing';
verb 'boast','boasts','boasted','boasted','boasting';
verb 'boil','boils','boiled','boiled','boiling';
verb 'bolt','bolts','bolted','bolted','bolting';
verb 'bomb','bombs','bombed','bombed','bombing';
verb 'book','books','booked','booked','booking';
verb 'bore','bores','bored','bored','boring';
verb 'borrow','borrows','borrowed','borrowed','borrowing';
verb 'bounce','bounces','bounced','bounced','bouncing';
verb 'bow','bows','bowwed','bowwed','bowwing';
verb 'box','boxes','boxxed','boxxed','boxxing';
verb 'brake','brakes','braked','braked','braking';
verb 'branch','branches','branched','branched','branching';
verb 'break','breaks','broke','broken','breaking';
verb 'breathe','breathes','breathed','breathed','breathing';
verb 'breed','breeds','bred','bred','breeding';
verb 'bring','brings','brought','brought','bringing';
verb 'bruise','bruises','bruised','bruised','bruising';
verb 'brush','brushes','brushed','brushed','brushing';
verb 'bubble','bubbles','bubbled','bubbled','bubbling';
verb 'build','builds','built','built','building';
verb 'bump','bumps','bumped','bumped','bumping';
verb 'burn','burns','burned','burned','burning';
verb 'bury','buries','buried','buried','burying';
verb 'buy','buys','bought','bought','buying';
verb 'buzz','buzzes','buzzed','buzzed','buzzing';
verb 'calculate','calculates','calculated','calculated','calculating';
verb 'call','calls','called','called','calling';
verb 'camp','camps','camped','camped','camping';
verb 'care','cares','cared','cared','caring';
verb 'carry','carries','carried','carried','carrying';
verb 'carve','carves','carved','carved','carving';
verb 'catch','catches','caught','caught','catching';
verb 'cause','causes','caused','caused','causing';
verb 'challenge','challenges','challenged','challenged','challenging';
verb 'change','changes','changed','changed','changing';
verb 'charge','charges','charged','charged','charging';
verb 'chase','chases','chased','chased','chasing';
verb 'cheat','cheats','cheated','cheated','cheating';
verb 'check','checks','checked','checked','checking';
verb 'cheer','cheers','cheered','cheered','cheering';
verb 'chew','chews','chewwed','chewwed','chewwing';
verb 'choke','chokes','choked','choked','choking';
verb 'chop','chops','chopped','chopped','chopping';
verb 'claim','claims','claimed','claimed','claiming';
verb 'clap','claps','clapped','clapped','clapping';
verb 'clean','cleans','cleaned','cleaned','cleaning';
verb 'clear','clears','cleared','cleared','clearing';
verb 'clip','clips','clipped','clipped','clipping';
verb 'close','closes','closed','closed','closing';
verb 'coach','coaches','coached','coached','coaching';
verb 'coil','coils','coiled','coiled','coiling';
verb 'collect','collects','collected','collected','collecting';
verb 'colour','colours','coloured','coloured','colouring';
verb 'comb','combs','combed','combed','combing';
verb 'come','comes','came','come','coming';
verb 'command','commands','commanded','commanded','commanding';
verb 'communicate','communicates','communicated','communicated','communicating';
verb 'compare','compares','compared','compared','comparing';
verb 'compete','competes','competed','competed','competing';
verb 'complain','complains','complained','complained','complaining';
verb 'complete','completes','completed','completed','completing';
verb 'concentrate','concentrates','concentrated','concentrated','concentrating';
verb 'concern','concerns','concerned','concerned','concerning';
verb 'confess','confesses','confessed','confessed','confessing';
verb 'confuse','confuses','confused','confused','confusing';
verb 'connect','connects','connected','connected','connecting';
verb 'consider','considers','considered','considered','considering';
verb 'consist','consists','consisted','consisted','consisting';
verb 'contain','contains','contained','contained','containing';
verb 'continue','continues','continueed','continueed','continueing';
verb 'copy','copies','copied','copied','copying';
verb 'correct','corrects','corrected','corrected','correcting';
verb 'cough','coughs','coughed','coughed','coughing';
verb 'count','counts','counted','counted','counting';
verb 'cover','covers','covered','covered','covering';
verb 'crack','cracks','cracked','cracked','cracking';
verb 'crash','crashes','crashed','crashed','crashing';
verb 'crawl','crawls','crawled','crawled','crawling';
verb 'create','creates','created','created','creating';
verb 'creep','creeps','crept','crept','creeping';
verb 'cross','crosses','crossed','crossed','crossing';
verb 'crush','crushes','crushed','crushed','crushing';
verb 'cry','cries','cried','cried','crying';
verb 'cure','cures','cured','cured','curing';
verb 'curl','curls','curled','curled','curling';
verb 'curve','curves','curved','curved','curving';
verb 'cut','cuts','cut','cut','cutting';
verb 'cycle','cycles','cycled','cycled','cycling';
verb 'dam','dams','dammed','dammed','damming';
verb 'damage','damages','damaged','damaged','damaging';
verb 'dance','dances','danced','danced','dancing';
verb 'dare','dares','dared','dared','daring';
verb 'deal','deals','dealt','dealt','dealing';
verb 'decay','decays','decayed','decayed','decaying';
verb 'deceive','deceives','deceived','deceived','deceiving';
verb 'decide','decides','decided','decided','deciding';
verb 'decorate','decorates','decorated','decorated','decorating';
verb 'delay','delays','delayed','delayed','delaying';
verb 'delight','delights','delighted','delighted','delighting';
verb 'deliver','delivers','delivered','delivered','delivering';
verb 'depend','depends','depended','depended','depending';
verb 'describe','describes','described','described','describing';
verb 'desert','deserts','deserted','deserted','deserting';
verb 'deserve','deserves','deserved','deserved','deserving';
verb 'desire','desires','desired','desired','desiring';
verb 'destroy','destroys','destroyed','destroyed','destroying';
verb 'detect','detects','detected','detected','detecting';
verb 'develop','develops','developed','developed','developing';
verb 'dig','digs','dug','dug','digging';
verb 'disagree','disagrees','disagreed','disagreed','disagreeing';
verb 'disappear','disappears','disappeared','disappeared','disappearing';
verb 'disapprove','disapproves','disapproved','disapproved','disapproving';
verb 'disarm','disarms','disarmed','disarmed','disarming';
verb 'discover','discovers','discovered','discovered','discovering';
verb 'dislike','dislikes','disliked','disliked','disliking';
verb 'dive','dives','dove','dived','diving';
verb 'divide','divides','divided','divided','dividing';
verb 'do','does','did','done','doing';
verb 'double','doubles','doubled','doubled','doubling';
verb 'doubt','doubts','doubted','doubted','doubting';
verb 'drag','drags','dragged','dragged','dragging';
verb 'drain','drains','drained','drained','draining';
verb 'draw','draws','drew','drawn','drawwing';
verb 'dream','dreams','dreamed','dreamed','dreaming';
verb 'dress','dresses','dressed','dressed','dressing';
verb 'dribble','dribbles','dribbled','dribbled','dribbling';
verb 'drink','drinks','drank','drunk','drinking';
verb 'drip','drips','dripped','dripped','dripping';
verb 'drive','drives','drove','driven','driving';
verb 'drop','drops','dropped','dropped','dropping';
verb 'drown','drowns','drowned','drowned','drowning';
verb 'drum','drums','drummed','drummed','drumming';
verb 'dry','dries','dried','dried','drying';
verb 'dust','dusts','dusted','dusted','dusting';
verb 'dwell','dwells','dwelt','dwelt','dwelling';
verb 'earn','earns','earned','earned','earning';
verb 'eat','eats','ate','eaten','eating';
verb 'educate','educates','educated','educated','educating';
verb 'embarrass','embarrasses','embarrassed','embarrassed','embarrassing';
verb 'employ','employs','employed','employed','employing';
verb 'empty','empties','emptied','emptied','emptying';
verb 'encourage','encourages','encouraged','encouraged','encouraging';
verb 'end','ends','ended','ended','ending';
verb 'enjoy','enjoys','enjoyed','enjoyed','enjoying';
verb 'enter','enters','entered','entered','entering';
verb 'entertain','entertains','entertained','entertained','entertaining';
verb 'escape','escapes','escaped','escaped','escaping';
verb 'examine','examines','examined','examined','examining';
verb 'excite','excites','excited','excited','exciting';
verb 'excuse','excuses','excused','excused','excusing';
verb 'exercise','exercises','exercised','exercised','exercising';
verb 'exist','exists','existed','existed','existing';
verb 'expand','expands','expanded','expanded','expanding';
verb 'expect','expects','expected','expected','expecting';
verb 'explain','explains','explained','explained','explaining';
verb 'explode','explodes','exploded','exploded','exploding';
verb 'extend','extends','extended','extended','extending';
verb 'face','faces','faced','faced','facing';
verb 'fade','fades','faded','faded','fading';
verb 'fail','fails','failed','failed','failing';
verb 'fall','falls','fell','fallen','falling';
verb 'fancy','fancies','fancied','fancied','fancying';
verb 'fart','farts','farted','farted','farting';
verb 'fasten','fastens','fastened','fastened','fastening';
verb 'fax','faxes','faxxed','faxxed','faxxing';
verb 'fear','fears','feared','feared','fearing';
verb 'feed','feeds','fed','fed','feeding';
verb 'feel','feels','felt','felt','feeling';
verb 'fence','fences','fenced','fenced','fencing';
verb 'fetch','fetches','fetched','fetched','fetching';
verb 'fight','fights','fought','fought','fighting';
verb 'file','files','filed','filed','filing';
verb 'fill','fills','filled','filled','filling';
verb 'film','films','filmed','filmed','filming';
verb 'find','finds','found','found','finding';
verb 'fire','fires','fired','fired','firing';
verb 'fit','fits','fitted','fitted','fitting';
verb 'fix','fixes','fixxed','fixxed','fixxing';
verb 'flap','flaps','flapped','flapped','flapping';
verb 'flash','flashes','flashed','flashed','flashing';
verb 'flee','flees','fled','fled','fleeing';
verb 'float','floats','floated','floated','floating';
verb 'flood','floods','flooded','flooded','flooding';
verb 'flow','flows','flowwed','flowwed','flowwing';
verb 'flower','flowers','flowered','flowered','flowering';
verb 'fly','flies','flew','flown','flying';
verb 'fold','folds','folded','folded','folding';
verb 'follow','follows','followed','followed','following';
verb 'fool','fools','fooled','fooled','fooling';
verb 'force','forces','forced','forced','forcing';
verb 'form','forms','formed','formed','forming';
verb 'forsake','forsakes','forsook','forsaken','forsaking';
verb 'found','founds','founded','founded','founding';
verb 'frame','frames','framed','framed','framing';
verb 'freeze','freezes','froze','frozen','freezing';
verb 'frighten','frightens','frightened','frightened','frightening';
verb 'fry','fries','fried','fried','frying';
verb 'fuck','fucks','fucked','fucked','fucking';
verb 'gather','gathers','gathered','gathered','gathering';
verb 'gaze','gazes','gazed','gazed','gazing';
verb 'get','gets','got','gotten','getting';
verb 'glow','glows','glowwed','glowwed','glowwing';
verb 'glue','glues','glueed','glueed','glueing';
verb 'go','goes','went','gone','going';
verb 'grab','grabs','grabbed','grabbed','grabbing';
verb 'grate','grates','grated','grated','grating';
verb 'grease','greases','greased','greased','greasing';
verb 'greet','greets','greeted','greeted','greeting';
verb 'grin','grins','grinned','grinned','grinning';
verb 'grind','grinds','ground','ground','grinding';
verb 'grip','grips','gripped','gripped','gripping';
verb 'groan','groans','groaned','groaned','groaning';
verb 'grow','grows','grew','grown','growwing';
verb 'guarantee','guarantees','guaranteed','guaranteed','guaranteeing';
verb 'guard','guards','guarded','guarded','guarding';
verb 'guess','guesses','guessed','guessed','guessing';
verb 'guide','guides','guided','guided','guiding';
verb 'hammer','hammers','hammered','hammered','hammering';
verb 'hand','hands','handed','handed','handing';
verb 'handle','handles','handled','handled','handling';
verb 'hang','hangs','hanged','hanged','hanging';
verb 'happen','happens','happened','happened','happening';
verb 'harass','harasses','harassed','harassed','harassing';
verb 'harm','harms','harmed','harmed','harming';
verb 'hate','hates','hated','hated','hating';
verb 'haunt','haunts','haunted','haunted','haunting';
verb 'have','haves','had','had','having';
verb 'head','heads','headed','headed','heading';
verb 'heal','heals','healed','healed','healing';
verb 'heap','heaps','heaped','heaped','heaping';
verb 'hear','hears','heard','heard','hearing';
verb 'heat','heats','heated','heated','heating';
verb 'help','helps','helped','helped','helping';
verb 'hew','hews','hewed','hewn','hewwing';
verb 'hide','hides','hid','hid','hiding';
verb 'hit','hits','hit','hit','hitting';
verb 'hold','holds','held','held','holding';
verb 'hook','hooks','hooked','hooked','hooking';
verb 'hop','hops','hopped','hopped','hopping';
verb 'hope','hopes','hoped','hoped','hoping';
verb 'hover','hovers','hovered','hovered','hovering';
verb 'hug','hugs','hugged','hugged','hugging';
verb 'hum','hums','hummed','hummed','humming';
verb 'hunt','hunts','hunted','hunted','hunting';
verb 'hurry','hurries','hurried','hurried','hurrying';
verb 'hurt','hurts','hurt','hurt','hurting';
verb 'identify','identifies','identified','identified','identifying';
verb 'ignore','ignores','ignored','ignored','ignoring';
verb 'imagine','imagines','imagined','imagined','imagining';
verb 'impress','impresses','impressed','impressed','impressing';
verb 'improve','improves','improved','improved','improving';
verb 'include','includes','included','included','including';
verb 'increase','increases','increased','increased','increasing';
verb 'influence','influences','influenced','influenced','influencing';
verb 'inform','informs','informed','informed','informing';
verb 'inject','injects','injected','injected','injecting';
verb 'injure','injures','injured','injured','injuring';
verb 'instruct','instructs','instructed','instructed','instructing';
verb 'intend','intends','intended','intended','intending';
verb 'interest','interests','interested','interested','interesting';
verb 'interfere','interferes','interfered','interfered','interfering';
verb 'interrupt','interrupts','interrupted','interrupted','interrupting';
verb 'introduce','introduces','introduced','introduced','introducing';
verb 'invent','invents','invented','invented','inventing';
verb 'invite','invites','invited','invited','inviting';
verb 'irritate','irritates','irritated','irritated','irritating';
verb 'itch','itches','itched','itched','itching';
verb 'jail','jails','jailed','jailed','jailing';
verb 'jam','jams','jammed','jammed','jamming';
verb 'jog','jogs','jogged','jogged','jogging';
verb 'join','joins','joined','joined','joining';
verb 'joke','jokes','joked','joked','joking';
verb 'judge','judges','judged','judged','judging';
verb 'juggle','juggles','juggled','juggled','juggling';
verb 'jump','jumps','jumped','jumped','jumping';
verb 'keep','keeps','kept','kept','keeping';
verb 'kick','kicks','kicked','kicked','kicking';
verb 'kill','kills','killed','killed','killing';
verb 'kiss','kisses','kissed','kissed','kissing';
verb 'kneel','kneels','kneeled','kneeled','kneeling';
verb 'knit','knits','knitted','knitted','knitting';
verb 'knock','knocks','knocked','knocked','knocking';
verb 'knot','knots','knotted','knotted','knotting';
verb 'know','knows','knew','known','knowwing';
verb 'label','labels','labeled','labeled','labeling';
verb 'land','lands','landed','landed','landing';
verb 'last','lasts','lasted','lasted','lasting';
verb 'laugh','laughs','laughed','laughed','laughing';
verb 'launch','launches','launched','launched','launching';
verb 'lead','leads','lead','lead','leading';
verb 'leap','leaps','leaped','leaped','leaping';
verb 'learn','learns','learned','learned','learning';
verb 'leave','leaves','left','left','leaving';
verb 'lend','lends','lent','lent','lending';
verb 'let','lets','let','let','letting';
verb 'level','levels','leveled','leveled','leveling';
verb 'license','licenses','licensed','licensed','licensing';
verb 'lick','licks','licked','licked','licking';
verb 'lie','lies','lied','lied','lying';
verb 'light','lights','lit','lit','lighting';
verb 'lighten','lightens','lightened','lightened','lightening';
verb 'like','likes','liked','liked','liking';
verb 'list','lists','listed','listed','listing';
verb 'listen','listens','listened','listened','listening';
verb 'live','lives','lived','lived','living';
verb 'load','loads','loaded','loaded','loading';
verb 'lock','locks','locked','locked','locking';
verb 'long','longs','longed','longed','longing';
verb 'look','looks','looked','looked','looking';
verb 'love','loves','loved','loved','loving';
verb 'make','makes','made','made','making';
verb 'man','mans','manned','manned','manning';
verb 'manage','manages','managed','managed','managing';
verb 'march','marches','marched','marched','marching';
verb 'mark','marks','marked','marked','marking';
verb 'marry','marries','married','married','marrying';
verb 'match','matches','matched','matched','matching';
verb 'mate','mates','mated','mated','mating';
verb 'matter','matters','mattered','mattered','mattering';
verb 'mean','means','meant','meant','meaning';
verb 'measure','measures','measured','measured','measuring';
verb 'meddle','meddles','meddled','meddled','meddling';
verb 'meet','meets','met','met','meeting';
verb 'melt','melts','melted','melted','melting';
verb 'memorise','memorises','memorised','memorised','memorising';
verb 'mend','mends','mended','mended','mending';
verb 'mess up','mess ups','mess uped','mess uped','mess uping';
verb 'milk','milks','milked','milked','milking';
verb 'mine','mines','mined','mined','mining';
verb 'miss','misses','missed','missed','missing';
verb 'mix','mixes','mixxed','mixxed','mixxing';
verb 'moan','moans','moaned','moaned','moaning';
verb 'moor','moors','moored','moored','mooring';
verb 'mourn','mourns','mourned','mourned','mourning';
verb 'move','moves','moved','moved','moving';
verb 'muddle','muddles','muddled','muddled','muddling';
verb 'mug','mugs','mugged','mugged','mugging';
verb 'multiply','multiplies','multiplied','multiplied','multiplying';
verb 'murder','murders','murdered','murdered','murdering';
verb 'nail','nails','nailed','nailed','nailing';
verb 'name','names','named','named','naming';
verb 'need','needs','needed','needed','needing';
verb 'nest','nests','nested','nested','nesting';
verb 'nod','nods','nodded','nodded','nodding';
verb 'note','notes','noted','noted','noting';
verb 'notice','notices','noticed','noticed','noticing';
verb 'number','numbers','numbered','numbered','numbering';
verb 'obey','obeys','obeyed','obeyed','obeying';
verb 'object','objects','objected','objected','objecting';
verb 'observe','observes','observed','observed','observing';
verb 'obtain','obtains','obtained','obtained','obtaining';
verb 'occur','occurs','occured','occured','occuring';
verb 'offend','offends','offended','offended','offending';
verb 'offer','offers','offered','offered','offering';
verb 'open','opens','opened','opened','opening';
verb 'order','orders','ordered','ordered','ordering';
verb 'ought','oughts','ought','ought','oughting';
verb 'overflow','overflows','overflowed','overflowed','overflowing';
verb 'owe','owes','owed','owed','owing';
verb 'own','owns','owned','owned','owning';
verb 'pack','packs','packed','packed','packing';
verb 'paddle','paddles','paddled','paddled','paddling';
verb 'paint','paints','painted','painted','painting';
verb 'park','parks','parked','parked','parking';
verb 'part','parts','parted','parted','parting';
verb 'pass','passes','passed','passed','passing';
verb 'paste','pastes','pasted','pasted','pasting';
verb 'pat','pats','patted','patted','patting';
verb 'pause','pauses','paused','paused','pausing';
verb 'peck','pecks','pecked','pecked','pecking';
verb 'pedal','pedals','pedaled','pedaled','pedaling';
verb 'peel','peels','peeled','peeled','peeling';
verb 'peep','peeps','peeped','peeped','peeping';
verb 'perform','performs','performed','performed','performing';
verb 'permit','permits','permited','permited','permiting';
verb 'phone','phones','phoned','phoned','phoning';
verb 'pick','picks','picked','picked','picking';
verb 'pinch','pinches','pinched','pinched','pinching';
verb 'pine','pines','pined','pined','pining';
verb 'place','places','placed','placed','placing';
verb 'plan','plans','planned','planned','planning';
verb 'plant','plants','planted','planted','planting';
verb 'play','plays','played','played','playing';
verb 'plead','pleads','pleaded','pleaded','pleading';
verb 'please','pleases','pleased','pleased','pleasing';
verb 'plug','plugs','plugged','plugged','plugging';
verb 'point','points','pointed','pointed','pointing';
verb 'poke','pokes','poked','poked','poking';
verb 'polish','polishes','polished','polished','polishing';
verb 'pop','pops','popped','popped','popping';
verb 'possess','possesses','possessed','possessed','possessing';
verb 'post','posts','posted','posted','posting';
verb 'pour','pours','poured','poured','pouring';
verb 'practise','practises','practised','practised','practising';
verb 'pray','prays','prayed','prayed','praying';
verb 'preach','preaches','preached','preached','preaching';
verb 'precede','precedes','preceded','preceded','preceding';
verb 'prefer','prefers','prefered','prefered','prefering';
verb 'prepare','prepares','prepared','prepared','preparing';
verb 'present','presents','presented','presented','presenting';
verb 'preserve','preserves','preserved','preserved','preserving';
verb 'press','presses','pressed','pressed','pressing';
verb 'pretend','pretends','pretended','pretended','pretending';
verb 'prevent','prevents','prevented','prevented','preventing';
verb 'prick','pricks','pricked','pricked','pricking';
verb 'print','prints','printed','printed','printing';
verb 'produce','produces','produced','produced','producing';
verb 'program','programs','programed','programed','programing';
verb 'promise','promises','promised','promised','promising';
verb 'protect','protects','protected','protected','protecting';
verb 'prove','proves','proved','proven','proving';
verb 'provide','provides','provided','provided','providing';
verb 'pull','pulls','pulled','pulled','pulling';
verb 'pump','pumps','pumped','pumped','pumping';
verb 'punch','punches','punched','punched','punching';
verb 'puncture','punctures','punctured','punctured','puncturing';
verb 'punish','punishes','punished','punished','punishing';
verb 'push','pushes','pushed','pushed','pushing';
verb 'put','puts','put','put','putting';
verb 'question','questions','questioned','questioned','questioning';
verb 'queue','queues','queueed','queueed','queueing';
verb 'race','races','raced','raced','racing';
verb 'radiate','radiates','radiated','radiated','radiating';
verb 'rain','rains','rained','rained','raining';
verb 'raise','raises','raised','raised','raising';
verb 'reach','reaches','reached','reached','reaching';
verb 'read','reads','read','read','reading';
verb 'realise','realises','realised','realised','realising';
verb 'receive','receives','received','received','receiving';
verb 'recognise','recognises','recognised','recognised','recognising';
verb 'record','records','recorded','recorded','recording';
verb 'reduce','reduces','reduced','reduced','reducing';
verb 'reflect','reflects','reflected','reflected','reflecting';
verb 'refuse','refuses','refused','refused','refusing';
verb 'regret','regrets','regreted','regreted','regreting';
verb 'reign','reigns','reigned','reigned','reigning';
verb 'reject','rejects','rejected','rejected','rejecting';
verb 'rejoice','rejoices','rejoiced','rejoiced','rejoicing';
verb 'relax','relaxes','relaxed','relaxed','relaxing';
verb 'release','releases','released','released','releasing';
verb 'rely','relies','relied','relied','relying';
verb 'remain','remains','remained','remained','remaining';
verb 'remember','remembers','remembered','remembered','remembering';
verb 'remind','reminds','reminded','reminded','reminding';
verb 'remove','removes','removed','removed','removing';
verb 'repair','repairs','repaired','repaired','repairing';
verb 'repeat','repeats','repeated','repeated','repeating';
verb 'replace','replaces','replaced','replaced','replacing';
verb 'reply','replies','replied','replied','replying';
verb 'report','reports','reported','reported','reporting';
verb 'reproduce','reproduces','reproduced','reproduced','reproducing';
verb 'request','requests','requested','requested','requesting';
verb 'rescue','rescues','rescueed','rescueed','rescueing';
verb 'retire','retires','retired','retired','retiring';
verb 'return','returns','returned','returned','returning';
verb 'rhyme','rhymes','rhymed','rhymed','rhyming';
verb 'ride','rides','rode','ridden','riding';
verb 'ring','rings','rang','rung','ringing';
verb 'rinse','rinses','rinsed','rinsed','rinsing';
verb 'rise','rises','rose','risen','rising';
verb 'risk','risks','risked','risked','risking';
verb 'rob','robs','robbed','robbed','robbing';
verb 'rock','rocks','rocked','rocked','rocking';
verb 'roll','rolls','rolled','rolled','rolling';
verb 'rot','rots','rotted','rotted','rotting';
verb 'rub','rubs','rubbed','rubbed','rubbing';
verb 'ruin','ruins','ruined','ruined','ruining';
verb 'rule','rules','ruled','ruled','ruling';
verb 'run','runs','ran','run','running';
verb 'rush','rushes','rushed','rushed','rushing';
verb 'sack','sacks','sacked','sacked','sacking';
verb 'sail','sails','sailed','sailed','sailing';
verb 'satisfy','satisfies','satisfied','satisfied','satisfying';
verb 'save','saves','saved','saved','saving';
verb 'saw','saws','sawwed','sawwed','sawwing';
verb 'say','says','said','said','saying';
verb 'scare','scares','scared','scared','scaring';
verb 'scatter','scatters','scattered','scattered','scattering';
verb 'scold','scolds','scolded','scolded','scolding';
verb 'scorch','scorches','scorched','scorched','scorching';
verb 'scrape','scrapes','scraped','scraped','scraping';
verb 'scratch','scratches','scratched','scratched','scratching';
verb 'scream','screams','screamed','screamed','screaming';
verb 'screw','screws','screwwed','screwwed','screwwing';
verb 'scribble','scribbles','scribbled','scribbled','scribbling';
verb 'scrub','scrubs','scrubbed','scrubbed','scrubbing';
verb 'seal','seals','sealed','sealed','sealing';
verb 'search','searches','searched','searched','searching';
verb 'see','sees','saw','seen','seeing';
verb 'seek','seeks','sought','sought','seeking';
verb 'sell','sells','sold','sold','selling';
verb 'send','sends','sent','sent','sending';
verb 'separate','separates','separated','separated','separating';
verb 'serve','serves','served','served','serving';
verb 'settle','settles','settled','settled','settling';
verb 'sew','sews','sewed','sewn','sewwing';
verb 'shade','shades','shaded','shaded','shading';
verb 'shake','shakes','shook','shaken','shaking';
verb 'share','shares','shared','shared','sharing';
verb 'shave','shaves','shaved','shaved','shaving';
verb 'shear','shears','sheared','shorn','shearing';
verb 'shelter','shelters','sheltered','sheltered','sheltering';
verb 'shine','shines','shined','shined','shining';
verb 'shit','shits','shat','shat','shitting';
verb 'shiver','shivers','shivered','shivered','shivering';
verb 'shock','shocks','shocked','shocked','shocking';
verb 'shoot','shoots','shot','shot','shooting';
verb 'shop','shops','shopped','shopped','shopping';
verb 'show','shows','showed','shown','showwing';
verb 'shrink','shrinks','shrank','shrunk','shrinking';
verb 'shrug','shrugs','shrugged','shrugged','shrugging';
verb 'shut','shuts','shut','shut','shutting';
verb 'sigh','sighs','sighed','sighed','sighing';
verb 'sign','signs','signed','signed','signing';
verb 'signal','signals','signaled','signaled','signaling';
verb 'sin','sins','sinned','sinned','sinning';
verb 'sing','sings','sang','sung','singing';
verb 'sink','sinks','sank','sunk','sinking';
verb 'sip','sips','sipped','sipped','sipping';
verb 'sit','sits','sat','sat','sitting';
verb 'ski','skis','skied','skied','skiing';
verb 'skip','skips','skipped','skipped','skipping';
verb 'slap','slaps','slapped','slapped','slapping';
verb 'slay','slays','slew','slain','slaying';
verb 'sleep','sleeps','slept','slept','sleeping';
verb 'slide','slides','slid','slid','sliding';
verb 'slip','slips','slipped','slipped','slipping';
verb 'slow','slows','slowed','slowed','slowing';
verb 'smash','smashes','smashed','smashed','smashing';
verb 'smell','smells','smelled','smelled','smelling';
verb 'smile','smiles','smiled','smiled','smiling';
verb 'smoke','smokes','smoked','smoked','smoking';
verb 'snatch','snatches','snatched','snatched','snatching';
verb 'sneeze','sneezes','sneezed','sneezed','sneezing';
verb 'sniff','sniffs','sniffed','sniffed','sniffing';
verb 'snore','snores','snored','snored','snoring';
verb 'snow','snows','snowed','snowed','snowing';
verb 'soak','soaks','soaked','soaked','soaking';
verb 'soothe','soothes','soothed','soothed','soothing';
verb 'sound','sounds','sounded','sounded','sounding';
verb 'spare','spares','spared','spared','sparing';
verb 'spark','sparks','sparked','sparked','sparking';
verb 'sparkle','sparkles','sparkled','sparkled','sparkling';
verb 'speak','speaks','spoke','spoken','speaking';
verb 'spell','spells','spelled','spelled','spelling';
verb 'spend','spends','spent','spent','spending';
verb 'spill','spills','spilled','spilled','spilling';
verb 'spin','spins','spun','spun','spinning';
verb 'spit','spits','spat','spat','spitting';
verb 'spoil','spoils','spoiled','spoiled','spoiling';
verb 'spot','spots','spotted','spotted','spotting';
verb 'spray','sprays','sprayed','sprayed','spraying';
verb 'sprout','sprouts','sprouted','sprouted','sprouting';
verb 'squash','squashes','squashed','squashed','squashing';
verb 'squeak','squeaks','squeaked','squeaked','squeaking';
verb 'squeal','squeals','squealed','squealed','squealing';
verb 'squeeze','squeezes','squeezed','squeezed','squeezing';
verb 'stain','stains','stained','stained','staining';
verb 'stamp','stamps','stamped','stamped','stamping';
verb 'stand','stands','stood','stood','standing';
verb 'stare','stares','stared','stared','staring';
verb 'start','starts','started','started','starting';
verb 'stay','stays','stayed','stayed','staying';
verb 'steer','steers','steered','steered','steering';
verb 'step','steps','stepped','stepped','stepping';
verb 'stir','stirs','stirred','stirred','stirring';
verb 'stitch','stitches','stitched','stitched','stitching';
verb 'stop','stops','stopped','stopped','stopping';
verb 'store','stores','stored','stored','storing';
verb 'strap','straps','strapped','strapped','strapping';
verb 'strengthen','strengthens','strengthened','strengthened','strengthening';
verb 'stretch','stretches','stretched','stretched','stretching';
verb 'strip','strips','stripped','stripped','stripping';
verb 'stroke','strokes','stroked','stroked','stroking';
verb 'stuff','stuffs','stuffed','stuffed','stuffing';
verb 'subtract','subtracts','subtracted','subtracted','subtracting';
verb 'succeed','succeeds','succeeded','succeeded','succeeding';
verb 'suck','sucks','sucked','sucked','sucking';
verb 'suffer','suffers','suffered','suffered','suffering';
verb 'suggest','suggests','suggested','suggested','suggesting';
verb 'suit','suits','suited','suited','suiting';
verb 'supply','supplies','supplied','supplied','supplying';
verb 'support','supports','supported','supported','supporting';
verb 'suppose','supposes','supposed','supposed','supposing';
verb 'surprise','surprises','surprised','surprised','surprising';
verb 'surround','surrounds','surrounded','surrounded','surrounding';
verb 'suspect','suspects','suspected','suspected','suspecting';
verb 'suspend','suspends','suspended','suspended','suspending';
verb 'swell','swells','swelled','swollen','swelling';
verb 'swim','swims','swam','swum','swimming';
verb 'switch','switches','switched','switched','switching';
verb 'take','takes','took','taken','taking';
verb 'talk','talks','talked','talked','talking';
verb 'tame','tames','tamed','tamed','taming';
verb 'tap','taps','tapped','tapped','tapping';
verb 'taste','tastes','tasted','tasted','tasting';
verb 'teach','teaches','taught','taught','teaching';
verb 'tear','tears','tore','torn','tearing';
verb 'tease','teases','teased','teased','teasing';
verb 'telephone','telephones','telephoned','telephoned','telephoning';
verb 'tell','tells','told','told','telling';
verb 'tempt','tempts','tempted','tempted','tempting';
verb 'terrify','terrifies','terrified','terrified','terrifying';
verb 'test','tests','tested','tested','testing';
verb 'thank','thanks','thanked','thanked','thanking';
verb 'thaw','thaws','thawwed','thawwed','thawwing';
verb 'think','thinks','thought','thought','thinking';
verb 'thrive','thrives','throve','thriven','thriving';
verb 'throw','throws','threw','thrown','throwwing';
verb 'tick','ticks','ticked','ticked','ticking';
verb 'tickle','tickles','tickled','tickled','tickling';
verb 'tie','ties','tied','tied','tying';
verb 'time','times','timed','timed','timing';
verb 'tip','tips','tipped','tipped','tipping';
verb 'tire','tires','tired','tired','tiring';
verb 'touch','touches','touched','touched','touching';
verb 'tour','tours','toured','toured','touring';
verb 'tow','tows','towed','towed','towing';
verb 'trace','traces','traced','traced','tracing';
verb 'trade','trades','traded','traded','trading';
verb 'train','trains','trained','trained','training';
verb 'transport','transports','transported','transported','transporting';
verb 'trap','traps','trapped','trapped','trapping';
verb 'travel','travels','traveled','traveled','traveling';
verb 'treat','treats','treated','treated','treating';
verb 'tremble','trembles','trembled','trembled','trembling';
verb 'trick','tricks','tricked','tricked','tricking';
verb 'trip','trips','tripped','tripped','tripping';
verb 'trot','trots','trotted','trotted','trotting';
verb 'trouble','troubles','troubled','troubled','troubling';
verb 'trust','trusts','trusted','trusted','trusting';
verb 'try','tries','tried','tried','trying';
verb 'tug','tugs','tugged','tugged','tugging';
verb 'tumble','tumbles','tumbled','tumbled','tumbling';
verb 'turn','turns','turned','turned','turning';
verb 'twist','twists','twisted','twisted','twisting';
verb 'type','types','typed','typed','typing';
verb 'undress','undresses','undressed','undressed','undressing';
verb 'unfasten','unfastens','unfastened','unfastened','unfastening';
verb 'unite','unites','united','united','uniting';
verb 'unlock','unlocks','unlocked','unlocked','unlocking';
verb 'unpack','unpacks','unpacked','unpacked','unpacking';
verb 'untidy','untidies','untidied','untidied','untidying';
verb 'use','uses','used','used','using';
verb 'vanish','vanishes','vanished','vanished','vanishing';
verb 'visit','visits','visited','visited','visiting';
verb 'wail','wails','wailed','wailed','wailing';
verb 'wait','waits','waited','waited','waiting';
verb 'walk','walks','walked','walked','walking';
verb 'wander','wanders','wandered','wandered','wandering';
verb 'want','wants','wanted','wanted','wanting';
verb 'warm','warms','warmed','warmed','warming';
verb 'warn','warns','warned','warned','warning';
verb 'wash','washes','washed','washed','washing';
verb 'waste','wastes','wasted','wasted','wasting';
verb 'watch','watches','watched','watched','watching';
verb 'water','waters','watered','watered','watering';
verb 'wave','waves','waved','waved','waving';
verb 'weigh','weighs','weighed','weighed','weighing';
verb 'welcome','welcomes','welcomed','welcomed','welcoming';
verb 'whine','whines','whined','whined','whining';
verb 'whip','whips','whipped','whipped','whipping';
verb 'whirl','whirls','whirled','whirled','whirling';
verb 'whisper','whispers','whispered','whispered','whispering';
verb 'whistle','whistles','whistled','whistled','whistling';
verb 'win','wins','won','won','winning';
verb 'wink','winks','winked','winked','winking';
verb 'wipe','wipes','wiped','wiped','wiping';
verb 'wish','wishes','wished','wished','wishing';
verb 'wobble','wobbles','wobbled','wobbled','wobbling';
verb 'wonder','wonders','wondered','wondered','wondering';
verb 'work','works','worked','worked','working';
verb 'worry','worries','worried','worried','worrying';
verb 'wrap','wraps','wrapped','wrapped','wrapping';
verb 'wreck','wrecks','wrecked','wrecked','wrecking';
verb 'wrestle','wrestles','wrestled','wrestled','wrestling';
verb 'wriggle','wriggles','wriggled','wriggled','wriggling';
verb 'wring','wrings','wrung','wrung','wringing';
verb 'write','writes','wrote','written','writing';
verb 'x-ray','x-rays','x-rayed','x-rayed','x-raying';
verb 'yawn','yawns','yawned','yawned','yawning';
verb 'yell','yells','yelled','yelled','yelling';
verb 'zip','zips','zipped','zipped','zipping';
verb 'zoom','zooms','zoomed','zoomed','zooming';
	



__DATA__

:start
Start Verb
Infinitive,present
Third,present
Past,past
am,presbe
is,presbe
are,presbe
had,pasthave
has,preshave
have,preshave
was,pastbe
were,pastbe
Modal,modal
Tests,sIsInfinitive,sIsThird,sIsPast,sIsModal
:present
Present Tense
:past
Past Tense
:presbe
Present Be
Tests,sIsGerund,sIsPart
being,presprogbe
had,prespasshave
having,presproghave
Gerund,presprog
Part,prespass
:presprog
Present Progressive
:prespass
Present Passive
:presprogbe
Present Progressive Be
Tests,sIsPart
had,presprogpasshave
Part,presprogpass
:presprogpass
Present Progressive Passive
:presprogpasshave
Present Progressive Passive Have
:prespasshave
Present Passive Have
:presproghave
Present Progressive Have
:pasthave
Past Have
Tests,sIsPart
been,pastperfbe
had,pastperfhave
Part,pastperf
:pastperf
Past Perfect
:pastperfhave
Past Perfect Have
:pastperfbe
Past Perfect Be
Tests,sIsGerund,sIsPart
had,pastperfpasshave
having,pastperfproghave
being,pastperfprogbe
Gerund,pastperfprog
Part,pastperfpass
:pastperfpass
Past Perfect Passive
:pastperfprog
Past Perfect Progressive
:pastperfpasshave
Past Perfect Passive Have
:pastperfproghave
Past Perfect Progressive Have
:pastperfprogbe
Past Perfect Progressive Be
Tests,sIsPart
had,pastperfprogpasshave
Part,pastperfprogpass
:pastperfprogpass
Past Perfect Progressive Passive
:pastperfprogpasshave
Past Perfect Progressive Passive Have
:preshave
Present Have
Tests,sIsPart
had,presperfhave
been,presperfbe
Part,presperf
:presperf
Present Perfect
:presperfhave
Present Perfect Have
:presperfbe
Present Perfect Be
Tests,sIsPart,sIsGerund
had,presperfpasshave
having,presperfproghave
being,presperfprogbe
Part,presperfpass
Gerund,presperfprog
:presperfprog
Present Perfect Progressive
:presperfpass
Present Perfect Passive
:presperfpasshave
Present Perfect Passive Have
:presperfproghave
Present Perfect Progressive Have
:presperfprogbe
Present Perfect Progressive Be
Tests,sIsPart
had,presperfprogpasshave
Part,presperfprogpass
:presperfprogpass
Present Perfect Progressive Passive
:presperfprogpasshave
Present Perfect Progressive Passive Have
:pastbe
Past Be
Tests,sIsGerund,sIsPart
had,pastpasshave
having,pastproghave
being,pastprogbe
Part,pastpass
Gerund,pastprog
:pastpass
Past Passive
:pastprog
Past Progressive
:pastpasshave
Past Passive Have
:pastproghave
Past Progressive Have
:pastprogbe
Past Progressive Be
Tests,sIsPart
had,pastprogpasshave
Part,pastprogpass
:pastprogpass
Past Progressive Passive
:pastprogpasshave
Past Progressive Passive Have
:modal
Modal
Tests,sIsInfinitive
be,modalbe
have,modalhave
Infinitive,modalinf
:modalinf
Present
:modalbe
Be
Tests,sIsPart,sIsGerund
had,modalpasshave
having,modalproghave
being,modalprogbe
Part,modalpass
Gerund,modalprog
:modalpass
Passive
:modalprog
Progressive
:modalpasshave
Passive Have
:modalproghave
Progressive Have
:modalprogbe
Progressive Be
Tests,sIsPart
had,modalprogpasshave
Part,modalprogpass
:modalprogpass
Progressive Passive
:modalprogpasshave
Progressive Passive Have
:modalhave
Have
Tests,sIsPart
had,modalperfhave
been,modalperfbe
Part,modalperf
:modalperf
Perfect
:modalperfhave
Perfect Have
:modalperfbe
Perfect Be
Tests,sIsPart,sIsGerund
had,modalperfpasshave
having,modalperfproghave
being,modalperfprogbe
Part,modalperfpass
Gerund,modalperfprog
:modalperfpass
Perfect Passive
:modalperfprog
Perfect Progressive
:modalperfpasshave
Perfect Passive Have
:modalperfproghave
Perfect Progressive Have
:modalperfprogbe
Perfect Progressive Be
Tests,sIsPart
had,modalperfprogpasshave
Part,modalperfprogpass
:modalperfprogpass
Perfect Progressive Passive
:modalperfprogpasshave
Perfect Progressive Passive Have

__END__

=head1 NAME

Linga::EN::VerbTense - Parses verb structures into modal, tense, & infinitive.

=head1 SYNOPSIS

	use Lingua::EN::VerbTense;
	
	my $string = 'I am going home now.'
	my ($modality, $tense, $inf) = verb_tense($string);
	# Gives: 
	#   $modality='None', $tense='Present Progressive', $inf='go'
	
	$string = 'He really did eat the cookie.';
	($modality, $tense, $inf) = verb_tense($string);
	# Gives:
	#   $modality='Affirmative', $tense='Present', $inf='eat'
	
	$string = 'How could she have done that???';
	($modality, $tense, $inf) = verb_tense($string);
	# Gives:
	#   $modality='Subjective Ability', $tense='Perfect', $inf='do'

=head1 DESCRIPTION	

This is a simple Perl module designed to parse english verb structures
using a finite state machine into the verb tense and infinitive, as well
as the type of infinitive in the structure. This was originally written
by Chris Meyer <chris@mytechs.com>. Josiah Byran <jdb@wcoil.com> added
multiple tweaks and twists, POD docs, and CPAN packaging.

=head1 EXPORTS

Exported by default:
	verb_tense

Tags:
	all =>
		verb 
		verb_tense 
		sFormPartInf 
		sInfPartForm 
		sIsModal 
		sIsInfinitive 
		sIsThird 
		sIsPast 
		sIsGerund 
		sIsPart
	basic => 
		verb 
		verb_tense
	tests =>
		sFormPartInf 
		sInfPartForm 
		sIsModal 
		sIsInfinitive 
		sIsThird 
		sIsPast 
		sIsGerund 
		sIsPart

OK for export:
	verb 
	verb_tense 
	sFormPartInf 
	sInfPartForm 
	sIsModal 
	sIsInfinitive 
	sIsThird 
	sIsPast 
	sIsGerund 
	sIsPart		

=head1 FUNCTIONS

=over 4 

=item verb_tense($string);

Parses a string and returns a three element list containg info about the first verb 
in the string. Example:

	($modal, $tense, $inf) = verb_tense('How could she do that???');

After that call, the variables will be set to:

	$modality='Subjective Ability';
	$tense='Perfect';
	$inf='do';


=item verb($infinitive,$third,$past,$part,$gerund);

This allows addition of your own custom verbs to the verb hash internally. 

=item sFormPartInf($verb,$type);

Tanslates the verb $verb which is of type $type into the infitive for that
verb. $type must be one of the following:
	Gerund
	Infinitive
	Third
	Past

Example:
	$string = sFormPart("going","Gerund") 

Returns "go".

=item sInfPartForm($verb,$type);

Translates infinitive $verb to type $type. $type must be one of the 
following:
	Gerund
	Infinitive
	Third
	Past

Example:
	$string = sInfPartForm("go","Gerund");

Returns "going".

=item sIsModal($verb);

=item sIsInfinitive($verb);

=item sIsThird($verb);

=item sIsPast($verb);

=item sIsGerund($verb); 

=item sIsPart($verb);

Each of these functions tests for its namesake. E.g. sIsModal($verb) tests if $verb
is a modal. If $verb is a modal, it returns "Modal", else it returns "" (not undef.) 
The same logic follows for the other five functions.

=back

=head1 EXAMPLE

    use Lingua::EN::VerbTense;
	
	print ': ';
	while (<>)	{
		chomp;
		exit if /^[qQdDeE]$/;
        my ($Modality, $Tense, $Inf) = verb_tense($_);
		print "modality = $Modality, tense = $Tense, inf = $Inf\n: ";
	}

This example allows you to enter a string to parse and it displays
the results of the parse. Type 'q' to quit the loop.

=head1 AUTHOR

Copyright (C) 2000 Chris Meyer
chris@mytechs.com
1143 5th Street East
Altoona, WI 54720

Edited and enhanced by Josiah Bryan jbryan@cpan.org>

Repackaged by John Napiorkowski jjnapiork@cpan.org

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

=cut
