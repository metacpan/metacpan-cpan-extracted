# Copyright (C) 1998 Tuomas J. Lukka
# DISTRIBUTED WITH NO WARRANTY, EXPRESS OR IMPLIED.
# See the GNU Library General Public License (file COPYING in the distribution)
# for conditions of use and redistribution.


# Implement OpenGL backend using the C structs.

package VRML::GLBackEnd;
use VRML::OpenGL;
use VRML::VRMLFunc;
VRML::VRMLFunc::set_divs(10,10);
if($VRML::verbose::rend) {
	VRML::VRMLFunc::render_verbose(1);
}
require 'VRML/VRMLCU.pm';
require 'VRML/Viewer.pm';
use strict vars;
# ISA?

###############################################################
#
# Public backend API

####
#
# Set rendering accuracy vs speed tradeoff
# 
# Currently only has effect when something changes - otherwise
# values stored in the display lists are used for nodes.

sub set_best {
	glShadeModel(&GL_SMOOTH);
	VRML::VRMLFunc::set_divs(20,20);
}
sub set_fast {
	glShadeModel(&GL_FLAT);
	VRML::VRMLFunc::set_divs(8,8);
}

####
#
# Set / pop views for snapshots

sub pushview {
	my($this, $loc, $ori) = @_;
	push @{$this->{AView}}, $this->{Viewer};
	$this->{Viewer} = VRML::Viewer::None->new($loc,$ori);
}

sub popview {
	my($this) = @_;
	$this->{Viewer} = pop @{$this->{AView}};
}

####
#
# Take a snapshot of the world. Returns array ref, 
# first member: width, second: height and third is a raw string
# of RGB values. You can use e.g. rawtoppm to convert this

sub snapshot {
	my($this) = @_;
	my($w,$h) = @{$this}{qw/W H/};
	my $n = 3*$w*$h;
	my $str = pack("C$n");
	glPixelStorei(&GL_UNPACK_ALIGNMENT,1);
	glPixelStorei(&GL_PACK_ALIGNMENT,1);
	glReadPixels(0,0,$w,$h,&GL_RGB,&GL_UNSIGNED_BYTE,
		$str);
	return [$w,$h,$str];
}

###############################################################
#
# Private functions, used by other browser modules below

if(0) {
VRML::VRMLFunc::render_verbose(1);
$VRML::verbose = 1;
}

sub new {
	my($type,%pars) = @_;
	my $this = bless {}, $type;

	my($w,$h) = (300,300);
        my $x = 0; 
        my $y = 0; 

	if(my $g = $pars{Geometry}) {
		$g =~ /^(\d+)x(\d+)(?:([+-]\d+)([+-]\d+))?$/ 
			or die("Invalid geometry string '$g' given to GLBackend");
		($w,$h,$x,$y) = ($1,$2,$3,$4);
		# print "GEOMETRY: $w $h $x $y\n";
	}

	$this->{W} = $w; $this->{H} = $h;
        my @db = &GLX_DOUBLEBUFFER;
#       my @db = ();
        if($VRML::offline) {$x = -1; @db=()}
        
        print "STARTING OPENGL\n" if $VRML::verbose;
        glpOpenWindow(attributes=>[&GLX_RGBA, @db,
                                &GLX_RED_SIZE,1,
                                &GLX_GREEN_SIZE,1,
                                &GLX_BLUE_SIZE,1,
                                &GLX_DEPTH_SIZE,1,
# Alpha size?
                        ],
                mask => (KeyPressMask | &KeyReleaseMask | ButtonPressMask |
                        ButtonMotionMask | ButtonReleaseMask |
                        ExposureMask | StructureNotifyMask |
                        PointerMotionMask),
                width => $w,height => $h,
                "x" => $x,
                "y" => $y,
		cmap => !$VRML::ENV{FREEWRL_NO_COLORMAP});

        glClearColor(0,0,0,1);
#        my $lb = VRML::OpenGL::glpRasterFont("5x8",0,256);
#        $VRML::OpenGL::fontbase = $lb;
#       glDisable(&GL_DITHER);
        # glShadeModel (&GL_SMOOTH);
        glShadeModel (&GL_FLAT);
        glEnable(&GL_DEPTH_TEST);
        glEnable(&GL_NORMALIZE);
        glEnable(&GL_LIGHTING);
        glEnable(&GL_LIGHT0);
	glEnable(&GL_CULL_FACE);
        glLightModeli(&GL_LIGHT_MODEL_TWO_SIDE, &GL_TRUE);
        glLightModeli(&GL_LIGHT_MODEL_LOCAL_VIEWER, &GL_FALSE);
        # glLightModeli(&GL_LIGHT_MODEL_TWO_SIDE, &GL_TRUE);

	glEnable(&GL_POLYGON_OFFSET_EXT);
	glPolygonOffsetEXT(0.0000000001,0.00002);

	glPixelStorei(&GL_UNPACK_ALIGNMENT,1);
	glPixelStorei(&GL_PACK_ALIGNMENT,1);

        # $this->reshape();

# Try to interface with Tk event loop?
        if(defined &Tk::DoOneEvent) {
                my $gld = VRML::OpenGL::glpXConnectionNumber();
                # Create new mainwindow just for us.
                my $mw = MainWindow->new();
                $mw->iconify();
                my $fh = new FileHandle("<&=$gld\n") 
                        or die("Couldn't reopen GL filehandle");
                $mw->fileevent($fh,'readable',
                   sub {# print "GLEV\n"; 
                        $this->twiddle(1)});
                $this->{FileHandle} = $fh;
                $this->{MW} = $mw;
        }

        $this->{Interactive} = 1;
        print "STARTED OPENGL\n" if $VRML::verbose;

        if($VRML::offline) {
                $this->doconfig($w,$h);
        }
	$this->{Viewer} = VRML::Viewer::Examine->new;

	return $this;
}

