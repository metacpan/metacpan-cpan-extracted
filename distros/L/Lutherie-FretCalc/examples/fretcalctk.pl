#!/usr/bin/perl -w
###############################################################
# fretcalctk.pl                                               #
# Copyright (c) 2002 Douglas S Sparling. All rights reserved. #
# This program is free software; you can redistribute it      #
# and/or modify it under the same terms as Perl itself.       #
###############################################################
use strict;
use Tk;
use Tk::Dialog;
use Lutherie::FretCalc;

my $VERSION = '0.03';

my $rb1 = 0; # Mode
my $rb2 = 0; # Precision
my $rb3 = 0; # In Units
my $rb4 = 0; # Out Units
my $rb5 = 0; # Calc Method

my $mw = MainWindow->new();

# Set app size and center
my $screen_width = $mw->screenwidth;
my $screen_height = $mw->screenheight;
my $pos_x = $screen_width / 2;
my $pos_y = $screen_height / 2;
my $size_x = 500;
#my $size_x = 400;
#my $size_y = 335;
#my $size_y = 365;
my $size_y = 450;
$mw->geometry($size_x.'x'.$size_y.'+'.$pos_x.'+'.$pos_y);

# Disable window resize
$mw->resizable(0,0);

# Set the title
$mw->title("FretCalcTk $VERSION");

# Create the menubar
my $menubar = $mw->Frame(-relief => 'raised',
                         -borderwidth => 2,
)->place(-x => 0, -y => 0, -relwidth => 1.0);

# Create the menubuttons
my $menu_file = $menubar->Menubutton(-text => 'File',
                                     -underline => 0,
                                     -tearoff => 0
)->pack(-side => 'left');

my $menu_calc = $menubar->Menubutton(-text => 'Calc',
                                        -underline => 0,
                                        -tearoff => 0
)->pack(-side => 'left');


my $menu_help = $menubar->Menubutton(-text => 'Help',
                                     -underline => 0,
                                     -tearoff => 0
)->pack(-side => 'left');

# Create menu items

# File menu items
$menu_file->command(-label => 'Print',
                    -command => [\&print, 'Print not implemented'],
                    -underline => 1);

$menu_file->separator();

$menu_file->command(-label => 'Exit',
                    -command => sub { exit },
                    -underline => 1);

# Calc menu items
# Mode Cascade
my $menu_mode_cascade = $menu_calc->menu->Menu();

$menu_mode_cascade->radiobutton(-label => 'Standard',
                           #-command => \&mode,
                           -variable => \$rb1,
                           -value => 'Standard');

$menu_mode_cascade->radiobutton(-label => 'Dulcimer',
                           #-command => \&mode,
                           -variable => \$rb1,
                           -value => 'Dulcimer');

$menu_calc->cascade(-label => 'Mode');

$menu_calc->entryconfigure('Mode', -menu => $menu_mode_cascade);

$menu_calc->separator();

# Precision Cascade
my $menu_prec_cascade = $menu_calc->menu->Menu();

$menu_prec_cascade->radiobutton(-label => '.1',
                           #-command => \&display_radiobutton2,
                           -variable => \$rb2,
                           -value => '.1');

$menu_prec_cascade->radiobutton(-label => '.01',
                           #-command => \&display_radiobutton2,
                           -variable => \$rb2,
                           -value => '.01');

$menu_prec_cascade->radiobutton(-label => '.001',
                           #-command => \&display_radiobutton2,
                           -variable => \$rb2,
                           -value => '.001');

$menu_prec_cascade->radiobutton(-label => '.0001',
                           #-command => \&display_radiobutton2,
                           -variable => \$rb2,
                           -value => '.0001');


$menu_calc->cascade(-label => 'Precision');

$menu_calc->entryconfigure('Precision', -menu => $menu_prec_cascade);


# Help menu items
$menu_help->command(-label => 'Help',
                    -command => [\&help, 'Help not implemented']);

$menu_help->separator();

$menu_help->command(-label => 'About',
                    -command => [\&about_dialog]);


### About Dialog ###
my $dialog_text = "FretCalcTk $VERSION\n\n";
$dialog_text .= "Copyright 2002 Douglas S. Sparling. All rights reserved.\n\n".
                "This program is free software; you can redistribute it ".
                "and/or modify it under the same terms as Perl itself.\n\n";
