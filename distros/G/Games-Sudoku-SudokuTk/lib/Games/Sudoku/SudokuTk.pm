package Games::Sudoku::SudokuTk;

use 5.008008;
#use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Games::Sudoku::SudokuTk ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.14';
sudoku();
# Preloaded methods go here.

1;

sub sudoku {
use Tk;
use Tk::Balloon;
use Games::Sudoku::menu;
use Games::Sudoku::affichgrille;
use Games::Sudoku::tr1;
use Games::Sudoku::conf;
conf();
foreach $a (@INC) {             # we verifie that drawings are here
        $retour = opendir('DIRECTORY',$a . '/Games/Sudoku/photos');
        $b = $a;
        if ($retour) {
          last;
        }
}
closedir('DIRECTORY');
#print ("fichier " . "$b" . "\n");
$system = $^O;                  # we find the system
#print "system $system\n";
$pref = "$b" . "/Games/Sudoku";
@precarre = "";
@wprecarre = "";
# Definition of main window 
$langue = "";
$dessin = "chiffres";
$MaxiSudoku = 0;             # 0 non choisi 1 choisi 2 autre choisi
$Normal = 0;                 # idem
$Enfant = 0;                 # idem
$Simpliste = 0;              # idem
$Ardu = 0;                   # idem
$trait = "sudoku";
$main = MainWindow->new();
menu($trait);
if ($skin == 1) {
# ---------------------------------------------------------
# frame1                            |frame3 frame31       |
# frame2                            |----------------------
# frame4                            |frame32   |34frame35 |
#                                   |frame33   | |frame37 |
#                                   |frame38   | |        |
#                                   |          | |        |
#                                   |          | |        |
#-----------------------------------|          | |        | 
# frame5                            |          | |        |
#-----------------------------------|          | |        |
# frame6 frame7  |frame8            |          | |        |
#-----------------------------------|----------------------
# frame9                            |frame36              |
#---------------------------------------------------------- 
        $frame1 = $main->Frame(-background => $couleurfond)->pack();
        $frame2 = $frame1->Frame(-background => $couleurfond)->pack(-side => 'left');
        $frame3 = $frame1->Frame(-background => $couleurfond)->pack(-side => 'right');
        $frame4 = $frame2->Frame(-background => $couleurfond)->pack();
        $canvas = $frame4->Canvas(-width => 500, -height => 300);
        $frame4->Photo("imagesudoku", -file => $pref . '/photos/sudoku.bmp');
        $canvas->createImage(250 ,0,-anchor => 'n', -image => "imagesudoku"); 
        $canvas->pack;

        $frame5 = $frame2->Frame(-background => $couleurfond)->pack();
        $frame5->Photo('imagenormal', -file => $pref . '/photos/button/' . $langue . '/normal.bmp');
        $rbutton1= $frame5->Button(-command => [\&CType,'Normal'],
                        -image => "imagenormal")->pack(-side => 'left');
        my $balloon1 = $rbutton1->Balloon();
        $balloon1->attach($rbutton1, -msg => tr1("Grille 9x9 normale"));
        $frame6 = $frame2->Frame(-background => $couleurfond)->pack();
        $frame7 = $frame6->Frame(-background => $couleurfond)->pack(-side => 'left');
        $frame7->Photo('imagesimpliste', -file => $pref . '/photos/button/' . $langue . '/simpliste.bmp');
        $rbutton2= $frame7->Button(-command => [\&CType,'Simpliste'],
                        -image => "imagesimpliste")->pack(-side => 'left');
        my $balloon2 = $rbutton2->Balloon();
        $balloon2->attach($rbutton2, -msg => tr1("Grille 6x6 facile"));
        $frame8 = $frame6->Frame(-background => $couleurfond)->pack(-side => 'left');
        $frame8->Photo('imageardu', -file => $pref . '/photos/button/' . $langue . '/ardu.bmp');
        $rbutton3= $frame8->Button(-command => [\&CType,'Ardu'],
                        -image => "imageardu")->pack(-side => 'left');
        my $balloon3 = $rbutton3->Balloon();
        $balloon3->attach($rbutton3, -msg => tr1("Grille 8x8 pas facile"));
        $frame9 = $frame2->Frame(-background => $couleurfond)->pack();
        $frame9->Photo('imagedifficile', -file => $pref . '/photos/button/' . $langue . '/difficile.bmp');
        $rbutton6= $frame9->Button(-command => [\&CType,'Difficile'],
                        -image => "imagedifficile")->pack(-side => 'left');
        my $balloon6 = $rbutton6->Balloon();
        $balloon6->attach($rbutton6, -msg => tr1("Grille 10x10 difficile"));
        $frame9->Photo('imagemaxisudoku', -file => $pref . '/photos/button/' . $langue . '/maxisudoku.bmp');
        $rbutton4= $frame9->Button(-command => [\&CType,'MaxiSudoku'],
                        -image => "imagemaxisudoku")->pack(-side => 'left');
        my $balloon4 = $rbutton4->Balloon();
        $balloon4->attach($rbutton4, -msg => tr1("Grille 16x16 très difficile"));
        $frame10 = $frame2->Frame(-background => $couleurfond)->pack();
        my $frame11 = $frame10->Frame(-background => $couleurfond)->pack(-side => 'left');
        my $button6 = $frame11->Label(-text => ' ', -background => $couleurfond, 
                -height => 2, -width => 50)->pack;
        $frame12 = $frame10->Frame->pack(-side => 'right');
        $frame12->Photo('imagetresdifficile', -file => $pref . '/photos/button/' . 
                $langue . '/tresdifficile.bmp');
        $rbutton7 = $frame12->Button(-command => [\&CType,'Tresdifficile'],
                        -image => "imagetresdifficile")->pack(-side => 'left');
        my $balloon7 = $rbutton7->Balloon();
        $balloon7->attach($rbutton7, -msg => tr1("Grille 12x12 très difficile"));
        $frame12->Photo('imageenfant', -file => $pref . '/photos/button/' . $langue . '/enfant.bmp');
        $rbutton5 = $frame12->Button(-command => [\&CType,'Enfant'],
                        -image => "imageenfant")->pack(-side => 'left');
        my $balloon5 = $rbutton5->Balloon();
        $balloon5->attach($rbutton5, -msg => tr1("Grille 4x4 très facile\navec dessins d'animaux\npar défaut"));
        my $frame31 = $frame3->Frame(-height => 3, -background => $couleurfond)->pack();
        my $frame32 = $frame3->Frame(-background => $couleurfond)->pack();
        my $frame33 = $frame32->Frame(-background => $couleurfond)->pack(-side => 'left');
        my $frame34 = $frame32->Frame(-background => $couleurfond)->pack(-side => 'left');
        my $frame35 = $frame32->Frame(-background => $couleurfond)->pack(-side => 'left');
        my $canvas3 = $frame34->Canvas('-width' => 5, '-height' => 500, -background => 'black')->pack();
        my $frame36 = $frame32->Frame(-height => 3, -background => $couleurfond)->pack();
        my $frame37 = $frame32->Frame(-background => $couleurfond)->pack(-side => 'left');
        my $frame38 = $frame32->Frame(-background => $couleurfond)->pack(-side => 'left');

# Left column  -------------------------------

        $frame33->Photo('imageresoudre', -file => $pref . '/photos/button/' . $langue . '/resoudre.bmp');
        $rbutton10 = $frame33->Button(-command => [\&affichgrille,"R"],
                        #-text => "Resoudre une grille")->pack();
                        -image => "imageresoudre")->pack();
        my $balloon10 = $rbutton10->Balloon();
        $balloon10->attach($rbutton10, -msg => tr1("Saisir une grille\npour la résoudre"));
        $frame33->Photo('imagecreer', -file => $pref . '/photos/button/' . $langue . '/creer.bmp');
        $rbutton12 = $frame33->Button(-command => [\&creation_grille],
                        #-text => "Creer une grille")->pack();
                        -image => "imagecreer")->pack(); 
        my $balloon12 = $rbutton12->Balloon();
        $balloon12->attach($rbutton12, -msg => tr1("Créer une grille soi même"));
        $frame33->Photo('imagechiffres', -file => $pref . '/photos/button/' . $langue . '/chiffres.bmp');
        if ($dessin ne "chiffres") {
                $rbutton13 = $frame33->Button(-command => [sub{$dessin = "chiffres"}],
                        #-text => "Résoudre avec\ndes chiffres")->pack();
                        -image => "imagechiffres")->pack();
        } else {
                $rbutton13 = $frame33->Label(-background => $couleurfond,
                        #-text => "Résoudre avec\ndes chiffres")->pack();
                        -image => "imagechiffres")->pack();
        }
        my $balloon13 = $rbutton13->Balloon();
        $balloon13->attach($rbutton13, -msg => tr1("Il y a des chiffres\n dans les cases"));
        $frame38->Photo('imagecouleurs', -file => $pref . '/photos/button/' . $langue . '/couleurs.bmp');
        if ($dessin ne "couleurs") {
                $rbutton21 = $frame33->Button(-command => [sub{$dessin = "couleurs"}],
                        #-text => "Résoudre avec\ndes lettres")->pack();
                        -image => "imagecouleurs")->pack();
        } else {
                $rbutton21 = $frame33->Label(
                        #-text => "Résoudre avec\ndes lettres")->pack();
                        -image => "imagecouleurs")->pack();
        }
        my $balloon21 = $rbutton21->Balloon();
        $balloon21->attach($rbutton21, -msg => tr1("Il y a des couleurs\n dans les cases"));
        my $Label5 = $frame33->Label(-text => tr1('Langues'),
                -font => "Nimbus 20",
                -background => $couleurfond,
                -height => 2, -width => 10)->pack;
        $frame33->Photo('imagefr', -file => $pref . '/photos/button/fr/drapeau.gif');
        if ($langue ne "fr") {
                $rbutton14 = $frame33->Button(-command => [\&changelang,"fr"],
                        #-text => "Français")->pack();
                        -background => $couleurfond,
                        -image => "imagefr")->pack(); 
        } else {
                $rbutton14 = $frame33->Label(-background => $couleurfond,
                        #-text => "Français")->pack();
                        -background => $couleurfond,
                        -image => "imagefr")->pack(); 
        }
        my $balloon14 = $rbutton14->Balloon();
        $balloon14->attach($rbutton14, -msg => tr1("français"));
        $frame33->Photo('imagege', -file => $pref . '/photos/button/ge/drapeau.gif'); 
        if ($langue ne "ge") {
                $rbutton15 = $frame33->Button(-command => [\&changelang,"ge"],
                        -background => $couleurfond,
                        -image => "imagege")->pack(); 
        } else {
                $rbutton15 = $frame33->Label(-background => $couleurfond,
                        -background => $couleurfond,
                        -image => "imagege")->pack(); 
        } 
        my $balloon15 = $rbutton15->Balloon();
        $balloon15->attach($rbutton15, -msg => tr1("allemand"));
        $frame33->Photo('imageit', -file => $pref . '/photos/button/it/drapeau.gif'); 
        if ($langue ne "it") {
                $rbutton16 = $frame33->Button(-command => [\&changelang,"it"],
                        -background => $couleurfond,
                        -image => "imageit")->pack(); 
        } else {
                $rbutton16 = $frame33->Label(-background => $couleurfond,
                        -background => $couleurfond,
                        -image => "imageit")->pack(); 
        }
        my $balloon16 = $rbutton16->Balloon();
        $balloon16->attach($rbutton16, -msg => tr1("italien"));                     

# Right column ------------------------------

        $frame35->Photo('imagenewgrille', -file => $pref . '/photos/button/' . $langue . '/newgrille.bmp');
        $rbutton17 = $frame35->Button(-command => [\&affichgrille,"C"],
                        #-text => "Demander\nune nouvelle grille")->pack();
                        -image => "imagenewgrille")->pack();
        my $balloon17 = $rbutton17->Balloon();
        $balloon17->attach($rbutton17, -msg => tr1("Demander une nouvelle grille"));
        $frame33->Photo('imageanimaux', -file => $pref . '/photos/button/' . $langue . '/animaux.bmp');
        my $button18 = $frame35->Label(-text => ' ', -background => $couleurfond,
                -height => 4, -width => 10)->pack;
        if ($dessin ne "animaux") {
                $rbutton19 = $frame35->Button(-command => [sub{$dessin = "animaux"}], 
                        #-text => "Résoudre avec\ndes animaux")->pack();
                        -image => "imageanimaux")->pack();
        } else {
                $rbutton19 = $frame35->Label(
                        #-text => "Résoudre avec\ndes animaux")->pack();
                        -image => "imageanimaux")->pack();
        }
        my $balloon19 = $rbutton19->Balloon();
        $balloon19->attach($rbutton19, -msg => tr1("Il y a des animaux\n dans les cases"));
        $frame37->Photo('imagelettres', -file => $pref . '/photos/button/' . $langue . '/lettres.bmp');
        if ($dessin ne "lettres") {
                $rbutton20 = $frame35->Button(-command => [sub{$dessin = "lettres"}],
                        #-text => "Résoudre avec\ndes lettres")->pack();
                        -image => "imagelettres")->pack();
        } else {
                $rbutton20 = $frame35->Label(
                        #-text => "Résoudre avec\ndes lettres")->pack();
                        -image => "imagelettres")->pack();
        }
        my $balloon20 = $rbutton20->Balloon();
        $balloon20->attach($rbutton20, -msg => tr1("Il y a des lettres\n dans les cases"));
        #my $Label6 = $frame35->Label(-text => ' ', -background => $couleurfond,
         #       -height => 4, -width => 10)->pack;
        my $Label6 = $frame35->Label(-text => ' ', -background => $couleurfond,
                -height => 4, -width => 10)->pack;
        $frame35->Photo('imageen', -file => $pref . '/photos/button/en/drapeau.gif');
        if ($langue ne "en") {
                $rbutton22 = $frame35->Button(-command => [\&changelang,"en"],
                        -background => $couleurfond,
                        #-text => "English")->pack();
                        -image => "imageen")->pack(); 
        } else {
                $rbutton22 = $frame35->Label(
                        #-text => "English")->pack();
                        -background => $couleurfond,
                        -image => "imageen")->pack(); 
        } 
        my $balloon22 = $rbutton22->Balloon();
        $balloon22->attach($rbutton22, -msg => tr1("anglais"));
        $frame35->Photo('imagesp', -file => $pref . '/photos/button/sp/drapeau.gif');
        if ($langue ne "sp") {
                $rbutton23 = $frame35->Button(-command => [\&changelang,"sp"],
                        -background => $couleurfond,
                        -image => "imagesp")->pack(); 
        } else {
                $rbutton23 = $frame35->Label(
                        -background => $couleurfond,
                        -image => "imagesp")->pack(); 
        }
        my $balloon23 = $rbutton23->Balloon();
        $balloon23->attach($rbutton23, -msg => tr1("espagnol")); 
        $frame35->Photo('imagept', -file => $pref . '/photos/button/pt/drapeau.gif');
        if ($langue ne "pt") {
                $rbutton24 = $frame35->Button(-command => [\&changelang,"pt"],
                        -background => $couleurfond,
                        -image => "imagept")->pack(); 
        } else {
                $rbutton24 = $frame35->Label(
                        -background => $couleurfond,
                        -image => "imagept")->pack(); 
        }
        my $balloon24 = $rbutton24->Balloon();
        $balloon24->attach($rbutton24, -msg => tr1("portugais"));
} else {                                # normal look              
        $canvas = $main->Label(-text => 'Sudoku',
               -height => 4, -width => 10,
               -font => "Nimbus 80")->pack;
        $framed1 = $main->Frame->pack();
        $framed2 = $main->Frame->pack();
        $canvas1 = $framed1->Canvas('-width' => 100,
               -height => 80);
        $framed1->Photo('image1', -file => $pref . '/photos/20.gif');
        $canvas1->createImage(0, 0, -anchor => 'nw',
               -image => image1);
        $canvas1->pack;
        $rbutton1= $framed1->Radiobutton(-text 
                               => tr1('Normal'), 
                              -font => "Nimbus 20",
                              -value => 1,         # valeur transmise de la variable
                              -command => [\&CType],
                              -variable => \$Normal
                              )->pack(-side => 'left');
        $rbutton2= $framed1->Radiobutton(-text 
                               => tr1('Simpliste'), 
                              -font => "Nimbus 20",
                              -value => 1,       
                              -command => [\&CType],
                              -variable => \$Simpliste
                              )->pack(-side => 'left');
        $rbutton3= $framed1->Radiobutton(-text 
                               => tr1('Ardu'), 
                               -font => "Nimbus 20",
                               -value => 1,       
                               -command => [\&CType],
                               -variable => \$Ardu
                               )->pack(-side => 'left');
        $rbutton4= $framed2->Radiobutton(-text 
                               => tr1('MaxiSudoku'), 
                               -font => "Nimbus 20",
                               -value => 1,
                               -command => [\&CType],
                               -variable => \$MaxiSudoku
                               )->pack(-side => 'left');
        $rbutton5= $framed2->Radiobutton(-text 
                               => tr1('Enfant'), 
                               -font => "Nimbus 20",
                               -value => 1,
                               -command => [\&CType],
                               -variable => \$Enfant
                               )->pack(-side => 'left');
       $rbutton6= $framed2->Radiobutton(-text 
                               => tr1('Difficile'), 
                               -font => "Nimbus 20",
                               -value => 1,
                               -command => [\&CType],
                               -variable => \$Difficile
                               )->pack(-side => 'left');
       $rbutton7= $framed2->Radiobutton(-text 
                               => tr1('Très difficile'), 
                               -font => "Nimbus 20",
                               -value => 1,
                               -command => [\&CType],
                               -variable => \$Tresdifficile
                               )->pack(-side => 'left');
}
$wcanvas = 1;
MainLoop;
}
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Games::Sudoku::SudokuTk - Sudoku Game 

=head1 SYNOPSIS

  use Games::Sudoku::SudokuTk;

=head1 DESCRIPTION

Game Sudoku allows to solve grids Sudoku in some seconds, to generate new grids, to work out grids.
3 dimensions are possible - For the children 4x4 - Normal Sudoku 9x9 - MaxiSudoku 16x16
Symbols to be found are figures but can be drawings of animals (by default for format child)
Sudoku exists in several languages: French, English, German, Spanish, Portuguese. 
Resolutions are approachable and a help is given to find resolution if you want it


=head2 EXPORT

None by default.



=head1 SEE ALSO

Dependance: Tk, IO::File

=head1 AUTHOR

Christian Guine, E<lt>c.guine@free.frE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Christian Guine

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.


=cut