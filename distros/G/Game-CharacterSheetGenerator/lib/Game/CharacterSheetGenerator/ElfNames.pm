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

Game::CharacterSheetGenerator::ElfName - return a elf name

=head1 SYNOPSIS

    use Game::CharacterSheetGenerator::ElfName qw(elf_name);
    # returns both $name and $gender (F, M, or ?)
    my ($name, $gender) = elf_name();
    # returns the same name and its gender
    ($name, $gender) = elf_name("Alex");

=head1 DESCRIPTION

This package has one function that returns a elf name and a gender. The gender
returned is "M", "F", or "?".

If a name is provided, the gender is returned.

=cut

package Game::CharacterSheetGenerator::ElfNames;
use Modern::Perl;
use utf8;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(elf_name);

sub one {
  my $i = int(rand(scalar @_));
  return $_[$i];
}

# Sindarin-English & English-Sindarin Dictionary, J-M Carpenter (2017)
# https://realelvish.net/names/sindarin/woodelf/all/
# https://sindarinlessons.weebly.com/36---how-to-make-names-1.html
# https://sindarinlessons.weebly.com/37---how-to-make-names-2.html

my @prefix =
    qw(achar adertha adleg al amartha aníra aphada ar ava awartha badh batha
       beria blab brenia brona buia cab can car carpha cen critha dartha delia
       dew díhena doltha drava drega dringa echad edledhia egleria eitha elia
       ercha ertha fantha fara feira feria fuia gad gala gir gladh glavra
       glintha glir gohena gonod gor gosta groga gruitha gwatha gwathra gweria
       gwesta had hal haltha hamma harna hasta henia hwinia ialla ídha ídhra
       ista iuitha laba lala lamma lasta lathra linna luitha mel metha mista nag
       nalla nara narcha ndag ndagra ndamma nde nedia negra neitha nella nesta
       ngal nganna nod nor northa orthel orthor osgar pad padra ped pel per puia
       rada ran reda redh reitha reth rhib rista ritha rosta ruthra síla sog
       suila teilia teitha telia theria thilia thora thosta tintha tir toba
       toltha tortha trasta trevad tuia);

my @word =
    qw(abonthen achad adan agar agarwen aglar aglareb agor aith alag alagos alph
       alu alwed amar amarth amarthan amath amdir amlug amon amrûn anc and
       andreth ang angol angren annui annûn anor anu anwar apharch ar aran aras
       arn arod arth asgar ast astor athe aur avorn awarth bain balch bara baran
       beleg belt belthas beren bereth bor born bragol braig brand brassen
       bregol brog bronadui brui brûn bŷr cadu cadwar cal calar calen callon cam
       canad cand caran carch carweg caun celair celeb celebren celeg celevon
       cem cidinn cinnog cîw coll com conui corch cordof corn coru coth craban
       crann crist crumui cû cugu cuin cûn cund curu cŷr dail de del deleb delu
       dem der dern dîn dínen dîr dol dolen doll dom donn dorn dram draug dring
       dû dûr dŷr ech ecthel eden edhel edhellen edlenn eg egas eglan eglir
       eglos eiliant einior el elanor ell elloth elu en er ereb eredh ereg eru
       erui esgal estel estent ethir ew ewen fain fair falas falf fanui far faug
       faun fe feg fel fela fen fer fern ferui filig fim find fíreb firen forgam
       forn forod forodren fuin gail galadh galas galenas gamp gaud gear gearon
       gel gell gellam gellui gem ger gern geruil glad glam glamor glamren glan
       glass glaur glaw gler glîr glórin gloss goeol golass gondren gordh gorn
       gost graw gronn gruin gûr gwache gwain gwann gwarth gwath gwathren
       gwathui gwaun gwaur gwe gwen gweren gwest gwew gwilwileth gwîn hadhod hal
       hall hallas hand hannas harad haradren hargam harn harvo hast hathel he
       helch heledir hell hen heneb her hethu hîl him hîr hiril hith hithren
       hithui hîw horn hû hûr hwand hwîn iand iar iaun iaur îdh idhor idhren ind
       ingem inu iphant írui ist istui ithil ivren lagor laich lain lalaith lalf
       lam lanc land lang lass laug lavan leb leg lend ler lew leweg lhain lhew
       lhind lhûg lim limp lind lithui loen lom lorn lossen lost loth luin lum
       lung lŷg madweg maelui magor maidh malt malthen malthorn malu man mbar
       mbarad mecheneb med medli medlin medui meg megil melch meldir meldis
       meleth mell mellon melui men mer meren meron mesg methen mew milui min
       minai mîr mith mithren mîw morgul morn muil muin mûl mund mŷl naith nar
       narch naru nathal naud naug naugla naur nauth naw nawag ndam nder ndîr
       ndîs negen neledh nen nend nenui ner nestadren ngail ngalad ngannel
       ngaraf ngaur ngawad ngilith ngoll ngollor ngolodh ngolu ngolwen ngor
       ngorgor ngorn ngorth ngorthad ngûl ngurth nguru nguruthos niben nîd nîf
       nimp nîn nind nîr noen norn noroth nórui nûr oel oer ogol ol onod orch
       orchall orod oron othol ovor pant paran parch path paur pedweg pegui
       pelin pen peng periand peth pigen pîn puig rain raud raudh raug raun raw
       reg rem ren rend reth rhanc rhaw rhosg rhoss rhudol rhúnen rî rîn ring
       rîs riss roch rosc ross rost rûdh ruin rustui rûth rŷn sadar sador said
       sain sammar sarch sel ser sereg sîdh silef silivren sîr sûl tad taid tal
       talagand talt tan tanc tang tara tarch tarlanc tathren taug taur tavor
       taw tawar tawaren tawen tegil ten ter tes thala thanc thand tharan tharn
       thaur thavor thaw thend thent thîr thon thorn thoron thûl thurin tinnu
       tint tinu tîr tirn tithen tolog tond tong torn torog trîw tû tûg tuilind
       tulus tûr uanui uilos uireb ûl ulund ûn ungol ûr urug urui);