# Set the sub used to go forwards/backwards in VP list
sub set_vp_sub {
	$_[0]{VPSub} = $_[1];
}

sub quitpressed {
	return delete $_[0]{QuitPressed};
}

sub update_scene {
	my($this,$time) = @_;

	while(XPending()) {
		# print "UPDS: Xpend:",XPending(),"\n";
		my @e = &glpXNextEvent();
		# print "EVENT $e[0] $e[1] $e[2] !!!\n";
		if($e[0] == &ConfigureNotify) {
			$this->resize($e[1],$e[2]);
		} 
		$this->event($time,@e);
	}
	$this->finish_event();
	$this->{Viewer}->handle_tick($time);

	$this->render();

}

sub set_root { $_[0]{Root} = $_[1] }

sub bind_viewpoint {
	my($this,$node,$bind_info) = @_;
	$this->{Viewer}->bind_viewpoint($node,$bind_info);
}

sub unbind_viewpoint {
	my($this, $node) = @_;
	return $this->{Viewer}->unbind_viewpoint($node);
}

sub bind_navi_info {
	my($this,$node) = @_;
	$this->{Viewer}->bind_navi_info($node);
	my $t = ref $this->{Viewer};
	$t =~ /^VRML::Viewer::(\w+)/ or die("Invalid viewer");
	$this->choose_viewer($1);
}

sub choose_viewer {
	my($this,$viewer) = @_;
	my $vs = [];
	if($this->{Viewer}{Navi}) {
		$vs = $this->{Viewer}{Navi}{RFields}{"type"};
	}
	if(!@$vs) {
		if($viewer) {
			$this->set_viewer($viewer);
		} else {
			$this->set_viewer("WALK");
		}
		return;
	} 
	if(grep {(lc $_) eq (lc $viewer)} @$vs) {
		$this->set_viewer($viewer);
		return;
	}
	$this->set_viewer($vs->[0]);
}
	
sub set_viewer {
	my($this,$viewer) = @_;
	$viewer = ucfirst lc $viewer;
	print "Setting viewing mode '$viewer'\n";
	$this->{Viewer} = "VRML::Viewer::$viewer"->new($this->{Viewer});
}

