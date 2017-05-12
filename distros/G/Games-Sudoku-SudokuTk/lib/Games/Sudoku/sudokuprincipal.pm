#* Copyright (C) 2008 Christian Guine
# * This program is free software; you can redistribute it and/or modify it
# * under the terms of the GNU General Public License as published by the Free
# * Software Fondation; either version 2 of the License, or (at your option)
# * any later version.
# * This program is distributed in the hope that it will be useful, but WITHOUT
# * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# * FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# * more details.
# * You should have received a copy of the GNU General Public License along with
# * this program; if not, write to the Free Software Foundation, Inc., 59
# * Temple Place - Suite 330, Boston, MA 02111-1307, USA.
# */
# sudokuprincipal.pm 
# to resolve Sudoku in few seconds
sub sudokuprincipal {

}
1;

sub traitement {                    # treatment of seizure   
solution();
exportation();
verif_seul();                       # we indicate if a number remains alone after calculation
$final = 0;
while ($final == 0) {
        cherche_seul();             # we seek if a number can be alone in line column or area
}
$final = 0;
while ($final == 0) {
        cherche_sequence();         # we seek if a number is surely that which misses
}                                   # in its line column or area
verif_fin();                        # we check if all is found
print $trait . "\n";

affichage_grille('F');
}

sub fin_saisie {
        $traitexport = " ";
        exportation();
        $trait = "N";
        solution();
        $traitexport = "S";
        exportation();
        $trait = "V";
        $fin = 0;
        $traitexport = " ";
        importation("","txt");
        saisie1();
}

sub saisie2 {
        #print "saisie2 trait= " . $trait . "\n";
        $erreur_saisie = 0;
        if ($trait eq "V") {
                fin_saisie();
        } elsif ($trait eq "N") {
                print ("Reprise saisie2\n");
        } else {
                saisie1();
        }
}

sub verif {
        verif_fin();                        # we verifie if all is found
        if ($fin != 1) {
                importation("","txt");
                affichage_grille('T');
        } else {
                affichage_grille('F');
        }                       
}

sub solutiond {
        $trait = "S";
        solution();
}

sub solution {                              # Posting solution
        #$topcase = 30;                #debug 
        #cherche_case_blanche1();         #debug 
        if ($trait eq "V") {
                importation('W','txt');           # backup of initial grid
        }
        if ($trait eq "S") {
                importation('S','txt');
        }
        #$topcase = 31;                #debug 
        #cherche_case_blanche1();         #debug 
        verif_seul();                       # we indicate if a number is alone
        $final = 0;
        #$topcase = 32;                #debug 
        #cherche_case_blanche1();         #debug 
        while ($final == 0) {
                cherche_seul();             # we check if a number can be alone in a line column or area
        }
        #$topcase = 33;                #debug 
        #cherche_case_blanche1();         #debug 
        $final = 0;
        while ($final == 0) {
                cherche_sequence();         # we seek if a number is surely that which misses
                                            # in its line column or area
        }
        #$topcase = 34;                #debug 
        #cherche_case_blanche1();         #debug                                   
        verif_fin();                        # we verify that all is found
        if ($trait ne "N") {
                affichage_grille('F');
        }
}

sub verif_fin                   #Checking that all is found
{
        $fin = 1;
        for ($i = 0; $i < $nbcase; $i++) {
                for ($j = 0; $j < $nbcase; $j++) {
                        for ($k = 0; $k < $nbcase; $k++) {
                                if ($precarre[$i][$j][$k] eq "P") {
                                        $fin = 0;
                                }
                        }
                }
        }
}

sub cherche_sequence         # we seek if a number is surely that which misses 
                             # in its line column or area
{
        # not implemented not useless
        #print "cherche_sequence\n";
        $final = 1;

}

