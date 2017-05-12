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
# newgrille.pm design of a new grid
# voir lorsqu on a trouve une case blanche si on se repositionne tout de suite
sub newgrille { 
        use Games::Sudoku::sudokuprincipal;
        use Games::Sudoku::affichgrille; 
        use Games::Sudoku::conf;
        conf();
        if ($wcanvas == 1) {            # delete Label of beginning
                $canvas -> destroy;
                $framed -> destroy;
                $wcanvas = 0;
                $frame1 = $main->Frame;
                $frame1->pack;
        }
        $trait = "N";
        $oldwcpt = 0;
        $fin = 0;
        $force = 0;
        BOUCLE:while ($fin == 0 and $force == 0) {   # loop as much as a solution was not found 
                                                # where all is found
        print "debut boucle\n";
        init_tableau();                         # initialization table
        $fin = 0;
        $cpt = 0;
        $wcpt2 = 0;
        $toploop = 0;
        $cptpris = 0;
        $cptblanc = 0;
        $cptlibre = 0;
        $nbreposit = 0;
        $cptcaseblanche = 0;
        $restauresolution = 0;
        $wsi = 0;
        $wsj = 0;
        $wsk = 0;
        $wwsi = 0;
        $wwsj = 0;
        $wwsk = 0;
        $wtoploop = 0;
        $ic = 0;
        $jc = 0;
        $kc = 0;
        $aic = 0;                # init index for "affect"
        $ajc = 0;
        $akc = -1;
        $affect = 0;
        if ($nbcase == 16) {
                $cptloop = 10000;
        } else {
                $cptloop = 500;
        }
                LOOP:while (($fin == 0) and ($cpt < $cptloop) 
                                and ($toploop < 150)) { #loop for filling the grid
                                        #$topcase = 5;      # debug 
                                        #cherche_case_blanche1();                
                        $cpt++;
                        $wcpt2++;
                        $topreplace = 0;
                        if ($wcpt2 > 2000) {
                                comptageOK();
                                if (($nbcase != 6 and $nbcase != 8 and $nbcase != 9 and $nbcase != 4) # pour debug à enlever
                                        and $toploop > 1) {   # pour debug à enlever
                                        $force = 1;          # pour debug à enlever
                                        last;                   # pour debug à enlever
                                }                               # pour debug à enlever
                                print ("Reprise comptage\n");
                                $wcpt2 = 0;
                        }
                        #$topcase = 7;      # debug
                        #cherche_case_blanche1();
                        # random search of a number
                        if ($wtoploop == 1) {    
                                if ($wsi == $wwsi and $wsj == $wwsj and $wsk == $wwsk) { # we verifie 
                                                                                #that all possibilities 
                                                                                # are explored
                                        print ("Tout est pris arret\n");
                                        $fin = 0;
                                        $force = 1;      # change force = 0 for no stopping
                                        last;
                                }
                                $wwsi = $wsi;
                                $wwsj = $wsj;
                                $wwsk = $wsk;
                                $i = $wsi;
                                $j = $wsj;
                                $k = $wsk;
                                $wtoploop = 0;
                                $topreplace = 1;
                                $nbreposit++;
                                print "ligne= " . ($i + 1) . " colonne= " . ($j + 1) . " valeur= " 
                                . ($k + 1) . " cpt= " . $cpt . " toploop= " . $toploop . " cptlibre= " 
                                . $cptlibre . "\n";
                        } else {
                                if ($cpt < 300) {
                                        #print("rand");
                                        $i = int(rand($nbcase));
                                        $j = int(rand($nbcase));
                                        $k = int(rand($nbcase));
                                } else {
                                        print "affect1";
                                        affect();
                                        if ($cpt > 800) {
                                                print ("arret cpt > 800\n");
                                                $restauresolution = 1;          # restaure solution
                                                $force = 1;
                                        }
                                }
                        }
                #print "ligne= " . ($i + 1) . " colonne= " . ($j + 1) . " valeur= " . ($k + 1) 
                 #       . " cpt= " . $cpt . "\n";
                        $caseblanche = 0;
                        #$topcase = 9;      # debug 
                        #cherche_case_blanche1();
                        if ($precarre[$i][$j][$k] ne "P") {
                                $cpt--;
                                $wcpt2--;
                                if ($topreplace == 1) {
                                        print ("deja pris");
                                }
                                print "KO$i$j$k";
                                $cptpris++;
                                        #$topcase = 8;      # debug
                                        #cherche_case_blanche1();
                                next LOOP;
                        }
                        print "OK$i$j$k"; 
                        #$topcase = 10;      # debug
                        #cherche_case_blanche1();
                        $#wprecarre = -1;
                        # save before checking correct choice
                        for (my $wi = 0; $wi < $nbcase; $wi++) {                
                                for (my $wj = 0; $wj < $nbcase; $wj++) {
                                        for (my $wk = 0; $wk < $nbcase; $wk++) {
                                                $wprecarre[$wi][$wj][$wk] = $precarre[$wi][$wj][$wk];
                                        }
                                        #cherche_case_blanche1();   # debug
                                }
                        }
                        #$topcase = 1;      # debug 
                        #cherche_case_blanche1();   # debug 
                        # we cancel the other possibility on line column and area
                        $precarre[$i][$j][$k] = "S";
                        $trait = "N";
                        $ligne = $i;
                        $colonne = $j;
                        $valeur = $k;
                        $entree = "S";
                        $endroit = "";
                        $topcase = 11;
                        modif_tableau();
                        $topcase = 30;
                        # it is checked that there is no completely cancelled square
                        cherche_case_blanche1();
                        $final = 0;
                        solution();             # we are checking that all is found
                        $caseblanche = 0;
                        cherche_case_blanche1();
                        verifnbcase();
                        exportation();
                        $topcase = 4;          #debug
                        cherche_case_blanche1();       
                }
                # it is checked that all is filled
                #$fin = 1;    # we stop more we go on
                $fin = 1;      # put in zero not to stop any more
                $cpt1 = 0;
                for (my $wi = 0; $wi < $nbcase; $wi++) {                
                        for (my $wj = 0; $wj < $nbcase; $wj++) {
                                $trouve = 0;
                                for (my $wk = 0; $wk < $nbcase; $wk++) {
                                        if ($precarre[$wi][$wj][$wk] ne " " 
                                                and $precarre[$wi][$wj][$wk] ne "P") {
                                                $trouve = 1;
                                                if ($precarre[$wi][$wj][$wk] eq "S") {
                                                        $cpt1++;      
                                                }                 
                                        }
                                }
                                if ($trouve == 0) {
                                        $fin = 0;       # we start again
                                }
                        }
                }
                $topcase = 11;      # debug
                cherche_case_blanche1();
                print "fin cpt1= " . $cpt1 . " fin= " . $fin . " toploop= " . $toploop . "\n";
        }
        #$traitexport = "S";
        #exportation();                # save the solution
        # Preparation grid for posting
        for (my $wi = 0; $wi < $nbcase; $wi++) {                
                        for (my $wj = 0; $wj < $nbcase; $wj++) {
                                $trouve = 0;
                                # Is it a seizure in the square? 
                                for (my $wk1 = 0; $wk1 < $nbcase; $wk1++) {
                                        if ($precarre[$wi][$wj][$wk1] eq "S") {
                                                $trouve = 1;
                                                last;
                                        }
                                }      
                                for (my $wk = 0; $wk < $nbcase; $wk++) {
                                        if ($precarre[$wi][$wj][$wk] ne "S") {
                                                if ($trouve == 0) { # if we find a seizure
                                                        $precarre[$wi][$wj][$wk] = "P";
                                                } else {
                                                        $precarre[$wi][$wj][$wk] = " ";
                                                }
                                        } 
                                }
                        }
        }
        #$topcase = 6;      # debug 
        #cherche_case_blanche1();
        # Elimination of impossible combinations
        for (my $wi = 0; $wi < $nbcase; $wi++) {                
                        for (my $wj = 0; $wj < $nbcase; $wj++) {
                                $trouve = 0;
                                for (my $wk = 0; $wk < $nbcase; $wk++) {
                                        if ($precarre[$wi][$wj][$wk] eq "S") {
                                                $entree = "S";
                                                $ligne = $wi;
                                                $colonne = $wj;
                                                $valeur = $wk;
                                                $endroit = "";
                                                $topcase = 12;
                                                modif_tableau($entree); 
                                        }
                                }
                        }
        }
        restaure_solution();
        $fin = 0;
        $traitexport = " ";
        exportation();
        $traitexport = "S";
        exportation();          # save the solution
        retour_arriere();       # abolition no one or two seizures according to difficulty
        $traitexport = " ";
        exportation();
        affichage_grille('V');
        $timedebut = time;
        fin_saisie();
        if ($nbcase == 16 and $affect == 0) {           # sauvegarde solutions
                if ($system eq "linux") {
                        #my $t = time;
                        my @tab = ("cp", "sudoku16.txt", "sudoku16$t.txt");   # sauvegarde
                        system @tab;
                        @tab = ("cp", "sudokus16.txt", "sudokus16$t.txt");
                        system @tab;
                }
        }
        if (defined($fabrication) and $fabrication == 1) {       # sauvegarde solutions
                newgrille();
        }
}
1;

