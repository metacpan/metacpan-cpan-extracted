package Gtk::GLArea::Glut;

# Glut, as made possible by Perl/Gtk, with the cooperation of GtkGLArea. 
#
# The interface is intended to be identical to that used by Perl/OpenGL, and
# in fact Perl/OpenGL is required, to supply the fonts and teapots.

# Early Alpha version, plenty of stuff not supported yet

use OpenGL qw(:glutconstants
	glutSolidSphere
	glutWireSphere
	glutSolidCone
	glutWireCone
	glutSolidCube
	glutWireCube
	glutSolidTorus
	glutWireTorus
	glutSolidTeapot
	glutWireTeapot
);
use Gtk::GLArea::Constants;

require Exporter;
require Gtk;

@ISA = qw(Exporter);

@glut_func = qw(
	glutInitWindowSize
	glutInitWindowPosition
	glutInitDisplayMode
	glutInit
	glutCreateWindow
	glutCreateSubWindow
	glutMainLoop
	glutDisplayFunc
	glutReshapeFunc
	glutVisibilityFunc
	glutIdleFunc
	glutGet
	glutSwapBuffers
	glutPostRedisplay
	glutCreateMenu
	glutGetMenu
	glutSetMenu
	glutGetWindow
	glutSetWindow
	glutDestroyMenu
	glutAddMenuEntry
	glutAddSubMenu
	glutChangeToMenuEntry
	glutChangeToSubMenu
	glutRemoveMenuItem
	glutAttachMenu
	glutDetachMenu
	glutMenuStateFunc

	
	glutSolidSphere
	glutWireSphere
	glutSolidCone
	glutWireCone
	glutSolidCube
	glutWireCube
	glutSolidTorus
	glutWireTorus
	glutSolidTeapot
	glotWireTeapot
);

@EXPORT = qw();

@EXPORT_OK = (@glut_func, @OpenGL::glut_const);

%EXPORT_TAGS = ('all' => \@EXPORT_OK, 'functions' => \@glut_func, 'constants' => \@OpenGL::glut_const);

$id=0;

sub _NewWindowID {
	return ++$id;
}

$mid=0;

sub _NewMenuID {
	return ++$mid;
}


@window = ();
@menu = ();
$current = undef;
$currentgl = undef;
$currentmenu = undef;
$popupwindow = undef;
$idle = undef;
$idlecb = undef;

@initialSize = (300, 30);
@initialPos = (-1, -1);
$initialMode = ( GLUT_RGB | GLUT_SINGLE | GLUT_DEPTH );

sub glutInitWindowSize ($$) {
	@initialSize = @_;
}

sub glutInitWindowPosition ($$) {
	@initialPos= @_;
}

sub glutInitDisplayMode ($) {
	$initialMode = $_[0];
}

sub glutInit () {
	OpenGL::glutInit();
}

sub _draw {
	my($g) = $_[0];

	$currentgl->endgl if defined $currentgl;

	local($current,$currentgl) = ($g->{data}, $g);
	$currentgl->begingl;
	_invoke($current->{display});

}

sub _idle {

	return _invoke($idle);
}

sub _timer {

	return _invoke($_[0]);
}

sub _key {

}

sub _visible {
}


sub _invoke {
	my($s, @args) = @_;
	if (not defined $s) {
		return 0;
	}
	my(@a) = @$s;
	$s = shift @a;
	if (defined $s) {
		if (defined ref $s and ref $s ne "CODE") {
			my($method) = shift @args;
			$s->$method(@a, @args);
		} else {
			&{$s}(@a, @args);
		}
		return 1;
	} else {
		return 0;
	}
}

sub _button {
	my($g,$e) = @_;
	
	$currentgl->endgl if defined $currentgl;

	local($current,$currentgl) = ($g->{data}, $g);
	$currentgl->begingl;
	
	my($i) = $current->{menu}->[$e->{button}];
	
	return if not defined $i or not defined $menu[$i];
	
	$m = _generateMenu($menu[$i]);
	
	$popupwindow = $current;

	_invoke($current->{menustate}, 1);
	
	$m->popup(undef, undef, $e->{'button'}, $e->{'time'});
}	

sub _menu {
	my($widget,$menu,$value) = @_;

	$currentgl->endgl if defined $currentgl;
	
	$currentmenu = $menu;

	local($current,$currentgl) = ($popupwindow, $popupwindow->{glarea});
	$currentgl->begingl;
	
	&{$menu->{callback}->[0]}($value);
}

