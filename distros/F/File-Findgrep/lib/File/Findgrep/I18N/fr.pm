
package File::Findgrep::I18N::fr;
# French language messages for Findgrep
use base qw(File::Findgrep::I18N);
use strict;
use vars qw(%Lexicon);
%Lexicon = (

"What options?" => "Quels paramètres?",

"Unknown switch \"[_1]\"\n" => "Option inconnue «[_1]»\n",

"# Searching in directory [_1]\n"
 => "Cherchant dans le répertoire [_1]\n",

"[_1] looks like a binary file.  Skipping.\n"
 => "Sautant le fichier apparemment binaire [_1].\n",

"Not enough arguments for findgrep!"
 => "Pas assez de paramètres pour findgrep!",

"Minimum ([_1]) is larger than maximum ([_2])!\n",
 => "Le minimum ([_1]) est plus grand que le maximum ([_2])!\n",

"Invalid line-regexp: [_1] -- [_2]"
 => "modèle-ligne malformé: [_1] -- [_2]",

"Invalid file-regexp: [_1] -- [_2]",
 => "modèle-fichier malformé: [_1] -- [_2]",

"Can't open directory [_1]: [_2]\n"
 => "Incapable d'ouvrir le répertoire [_1]: [_2]\n",

"Found [quant,_1,line] in [quant,_2,file], in [quant,_3,directory,directories] scanned.\n"
 =>
"[quant,_1,ligne trouvée,lignes trouvées,Aucune ligne trouvée][
] dans [quant,_2,fichier], dans [
][quant,_3,répertoire vu,répertoires vus].\n",


'_USAGE_MESSAGE' =>
   # an example of a phrase whose key isn't meant to
   #  ever double as a lexicon value.
\q{Instructions:
 findgrep [options] modèle-ligne [modèle-fichier [noms-de-répertoires...]]
Options:
 -R      récurser
 -m123   taille de fichier minimum en octets  (implicite: 0)
 -m123K  taille de fichier minimum en kilo-octets
 -m123M  taille de fichier minimum en mega-octets
 -m123G  taille de fichier minimum en giga-octets
 -m123   taille de fichier maximum en octets  (implicite: 10 million)
 -m123K  taille de fichier maximum en kilo-octets
 -m123M  taille de fichier maximum en mega-octets
 -m123G  taille de fichier maximum en giga-octets
 -h      terminer en montrant ce message
 --      indiquer la fin des options

Modèle-ligne devrait être un regexp pour les lignes à montrer.

Modèle-fichier devrait être un regexp pour les noms-de-base de fichier.
  Implicitement, on cherche dans tous les fichers dont le nom
  ne se commence pas avec un point.
Noms-de-répertoires devrait être une liste de répertoires à chercher.
  Implicitement, on cherche dans le répertoire actuel.
Example:
  findgrep -R 'cheva(l|aux)' '\.txt$' ~/trucs
},



);
# fin de lexique.

1;  # fin de module.

