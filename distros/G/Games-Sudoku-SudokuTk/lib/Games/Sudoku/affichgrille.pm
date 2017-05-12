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
# affichgrille.pm    Posting of a grid 
#               fonction = "S" ==> solution
#               fonction = "R" ==> resolution
#               fonction = "C" ==> grid creation
#               fonction = "T" ==> seizure grid
#               fonction = "V" ==> seizure solution
sub affichgrille {
        use Tk;
        use Games::Sudoku::menu;
        use Games::Sudoku::tr1;
        use Games::Sudoku::conf;
        conf();
        $timedebut = time;
        if ($wcanvas == 1) {                    # cancellation image beginning 
                if ($skin == 1) {
                        $frame1 -> destroy;
                } else {
                        $canvas -> destroy;
                        $framed1 -> destroy;
                        $framed2 -> destroy;
                }
                $wcanvas = 0;
        } else {
                $frame1 -> destroy;
        }
        ($fonction) = @_;
        if ($Enfant == 1) {
                $nbcase = 4; 
        } elsif ($MaxiSudoku == 1) {
                $nbcase = 16;
        } elsif ($Simpliste == 1) {
                $nbcase = 6;       
        } elsif ($Ardu == 1) {
                $nbcase = 8;
        } elsif ($Difficile == 1) {
                $nbcase = 10;
        } elsif ($Tresdifficile == 1) {
                $nbcase = 12;
        } else  {
                $nbcase = 9;            # Normal
        }
        if ($fonction eq "S") {
                menu('affichgrilleS');
        } else {
                menu('affichgrille');
        }
        if ($fonction eq "R") {
                $frame1 = $main->Frame(-width => 850, -height => 600);
                $frame1->pack(-side=>'left');
                my $frame2 = $frame1->Frame;            # Posting Question 
                $frame2->pack;
                $frame2->Label(-text=>tr1('Est ce une nouvelle grille? oui/non'),
                        -font => "Nimbus 15")->pack(-side=>'left');
                $listoption = $frame2->Listbox(-width => 5, -height => 2)->pack(-side=>'right');
                $listoption->insert('end',tr1('OUI'),tr1('NON'));
                $listoption->activate(0);
                $listoption->bind('<Double-1>',\&OK1);
                $main->bind('<Key-Return>', => [\&OK1]);
                my $frame3 =$frame1->Frame;
                        $frame3->pack;
                $frame3 = $frame1->Button (
                                -command=>[\&OK1],
                                -text=>tr1('OK')
                        )->pack();
        } elsif ($fonction eq "C") {
                $frame1 = $main->Frame(-width => 850, -height => 600);
                $frame1->pack(-side=>'left');
                my $frame2 = $frame1->Frame;            # Posting Question 
                $frame2->pack;
                $frame2->Label(-text=>tr1('Quelle difficulté?'),
                        -font => "Nimbus 15")->pack(-side=>'left');
                $listdifficulte = $frame2->Listbox(-width => 10, -height => 3)->pack(-side=>'right');
                $listdifficulte->insert('end',tr1('Facile'),tr1('Difficile'),tr1('Très difficile'));
                $listdifficulte->activate(0);
                $listdifficulte->bind('<Double-1>',\&OK2);
                $main->bind('<Key-Return>', => [\&OK2]);
                my $frame3 = $frame1->Frame;
                        $frame3->pack;
                $frame3 = $frame1->Button (
                                -command=>[\&OK2],
                                -text=>tr1('OK')
                        )->pack();
        } else {
                menu('affichgrilleS');
                $frame1 = $main->Frame(-width => 850, -height => 600);
                $frame1->pack(-side=>'left');
                init_tableau();
                affichage_grille($fonction);
        }
        
}
1;

sub creation_grille {                   # Posting grid to build a problem
        if ($wcanvas == 1) {
                $frame1->destroy;
                $wcanvas = 0;
        } else {
                $frame1 -> destroy;
        }
        if ($Enfant == 1) {
                $nbcase = 4;
        } elsif ($Simpliste == 1) {
                $nbcase = 6;
        } elsif ($Ardu == 1) {
                $nbcase = 8;
        } elsif ($Difficile == 1) {
                $nbcase = 10;
        } elsif ($Tresdifficile == 1) {
                $nbcase = 12;
        } elsif ($MaxiSudoku == 1) {
                $nbcase = 16;
        } else {
                $nbcase = 9;
        }
        menu('affichgrille');
        $fonction = "R";
        menu('affichgrilleS');
        $frame1 = $main->Frame;
        $frame1->pack(-side=>'left');
        @precarre = ' ';
        @frame = ' ';
        @frame1 = ' ';
        @carre = 0;
        init_tableau();
        $timedebut = time;
        affichage_grille($fonction);        
}

