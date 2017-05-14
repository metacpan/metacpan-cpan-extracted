# Copyright (C) 1998 Tuomas J. Lukka
# Portions Copyright (C) 1998 John Breen
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.


use strict qw/vars/;

# 
# The different viewers for VRML::Browser.
#
# All viewers are given the current viewpoint node
# and their own internal coordinate system (position+rotation)
# from that.
#
# XXX Examine doesn't handle animated viewpoints at all!


# The following is POD documentation for the freewrl command.
# It will be automatically installed in a manual page upon make install.
# See the perlpod manpage for the I<>, C<> &c explanation

=head1 NAME

VRML::Viewer -- navigation modes of FreeWRL

=head1 SYNOPSIS

(used internally by FreeWRL)


=head1 DESCRIPTION

This module implements the various
navigation modes for the FreeWRL VRML browser
(see L<VRML::Browser>, L<freewrl>). 
L<freewrl> explains how to use the navigation modes.

=head1 AUTHOR

Tuomas J. Lukka, with help from John Breen.

=cut

package VRML::Viewer;
require 'VRML/Quaternion.pm';

# Default gaze: -z, pos: z
sub new {
	my($type,$old) = @_;
	my $this = bless {
	# For our viewpoint
		Pos => [0,0,10],
		Dist => 10,
		Quat => new VRML::Quaternion(1,0,0,0),
	# The viewpoint node at the time of the binding -- we have
	# to counteract it.
	# AntiPos is the real position, AntiQuat is inverted ;)
		AntiPos => [0,0,0],
		AntiQuat => new VRML::Quaternion(1,0,0,0),
		Navi => undef,
	}, $type;
	if($old) {
		$this->{Pos} = $old->{Pos};
		$this->{Quat} = $old->{Quat};
		$this->{Dist} = $old->{Dist};
		$this->{AntiPos} = $old->{AntiPos};
		$this->{AntiQuat} = $old->{AntiQuat};
                $this->{Navi} = $old->{Navi};
	} else {
                $this->{Navi} = VRML::Scene->new_node("NavigationInfo",
                                VRML::Nodes->{NavigationInfo}{Defaults});
        }
	$this->resolve_pos();
	return $this;
}

sub use_keys { 0 }

sub handle_tick { }

sub bind_viewpoint {
	my($this,$node,$bind_info) = @_;
	if(defined $bind_info) {
		$this->{Pos} = $bind_info->[0];
		$this->{Quat} = $bind_info->[1];
	} else {
		$this->{Pos} = [@{$node->{Fields}{position}}];
		$this->{Quat} = VRML::Quaternion->new_vrmlrot(
		@{$node->{Fields}{orientation}});
	}
	$this->{AntiPos} = [@{$node->{Fields}{position}}];
	$this->{AntiQuat} = VRML::Quaternion->new_vrmlrot(
		@{$node->{Fields}{orientation}})->invert;
	$this->resolve_pos();
}

sub resolve_pos { } # hook to modify Pos & Quat, e.g. for Examine

# Just restore these later...
sub unbind_viewpoint {
	my($this,$node) = @_;
	return [$this->{Pos},$this->{Quat}];
}

sub bind_navi_info {
	my($this,$node) = @_;
	$this->{Navi} = $node;
}

sub togl {
	my($this) = @_;
	$this->{Quat}->togl();
	VRML::OpenGL::glTranslatef(map {-$_} @{$this->{Pos}});
	VRML::OpenGL::glTranslatef(@{$this->{AntiPos}});
	$this->{AntiQuat}->togl();
}

package VRML::Viewer::None;
@VRML::Viewer::None::ISA=VRML::Viewer;

sub new {
	my($type, $loc, $ori) = @_;
	my $this = VRML::Viewer->new();
	$this->{Pos} = $loc;
	$this->{Quat} = new_vrmlrot VRML::Quaternion(@$ori);
	return $this;
}

package VRML::Viewer::Walk;
@VRML::Viewer::Walk::ISA=VRML::Viewer;