sub cherche_seul
{
        #print "cherche_seul\n";
        $final = 1;
        for ($csi = 0; $csi < $nbcase; $csi++) {
                for ($csj = 0; $csj < $nbcase; $csj++) {
                        for ($csk = 0; $csk < $nbcase; $csk++) {
                                if ($precarre[$csi][$csj][$csk] eq "P") {  # we find a number
                                        # we check that it is not the only possible one in the line
                                        # column or area
                                        # checking on the column
                                        $trouve = 0;
                                        for ($wcsj = 0; $wcsj < $nbcase; $wcsj++) {
                                                if ($precarre[$csi][$wcsj][$csk] eq "P") {
                                                        $trouve++;
                                                }
                                        }
                                        if ($trouve == 1) {     
                                                $ligne = $csi;
                                                $colonne = $csj;
                                                $valeur = $csk;
                                                $entree = "C";
                                                $endroit = "colonne";
                                                #$topcase = 2;          # debug
                                                modif_tableau();
                                                #cherche_case_blanche1();         #debug 
                                                $final = 0;
                                        }
                                        # checking line
                                        $trouve = 0;
                                        for ($wcsi = 0; $wcsi < $nbcase; $wcsi++) {
                                                if ($precarre[$wcsi][$csj][$csk] eq "P") {
                                                        $trouve++;
                                                }
                                        }
                                        if ($trouve == 1) {
                                                $ligne = $csi;
                                                $colonne = $csj;
                                                $valeur = $csk;
                                                $entree = "C";
                                                $endroit = "ligne";
                                                #$topcase = 21;
                                                modif_tableau();
                                                #cherche_case_blanche1();         #debug  
                                                $final = 0;
                                        }
                                        # checking area
                                        $trouve = 0;
                                        ($wimin, $wimax, $wjmin, $wjmax) =     
                                                calminmax ($nbcase, $csi, $csj);
                                        for ($wcsi = $wimin; $wcsi < $wimax; $wcsi++) {
                                                for ($wcsj = $wjmin; $wcsj < $wjmax; $wcsj++) {
                                                        if ($precarre[$wcsi][$wcsj][$csk] eq "P") {
                                                                $trouve++;
                                                        }
                                                }
                                        }
                                        if ($trouve == 1) {
                                                $ligne = $csi;
                                                $colonne = $csj;
                                                $valeur = $csk;
                                                $entree = "C";
                                                $endroit = "carre";
                                                #$topcase = 22;
                                                modif_tableau();
                                                #cherche_case_blanche1();         #debug 
                                                $final = 0;
                                        }
                                }
                        }
                }
        }
}

sub verif_seul                  # we verify that the number found is the only one in the square
{
        #print "verif_seul\n";
        for ($vsi = 0; $vsi < $nbcase; $vsi++) {
                for ($vsj = 0; $vsj < $nbcase; $vsj++) {
                        $seul = 0;
                        for ($vsk = 0; $vsk < $nbcase; $vsk++) {
                                if ($precarre[$vsi][$vsj][$vsk] eq "P") {
                                        $seul++;
                                }
                        }
                        if ($seul == 1) {
                                for ($vsk = 0; $vsk < $nbcase; $vsk++) {
                                        if ($precarre[$vsi][$vsj][$vsk] eq "P") {
                                                $ligne = $vsi;
                                                $colonne = $vsj;
                                                $valeur = $vsk;
                                                $entree = "C";
                                                $endroit = "";
                                                #$topcase = 23;
                                                modif_tableau();
                                                #cherche_case_blanche1();         #debug
                                                $final = 0;
                                        }
                                }
                        }
                }
        }          
}