sub OK1 {                       # seizure answer to question new grid yes/no
        use Games::Sudoku::sudokuprincipal;
        use Games::Sudoku::tr1;
        @precarre = ' ';
        @frame = ' ';
        @frame1 = ' ';
        @carre = 0;
        $option = $listoption->get('active');
        $option =~ s/^\s+//;      # delete spaces beginning and end
        my $reponse = tr1('NON');
        my $reponse1 = tr1('non');
        if ($option =~ m/$reponse/ or $option =~ m/$reponse1/) {
                #print "importation\n";
                importation("","txt");
        } else {
                #print "init\n";
                init_tableau();       
        }
        #print "OK1 " . $option . "\n";
        $trait = "T";
        $fin = 0;
        affichage_grille('T');
}

sub OK2 {                       # seizure answer to question difficult
        use Games::Sudoku::sudokuprincipal;
        use Games::Sudoku::tr1;
        $option = $listdifficulte->get('active');
        $option =~ s/^\s+//;      # delete spaces beginning and end
        my $reponse = tr1('Facile');
        my $reponse1 = tr1('Difficile');

        my $reponse2 = tr1('Très difficile');
        if ($option eq $reponse1) {
                $difficulte = 1;
        } elsif ($option eq $reponse2) {
                $difficulte = 2;
        } else {
                $difficulte = 0;
        }
        newgrille();
}