sub event {
	my $w;
	my($this,$time,$type,@args) = @_;
	my $code;
	my $but;
	# print "EVENT $this $type $args[0] $args[1] $args[2]\n";
	if($type == &MotionNotify) {
		my $but;
		# print "MOT!\n";
		if($args[0] & (&Button1Mask)) {
			$but = 1;
		} elsif ($args[0] & (&Button2Mask)) {
			$but = 2;
		} elsif ($args[0] & (&Button3Mask)) {
			$but = 3;
		}
		# print "BUT: $but\n";
		$this->{MX} = $args[1]; $this->{MY} = $args[2];
		$this->{BUT} = $but;
		$this->{SENSMOVE} = 1;
		push @{$this->{BUTEV}}, [MOVE, undef, $args[1], $args[2]];
		undef $this->{EDone} if ($but > 0);
	} elsif($type == &ButtonPress) {
		# print "BP!\n";
		if($args[0] == (&Button1)) {
			$but = 1;
		} elsif($args[0] == (&Button2)) {
			$but = 2;
		} elsif ($args[0] == (&Button3)) {
			$but = 3;
		}
		$this->{MX} = $args[1]; $this->{MY} = $args[2];
		my $x = $args[1]/$this->{W}; my $y = $args[2]/$this->{H};
		if($but == 1 or $but == 3) {
			# print "BPRESS $but $x $y\n";
			$this->{Viewer}->handle("PRESS",$but,$x,$y,
				$args[5] & &ShiftMask,
				$args[5] & &ControlMask);
		}
		push @{$this->{BUTEV}}, [PRESS, $but, $args[1], $args[2]];
		$this->{BUT} = $but;
		$this->{SENSBUT} = $but;
		undef $this->{EDone};
	} elsif($type == &ButtonRelease) {
		if($args[0] == (&Button1)) {
			$but = 1;
		} elsif($args[0] == (&Button2)) {
			$but = 2;
		} elsif ($args[0] == (&Button3)) {
			$but = 3;
		}
		push @{$this->{BUTEV}}, [RELEASE, $but, $args[1], $args[2]];
		$this->finish_event;
		$this->{Viewer}->handle("RELEASE",$but,0,0);
		$this->{SENSBUTREL} = $but;
		undef $this->{BUT};
	} elsif($type == &KeyPress) {
		# print "KEY: $args[0] $args[1] $args[2] $args[3]\n";
		if((lc $args[0]) eq "e") {
			$this->{Viewer} = VRML::Viewer::Examine->new($this->{Viewer});
		} elsif((lc $args[0]) eq "w") {
			$this->{Viewer} = VRML::Viewer::Walk->new($this->{Viewer});
		} elsif((lc $args[0]) eq "d") {
			$this->{Viewer} = VRML::Viewer::Fly->new($this->{Viewer});
		} elsif((lc $args[0]) eq "/") {
			my $tr = join ', ',@{$this->{Viewer}{Pos}};
			my $rot = join ', ',@{$this->{Viewer}{Quat}->to_vrmlrot()};
			print "Viewpoint: [$tr], [$rot]\n";
		} elsif((lc $args[0]) eq "q") {
			$this->{QuitPressed} = 1;
		} elsif((lc $args[0]) eq "v") {
			print "NEXT VP\n";
			if($this->{VPSub}) {$this->{VPSub}->(1)}
			else {die("No VPSUB");}
		} elsif((lc $args[0]) eq "b") {
			print "PREV VP\n";
			if($this->{VPSub}) {$this->{VPSub}->(-1)}
			else {die("No VPSUB");}
		} elsif(!$this->{Viewer}->use_keys) {
			if((lc $args[0]) eq "k") {
				$this->{Viewer}->handle("PRESS", 1, 0.5, 0.5);
				$this->{Viewer}->handle("DRAG", 1, 0.5, 0.4);
			} elsif((lc $args[0]) eq "j") {
				$this->{Viewer}->handle("PRESS", 1, 0.5, 0.5);
				$this->{Viewer}->handle("DRAG", 1, 0.5, 0.6);
			} elsif((lc $args[0]) eq "l") {
				$this->{Viewer}->handle("PRESS", 1, 0.5, 0.5);
				$this->{Viewer}->handle("DRAG", 1, 0.6, 0.5);
			} elsif((lc $args[0]) eq "h") {
				$this->{Viewer}->handle("PRESS", 1, 0.5, 0.5);
				$this->{Viewer}->handle("DRAG", 1, 0.4, 0.5);
			}
		} else {
			$this->{Viewer}->handle_key($time,$args[0]);
		}
	} elsif($type == &KeyRelease) {
		if($this->{Viewer}->use_keys) {
			$this->{Viewer}->handle_keyrelease($time,$args[0]);
		}
	}
}
	