sub modif_tableau                       # If a number is found we cancel the possibility 
                                        #       of this number on the same line, the same column
                                        #       and the same area
{
        #print "modif_tableau " . $entree . " endroit " . $endroit . " ligne " . ($ligne + 1) 
         #       . " colonne " . ($colonne + 1) . " valeur " . ($valeur + 1) . "\n";
        if ($entree ne "P") {
                $precarre[$ligne][$colonne][$valeur] = $entree;            # S pour seizure C for calculated
        }
        for ($wwi = 0; $wwi < $nbcase; $wwi++) {       # delete line
                if ($entree ne "P") {
                        if ($precarre[$wwi][$colonne][$valeur] eq "P") {
                                $precarre[$wwi][$colonne][$valeur] = " ";
                        }
                } else {                                # entree P we backup
                        if ($precarre[$wwi][$colonne][$valeur] eq " ") {
                                $trouve = 0;
                                for (my $wwk1 = 0; $wwk1 < $nbcase; $wwk1++) {
                                        if ($precarre[$wwi][$colonne][$wwk1] eq "S" 
                                                or $precarre[$wwi][$colonne][$wwk1] eq "C") {
                                                $trouve = 1;
                                        }
                                }
                                if ($trouve == 0) {
                                        $precarre[$wwi][$colonne][$valeur] = "P";
                                }
                        }
                }
        }
        for ($wwj = 0; $wwj < $nbcase; $wwj++) {       # delete column
                if ($entree ne "P") {
                        if ($precarre[$ligne][$wwj][$valeur] eq "P") {
                                $precarre[$ligne][$wwj][$valeur] = " ";
                        }
                } else {                                # entree P we backup
                        if ($precarre[$ligne][$wwj][$valeur] eq " ") {
                                $trouve = 0;
                                for (my $wwk1 = 0; $wwk1 < $nbcase; $wwk1++) {
                                        if ($precarre[$ligne][$wwj][$wwk1] eq "S" 
                                                or $precarre[$ligne][$wwj][$wwk1] eq "C") {
                                                $trouve = 1;
                                        }
                                }
                                if ($trouve == 0) {
                                        $precarre[$ligne][$wwj][$valeur] = "P";
                                }
                        }
                }
        }
        for ($wwk = 0; $wwk < $nbcase; $wwk++) {       # delete area
                if ($entree ne "P") {
                        if ($precarre[$ligne][$colonne][$wwk] eq "P") {
                                $precarre[$ligne][$colonne][$wwk] = " ";
                        }
                } else {                                # entree P we backup
                        if ($precarre[$ligne][$colonne][$wwk] eq " ") {
                                $trouve = 0;
                                for (my $wwk1 = 0; $wwk1 < $nbcase; $wwk1++) {
                                        if ($precarre[$ligne][$colonne][$wwk1] eq "S" 
                                                or $precarre[$ligne][$colonne][$wwk1] eq "C") {
                                                $trouve = 1;
                                        }
                                }
                                if ($trouve == 0) {
                                        $precarre[$ligne][$colonne][$wwk] = "P";
                                }
                        }
                }
        }
        # delete possibility on an area
        ($wimin, $wimax, $wjmin, $wjmax) = calminmax ($nbcase, $ligne, $colonne);
        for ($wwi = $wimin; $wwi < $wimax; $wwi++) {
                for ($wwj = $wjmin; $wwj < $wjmax; $wwj++) {
                        if ($entree ne "P") {
                                if ($precarre[$wwi][$wwj][$valeur] eq "P") {
                                        $precarre[$wwi][$wwj][$valeur] = " ";
                                }
                        } else {                                # entree P we backup
                                if ($precarre[$wwi][$wwj][$valeur] eq " ") {
                                        $trouve = 0;
                                        for (my $wwk1 = 0; $wwk1 < $nbcase; $wwk1++) {
                                                if ($precarre[$wwi][$wwj][$wwk1] eq "S" 
                                                        or $precarre[$wwi][$wwj][$wwk1] eq "C") {
                                                        $trouve = 1;
                                                }
                                        }
                                        if ($trouve == 0) {
                                                $precarre[$wwi][$wwj][$valeur] = "P";
                                        }
                                }
                        }
                }
        }
        if ($entree eq "P") {
                $precarre[$ligne][$colonne][$valeur] = $entree;            # S pour seizure 
                                                                                # C for calculated
        }
        #cherche_case_blanche1();         #debug 
}

sub importations
{
        use IO::File;
        $filehandle = new IO::File;
        my $retour = $filehandle->open("< sudokus$nbcase.txt") 
                or die "impossible ouvrir sudokus importations";  
        $#precarres = -1;
        for (my $i = 0; $i < $nbcase; $i++) {
                for (my $j = 0; $j < $nbcase; $j++) {
                        for (my $k = 0; $k < $nbcase; $k++) {
                                $filehandle->read($newtext,1);
                                $precarres[$i][$j][$k] = $newtext;
                        }
                }
        }
        $filehandle->close;       
}

