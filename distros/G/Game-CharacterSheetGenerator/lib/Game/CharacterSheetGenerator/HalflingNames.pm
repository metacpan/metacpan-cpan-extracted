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

Game::CharacterSheetGenerator::HalflingName - return a halfling name

=head1 SYNOPSIS

    use Game::CharacterSheetGenerator::HalflingName qw(halfling_name);
    # returns both $name and $gender (F, M, or ?)
    my ($name, $gender) = halfling_name();
    # returns the same name and its gender
    ($name, $gender) = halfling_name("Alex");

=head1 DESCRIPTION

This package has one function that returns a halfling name and a gender. The gender
returned is "M", "F", or "?".

If a name is provided, the gender is returned.

=cut

package Game::CharacterSheetGenerator::HalflingNames;
use Modern::Perl;
use utf8;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(halfling_name);

sub one {
  my $i = int(rand(scalar @_));
  return $_[$i];
}

# http://themiddleages.net/people/names.html

my @names = qw{Adalbert M Ageric M Agiulf M Ailwin M Alan M Alard M Alaric M
Aldred M Alexander M Alured M Amalaric M Amalric M Amaury M Andica M Anselm M
Ansovald M Aregisel M Arnald M Arnegisel M Asa M Athanagild M Athanaric M Aubrey
M Audovald M Austregisel M Authari M Badegisel M Baldric M Baldwin M Bartholomew
M Bennet M Bernard M Bero M Berthar M Berthefried M Bertram M Bisinus M Blacwin
M Burchard M Carloman M Chararic M Charibert M Childebert M Childeric M
Chilperic M Chlodomer M Chramnesind M Clovis M Colin M Constantine M Dagaric M
Dagobert M David M Drogo M Eberulf M Ebregisel M Edwin M Elias M Engeram M
Engilbert M Ernald M Euric M Eustace M Fabian M Fordwin M Forwin M Fulk M Gamel
M Gararic M Garivald M Geoffrey M Gerard M Gerold M Gervase M Gilbert M Giles M
Gladwin M Godomar M Godwin M Grimald M Gunderic M Gundobad M Gunthar M Guntram M
Guy M Hamo M Hamond M Harding M Hartmut M Helyas M Henry M Herlewin M Hermangild
M Herminafrid M Hervey M Hildebald M Hugh M Huneric M Imnachar M Ingomer M James
M Jocelin M John M Jordan M Lawrence M Leofwin M Leudast M Leuvigild M Lothar M
Luke M Magnachar M Magneric M Marachar M Martin M Masci M Matthew M Maurice M
Meginhard M Merovech M Michael M Munderic M Nicholas M Nigel M Norman M Odo M
Oliva M Osbert M Otker M Pepin M Peter M Philip M Ragnachar M Ralf M Ralph M
Ranulf M Rathar M Reccared M Ricchar M Richard M Robert M Roger M Saer M Samer M
Savaric M Sichar M Sigeric M Sigibert M Sigismund M Silvester M Simon M Stephan
M Sunnegisil M Tassilo M Terric M Terry M Theobald M Theoderic M Theudebald M
Theuderic M Thierry M Thomas M Thorismund M Thurstan M Umfrey M Vulfoliac M
Waleran M Walter M Waltgaud M Warin M Werinbert M William M Willichar M Wimarc M
Ymbert M Ada F Adallinda F Adaltrude F Adelina F Adofleda F Agnes F Albofleda F
Albreda F Aldith F Aldusa F Alice F Alina F Amabilia F Amalasuntha F Amanda F
Amice F Amicia F Amiria F Anabel F Annora F Arnegunde F Ascilia F Audovera F
Austrechild F Avelina F Avice F Avoca F Basilea F Beatrice F Bela F Beretrude F
Berta F Berthefled F Berthefried F Berthegund F Bertrada F Brunhild F Cecilia F
Celestria F Chlodosind F Chlothsinda F Cicely F Clarice F Clotild F Constance F
Denise F Dionisia F Edith F Eleanor F Elena F Elizabeth F Ellen F Emma F
Estrilda F Faileuba F Fastrada F Felicia F Fina F Fredegunde F Galswinth F
Gersvinda F Gisela F Goda F Goiswinth F Golda F Grecia F Gundrada F Gundrea F
Gundred F Gunnora F Haunild F Hawisa F Helen F Helewise F Hilda F Hildegarde F
Hiltrude F Ida F Idonea F Ingitrude F Ingunde F Isabel F Isolda F Joan F Joanna
F Julian F Juliana F Katherine F Lanthechilde F Laura F Leticia F Lettice F
Leubast F Leubovera F Liecia F Linota F Liutgarde F Lora F Lucia F Mabel F
Madelgarde F Magnatrude F Malota F Marcatrude F Marcovefa F Margaret F Margery F
Marsilia F Mary F Matilda F Maud F Mazelina F Millicent F Muriel F Nesta F
Nicola F Parnel F Petronilla F Philippa F Primeveire F Radegund F Richenda F
Richolda F Rigunth F Roesia F Rosamund F Rothaide F Rotrude F Ruothilde F
Sabelina F Sabina F Sarah F Susanna F Sybil F Sybilla F Theodelinda F Theoderada
F Ultrogotha F Vuldretrada F Wymarc F};

# This slow setting allows us to find errors.
my %names;
my $last = "";
while (@names) {
  my $key = shift(@names);
  my $val = shift(@names);
  die "$last $key" unless $val =~ /^[FM?]$/;
  $names{$key} = $val;
  $last = $val;
}

sub halfling_name {
  my $name = shift || one(keys %names);
  my $gender = $names{$name};
  return ($name, $gender);
}

1;