$dialog_text .= 'doug@dougsparling.com' . "\n";
$dialog_text .= 'http://www.dougsparling.com/software/fretcalc/' . "\n";
my $dialog_title = "FretCalcTk $VERSION";
my $dialog = $mw->Dialog(-text => $dialog_text, -title => $dialog_title,
                         -default_button => 'OK', -buttons => [qw/OK/]);


### Place our widgets ###

### Text Area ###
#my $text = $mw->Text()->place(-x => 0, -y => 28, -height => 400, -width => 180);
my $text = $mw->Scrolled('Text', -scrollbars => 'e')->place(-x => 0, -y => 28, -height => 410, -width => 180);

### Scale length/In units ###
$mw->Label(-text => 'Scale Length')->place(-x => 190, -y => 30);
my $scale_length = $mw->Entry(-validate => 'key',
                          -validatecommand => sub {
                          my($proposed, $chars, $current, $index, $type) = @_;
                          return $proposed =~ /^[\d\.\s]*$/;
                          },                          
)->place(-x => 190, -y => 50, -width => 120);

# In units (scale) radio buttons
$mw->Radiobutton(-text => 'Inches - Decimal',
                 -value => 1,
                 -variable => \$rb3)->place(-x => 190, -y => 80);

$mw->Radiobutton(-text => 'Inches - Fraction',
                 -value => 2,
                 -state => 'disabled',  # Not functional
                 -variable => \$rb3)->place(-x => 190, -y => 100);

$mw->Radiobutton(-text => 'Millimeters',
                 -value => 3,
                 -variable => \$rb3)->place(-x => 190, -y => 120);

$mw->Radiobutton(-text => 'Common',
                 -value => 4,
                 -state => 'disabled',  # Not functional
                 -variable => \$rb3)->place(-x => 190, -y => 140);

### Calc Method ###
$mw->Label(-text => 'Calc Method')->place(-x => 190, -y => 180);

$mw->Radiobutton(-text => '12th root of 2',
                 -value => 1,
                 -variable => \$rb5)->place(-x => 190, -y => 200);

$mw->Radiobutton(-text => '17.817',
                 -value => 2,
                 -variable => \$rb5)->place(-x => 190, -y => 220);

$mw->Radiobutton(-text => '17.835',
                 -value => 3,
                 -variable => \$rb5)->place(-x => 190, -y => 240);

$mw->Radiobutton(-text => '18',
                 -value => 4,
                 -variable => \$rb5)->place(-x => 190, -y => 260);

$mw->Radiobutton(-text => 'Non 12-tone',
                 -value => 5,
                 -state => 'disabled',  # Not functional
                 -variable => \$rb5)->place(-x => 190, -y => 280);

### Settings ###
$mw->Label(-text => 'Settings')->place(-x => 190, -y => 320);
my $mode_setting = $mw->Label(-text => 'Mode:')->place(-x => 190, -y => 340);
my $sl_setting = $mw->Label(-text => 'Scale Length:')->place(-x => 190, -y => 360);
my $nf_setting = $mw->Label(-text => 'Number of Frets:')->place(-x => 190, -y => 380);
my $out_setting = $mw->Label(-text => 'Out Units:')->place(-x => 190, -y => 400);
my $method_setting = $mw->Label(-text => 'Calc Method:')->place(-x => 190, -y => 420);

### Frets/Out Units ###
$mw->Label(-text => 'Number of Frets')->place(-x => 335, -y => 30);
my $num_frets = $mw->Entry(-validate => 'key',
                          -validatecommand => sub {
                          my($proposed, $chars, $current, $index, $type) = @_;
                          return $proposed =~ /^[\d\s]*$/;
                          },                          
)->place(-x => 335, -y => 50, -width => 120);

# Out units radio buttons
$mw->Radiobutton(-text => 'Inches - Decimal',
                 -value => 1,
                 -variable => \$rb4)->place(-x => 335, -y => 80);

$mw->Radiobutton(-text => 'Inches - Nearest 1/64"',
                 -value => 2,
                 -state => 'disabled',  # Not functional
                 -variable => \$rb4)->place(-x => 335, -y => 100);

$mw->Radiobutton(-text => 'Millimeters',
                 -value => 3,
                 -variable => \$rb4)->place(-x => 335, -y => 120);


#$mw->Label(-text => 'Half Frets')->place(-x => 335, -y => 150);

$mw->Button(-text => 'Calculate',
            -command => \& calculate)->place(-x => 400, -y => 415);
            #-command => \& calculate)->place(-x => 350, -y => 415);