sub importation                 #importation data from a file
{         
        use IO::File;
        #use File::Copy;
        $#precarre = -1;
        my ($traitexport, $extension) = @_;
        if ($extension =~ m/sav/) {
                $pref1 = $pref . "/sav/";
        } else {
                $pref1 = "";
        }
        #print "importation " . $traitexport . " extension " . $extension . "\n";
        $filehandle = new IO::File; 
        my $fic = $pref1 . "sudoku" . $nbcase . "." . $extension;
        my $fics = $pref1 . "sudokus" . $nbcase . "." . $extension;
        if ($traitexport eq "S") {
                 my $retour = $filehandle->open("< $fics") 
                        or die "impossible ouvrir sudokus$nbcase";     
        } else {
                my $retour = $filehandle->open("< $fic");
                print "fic $fic retour $retour\n";
                if ($retour != 1) {
                        $filesortie = new IO::File;
                        $filesortie->open("> $fic") 
                              or die "impossible ouvrir sortie $fic";
                        $filesortie->write(" ", 1);
                        $filesortie->close;
                }
                $filehandle->close;
                $filehandle->open("< $fic") 
                        or die "impossible d'ouvrir fichier";
        }
        print "restauration eff\n"; 
        $#precarre = -1;
        for ($i = 0; $i < $nbcase; $i++) {
                for ($j = 0; $j < $nbcase; $j++) {
                        for ($k = 0; $k < $nbcase; $k++) {
                                $filehandle->read($newtext,1);
                                $precarre[$i][$j][$k] = $newtext;
                        }
                }
        }
        $filehandle->close; 
}

sub sauve
{
        $traitexport = " ";
        exportation();
}

sub exportation {
        use IO::File;
        #print "exportation trait " . $traitexport . " cpt1= " . $cpt1 . "\n";
        $filesortie = new IO::File;
        if ($traitexport eq "S") {
                $filesortie->open("> sudokus$nbcase.txt") 
                        or die "impossible ouvrir sortie sudokus$nbcase";
        } else {
                $filesortie->open("> sudoku$nbcase.txt") or die "impossible ouvrir sortie ";
        }
        $cpt2 = 0;
        for ($i = 0; $i < $nbcase; $i++) {
                for ($j = 0; $j < $nbcase; $j++) {
                        for ($k = 0; $k < $nbcase; $k++) {
                                $text = $precarre[$i][$j][$k];
                                $filesortie->write($text, 1);
                        }
                }
        }
        $filesortie->close;             
}

sub init_tableau {
        # initialization table
        for ($i = 0; $i < $nbcase; $i++) {                # init lines
                for ($j = 0; $j < $nbcase; $j++) {        # init columns
                        for ($k = 0; $k < $nbcase; $k++) { # init areas
                                $precarre[$i][$j][$k] = "P"; # P for possible
                        }
                }
        }
}
 
sub retour_arriere {
        print "backup $difficulte\n";
        my $cpt = 0;
        my $cpt1 = 0;
        #edit();
        while ($cpt < $difficulte and $cpt1 < 100) {
                $cpt1++;
                my $is = int(rand($nbcase));
                my $js = int(rand($nbcase));
                my $ks = int(rand($nbcase));
                if ($precarre[$is][$js][$ks] eq "C" or 
                        $precarre[$is][$js][$ks] eq "S") {
                                #print "retour arriere $is $js $ks\n";
                                $ligne = $is;
                                $colonne = $js;
                                $valeur = $ks;
                                $entree = "P";
                                $endroit = "";
                                modif_tableau();
                                #edit();
                                $cpt++;
                        }

        }
} 

sub cherche_case_blanche {
        # it is checked that there is no completely cancelled square
        for ($wic = 0; $wic < $nbcase; $wic++) {                
                for ($wjc = 0; $wjc < $nbcase; $wjc++) {
                        $trouvec = 0;
                        for ($wkc = 0; $wkc < $nbcase; $wkc++) {
                                if ($precarre[$wic][$wjc][$wkc] ne " ") {
                                        $trouvec = 1;
                                }
                        }
                        if ($trouvec == 0 and $topcase != 0) {    #debug supprimer
                              print ("\ncase blanche ic " . $wic . " jc " . $wjc . " topcase" . $topcase 
                                #. " vsi " . $vsi . " vsj " . $vsj .
                                #" vsk " . $vsk . " csi " . $csi . " csj " . $csj .
                                #" csk " . $csk . "cptcase" . $cptcaseblanche . " cpt " . $cpt 
                                #. " cpt1 " . $cpt1 . "\n");
                                . " ");
                              #edit(); 
                              #exit;
                                $caseblanche = 1;
                                $cptcaseblanche++;
                                if ($cptcaseblanche > 3000) {
                                        $force = 1;
                                }
                                $topcase = 0;
                        }
                }
        }
}