sub comptageOK {
        $wcpt3 = 0;
        my $n1cpt = 0;
        $cptlibre = 0;
        $wcptstock = 0;
        for (my $wi = 0; $wi < $nbcase; $wi++) {
                for (my $wj = 0; $wj < $nbcase; $wj++) {
                        for (my $wk = 0; $wk < $nbcase; $wk++) {
                                if ($precarre[$wi][$wj][$wk] eq "S" or $precarre[$wi][$wj][$wk] eq "C")
                                {
                                        $wcpt3++;
                                } elsif ($precarre[$wi][$wj][$wk] eq "P") {
                                        if (($wsi < $wi or
                                                ($wsi == $wi and $wsj < $wj) or
                                                ($wsi == $wi and $wsj == $wj and $wsk < $wk))
                                                and $wcptstock == 0) {
                                                        $n1cpt++;
                                                        if ($n1cpt >= $nbreposit) { # having so already 
                                                                                #re-positioned them ask 
                                                                        #for following free position
                                                                $wsi = $wi;
                                                                $wsj = $wj;
                                                                $wsk = $wk;
                                                                $wcptstock = 1;
                                                        #print ("stock1 wi= " . $wi . " wj= " . $wj . 
                                                        #      " wk= " . $wk . "\n");
                                                        }
                                        }
                                        $cptlibre++;
                                }
                        }
                }
        }
        #print "comptage" . $wcpt3 . " fin= " . $fin . " cpt= " . $cpt . " cptloop= " . $cptloop .
         #       " toploop= " . $toploop . " cptpris= " . $cptpris . " cptblanc= " . $cptblanc . "\n";
        $wtoploop = 0;
        if ($wcpt3 == $oldwcpt) {
                $toploop++;          # we stop the loop if the number of thrue squares is not greater
                $wtoploop = 1;
        }
        $cptpris = 0;
        $cptblanc = 0;
        $oldwcpt = $wcpt3;
}