sub affichage_grille {          # posting grid
        use Games::Sudoku::saisie1;
        use Games::Sudoku::sudokuprincipal;
        ($trait) = @_;
        #print "affichage grille trait= " . $trait . "\n";
        $frame1->destroy;
        $frame1 = $main->Frame(-width => 950, -height => 600);
        $frame1->pack;
        $frame2 = $frame1->Frame;
        $frame2->pack;
        $frame7 = $frame2->Frame->pack(-side=>'right');         # posting right side
        $timefin = time;
        my ($hh, $mn, $s) = caltime($timefin, $timedebut);
        my $frame20 = $frame7->Label(-text => tr1('Temps : ') . $hh . tr1('h') . $mn . tr1('mn') . $s . tr1('s') . "\n\n\n",
                -font => "Nimbus 10"
                )->pack();
        if ($trait ne "F" or $fin != 1) {
                if ($fonction ne "S") {
                        if ($trait ne "T" and $trait ne "V") {
                                if ($fin == 0) {
                                        $frame10 = $frame7->Label(-text => tr1('Tout n\'est pas réglé'),
                                                -font => "Nimbus 15"
                                                )->pack();
                                        $frame8 = $frame7->Label(-text => 
                                                tr1('Supprimer le chiffre choisi'),
                                                -font => "Nimbus 15"
                                                )->pack();
                                                $frame9 = $frame7->Button (
                                                        -command=>\&saisie1,
                                                        -text=>tr1('OK')
                                                        )->pack();
                                } else {
                                        $frame8 = $frame7->Label(-text => 
                                                tr1('Supprimer le chiffre choisi'),
                                                -font => "Nimbus 15"
                                                )->pack();
                                }
                        } else {        # T seizure ou V end seizure
                                if ($erreur_saisie == 1 and $trait eq "T") {
                                        $frame11 = $frame7->Label(-text => tr1('Erreur de saisie'),
                                                -font => "Nimbus 15"
                                                )->pack();
                                }
                                if ($erreur_saisie == 1 and $trait eq "V") {
                                        $frame11 = $frame7->Label(-text => tr1('Erreur'),
                                                -font => "Nimbus 15"
                                                )->pack();
                                }
                                if ($fin == 0) {    # all is not found
                                        if ($trait eq "V") {
                                                $frame11 = $frame7->Frame;
                                                $checkaide= $frame7->Checkbutton(-text 
                                                        => tr1('Aide?'), 
                                                        -font => "Nimbus 15",
                                                        -variable => \$aide,
                                                        -command => \&importations
                                                        )->pack();
                                                if ($aide == 1) {
                                                        $checkaide->select;
                                                } else {
                                                        $checkaide->deselect;
                                                }
                                                if ($erreur_aide == 1) {
                                                        #print ("bonnevaleur = " . $bonnevaleur . "\n");
                                                        $affichbonnevaleur = convertcase($bonnevaleur);
                                                        if ($dessin eq "animaux") {
                                                                $frame12 = $frame7->Frame;
                                                                $frame121 = $frame12->Label(-text
                                                                => tr1('Faux la bonne valeur est '), 
                                                                -font => "Nimbus 15"
                                                                )->pack(-side => 'left');
                                                                my $nomdessinanimaux = 
                                                                        $dessinanimaux{$affichbonnevaleur};
                                                                my $fichier = 
                                                                        $pref . '/photos/' . $nomdessinanimaux;
                                                                my $image = "image" . ($affichbonnevaleur);
                                                                my $im = $frame12
                                                                        ->Photo($image, -file => $fichier);
                                                                my $button = $frame12
                                                                        ->Button(-height => 45, -width => 45,
                                                                        -image => $im);
                                                                $button->pack(-side => 'left');
                                                        } elsif ($dessin eq "couleurs") {
                                                                $frame12 = $frame7->Frame;
                                                                $frame121 = $frame12->Label(-text
                                                                => tr1('Faux la bonne valeur est '), 
                                                                -font => "Nimbus 15"
                                                                )->pack(-side => 'left');
                                                                my $nomdessincouleurs = 
                                                                        $dessincouleurs{$affichbonnevaleur};
                                                                my $button = $frame12
                                                                        ->Button(-height => 3, -width => 5,
                                                                        -background => $nomdessincouleurs);
                                                                $button->pack(-side => 'left');
                                                        } elsif ($dessin eq "lettres") {
                                                                $affichbonnevaleur = convertlettre($bonnevaleur);
                                                                $frame12 = $frame7->Label(-text
                                                                => tr1('Faux la bonne valeur est ') 
                                                                . $affichbonnevaleur,
                                                                -font => "Nimbus 15"
                                                                )->pack();
                                                        } else {
                                                                $frame12 = $frame7->Label(-text
                                                                => tr1('Faux la bonne valeur est ') 
                                                                . $affichbonnevaleur,
                                                                -font => "Nimbus 15"
                                                                )->pack();
                                                        }
                                                        $frame12->pack;
                                                }
                                                $frame10 = $frame7->Label(-text 
                                                        => tr1('Tout n\'est pas trouvé'),
                                                        -font => "Nimbus 15"
                                                        )->pack();
                                        }
                                        if ($dessin eq "animaux") {
                                                $frame8 = $frame7->Label(-text => tr1('Choisir dessin'),
                                                        -font => "Nimbus 15"
                                                        )->pack();
                                        } elsif ($dessin eq "lettres") {
                                                $frame8 = $frame7->Label(-text => tr1('Saisir lettres'),
                                                        -font => "Nimbus 15"
                                                        )->pack();
                                        } elsif ($dessin eq "couleurs") {
                                                $frame8 = $frame7->Label(-text => tr1('Choisir couleurs'),
                                                        -font => "Nimbus 15"
                                                        )->pack();
                                        } else {
                                                $frame8 = $frame7->Label(-text => tr1('Saisir chiffres'),
                                                        -font => "Nimbus 15"
                                                        )->pack();
                                        }
                                        $frame9 = $frame7->Button (
                                                -command=>\&fin_saisie,
                                                -text=> tr1('FIN SAISIE')
                                                )->pack();
                                } else {        # all is found
                                        $frame10 = $frame7->Label(-text => tr1('Bravo'),
                                                -font => "Nimbus 15"
                                                )->pack();
                                        
                                }
                        }
                } else {
                }
        } else {
                $frame10 = $frame7->Label(-text => tr1('Tout est réglé'),
                        -font => "Nimbus 15"
                        )->pack();
        }
        # Preparation grid
        $i = 0;
        $j = 0;
        ($wimax, $wjmax, $wimax1, $wjmax1) = calminmaxred($nbcase);
        if ($nbcase == 4) {
                $tailleborder = 2;
        } else {
                $tailleborder = 4;
        }
        for ($wi = 0; $wi < $wimax; $wi++) {         # posting areas
                $frame3[$wi] = $frame2->Frame(-borderwidth=>4)->pack;
                for ($wj = 0; $wj < $wjmax; $wj++) {
                        $frame4[$wi][$wj] = $frame3[$wi]->Frame(-borderwidth=>$tailleborder)
                                ->pack(-side=>'left');
                        for ($wwi = 0; $wwi < $wimax1; $wwi++) {
                                $frame5[$wi][$wj][$wwi] = $frame4[$wi][$wj]->Frame->pack;
                                for ($wwj = 0; $wwj < $wjmax1; $wwj++) {
                                        $frame6[$wi][$wj][$wwi][$wwj] = $frame5[$wi][$wj][$wwi]
                                                ->Frame(-borderwidth=>($tailleborder/2))
                                                ->pack(-side=>'left');
                                                $i = ($wimax1 * $wi) + $wwi;
                                                $j = ($wjmax1 * $wj) + $wwj;
                                                affich_case($i,$j);
                                }
                        }
                }
        }
        #print "fin affich trait= " . $trait . "\n";
        if ($trait eq "V") {

                $traitexport = " ";
                exportation();
        }
        $main->bind('<Key-Return>', => [\&saisie2]);
                #}
}

