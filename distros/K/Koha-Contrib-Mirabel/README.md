# Koha-Contrib-Mirabel

[Mir@bel](http://www.reseau-mirabel.info) référence une liste de plus de deux
milles revues pour lesquelles des *services* en-ligne sont signalés. Ces
*services* sont des URL donnant accès à des contenus de quatre types différents
: texte intégral, sommaires, résumés et indexation. La période de publication
de la revue couverte par chaque service, ainsi que les lacunes et les condtions
d'accès sont fournies avec le service.

Mir@bel est géré par un réseau de **partenaires**. Ce sont les bibliothèques et
centres de documentation qui sont autorisés à mettre à jour Mir@bel et à
récupérer localement les informations de Mir@bel au moyen de services web.

Le programme **koha-mirabel** synchronise la base d'information Mir@bel avec un
Catalogue Koha. Il agit comme un client des services web de Mir@bel. Les
informations sont retrouvées dans Mir@bel et reportées dans les notices
bibliographiques Koha de périodique.


## Synopsys

```sh
koha-mirabel sync
koha-mirabel sync --doit
koha-mirabel sync --doit --noverbose
koha-mirabel clean
koha-mirabel fullclean
```

## Installation

Sur un serveur Koha, installez le paquet `Koha::Contrib::Mirabel`, en tant
qu'utilisateur root :

```sh
cpan Koha::Contrib::Mirabel
```

## Configuration

Le programme accède à une instance de Koha au moyen des variables
d'environnement habituelles : **KOHA_CONF** et **PERL5LIB**. Deux préférences
systèmes sont nécessaires : 

* **MirabelPartenaire** - Contient le numéro de partenaire Mir@bel. Ce numéro
est utilisé pour obtenir la liste des revues du partenaire dans Mir@bel.
* **MirabelTag** - Le tag de la zone MARC dans laquelle les info Mir@bel sont
recopiées.


## Synchronisation

La synchronisation consiste à interroger Mir@bel afin d'obtenir la liste des
info relatives aux revues du partenaire. À chaque revue est associée une liste
de _services_. Un service Mir@bel est une collection d'informations décrivant
des ressources en-ligne, dont leur URL. Les _services_ Mir@bel sont reportés
dans des répétitions de la zone dont le tag est spécifié par la préférence
système _MirabelTag_. Les sous-champs de la zone MARC contiennent les info du
service :

* `id` : $3
* `type` : $4 -- Le type de lien : Intégral, Sommaire, Résumé, Indexation
* `urlservice` ou `urldirecte` : $a -- urlservice, mais si absent urldirecte.
* `nom` : $b -- Le nom en clair du fournisseur du service.
* `acces` : $c -- Les conditions d'accès. Par exemple : libre, restreint.
* `debut` et `fin` : $d -- les deux info sont concaténées.
* `converture` : $e -- La période couverte.
* `lacunaire` : $f

La synchronisation est effectuée en lançant la commande : `koha-mirabel sync`.
Le paramètre `--doit` est nécessaire pour que la synchronisation soit
effective.  Par défaut, le script affiche une description du travail qu'il
effectue. Par exemple, en traitant une notice dont le biblionumner est 82146,
il peut afficher ceci :

```text
________________________________________ #82146
00564    a2200157   4500
022    $a 1144-5645
041    $a fre
044    $a FRA
245    $a Alliage
260    $a Nice : $b Association ANAIS
362    $a n˚3, 1990
500    $a moins de 10 fascicules
942    $c PER
999    $c 82146 $d 82146

Mirabel #6951
   nom: Revues électroniques de l'université de Nice
   urlservice: http://revel.unice.fr/
   acces: Libre
   debut: 1999
   urldirecte: http://revel.unice.fr/alliage/index.html?id=4041
   fin: 2012
   type: Intégral
Mirabel #6952
   nom: Revues électroniques de l'université de Nice
   urlservice: http://revel.unice.fr/
   acces: Libre
   debut: 1999
   urldirecte: http://revel.unice.fr/alliage/index.html?id=33
   fin: 2012
   type: Indexation
 
APRÈS:
00564    a2200157   4500
022    $a 1144-5645
041    $a fre
044    $a FRA
245    $a Alliage
260    $a Nice : $b Association ANAIS
362    $a n˚3, 1990
500    $a moins de 10 fascicules
901    $3 6951 $4 Intégral $a http://revel.unice.fr/alliage/index.html?id=4041 $b Revues électroniques de l'université de Nice $c Libre $d 1999-2012
901    $3 6952 $4 Indexation $a http://revel.unice.fr/alliage/index.html?id=33 $b Revues électroniques de l'université de Nice $c Libre $d 1999-2012
942    $c PER
999    $c 82146 $d 82146
```

## Nettoyage

La tâche de nettoyage interroge Mir@bel pour obtenir la liste des identifiants
des services qui ont été supprimés depuis un an. Ces identifiants sont
recherchés dans le Catalogue Koha (sous-champ `$4` de la zone spécifiée par la
préférence *MirabelTag*) et les zones MARC correspondantes sont supprimées des
notices.

On lance la commande : `koha-mirabel clean`. Le paramêtre `--doit` est
nécessaire pour que les notices concernées soient effectivement modifiées. Par
défaut, sans le paramètre `--noverbose`, le détail du travail effectué est
affiché. Par exemple, si parmi les services supprimés de Mir@bel, il y a le
service 2540 et qu'il se trouve dans la zone 901 de la notice Koha 81935, les
info suivantes seront affichées :

```text
Suppression dans Koha des services retirés de Mir@bel depuis un an
Services supprimées : 977, 979, 981, 982, 1459, 1460, 1461, 1513, 1518, 1628, 1631, 1638, 1639, 1640, 1689, 1727, 1728, 1729, 1777, 1784, 1869, 1870, 1871, 2108, 2111, 2303, 2537, 2540, 2540, 2603, 2759, 2786, 2794, 2808, 2809, 2890, 2891, 2892, 2938, 2939, 3096, 3207, 3258, 3260, 3295, 3322, 3323, 3324, 3338, 3382, 3420, 3452, 3463, 3496, 3545, 3627, 4113, 4133, 4219, 4475, 4497, 4904, 4905, 4981, 4996, 5041, 5102, 5138, 5157, 5186, 5279, 5296, 5310, 5314, 5370, 5390, 5474, 5517, 5632, 5936, 5978, 6015, 6019, 6316, 6341, 6393, 6395, 6403, 6417, 6434, 6442, 6459, 6560, 6575, 6576, 6584, 6637, 6820, 6822, 6865, 6909, 6987, 6999, 7000, 7003, 7004, 7005, 7006, 7007, 7008, 7009, 7010, 7011, 7012, 7013, 7014, 7015, 7016, 7017, 7018, 7019, 7020, 7021, 7022, 7023, 7024, 7029, 7031, 7032, 7033, 7034, 7068, 7088, 7089, 7139, 7141, 7143, 7162, 7259, 7262, 7428, 7477, 7552, 7632

________________________________________ #81935
01504    a2200241   4500
022    $a 0458-726X
041    $a fre
044    $a FRA
245    $a Langages
260    $a Paris : $b Larousse : $b A. Colin, $c n°1, 1966 - ...
500    $a Collection en cours. Trimestriel
901    $3 959 $4 Intégral $a http://www.armand-colin.com/revue/20/1/langages.php $b Armand Colin $c Libre $d 2002-03-2010-12
901    $3 2165 $4 Sommaire $a http://www.vjf.cnrs.fr/clt/v2/Page_revue.php?ValCodeRev=LANGA $b Cultures, Langues, Textes : la revue de sommaires $c Libre $d 1969- $e Lacunaire
901    $3 2539 $4 Intégral $a http://www.armand-colin.com/revue/20/1/langages.php $b Armand Colin $c Libre $d 2001-2001 $e Lacunaire - Sélection d'articles
901    $3 2540 $4 Résumé $a http://www.armand-colin.com/revue/20/1/langages.php $b Armand Colin $c Libre $d 2001-02- $e Lacunaire - Sélection d'articles
901    $3 2541 $4 Sommaire $a http://www.armand-colin.com/revue/20/1/langages.php $b Armand Colin $c Libre $d 2002-03-
901    $3 3917 $4 Intégral $a http://www.armand-colin.com/revue/20/1/langages.php $b Armand Colin $c Restreint $d 2011-03-
901    $3 4824 $4 Intégral $a http://www.persee.fr/web/revues/home/prescript/revue/lgge $b Persée $c Libre $d 1966-2006
901    $3 5145 $4 Intégral $a http://www.cairn.info/revue-langages.htm $b Cairn $c Libre $d 2004-2010
901    $3 5146 $4 Intégral $a http://www.cairn.info/revue-langages.htm $b Cairn $c Restreint $d 2011-2013
942    $c PER
362    $a n ̊4, 1966 - ... [lac. : n ̊10, 1968 ; n ̊20, 1970 ; n ̊25, 1972]
999    $c 81935 $d 81935

APRÈS
01504    a2200241   4500
022    $a 0458-726X
041    $a fre
044    $a FRA
245    $a Langages
260    $a Paris : $b Larousse : $b A. Colin, $c n°1, 1966 - ...
500    $a Collection en cours. Trimestriel
901    $3 959 $4 Intégral $a http://www.armand-colin.com/revue/20/1/langages.php $b Armand Colin $c Libre $d 2002-03-2010-12
901    $3 2165 $4 Sommaire $a http://www.vjf.cnrs.fr/clt/v2/Page_revue.php?ValCodeRev=LANGA $b Cultures, Langues, Textes : la revue de sommaires $c Libre $d 1969- $e Lacunaire
901    $3 2539 $4 Intégral $a http://www.armand-colin.com/revue/20/1/langages.php $b Armand Colin $c Libre $d 2001-2001 $e Lacunaire - Sélection d'articles
901    $3 2541 $4 Sommaire $a http://www.armand-colin.com/revue/20/1/langages.php $b Armand Colin $c Libre $d 2002-03-
901    $3 3917 $4 Intégral $a http://www.armand-colin.com/revue/20/1/langages.php $b Armand Colin $c Restreint $d 2011-03-
901    $3 4824 $4 Intégral $a http://www.persee.fr/web/revues/home/prescript/revue/lgge $b Persée $c Libre $d 1966-2006
901    $3 5145 $4 Intégral $a http://www.cairn.info/revue-langages.htm $b Cairn $c Libre $d 2004-2010
901    $3 5146 $4 Intégral $a http://www.cairn.info/revue-langages.htm $b Cairn $c Restreint $d 2011-2013
942    $c PER
362    $a n ̊4, 1966 - ... [lac. : n ̊10, 1968 ; n ̊20, 1970 ; n ̊25, 1972]
999    $c 81935 $d 81935
```

## Nettoyage complet

Alternativement au nettoyage précédent, il est possible de réaliser un
nettoyage complet. Cela consiste à supprimer de toutes les notices de
périodique du Catalogue Koha tous les champs *MirabelTag*. Cette opération ne
nécessite pas d'interroger les services web Mir@bel. Le traitement n'est
effectif que si le paramètre `--doit` est fourni. Sans le paramètre
`--noverbose`, les notices avant/après modification sont affichées.

Par exemple :

```sh
koha-mirabel fullclean
```

affiche ceci :

```text
________________________________________ #89077
01060nam a2200217   4500
022    $a 0182-2411
041    $a fre
044    $a FRA
245 12 $a L'histoire
260    $a Paris : $b Sophia publications, $c 1978 -
500    $a Mensuel
901    $3 4504 $4 Intégral $a http://www.cairn.info/magazine-l-histoire.htm $b Cairn $c Restreint $d 2001-2014
901    $3 4544 $4 Indexation $a http://doc.sciencespo-lyon.fr/Signal/index.php?r=article/search&SearchArticle[revueId]=13&SearchArticle[dateDeb]=1988&SearchArticle[dateFin]= $b Sign@l $c Libre $d 1988- $e Sélection d'articles
901    $3 7042 $4 Sommaire $a http://www.histoire.presse.fr/boutique/parutions $b Histoire $c Libre $d 1978-
901    $3 7043 $4 Intégral $a http://www.histoire.presse.fr/boutique/parutions $b Histoire $c Restreint $d 1978-05-
901    $3 7333 $4 Sommaire $a http://doc.sciencespo-lyon.fr/Signal/index.php?r=numero/search&SearchNumero[revueId]=13 $b Sign@l $c Libre $d 2000-
942    $c PER
042    $a pcc
362    $a n°389, 2013 - ...
580    $a A un supplément depuis 1998: Collections de L'histoire.
999    $c 89077 $d 89077

APRÈS
01060nam a2200217   4500
022    $a 0182-2411
041    $a fre
044    $a FRA
245 12 $a L'histoire
260    $a Paris : $b Sophia publications, $c 1978 -
500    $a Mensuel
942    $c PER
042    $a pcc
362    $a n°389, 2013 - ...
580    $a A un supplément depuis 1998: Collections de L'histoire.
999    $c 89077 $d 89077
```

## Automatisation

Les opérations de synchronisation-nettoyage peuvent être programmées sur un
serveur Linux au moyen d'entrées dans le crontab. Par exemple, pour une synchro
quotidienne à 2h15 et un nettoyage hebdomadaire, on peut avoir ceci :

```crontab
# Mir@bel
15 2 * * * koha-mirabel sync --doit --noverbose
@weekly koha-mirabel clean --doit --noverbose
```

## Affichage

Une fois les info de Mir@bel remontées dans les notices d'un Catalogue Koha, il
faut les afficher. A cet effet, il faut modifier la feuille de style de la page
de détail de l'OPAC. Par exemple, pour afficher toutes les URL de Mir@bel, on
peut avoir cela :

```xsl
<xsl:if test="marc:datafield[@tag='901']">
  <div style="border: 1px solid #a0a0a0; padding: 5px; margin-bottom: 5px; background: #fafafa;">
    <p style="font-size: 11px; font-weight: bold; margin-bottom: 2px;">Accès en ligne:</p>
    <xsl:call-template name="mirabel">
      <xsl:with-param name="tag">901</xsl:with-param>
      <xsl:with-param name="type">Intégral</xsl:with-param>
      <xsl:with-param name="label">Texte intégral des articles</xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="mirabel">
      <xsl:with-param name="tag">901</xsl:with-param>
      <xsl:with-param name="type">Sommaire</xsl:with-param>
      <xsl:with-param name="label">Sommaire de la revue</xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="mirabel">
      <xsl:with-param name="tag">901</xsl:with-param>
      <xsl:with-param name="type">Résumé</xsl:with-param>
      <xsl:with-param name="label">Résumé des articles</xsl:with-param>
    </xsl:call-template>
    <xsl:call-template name="mirabel">
      <xsl:with-param name="tag">901</xsl:with-param>
      <xsl:with-param name="type">Indexation</xsl:with-param>
      <xsl:with-param name="label">Indexation des articles</xsl:with-param>
    </xsl:call-template>
  </div>
</xsl:if>
 
 
<xsl:template name="mirabel">
  <xsl:param name="tag"/>
  <xsl:param name="type"/>
  <xsl:param name="label"/>
  <xsl:if test="marc:datafield[@tag=$tag]/marc:subfield[@code='4']=$type">
    <span class="results_summary">
      <span class="label">
        <xsl:value-of select="$label"/>
        <xsl:text> : </xsl:text>
      </span>
      <xsl:for-each select="marc:datafield[@tag=$tag]">
        <xsl:if test="marc:subfield[@code='4']=$type">
          <a>
            <xsl:attribute name="href">
              <xsl:value-of select="marc:subfield[@code='a']"/>
            </xsl:attribute>
            <xsl:value-of select="marc:subfield[@code='b']"/>
          </a>
          <xsl:for-each select="marc:subfield[contains('cde', @code)]">
            <xsl:text>, </xsl:text>
            <xsl:value-of select="."/>
          </xsl:for-each>
          <xsl:if test="not(position()=last())">
            <br/>
          </xsl:if>
        </xsl:if>
      </xsl:for-each>
    </span>
  </xsl:if>
</xsl:template>
```

## Développement

Il est possible de participer au développement de ce programme ou d'en faire
fonctionner une version modifiée localement. À cet effet, il faut cloner le
dépôt Git de `Koha::Contrib::Mirabel`, puis rendre accessible l'exécutable
`koha-mirabel` ainsi que le module Perl associé au moyen des variables
d'environnement suivantes : 

```sh
EXPORT PATH=<koha-mirabel-root>/bin:$PATH
EXPORT PERL5LIB=<koha_mirabel_root>/lib:$PERL5LIB
```

## Copyright et license

Copyright 2015 by Tamil, s.a.r.l.

<http://www.tamil.fr>

This script is free software; you can redistribute it and/or modify it under
the same terms as Perl 5 itself.