#$mw->Button(-text => 'Exit',
#            -command => sub { exit })->place(-x => 435, -y => 415);


### Initialize ###
my $fretcalc = Lutherie::FretCalc->new();
$scale_length->focus();
$rb1 = 'Standard';
$rb2 = '.0001';
$rb3 = 1; # In units = in
$rb4 = 1; # Out units = in
$rb5 = 1; # Calc method = 12th root of 2
my $item = "Fret\tDist from Nut\n";
$text->delete('1.0', 'end');
$text->insert('end', $item);

MainLoop;

### Subs ###

sub calculate {

    # Set precision
    if ($rb2 == .1) {
        $fretcalc->precision(1);
    } elsif ($rb2 == .01) {
        $fretcalc->precision(2);
    } elsif ($rb2 == .001) {
        $fretcalc->precision(3);
    } elsif ($rb2 == .0001) {
        $fretcalc->precision(4);
    }

    # Set in units
    if ($rb3 == 1) {
        # Inches - Decimal
        $fretcalc->in_units('in');
    } elsif ($rb3 == 2) {
        # Inches - Fraction
        #$fretcalc->in_units();
    } elsif ($rb3 == 3) {
        # Millimeters
        $fretcalc->in_units('mm');
    } elsif ($rb3 == 4) {
        # Common
        #$fretcalc->in_units();
    }

    # Set out units
    my $out_units;
    if ($rb4 == 1) {
        # Inches - Decimal
        $out_units = 'Inches - Decimal';
        $fretcalc->out_units('in');
    } elsif ($rb4 == 2) {
        # Inches - Nearest 1/64"
        #$out_units = 'Inches - Nearest 1/64"';
        #$fretcalc->out_units();
    } elsif ($rb4 == 3) {
        # Millimeters
        $out_units = 'Millimeters';
        $fretcalc->out_units('mm');
    }

    # Set calc method
    my $calc_method;
    if ($rb5 == 1) {
        # 12th root of 2 
        $calc_method = '12th root of 2';
        $fretcalc->calc_method('t');
    } elsif ($rb5 == 2) {
        # 17.817 
        $calc_method = '17.817';
        $fretcalc->calc_method('ec');
    } elsif ($rb5 == 3) {
        # 17.835 
        $calc_method = '17.835';
        $fretcalc->calc_method('es');
    } elsif ($rb5 == 4) {
        # 18 
        $calc_method = '18'; 
        $fretcalc->calc_method('ep');
    } elsif ($rb5 == 5) {
        # Non 12-tone 
        #$calc_method = 'Non 12-tone';
        #$fretcalc->calc_method('ep');
    }


    # Get scale length and number of frets
    my $sl = $scale_length->get();
    my $nf = $num_frets->get();

    # Settings
    $mode_setting->configure(-text => "Mode: $rb1");
    $sl_setting->configure(-text => "Scale Length: $sl");
    $nf_setting->configure(-text => "Number of Frets: $nf");
    $out_setting->configure(-text => "Out Units: $out_units");
    $method_setting->configure(-text => "Calc Method: $calc_method");

    $fretcalc->scale($sl);
    $fretcalc->num_frets($nf);

    #my ($item, @chart, %chart);
    my $item = "Fret\tDist from Nut\n";
    if( $rb1 eq 'Standard' ) {
        my @chart = $fretcalc->fretcalc();
        $item = "Fret\tDist from Nut\n";
        for my $fret(1..$#chart) {
            $fret = sprintf("%3d",$fret);
            $item .= "$fret\t$chart[$fret]\n";
        }
    } elsif( $rb1 eq 'Dulcimer' ) {
        $fretcalc->half_fret(6);
        $fretcalc->half_fret(13);
        my %chart = $fretcalc->dulc_calc();
        foreach my $fret (sort {$a <=> $b} keys %chart) {
            my $dist = $chart{$fret};
            my $fret = sprintf("%4s",$fret);
            $item .= "$fret\t$dist\n";
        }
    }

    chomp $item;

    $text->delete('1.0', 'end');
    $text->insert('end', $item);
}

sub about_dialog {

    $dialog->Show();
}

### Stubs ###
sub print {
    my ($item) = @_;
    print "$item\n";
}

sub help {
    my ($item) = @_;
    print "$item\n";
}

sub mode {
    print "Mode not implemented\n";
}