sub handle {
       #my($this, $mev, $but, $mx, $my) = @_;
       ## print "VEIEVENT\n";
       #if($mev eq "PRESS" and $but == 1) {
       #        $this->{SY} = $my;
       #        $this->{SX} = $mx;
       #} elsif($mev eq "DRAG" and $but == 1) {
       #        my $yd = ($my - $this->{SY});
       #        my $xd = ($mx - $this->{SX});
       #        my $nv = $this->{Quat}->invert->rotate([0,0,0.15*$yd]);
       #        for(0..2) {$this->{Pos}[$_] += $nv->[$_]}
       #        my $nq = new VRML::Quaternion(1-0.2*$xd,0,0.2*$xd,0);
       #        $nq->normalize_this;
       #        $this->{Quat} = $nq->multiply($this->{Quat});
       #        print "WVIEW: (",(join ',',@{$this->{Quat}}),") (",
       #                        (join ',',@{$this->{Pos}}),") (",
       #                        (join ',',@{$nv}),") \n";
       #}
    my($this, $mev, $but, $mx, $my) = @_;
    # print "VEIEVENT\n";
    if($mev eq "PRESS" and $but == 1) {
        $this->{SY} = $my;
        $this->{SX} = $mx;
    } elsif($mev eq "PRESS" and $but == 3) {
        $this->{SY} = $my;
        $this->{SX} = $mx;
    } elsif($mev eq "DRAG" and $but == 1) {
        $this->{ZD} = ($my - $this->{SY}) * $this->{Navi}{Fields}{speed};
        $this->{RD} = ($mx - $this->{SX}) * 0.1;
    } elsif($mev eq "DRAG" and $but == 3) {
        $this->{XD} = ($mx - $this->{SX}) * $this->{Navi}{Fields}{speed};
        $this->{YD} = -($my - $this->{SY}) * $this->{Navi}{Fields}{speed};
    } elsif ($mev eq "RELEASE") {
        if ($but == 1) {
            $this->{ZD} = 0;
            $this->{RD} = 0;
        } elsif ($but == 3) {
            $this->{XD} = 0;
            $this->{YD} = 0;
        }
    }
}

sub handle_tick {
    my($this, $time) = @_;
    # print "handle_tick: time=$time rd=$this->{RD} yd=$this->{YD} zd=$this->{ZD}\n";
    my $nv = $this->{Quat}->invert->rotate([0.15*$this->{XD},0.15*$this->{YD},0.15*$this->{ZD}]);
    for(0..2) {$this->{Pos}[$_] += $nv->[$_]}
    my $nq = new VRML::Quaternion(1-0.2*$this->{RD},0,0.2*$this->{RD},0);
    $nq->normalize_this;
    $this->{Quat} = $nq->multiply($this->{Quat});
}


# # The old routine
# sub handle {
# 	my($this, $mev, $but, $mx, $my) = @_;
# 	# print "VEIEVENT\n";
# 	if($mev eq "PRESS" and $but == 1) {
# 		$this->{SY} = $my;
# 		$this->{SX} = $mx;
# 	} elsif($mev eq "DRAG" and $but == 1) {
# 		my $yd = ($my - $this->{SY});
# 		my $xd = ($mx - $this->{SX});
# 		my $nv = $this->{Quat}->invert->rotate([0,0,0.15*$yd]);
# 		for(0..2) {$this->{Pos}[$_] += $nv->[$_]}
# 		my $nq = new VRML::Quaternion(1-0.2*$xd,0,0.2*$xd,0);
# 		$nq->normalize_this;
# 		$this->{Quat} = $nq->multiply($this->{Quat});
# 		print "WVIEW: (",(join ',',@{$this->{Quat}}),") (",
# 				(join ',',@{$this->{Pos}}),") (",
# 				(join ',',@{$nv}),") \n";
# 	}
# }

sub ignore_vpcoords {
	return 0;
}