sub finish_event {
	my($this) = @_;
	return if $this->{EDone};
	my $x = $this->{MX} / $this->{W}; my $y = $this->{MY} / $this->{H};
	my $but = $this->{BUT};
	if($but == 1 or $but == 3) {
		$this->{Viewer}->handle("DRAG", $but, $x, $y);
		# print "FE: $but $x $y\n";
	} elsif($but == 2) {
		$this->{MCLICK} = 1;
		$this->{MCLICKO} = 1;
		$this->{MOX} = $this->{MX}; $this->{MOY} = $this->{MY}
	}
	$this->{EDone} = 1;
}

sub resize { # Called by resizehandler.
	my($t,$w,$h) = @_;
	print "RESIZE: $w $h\n" if $VRML::verbose::be;
	$t->{W} = $w;
	$t->{H} = $h;
}

sub new_node {
	my($this,$type,$fields) = @_;
	# print "NEW_NODE $type\n";
	my $node = {
		Type => $type,
		CNode => VRML::CU::alloc_struct_be($type),
	}; 
	$this->set_fields($node,$fields);
	return $node;
}

sub set_fields {
	my($this,$node,$fields) = @_;
	for(keys %$fields) {
		my $value = $fields->{$_};
		# if("HASH" eq ref $value) { # Field
		# 	$value = $value->{CNode};
		# } elsif("ARRAY" eq ref $value and "HASH" eq ref $value->[0]) {
		# 	$value = [map {$_->{CNode}} @$value];
		# }
		VRML::CU::set_field_be($node->{CNode}, 
			$node->{Type}, $_, $fields->{$_});
	}
}

sub set_sensitive {
	my($this,$node,$sub) = @_;
	print "BE SET SENS $node $node->{TypeName} $sub\n" if $VRML::verbose::glsens;
	push @{$this->{Sens}}, [$node, $sub];
	$this->{SensC}{$node->{CNode}} = $node;
	$this->{SensR}{$node->{CNode}} = $sub;
}

sub delete_node {
	my($this,$node) = @_;
	VRML::CU::free_struct_be($node->{CNode}, $node->{Type});
}

sub get_proximitysensor_stuff {
	my($this,$node) = @_;
	my($hit, $x1, $y1, $z1, $x2, $y2, $z2, $q2);
	VRML::VRMLFunc::get_proximitysensor_vecs($node->{CNode},$hit,$x1,$y1,$z1,$x2,$y2,$z2,$q2);
	if($hit or !$hit) {
		return [$hit, [$x1, $y1, $z1], [$x2, $y2, $z2, $q2]];
	} else {
		return [$hit];
	}
}

sub setup_projection {
	my($this,$pick,$x,$y) = @_;
	my $i = pack ("i",0);
		glMatrixMode(&GL_PROJECTION);
	glGetIntegerv(&GL_PROJECTION_STACK_DEPTH,$i);
	my $dep = unpack("i",$i);
	while($dep-- > 1) { glPopMatrix(); }

		glViewport(0,0,$this->{W},$this->{H});
		glLoadIdentity();
	# print "SVP: $this->{W} $this->{H}\n";
		if($pick) { # We are picking for mouse events ..
			my $vp = pack("i4",0,0,0,0);
			glGetIntegerv(&GL_VIEWPORT, $vp);
			# print "VPORT: ",(join ",",unpack"i*",$vp),"\n";
			# print "PM: $this->{MX} $this->{MY} 3 3\n";
			my @vp = unpack("i*",$vp);
			print "Pick",
			 (join ', ',$this->{MX}, $vp[3]-$this->{MY}, 3, 3, @vp),
			 "\n"
			  if $VRML::verbose::glsens;
			glupPickMatrix($x, $vp[3]-$y, 3, 3, @vp);
		}
		glPushMatrix();
		gluPerspective(40.0, $this->{W}/$this->{H},	
			0.1, 200000);
		glHint(&GL_PERSPECTIVE_CORRECTION_HINT,&GL_NICEST);
		glMatrixMode(&GL_MODELVIEW);
		glLoadIdentity();
		# glShadeModel(GL_SMOOTH);
}