sub glutCreateWindow ($) {
	my($title) = @_;
	
	my($w) = (new Gtk::Window -toplevel);
	
	$w->set_title($title);
	$w->set_policy(1, 1, 0);
	#$w->set_usize(@initialSize) if @initialSize and $initialSize[0]>0 and $initialSize[1]>0;
	#$w->set_uposition(@initialPos) if @initialPos and $initialPos[0]>0 and $initialPos[1]>0;
	$w->set_default_size(100, 100);

	my($f) = new Gtk::Fixed;
	
	#show $f;
	
	$w->add($f);
	
	my($g) = new Gtk::DrawingArea; # _glut_init($initialMode);
	$g->set_events([-exposure_mask, -button_press_mask, -key_press_mask, -pointer_motion_mask, -pointer_motion_hint_mask]);

	use Data::Dumper;

	$f->set_usize(40,40); #@initialSize) if @initialSize and $initialSize[0]>0 and $initialSize[1]>0;
	
	$f->put($g, 0, 0);
	
	
	$w->signal_connect("configure_event" => sub {
		my($widget,$e) = @_;
		use Data::Dumper;
		print Dumper($e);
		if ($e->{width} > 0 and $e->{height} > 0) {
			$g->set_usize($e->{width}, $e->{height});
		}
	});

	$g->signal_connect("size_allocate" => sub {
		print "size_allocate: ", Dumper($_[1]);
		#$g->set_usize($_[1]->[2], $_[1]->[3]);
	});

#	$g->signal_connect("expose_event" => \&_draw);
	$g->signal_connect("visibility_notify_event" => \&_visible);
	$g->signal_connect("button_press_event" => \&_button);
	$g->signal_connect("key_press_event" => \&_key);

	$g->signal_connect("map" => sub { 
		if (!$g->{data}->{visible}) {
			_invoke($g->{visibility}, 1);
			$g->{data}->{visible} = 1;
		}
	});

	$g->signal_connect("unmap" => sub { 
		if ($g->{data}->{visible}) {
			_invoke($g->{visibility}, 0);
			$g->{data}->{visible} = 0;
		}
	});

	$g->{window} = $w;
	
	#show $g;
	
	show_all $w;

#	$g->can_focus(1);
#	$g->grab_focus();

	my($id) = _NewWindowID();
	
	$window[$id] = { "window" => $w, "parent" => undef, "id" => $id, "fixed" => $f, "glarea" => $g,
					"display" => undef, "toplevel" => 1 };

	$g->{data} = $window[$id];
	
	$current = $window[$id];
	
#	$g->begingl;
	
	return $id;
}

sub glutCreateSubWindow ($$$$$) {
	my($parentID, $x, $y, $w, $h) = @_;
	
	my($id) = _NewWindowID();
	
	my($f) = new Gtk::Fixed;
	$f->set_usize($w, $h);
	show $f;
	
	$window[$parentID]->{fixed}->put($f, $x, $y);
	

	my($g) = _glut_init($initialMode);
	$g->set_events([-exposure_mask, -button_press_mask, -key_press_mask, -pointer_motion_mask, -pointer_motion_hint_mask]);

#	$g->signal_connect("expose_event" => \&_draw);
	$g->signal_connect("visibility_notify_event" => \&_visible);
	$g->signal_connect("button_press_event" => \&_button);
	$g->signal_connect("key_press_event" => \&_key);
	
	
	$window[$id] = { "parent" => $window[$parentID], "id" => $id, "glarea" => $g, "window" => $window[$parentID]->{window}, "fixed" => $f,
					"toplevel" => 0, "visible" => 0};

	$g->signal_connect("map" => sub { 
		if (!$g->{data}->{visible}) {
			_invoke($g->{visibility}, 1);
			$g->{data}->{visible} = 1;
		}
	});

	$g->signal_connect("unmap" => sub { 
		if ($g->{data}->{visible}) {
			_invoke($g->{visibility}, 0);
			$g->{data}->{visible} = 0;
		}
	});
	
	push @{$window[$parentID]->{children}}, $id;

	$g->{data} = $window[$id];
	
	$g->set_usize($w, $h);
	
	show $g;

	$f->put($g, 0, 0);
	
	$current = $window[$id];
	
	$g->begingl;
	
	return $id;
}