sub affich_case {           # posting a square
        my ($i,$j) = @_;
        #print ("affich_case " . $i . " " . $j . "\n");
        if ($nbcase == 9 or $nbcase == 4 or $nbcase == 6 or $nbcase == 8 
                or $nbcase == 10) { 
                        $width = 2;
                        $taillefont = "30";
                } else { 
                        $width = 30;
                        $taillefont = "15";
                }
        my $trouve = 0;
        for (my $k = 0; $k < $nbcase; $k++) {
                if ($precarre[$i][$j][$k] eq "S" or $precarre[$i][$j][$k] eq "C") {
                        $wk = $k + 1; 
                        $wkaffich = convertcase($wk);
                        $trouve++;
                }
        }
        if ($trouve != 0) {             # posting big square because number is found
                
                #print ("i= " . $i . " j= " . $j . " " . $precarre[$i][$j][$wk - 1] . "\n");
                if ($precarre[$i][$j][$wk - 1] eq "S") {
                        $backgroundcouleur = "red";
                } else {
                        $backgroundcouleur = "blue";
                }
                affich();
        } elsif ($trait eq "T" or $trait eq "V") { #posting big white square
                if ($dessin eq "animaux") {
                        fixwidthheight();
                        $entrycarre[$i][$j][0] = $frame6[$wi][$wj][$wwi][$wwj]
                        ->Button(-text => ' ', -height => $height, -width => $width,
                        -activebackground => "yellow",
                        -command => [\&affichdessin,$i,$j,$wi,$wj,$wwi,$wwj])
                        ->pack(-side=>'left');
                }elsif ($dessin eq "couleurs") {
                        fixwidthheight();
                        $entrycarre[$i][$j][0] = $frame6[$wi][$wj][$wwi][$wwj]
                        ->Button(-text => ' ', -height => $height, -width => $width,
                        -activebackground => "yellow",
                        -command => [\&affichcouleurs,$i,$j,$wi,$wj,$wwi,$wwj])
                        ->pack(-side=>'left');
                } else {
                        $entrycarre[$i][$j][0] = $frame6[$wi][$wj][$wwi][$wwj]
                                ->Entry(-width=>2,-font => "Nimbus " . $taillefont,-background => "white")
                                ->pack;
                        $entrycarre[$i][$j][0]->insert(0," ");
                }
        } else {                        # posting small square because number not found
                for ($k = 0; $k < $nbcase; $k++) {
                        $wk = $k + 1;
                        $wkaffich = convertcase($wk);
                        if ($nbcase == 4) {                             # Enfant
                                $width = 2;
                                $taillefont = 4;
                                if ($k == 0 or $k == 2) {
                                        if ($k == 0) {
                                                $wwk = 0;
                                        } else {
                                                $wwk = 1;
                                        }
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk] = $frame6[$wi][$wj][$wwi][$wwj]
                                        ->Frame(-borderwidth=>1);
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk]->pack;
                                }
                        } elsif ($nbcase == 6) {                        # Simpliste
                                $width = 2;
                                $taillefont = 4;
                                if ($k == 0 or $k == 3) {
                                        if ($k == 0) {
                                                $wwk = 0;
                                        } else { 
                                                $wwk = 1;
                                        }
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk] = $frame6[$wi][$wj][$wwi][$wwj]
                                        ->Frame(-borderwidth=>1);
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk]->pack;
                                }
                        } elsif ($nbcase == 8) {                        # Ardu
                                $width = 2;
                                $taillefont = 4;
                                if ($k == 0 or $k == 4) {
                                        if ($k == 0) {
                                                $wwk = 0;
                                        } else { 
                                                $wwk = 1;
                                        }
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk] = $frame6[$wi][$wj][$wwi][$wwj]
                                        ->Frame(-borderwidth=>1);
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk]->pack;
                                }
                        } elsif ($nbcase == 9) {                        # Normal
                                $width = 2;
                                $taillefont = 4;
                                if ($k == 0 or $k == 3 or $k == 6) {
                                        if ($k == 0) {
                                                $wwk = 0;
                                        } elsif ($k == 3) {
                                                $wwk = 1;
                                        } else {
                                                $wwk = 2;
                                        }
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk] = $frame6[$wi][$wj][$wwi][$wwj]
                                        ->Frame(-borderwidth=>1);
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk]->pack;
                                }
                        } elsif ($nbcase == 10) {                        # Difficile
                                $width = 2;
                                $taillefont = 4;
                                if ($k == 0 or $k == 5) {
                                        if ($k == 0) {
                                                $wwk = 0;
                                        } else { 
                                                $wwk = 1;
                                        }
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk] = $frame6[$wi][$wj][$wwi][$wwj]
                                        ->Frame(-borderwidth=>1);
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk]->pack;
                                }
                        } elsif ($nbcase == 12) {                        # Tresifficile
                                $width = 1;
                                $taillefont = 1;
                                if ($k == 0 or $k == 4 or $k == 8) {
                                        if ($k == 0) {
                                                $wwk = 0;
                                        } elsif ($k == 4) {
                                                $wwk = 1;
                                        } else {
                                                $wwk = 2;
                                        }
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk] = $frame6[$wi][$wj][$wwi][$wwj]
                                        ->Frame(-borderwidth=>1);
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk]->pack;
                                }
                        } else {                                        #nbcase = 16 Maxi
                                $width = 1;
                                $taillefont = 1;
                                if ($k == 0 or $k == 4 or $k == 8 or $k == 12) {
                                        if ($k == 0) {
                                                $wwk = 0;
                                        } elsif ($k == 4) {
                                                $wwk = 1;
                                        } elsif ($k == 8) {
                                                $wwk = 2;
                                        } else {
                                                $wwk = 3;
                                        }
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk] = $frame6[$wi][$wj][$wwi][$wwj]
                                        ->Frame(-borderwidth=>1);
                                $frame7[$wi][$wj][$wwi][$wwj][$wwk]->pack;
                                }
                        }
                        affich1();                # posting little square
                }
        }
}