sub edit {
        my $edit;
        for (my $wid = 0; $wid < $nbcase; $wid++) {                
                for (my $wjd = 0; $wjd < $nbcase; $wjd++) {
                        print ("|" . $wid . "." . $wjd . ".");
                        for (my $wkd = 0; $wkd < $nbcase; $wkd++) {
                                #if ($precarre [$wid][$wjd][$wkd] ne $wprecarre [$wid][$wjd][$wkd]) {
                                        $edit = $precarre [$wid][$wjd][$wkd];
                                        if ($edit eq " ") {
                                                $edit = "_";
                                        }
                                    print ($edit);
                                 #   print ($wprecarre [$wid][$wjd][$wkd] . "|");
                                #}
                        }
                }
                print "\n";
        }               
}

sub calminmax {
        my ($nbcase, $ligne, $colonne, $code) = @_;
        my $wimax = 0;
        my $wimin = 0;
        my $wjmax = 0;
        my $wjmin = 0;
        if ($nbcase == 4) {                     # Enfant
                if ($ligne < 2) {
                        $wimax = 2;
                        $wimin = 0;
                } else {
                        $wimax = 4;
                        $wimin = 2;
                }
                if ($colonne < 2) {
                        $wjmax = 2;
                        $wjmin = 0;
                } else {
                        $wjmax = 4;
                        $wjmin = 2;
                }
        }
        if ($nbcase == 6) {                     # Simpliste
                if ($ligne < 2) {
                        $wimax = 2;
                        $wimin = 0;
                } elsif ($ligne < 4) {
                        $wimax = 4;
                        $wimin = 2;
                } else {
                        $wimax = 6;
                        $wimin = 4;
                }
                if ($colonne < 3) {
                        $wjmax = 3;
                        $wjmin = 0;
                } else {
                        $wjmax = 6;
                        $wjmin = 3;
                }
        }
        if ($nbcase == 8) {                     # Ardu
                if ($ligne < 2) {
                        $wimax = 2;
                        $wimin = 0;
                } elsif ($ligne < 4) {
                        $wimax = 4;
                        $wimin = 2;
                } elsif ($ligne < 6) {
                        $wimax = 6;
                        $wimin = 4;
                } else {
                        $wimax = 8;
                        $wimin = 6;
                }
                if ($colonne < 4) {
                        $wjmax = 4;
                        $wjmin = 0;
                } else {
                        $wjmax = 8;
                        $wjmin = 4;
                }
        }
        if ($nbcase == 9) {                     # Normal
                if ($ligne < 3) {
                        $wimax = 3;
                        $wimin = 0;
                } elsif ($ligne < 6) {
                        $wimax = 6;
                        $wimin = 3;
                } else {
                        $wimax = 9;
                        $wimin = 6;
                }
                if ($colonne < 3) {
                        $wjmax = 3;
                        $wjmin = 0;
                } elsif ($colonne < 6) {
                        $wjmax = 6;
                        $wjmin = 3;
                } else {
                        $wjmax = 9;
                        $wjmin = 6;
                }
        }
        if ($nbcase == 10) {                     # Difficile
                if ($ligne < 2) {
                        $wimax = 2;
                        $wimin = 0;
                } elsif ($ligne < 4) {
                        $wimax = 4;
                        $wimin = 2;
                } elsif ($ligne < 6) {
                        $wimax = 6;
                        $wimin = 4;
                } elsif ($ligne < 8) {
                        $wimax = 8;
                        $wimin = 6;
                } else {
                        $wimax = 10;
                        $wimin = 8;
                }
                if ($colonne < 5) {
                        $wjmax = 5;
                        $wjmin = 0;
                } else {
                        $wjmax = 10;
                        $wjmin = 5;
                }
        }
        if ($nbcase == 12) {                     # Tresdifficile
                if ($ligne < 3) {
                        $wimax = 3;
                        $wimin = 0;
                } elsif ($ligne < 6) {
                        $wimax = 6;
                        $wimin = 3;
                } elsif ($ligne < 9) {
                        $wimax = 9;
                        $wimin = 6;
                } else {
                        $wimax = 12;
                        $wimin = 9;
                }
                if ($colonne < 4) {
                        $wjmax = 4;
                        $wjmin = 0;
                } elsif ($colonne < 8) {
                        $wjmax = 8;
                        $wjmin = 4;
                } else {
                        $wjmax = 12;
                        $wjmin = 8;
                }
        }
        if ($nbcase == 16) {                    # Maxi
                if ($ligne < 4) {
                        $wimax = 4;
                        $wimin = 0;
                } elsif ($ligne < 8) {
                        $wimax = 8;
                        $wimin = 4;
                } elsif ($ligne < 12) {
                        $wimax = 12;
                        $wimin = 8;
                } else {
                        $wimax = 16;
                        $wimin = 12;
                }
                if ($colonne < 4) {
                        $wjmax = 4;
                        $wjmin = 0;
                } elsif ($colonne < 8) {
                        $wjmax = 8;
                        $wjmin = 4;
                } elsif ($colonne < 12) {
                        $wjmax = 12;
                        $wjmin = 8;
                } else {
                        $wjmax = 16;
                        $wjmin = 12;
                }
        }
        return($wimin, $wimax, $wjmin, $wjmax);
} 

