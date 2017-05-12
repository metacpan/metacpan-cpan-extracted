package Lingua::GA::Gramadoir::Languages::fr;
# Messages français pour GNU concernant gramadoir.
# Copyright © 2004-2008 Free Software Foundation, Inc.
# This file is distributed under the same license as the gramadoir package.
# Michel Robitaille <robitail@IRO.UMontreal.CA>, traducteur depuis/since 1996.
# Odile Bénassy <obenassy@april.org>, traductrice depuis 2008.
#msgid ""
#msgstr ""
#"Project-Id-Version: GNU gramadoir 0.7\n"
#"Report-Msgid-Bugs-To: <kscanne@gmail.com>\n"
#"POT-Creation-Date: 2008-09-05 17:20-0500\n"
#"PO-Revision-Date: 2008-08-25 22:27+0200\n"
#"Last-Translator: Odile Bénassy <obenassy@april.org>\n"
#"Language-Team: French <traduc@traduc.org>\n"
#"MIME-Version: 1.0\n"
#"Content-Type: text/plain; charset=ISO-8859-1\n"
#"Content-Transfer-Encoding: 8-bit\n"

use strict;
use warnings;
use utf8;
use base qw(Lingua::GA::Gramadoir::Languages);
use vars qw(%Lexicon);

%Lexicon = (
    "Line %d: [_1]\n"
 => "Ligne %d : [_1]\n",

    "unrecognized option [_1]"
 => "option [_1] non reconnue",

    "option [_1] requires an argument"
 => "l'option [_1] appelle un argument",

    "option [_1] does not allow an argument"
 => "l'option [_1] n'accepte pas d'argument",

    "error parsing command-line options"
 => "erreur d'analyse des options de la ligne de commande",

    "Unable to set output color to [_1]"
 => "Impossible de régler la couleur de sortie à [_1]",

    "Language [_1] is not supported."
 => "La langue [_1] n'est pas implémentée.",

    "An Gramadoir"
 => "An Gramadóir",

    "Try [_1] for more information."
 => "Essayez [_1] pour plus d'informations.",

    "version [_1]"
 => "version [_1]",

    "This is free software; see the source for copying conditions.  There is NO\nwarranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE,\nto the extent permitted by law."
 => "Ceci est un logiciel libre ; voir les sources pour les conditions de reproduction. AUCUNE garantie n'est donnée; pas même celle de CAPACITÉ DE MISE SUR LE MARCHÉ ni celle d'ADAPTATION À UN BUT PARTICULIER, sous réserve des conditions légales.",

    "Usage: [_1] ~[OPTIONS~] ~[FILES~]"
 => "Usage : [_1] ~[OPTIONS~] ~[FICHIERS~]",

    "Options for end-users:"
 => "Options pour les utilisateurs :",

    "    --iomlan       report all errors (i.e. do not use ~/.neamhshuim)"
 => "    --iomlan       rapporter toutes les erreurs (i.e. ne pas utiliser ~/.neamhshuim)",

    "    --ionchod=ENC  specify the character encoding of the text to be checked"
 => "    --ionchod=ENC  spécifier l'encodage des caractères du texte à vérifier",

    "    --aschod=ENC   specify the character encoding for output"
 => "    --aschod=ENC   spécifier l'encodage des caractères pour la sortie",

    "    --comheadan=xx choose the language for error messages"
 => "    --comheadan=xx choisir le langage pour les message d'erreur",

    "    --dath=COLOR   specify the color to use for highlighting errors"
 => "    --dath=COULEUR spécifier la couleur à utiliser pour surligner les erreurs",

    "    --litriu       write misspelled words to standard output"
 => "    --litriu       écrire les mots mal orthographiés sur la sortie standard",

    "    --aspell       suggest corrections for misspellings"
 => "    --aspell       suggérer des corrections pour les erreurs d'orthographe",

    "    --aschur=FILE  write output to FILE"
 => "    --aschur=FICHIER  écrire la sortie dans le FICHIER",

    "    --help         display this help and exit"
 => "    --help         afficher l'aide-mémoire et quitter",

    "    --version      output version information and exit"
 => "    --version      afficher la version du logiciel et quitter",

    "Options for developers:"
 => "Options pour les développeurs :",

    "    --api          output a simple XML format for use with other applications"
 => "    --api          produire seulement un format XML à utiliser avec d'autres applications",

    "    --html         produce HTML output for viewing in a web browser"
 => "    --html         produire une sortie HTML pour un logiciel de navigation Internet",

    "    --no-unigram   do not resolve ambiguous parts of speech by frequency"
 => "    --no-unigram   ne pas résoudre les parties ambiguës de la langue en fonction de la fréquence",

    "    --xml          write tagged XML stream to standard output, for debugging"
 => "    --xml          écrire un flot XML étiqueté sur la sortie standard, pour mise au point (debug)",

    "If no file is given, read from standard input."
 => "Si aucun fichier n'est fourni, lire l'entrée standard",

    "Send bug reports to <[_1]>."
 => "Transmettre les rapports d'anomalie à <[_1]>.",

    "There is no such file."
 => "Ce fichier n'existe pas.",

    "Is a directory"
 => "Est un répertoire",

    "Permission denied"
 => "Autorisation refusée",

    "[_1]: warning: problem closing [_2]\n"
 => "[_1] : AVERTISSEMENT: problème de fermeture de [_2]\n",

    "Currently checking [_1]"
 => "Vérification en cours de [_1]",

    "    --ilchiall     report unresolved ambiguities, sorted by frequency"
 => "    --ilchiall     rapporter les ambiguïtés non résolues, classées par fréquence",

    "    --minic        output all tags, sorted by frequency (for unigram-xx.txt)"
 => "    --minic        afficher toutes les étiquettes, classées par fréquence (pour unigram-xx.txt)",

    "    --brill        find disambiguation rules via Brill's unsupervised algorithm"
 => "    --brill        trouver des règles de clarification à l'aide de l'algorithme non supervisé de Brill",

    "[_1]: problem reading the database\n"
 => "[_1] : problème de lecture de la base de données\n",

    "[_1]: `[_2]' corrupted at [_3]\n"
 => "[_1] : « [_2] » corrompu à [_3]\n",

    "conversion from [_1] is not supported"
 => "la conversion à partir de [_1] n'est pas prise en charge",

    "[_1]: illegal grammatical code\n"
 => "[_1] : code grammatical formellement incorrect\n",

    "[_1]: no grammar codes: [_2]\n"
 => "[_1] : pas de codes grammaticaux : [_2]\n",

    "[_1]: unrecognized error macro: [_2]\n"
 => "[_1] : erreur macro non reconnue : [_2]\n",

    "Valid word but extremely rare in actual usage. Is this the word you want?"
 => "Mot valide mais extrêmement rare en usage réel. Est-ce bien ce mot-là que vous voulez ?",

    "Repeated word"
 => "Mot répété",

    "Unusual combination of words"
 => "Combinaison de mots rarement utilisée",

    "The plural form is required here"
 => "La forme au pluriel est requise ici",

    "The singular form is required here"
 => "La forme au singulier est requise ici",

    "Plural adjective required"
 => "Cet adjectif doit être au pluriel",

    "Comparative adjective required"
 => "L'adjectif comparatif est requis",

    "Definite article required"
 => "L'article défini est requis",

    "Unnecessary use of the definite article"
 => "Usage non nécessaire de l'article défini",

    "No need for the first definite article"
 => "Le premier article défini n'est pas nécessaire",

    "Unnecessary use of the genitive case"
 => "Usage non nécessaire du génitif",

    "The genitive case is required here"
 => "Il faut le génitif ici",

    "You should use the present tense here"
 => "Ici, vous devriez employer le présent",

    "You should use the conditional here"
 => "Ici, vous devriez employer le présent",

    "It seems unlikely that you intended to use the subjunctive here"
 => "Il semble peu probable que vous ayiez l'intention d'employer le subjonctif",

    "Usually used in the set phrase /[_1]/"
 => "habituellement utilisé dans l'expression /[_1]/",

    "You should use /[_1]/ here instead"
 => "Vous devriez utiliser plutôt /[_1]/ ici",

    "Non-standard form of /[_1]/"
 => "Forme non-standard de /[_1]/",

    "Derived from a non-standard form of /[_1]/"
 => "Dérivé d'une forme non-standard de /[_1]/",

    "Derived incorrectly from the root /[_1]/"
 => "Dérivé incorrectement de la racine /[_1]/",

    "Unknown word"
 => "Mot inconnu",

    "Unknown word: /[_1]/?"
 => "Mot inconnu : /[_1]/?",

    "Valid word but /[_1]/ is more common"
 => "Mot valide, mais /[_1]/ est plus usuel",

    "Not in database but apparently formed from the root /[_1]/"
 => "Absent de la base de données, mais apparemment formé à partir de la racine /[_1]/",

    "The word /[_1]/ is not needed"
 => "Le mot /[_1]/ n'est pas obligatoire.",

    "Do you mean /[_1]/?"
 => "Voulez-vous dire /[_1]/ ?",

    "Derived form of common misspelling /[_1]/?"
 => "Forme dérivée d'une faute d'orthographe fréquente /[_1]/ ?",

    "Not in database but may be a compound /[_1]/?"
 => "N'est pas dans la base de données mais peut-être un mot composé /[_1]/ ?",

    "Not in database but may be a non-standard compound /[_1]/?"
 => "N'est pas dans la base de données mais peut-être un mot composé inhabituel /[_1]/ ?",

    "Possibly a foreign word (the sequence /[_1]/ is highly improbable)"
 => "Peut-être un mot étranger (la séquence /[_1]/ est très peu probable)",

    "Gender disagreement"
 => "Discordance de genre",

    "Number disagreement"
 => "Discordance de nombre",

    "Case disagreement"
 => "Discordance de cas",

    "Prefix /h/ missing"
 => "Préfixe /h/ manquant",

    "Prefix /t/ missing"
 => "Préfixe /t/ manquant",

    "Prefix /d'/ missing"
 => "Le préfixe /d'/ est manquant",

    "Unnecessary prefix /h/"
 => "Le préfixe /h/ n'est pas nécessaire",

    "Unnecessary prefix /t/"
 => "Le préfixe /t/ n'est pas nécessaire",

    "Unnecessary prefix /d'/"
 => "Le préfixe /d'/ n'est pas nécessaire",

    "Unnecessary prefix /b'/"
 => "Le préfixe /b'/ n'est pas nécessaire",

    "Unnecessary initial mutation"
 => "Cette mutation initiale n'est pas nécessaire",

    "Initial mutation missing"
 => "Mutation initiale manquante",

    "Unnecessary lenition"
 => "Cette lénition n'est pas nécessaire",

    "The second lenition is unnecessary"
 => "La seconde lénition n'est pas nécessaire",

    "Often the preposition /[_1]/ causes lenition, but this case is unclear"
 => "Souvent la préposition /[_1]/ provoque une lénition, mais ce cas n'est pas clair",

    "Lenition missing"
 => "Lénition manquante",

    "Unnecessary eclipsis"
 => "Cette éclipse n'est pas nécessaire",

    "Eclipsis missing"
 => "Éclipse manquante",

    "The dative is used only in special phrases"
 => "La partie au datif est utilisée seulement dans des phrases spécifiques",

    "The dependent form of the verb is required here"
 => "La forme dépendante du verbe est requise ici",

    "Unnecessary use of the dependent form of the verb"
 => "Usage non nécessaire de la forme dépendante du verbe",

    "The synthetic (combined) form, ending in /[_1]/, is often used here"
 => "La forme synthétique (combinée) se terminant par /[_1]/ est souvent utilisé ici",

    "Second (soft) mutation missing"
 => "Seconde mutation (adoucissement) manquante",

    "Third (breathed) mutation missing"
 => "Troisième mutation (breathed) manquante",

    "Fourth (hard) mutation missing"
 => "Quatrième mutation (durcissement) manquante",

    "Fifth (mixed) mutation missing"
 => "Quatrième mutation (mixte) manquante",

    "Fifth (mixed) mutation after 'th missing"
 => "Cinquième mutation (mixte) après la nième manquante",

    "Aspirate mutation missing"
 => "Mutation aspirée manquante",

    "This word violates the rules of Igbo vowel harmony"
 => "Ce mot porte une violation des règles de l'harmonie des voyelles dans la langue Igbo",

    "Valid word but more often found in place of /[_1]/"
 => "Mot vlaide mais trouvé plus d'une fois à la place de /[_1]/",

    "#~ \"    --teanga=XX    specify the language of the text to be checked \"#~ \"(default=ga)\""
 => "#~ \"    --teanga=XX    spécifier le langage du texte à vérifier (par \"#~ \"défaut=ga)\"",

    "aspell-[_1] is not installed"
 => "aspell-[_1] n'est pas installé",

    "Unknown word (ignoring remainder in this sentence)"
 => "Mot inconnu (le reste de la phrase est ignoré)",

    "[_1]: out of memory\n"
 => "[_1]: mémoire épuisée\n",

    "[_1]: warning: check size of [_2]: %d?\n"
 => "[_1]: AVERTISSEMENT: vérifier la taille de [_2]: %d?\n",

    "problem with the `cuardach' command\n"
 => "problème avec la commande « cuardach »\n",

);
1;