sub affich {
        use Games::Sudoku::conf; 
        conf();
        if ($dessin eq "animaux") {
                if ($nbcase == 10 or $nbcase == 12 or $nbcase == 16) {
                        $width1 = 30;
                        $height1 = 30;
                } else {
                        $width1 = 45;
                        $height1 = 45;
                }
                $entrycarre[$i][$j][$k] = $frame6[$wi][$wj][$wwi][$wwj]
                        ->Canvas('width' => $width1,-highlightbackground => 'black',
                                -height => $height1);
                my $nomdessinanimaux = $dessinanimaux{$wkaffich};
                my $fichier;
                if ($nbcase == 10 or $nbcase == 12 or $nbcase == 16) {
                        $fichier = $pref . '/photos/p' . $nomdessinanimaux;
                } else {
                        $fichier = $pref . '/photos/' . $nomdessinanimaux;
                }
                my $image = "image" . $wkaffich;
                $frame6[$wi][$wj][$wwi][$wwj]
                        ->Photo($image, -file => $fichier);
                $entrycarre[$i][$j][$k]->createImage(0, 0, -anchor => 'nw',
                        -image => $image);
                $entrycarre[$i][$j][$k]->pack;
        } elsif ($dessin eq "couleurs") {
                if ($nbcase == 10 or $nbcase == 12 or $nbcase == 16) {
                        $height2 = 1;
                } else { 
                        $height2 = 2;
                }
                my $couleur = $dessincouleurs{$wkaffich};
                $entrycarre[$i][$j][$k] = $frame6[$wi][$wj][$wwi][$wwj]
                        ->Entry(-width=> 2, 
                        -font => "Nimbus " . $taillefont,
                        -background=>$couleur)->pack;
        } else {
                if ($nbcase == 10 or $nbcase == 12 or $nbcase == 16) {
                        $height2 = 1;
                } else { 
                        $height2 = 2;
                }
                $entrycarre[$i][$j][$k] = $frame6[$wi][$wj][$wwi][$wwj]
                        ->Entry(-width=> 2,  
                        -font => "Nimbus " . $taillefont,
                        -background=>$backgroundcouleur)->pack;
                if ($dessin eq "lettres") {
                        my $lettre = convertlettre($wkaffich);
                        $entrycarre[$i][$j][$k]->insert(0," " . $lettre);
                } else {
                        $entrycarre[$i][$j][$k]->insert(0," " . $wkaffich);
                }
        }             
}