# sub unsetup_projection {
# 	glMatrixMode(&GL_PROJECTION);
# 	glPopMatrix();
# 	glMatrixMode(&GL_MODELVIEW);
# }

sub setup_viewpoint {
	my($this,$node) = @_;
	my $viewpoint = 0;
		$this->{Viewer}->togl(); # Make viewpoint
	     # Store stack depth
		my $i = pack ("i",0);
		glGetIntegerv(&GL_MODELVIEW_STACK_DEPTH,$i);
		my $dep = unpack("i",$i);
	     # Go through the scene, rendering all transforms
	     # in reverse until we hit the viewpoint
	     # die "NOVP" if !$viewpoint;
		glMatrixMode(&GL_MODELVIEW);
	         VRML::VRMLFunc::render_hier($node,
		 		1, 1, 0, 0, 0, $viewpoint);
		my $i2 = pack ("i",0);
		glGetIntegerv(&GL_MODELVIEW_STACK_DEPTH,$i2);
		my $depnow = unpack("i",$i2);
#		print "DEP: $dep $depnow\n";
		if($depnow > $dep) {
			my $mod = pack ("d16",0,0,0,0,0,0,0,0,0,0,0,0);
			glGetDoublev(&GL_MODELVIEW_MATRIX, $mod);
			while($depnow-- > $dep) {
				# print "POP!\n";
				glPopMatrix();
			}
			glLoadIdentity();
			glMultMatrixd($mod);
		}
}