sub glutDestroyWindow ($) {
	my($id) = @_;
	
	my($w) = $window[$id];
	
	$w->{window}->hide;
	
	if (defined $w->{parent}) {
		@{$w->{parent}->{children}} = grep {$_ != $id} @{$w->{parent}->{children}};
	}
	
	my(@children) = @{$w->{children}};
	
	foreach (@children) {
		glutDestroyWindow($_);
	}
	
	$window[$id] = undef;
}

sub glutGetWindow () {
	return $current->{id};
}

sub glutSetWindow ($) {
	my($id) = $_[0];
	
	$current = $window[$id];
	$currentgl = $current->{glarea};
}

sub glutShowWindow {
	$current->{window}->show;
}

sub glutHideWindow {
	$current->{window}->hide;
}

sub glutDisplayFunc (@) {

	$current->{display} = [@_];
}

sub glutReshapeFunc (@) {
	
	$current->{reshape} = [@_];
	
	if (@_ and defined $_[0]) {
		if (!defined $g->{reshapeID}) {
			$current->{reshapeID} = $current->{glarea}->signal_connect("configure_event" => sub {
				my($g) = $_[0];

				$currentgl->endgl if defined $currentgl;

				local($current,$currentgl) = ($g->{data}, $g);
				$currentgl->begingl;

				my($a) = $g->allocation;
				if (_invoke($current->{reshape}, $a->[2], $a->[3])) {
					glutPostRedisplay();
				}
			
			});
		}
	} else {
		if (defined $g->{reshapeID}) {
			$current->{glarea}->signal_disconnect($current->{reshapeID});
			delete $current->{reshapeID};
		}
	}

}

sub glutVisibilityFunc (@) {
	# This doesn't work as you'd expect, unfortunately.
	$current->{visible} = [@_];
}

sub glutKeyboardFunc (@) {
	$current->{keyboard} = [@_];
}

sub glutMenuStateFunc (@) {
	$current->{menustate} = [@_];
}

sub glutIdleFunc (@) {
	$idle = [@_];
	if (defined $idlecb) {
		Gtk->idle_remove($idlecb);
		$idlecb = undef;
	}
	if (@_) {
		$idlecb = Gtk->idle_add(\&_idle);
	}
}

sub glutTimerFunc ($@) {
	my($msec, @handler) = @_;
	Gtk->timeout_add($msec, \&_timer, \@handler);
}

sub glutMainLoop {
	Gtk->main();
}

sub glutGet ($) {
	my($x) = $_[0];
	
	if ($x == GLUT_WINDOW_WIDTH) {
		my($a) = $current->{glarea}->allocation;
		return $a->[2];
	}
	elsif ($x == GLUT_WINDOW_HEIGHT) {
		my($a) = $current->{glarea}->allocation;
		return $a->[3];
	}
	else {
		return OpenGL::glutGet($x);
	}
}

sub glutSwapBuffers () {
	$current->{glarea}->swapbuffers();
}

sub glutPostRedisplay () {
	$current->{glarea}->queue_draw();
}

sub glutCreateMenu (@) {
	my($m) = { "callback" => [@_], "id" => _NewMenuID() };
	$menu[$m->{id}] = $m;
	
	$currentmenu = $m;
	
	return $m->{id};
}

sub glutGetMenu () {
	return $currentmenu->{id};
}

sub glutSetMenu ($) {
	my($id) = @_;
	
	$currentmenu = $menu[$id];
}

sub glutDestroyMenu ($) {
	$menu[$id] = undef;
	
	if ($currentmenu->{id} == $id) {
		if (defined $currentmenu->{generated}) {
			$currentmenu->{generate}->destroy;
		}
		$currentmenu = undef;
	}
}

sub glutAddMenuEntry ($$) {
	my($label, $value) = @_;
	push @{$currentmenu->{entries}}, [1, $label, $value];
	
	$currentmenu->{regenerate}=1;
}

sub glutAddSubMenu ($$) {
	my($label, $submenu) = @_;
	push @{$currentmenu->{entries}}, [2, $label, $submenuid];

	$currentmenu->{regenerate}=1;
}

sub glutChangeToMenuEntry ($$$) {
	my($item, $label, $value) = @_;
	$currentmenu->{entries}->[$item] = [1, $label, $value];

	$currentmenu->{regenerate}=1;
}

sub glutChangeToSubMenu ($$$) {
	my($item, $label, $submenu) = @_;
	$currentmenu->{entries}->[$item] = [2, $label, $submenu];

	$currentmenu->{regenerate}=1;
}

sub glutRemoveMenuItem ($) {
	my($item) = @_;
	splice @{$currentmenu->{entries}}, $item, 1;

	$currentmenu->{regenerate}=1;
}