sub affich1 {                 # posting square or image
        $entrycarre[$i][$j][$k] = $frame7[$wi][$wj][$wwi][$wwj][$wwk]
                ->Entry(-width=>$width,-selectforeground => 'red',
                -font => "Nimbus " . $taillefont)
                ->pack(-side=>'left');
        if ($precarre[$i][$j][$k] eq "P") {
                        $entrycarre[$i][$j][$k]->insert(0,$wkaffich);
        } else {
                        $entrycarre[$i][$j][$k]->insert(0,"  ");
        }
}

sub affichdessin {
        my ($idessin, $jdessin, $wi, $wj, $wwi, $wwj, $code) = @_;
        use Games::Sudoku::conf; 
        conf();
        #print "affichdessin $idessin $jdessin\n";
        fixwidthheight();
        $entrycarre[$idessin][$jdessin][0]->destroy;
        $entrycarre[$idessin][$jdessin][0] = $frame6[$wi][$wj][$wwi][$wwj]
                        ->Button(-text => ' ', -height => $height, -width => $width,
                        -background => "yellow")
                        ->pack(-side=>'left');
        $frame3 = $frame7->Frame->pack;
        my $textframe3 = $frame3->Label(-text => tr1('Choisissez'), 
                -font => "Nimbus 20")->pack;
        $frame4 = $frame7->Frame->pack;
        $frame5 = $frame7->Frame->pack;
        for (my $i = 0; $i < $nbcase; $i++) {             # posting drawings for choice
                my $chiffre = convertcase($i + 1);
                my $nomdessinanimaux = $dessinanimaux{$chiffre};
                my $fichier;
                my $height;
                my $width;
                if ($nbcase == 10 or $nbcase == 12 or $nbcase == 16) {
                        $fichier = $pref . '/photos/p' . $nomdessinanimaux;
                        $width = 35;
                        $height = 35;
                } else {
                        $fichier = $pref . '/photos/' . $nomdessinanimaux;
                        $width = 45;
                        $height = 45;
                }
                my $image = "image" . ($i + 1);
                my $button;
                if ($i <= 8) {
                        my $im = $frame4->Photo($image, -file => $fichier);
                        $button = $frame4->Button(-height => $height, -width => $width,
                                -image => $im,
                                -command => [\&saisiedessin,$idessin,$jdessin,$i + 1]);
                } else {
                        $im = $frame5->Photo($image, -file => $fichier);
                        $button = $frame5->Button(-height => $height, -width => $width,
                                -image => $im,
                                -command => [\&saisiedessin,$idessin,$jdessin,$i + 1]);
                }
                $button->pack(-side => 'left');
        } 
        fixwidthheight();
        my $button = $frame5->Button(-height => $height, -width => $width + 4,
                        -text => tr1("annulation"),
                        -command => [\&annuldessin, $idessin, $jdessin, $wi, $wj, $wwi, $wwj]);
                $button->pack(-side => 'left');
}

