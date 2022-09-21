#!/usr/bin/env perl
# Copyright (C) 2012-2022  Alex Schroeder <alex@gnu.org>

# This program is free software: you can redistribute it and/or modify it under
# the terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program. If not, see <http://www.gnu.org/licenses/>.

=encoding utf8

=head1 NAME

Game::CharacterSheetGenerator - a web app to generate character sheets

=head1 DESCRIPTION

Character Sheet Generator is a web application that generates characters for the
Halberts & Helmets game. It does two things: it generates the stats for random
characters, and it populates a SVG file with those values.

Here's an example of the stats generated:

    name: Diara
    str: 11
    dex: 10
    con: 13
    int: 10
    wis: 9
    cha: 7
    level: 1
    xp: 0
    thac0: 19
    class: halfling
    hp: 4
    ac: 6
    property: backpack
    property: rope
    property: leather armour
    property: silver dagger
    property: sling
    property: pouch with 30 stones
    abilities: 1/6 for normal tasks
    abilities: 2/6 to hide and sneak
    abilities: 5/6 to hide and sneak outside
    abilities: +1 for ranged weapons
    abilities: AC -2 against giants
    charsheet: Charaktersheet.svg
    breath: 13
    poison: 8
    petrify: 10
    wands: 9
    spells: 12

Think of it as key value pairs. Some keys have multiple values, resulting in
multiline values.

The SVG file acts as a template. For every key in the character, a C<text>
element with a matching id is searched and if found, C<tspan> elements matching
the value are inserted.

The C<charsheet> key is special because it tells the app which file to load.

On a technical level, Character Sheet Generator is a web app based on the
Mojolicious framework. This class in particular uses L<Mojolicious::Lite>.

See L<Mojolicious::Guides> for more information.

=cut

package Game::CharacterSheetGenerator;

our $VERSION = 1.03;

use Modern::Perl;
use Game::CharacterSheetGenerator::ElfNames qw(elf_name);
use Game::CharacterSheetGenerator::DwarfNames qw(dwarf_name);
use Game::CharacterSheetGenerator::HalflingNames qw(halfling_name);
use Game::CharacterSheetGenerator::HumanNames qw(human_name);
use Mojolicious::Lite;
use Mojo::UserAgent;
use Mojo::Log;
use File::ShareDir "dist_dir";
use I18N::AcceptLanguage;
use XML::LibXML;
use List::Util qw(shuffle max);
use POSIX qw(floor ceil);
use Cwd;
no warnings qw(uninitialized numeric);

# Commands for the command line!
push @{app->commands->namespaces}, "Game::CharacterSheetGenerator::Command";

# Change scheme if "X-Forwarded-Proto" header is set (presumably to HTTPS)
app->hook(before_dispatch => sub {
  my $c = shift;
  $c->req->url->base->scheme("https")
      if $c->req->headers->header("X-Forwarded-Proto") } );

=head2 Configuration

As a Mojolicious application, it will read a config file called
F<character-sheet-generator.conf> in the same directory, if it exists. As the
default log level is "debug", one use of the config file is to change the log
level using the C<loglevel> key, and if you're not running the server in a
terminal, using the C<logfile> key to set a file.

The default map and table are stored in the F<contrib> directory. You can change
this directory using the C<contrib> key. By default, the directory included with
the distribution is used. Thus, if you're a developer, you probably want to use
something like the following to use the files from the source directory.

The code also needs to know where the Face Generator can be found, if at all.
You can set the URL using the C<face_generator_url> key. If you're a developer
and have it running locally on port 3020, this is what you'd use:

    {
      loglevel => "debug",
      logfile => undef,
      contrib => "share",
      face_generator_url => "http://localhost:3020",
    }

=cut

plugin Config => {
  default => {
    loglevel => "warn",
    logfile => undef,
    contrib => undef,
  },
  file => getcwd() . "/character-sheet-generator.conf",
};

my $log = Mojo::Log->new;
$log->level(app->config("loglevel"));
$log->path(app->config("logfile"));
$log->debug($log->path ? "Logfile is " . $log->path : "Logging to stderr");

my $dist_dir = app->config("contrib") // dist_dir("Game-CharacterSheetGenerator");
$log->debug("Reading contrib files from $dist_dir");

sub translations {
  # strings in sinqle quotes are translated into German if necessary
  # use %0, %1, etc. for parameters
  my %translations = split(/\n/, q{%0 gold
%0 Gold
%0 silver
%0 Silber
%0: How much does this cost?
%0: Wieviel kostet das?
+1 bonus to ranged weapons
+1 für Fernwaffen
+4 to hit and double damage backstabbing
+4 und Schaden ×2 für hinterhältigen Angriff
1/6 for normal tasks
1/6 für normale Aufgaben
2/6 to find secret constructions and traps
2/6 um Geheimbauten und Fallen zu finden
2/6 to find secret or concealed doors
2/6 um geheime und versteckte Türen zu finden
2/6 to hear noise
2/6 um Geräusche zu hören
2/6 to hide and sneak
2/6 für Verstecken und Schleichen
5/6 to hide and sneak outdoors
5/6 für Verstecken und Schleichen im Freien
%d/6 for all activities
%d/6 für alle Aktivitäten
AC -2 vs. opponents larger than humans
Rüstung -2 bei Gegnern über Menschengrösse
Charactersheet.svg
Charakterblatt.svg
Charactersheet-landscape.svg
Charakterblatt-quer.svg
Hireling.svg
Mietling.svg
Classes
Klassen
Property
Eigentum
Spells:
Zaubersprüche:
Unknown Price
Unbekannter Preis
and
und
backpack
Rucksack
battle axe
Streitaxt
case with 30 bolts
Kiste mit 30 Bolzen
chain mail
Kettenhemd
charm person
Person bezaubern
club
Keule
crossbow
Armbrust
d6
W6
dagger
Dolch
detect magic
Magie entdecken
dwarf
Zwerg
elderly man
älterer Mann
elderly woman
ältere Frau
elf
Elf
fighter
Krieger
flask of oil
Ölflasche
floating disc
Schwebende Scheibe
halfling
Halbling
hand axe
Handaxt
helmet
Helm
hireling
Mietling
porter
Träger
hold portal
Portal verschliessen
12 iron spikes and hammer
12 Eisenkeile und Hammer
3 stakes and hammer
12 Holzpfähle und Hammer
lantern
Laterne
leather armor
Lederrüstung
light
Licht
long bow
Langbogen
long sword
Langschwert
mace
Streitkeule
magic missile
Magisches Geschoss
magic-user
Magier
man
Mann
mirror
Spiegel
plate mail
Plattenpanzer
pole arm
Stangenwaffe
pouch with 30 stones
Beutel mit 30 Steinen
protection from evil
Schutz vor Bösem
quiver with 20 arrows
Köcher mit 20 Pfeilen
read languages
Sprachen lesen
read magic
Magie lesen
rope
Seil
shield
Schild
short bow
Kurzbogen
short sword
Kurzschwert
silver dagger
Silberner Dolch
sleep
Schlaf
sling
Schleuder
spear
Speer
spell book
Zauberbuch
staff
Stab
thief
Dieb
thieves’ tools
Diebeswerkzeug
6 torches
6 Fackeln
two handed sword
Zweihänder
ventriloquism
Bauchreden
war hammer
Kriegshammer
wolfsbane
Eisenhut (sog. Wolfsbann)
garlic
Knoblauch
woman
Frau
pole
Stab
young man
junger Mann
young woman
junge Frau
rations (1 week)
Wegzehrung (1 Woche)
});

  return \%translations;
}

my $translation = translations();
our $lang; # we'll set it in random_parameters

sub T {
  my ($en, @arg) = @_;
  my $suffix = '';
  # handle (2) suffixes
  if ($en =~ /(.*)( \(\d+\))$/) {
    $en = $1;
    $suffix = $2;
  }
  if ($translation->{$en} and $lang eq "de") {
    $en = $translation->{$en};
  }
  # utf8::encode($en);
  for (my $i = 0; $i < scalar @arg; $i++) {
    my $s = $arg[$i];
    $en =~ s/%$i/$s/g;
  }
  return $en . $suffix;
}

sub svg_read {
  my ($char) = @_;
  my $filename = $char->{charsheet} || 'Charactersheet.svg';
  my $doc;
  if (-f "$dist_dir/$filename") {
    $doc = XML::LibXML->load_xml(location => "$dist_dir/$filename");
  } else {
    my $ua = Mojo::UserAgent->new;
    my $tx = $ua->get($filename);
    die "«$filename»: " . $tx->res->error->{message} . "\n" unless $tx->success;
    $doc = XML::LibXML->load_xml(string => $tx->res->body);
  }
  return ($char, $doc); # used as parameters for svg_transform
}

sub replace_text {
  my ($parser, $node, $str) = @_;
  my @line = split(/\\\\/, $str);

  # is this multiline in the template
  # (ignore text nodes, go for tspans only)
  my $dy;
  my $tspans = $node->find(qq{svg:tspan});
  if ($tspans->size() > 1) {
    $dy = $tspans->get_node(2)->getAttribute("y")
      - $tspans->get_node(1)->getAttribute("y");
  } else {
    # mismatch, attempt readable compromise
    @line = (join(", ", @line));
  }

  # delete the tspan nodes of the text node
  $node->removeChildNodes();

  my $tspan = XML::LibXML::Element->new("tspan");
  $tspan->setAttribute("x", $node->getAttribute("x"));
  $tspan->setAttribute("y", $node->getAttribute("y"));

  while (@line) {
    my $line = shift(@line); # cannot have this in while cond because of "0"
    next if $line eq ''; # cannot parse empty strings
    my $fragment = $parser->parse_balanced_chunk(T($line));
    foreach my $child ($fragment->childNodes) {
      my $tag = $child->nodeName;
      if ($tag eq "strong" or $tag eq "b") {
	my $node = XML::LibXML::Element->new("tspan");
	$node->setAttribute("style", "font-weight:bold");
	$node->appendText($child->textContent);
	$tspan->appendChild($node);
      } elsif ($tag eq "em" or $tag eq "i") {
	my $node = XML::LibXML::Element->new("tspan");
	$node->setAttribute("style", "font-style:italic");
	$node->appendText($child->textContent);
	$tspan->appendChild($node);
      } elsif ($tag eq "a") {
	$child->setAttributeNS("http://www.w3.org/1999/xlink", "xlink:href",
			       $child->getAttribute("href"));
	$child->removeAttribute("href");
	$tspan->appendChild($child);
      } else {
	$tspan->appendText($child->textContent);
      }
    }
    $node->appendChild($tspan);
    if (@line) {
      $tspan = $tspan->cloneNode();
      $tspan->setAttribute("y", $tspan->getAttribute("y") + $dy);
    }
  }
}