# Given root node of scene, render it all
sub render {
	my($this) = @_;
	my($node,$viewpoint) = @{$this}{Root, Viewpoint};
	$node = $node->{CNode};
	$viewpoint = $viewpoint->{CNode};
	if($VRML::verbose::be) {print "Render: root $node\n";}
	glDisable(&GL_LIGHT0); # /* Put them all off first */
	glDisable(&GL_LIGHT1);
	glDisable(&GL_LIGHT2);
	glDisable(&GL_LIGHT3);
	glDisable(&GL_LIGHT4);
	glDisable(&GL_LIGHT5);
	glDisable(&GL_LIGHT6);
	glDisable(&GL_LIGHT7);
	glClear(&GL_COLOR_BUFFER_BIT | &GL_DEPTH_BUFFER_BIT);
	my $pick;
	# 1. Set up projection
		$this->setup_projection();
	# 2. Headlight
	     # Headlight - make conditional
		glEnable(&GL_LIGHT0);
		my $pos = pack ("f*",0,0,1,0);
		glLightfv(&GL_LIGHT0,&GL_POSITION, $pos);
		my $s = pack ("f*", 1,1,1,1);
		glLightfv(&GL_LIGHT0,&GL_AMBIENT, $s);
		glLightfv(&GL_LIGHT0,&GL_DIFFUSE, $s);
		glLightfv(&GL_LIGHT0,&GL_SPECULAR, $s);
				
	     # render_hier
	# 3. Viewpoint
		$this->setup_viewpoint($node);
        # Other lights
	     	VRML::VRMLFunc::render_hier($node,
				0,0,0,1,0,0);
	# 4. Nodes
		VRML::VRMLFunc::render_hier($node,
				0, 0, 1, 0, 0, 0);
	# glFlush();
	glXSwapBuffers();

	# Do selection
	if(@{$this->{Sens}}) {
		# print "SENS: $this->{MOUSEGRABBED}\n";
		# my $b = delete $this->{SENSBUT};
		# my $sb = delete $this->{SENSBUTREL};
		# my $m = delete $this->{SENSMOVE};
		print "SENSING\n"
			if $VRML::verbose::glsens;
	   for(my $i = 1; $i < scalar @{$this->{BUTEV}}; $i ++) {
	   	if($this->{BUTEV}[$i-1][0] eq "MOVE" and
		   $this->{BUTEV}[$i][0] eq "MOVE") {
		   	splice @{$this->{BUTEV}}, $i-1, 1;
			$i --;
		}
	   }
	   for(@{$this->{BUTEV}}) {
	   	print "BUTEV: $_->[0]\n" 
			if $VRML::verbose::glsens;
		for(@{$this->{Sens}}) {
			VRML::VRMLFunc::zero_hits($_->[0]{CNode});
			VRML::VRMLFunc::set_sensitive($_->[0]{CNode},1);
		}
		if($this->{MOUSEGRABBED}) {
			VRML::VRMLFunc::set_hypersensitive($this->{MOUSEGRABBED});
		} else {
			VRML::VRMLFunc::set_hypersensitive(0);
		}
		my $nints = 100;
		my $s = pack("i$nints");
		glRenderMode(&GL_SELECT);
		$this->setup_projection();
		glSelectBuffer($nints, $s);
		$this->setup_projection(1, $_->[2], $_->[3]);
		$this->setup_viewpoint($node);
		VRML::VRMLFunc::render_hier($node,
				0, 0, 0, 0, 1, 0);
		# print "SENS_BR: $b\n" if $VRML::verbose::glsens;
		my($x,$y,$z,$nx,$ny,$nz,$tx,$ty);
		my $p = VRML::VRMLFunc::get_rayhit($x,$y,$z,$nx,$ny,$nz,$tx,$ty);
		if($this->{MOUSEGRABBED}) {
			if($_->[0] eq "RELEASE") {
				# XXX The position at release is garbage :(
				my $rout = $this->{SensR}{$this->{MOUSEGRABBED}};
				$pos = [$x,$y,$z];
				my $nor = [$nx,$ny,$nz];
				$rout->("RELEASE", 0, 1, $pos, $nor);
				undef $this->{MOUSEGRABBED}
			} elsif($_->[0] eq "MOVE") {
				my $over = ($this->{MOUSEGRABBED} == $p);
				my $rout = $this->{SensR}{$this->{MOUSEGRABBED}};
				$pos = [$x,$y,$z];
				my $nor = [$nx,$ny,$nz];
				$rout->("",1,$over,$pos,$nor);
				if(!VRML::VRMLFunc::get_hyperhit(
					$x,$y,$z,$nx,$ny,$nz)) {
						die("No hyperhit??? REPORT BUG!");
				}
				print "HYP: $x $y $z $nx $ny $nz\n" 
					if $VRML::verbose::glsens;
				my $rout = $this->{SensR}{$this->{MOUSEGRABBED}};
				$pos = [$x,$y,$z];
				$nor = [$nx,$ny,$nz];
				$rout->("DRAG", 1, $over, $pos, $nor);
			}
		} else {
			if(defined $this->{SensC}{$p}) {
				my $rout = $this->{SensR}{$p};
				print "HIT: $p, $x $y $z\n"
					if $VRML::verbose::glsens;
				$pos = [$x,$y,$z];
				my $nor = [$nx,$ny,$nz];
				if($_->[0] eq "MOVE") {
					$rout->("",1,1,$pos,$nor);
				}
				if($_->[0] eq "PRESS") {
					$rout->("PRESS",0,1,$pos,$nor);
					$this->{MOUSEGRABBED} = $p;
				}
				# if($sb) {
				# 	$rout->("RELEASE",0,1,$pos,$nor);
				# }
			} else {
				print "No hit: $p\n"
					if $VRML::verbose::glsens;
			}
			print "MOUSOVER: $this->{MOUSOVER}, p: $p\n"
				if $VRML::verbose::glsens;
			if(defined $this->{MOUSOVER} and
			   $this->{MOUSOVER} != $p and
			   defined($this->{SensC}{$this->{MOUSOVER}})) {
			   	my $rout = $this->{SensR}{$this->{MOUSOVER}};
				$rout->("",1,0,undef,undef);
			}
			$this->{MOUSOVER} = $p;
		} 
	   }
	}
	$#{$this->{BUTEV}} = -1;
	glRenderMode(&GL_RENDER);
}




1;