sub calminmaxred {
        my ($nbcase, $code) = @_;
        # Enfant -- --  Simpliste --- --- Ardu ---- ---- Normal --- --- --- Maxi ---- ---- ---- ---- 
        #        -- --            --- ---      ---- ----        --- --- ---      ---- ---- ---- ----
        #                                                       --- --- ---      ---- ---- ---- ----
        #                         --- ---      ---- ----                         ---- ---- ---- ----
        #                         --- ---      ---- ----        --- --- ---
        #                                                       --- --- ---      ---- ---- ---- ----
        #                         --- ---      ---- ----        --- --- ---      ---- ---- ---- ----
        #                         --- ---      ---- ----                         ---- ---- ---- ---- 
        #                                                       --- --- ---      ---- ---- ---- ----
        #                                      ---- ----        --- --- ---
        #                                      ---- ----        --- --- ---      ---- ---- ---- ----
        #                                                                        ---- ---- ---- ----
        #                                                                        ---- ---- ---- ----
        #                                                                        ---- ---- ---- ----
        #
        #                                                                        ---- ---- ---- ----
        #                                                                        ---- ---- ---- ----
        #                                                                        ---- ---- ---- ----
        #                                                                        ---- ---- ---- ----
        # Difficile ----- ----- Tresdifficile ---- ---- ----
        #           ----- -----               ---- ---- ----
        #                                     ---- ---- ----
        #           ----- -----
        #           ----- -----               ---- ---- ----
        #                                     ---- ---- ----
        #           ----- -----               ---- ---- ----
        #           ----- -----    
        #                                     ---- ---- ----
        #           ----- -----               ---- ---- ----
        #           ----- -----               ---- ---- ----
        #                                   
        #           ----- -----               ---- ---- ----
        #           ----- -----               ---- ---- ----
        #                                     ---- ---- ----
        my $wimax = 0;                  
        my $wjmax = 0;                  
        my $wimax1 = O;                 
        my $wjmax1 = 0;
        if ($nbcase == 4) {             # Enfant
                $wimax = 2;                     # number area vertical
                $wjmax = 2;                     # number area horizontal
                $wimax1 = 2;                    # number of vertical figures (lines) in an area
                $wjmax1 = 2;                    # number of horizontal figures (columns) in an area
        } elsif ($nbcase == 6) {        # Simpliste
                $wimax = 3;
                $wjmax = 2;
                $wimax1 = 2;
                $wjmax1 = 3;
        } elsif ($nbcase == 8) {        # Ardu
                $wimax = 4;
                $wjmax = 2;
                $wimax1 = 2;
                $wjmax1 = 4;
        } elsif ($nbcase == 10) {       # Difficile
                $wimax = 5;
                $wjmax = 2;
                $wimax1 = 2;
                $wjmax1 = 5;
        } elsif ($nbcase == 12) {       # Maxi
                $wimax = 4;
                $wjmax = 3;
                $wimax1 = 3;
                $wjmax1 = 4;
        } elsif ($nbcase == 16) {       # Maxi
                $wimax = 4;
                $wjmax = 4;
                $wimax1 = 4;
                $wjmax1 = 4;
        } else {                        # Normal
                $wimax = 3;
                $wjmax = 3;
                $wimax1 = 3;
                $wjmax1 = 3;
        }
        return ($wimax, $wjmax, $wimax1, $wjmax1);
}             