sub annuldessin {
# step backwards on choice square in the case of drawings
        my ($idessin, $jdessin, $wi, $wj, $wwi, $wwj, $code) = @_;
        fixwidthheight();
        $entrycarre[$idessin][$jdessin][0]->destroy;
        if ($dessin eq "animaux") {
                $entrycarre[$idessin][$jdessin][0] = $frame6[$wi][$wj][$wwi][$wwj]
                        ->Button(-text => ' ', -height => $height, -width => $width,
                        -background => "white",
                        -command => [\&affichdessin,$idessin,$jdessin,$wi,$wj,$wwi,$wwj])
                        ->pack(-side=>'left');
        } elsif ($dessin eq "couleurs") {
                $entrycarre[$idessin][$jdessin][0] = $frame6[$wi][$wj][$wwi][$wwj]
                        ->Button(-text => ' ', -height => $height, -width => $width,
                        -background => "white",
                        -command => [\&affichcouleurs,$idessin,$jdessin,$wi,$wj,$wwi,$wwj])
                        ->pack(-side=>'left');
        }
        $frame4->destroy;
        $frame5->destroy;
        $frame3->destroy;        
}

sub affichcouleurs {
        my ($idessin, $jdessin, $wi, $wj, $wwi, $wwj, $code) = @_;
        use Games::Sudoku::conf; 
        conf();
        #print "affichcouleur $idessin $jdessin\n";
        fixwidthheight();
        $entrycarre[$idessin][$jdessin][0]->destroy;
        $entrycarre[$idessin][$jdessin][0] = $frame6[$wi][$wj][$wwi][$wwj]
                        ->Button(-text => ' ', -height => $height, -width => $width,
                        -background => "yellow")
                        ->pack(-side=>'left');
        $frame3 = $frame7->Frame->pack;
        my $textframe3 = $frame3->Label(-text => tr1('Choisissez'), 
                -font => "Nimbus 20")->pack;
        $frame4 = $frame7->Frame->pack;
        $frame5 = $frame7->Frame->pack;
        for (my $i = 0; $i < $nbcase; $i++) {             # posting drawings for choice
                my $chiffre = convertcase($i + 1);
                my $couleur = $dessincouleurs{$chiffre};
                my $button;
                if ($i <= 8) {
                        $button = $frame4->Button(-height => $height, -width => $width,
                                -background => $couleur,
                                -command => [\&saisiedessin,$idessin,$jdessin,$i + 1]);
                } else {
                        $button = $frame5->Button(-height => $height, -width => $width,
                                -background => $couleur,
                                -command => [\&saisiedessin,$idessin,$jdessin,$i + 1]);
                }
                $button->pack(-side => 'left');
        } 
        fixwidthheight();
        my $button = $frame5->Button(-height => $height, -width => $width + 4,
                        -text => tr1("annulation"),
                        -command => [\&annuldessin, $idessin, $jdessin, $wi, $wj, $wwi, $wwj]);
                $button->pack(-side => 'left');        
}

