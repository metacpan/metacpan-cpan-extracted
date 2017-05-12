package #
Locale::VersionedMessages::Sets::lm_gui::fr_FR;
####################################################
#        *** WARNING WARNING WARNING ***
#
# This file was generated, and is intended to be
# maintained automatically using the Locale::VersionedMessages
# tools.
#
# Any changes to this file may be lost the next
# time these commands are run.
####################################################
# Copyright 2014-2014

use strict;
use warnings;

our $CopyrightBeg = 2014;
our $CopyrightEnd = 2014;

our(%Messages);

%Messages = (
   'button: add locale' => {
      'vers'  => 1,
      'text'  => 'Ajouter de nouveaux paramètres régionaux',
   },
   'button: add message' => {
      'vers'  => 1,
      'text'  => 'Ajouter un Message',
   },
   'button: browse' => {
      'vers'  => 1,
      'text'  => 'Parcourir',
   },
   'button: exit' => {
      'vers'  => 1,
      'text'  => 'SORTIE',
   },
   'button: sel locale' => {
      'vers'  => 1,
      'text'  => 'Affichage paramètres régionaux',
   },
   'button: submit' => {
      'vers'  => 1,
      'text'  => 'Envoyer',
   },
   'create_set: instructions' => {
      'vers'  => 1,
      'text'  => 'Pour créer un message, il faut préciser le paramètres régionaux par défaut.
Les paramètres régionaux sont de la forme LC_CC ou simplement LC où LC est une langue de deux caractères
code (en minuscules) et CC est un codes de langue 2 caractères (majuscules). Ainsi, le
suivantes sont valides : <b>fr</b>, <b>fr_FR</b>.',
   },
   'create_set: loc err' => {
      'vers'  => 1,
      'text'  => 'Un valide de paramètres régionaux doit être de la forme LC_CC ou LC.',
   },
   'create_set: locale' => {
      'vers'  => 1,
      'text'  => 'Paramètres régionaux par défaut',
   },
   'create_set: window title' => {
      'vers'  => 1,
      'text'  => '[COM] :: Créer une série de messages de Locale::VersionedMessages',
   },
   'error' => {
      'vers'  => 1,
      'text'  => 'ERREUR',
   },
   'manage_set: curr' => {
      'vers'  => 1,
      'text'  => 'Message dans les paramètres régionaux en cours',
   },
   'manage_set: def' => {
      'vers'  => 1,
      'text'  => 'Message par défaut des paramètres régionaux',
   },
   'manage_set: def mess instructions' => {
      'vers'  => 1,
      'text'  => 'Le message suivant est défini dans le paramètres régionaux par défaut.

Vous pouvez modifier le texte du message dans le paramètres régionaux par défaut ou modifier la
valeurs de description ou de substitution.

Par défaut, toute modification au message se traduira en augmentant la
Numéro de version du message dans le paramètres régionaux par défaut. Cela aura l\'effet
de faire le message obsolète dans tous les autres paramètres régionaux.

Si vous cliquez sur quitter Version non </B> la <B>, la version sera
restée seule, sauf si les valeurs de substitution est modifié. Dans ce cas,
la version augmentera peu importe car tous les messages devront être
mis à jour.',
   },
   'manage_set: desc' => {
      'vers'  => 1,
      'text'  => 'Description du message',
   },
   'manage_set: edit mess instructions' => {
      'vers'  => 1,
      'text'  => 'Le message suivant est défini dans les paramètres régionaux actuels.

Vous pouvez modifier le texte du message pour faire correspondre le texte dans le paramètres régionaux par défaut.

Par défaut, chaque fois que vous modifiez le texte, la version du message dans le
paramètres régionaux en cours sera définie sur les mêmes que le paramètres régionaux par défaut. Si votre modification
n\'est pas suffisante pour qu\'il soit à jour, et d\'autres modifications seront
nécessaire, cliquez sur la case obsolète </B> <B> et le message seront marqués
obsolète.

Messages surlignés en rouge sont actuellement manquants dans la locale courante. Ceux
surlignés en jaune sont présents, mais obsolètes en ce qui concerne le paramètres régionaux par défaut.',
   },
   'manage_set: instructions' => {
      'vers'  => 1,
      'text'  => 'Pour créer un message, il faut préciser le paramètres régionaux
par défaut. Les paramètres régionaux sont de la forme LC_CC ou simplement LC où LC
est une langue de deux caractères code (en minuscules) et CC est un codes de langue
2 caractères (majuscules). Ainsi, le suivantes sont valables: <b>fr</b>,
<b>fr_FR</b>.',
   },
   'manage_set: leave version unmodified' => {
      'vers'  => 1,
      'text'  => 'Laissez la Version non modifiée',
   },
   'manage_set: mark ood' => {
      'vers'  => 1,
      'text'  => 'Mark obsolète',
   },
   'manage_set: msgid' => {
      'vers'  => 1,
      'text'  => 'ID de message',
   },
   'manage_set: msgid list' => {
      'vers'  => 1,
      'text'  => 'Série de messages: [SET]',
   },
   'manage_set: new mess def err' => {
      'vers'  => 1,
      'text'  => 'Lorsque vous créez un nouveau message, le message par défaut
locale est nécessaire.',
   },
   'manage_set: new mess instructions' => {
      'vers'  => 1,
      'text'  => 'Pour créer un nouveau message, vous devez entrer ce qui suit :

1) Un ID de message unique (différent de n\'importe quel ID de message dans la liste à gauche).

2) Une simple description de la ligne 1 du message. Cela peut être laissé vide, mais
peut être utile aux traducteurs dans la compréhension du contexte du message.

3) S\'il n\'y a aucune substitution de valeur dans le message, ils peuvent être saisis
comme un espace séparé la liste des noms des valeurs. S\'il n\'y a rien, laissez ce champ vide.