sub _regenerateMenu {
	my($m) = $_[0];
	
	if ($m->{regenerate} or !$m->{generated}) {
		return 1;
	}

	foreach (@{$m->{entries}}) {
		if ($_->[0] == 2 and $menu[$_->[2]]) {
			if (_regenerateMenu($menu[$_->[2]])) {
				return 1;
			}
		}
	}
	
	return 0;
}

sub _generateMenu {
	my($m) = @_;
	
	if (!_regenerateMenu($m)) {
		return $m->{generated};
	}

	if ($m->{generated}) {
		$m->{generated}->popdown;
		#destroy $m->{generated};
		$m->{generated} = undef;
		# Let it get garbage collected
	}

	my($menu) = new Gtk::Menu;
	
	foreach (@{$m->{entries}}) {
		if ($_->[0] == 1) {
			my($i) = new Gtk::MenuItem $_->[1];
			$i->signal_connect("activate" => \&_menu, $m, $_->[2]);
			show $i;
			$menu->append($i);
		} elsif ($_->[0] == 2) {
			my($i) = new Gtk::MenuItem $_->[1];
			$i->set_submenu(_generateMenu($menu[$_->[2]]));
			show $i;
			$menu->append($i);
		}
	}

	$menu->signal_connect("deactivate" => sub { _invoke($current->{menustate}, 0); } );

	$m->{generated} = $menu;
	$m->{regenerate} = 0;
	
	return $menu;
}

sub glutAttachMenu ($) {
	my($button) = @_;
	
	$current->{menu}->[$button] = $currentmenu->{id};
}

sub glutDetachMenu ($) {
	my($button) = @_;
	
	$current->{menu}->[$button] = undef;
}

sub glutPushWindow () {
	
	$current->{window}->window->lower();
}


sub glutPopWindow () {
	
	$current->{window}->window->raise();
}

sub _glut_init {
	my($mode) = @_;
	my(@i);
	my($g);
	
	if (($mode & GLUT_INDEX) != GLUT_INDEX) {
	
		push @i, GDK_GL_RGBA, GDK_GL_RED_SIZE, 1, GDK_GL_GREEN_SIZE, 1, GDK_GL_BLUE_SIZE, 1;

		if (($mode & GLUT_ALPHA) == GLUT_ALPHA) {
			push @i, GDK_GL_ALPHA_SIZE, 1;
		}

		if (($mode & GLUT_DOUBLE) == GLUT_DOUBLE) {
			push @i, GDK_GL_DOUBLEBUFFER;
		}

		if (($mode & GLUT_STEREO) == GLUT_STEREO) {
			push @i, GDK_GL_STEREO;
		}

		if (($mode & GLUT_DEPTH) == GLUT_DEPTH) {
			push @i, GDK_GL_DEPTH_SIZE, 1;
		}

		if (($mode & GLUT_STENCIL) == GLUT_STENCIL) {
			push @i, GDK_GL_STENCIL_SIZE, 1;
		}

		if (($mode & GLUT_ACCUM) == GLUT_ACCUM) {
			push @i, GDK_GL_ACCUM_RED_SIZE, 1;
			push @i, GDK_GL_ACCUM_GREEN_SIZE, 1;
			push @i, GDK_GL_ACCUM_BLUE_SIZE, 1;

			if (($mode & GLUT_ALPHA) == GLUT_ALPHA) {
				push @i, GDK_GL_ACCUM_ALPHA_SIZE, 1;
			}
		}

		return new Gtk::GLArea @i;
	
	} else {
	
		push @i, GDK_GL_BUFFER_SIZE, 1;

		if (($mode & GLUT_DOUBLE) == GLUT_DOUBLE) {
			push @i, GDK_GL_DOUBLEBUFFER;
		}

		if (($mode & GLUT_STEREO) == GLUT_STEREO) {
			push @i, GDK_GL_STEREO;
		}

		if (($mode & GLUT_DEPTH) == GLUT_DEPTH) {
			push @i, GDK_GL_DEPTH_SIZE, 1;
		}

		if (($mode & GLUT_STENCIL) == GLUT_STENCIL) {
			push @i, GDK_GL_STENCIL_SIZE, 1;
		}
	
		foreach (16, 12, 8, 4, 2, 1, 0) {
			$i[1] = $_;
			
			$g = new Gtk::GLArea @i;
			
			return $g if defined $g;
		}
	}
	
	return undef;
}

1;
