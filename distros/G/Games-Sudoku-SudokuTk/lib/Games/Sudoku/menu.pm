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
# menu.pm  menu management 
sub menu {
        use Games::Sudoku::affichgrille;
        use Games::Sudoku::newgrille;
        my ($origine) = @_;
        #print "menu " . $origine . "\n";
        # definition of menu
        if ($origine ne "sudoku") {
                $menubar -> destroy;
        }
        $menubar = $main->Frame;
        $menubar->pack(
                -fill => 'x');
        # File menu
        my $fichiermenu = $menubar->Menubutton(-text => tr1('Fichier'));
        $fichiermenu->pack(
                '-side' => 'left');

        #save
        $fichiermenu->command(
                -label          => tr1('Sauver'),
                -command        => [\&sauve],
                -accelerator    => 'Ctrl+s'
        );
        $main->bind('<Control-s>' => [\&sauve]);
        
        # Exit         
        $fichiermenu->command(
                -label          => tr1('Quitter'),
                -command        => [$main => 'destroy'],
                -accelerator    => 'Ctrl+q'
        );
        $main->bind('<Control-q>' => [$main => 'destroy']);
        
        if ($origine eq "affichgrille" or $origine eq "affichgrilleS" or $origine eq "sudoku"
                or $origine eq "V") {
                # Options Menu
                my $optionmenu = $menubar->Menubutton(-text => tr1('Options'));
                $optionmenu->pack(
                        '-side' => 'left');
                # resolve of a seized grid
                $optionmenu->command(
                        -label          => tr1('Resoudre une grille saisie'),
                        -command        => [\&affichgrille,"R"],
                        -accelerator    => 'Ctrl+s',
                );
                $main->bind('<Control-s>' => [\&affichgrille,"R"]);

                # ask for a new grid
                $optionmenu->command(
                        -label          => tr1('Demander une nouvelle grille'),
                        -command        => [\&affichgrille,"C"],
                        -accelerator    => 'Ctrl+r',
                );
                $main->bind('<Control-n>' => [\&affichgrille,"R"]);
                
                # Creation of a new grid
                $optionmenu->command(
                        -label          => tr1('Creer une grille'),
                        -command        => [\&creation_grille],
                        -accelerator    => 'Ctrl+c',
                );
                my $text2 = tr1('Creer une grille') . ' C+c\n';
                $main->bind('<Control-c>' => [\&creation_grille]);
                
                if (($origine ne "affichgrilleS" 
                        and $origine ne "sudoku") or $trait eq "V") {
                        # Solution
                        $optionmenu->command(
                                -label          => tr1('Solution'),
                                -command        => [\&solutiond,"S"],
                                -accelerator    => 'Ctrl+s',
                        );
                        my $text3 = tr1('Solution') . 'C+s\n';
                        $main->bind('Control-s>' => [\&solutiond,"S"]);
                }
        }
        # Drawing
        my $dessinmenu = $menubar->Menubutton(-text => tr1('affichage'));
        $dessinmenu->pack(
                '-side' => 'left');
        # selection of drawing of cases
        $dessinmenu->radiobutton(-label => tr1('chiffres'),
                -command => [sub{$dessin = "chiffres"}]);        
        $dessinmenu->radiobutton(-label => tr1('animaux'),
                -command => [sub{$dessin = "animaux"}]); 
        $dessinmenu->radiobutton(-label => tr1('lettres'),
                -command => [sub{$dessin = "lettres"}]);        
        $dessinmenu->radiobutton(-label => tr1('couleurs'),
                -command => [sub{$dessin = "couleurs"}]);   
        # Language Menu
        my $languemenu = $menubar->Menubutton(-text => tr1('Langues'));
        $languemenu->pack(
                '-side' => 'left');
        # selection of languages
        $languemenu->radiobutton(-label => tr1('français'),
                -command => [\&changelang,"fr"]);        
        $languemenu->radiobutton(-label => tr1('anglais'),
                -command => [\&changelang,"en"]);   
        $languemenu->radiobutton(-label => tr1('allemand'),
                -command => [\&changelang,"ge"]);
        $languemenu->radiobutton(-label => tr1('espagnol'),
                -command => [\&changelang,"sp"]); 
        $languemenu->radiobutton(-label => tr1('italien'),
                -command => [\&changelang,"it"]);
        $languemenu->radiobutton(-label => tr1('portuguais'),
                -command => [\&changelang,"pt"]);
}
1;