# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::MapMaker;
use strict;
use warnings;
use 5.012;

use base qw(Maplat::Web::BaseModule);

our $VERSION = 0.995;


use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
        
    return $self;
}

sub reload {
    my ($self) = @_;
    
    # Don't need to load any files 

    return;
}

sub register {
    my $self = shift;

    # We don't actually register any URL's. This module is called
    # from other modules to extend the webdata hash
    
    return;
}

sub makeMap {
    my ($self, $webdata, %config) = @_;

    #my %config = (
    #    type    => 'computer|calib',
    #    readonly    => '0|1',
    #
    # For type "computer"
    #    pos_x   => 1234,
    #    pos_y   => 1234,
    #    target_x    => '#position_x_c',
    #    target_y    => '#position_y_c',
    #    infofield   => 'div#computercoords',
    #    status  => 'ok|fail|blink',
    #
    # For type "calib"
    #    pos_a_x   => 1234,
    #    pos_a_y   => 1234,
    #    target_a_x    => '#positiona_x_c',
    #    target_a_y    => '#positiona_y_c',
    #    infofield_a   => 'div#computercoords',
    #    pos_b_x   => 1234,
    #    pos_b_y   => 1234,
    #    target_b_x    => '#positiona_x_c',
    #    target_b_y    => '#positiona_y_c',
    #    infofield_b   => 'div#computercoords',
    #);

    my $html = "";
    my $js = "";
    my $bgimg = $self->{mapimg} || "";
    
    my $height = $self->{height} || 100;
    my $heightpx = $height . "px";
    my $width = $self->{width} || 100;
    my $widthpx = $width . "px";
    my $caliba = $self->{calib_a} || "";
    my $calibb = $self->{calib_a} || "";
    my $computericon = "";
    
    if($config{type} eq "computer") {
        given($config{status}) {
            when("ok") {
                $computericon = $self->{computer_ok} || "";
            }
            when("fail") {
                $computericon = $self->{computer_fail} || "";
            }
            when("blink") {
                $computericon = $self->{computer_blink} || "";
            }
        }
        my $targetx = $config{target_x} || "";
        my $targety = $config{target_y} || "";
        my $infofield = $config{infofield} || "";
        my $posx = ($config{pos_x} || "0") . "px";
        my $posy = ($config{pos_y} || "0") . "px";
        $html .=<<"HTMLCOMPUTER";
<p align="left">
    <div id="computermap" style="position: relative; border: 1px solid rgb(0, 0, 0)">
        <div id="computericon" style="position: absolute; border: 1px solid rgb(0, 0, 0)">
            <img src="$computericon"/>
        </div>
    </div>
</p>
HTMLCOMPUTER
        $js .=<<"JSCOMPUTER1";
    \$(function() {
        \$('#computermap').css("background-image", "url($bgimg)");
        \$('#computermap').css("width", "$widthpx");
        \$('#computermap').css("height", "$heightpx");
JSCOMPUTER1
        if(!defined($config{readonly}) || $config{readonly} eq "0") {
            $js .=<<"JSCOMPUTER2";
        \$('#computericon').draggable({
        
            stop: function(event, ui) {
        
                // Show dropped position.
                var Stoppos = \$(this).position();
                var xpos = Stoppos.left;
                var ypos = Stoppos.top;
                
                if("$targetx" != "") {
                    \$("$targetx").val(xpos);
                }
                if("$targety" != "") {
                    \$("$targety").val(ypos);
                }
                
                if("$infofield" != "") {
                    var tmpstring = xpos + " : " + ypos;    
                    \$("$infofield").text(tmpstring);
                }
            }
        });
JSCOMPUTER2
        }

        $js .=<<"JSCOMPUTER3";        
    });
    
    function startMap() {
        var xstring = "$posx";
        var ystring = "$posy";
        \$('#computericon').css("left", xstring);
        \$('#computericon').css("top", ystring)
    }
JSCOMPUTER3

    }
    
    my $complete = <<"COMPLETEMAP";
$html

<script language="javascript">
$js
</script>
COMPLETEMAP
    
    $webdata->{MAPMAKER} = $complete;
    return;
}

1;
__END__

=head1 NAME

Maplat::Web::MapMaker - Generate MAPS with draggable items

=head1 SYNOPSIS

This module creates maps (floor plans, ...) with moveable icon.

=head1 DESCRIPTION

This module can be used in various ways. Currently, it's mainly used in the ComputerDB modules
to track where the computers are on the floor plan.

=head1 Configuration

        <module>
            <modname>computermap</modname>
            <pm>MapMaker</pm>
            <options>
                <mapimg>/static/hallenplan_computerdb.jpg</mapimg>
                <width>1190</width>
                <height>826</height>
                <computer_ok>/static/hallenplan_computer_ok.gif</computer_ok>
                <computer_fail>/static/hallenplan_computer_fail.gif</computer_fail>
                <computer_blink>/static/hallenplan_computer_failblink.gif</computer_blink>
                <calib_a>/static/hallenplan_kalib_h3.gif</calib_a>
                <calib_b>/static/hallenplan_kalib_c8.gif</calib_b>
            </options>
        </module>

=head2 makeMap

Add the MAP markup to webdata.

=head1 SEE ALSO

Maplat::Web

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