package VRML::Viewer::Fly; # Modeled after Descent(tm) ;)
@VRML::Viewer::Fly::ISA=VRML::Viewer;
#
# Members:
#  Velocity - current velocity as 3-vector
#  

# Do nothing for the mouse

sub use_keys { 1 }

sub handle {
}

sub handle_key {
	my($this,$time,$key) = @_;
	$key = lc $key;
	$this->{Down}{$key} = 1;
}

sub handle_keyrelease {
	my($this,$time,$key) = @_;
	# print "KEYREL!\n";
	$key = lc $key;
	$this->{WasDown}{$key} += $this->{Down}{$key};
	delete $this->{Down}{$key};
}

{
my @aadd;
my @radd;
my %actions = (
	a => sub {$aadd[2] -= $_[0]},
	z => sub {$aadd[2] += $_[0]},
	j => sub {$aadd[0] -= $_[0]},
	l => sub {$aadd[0] += $_[0]},
	p => sub {$aadd[1] += $_[0]},
	';' => sub {$aadd[1] -= $_[0]},

	8 => sub {$radd[0] += $_[0]},
	k => sub {$radd[0] -= $_[0]},
	u => sub {$radd[1] -= $_[0]},
	o => sub {$radd[1] += $_[0]},
	7 => sub {$radd[2] -= $_[0]},
	9 => sub {$radd[2] += $_[0]},
);
my $lasttime = -1;
sub handle_tick {
	my($this, $time) = @_;
	if(!defined $this->{Velocity}) {$this->{Velocity} = [0,0,0]}
	if(!defined $this->{AVelocity}) {$this->{AVelocity} = [0,0,0]}
	if($lasttime == -1) {$lasttime = $time;}
# First, get all the keypresses since the last time
	my %ps;
	for(keys %{$this->{Down}}) {
		$ps{$_} += $this->{Down}{$_};
	}
	for(keys %{$this->{WasDown}}) {
		$ps{$_} += delete $this->{WasDown}{$_};
	}
	undef @aadd;
	undef @radd;
	for(keys %ps) {
		if(exists $actions{$_}) {
			$actions{$_}->($ps{$_}?1:0);
			# print "Act: '$_', $ps{$_}\n";
		} 
	}
	my $v = $this->{Velocity};
	my $ind = 0;
	my $dt = $time-$lasttime;
	for(@$v) {$_ *= 0.06 ** ($dt);
		$_ += $dt * $aadd[$ind++] * 14.5;
		if(abs($_) > 9.0) {$_ /= abs($_)/9.0}
	}
	my $nv = $this->{Quat}->invert->rotate(
		[map {$_ * $dt} @{$this->{Velocity}}]
		);
	for(0..2) {$this->{Pos}[$_] += $nv->[$_]}

	my $av = $this->{AVelocity};
	$ind = 0;
	my $sq;
	for(@$av) {$_ *= 0.04 ** ($dt);
		$_ += $dt * $radd[$ind++] * 0.1;
		if(abs($_) > 0.8) {$_ /= abs($_)/0.8;}
		$sq += $_*$_;
	}
	my $nq = new VRML::Quaternion(1,@$av);
	$nq->normalize_this;
	$this->{Quat} = $nq->multiply($this->{Quat});

#	print "HANDLE_TICK($dt): @aadd | @{$this->{Velocity}} | @$nv\n";
	$lasttime = $time;
}
}

package VRML::Viewer::Examine;
@VRML::Viewer::Examine::ISA=VRML::Viewer;

# Semantics: given a viewpoint and orientation,
# we take the center to revolve around to be the closest point to origin
# on the z axis.

sub resolve_pos {
	my($this) = @_;
        my $z = $this->{Quat}->invert->rotate([0,0,1]);
	# my $l = 0; for(0..2) {$l += $this->{Pos}[$_]**2} $l = sqrt($l);
	my $d = 0; for(0..2) {$d += $this->{Pos}[$_] * $z->[$_]}
	$this->{Origin} = [ map {$this->{Pos}[$_] - $d * $z->[$_]} 0..2 ];
	$this->{Dist} = $d;
}