sub svg_transform {
  my ($self, $char, $doc) = @_;
  my $parser = XML::LibXML->new;
  my $svg = XML::LibXML::XPathContext->new;
  $svg->registerNs("svg", "http://www.w3.org/2000/svg");

  for my $id (keys %$char) {
    next unless $id =~ /^[-a-z0-9]+$/;
    my $nodes = $svg->find(qq{//svg:text[\@id="$id"]}, $doc);
    for my $node ($nodes->get_nodelist) {
      replace_text($parser, $node, $char->{$id}, $doc);
      next;
    }
    $nodes = $svg->find(qq{//svg:image[\@id="$id"]}, $doc);
    for my $node ($nodes->get_nodelist) {
      $node->setAttributeNS("http://www.w3.org/1999/xlink",
			    "xlink:href", $char->{$id});
      next;
    }
  }

  # $self is not set when using the random command
  # (Game::CharacterSheetGenerator::Command::random).
  if ($self) {
    my $nodes = $svg->find(qq{//svg:a[\@id="link"]/attribute::xlink:href}, $doc);
    for my $node ($nodes->get_nodelist) {
      my $params = Mojo::Parameters->new;
      for my $key (@{$char->{provided}}) {
	$params->append($key => $char->{$key}||'');
      }
      $node->setValue($self->url_for("edit")->query($params));
    }
  }

  return $doc;
}

sub svg_show_id {
  my ($char, $doc) = @_;

  my $svg = XML::LibXML::XPathContext->new;
  $svg->registerNs("svg", "http://www.w3.org/2000/svg");

  for my $node ($svg->find(qq{//svg:text/svg:tspan/..}, $doc)->get_nodelist) {
    my $id = $node->getAttribute("id");
    next if $id =~ /^text[0-9]+(-[0-9]+)*$/; # skip Inkscape default texts
    next unless $id =~ /^[-a-z0-9]+$/;
    $node->removeChildNodes();
    $node->appendText($id);
    my $style = $node->getAttribute("style");
    $style =~ s/font-size:\d+px/font-size:8px/;
    $style =~ s/fill:#\d+/fill:magenta/ or $style .= ";fill:magenta";
    $node->setAttribute("style", $style);
  }

  for my $node ($svg->find(qq{//svg:image}, $doc)->get_nodelist) {
    my $id = $node->getAttribute("id");
    next if $id =~ /^text[0-9]+(-[0-9]+)*$/; # skip Inkscape default texts
    next unless $id =~ /^[-a-z0-9]+$/;
    my $text = XML::LibXML::Element->new("text");
    $text->setAttribute("x", $node->getAttribute("x") + 5);
    $text->setAttribute("y", $node->getAttribute("y") + 10);
    $text->appendText($id);
    $text->setAttribute("style", "font-size:8px;fill:magenta");
    $node->addSibling($text);
  }

  return $doc;
}

sub bonus {
  my $n = shift;
  return "-3" if $n <=  3;
  return "-2" if $n <=  5;
  return "-1" if $n <=  8;
  return "" if $n <= 12;
  return "+1" if $n <= 15;
  return "+2" if $n <= 17;
  return "+3";
}

sub cha_bonus {
  my $n = shift;
  return "-2" if $n <=  3;
  return "-1" if $n <=  8;
  return "" if $n <= 12;
  return "+1" if $n <= 17;
  return "+2";
}

sub character {
  my $char = shift;
  for my $id (qw(str dex con int wis cha)) {
    if ($char->{$id} and not defined $char->{"$id-bonus"}) {
      $char->{"$id-bonus"} = bonus($char->{$id});
    }
  }
  if ($char->{cha} and not defined $char->{reaction}) {
    $char->{reaction} = cha_bonus($char->{cha});
  }
  if (not $char->{loyalty}) {
    $char->{loyalty} =  7 + $char->{"cha-bonus"};
  }
  if (not defined $char->{hirelings}) {
    $char->{hirelings} =  4 + $char->{"cha-bonus"};
  }
  if ($char->{thac0} and not defined $char->{"melee-thac0"}) {
    $char->{"melee-thac0"} = $char->{thac0} - $char->{"str-bonus"};
  }
  if ($char->{thac0} and not defined $char->{"range-thac0"}) {
    $char->{"range-thac0"} = $char->{thac0} - $char->{"dex-bonus"};
  }
  if ($char->{thac0} and not defined $char->{"other-thac0"}) {
    $char->{"other-thac0"} = $char->{thac0};
  }
  for my $type ("melee", "range", "other") {
    for (my $n = 0; $n <= 9; $n++) {
      my $val = $char->{"$type-thac0"} - $n;
      $val = 20 if $val > 20;
      $val =  1 if $val <  1;
      $char->{"$type$n"} = $val unless $char->{"$type$n"};
    }
  }
  if (not defined $char->{damage}) {
    $char->{damage} = 1 . T('d6');
  }
  if (not defined $char->{"melee-damage"}) {
    $char->{"melee-damage"} = $char->{damage} . $char->{"str-bonus"};
  }
  if (not defined $char->{"range-damage"}) {
    $char->{"range-damage"} = $char->{damage};
  }
  if (not defined $char->{"other-damage"}) {
    $char->{"other-damage"} = $char->{damage};
  }
  saves($char);
}

# This function is called when preparing data for display in SVG.
sub compute_data {
  my ($char, $language) = @_;
  local $lang = $language; # make sure T works as intended
  character($char);
}

sub starting_gold {
  my $class = shift;
  return 0 if $class eq T('hireling') or $class eq T('porter');
  return roll_3d6() * 10;
}

my %price_cache;

sub equipment {
  my $char = shift;
  my $xp = $char->{xp};
  my $level = $char->{level};
  my $class = $char->{class};
  return if $xp or $level > 1 or not $class;

  get_price_cache($char);
  my $money = starting_gold($class);
  my @property;

  # free spellbook for arcane casters
  if (member($class, T('magic-user'), T('elf'))) {
    push(@property, T('spell book'));
  }

  ($money, @property) = buy_basics($char, $money, $class, @property);
  ($money, @property) = buy_armor($char, $money, $class, @property);
  ($money, @property) = buy_weapon($char, $money, $class, @property);
  ($money, @property) = buy_tools($char, $money, $class, @property);
  ($money, @property) = buy_light($char, $money, $class, @property);
  ($money, @property) = buy_gear($char, $money, $class, @property);
  ($money, @property) = buy_protection($char, $money, $class, @property);
  my $gold = int($money);
  my $silver = int(10 * ($money - $gold) + 0.5);;
  push(@property, T('%0 gold', $gold)) if $gold;
  push(@property, T('%0 silver', $silver)) if $silver;
  provide($char, "property",  join("\\\\", @property));
}

# This is computed at runtime because of the translations.
sub get_price_cache {
  my $char = shift;
  %price_cache = (
    T('backpack') => 5,
    T('rations (1 week)') => 15,
    T('thieves’ tools') => 25,
    T('lantern') => 10,
    T('flask of oil') => 2,
    T('6 torches') => 1,
    T('rope') => 1,
    T('3 stakes and hammer') => 3,
    T('12 iron spikes and hammer') => 3,
    T('pole') => 1,
    T('wolfsbane') => 10,
    T('garlic') => 1,
    T('mirror') => 5,
    T('leather armor') => 20,
    T('chain mail') => 40,
    T('plate mail') => 60,
    T('shield') => 10,
    T('helmet') => 10,
    T('club') => 3,
    T('mace') => 5,
    T('war hammer') => 5,
    T('staff') => 2,
    T('dagger') => 3,
    T('silver dagger') => 30,
    T('two handed sword') => 15,
    T('battle axe') => 7,
    T('pole arm') => 7,
    T('long sword') => 10,
    T('short sword') => 7,
    T('long bow') => 40,
    T('quiver with 20 arrows') => 5,
    T('short bow') => 25,
    T('crossbow') => 30,
    T('case with 30 bolts') => 10,
    T('sling') => 2,
    T('pouch with 30 stones') => 0,
    T('hand axe') => 4,
    T('spear') => 3,
      );
}

sub price {
  my ($char, $item) = @_;
  my $price = $price_cache{$item};
  if (not defined $price) {
    $log->error(T('Unknown Price'), T('%0: How much does this cost?', $item));
    return 0;
  }
  return $price;
}

# add($item, \@property) modifies @property directly
sub add {
  my ($item, $property) = @_;
  foreach (@$property) {
    if ($_ eq $item) {
      if (/\(\d+\)$/) {
	my $n = $1++;
	s/\(\d+\)$/($n)/;
      } else {
	$_ .= " (2)";
      }
      $item = undef;
      last;
    }
  }
  if ($item) {
    push(@$property, $item);
  }
}

# Use array references to buy one of several alternatives.
# Buy a and b, or buy c instead:
# ($money, @property) = buy($char, [[a, b], c], $money, @property)
sub buy {
  my ($char, $item, $money, @property) = @_;
  if (ref $item eq "ARRAY") {
    for my $elem (@$item) {
      if (ref $elem eq "ARRAY") {
	my $price = 0;
	for my $thing (@$elem) {
	  $price += price($char, $thing);
	}
	if ($money >= $price) {
	  $money -= $price;
	  $elem->[-1] .= " (${price}gp)" if $char->{debug};
	  foreach (@$elem) {
	    add($_, \@property);
	  }
	  last;
	}
      } else {
	my $price = price($char, $elem);
	if ($money >= $price) {
	  $money -= $price;
	  $elem .= " (${price}gp)" if $char->{debug};
	  add($elem, \@property);
	  last;
	}
      }
    }
  } else {
    my $price = price($char, $item);
    if ($money >= $price) {
      $money -= $price;
      $item .= " (${price}gp)" if $char->{debug};
      add($item, \@property);
    }
  }
  return ($money, @property);
}

sub buy_basics {
  my ($char, $money, $class, @property) = @_;
  push(@property, "- $money gp -") if $char->{debug};
  ($money, @property) = buy($char, T('backpack'), $money, @property);
  ($money, @property) = buy($char, T('rations (1 week)'), $money, @property);

  return ($money, @property);
}

sub buy_tools {
  my ($char, $money, $class, @property) = @_;
  push(@property, "- $money gp -") if $char->{debug};
  if ($class eq T('thief')) {
    ($money, @property) = buy($char, T('thieves’ tools'), $money, @property);
  }
  return ($money, @property);
}

sub buy_light {
  my ($char, $money, $class, @property) = @_;
  push(@property, "- $money gp -") if $char->{debug};
  return buy($char, [[T('lantern'), T('flask of oil')],
	      T('6 torches')],
	     $money, @property);
}

sub buy_gear {
  my ($char, $money, $class, @property) = @_;
  push(@property, "- $money gp -") if $char->{debug};
  my @preferences = shuffle(
    T('rope'),
    T('12 iron spikes and hammer'),
    T('3 stakes and hammer'),
    T('pole'));
  return buy($char, \@preferences, $money, @property);
}

sub buy_protection {
  my ($char, $money, $class, @property) = @_;
  push(@property, "- $money gp -") if $char->{debug};
  my @preferences = shuffle(
    T('garlic'),
    T('wolfsbane'),
    T('mirror'));
  return buy($char, \@preferences, $money, @property);
}

sub buy_armor {
  my ($char, $money, $class, @property) = @_;
  push(@property, "- $money gp -") if $char->{debug};
  my $budget = $money / 2;
  $money -= $budget;

  if ($class eq T('magic-user')) {
    # no armor
  } elsif ($class eq T('thief')) {
    # leather, no shield, no helmet
    ($budget, @property) = buy($char, T('leather armor'), $budget, @property);
  } else {
    # any armor
    ($budget, @property) = buy($char, [T('plate mail'),
				       T('chain mail'),
				       T('leather armor')], $budget, @property);
    ($budget, @property) = buy($char, T('shield'), $budget, @property);
    ($budget, @property) = buy($char, T('helmet'), $budget, @property);
  }

  # compute AC
  my $dex = $char->{dex};
  my $ac = 9 - bonus($dex);

  if (member(T('plate mail'), @property)) { $ac -= 6; }
  elsif (member(T('chain mail'), @property)) { $ac -= 4; }
  elsif (member(T('leather armor'), @property)) { $ac -= 2; }

  if (member(T('shield'), @property)) { $ac -= 1; }

  if ($class eq T('halfling')) {
    $ac .= "/" . ($ac - 2);
  }
  provide($char, "ac",  $ac);

  return ($money + $budget, @property);
}

sub buy_melee_weapon {
  my $char = shift;
  my ($money, $class, @property) = @_;
  my $str = $char->{str};
  my $hp  = $char->{hp};
  my $shield = member(T('shield'), @property);
  my @preferences;

  if ($class eq T('magic-user')) {
    @preferences = shuffle(
      T('dagger'),
      T('staff'));
  } elsif ($class eq T('fighter')) {
    if (good($str)
	and $hp > 6
	and not $shield) {
      # prefer a shield!
      push(@preferences,
	   shuffle(T('two handed sword'),
		   T('battle axe'),
		   T('pole arm')));
    }
    push(@preferences,
	 T('long sword'),
	 T('short sword'),
	 T('mace'));
  } elsif ($class eq T('dwarf')) {
    push(@preferences, T('battle axe')) unless $shield;
    push(@preferences,
	 T('war hammer'),
	 T('mace'),
	 T('short sword'));
  } elsif ($class eq T('halfling')) {
    @preferences = (T('short sword'),
		    T('mace'),
		    T('club'));
  } elsif ($class eq T('elf')) {
    @preferences = (T('long sword'),
		    T('short sword'));
  } elsif ($class eq T('thief')) {
    @preferences = (T('long sword'),
		    T('short sword'),
		    T('mace'),
		    T('club'));
  } elsif ($class eq T('hireling')) {
    @preferences = (T('spear'),
		    T('club'));
  } elsif ($class eq T('porter')) {
    @preferences = ();
  } else {
    $log->warn("Unknown class $class has no preferred weapons");
  }
  return buy($char, \@preferences, $money, @property);
}

sub buy_throwing_weapon {
  my $char = shift;
  my ($money, $class, @property) = @_;
  my @preferences;
  if ($class eq T('dwarf') or member(T('battle axe'), @property)) {
    push(@preferences, [T('hand axe'), T('hand axe')]);
    push(@preferences, T('hand axe'));
  }
  if ($class eq T('fighter')) {
    push(@preferences, T('spear'));
  }
  return buy($char, \@preferences, $money, @property);
}

sub buy_ranged_weapon {
  my $char = shift;
  my ($money, $class, @property) = @_;
  my @preferences;
  my $dex = $char->{dex};
  if (($class eq T('fighter') or $class eq T('elf'))
      and average($dex)) {
    push(@preferences,
	 [T('long bow'),
	  T('quiver with 20 arrows'),
	  T('quiver with 20 arrows')],
	 [T('long bow'),
	  T('quiver with 20 arrows')]);
  }
  if ($class ne T('magic-user')) {
    if (average($dex)) {
      push(@preferences,
	   [T('short bow'),
	    T('quiver with 20 arrows'),
	    T('quiver with 20 arrows')],
	   [T('short bow'),
	    T('quiver with 20 arrows')]);
    }
    push(@preferences,
	 [T('crossbow'),
	  T('case with 30 bolts')]);
    push(@preferences,
	 [T('sling'),
	  T('pouch with 30 stones')]);
  }
  return buy($char, \@preferences, $money, @property);
}

sub buy_weapon {
  my $char = shift;
  my ($money, $class, @property) = @_;
  push(@property, "- $money gp -") if $char->{debug};
  my $budget = $money / 2;
  $money -= $budget;

  ($budget, @property) = buy_melee_weapon($char, $budget, $class, @property);
  ($budget, @property) = buy_throwing_weapon($char, $budget, $class, @property);
  ($budget, @property) = buy_ranged_weapon($char, $budget, $class, @property);

  ($budget, @property) = buy($char, T('silver dagger'), $budget, @property);

  ($budget, @property) = buy($char, T('dagger'), $budget, @property);
  ($budget, @property) = buy($char, T('dagger'), $budget, @property);

  return ($money + $budget, @property);
}

sub spellbook {
  my $char = shift;
  return T('Spells:') . " "
      . one(T('charm person'),
	    T('detect magic'),
	    T('floating disc'),
	    T('hold portal'),
	    T('light'),
	    T('magic missile'),
	    T('protection from evil'),
	    T('read languages'),
	    T('read magic'),
	    T('shield'),
	    T('sleep'),
	    T('ventriloquism'));
}

sub saves {
  my $char = shift;
  my $class = $char->{class};
  my $level = $char->{level};
  return unless $class;
  my ($breath, $poison, $petrify, $wands, $spells);
  if  ($class eq T('dwarf') or $class eq T('halfling')) {
    ($breath, $poison, $petrify, $wands, $spells) =
	improve([13, 8, 10, 9, 12], [3, 2, 2, 2, 2], int(($level-1)/3));
  } elsif ($class eq T('elf')) {
    ($breath, $poison, $petrify, $wands, $spells) =
	improve([15, 12, 13, 13, 15], 2, int(($level-1)/3));
  } elsif ($class eq T('fighter')) {
    ($breath, $poison, $petrify, $wands, $spells) =
      improve([15, 12, 14, 13, 16], 2, int(($level-1)/3));
  } elsif ($class eq T('magic-user')) {
    ($breath, $poison, $petrify, $wands, $spells) =
      improve([16, 13, 13, 13, 14], 2, int(($level-1)/5));
  } elsif ($class eq T('thief')) {
    ($breath, $poison, $petrify, $wands, $spells) =
      improve([16, 14, 13, 15, 14], 2, int(($level-1)/4));
  } else {
    ($breath, $poison, $petrify, $wands, $spells) =
      (17, 14, 16, 15, 18);
  }

  provide($char, "breath",  $breath) unless $char->{breath};
  provide($char, "poison",  $poison) unless $char->{poison};
  provide($char, "petrify",  $petrify) unless $char->{petrify};
  provide($char, "wands",  $wands) unless $char->{wands};
  provide($char, "spells",  $spells) unless $char->{spells};
}

sub improve {
  my $saves = shift;
  my $improvement = shift;
  my $steps = shift;
  for (my $i = 0; $i < @$saves; $i++) {
    $saves->[$i] -= ref($improvement) ? $improvement->[$i] : $improvement for 1 .. $steps;
  }
  return @$saves;
}

sub d3 {
  return 1 + int(rand(3));
}

sub d4 {
  return 1 + int(rand(4));
}

sub d6 {
  return 1 + int(rand(6));
}

sub d8 {
  return 1 + int(rand(8));
}

sub d10 {
  return 1 + int(rand(10));
}

sub d12 {
  return 1 + int(rand(12));
}

sub roll_3d6 {
  return d6() + d6() + d6();
}

sub roll_3d8 {
  return d8() + d8() + d8();
}

sub best {
  my $best = 0;
  my $max = $_[0];
  for (my $i = 1; $i < 6; $i++) {
    if ($_[$i] > $max) {
      $best = $i;
      $max = $_[$best];
    }
  }
  my @stat = qw(str dex con int wis cha);
  return $stat[$best];
}

sub above {
  my $limit = shift;
  my $n = 0;
  for (my $i = 0; $i <= $#_; $i++) {
    $n++ if $_[$i] > $limit;
  }
  return $n;
}

sub good {
  return above(12, @_);
}

sub average {
  return above(8, @_);
}

# use prototype so that Perl knows that there are only three arguments, which
# allows wrap to use wantarray when used to wrap $value
sub provide ($$$) {
  my ($char, $key, $value) = @_;
  return unless not defined $char->{$key} or $char->{$key} eq '';
  # empty strings get overwritten, but zero does not get overwritten
  push(@{$char->{provided}}, $key);
  $char->{$key} = $value;
}

sub one {
  my $i = int(rand(scalar @_));
  return $_[$i];
}

sub two {
  my $i = int(rand(scalar @_));
  my $j = int(rand(scalar @_));
  $j = int(rand(scalar @_)) until $i != $j;
  return ($_[$i], $_[$j]);
}

sub member {
  my $element = shift;
  foreach (@_) {
    return 1 if $element eq $_;
  }
}

sub wrap {
  my ($text, $width) = @_;
  my @result;
  while (length($text) > $width) {
    my $n = $width;
    while ($n > 0) {
      if (substr($text, $n, 1) eq " ") {
	push(@result, substr($text, 0, $n));
	$text = substr($text, $n + 1);
	last;
      } else {
	$n--;
      }
    }
  }
  push(@result, $text);
  return @result if wantarray;
  return join("\\\\", @result);
}

my $traits = {
  # http://charaktereigenschaften.miroso.de/
  de => [qw{
aalglatt abenteuerlustig abfällig abgebrüht abgehoben abgeklärt abgestumpft
absprachefähig abwartend abweisend abwägend achtsam affektiert affig aggressiv
agil akkurat akribisch aktiv albern altklug altruistisch ambitioniert
anarchisch angeberisch angepasst angriffslustig angsteinflößend angstvoll
anhänglich anmutig anpassungsfähig ansprechend anspruchslos anspruchsvoll
anstrengend anzüglich arbeitswütig arglistig arglos argwöhnisch arrogant artig
asketisch athletisch attraktiv aufbegehrend aufbrausend aufdringlich aufgedreht
aufgeregt aufgeschlossen aufgeweckt aufhetzerisch aufmerksam
aufmerksamkeitsbedürftig aufmüpfig aufopfernd aufrichtig aufschneiderisch
aufsässig ausdauernd ausdruckslos ausdrucksstark ausfallend ausgeflippt
ausgefuchst ausgeglichen ausländerfeindlich ausnutzbar autark authentisch
autonom autoritär außergewöhnlich barbarisch barmherzig barsch bedacht
bedrohlich bedrückt bedächtig bedürfnislos beeinflussbar befangen befehlerisch
begeistert begeisterungsfähig begierig begnügsam begriffsstutzig behaglich
beharrlich behende beherrscht beherzt behutsam behäbig beirrbar belastbar
belebend beliebt bemüht bequem berechnend beredsam berüchtigt bescheiden
besessen besitzergreifend besonders besonnen besorgt besserwissend
besserwisserisch bestechend bestechlich bestialisch bestimmend bestimmerisch
beständig betriebsam betrügerisch betörend bewandert bewusst bezaubernd bieder
bigott bissig bitter bizarr blasiert blass blauäugig blumig blutrünstig bockig
bodenständig borniert boshaft brav breitspurig brisant brummig brutal bärbeißig
bösartig böse böswillig chaotisch charismatisch charmant chauvinistisch
cholerisch clever cool couragiert damenhaft dankbar defensiv dekadent
demagogisch demütig depressiv derb desorganisiert despotisch destruktiv
determinativ devot dezent dezidiert diabolisch dickhäutig dickköpfig diffus
diktatorisch diplomatisch direkt diskret distanziert distinguiert diszipliniert
disziplinlos divenhaft dogmatisch doktrinär dominant doof dramatisch
dramatisierend draufgängerisch dreist drängend dubios duckmäuserisch duldsam
dumm durchblickend durcheinander durchschaubar durchschauend durchsetzungsstark
durchtrieben dusselig dynamisch dämlich dünkelhaft dünnhäutig echt edel
effizient egoistisch egoman egozentrisch ehrenhaft ehrenwert ehrfürchtig
ehrgeizig ehrlich eifersüchtig eifrig eigen eigenartig eigenbestimmt
eigenbrödlerisch eigenmächtig eigennützig eigensinnig eigenständig eigenwillig
eilig einfach einfallslos einfallsreich einfältig einfühlsam eingebildet
eingeschüchtert einladend einnehmend einsam einsatzbereit einschüchternd
einseitig einsichtig einträchtig eintönig einzelgängerisch einzigartig eisern
eiskalt eitel ekelig elastisch elefantös elegant elitär emotional empathisch
empfindlich empfindsam empfindungsvoll emsig energetisch energiegeladen
energievoll energisch engagiert engstirnig entgegenkommend enthaltsam enthemmt
enthusiastisch entscheidungsfreudig entschieden entschlossen entspannt
enttäuscht erbarmungslos erbärmlich erfinderisch erfolgsorientiert erfrischend
ergeben erhaben erlebnisse ermutigend ernst ernsthaft erotisch erwartungsvoll
exaltiert exorbitant experimentierfreudig extravagant extravertiert
extrovertiert exzentrisch facettenreich fair falsch familiär fantasielos
fantasiereich fantasievoll fantastisch fatalistisch faul feige fein feindselig
feinfühlig feinsinnig feminin fesselnd feurig fies fixiert flatterhaft fleissig
fleißig flexibel folgsam fordernd forsch fragil frech freiheitskämfend
freiheitsliebend freimütig freizügig fremdbestimmend fremdbestimmt freudvoll
freundlich friedfertig friedlich friedliebend friedlos friedselig friedvoll
frigide frisch frohgemut frohnatur frohsinnig fromm frostig fröhlich furchtlos
furchtsam furios fügsam fürsorglich galant gallig gamsig garstig gastfreundlich
gebieterisch gebildet gebührend gedankenlos gediegen geduldig gefallsüchtig
gefährlich gefällig gefügig gefühllos gefühlsbetont gefühlskalt gefühlvoll
geheimnisvoll gehemmt gehorsam gehässig geistreich geizig geladen gelassen
geldgierig geltungssüchtig gemein gemütvoll genauigkeitsliebend generös genial
genügsam gepflegt geradlinig gerecht gerechtigkeitsliebend gerissen gescheit
geschickt geschmeidig geschwätzig gesellig gesprächig gesundheitsbewusst
gewaltsam gewalttätig gewieft gewissenhaft gewissenlos gewitzt gewöhnlich
gierig giftig glamurös glaubensstark gleichgültig gleichmütig gläubig gnadenlos
gottergeben gottesfürchtig grantig grausam grazil griesgrämig grimmig grob
grotesk großherzig großkotzig großmäulig großmütig großspurig großzügig
gräßlich größenwahnsinnig grübelnd gründlich gutgläubig gutherzig gutmütig
gönnerhaft gütig haarspalterisch habgierig habsüchtig halsstarrig harmlos
harmoniebedürftig harmoniesüchtig hart hartherzig hartnäckig hasenherzig
hasserfüllt hedonistisch heimatverbunden heimtückisch heiter hektisch
heldenhaft heldenmütig hellhörig hemmungslos herablassend herausfordernd
heroisch herrisch herrlich herrschsüchtig herzerfrischend herzlich herzlos
hetzerisch heuchlerisch hibbelig hilflos hilfsbereit hingebungsvoll
hinterfotzig hintergründig hinterhältig hinterlistig hinterwäldlerisch
hirnrissig hitzig hitzköpfig hochbegabt hochfahrend hochmütig hochnäsig
hochtrabend humorlos humorvoll hyperkorrekt hysterisch hämisch hässlich
häuslich höflich höflichkeitsliebend höhnisch hübsch ichbezogen idealistisch
ideenreich idiotisch ignorant impertinent impulsiv inbrünstig individualistisch
infam infantil initiativ inkompetent inkonsequent innovativ instinktiv integer
intelektuell intelligent intensiv interessiert intolerant intrigant
introvertiert intuitiv ironisch irre jovial jugendlich jung jähzornig
kalkulierend kalt kaltblütig kaltherzig kaltschnäuzig kapriziös kasuistisch
katzig kauzig keck kess ketzerisch keusch kinderlieb kindisch kindlich klar
kleingeistig kleinkariert kleinlaut kleinlich kleinmütig klug knackig knallhart
knickrig kokett komisch kommunikationsfähig kommunikativ kompetent kompliziert
kompromissbereit konfliktfreudig konfliktscheu konkret konsequent konservativ
konsistent konstant kontaktarm kontaktfreudig kontraproduktiv kontrareligiös
kontrolliert konziliant kooperativ kopffrorm kopflastig kordial korrekt korrupt
kosmopolitisch kraftvoll krank kratzbürstig kreativ kriecherisch
kriegstreiberisch kriminell kritisch kritkfähig kräftig kulant kultiviert
kumpelhaft kurios kämpferisch kühl kühn künstlerisch künstlich labil lachhaft
lahm lammfromm langmütig langweilig larmoyant launisch laut lebendig
lebensbejahend lebensfroh lebenslustig lebhaft leicht leichtfertig leichtfüssig
leichtgläubig leichtlebig leichtsinnig leidenschaftlich leidlich leise
leistungsbereit leistungsstark lernbereit lethargisch leutselig liberal lieb
liebenswert liebevoll lieblich lieblos locker loyal lustlos lustvoll
lösungsorientiert lügnerisch lüstern machtbesessen machtgierig machthaberisch
machthungrig mager magisch manipulativ markant martialisch maskulin
masochistisch materialistisch matriachalisch maßlos melancholisch memmenhaft
menschenscheu menschenverachtend merkwürdig mies mild militant mimosenhaft
minimalistisch misanthropisch missgünstig missmutig misstrauisch mitfühlend
mitleiderregend mitleidlos mitleidslos mitteilsam modisch mollig mondän
moralisch motivierend motiviert musikalisch mutig männerfeindlich mürrisch
mütterlich nachdenklich nachgiebig nachlässig nachsichtig nachtragend naiv
naturfreudig naturverbunden natürlich nebulös neckisch negativ neiderfüllt
neidisch nervig nervös nett neugierig neurotisch neutral nichtssagend
niedergeschlagen niederträchtig niedlich nihilistisch nonchalant normal notgeil
nutzlos nüchtern oberflächlich objektiv obszön offen offenherzig
opportunistisch oppositionell optimistisch ordentlich ordinär ordnungsfähig
ordnungsliebend organisiert orientierungslos originell paranoid passiv patent
patriarchisch patriotisch pedantisch pejorativ penibel perfektionistisch
pervers pessimistisch pfiffig pflegeleicht pflichtbewusst pflichtversessen
phantasievoll philanthropisch phlegmatisch phobisch pingelig planlos plump
polarisierend politisch positiv pragmatisch prinzipientreu problembewusst
profilierungssüchtig progressiv prollig promiskuitiv prophetisch protektiv
provokant prüde psychotisch putzig pünktlich qualifiziert quengelig querdenkend
querulant quicklebendig quirlig quälend rabiat rachsüchtig radikal raffiniert
rastlos ratgebend rational ratlos ratsuchend rau reaktionsschnell reaktionär
realistisch realitätsfremd rebellisch rechthaberisch rechtlos rechtschaffend
redegewandt redelustig redselig reflektiert rege reif reiselustig reizbar
reizend reizvoll religiös renitent reserviert resigniert resolut respektlos
respektvoll reumütig rigoros risikofreudig robust romantisch routineorientiert
ruhelos ruhig ruppig rückgratlos rücksichtslos rücksichtsvoll rüde sachlich
sadistisch sanft sanftmütig sanguinisch sardonisch sarkastisch sauertöpfisch
schadenfroh schamlos scheinheilig scheu schlagfertig schlampig schlau
schmeichelhaft schneidig schnell schnippisch schnoddrig schreckhaft schrullig
schullehrerhaft schusselig schwach schweigsam schwermütig schäbig schöngeistig
schüchtern seicht selbstbewusst selbstdarstellerisch selbstgefällig
selbstgerecht selbstherrlich selbstkritisch selbstlos selbstreflektierend
selbstsicher selbstständig selbstsüchtig selbstverliebt selbstzweifelnd seltsam
senil sensationslüstern sensibel sensitiv sentimental seriös sexistisch sexy
sicherheitsbedürftig sinnlich skeptisch skrupellos skurril smart solidarisch
solide sonnig sorgfältig sorglos sorgsam souverän sparsam spaßig spießig
spirituell spitzfindig spontan sportlich sprachbegabt spritzig sprunghaft
spröde spöttisch staatsmännisch stabil stachelig standhaft stark starr
starrköpfig starrsinnig stereotypisch stilbewusst still stilsicher stilvoll
stinkig stoisch stolz strahlend strategisch streberhaft strebsam streitsüchtig
streng strikt stumpf stur sturköpfig störend störrisch stürmisch subjektiv
subtil suchend suchtgefährdet suspekt sympathisch süchtig tadellos taff
tagträumerisch taktisch taktlos taktvoll talentiert tatkräftig tatlos teamfähig
temperamentlos temperamentvoll tiefgründig tierlieb tolerant toll tollkühn
tollpatschig tough transparent traurig treu trotzig träge träumerisch
trübsinnig tyrannisch töricht tüchtig ulkig umgänglich umsichtig umständlich
umtriebig unabhängig unanständig unantastbar unartig unaufrichtig
unausgeglichen unbedeutend unbeherrscht unbeirrbar unbelehrbar unberechenbar
unbeschreiblich unbeschwert unbesonnen unbeständig unbeugsam undankbar
undiszipliniert undurchschaubar undurchsichtig unehrlich uneigennützig uneinig
unentschlossen unerbittlich unerreichbar unerschrocken unerschütterlich
unerträglich unfair unfein unflätig unfolgsam unfreundlich ungeduldig
ungehorsam ungehörig ungerecht ungeschickt ungesellig ungestüm ungewöhnlich
ungezogen ungezügelt unglaubwürdig ungläubig unhöflich unkompliziert
unkonventionell unkonzentriert unmenschlich unnachgiebig unnahbar unordentlich
unparteiisch unproblematisch unpünktlich unrealistisch unreflektiert unruhig
unsachlich unscheinbar unschlüssig unschuldig unselbständig unsensibel unsicher
unstet unternehmungsfreudig unternehmungslustig untertänig unterwürfig untreu
unverschämt unverwechselbar unverzagt unzufrieden unzuverlässig verachtend
verantwortungsbewusst verantwortungslos verantwortungsvoll verbindlich
verbissen verbittert verbrecherisch verfressen verführerisch vergebend
vergesslich verhandlungsstark verharrend verkopft verlangend verletzbar
verletzend verliebt verlogen verlustängstlich verlässlich vermittelnd
vernetzend vernünftig verrucht verräterisch verrückt verschlagen verschlossen
verschmitzt verschroben verschüchtert versiert verspielt versponnen
verständnislos verständnisvoll verstört vertrauensvoll vertrauenswürdig
verträumt verwahrlost verwegen verwirrt verwundert verwöhnt verzweifelt
vielfältig vielschichtig vielseitig vital vorausschauend voreingenommen vorlaut
vornehm vorsichtig vorwitzig väterlich wagemutig waghalsig wahnhaft wahnsinnig
wahnwitzig wahrhaftig wahrheitsliebend wankelmütig warm warmherzig wechselhaft
wehmütig weiblich weich weinselig weise weitsichtig weltfremd weltoffen wendig
wichtigtuerisch widerlich widerspenstig widersprüchlich widerstandsfähig wild
willenlos willensschwach willensstark willig willkürlich wirsch wissbegierig
wissensdurstig witzig wohlerzogen wohlgesinnt wortkarg wählerisch würdelos
würdevoll xanthippisch zaghaft zappelig zartbesaitet zartfühlend zauberhaft
zaudernd zerbrechlich zerdenkend zerknautscht zerstreut zerstörerisch zickig
zielbewusst zielführend zielorientiert zielstrebig zimperlich zufrieden
zugeknöpft zuhörend zukunftsgläubig zupackend zurechnungsfähig zurückhaltend
zuverlässig zuversichtlich zuvorkommend zwanghaft zweifelnd zwiegespalten
zwingend zäh zärtlich zögerlich züchtig ängstlich ätzend öde überdreht
überemotional überfürsorglich übergenau überheblich überkandidelt überkritisch
überlebensfähig überlegen überlegt übermütig überragend überraschend
überreagierend überschwenglich übersensibel überspannt überwältigent}],
# http://www.roleplayingtips.com/tools/1000-npc-traits/
en => [qw{able abrasive abrupt absent minded abusive accepting
accident prone accommodating accomplished action oriented active
adaptable substance abusing adorable adventurous affable affected
affectionate afraid uncommited aggressive agnostic agreeable alert
alluring aloof altruistic always hungry always late ambiguous
ambitious amiable amused amusing angry animated annoyed annoying
anti-social anxious apathetic apologetic appreciative apprehensive
approachable argumentative aristocratic arrogant artistic ashamed
aspiring assertive astonished attentive audacious austere
authoritarian authoritative available average awful awkward babbling
babyish bad bashful beautiful belligerent bewildered biter
blames others blasé blowhard boastful boisterous bold boorish bored
boring bossy boundless brainy brash bratty brave brazen bright
brilliant brotherly brutish bubbly busy calculating callous calm
candid capable capricious carefree careful careless caring caustic
cautious changeable charismatic charming chaste cheerful cheerless
childish chivalrous civilised classy clean clever close closed clumsy
coarse cocky coherent cold cold hearted combative comfortable
committed communicative compassionate competent complacent compliant
composed compulsive conceited concerned condescending confident
confused congenial conscientious considerate consistent constricting
content contented contrarian contrite controlling conversational
cooperative coquettish courageous courteous covetous cowardly cowering
coy crabby crafty cranky crazy creative credible creepy critical cross
crude cruel cuddly cultured curious cutthroat cynical dainty dangerous
daring dark dashing dauntless dazzling debonair deceitful deceiving
decent decisive decorous deep defeated defective deferential defiant
deliberate delicate delightful demanding demonic dependable dependent
depressed deranged despicable despondent detached detailed determined
devilish devious devoted dignified diligent direct disaffected
disagreeable discerning disciplined discontented discouraged discreet
disgusting dishonest disillusioned disinterested disloyal dismayed
disorderly disorganized disparaging disrespectful dissatisfied
dissolute distant distraught distressed disturbed dogmatic domineering
dorky doubtful downtrodden draconian dramatic dreamer dreamy dreary
dubious dull dumb dutiful dynamic eager easygoing eccentric educated
effervescent efficient egocentric egotistic elated eloquent
embarrassed embittered embraces change eminent emotional empathetic
enchanting encouraging enduring energetic engaging enigmatic
entertaining enthusiastic envious equable erratic ethical evasive evil
exacting excellent excessive excitable excited exclusive expansive
expert extravagant extreme exuberant fabulous facetious faded fair
faith in self faithful faithless fake fanatical fanciful fantastic
fatalistic fearful fearless feisty ferocious fidgety fierce fiery
fighter filthy fine finicky flagging flakey flamboyant flashy fleeting
flexible flighty flippant flirty flustered focused foolish forceful
forgetful forgiving formal fortunate foul frank frantic fresh fretful
friendly frightened frigid frugal frustrated fuddy duddy fun
fun loving funny furious furtive fussy gabby garrulous gaudy generous
genial gentle giddy giggly gives up easily giving glamorous gloomy
glorious glum goal orientated good goofy graceful gracious grandiose
grateful greedy gregarious grieving grouchy growly gruesome gruff
grumpy guarded guilt ridden guilty gullible haggling handsome happy
hard hard working hardy harmonious harried harsh hateful haughty
healthy heart broken heartless heavy hearted hedonistic helpful
helpless hesitant high high self esteem hilarious homeless honest
honor bound honorable hopeful hopeless hormonal horrible hospitable
hostile hot headed huffy humble humorous hurt hysterical ignorant ill
ill-bred imaginative immaculate immature immobile immodest impartial
impatient imperial impolite impotent impractical impudent impulsive
inactive incoherent incompetent inconsiderate inconsistent indecisive
independent indifferent indiscrete indiscriminate indolent indulgent
industrious inefficient inept inflexible inimitable innocent
inquisitive insecure insensitive insightful insincere insipid
insistent insolent instinctive insulting intellectual intelligent
intense interested interrupting intimidating intolerant intrepid
introspective introverted intuitive inventive involved irresolute
irresponsible irreverent irritable irritating jackass jaded jealous
jittery joking jolly jovial joyful joyous judgmental keen kenderish
kind hearted kittenish knowledgeable lackadaisical lacking languid
lascivious late lazy leader lean lethargic level lewd liar licentious
light-hearted likeable limited lineat lingering lively logical lonely
loquacious lordly loud loudmouth lovable lovely loves challenge loving
low confidence lowly loyal lucky lunatic lying macho mad malicious
manipulative mannerly materialistic matronly matter-of-fact mature
mean meek melancholy melodramatic mentally slow merciful mercurial
messy meticulous mild mischievous miserable miserly mistrusting modern
modest moody moping moralistic motherly motivated mysterious nagging
naive narcissistic narrow-minded nasty naughty neat
needs social approval needy negative negligent nervous neurotic
never hungry nibbler nice night owl nihilistic nimble nit picker
no purpose no self confidence noble noisy nonchalant nosy
not trustworthy nuanced nuisance nurturing nut obedient obese obliging
obnoxious obscene obsequious observant obstinate odd odious open
open-minded opinionated opportunistic optimistic orcish orderly
organized ornery ossified ostentatious outgoing outrageous outspoken
overbearing overweight overwhelmed overwhelming paces pacifistic
painstaking panicky paranoid particular passionate passive
passive-aggressive pathetic patient patriotic peaceful penitent
pensive perfect perfectionist performer perserverant perseveres
persevering persistent persuasive pert perverse pessimistic petty
petulant philanthropic picky pious pitiful placid plain playful
pleasant pleasing plotting plucky polite pompous poor popular positive
possessive practical precise predictable preoccupied pretentious
pretty prim primitive productive profane professional promiscuous
proper protective proud prudent psychotic puckish punctilious punctual
purposeful pushy puzzled quarrelsome queer quick quick tempered quiet
quirky quixotic rambunctious random rash rational rawboned realistic
reasonable rebellious recalcitrant receptive reckless reclusive
refined reflective regretful rejects change relaxed relents reliable
relieved religious reluctant remorseful repugnant repulsive resentful
reserved resilient resolute resourceful respectful responsible
responsive restless retiring rhetorical rich right righteous rigid
risk-taking romantic rough rowdy rude rugged ruthless sacrificing sad
sadistic safe sagely saintly salient sanctimonious sanguine sarcastic
sassy satisfied saucy savage scared scarred scary scattered scheming
scornful scrawny scruffy secretive secure sedate seductive selective
self-centered self-confident self-conscious self-controlling
self-directed self-disciplined self-giving self-reliant self-serving
selfish selfless senile sensitive sensual sentimental serene serious
sexual sexy shallow shameless sharp sharp-tongued sharp-witted
sheepish shiftless shifty short shrewd shy silent silky silly simian
simple sincere sisterly skillful sleazy sloppy slovenly slow paced
slutty sly small-minded smart smiling smooth sneaky snob sociable
soft-hearted soft-spoken solitary sore sorry sour spendthrift spiteful
splendid spoiled spontaneous spunky squeamish stately static steadfast
sterile stern stimulating stingy stoical stolid straight laced strange
strict strident strong strong willed stubborn studious stupid suave
submissive successful succinct sulky sullen sultry supercilious
superstitious supportive surly suspicious sweet sympathetic systematic
taciturn tacky tactful tactless talented talkative tall tardy tasteful
temperamental temperate tenacious tense tentative terrible terrified
testy thankful thankless thick skinned thorough thoughtful thoughtless
threatening thrifty thrilled tight timid tired tireless tiresome
tolerant touchy tough trivial troubled truculent trusting trustworthy
truthful typical ugly unappreciative unassuming unbending unbiased
uncaring uncommitted unconcerned uncontrolled unconventional
uncooperative uncoordinated uncouth undependable understanding
undesirable undisciplined unenthusiastic unfeeling unfocused
unforgiving unfriendly ungrateful unhappy unhelpful uninhibited unkind
unmotivated unpredictable unreasonable unreceptive unreliable
unresponsive unrestrained unruly unscrupulous unselfish unsure
unsympathetic unsystematic unusual unwilling upbeat upset uptight
useful vacant vague vain valiant vengeful venomous verbose versatile
vigorous vindictive violent virtuous visual vivacious volatile
voracious vulgar vulnerable warlike warm hearted wary wasteful weak
weary weird well grounded whimsical wholesome wicked wild willing wise
wishy washy withdrawn witty worldly worried worthless wretched
xenophobic youthful zany zealous}], };

# one way to test this on the command-line:
# perl halberdsnhelmets.pl get --redirect /characters | w3m -T text/html

sub name {
  my ($class, $name) = @_;
  if ($class eq T('halfling')) { return halfling_name($name) }
  elsif  ($class eq T('elf')) { return elf_name($name) }
  elsif  ($class eq T('dwarf')) { return dwarf_name($name) }
  return human_name($name);
}

sub traits {
  my ($char, $language) = @_;
  local $lang = $language; # make sure T works as intended
  my $description = $char->{name} . ", ";
  my $d;
  if ($char->{gender} eq "F") {
    $d = d3();
  } elsif ($char->{gender} eq "M") {
    $d = 3 + d3();
  } else {
    $d = d6();
  }
  if ($d == 1) {
    $description .= T('young woman');
  } elsif ($d == 2) {
    $description .= T('woman');
  } elsif ($d == 3) {
    $description .= T('elderly woman');
  } elsif ($d == 4) {
    $description .= T('young man');
  } elsif ($d == 5) {
    $description .= T('man');
  } elsif ($d == 6) {
    $description .= T('elderly man');
  };
  $description .= ", ";
  my $trait = one(@{$traits->{$lang}});
  $description .= $trait;
  my $other = one(@{$traits->{$lang}});
  if ($other ne $trait) {
    $description .= " " . T('and') . " " . $other;
  }
  provide($char, "traits", $description);
}

sub random {
  my $char = shift;
  # keys that can be provided: name, class, charsheet

  my $class = $char->{class};

  my ($str, $dex, $con, $int, $wis, $cha) =
      $class eq T('hireling') || $class eq T('porter')
      ? (10, 10, 10, 10, 10, 10)
      : (roll_3d6(), roll_3d6(), roll_3d6(),
	 roll_3d6(), roll_3d6(), roll_3d6());

  # if a class is provided, make sure minimum requirements are met
  if ($class eq T('dwarf')) {
    $con = roll_3d6() until average($con);
  }
  if ($class eq T('elf')) {
    $int = roll_3d6() until average($int);
  }
  if ($class eq T('halfling')) {
    $con = roll_3d6() until average($con);
    $dex = roll_3d6() until average($dex);
  }

  provide($char, "str", $str);
  provide($char, "dex", $dex);
  provide($char, "con", $con);
  provide($char, "int", $int);
  provide($char, "wis", $wis);
  provide($char, "cha", $cha);

  provide($char, "xp",  "0");

  if ($class eq T('hireling') or $class eq T('porter')) {
    provide($char, "level",  "0");
    provide($char, "thac0",  20);
  } else {
    provide($char, "level",  "1");
    provide($char, "thac0",  19);
  }

  my $best = best($str, $dex, $con, $int, $wis, $cha);

  if (not $class) {
    if (average($con) and $best eq "str") {
      $class = T('dwarf');
    } elsif (average($int)
	     and good($str, $dex)
	     and d6() > 2) {
      $class = T('elf');
    } elsif (average($str, $dex, $con) == 3
	     and good($str, $dex, $con)
	     and d6() > 2) {
      $class = T('halfling');
    } elsif (average($str, $dex, $con) >= 2
	     and ($best eq "str" or $best eq "con")
	     or good($str, $dex, $con) >= 2) {
      $class = T('fighter');
    } elsif ($best eq "int") {
      $class = T('magic-user');
    } elsif ($best eq "dex") {
      $class = T('thief');
    } else {
      my @candidates = (T('thief'), T('magic-user'), T('fighter'));
      $class = one(@candidates);
    }
  }

  provide($char, "class",  $class);

  unless ($char->{name}) {
    my ($name, $gender) = name($class);
    provide($char, "name", $name);
    $char->{gender} = $gender; # don't put it on the character sheet
  }

  unless ($char->{gender}) {
    my ($name, $gender) = name($class, $char->{name});
    $char->{gender} = $gender; # don't put it on the character sheet
  }

  if ($class eq T('halfling')) {
    provide($char, "range-thac0",  18 - bonus($dex));
  }


  my $level = $char->{level};
  my $hp = $char->{hp};
  if (not $hp) {
    if ($class eq T('fighter') or $class eq T('dwarf')) {
      $hp += max(1, d8() + bonus($con)) for 1.. $level;
    } elsif ($class eq T('elf') or $class eq T('halfling')) {
      $hp += max(1, d6() + bonus($con)) for 1.. $level;
    } else {
      $hp += max(1, d4() + bonus($con)) for 1.. $level;
    }
  }
  provide($char, "hp",  $hp);

  equipment($char);

  my $abilities = abilities($char);
  # spellbook
  if ($class eq T('magic-user') or $class eq T('elf')) {
    $abilities .= "\\\\" . spellbook();
  }

  provide($char, "abilities", $abilities);

  if (not $char->{charsheet}) {
    if ($class eq T('hireling') or $class eq T('porter')) {
      provide($char, "charsheet", T('Hireling.svg'));
    } elsif ($char->{landscape}) {
      provide($char, "charsheet", T('Charactersheet-landscape.svg'));
    } else {
      provide($char, "charsheet", T('Charactersheet.svg'));
    }
  }
}

sub abilities {
  my $char = shift;
  my $class = $char->{class};
  my $abilities = T('1/6 for normal tasks');
  if ($class eq T('elf')) {
    $abilities .= "\\\\" . T('2/6 to hear noise');
    $abilities .= "\\\\" . T('2/6 to find secret or concealed doors');
  } elsif ($class eq T('dwarf')) {
    $abilities .= "\\\\" . T('2/6 to hear noise');
    $abilities .= "\\\\" . T('2/6 to find secret constructions and traps');
  } elsif ($class eq T('halfling')) {
    $abilities .= "\\\\" . T('2/6 to hear noise');
    $abilities .= "\\\\" . T('2/6 to hide and sneak');
    $abilities .= "\\\\" . T('5/6 to hide and sneak outdoors');
    $abilities .= "\\\\" . T('+1 bonus to ranged weapons');
    $abilities .= "\\\\" . T('AC -2 vs. opponents larger than humans');
  } elsif ($class eq T('thief')) {
    my $level = $char->{level};
    my $n = 2 + int($char->{level} / 3);
    $n = 5 if $n > 5;
    # override the 1/6 for normal tasks
    $abilities = sprintf(T('%d/6 for all activities'), $n);
    $abilities .= "\\\\" . T('+4 to hit and double damage backstabbing');
  }
  return $abilities;
}

sub classes {
  return {
    T('dwarf') => "D",
	T('elf') => "E",
	T('halfling') => "H",
	T('fighter') => "F",
	T('magic-user') => "M",
	T('thief') => "T",
  };
}

sub random_parameters {
  my ($char, $language) = @_;
  local $lang = $language; # make sure T works as intended
  random($char);
  # choose a random portrait based on the character gender or class
  if (member("portrait", @_)) {
    provide($char, "portrait", portrait($char)) unless $char->{portrait};
  }
}

sub portrait {
  my $char = shift;
  my $face_generator_url = app->config("face_generator_url") or return '';
  my $gender = $char->{gender};
  if ($char->{class} eq T('elf')
      or $char->{race} eq T('elf')) {
    $gender = "elf";
  } elsif ($char->{class} eq T('dwarf')
      or $char->{race} eq T('dwarf')) {
    $gender = "dwarf";
  } elsif ($gender eq "F") {
    $gender = "woman";
  } elsif ($gender eq "M") {
    $gender = "man";
  } else {
    $gender = one("woman", "man");
  }
  my $url = Mojo::URL->new("$face_generator_url/redirect/alex/$gender");
  my $ua = Mojo::UserAgent->new;
  my $tx = $ua->get($url);
  if ($tx->res->code == 302) {
    $url->path($tx->res->headers->location);
  } else {
    $log->warn("Did you configure the face_generator_url setting in the config file correctly? "
	       . "It is currently set to $face_generator_url. "
	       . ($tx->res->code
		  ? "It returns: " . $tx->res->code . " " . $tx->res->message
		  : "The error: " . $tx->res->error->{message}));
  }
  return $url;
}

sub characters {
  my ($char, $lang) = @_;
  my @characters;
  for (my $i = 0; $i < 50; $i++) {
    my %one = %$char; # defaults
    random_parameters(\%one, $lang);
    traits(\%one, $lang);
    push(@characters, \%one);
  }
  return \@characters;
}

sub stats {
  my ($char, $language, $n) = @_;
  local $lang = $language; # make sure T works as intended
  my (%class, %property);
  for (my $i = 0; $i < $n; $i++) {
    my %one = %$char; # defaults
    random_parameters(\%one, $lang);
    $class{$one{class}}++;
    foreach (split(/\\\\/, $one{property})) {
      $property{$_}++;
    }
  }

  $n = 0;
  my $txt = T('Classes') . "\n";
  foreach (sort { $class{$b} <=> $class{$a} } keys %class) {
    $txt .= sprintf "%25s %4d\n", $_, $class{$_};
    $n += $class{$_};
  }
  $txt .= sprintf "%25s %4d\n", "total", $n;

  $txt .= T('Property') . "\n";
  foreach (sort { $property{$b} <=> $property{$a} }
	   keys %property) {
    next if /starting gold:/ or /gold$/;
    next if /Startgold:/ or /Gold$/;
    $txt .= sprintf "%25s %4d\n", $_, $property{$_};
  }
  return $txt;
}

sub url_encode {
  my $str = shift;
  return '' unless defined $str;
  utf8::encode($str);
  my @letters = split(//, $str);
  my %safe = map {$_ => 1} ("a" .. "z", "A" .. "Z", "0" .. "9", "-", "_", ".", "!", "~", "*", "\"", "(", ")", "#");
  foreach my $letter (@letters) {
    $letter = sprintf("%%%02x", ord($letter)) unless $safe{$letter};
  }
  return join('', @letters);
}

sub init {
  my $self = shift;
  my %char = %{$self->req->params->to_hash};
  my @provided; # We want to remember the order!
  my @pairs = @{$self->req->params->pairs};
  while (@pairs) {
    my $key = shift @pairs;
    my $value = shift @pairs;
    push(@provided, $key);
  }
  $char{provided} = \@provided;
  return \%char;
}

sub lang {
  my $self = shift;
  my $acceptor = I18N::AcceptLanguage->new(defaultLanguage => "en");
  return $acceptor->accepts($self->req->headers->accept_language, [qw(en de)]);
}

plugin "Config" => {default => {}};

get "/" => sub {
  my $self = shift;
  $self->redirect_to($self->url_with("main" => {lang => lang($self)}));
};

get "/:lang" => [lang => qr/(?:en|de)/] => sub {
  my $self = shift;
  my $lang = $self->param("lang");
  my $query = $self->req->query_params->to_string;
  if ($query) {
    # deprecated
    $query =~ tr/;/&/;
    my $params = Mojo::Parameters->new($query);
    return $self->redirect_to($self->url_for("char" => {lang => $lang})->query(@$params));
  }
  $self->render(template => "index.$lang");
} => "main";

get "/help" => "help";

get "/hilfe" => "hilfe";

get "/random" => sub {
  my $self = shift;
  $self->redirect_to($self->url_with("random" => {lang => lang($self)}));
};

get "/random/text/:lang" => sub {
  my $self = shift;
  my $char = init($self);
  my $lang = $self->param("lang");
  random_parameters($char, $lang, "portrait");
  compute_data($char, $lang);
  $self->render(template => "text.$lang",
		format => "txt",
		char => $char);
} => "text";

get "/random/:lang" => [lang => qr/(?:en|de)/] => sub {
  my $self = shift;
  my $char = init($self);
  my $lang = $self->param("lang");
  random_parameters($char, $lang, "portrait");
  compute_data($char, $lang);
  my $svg = svg_transform($self, svg_read($char));
  $self->render(format => "svg",
		data => $svg->toString());
} => "random";

get "/char" => sub {
  my $self = shift;
  $self->redirect_to($self->url_with("char" => {lang => lang($self)}));
};

get "/char/:lang" => [lang => qr/(?:en|de)/] => sub {
  my $self = shift;
  my $char = init($self);
  my $lang = $self->param("lang");
  # no random parameters
  compute_data($char, $lang);
  my $svg = svg_transform($self, svg_read($char));
  $self->render(format => "svg",
		data => $svg->toString());
} => "char";

# deprecated
get "/link/:lang" => [lang => qr/(?:en|de)/] => sub {
  my $self = shift;
  my $lang = $self->param("lang");
  my $query = $self->req->query_params;
  $query =~ tr/;/&/;
  my $params = Mojo::Parameters->new($query);
  $self->redirect_to($self->url_for("edit" => {lang => lang($self)})->query(@$params));
};

get "/edit" => sub {
  my $self = shift;
  $self->redirect_to(edit => {lang => lang($self)});
};

get "/edit/:lang" => [lang => qr/(?:en|de)/] => sub {
  my $self = shift;
  my $char = init($self);
  my $lang = $self->param("lang");
  $self->render(template => "edit.$lang",
		char => $char);
} => "edit";

get "/redirect" => sub {
  my $self = shift;
  $self->redirect_to($self->url_with("redirect" => {lang => lang($self)}));
};

get "/redirect/:lang" => [lang => qr/(?:en|de)/] => sub {
  my $self = shift;
  my $lang = $self->param("lang");
  my $input = $self->param("input");
  my $params = Mojo::Parameters->new;
  my $last;
  while ($input =~ /^([-a-z0-9]*): *(.*?)\r?$/gm) {
    if ($1 eq $last or $1 eq "") {
      $params->param($1 => $params->param($1) . "\\\\$2");
    } else {
      $params->append($1 => $2);
      $last = $1;
    }
  }
  $self->redirect_to($self->url_for("char" => {lang => $lang})->query($params));
} => "redirect";


get "/show" => sub {
  my $self = shift;
  my $char = init($self);
  my $svg = svg_show_id(svg_read($char));
  $self->render(format => "svg",
		data => $svg->toString());
} => "show";

get "/characters" => sub {
  my $self = shift;
  $self->redirect_to($self->url_with("characters" => {lang => lang($self)}));
};

get "/characters/:lang" => [lang => qr/(?:en|de)/] => sub {
  my $self = shift;
  my $lang = $self->param("lang");
  my $char = init($self);
  $self->render(template => "characters.$lang",
		width => "100%",
		characters => characters($char, $lang));
} => "characters";

get "/stats" => sub {
  my $self = shift;
  $self->redirect_to($self->url_with("stats" => {lang => lang($self),
						 n => 100}));
};

get "/stats/:n" => [n => qr/\d+/] => sub {
  my $self = shift;
  my $n = $self->param("n");
  $self->redirect_to($self->url_with("stats" => {lang => lang($self),
						 n => $n}));
};

get "/stats/:lang" => [lang => qr/(?:en|de)/] => sub {
  my $self = shift;
  my $lang = $self->param("lang");
  $self->redirect_to($self->url_with("stats" => {lang => $lang,
						 n => 100}));
};

get "/stats/:lang/:n" => [lang => qr/(?:en|de)/, n => qr/\d+/] => sub {
  my $self = shift;
  my $lang = $self->param("lang");
  my $n = $self->param("n");
  my $char = init($self);
  $self->render(format => "txt",
		text => stats($char, $lang, $n));
} => "stats";

app->secrets([app->config("secret")]) if app->config("secret");

app->start;

__DATA__

@@ index.en.html.ep
% layout "default.en";
% title "Character Sheet Generator";
<h1>Character Sheet Generator</h1>

<p>

This is the <a href="https://alexschroeder.ch/wiki/Halberds_and_Helmets">Halberds and Helmets</a>
Character Sheet Generator.
Reload the character sheet to generate more 1<sup>st</sup> level characters.

Feel free to provide a name for your random character!

%= form_for random => begin
%= label_for name => "Name:"
%= text_field "name"
%= label_for class => "Class:"
%= select_field class => ['', qw(fighter magic-user thief elf halfling dwarf hireling porter)]
%= check_box "landscape"
%= label_for landscape => "landscape"
%= submit_button
% end

<p>
The character sheet contains a link in the bottom right corner which allows you
to bookmark and edit your character. <%= link_to "Learn more…" => "help" %>

<p>
If you're looking for an alternative, check out the
<a href="http://character.totalpartykill.ca/">Random D&D Character Generator</a>
by <a href="http://save.vs.totalpartykill.ca/">Ramanan Sivaranjan</a>.

@@ index.de.html.ep
% layout "default.de";
% title "Character Sheet Generator";
<h1>Charakterblatt Generator</h1>

<p>
Dies ist der <a href="https://alexschroeder.ch/wiki/Hellebarden_%26_Helme">Hellebarden und Helme</a>
Charaktergenerator.
Um weitere Charaktere der ersten Stufe zu generieren, kann man die Seite einfach neu laden.

Wer will, kann dem generierten Charakter hier auch einen Namen geben:

%= form_for random => begin
%= label_for name => "Name:"
%= text_field "name"
%= label_for class => "Klasse:"
%= select_field class => ['', qw(Krieger Magier Dieb Elf Halbling Zwerg Mietling Träger)]
%= check_box "landscape"
%= label_for landscape => "Querformat"
%= submit_button
% end

<p>
Auf dem generierten Charakterblatt hat es unten rechts einen Link mit dem man
sich ein Lesezeichen erstellen kann und wo der Charakter bearbeitet werden kann.
<%= link_to "Weiterlesen…" => "hilfe" %>

<p>
Eine englische Alternative wäre der
<a href="http://character.totalpartykill.ca/">Random D&D Character Generator</a>
von <a href="http://save.vs.totalpartykill.ca/">Ramanan Sivaranjan</a>.


@@ edit.en.html.ep
% layout "default.en";
% title "Link (Character Sheet Generator)";
<h1>A Link For Your Character</h1>

<h2>Bookmark</h2>

<p>
Bookmark the following link to your
<%= link_to url_for("char")->query($self->req->params) => begin %>Character Sheet<% end %>.

<h2>Edit</h2>

<p>
Use the following form to make changes to your character sheet. You can also
copy and paste it on to a <a href="https://campaignwiki.org/">Campaign Wiki</a>
page to generate an inline character sheet.

%= form_for url_for("redirect" => {lang => $lang}) => begin
%= hidden_field lang => $lang
%= text_area "input" => (cols => 72, rows => 20) => begin
<% for my $key (@{$char->{provided}}) { %>\
<%   for my $value (split(/\\\\/, $char->{$key})) { =%>\
<%= $key =%>: <%= $value %>
<%   } %>\
<% } %>\
% end
<p>
%= submit_button
% end


@@ edit.de.html.ep
% layout "default.de";
% title "Edit Your Character";
<h1>Ein Link für deinen Charakter</h1>

<h2>Lesezeichen</h2>

<p>
Den Charakter kann man einfach aufbewahren, in dem man sich den Link auf
<%= link_to url_for("char")->query($self->req->params) => begin %>Charakterblatt<% end %>
als Lesezeichen speichert.

<h2>Bearbeiten</h2>

<p>
Mit dem folgenden Formular lassen sich leicht Änderungen am Charakter machen.
Man kann diesen Text auch auf einer <a href="https://campaignwiki.org/">Campaign
Wiki</a> Seite verwenden, um das Charakterblatt einzufügen.

%= form_for url_for("redirect" => {lang => $lang}) => begin
%= text_area "input" => (cols => 72, rows => 20) => begin
<% for my $key (@{$char->{provided}}) { %>\
<%   for my $value (split(/\\\\/, $char->{$key})) { =%>\
<%= $key =%>: <%= $value %>
<%   } %>\
<% } %>\
% end
<p>
%= submit_button
% end

@@ text.en.txt.ep
Character:
<% for my $key (@{$char->{provided}}) { %>\
<%   for my $value (split(/\\\\/, $char->{$key})) { =%>\
<%= $key =%>: <%= $value %>
<%   } %>\
<% } %>\

@@ text.de.txt.ep
Charakter:
<% for my $key (@{$char->{provided}}) { %>\
<%   for my $value (split(/\\\\/, $char->{$key})) { =%>\
<%= $key =%>: <%= $value %>
<%   } %>\
<% } %>\

@@ characters.html.ep
<% for my $char (@{$characters}) { %>
<div class="char">
<p><%= $char->{traits} %><br/></p>
<table>
<tr><th>Str</th><th>Dex</th><th>Con</th><th>Int</th><th>Wis</th><th>Cha</th><th>HP</th><th>AC</th><th>Class</th></tr>
<tr>\
<td class="num"><%= $char->{str} %></td>\
<td class="num"><%= $char->{dex} %></td>\
<td class="num"><%= $char->{con} %></td>\
<td class="num"><%= $char->{int} %></td>\
<td class="num"><%= $char->{wis} %></td>\
<td class="num"><%= $char->{cha} %></td>\
<td class="num"><%= $char->{hp} %></td>\
<td class="num"><%= $char->{ac} %></td>\
<td><%= $char->{class} %></td></tr>
</table>
<p><%= join(", ", split(/\\\\/, $char->{property})) %></p>
</div>
<% } %>
<div style="clear: both"></div>

@@ characters.en.html.ep
% layout "default.en";
% title "Characters";
<h1>A Bunch of Characters</h1>
%= include "characters"

@@ characters.de.html.ep
% layout "default.de";
% title "Charaktere";
<h1>Einige Charaktere</h1>
%= include "characters"


@@ hilfe.html.ep
% layout "default.de";
% title "Hilfe (Charakterblatt Generator)";
<h1>Charakterblatt Generator</h1>

<p>Das funktioniert über eine Vorlage und dem Ersetzen von Platzhaltern.

<p>Die
<%= link_to url_for("char" => {lang => "de"})->query(charsheet => "Charakterblatt.svg") => begin %>Defaultvorlage<% end %>
(<%= link_to url_for("char" => {lang => "de"})->query(charsheet => "Charakterblatt-quer.svg") => begin %>Querformat<% end %>, <%= link_to url_for("char" => {lang => "de"})->query(charsheet => "Charakterblatt-adv.svg") => begin %>Alternative<% end %>)
verwendet die <a href="/Purisa.ttf">Purisa</a> Schrift. Den Platzhaltern werden
über URL Parameter Werte zugewiesen
(<%= link_to url_for("char" => {lang => "de"})->query(name => "Tehah", class => "Elf", level => "1", xp => "100", ac => "9", hp => "5", str => "15", dex => "9", con => "15", int => "10", wis => "9", cha => "7", breath => "15", poison => "12", petrify => "13", wands => "13", spells => "15", property => "Zauberbuch (Gerdana)\\\\* Einschläferndes Rauschen", abilities => "Ghinorisch\\\\Elfisch", thac0 => "19", charsheet => "Charakterblatt.svg") => begin %>Beispiel<% end %>,
<%= link_to url_for("char" => {lang => "de"})->query(name => "Tehah", class => "Elf", level => "1", xp => "100", ac => "9", hp => "5", str => "15", dex => "9", con => "15", int => "10", wis => "9", cha => "7", breath => "15", poison => "12", petrify => "13", wands => "13", spells => "15", property => "Zauberbuch (Gerdana)\\\\* Einschläferndes Rauschen", languages => "Ghinorisch\\\\Elfisch", abilities => "Geheimtüren entdecken 2/6\\\\Geräusche hören 2/6\\\\Schlaf", thac0 => "19", charsheet=>"Charakterblatt-quer.svg") => begin %>Querformat<% end %>,
<%= link_to url_for("char" => {lang => "de"})->query(name => "Tehah", class => "Elf", level => "1", xp => "100", ac => "9", hp => "5", str => "15", dex => "9", con => "15", int => "10", wis => "9", cha => "7", breath => "15", poison => "12", petrify => "13", wands => "13", spells => "15", property => "Zauberbuch (Gerdana)\\\\* Einschläferndes Rauschen", languages => "Ghinorisch\\\\Elfisch", abilities => "Geheimtüren entdecken 2/6\\\\Geräusche hören 2/6\\\\Schlaf", misc => "“Dwarf-friend”", thac0 => "19", charsheet=>"Charakterblatt-adv.svg") => begin %>Alternative<% end %>).
Das Skript kann auch zeigen
<%= link_to url_for("show")->query(charsheet=>"Charakterblatt.svg") => begin %>welche Parameter wo erscheinen<% end %>
(<%= link_to url_for("show")->query(charsheet=>"Charakterblatt-quer.svg") => begin %>Querformat<% end %>, <%= link_to url_for("show")->query(charsheet=>"Charakterblatt-adv.svg") => begin %>Alternative<% end %>).
Die Parameter müssen UTF-8 codiert sein. Die Vorlage kann auch mehrzeilige
Platzhalter enthalten. Der entsprechende Parameter muss die Zeilen dann durch
doppelte Backslashes trennen.

<p>
Zudem werden einige Parameter berechnet, sofern sie nicht
angegeben wurden:

<ul>
<li>str → str-bonus
<li>dex → dex-bonus
<li>con → con-bonus
<li>int → int-bonus
<li>wis → wis-bonus
<li>cha → cha-bonus
<li>cha-bonus → loyalty
<li>str-bonus → damage
<li>thac0 → melee-thac0
<li>melee-thac0 → melee0-9
<li>damage → melee-damage
<li>thac0 → range-thac0
<li>range-thac0 → range0-9
<li>thac0 → other-thac0
<li>other-thac0 → range0-9
<li>damage → range-damage
</ul>

<p>
Das Skript kann auch
<%= link_to url_for("random" => {lang => "de"}) => begin %>einen zufälligen Charakter<% end %>,
<%= link_to url_for("random" => {lang => "de"})->query(class=>"Mietling") => begin %>zufällligen Mietling<% end %>,
<%= link_to url_for("random" => {lang => "de"})->query(class=>"Träger") => begin %>zufälligen Träger<% end %>,
<%= link_to url_for("characters" => {lang => "de"}) => begin %>einige Charaktere<% end %>,
oder <%= link_to url_for("stats" => {lang => "de"}) => begin %>Statistiken<% end %>
generieren.


@@ help.html.ep
% layout "default.en";
% title "Help (Character Sheet Generator)";
<h1>Character Sheet Generator</h1>

<p>The generator works by using a template and replacing some placeholders.

<p>The
<%= link_to url_for("char" => {lang => "en"}) => begin %>default template<% end %>
(<%= link_to url_for("char" => {lang => "en"})->query(charsheet=>"Charactersheet-landscape.svg") => begin %>landscape<% end %>, <%= link_to url_for("char" => {lang => "en"})->query(charsheet=>"Charactersheet-adv.svg") => begin %>alternative<% end %>)
uses the <a href="/Purisa.ttf">Purisa</a> font. You provide values for the
placeholders by providing URL parameters
(<%= link_to url_for("char" => {lang => "en"})->query(name => "Tehah", class => "Elf", level => "1", xp => "100", ac => "9", hp => "5", str => "15", dex => "9", con => "15", int => "10", wis => "9", cha => "7", breath => "15", poison => "12", petrify => "13", wands => "13", spells => "15", property => "Spell Book (Gerdana)\\\\* sleepy swoosh", abilities => "Ghinorian\\\\Elven", thac0 => "19", charsheet => "Charactersheet.svg") => begin %>example<% end %>,
<%= link_to url_for("char" => {lang => "en"})->query(name => "Tehah", class => "Elf", level => "1", xp => "100", ac => "9", hp => "5", str => "15", dex => "9", con => "15", int => "10", wis => "9", cha => "7", breath => "15", poison => "12", petrify => "13", wands => "13", spells => "15", property => "Spell Book (Gerdana)\\\\* sleepy swoosh", languages => "Ghinorian\\\\Elven", abilities => "Spot secret doors 2/6\\\\Hear noise 2/6\\\\Sleep", misc => "“Dwarf-friend”", thac0 => "19", charsheet=>"Charactersheet-landscape.svg") => begin %>landscape<% end %>,
<%= link_to url_for("char" => {lang => "en"})->query(name => "Tehah", class => "Elf", level => "1", xp => "100", ac => "9", hp => "5", str => "15", dex => "9", con => "15", int => "10", wis => "9", cha => "7", breath => "15", poison => "12", petrify => "13", wands => "13", spells => "15", property => "Spell Book (Gerdana)\\\\* sleepy swoosh", languages => "Ghinorian\\\\Elven", abilities => "Spot secret doors 2/6\\\\Hear noise 2/6\\\\Sleep", misc => "“Dwarf-friend”", thac0 => "19", charsheet=>"Charactersheet-adv.svg") => begin %>alternative<% end %>).
The script can also show
<%= link_to url_for("show")->query(charsheet=>"Charactersheet.svg") => begin %>which parameters go where<% end %>
(<%= link_to url_for("show")->query(charsheet=>"Charactersheet-landscape.svg") => begin %>landscape<% end %>, <%= link_to url_for("show")->query(charsheet=>"Charactersheet-adv.svg") => begin %>alternative<% end %>).
Also note that the parameters need to be UTF-8 encoded. If the
template contains a multiline placeholder, the parameter may also provide
multiple lines separated by two backslashes.

<p>
In addition to that, some parameters are computed unless provided:

<ul>
<li>str → str-bonus
<li>dex → dex-bonus
<li>con → con-bonus
<li>int → int-bonus
<li>wis → wis-bonus
<li>cha → cha-bonus
<li>cha-bonus → loyalty
<li>str-bonus → damage
<li>thac0 → melee-thac0
<li>melee-thac0 → melee0-9
<li>damage → melee-damage
<li>thac0 → range-thac0
<li>range-thac0 → range0-9
<li>damage → range-damage
</ul>

<p>
The script can also generate a
<%= link_to url_for("random" => {lang => "en"}) => begin %>random character<% end %>,
<%= link_to url_for("random" => {lang => "en"})->query(class=>"hireling") => begin %>random hireling<% end %>,
<%= link_to url_for("random" => {lang => "en"})->query(class=>"porter") => begin %>random porter<% end %>,
<%= link_to url_for("characters" => {lang => "en"}) => begin %>bunch of characters<% end %>
or <%= link_to url_for("stats" => {lang => "en"}) => begin %>some statistics<% end =%>.


@@ default.html.ep
<!DOCTYPE html>
<html>
<head>
<title><%= title %></title>
%= stylesheet "/halberdsnhelmets/default.css"
%= stylesheet begin
body { padding: 1em; width: <%= $self->stash("width")||"80ex" %>; font-family: "Palatino Linotype", "Book Antiqua", Palatino, serif }
textarea { width: 100% }
.char { page-break-inside: avoid; display: block; float: left; height: 13em; width: 20em; margin-bottom: 1em; margin-right: 1em; }
.num { text-align: center; }
.char th { font-weight: normal; text-align: left; }
.char p { margin: 0; }
% end
<meta name="viewport" content="width=device-width">
</head>
<body>
<%= content %>
<%= content "footer" %>
</body>
</html>

@@ layouts/default.en.html.ep
% content_for footer => begin
<div class="footer">
<hr>
<p>
<%= link_to url_for("main" => {lang => "en"}) => begin %>Character Generator<% end %> &nbsp;
<%= link_to Help => "help" %> &nbsp;
<a href="https://alexschroeder.ch/wiki/Contact">Alex Schroeder</a> &nbsp;
<a href="https://alexschroeder.ch/cgit/character-sheet-generator/about/">Source</a> &nbsp;
<%= link_to url_for("main" => {lang => "de"}) => begin %>German<% end %>
</div>
% end
%= include "default"

@@ layouts/default.de.html.ep
% content_for footer => begin
<div class="footer">
<hr>
<p>
<%= link_to url_for("main" => {lang => "de"}) => begin %>Charakterblatt Generator<% end %> &nbsp;
<%= link_to Hilfe => "hilfe" %> &nbsp;
<a href="https://alexschroeder.ch/wiki/Contact">Alex Schroeder</a> &nbsp;
<a href="https://alexschroeder.ch/cgit/character-sheet-generator/about/">Source</a> &nbsp;
<%= link_to url_for("main" => {lang => "en"}) => begin %>English<% end %>
</div>
% end
%= include "default"