4) Il faut le texte du message dans le paramètres régionaux par défaut. Il peut être
multiligne. Laissez une ligne blanche entre les paragraphes.',
   },
   'manage_set: new mess msgid err' => {
      'vers'  => 1,
      'text'  => 'Lorsque vous créez un nouveau message, l\'ID de message ne doit pas être
précédemment utilisé.',
   },
   'manage_set: subst' => {
      'vers'  => 1,
      'text'  => 'Valeurs de substitution',
   },
   'manage_set: window title' => {
      'vers'  => 1,
      'text'  => '[COM] :: Gérer une série de messages de Locale::VersionedMessages',
   },
   'select_operation: desc err' => {
      'vers'  => 1,
      'text'  => 'Un fichier de description d\'ensemble valide doit être un module perl avec un chemin d\'accès :
DIR/Locale/Messages/Sets/SET.pm.',
   },
   'select_operation: description' => {
      'vers'  => 1,
      'text'  => 'Description du jeu message',
   },
   'select_operation: directory' => {
      'vers'  => 1,
      'text'  => 'Sélectionnez le répertoire',
   },
   'select_operation: err' => {
      'vers'  => 1,
      'text'  => 'Lorsque vous spécifiez l\'ensemble de messages, vous pouvez spécifier soit le répertoire et définir le nom (à la fois requis) ou le message défini le fichier de description, mais pas les deux.',
   },
   'select_operation: instructions_1' => {
      'vers'  => 1,
      'text'  => 'Une série de messages jeu nommée vit dans un répertoire (DIR), qui contient
un message Locale::Message définie la hiérarchie du module. La description d\'une série de messages
sera dans le fichier : DIR/Locale/Messages/Sets/SET.pm. Lexiques vivront dans
DIR/Locale/Messages/Sets/SET/LOCALE.pm.

Pour créer une nouvelle série de messages, il est nécessaire de sélectionner le répertoire où
la hiérarchie de message vivra (le répertoire doit exister, mais la hiérarchie
en dessous il sera créé si nécessaire) et spécifiez le nom de la
ensemble de messages.

Vous pouvez également sélectionner un message existant défini pour maintenir en sélectionnant le
Répertoire et en spécifiant le message défini (bien que dans le cas d\'un existant
série de messages, il peut être plus facile de sélectionner directement à l\'aide du
<B> Description de la valeur du Message </B> case ci-dessous).

Pour ce faire, entrez le répertoire dans la zone <b>Sélectionner le répertoire </b> et entrez
le nom du message défini dans le <b>jeu de messages:</b> boîte.',
   },
   'select_operation: instructions_2' => {
      'vers'  => 1,
      'text'  => 'Pour sélectionner un message existant défini pour gérer, vous pouvez sélectionner
le message qui file description directement dans la
<b> Description de la valeur du Message:</b> boîte.',
   },
   'select_operation: set' => {
      'vers'  => 1,
      'text'  => 'Série de messages',
   },
   'select_operation: set err' => {
      'vers'  => 1,
      'text'  => 'Un nom de jeu valide doit se composent de caractères alphanumériques et souligner
caractères seulement.',
   },
   'select_operation: window title' => {
      'vers'  => 1,
      'text'  => '[COM] :: série de messages de Locale::VersionedMessages',
   },
);

1;
