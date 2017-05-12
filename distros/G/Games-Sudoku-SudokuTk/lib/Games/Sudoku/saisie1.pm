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
# saisie1.pm treatement of seized modifications
#               function = "S" ==> solution
#               function = "R" ==> resolution
#               function = "C" ==> grid creation
#               function = "T" ==> seizure of  grid
#               function = "V" ==> seizure of solution
sub saisie1 {
        use Games::Sudoku::sudokuprincipal;
        #print "saisie1 trait= " . $trait . "\n";
        $erreur_saisie = 0;
        $#wprecarre = -1;
        # Save of context
        for ($i = 0; $i < $nbcase; $i++) {                
                for ($j = 0; $j < $nbcase; $j++) {
                        for ($k = 0; $k < $nbcase; $k++) {
                                $wprecarre[$i][$j][$k] = $precarre[$i][$j][$k];
                        }
                }
        }
        
        for ($i = 0; $i < $nbcase; $i++) {               
                for ($j = 0; $j < $nbcase; $j++) {
                        my $trouve = "0";
                        for (my $k1 = 0; $k1 < $nbcase; $k1++) { 
                                # we seek if a square is found 
                                #print " s " . $wprecarre[$i][$j][$k1];
                                if ($wprecarre[$i][$j][$k1] ne "P" 
                                        and $wprecarre[$i][$j][$k1] ne " "
                                        ) {
                                        $trouve = "1";
                                        #print "saisie1 trouve $i $j $k1\n";        
                                }
                        }
                        if ($trouve eq "0") {   # if not found
                                if ($trait eq "T" or $trait eq "V") { # seizure
                                        #print "saisieaaa $i $j\n";
                                        if ($dessin ne "animaux" and $dessin ne "couleurs") {
                                                my $b = $entrycarre[$i][$j][0]->Entry;
                                                $valeurw = $entrycarre[$i][$j][0]->get;
                                                if ($dessin eq "lettres") {
                                                        # delete spaces beginning and end
                                                        $valeurw =~ s/^\s+//;
                                                        #print ("saisie lettre " . $valeurw . "\n");
                                                        $valeurw = convertchiffre($valeurw);
                                                }
                                        } else {
                                                if ($i == $idessin and $j == $jdessin) {
                                                        $valeurw = $valdessin;
                                                } else { 
                                                        $valeurw = "";
                                                }
                                        }
                                        # delete spaces beginning and end
                                        $valeurw =~ s/^\s+//;
                                        if ($valeurw eq "A" or $valeurw eq "a") {
                                                $valeurw = 10;
                                        }
                                        if ($valeurw eq "B" or $valeurw eq "b") {
                                                $valeurw = 11;
                                        }
                                        if ($valeurw eq "C" or $valeurw eq "c") {
                                                $valeurw = 12;
                                        }
                                        if ($valeurw eq "D" or $valeurw eq "d") {
                                                $valeurw = 13;
                                        }
                                        if ($valeurw eq "E" or $valeurw eq "e") {
                                                $valeurw = 14;
                                        }
                                        if ($valeurw eq "F" or $valeurw eq "f") {
                                                $valeurw = 15;
                                        }
                                        if ($valeurw eq "G" or $valeurw eq "g") {
                                                $valeurw = 16;
                                        }
                                        if ($valeurw > 0 and $valeurw < ($nbcase + 1)) {    # if number is correct    
                                                                # There is a seizure 
                                                $erreur_aide = 0;
                                                if ($aide == 1) {
                                                        if ($precarres[$i][$j][$valeurw - 1] ne "C") {
                                                                $erreur_aide = 1;
                                                                for (my $k1 = 0; $k1 < $nbcase; $k1++) {
                                                                if ($precarres[$i][$j][$k1] ne " " and
                                                                        $precarres[$i][$j][$k1] ne "P") 
                                                                        {
                                                                        $bonnevaleur = $k1 + 1;
                                                                        last;
                                                                }
                                                                }
                                                        }
                                                }
                                                if (($precarre[$i][$j][$valeurw - 1] ne "P")
                                                        or $erreur_aide == 1) {
                                                        $erreur_saisie = 1;
                                                } else {
                                                        if ($trait eq "V") {     # we are seizing
                                                                                # a solution
                                                                $precarre[$i][$j][$valeurw - 1] = "C";
                                                                $entree = "C";
                                                        } else {        # we are seising a problem 
                                                                $precarre[$i][$j][$valeurw - 1] = "S";
                                                                $entree = "S";
                                                        }
                                                        $ligne = $i;
                                                        $colonne = $j;
                                                        $valeur = $valeurw - 1;
                                                        $endroit = "";
                                                        modif_tableau($entree);
                                                }
                                        }
                                } else {   # we are not seizing
                                        for ($k = 0; $k < $nbcase; $k++) {
                                                #print "i= " . $i . " j= " . $j . " k= " . $k . "\n";
                                                if (exists ($entrycarre[$i][$j][$k])) {
                                                        my $b = $entrycarre[$i][$j][$k]->Entry;
                                                        $valeurw = $entrycarre[$i][$j][$k]->get;
                                                        # delete spaces beginning and end 
                                                        $valeurw =~ s/^\s+//;
                                                        #print " e " . $valeurw;
                                                        if ($wprecarre[$i][$j][$k] eq "P") {
                                                                $wcarre = $k + 1;
                                                        } else {
                                                                $wcarre = " ";
                                                        } 
                                                        if ($valeurw != $wcarre) {
                                                #print (" modif i= " . $i . " j= " . $j . " k= " . $k );
                                                                $precarre[$i][$j][$k] = "S";
                                                                $ligne = $i;
                                                                $colonne = $j;
                                                                $valeur = $k;
                                                                $entree = "S";
                                                                $endroit = "";
                                                                modif_tableau($entree);
                                                        }
                                                }
                                        }
                                }
                        }
                }
        }
        #print "fin saisie1 $erreur_saisie\n";
        if ($trait eq "T") {
                affichage_grille('T');
        } elsif ($trait eq "V") {
                verif_fin();
                affichage_grille('V');
        } else {
                solution();
        }
}
1;

sub convertchiffre {     # Conversion letter in number
        my ($lettre, $code) = @_;
        my %chif = ('A','1','B','2','C','3','D','4','E','5','F','6','G','7','H','8','I','9',
                'J','10','K','11','L','12','M','13','N','14','O','15','P','16',
                'a','1','b','2','c','3','d','4','e','5','f','6','g','7','h','8','i','9',
                'j','10','k','11','l','12','m','13','n','14','o','15','p','16');
        my $chiffre = $chif{$lettre};
        #print ("convertchiffre " . $chiffre . " " . $lettre . "\n");
        return $chiffre;
}