sub affect {                            # allocation square free since the beginning
        for ($aic = $aic; $aic < $nbcase; $aic ++) {
                for ($ajc = $ajc; $ajc < $nbcase; $ajc++) {
                        for ($akc = $akc + 1; $akc < $nbcase; $akc++) {
                                if ($precarre[$aic][$ajc][$akc] eq "P") {
                                        $i = $aic;
                                        $j = $ajc;
                                        $k = $akc;
                                        print ("affect " . $aic . "," . $ajc . "," . $akc . "\n");
                                        last;
                                } 
                        }
                        if ($precarre[$aic][$ajc][$akc] eq "P") {
                                last;
                        } else {
                                $akc = -1;
                        }
                }
                if ($precarre[$aic][$ajc][$akc] eq "P") {
                                last;
                } else {
                        $ajc = 0;
                }
        }
        print("affect i= " . $i . " j = " . $j . " k = " . $k . " nbcases " . $nbcase . "\n");
        if ($aic == ($nbcase)) {
                print("tout a ete examine \n");
                $fin = 1;
                $affect = 1;          # supprimer si pas de recherche solution
        }
}

sub cherche_case_blanche1 {
        $caseblanche = 0;
        cherche_case_blanche();
        if ($caseblanche == 1) {
                print ("Restauration2 topcase = $topcase\n");
                $#precarre = -1;
                for ($wi = 0; $wi < $nbcase; $wi++) {                
                        for ($wj = 0; $wj < $nbcase; $wj++) {
                                for ($wk = 0; $wk < $nbcase; $wk++) {
                                        $precarre[$wi][$wj][$wk] = 
                                        $wprecarre[$wi][$wj][$wk];
                                }
                        }
                }
        }
}