sub CType {                         # we choose the type of traitment
        my ($trait, $code) = @_;
        use Games::Sudoku::conf; 
        conf();
        if ($skin == 1) {                       # "beautiful" skin
                if ($trait eq 'Normal') {
                        $Normal = 1;
                        $rbutton1->destroy;
                        my $Label20 = $frame5->Label(-image => "imagenormal")->pack(-side => 'left');
                } else {
                        $Normal = 0;
                        $rbutton1->destroy;
                }
                if ($trait eq 'Simpliste') {
                        $Simpliste = 1;
                        $rbutton2->destroy;
                        my $Label21 = $frame7->Label(-image => "imagesimpliste")->pack(-side => 'left');
                } else {
                        $Simpliste = 0;
                        $rbutton2->destroy;
                }
                if ($trait eq 'Ardu') {
                        $Ardu = 1;
                        $rbutton3->destroy;
                        my $Label22 = $frame8->Label(-image => "imageardu")->pack(-side => 'left');
                } else {
                        $Ardu = 0;
                        $rbutton3->destroy;
                }
                if ($trait eq 'MaxiSudoku') {
                        $MaxiSudoku = 1;
                        $rbutton4->destroy;
                        my $Label23 = $frame9->Label(-image => "imagemaxisudoku")->pack(-side => 'left');
                } else {
                        $MaxiSudoku = 0;
                        $rbutton4->destroy;
                }
                if ($trait eq 'Enfant') {
                        $Enfant = 1;
                        $rbutton5->destroy;
                        my $Label24 = $frame12->Label(-image => "imageenfant")->pack(-side => 'right');
                        $dessin = "animaux";            # option by default
                } else {
                        $Enfant = 0;
                        $rbutton5->destroy;
                }
                if ($trait eq 'Difficile') {
                        $Difficile = 1;
                        $rbutton6->destroy;
                        my $Label25 = $frame9->Label(-image => "imagedifficile")
                        ->pack(-side => 'left');
                } else {
                        $Difficile = 0;
                        $rbutton6->destroy;
                }
                if ($trait eq 'Tresdifficile') {
                        $Tresdifficile = 1;
                        $rbutton7->destroy;
                        my $Label26 = $frame9->Label(-image => "imagetresdifficile")
                        ->pack(-side => 'left');
                } else {
                        $Tresdifficile = 0;
                        $rbutton7->destroy;
                }
        } else {                                               # Normal skin
                if ($Normal == 0) {
                       $rbutton1->destroy;
                       $Normal = 2;
                }
                if ($Simpliste == 0) {
                       $rbutton2->destroy;
                       $Simpliste = 2;
                }
                if ($Ardu == 0) {
                       $rbutton3->destroy;
                       $Ardu = 2;
                }
                if ($MaxiSudoku == 0) {
                       $rbutton4->destroy;
                       $MaxiSudoku = 2;
                }
                if ($Enfant == 0) {
                       $rbutton5->destroy;
                       $Enfant = 2;
                }
                if ($Enfant == 1) {
                       $dessin = "animaux";            # option by default
                }
                if ($Difficile == 0) {
                       $rbutton6->destroy;
                       $Difficile = 2;
                }
                if ($tresdifficile == 0) {
                       $rbutton7->destroy;
                       $Tresdifficile = 2;
                }
        }
}


sub saisiedessin {
        # we chose a drawings which is transformed into number
        use Games::Sudoku::saisie1;
        ($idessin, $jdessin, $valdessinin, $code) = @_;
        #print "saisiedessin $idessin $jdessin $valdessinin\n";
        $valdessin = convertcase($valdessinin);
        #print ("$valdessin\n");
        saisie1();      # Forcage at the end of seizure for backup
}

sub convertcase {               # Conversion number 
        my ($chiffre, $code) = @_;
        #print "convertcase $chiffre $chiffreconvert\n";
        my %val = (1,'1',2,'2',3,'3',4,'4',5,'5',6,'6',7,'7',8,'8',9,'9',
                10,'A',11,'B',12,'C',13,'D',14,'E',15,'F',16,'G');
        my $chiffreconvert = $val{$chiffre};
        return $chiffreconvert;
}

sub fixwidthheight {            # determination of $height and $width
        if ($system eq "linux") {
                                if ($nbcase == 10 or $nbcase == 12 or $nbcase == 16) {
                                        $height = 1;
                                        $width = 1;
                                } else {
                                        $height = 2;
                                        $width = 2;
                                }
                        } else {                        # windows
                                if ($nbcase == 10 or $nbcase == 12 or $nbcase == 16) {
                                        $height = 2;
                                        $width = 3;
                                } else {
                                        $height = 3;
                                        $width = 7;
                                }
                        }
}

sub caltime {           # compute time
        my ($timefin, $timedebut, $code) = @_;
        #print ("timefin " . $timefin . " timedebut " . $timedebut . "\n");
        my $dif = $timefin - $timedebut;        
        my $hh = int($dif / 3600);
        my $dif1 = $dif - ($hh * 3600);
        my $mn = int($dif1 / 60);
        my $s = $dif1 - ($mn * 60);
        return ($hh, $mn, $s);
}

sub convertlettre {     # Conversion number in letter
        my ($chiffre, $code) = @_;
        my %let = ('1','A','2','B','3','C','4','D','5','E','6','F','7','G','8','H','9','I',
                '10','J','11','K','12','L','13','M','14','N','15','O','16','P');
        my $lettre = $let{$chiffre};
        #print ("convertlettre " . $chiffre . " " . $lettre . "\n");
        return $lettre;
}