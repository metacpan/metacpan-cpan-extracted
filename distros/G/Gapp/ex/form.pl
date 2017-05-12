#!/usr/bin/perl -w
use strict;
use warnings;

use lib qw( ..\lib lib );

use Gapp;
use Gapp::Actions::Form qw( Apply Cancel Ok );

my $map = <<ENDMAP;
+-[--------[----------+------------------------------------+
|  Label | Entry                                           |
+-[--------[----------+------------------------------------+
| Label  | ComboBox                                        |
+-[--------[----------+-[----------------------------------+
| Label  | o Radio    | o Radio                            |
+-[--------[----------+------------------------------------+
| Label  | o Check                                         |
+->------+------------+------------------------------------+
|  ButtonBox                                               |
+--------+------------+------------------------------------+
ENDMAP

my $w = Gapp::Window->new(
    traits => [qw( Form )],
    content => Gapp::Table->new(
        map => $map,
        content => [
            Gapp::Label->new( text => 'Entry' ),
            Gapp::Entry->new( field => 'entry' ),
            
            Gapp::Label->new( text => 'ComboBox' ),
            Gapp::ComboBox->new( field => 'combo', values => [ '', '1', '2', '3' ] ),
            
            Gapp::Label->new( text => 'RadioButton' ),
            Gapp::RadioButton->new( field => 'radio', value => 1, label => 'True' ),
            Gapp::RadioButton->new( field => 'radio', value => 0, label => 'False' ),
            
            Gapp::Label->new( text => 'CheckButton' ),
            Gapp::CheckButton->new( field => 'check', label => 'True' ),
            
            Gapp::HButtonBox->new( content => [
                my $button1 = Gapp::Button->new(
                    action => Cancel->clone(
                        code => sub {
                            print @_, "\n";
                        }
                    ),
                ),
                my $button2 = Gapp::Button->new(
                    action => Apply,
                ),
                my $button3 = Gapp::Button->new(
                    action => Ok,
                ),
            ]),
        ],
        apply_action => sub {
            
        }
    )
);

$w->show_all;
Gapp->main;