# Mev: PRESS, DRAG
sub handle {
	my($this, $mev, $but, $mx, $my) = @_;
	 # print "HANDLE $mev $but $mx $my\n";
	if($mev eq "PRESS" and $but == 1) {
		# print 'PRESS\n';
		$this->{SQuat} = $this->xy2qua($mx,$my);
		$this->{OQuat} = $this->{Quat};
	} elsif($mev eq "DRAG" and $but == 1) {
		my $q = $this->xy2qua($mx,$my);
		my $arc = $q->multiply($this->{SQuat}->invert());
		# print "Arc: ",(join '   ',@$arc),"\n";
		$this->{Quat} = $arc->multiply($this->{OQuat});
		# print "Quat:\t\t\t\t ",(join '   ',@{$this->{Quat}}),"\n";
		# $this->{Quat} = $this->{OQuat}->multiply($arc);
#		print "DRAG1: (",
#			(join ',',@{$this->{SQuat}}), ") (",
#			(join ',',@{$this->{OQuat}}), ")\n (",
#			(join ',',@$q), ")\n (",
#			(join ',',@$arc), ") (",
#			(join ',',@{$this->{Quat}}), ")\n",
	} elsif($mev eq "PRESS" and $but == 3) {
		$this->{SY} = $my;
		$this->{ODist} = $this->{Dist};
	} elsif($mev eq "DRAG" and $but == 3) {
		$this->{Dist} = $this->{ODist} * exp($this->{SY} - $my);
	}
	$this->{Pos} = $this->{Quat}->invert->rotate([0,0,$this->{Dist}]);
	for(0..2) {$this->{Pos}[$_] += $this->{Origin}[$_]}
	# print "POS:     ",(join '    ',@{$this->{Pos}}),"\n";
	# print "QUASQ: ",$this->{Quat}->abssq,"\n";
	# print "VIEW: (",(join ',',@{$this->{Quat}}),") (",
	# 	 	(join ',',@{$this->{Pos}}),")\n";
}

sub change_viewpoint {
	my($this, $jump, $push, $ovp, $nvp) = @_;
	if($push == 1) { # Pushing the ovp under - must store stuff...
		$ovp->{Priv}{viewercoords} = [
			$this->{Dist}, $this->{Quat}
		];
	} elsif($push == -1 && $jump && $nvp->{Priv}{viewercoords}) {
		($this->{Dist}, $this->{Quat}) = 
			@{$nvp->{Priv}{viewercoords}};
	}
	if($push == -1) {
		delete $ovp->{Priv}{viewercoords};
	}
	if(!$jump) {return}
	my $f = $nvp->getfields();
	my $p = $f->{position};
	my $o = $f->{orientation};
	my $os = sin($o->[3]); my $oc = cos($o->[3]);
	$this->{Dist} = sqrt($p->[0]**2 + $p->[1]**2 + $p->[2]**2);
	$this->{Quat} = new VRML::Quaternion(
		$oc, map {$os * $_} @{$o}[0..2]);
}

# Whether to ignore the internal VP coords aside from jumps?
sub ignore_vpcoords {
	return 1;
}

# ArcCone from TriD
sub xy2qua {
	my($this, $x, $y) = @_;
#	print "XY2QUA: $x $y\n";
	$x -= 0.5; $y -= 0.5; $x *= 2; $y *= 2;
	$y = -$y;
	my $dist = sqrt($x**2 + $y**2);
#	print "DXY: $x $y $dist\n";
	if($dist > 1.0) {$x /= $dist; $y /= $dist; $dist = 1.0}
	my $z = 1-$dist;
	# print "Z: $z\n";
	my $qua = VRML::Quaternion->new(0,$x,$y,$z);
#	print "XY2QUA: $x $y ",(join ',',@$qua),"\n";
	$qua->normalize_this();
#	print "XY2QUA: $x $y ",(join ',',@$qua),"\n";
	return $qua;

}

1;