sub verifnbcase {
        # Check that in an area the number of squares determined 
        # + the possible number of squares is equal to nbcase 
        # otherwise restoration
        #print ("verifnbcase\n");
        $wimin = 0;
        $wjmin = 0;
        $restaur = 0;
        if ($nbcase == 9) {
                $plusi = 3;
                $plusj = 3;
        } elsif ($nbcase == 4) {
                $plusi = 2;
                $plusj = 2;
        } elsif ($nbcase == 6) {
                $plusi = 2;
                $plusj = 3;
        } elsif ($nbcase == 8) {
                $plusi = 2;
                $plusj = 4;
        } elsif ($nbcase == 10) {
                $plusi = 2;
                $plusj = 5;
        } elsif ($nbcase == 12) {
                $plusi = 3;
                $plusj = 4;
        } else {
                $plusi = 4;
                $plusj = 4;
        }
        for ($ligne = 0; $ligne < $nbcase; $ligne = $ligne + $plusi) {
                for ($colonne = 0; $colonne < $nbcase; $colonne = $colonne + $plusj) {
                        ($wimin, $wimax, $wjmin, $wjmax) = calminmax($nbcase, $ligne, $colonne);
                        # counting numbers possible squares in an area
                        $wcpt1 = 0;
                        $#area = -1;
                        if ($nbcase == 4) {
                                @area = (0,0,0,0);
                        } elsif ($nbcase == 6) {
                                @area = (0,0,0,0,0,0);
                        } elsif ($nbcase == 8) {
                                @area = (0,0,0,0,0,0,0,0);
                        } elsif ($nbcase == 9) {
                                @area = (0,0,0,0,0,0,0,0,0);
                        } elsif ($nbcase == 10) {
                                @area = (0,0,0,0,0,0,0,0,0,0);
                        } elsif ($nbcase == 12) {
                                @area = (0,0,0,0,0,0,0,0,0,0,0,0);
                        } else {
                                @area = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
                        }
                        for ($wim = $wimin; $wim < $wimax; $wim++) {
                                for ($wjm = $wjmin; $wjm < $wjmax; $wjm++) {
                                        for ($wkm = 0; $wkm < $nbcase; $wkm++) {
                                                if ($precarre[$wim][$wjm][$wkm] ne " ") { 
                                                        $area[$wkm] = 1;
                                                }
                                       }
                                }
                        }
                        for ($iarea = 0; $iarea < $nbcase; $iarea++) {
                                $wcpt1 = $wcpt1 + $area[$iarea];
                        }
                        if ($wcpt1 != $nbcase) {          #impossible solution we backup
                                print ("\nverifnbcase $wimin $wjmin $wcpt1 restaure\n");
                                $#precarre = -1;
                                for ($wim = 0; $wim < $nbcase; $wim++) {                
                                        for ($wjm = 0; $wjm < $nbcase; $wjm++) {
                                                for ($wkm = 0; $wkm < $nbcase; $wkm++) {
                                                        $precarre[$wim][$wjm][$wkm] = 
                                                        $wprecarre[$wim][$wjm][$wkm];
                                                }
                                        }
                                }             
                        }
                }
        }
}

sub restaure_solution {
        use Games::Sudoku::conf;
        use Games::Sudoku::sudokuprincipal;
        conf();
        # we choose a solution 
        if ($restauresolution == 1 and $nbcase == 16) {
                my $i = int(rand($nbsolution));
                importation("","sav$i");    
                print ("restaure_solution sav$i\n");                   
        }
}