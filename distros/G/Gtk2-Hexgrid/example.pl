#!/usr/bin/perl

use Gtk2 "-init";
use warnings;
use strict;

use lib "./lib/";
use Gtk2::Hexgrid;

my $window = new Gtk2::Window;
my $vbox = new Gtk2::VBox;
my $hbox = new Gtk2::HBox;
$window->add ($vbox);
my $controls = new Gtk2::Table(5,2);
my $sideControls = new Gtk2::Table(2,6);
my $Hexgrid;
$vbox->pack_start($controls, 0, 0, 0);
$vbox->pack_start($hbox, 0, 0, 0);
$hbox->pack_end($sideControls, 0, 0, 0);

my $resetbutton = new Gtk2::Button('Reset');
my $adjW = simple_adj(3,1,7);
my $adjH = simple_adj(8,1,18);
my $width = Gtk2::SpinButton->new ($adjW, 0,1);
my $height = Gtk2::SpinButton->new ($adjH, 0,1);
my $adjLS = simple_adj(30,1,100);
my $adjB = simple_adj(30,0,100);
my $linesize = Gtk2::SpinButton->new ($adjLS, 0,1);
my $border = Gtk2::SpinButton->new ($adjB, 0,1);

my $quit = Gtk2::Button->new ('leave');
my $evenFirst = new Gtk2::CheckButton->new_with_mnemonic ("even rows first");
my $evenLast = new Gtk2::CheckButton->new_with_mnemonic ("even rows last");
my $showCoordinates = new Gtk2::CheckButton->new_with_mnemonic ("show coordinates");
my $showDiag = new Gtk2::CheckButton->new_with_mnemonic ("show diagonal");
$controls->attach_defaults ($resetbutton, 0,1,0,2);
$controls->attach_defaults (new Gtk2::Label('width'), 1,2,0,1);
$controls->attach_defaults ($width, 1,2,1,2);
$controls->attach_defaults (new Gtk2::Label('height'), 2,3,0,1);
$controls->attach_defaults ($height, 2,3,1,2);
$controls->attach_defaults (new Gtk2::Label('line size'), 3,4,0,1);
$controls->attach_defaults ($linesize, 3,4,1,2);
$controls->attach_defaults (new Gtk2::Label('border'), 4,5,0,1);
$controls->attach_defaults ($border, 4,5,1,2);
$controls->attach_defaults ($evenFirst, 5,6,0,1);
$controls->attach_defaults ($evenLast, 5,6,1,2);
$controls->attach_defaults ($showCoordinates, 6,7,0,1);
$controls->attach_defaults ($showDiag, 6,7,1,2);
my $spacing = 0;
$controls->set_row_spacings ($spacing);
$controls->set_col_spacings ($spacing);

my $defaultR = Gtk2::Entry->new_with_max_length (5);
my $defaultG = Gtk2::Entry->new_with_max_length (5);
my $defaultB = Gtk2::Entry->new_with_max_length (5);
$defaultR->set_text(rand());
$defaultG->set_text(rand());
$defaultB->set_text(rand());
$sideControls->attach_defaults (new Gtk2::Label('Default color'), 0,2,0,1);
$sideControls->attach_defaults ($defaultR, 1,2,1,2);
$sideControls->attach_defaults ($defaultG, 1,2,2,3);
$sideControls->attach_defaults ($defaultB, 1,2,3,4);
$sideControls->attach_defaults (new Gtk2::Label('red'), 0,1,1,2);
$sideControls->attach_defaults (new Gtk2::Label('green'), 0,1,2,3);
$sideControls->attach_defaults (new Gtk2::Label('blue'), 0,1,3,4);

$window->signal_connect (destroy => sub { Gtk2->main_quit; });
$quit->signal_connect (clicked => sub { Gtk2->main_quit; });
$resetbutton->signal_connect (clicked => \&reset_hexgrid);

reset_hexgrid();
Gtk2->main;


sub reset_hexgrid{
    if ($Hexgrid){
       # $vbox->remove($Hexgrid);
        $Hexgrid->destroy;
    }
    my $w = $width->get_value;
    my $h = $height->get_value;
    my $ls = $linesize->get_value;
    my $border = $border->get_value;
    my $EFirst = $evenFirst->get_active();
    my $ELast = $evenLast->get_active();
    my $showC = $showCoordinates->get_active();
    my $showD = $showDiag->get_active();
    
    my @defaultColor = ($defaultR->get_text, $defaultG->get_text, $defaultB->get_text);
    for (@defaultColor){
        warn "color value is not numeric" and return unless is_numeric($_);
    }
    $Hexgrid = Gtk2::Hexgrid->new ($w, $h, $ls, $border, $EFirst, $ELast, @defaultColor);
    if ($showC){
        my @tiles = $Hexgrid->get_all_tiles;
        for my $T (@tiles){
            my $fontSize = 20;
            $T->set_text($T->col . ", " . $T->row, $fontSize);

        }
    }
    if($showD){
        my @tiles = $Hexgrid->nw_corner;
        for my $T (@tiles){
            do{
                $T->set_color(map{rand}(1..3))
            } while ($T = $T->southeast);
        }
    }
    my $showPic = 1;
    if($showPic){
        my $T=$Hexgrid->get_tile(1,3);
        $T->set_background('A_w_keim.png') if $T;
    }
    if(1){ #testing stuff
    #    my @tiles = $Hexgrid->se_corner;
    #    $_->set_color(map{rand}(1..3)) for @tiles;
    }
    $Hexgrid->on_click(\&Hexgrid_click_cb);
    $hbox->pack_start($Hexgrid, 0, 0, 0);
    $window->show_all;
}

sub Hexgrid_click_cb{
    my ($x, $y) = @_;
    $Hexgrid->draw_tile(0, $x,$y, 1, .9, 0);
    my @tiles;
    if(1){
        my $tile = $Hexgrid->get_tile($x, $y);
        push @tiles, $tile->n, $tile->ne, $tile->se, $tile->s, $tile->sw, $tile->nw;
        @tiles = grep {defined($_)} @tiles;
    }
    else {
        @tiles = $Hexgrid->get_adjacent_tiles($x,$y);
    }
    for my $T (@tiles){
        $Hexgrid->draw_tile(undef, $T->{col},$T->{row}, 0,.2, .7);
    }
}

sub simple_adj{
    return Gtk2::Adjustment->new($_[0],$_[1],$_[2], 1,1,0);
} 

sub getnum {
    use POSIX qw(strtod);
    my $str = shift;
    $str =~ s/^\s+//;
    $str =~ s/\s+$//;
    $! = 0;
    my($num, $unparsed) = strtod($str);
    if (($str eq '') || ($unparsed != 0) || $!) {
        return undef;
    } else {
        return $num;
    } 
} 
sub is_numeric { defined &getnum($_) } 