my @neutral_suffix =
    qw(ben dil ndil or wi);
my @female_suffix = (@neutral_suffix, @neutral_suffix,
		     qw(iel iell ien il eth el wen));
my @male_suffix = (@neutral_suffix, @neutral_suffix,
		   qw(dir ion on));

sub female_name {
  my $r = rand();
  if ($r < 0.6) { return one(@word) . one(@female_suffix) }
  elsif ($r < 0.8) { return one(@prefix) . one(@female_suffix) }
  else { return one(@prefix) . return one(@word) }
}

sub male_name {
  my $r = rand();
  if ($r < 0.6) { return one(@word) . one(@male_suffix) }
  elsif ($r < 0.8) { return one(@prefix) . one(@male_suffix) }
  else { return one(@prefix) . return one(@word) }
}

# We do some post-processing of words, inspired by these two web pages, but using
# our own replacements.
# https://sindarinlessons.weebly.com/36---how-to-make-names-1.html
# https://sindarinlessons.weebly.com/37---how-to-make-names-2.html

sub normalize {
  my $name = shift;

  $name =~ s/(.) \1/$1/g;
  $name =~ s/d t/d/g;
  $name =~ s/a ui/au/g;
  $name =~ s/nd m/dhm/g;
  $name =~ s/n?d w/dhw/g;
  $name =~ s/r gw/rw/g;
  $name =~ s/^nd/d/;
  $name =~ s/^ng/g/;
  $name =~ s/th n?d/d/g;
  $name =~ s/dh dr/dhr/g;
  $name =~ s/ //g;

  $name =~ tr/âêîôûŷ/aeioúi/;
  $name =~ s/ll$/l/;
  $name =~ s/ben$/wen/g;
  $name =~ s/bwi$/wi/;
  $name =~ s/[^aeiouúi]ndil$/dil/g;
  $name =~ s/ae/aë/g;
  $name =~ s/ea/ëa/g;
  $name =~ s/ii/ï/g;

  $name = ucfirst($name);

  return $name;
}

sub elf_name {
  my $name = shift;
  if ($name) {
    my $gender;
    for (@female_suffix) {
      return ($name, 'F') if $name =~ /$_$/;
    }
    for (@male_suffix) {
      return ($name, 'M') if $name =~ /$_$/;
    }
    return ($name, '?');
  } else {
    if (rand() < 0.5) { return (normalize(female_name()), 'F') }
    else { return (normalize(male_name()), 'M') }
  }
}

1;
