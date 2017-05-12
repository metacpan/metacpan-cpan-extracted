#!/usr/bin/perl -w
# Copyright 1998 Paolo Molaro <lupus@debian.org>
# This is GPL'ed code.

# TITLE: Slide
# REQUIRES: Gtk GkdImlib

use Gtk;
use Gtk::Gdk::ImlibImage;
use Gtk::Keysyms;
use Getopt::Std;

sub update_all;
sub do_page;

$opt_w = 640;
$opt_h = 480;

getopts('w:h:d:');

init Gtk;
init Gtk::Gdk::ImlibImage;

%images = ();
%fonts = ();

# get a window
$gtkwin = new Gtk::Window -toplevel;
$gtkwin->set("GtkWidget::app_paintable" => 1);
$gtkwin->set_events(['button_press_mask', 'key_press_mask']);
$width = $opt_w;
$height = $opt_h;
$gtkwin->set_usize($width, $height);
$gtkwin->set_uposition(0, 0);
$gtkwin->realize;
$gtkwin->set_policy(0, 0, 0);
$win = $gtkwin->window;
$win->set_decorations('border');

# Setup a backing pixmap and the GC to use when drawing
(undef, undef, undef, undef, $depth) = $win->get_geometry;
$bp = new Gtk::Gdk::Pixmap($win, $width, $height, $depth);
$gc = new Gtk::Gdk::GC ($win);
$colormap = $win->get_colormap;
$gc->set_foreground($colormap->color_white());
$bp->draw_rectangle($gc, 1, 0, 0, $width, $height);

# Events we care about
$gtkwin->signal_connect('button_press_event', sub {
	my ($w, $e)= @_;
	if ($e->{'button'} == 1) {Gtk->main_quit;}
	elsif ($e->{'button'} == 2) {Gtk->exit(0);}
	else {show_menu()}
	return 1;
});
$gtkwin->signal_connect('key_press_event', sub {
	my ($w, $e)= @_;
	# little test for Gtk::Keysyms
	print "Got control\n" if $e->{'keyval'} == $Gtk::Keysyms{'Control_L'};
	my ($c) = chr($e->{'keyval'});
	if ($c eq "n" || $c eq " ") {Gtk->main_quit;}
	elsif ($c eq "q") {Gtk->exit(0);}
	else {show_menu()}
	return 1;
});
$gtkwin->signal_connect('delete_event', sub {Gtk->exit(0);});
$gtkwin->signal_connect('expose_event', sub {
	my ($w, $e) = @_;
	my ($x, $y, $wi, $h) = @{$e->{'area'}};
	$win->draw_pixmap($gc, $bp, $x, $y, $x, $y, $wi, $h);
});

# preprocess slide data
$started = 0;
@data = ();
%slides =();
$i = 0;
while (<DATA>) {
	chomp;
	study;
	# remove whitespace and comments
	s/^\s+//;
	s/\s+$//;
	next if /^#/;	
	next if /^$/;
	if ( s"\\$"" ) { #"
		$_ .= <DATA>;
		redo;
	}
	push(@data, $_);
}

$i = 0;
@group = ();
%group = ();
$in_group = undef;
$xoffset = $width/20;

# execute the commands and wait for events
while($i < @data) {
	if ( $in_group ) {
		if ( $data[$i] =~ /^end/ ) {
			$in_group = undef;
			$i++;
		} else {
			push(@{$group{$in_group}}, $data[$i++]);
		}
		next;
	}
	if ( @group ) {
		$_ = shift(@group);
	} else {
		$_ = $data[$i++];
	}
	START:
	study;
	$fontsize = $font->ascent+$font->descent if defined $font;
	# parse (escapes, variable substitution)
	unless ( /^(eval|cmd)/ ) {
		s/\$(\w+)/${$1}/g;
		s/\\(.)/$1/g;
	}
	if (/^image\s+(\w+)\s+([^ \t]+)$/) {
		$images{$1} = load_image Gtk::Gdk::ImlibImage($2);
		if (!defined $images{$1}) {
			$images{$1} = create_image_from_data Gtk::Gdk::ImlibImage("\xff\x00\x00" x 9, undef, 3, 3);
		}
	} elsif (/^image\s+(\w+)\s+([clrn])\s+(\d+)\s+(\d+)$/) {
		my ($im) = $images{$1};
		my ($ip);
		if ( $2 eq 'c' ) {
			$curx = $width/2 - $3/2;
		} elsif ( $2 eq 'r' ) {
			$curx = $width - $xoffset - $3;
		} elsif ( $2 eq 'l' ) {
			$curx = $xoffset;
		}
		#$im->render($3, $4);
		#$ip = $im->move_image;
		#$bp->draw_pixmap($gc, $ip, 0, 0, $curx, $cury, $3, $4);
		$im->paste_image($bp, $curx, $cury, $3, $4);
		$cury += $4 + int($fontsize/2+.5) unless ($2 eq 'n');
		$curx += $3;
	} elsif (/^font\s*(\w+)\s+(.+)$/) {
		$fonts{$1} = [load Gtk::Gdk::Font($2), $2];
		if (!defined $fonts{$1}->[0]) {
			$fonts{$1} = [load Gtk::Gdk::Font("fixed"), "fixed"];
		}
		$font = $fonts{$1}->[0];
	} elsif (/^font\s*(\w+)$/) {
		$font = $fonts{$1}->[0];
	} elsif (/^fg\s*(.+)$/) {
		my ($c) = Gtk::Gdk::Color->parse_color($1);
		$c = $colormap->color_alloc($c);
		$gc->set_foreground($c);
	} elsif (/^bg\s*(.+)$/) {
		my ($c) = Gtk::Gdk::Color->parse_color($1);
		$c = $colormap->color_alloc($c);
		$gc->set_background($c);
	} elsif (/^evalx\s*(.+)/) {
		$_ = eval $1;
		if ( $@ ) {
			warn $@;
		} else {
			goto START;
		}
	} elsif (/^eval\s*(.+)/) {
		eval $1;
		warn $@ if $@;
	} elsif (/^define\s+(\w+)/) {
		$in_group = $1;
		$group{$in_group} = [];
	} elsif (/^cmd\s+(\w+)(\s+(.*))?/) {
		push(@group, @{$group{$1}});
		$arg = $3;
		eval $3;
		warn $@ if $@;
	} elsif (/^slide\s+(.+)?/) {
		$slides{$i - 1} = $1;
		$curx = $cury = 0;
		if ( !$started ) {
			$started = 1;
			$gtkwin->show;
		} else {
			update_all();
			do_page;
		}
		$gtkwin->set_title($1) if defined $1;
	} elsif (/^rect\s*([fe])\s+(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/) {
		$bp->draw_rectangle($gc, $1 eq 'f', $2, $3, $4, $5);
	} elsif (/^line\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)$/) {
		$bp->draw_line($gc, $1, $2, $3, $4);
	} elsif (/^skip\s*([+-]?\d+)\s+([+-]?\d+)$/) {
		$curx += $1;
		$cury += $2;
	} elsif (/^put\s*([clrn])\s+(.*)/) {
		$cury += $font->ascent + $font->descent unless ($1 eq 'n');
		my ($sw) = $font->string_width($2);
		if ( $1 eq 'c' ) {
			$curx = $width/2 - $sw/2;
		} elsif ( $1 eq 'r' ) {
			$curx = $width - $xoffset - $sw;
		} elsif ( $1 eq 'l' ) {
			$curx = $xoffset;
		}
		$bp->draw_string($font, $gc, $curx, $cury, $2);
		$curx += $sw+$font->string_width(" ");
	} elsif (/^puts\s*(\d+)\s+(\d+)\s+(.*)/) {
		$bp->draw_string($font, $gc, $1, $2, $3);
	} else {
		warn "Command not understood: $_\n"
	}
}

do_page;
Gtk->exit(0);

sub update_all {
	$win->draw_pixmap($gc, $bp, 0, 0, 0, 0, $width, $height);
}

sub do_page {
	$page = $i; # FIXME
	if ( defined $opt_d ) {
		print "Running convert ".  $win->XWINDOW . " to $opt_d\n";
		system("convert x:". $win->XWINDOW ." slide$page.$opt_d");
	}
	Gtk->main;
}

sub set_font {
	my ($w, $n) = @_;
	my ($fs) = new Gtk::FontSelectionDialog("Changing font: $n");
	$fs->set_font_name($fonts{$n}->[1]);
	$fs->cancel_button->signal_connect('clicked', sub {$fs->destroy});
	$fs->ok_button->signal_connect('clicked', sub {
		$fonts{$n} = [$fs->get_font, $fs->get_font_name];
		$fs->destroy
	});
	$fs->show;
}

sub get_fonts {
	my ($m, $mi, $i);
	$m = new Gtk::Menu;
	foreach $i (sort keys %fonts) {
		$mi = new Gtk::MenuItem($i);
		$mi->show;
		$m->append($mi);
		$mi->signal_connect('activate', \&set_font, $i);
	}
	return $m;
}
sub show_menu {
	my ($x, $y, $button) = @_;
	my ($m, $mi, $index);
	$m = new Gtk::Menu;
	$mi = new Gtk::MenuItem('Quit');
	$mi->show;
	$mi->signal_connect('activate', sub {Gtk->exit(0)});
	$m->append($mi);
	$mi = new Gtk::MenuItem('Fonts');
	$mi->show;
	$mi->set_submenu(get_fonts());
	$m->append($mi);
	$mi = new Gtk::MenuItem();
	$mi->show;
	$mi->set_sensitive(0);
	$m->append($mi);
	foreach $index ( sort {$a <=> $b} keys %slides) {
		$mi = new Gtk::MenuItem($slides{$index});
		$mi->show;
		$mi->signal_connect('activate', sub {
			$i = $index;
			$started = 0;
			Gtk->main_quit;
		});
		$m->append($mi);
	}
	$m->popup(undef, undef, 3, 0, undef);
}

__DATA__
################# load needed resources
eval	$fsize = int ($height*.6)
eval	$fssize = int ($height*.35)
eval	$fixedsize = int ($height*.3)
eval	$imsize = int ($height*.25)
# eval	$title = "Gtk+ e Perl"
image	tcl Xcamel.gif
image	bullet bullet.png
image	logo gtk-logo-rgb.gif
font	std -freefont-baskerville-bold-r-normal-*-*-$fsize-*-*-p-*-iso8859-1
font	small -freefont-baskerville-bold-r-normal-*-*-$fssize-*-*-p-*-iso8859-1
#font fixed -freefont-tekton-normal-r-normal-*-*-$fixedsize-*-*-p-*-iso8859-1
#font fixed -bitstream-terminal-medium-r-normal-*-*-$fixedsize-*-*-c-*-iso8859-1
#font	std		-bitstream-charter-*-*-*-*-*-$fsize-*-*-*-*-*-*
#font	small	-bitstream-charter-*-*-*-*-*-$fssize-*-*-*-*-*-*
font	fixed	-adobe-courier-*-*-*-*-*-$fixedsize-*-*-*-*-*-*
define	slide
	slide	$title
	fg		white
	rect	f 0 0 $width $height
	fg		black
	font	std
	put		c $title
	skip	0 $fontsize
	font	small
end
define comment
	fg black
	font small
end
define pcode
	fg red
	font fixed
end
define bullet
	image bullet l $fontsize $fontsize
	evalx "skip 0 -" . int($fontsize/2+.5)
	evalx $arg?"put n $arg":""
end
define tab
	eval $xoffset = int($width/20)*(defined $arg ? $arg : 1)
end
#########################################
cmd	slide $title = "Gtk+ e Perl"
image	logo c $imsize $imsize 
#put		l 
put		l Gtk+: una buona libreria grafica
put		l Perl: un linguaggio di programmazione flessibile
fg		steelblue
skip	0 $fontsize
put		l Rapid prototyping
put		l Sviluppo di piccole applicazioni
put		l Applicazioni "verticali"
put		l Scripting interattivo
skip	0 $fontsize
fg		red
font	fixed
put		r http://www.perl.org
put		r http://www.gtk.org
put		r http://www.gnome.org
########################################
cmd	slide	$title = "Come si compila Perl/Gtk"
put	l Le ultime versioni uscite sono:
put	l Gtk 0.3 (stabile)
put 	l Gtk 0.4 e Gnome 0.3 (in sviluppo)
skip	0 $fontsize
put 	l Le librerie richieste sono:
put 	l glib, gtk+, gdkimlib, gnome.
skip	0 $fontsize
fg	steelblue
font	fixed
put	l $ perl Makefile.PL --with-gnome --with-gdkimlib 
put	l $ make
put	l $ make test
put	l $ make install
# skip	0 $fontsize
#######################################
cmd	slide	$title = "I vantaggi (laziness)"
put 	l Sfrutta il design object oriented di gtk+,
put 	l quindi:
skip	0 $fontsize
cmd 	bullet  niente casting 
cmd 	bullet  codice più corto
skip	0 $fontsize
font 	fixed
fg	steelblue
put 	l button = gtk_button_new_with_label("Hello!");
put 	l gtk_container_add(GTK_CONTAINER(window), button);
skip	0 $fontsize
fg	black
put 	c diventa
skip	0 $fontsize
fg 	red
put 	l $\button = new Gtk::Button ("Hello!");
put 	l $\window->add($\button);
#####################################
cmd	slide	$title = "I vantaggi (impatience)"
put 	l Il modulo permette di usare riferimenti a subroutine
put 	l dove il codice C richiede il puntatore a una funzione
put 	l (callback) ed è possibile passare più argomenti senza
put 	l dover costruire una struttura apposta.
skip	0 $fontsize
font 	fixed
fg	steelblue
put 	l gtk_object_signal_connect(GTK_OBJECT(button),
put 	r "clicked", (GtkSignalFunc)gtk_main_quit, NULL);
skip	0 $fontsize
fg	black
put 	c diventa
skip	0 $fontsize
fg 	red
put 	l $\button->signal_connect("clicked", sub {Gtk->main_quit});
####################################
cmd	slide	$title = "I vantaggi (hubris)"
put 	l Si può anche mescolare codice C e codice perl e si possono
put 	l creare nuovi widget in perl che saranno accessibili anche
put 	l alla parte C del programma.
skip	0 $fontsize
font 	fixed
fg	red
put 	l package mywindow;
skip	0 $fontsize
put 	l @ISA = qw(Gtk::Window);
skip	0 $fontsize
put 	l sub new {
cmd 	tab 2
put 	l my($\class) = @_;
put 	l my($\self) = new Gtk::Window('toplevel');
put 	l $\self->set_title("a mywindow");
put 	l $\self->{"george"} = "bill";
put 	l bless $\self, $\class;
cmd 	tab
put 	l }
####################################
cmd	slide	$title = "Le differenze rispetto al C"
put 	c Namespace
skip	0 $fontsize
font 	fixed
fg	steelblue
put 	l gtk_
put 	l gdk_
put 	l gdk_imlib_
put 	l gnome_
put 	l gtk_object_
put 	l gdk_font_
fg 	red
evalx	"skip	0 -" . $fontsize*6
put 	r Gtk::
put 	r Gtk::Gdk::
put 	r Gtk::Gdk::ImlibImage::
put 	r Gtk::Gnome::
put 	r $\object->
put 	r $\font->
##################################
cmd	slide	$title = "Le differenze rispetto al C II"
put 	c Enumerazioni e flag
skip	0 $fontsize
font 	small
put 	l Al posto del valore di una enumerazione o di un flag
put 	l si usa rispettivamente una stringa e un riferimento ad
put 	l un array di stringhe.
skip	0 $fontsize
font 	fixed
fg	steelblue
put 	l GTK_WINDOW_TOPLEVEL
put 	l GDK_INPUT_READ|GDK_INPUT_WRITE
fg 	red
evalx	"skip	0 -" . $fontsize*2
put 	r "toplevel"
put 	r ['read', 'write']
skip	0 $fontsize
fg 	black
font 	small
put 	l Si può usare una stringa nel caso di un valore flag quando
put 	l questo è rappresentato da un solo item:
skip	0 $fontsize
font 	fixed
fg	steelblue
put 	l GDK_DECOR_BORDER
skip 	0 -$fontsize
fg 	red
put 	r "border"
#################################
cmd 	slide $title = "Passiamo agli esempi"
put 	l La creazione di una window: la differenza tra una
put 	l GdkWindow e una GtkWindow.
put 	l Quando serve "realizzare" o "costruire" una window.
skip 	0 $fontsize
font 	fixed
fg 	red
put 	l use Gtk;
skip 	0 $fontsize
put 	l init Gtk::Gdk::ImlibImage;
skip 	0 $fontsize
put 	l $\gtkwin = new Gtk::Window -toplevel;
put 	l $\gtkwin->set_events(['button_press_mask', 'key_press_mask']);
put 	l $\width = $\height = 400;
put 	l $\gtkwin->set_usize($\width, $\height);
put 	l $\gtkwin->set_policy(0, 0, 0);
put 	l $\gtkwin->realize;
put 	l $\win = $\gtkwin->window;
################################
cmd 	slide $title = "Colori, font e immagini"
put 	l Come si inizializzano i colori:
skip 	0 $fontsize
cmd 	pcode
put 	l Gtk::Gdk::Color->parse_color("steelblue");
put 	l $\color = $\colormap->color_alloc($\color);
put 	l $\gc->set_foreground($\color);
skip 	0 $fontsize
cmd 	comment
put 	l I font:
skip 	0 $fontsize
cmd 	pcode
put 	l load Gtk::Gdk::Font("fixed");
skip 	0 $fontsize
cmd 	comment
put 	l Le immagini con gdkimlib:
skip 	0 $fontsize
cmd 	pcode
put 	l $\image = load_image Gtk::Gdk::ImlibImage("logo.png");
put 	l $\im->render($\width, $\height);
put 	l $\ip = $\im->move_image;
put 	l $\bp->draw_pixmap($\gc, $\ip, 0, 0, $\x, $\y, $\width, $\height);
################################
cmd 	slide $title = "Preparare una backing pixmap"
put 	l E' una tecnica comunemente usata nella programmazione
put 	l nel sistema X Window: le operazioni di disegno vengono
put 	l eseguite su una pixmap (una immagine in memoria) e copiate
put 	l sulla finestra visibile sullo schermo solo quando è
put 	l necessario.
skip 	0 $fontsize
font 	fixed
fg 	red
put 	l	(undef, undef, undef, undef, $\depth) = $\win->get_geometry;
put 	l	$\bp = new Gtk::Gdk::Pixmap($\win, $\width, $\height, $\depth);
put 	l	$\gc = new Gtk::Gdk::GC ($\win);
put 	l	$\colormap = $\win->get_colormap;
put 	l	$\gc->set_foreground($\colormap->color_white());
put 	l	$\bp->draw_rectangle($\gc, 1, 0, 0, $\width, $\height);
################################
cmd 	slide $title = "Programmazione event-driven"
put 	l La programmazione event-driven è un paradigma che si
put 	l adatta bene ai programmi in ambiente grafico.
skip 	0 $fontsize
put 	l Il programmatore imposta delle callback che vengono
put 	l invocate quando si verificano determinati eventi.
skip 	0 $fontsize
put 	l In aggiunta agli eventi generati dall'ambiente grafico
put 	l ogni widget (discendente da GtkObject) può definire e
put 	l generare 
fg 	red
put 	n "signal"
fg 	black
put 	n : la generalizzazione di un evento.
################################
cmd 	slide $title = "La gestione degli eventi"
font 	fixed
fg 	red
put 	l $\gtkwin->signal_connect('button_press_event', sub {
cmd 	tab 2
put 	l	my ($\w, $\e)= @_;
put 	l	if ($\e->{'button'} == 1) {Gtk->main_quit;}
put 	l	elsif ($\e->{'button'} == 2) {Gtk->exit(0);}
put 	l	else {show_menu()}
cmd 	tab
put 	l });
skip 	0 $fontsize
put 	l $\gtkwin->signal_connect('delete_event', sub {Gtk->exit(0);});
skip 	0 $fontsize
put 	l $\gtkwin->signal_connect('expose_event', sub {
cmd 	tab 2
put 	l my ($\w, $\e) = @_;
put 	l my ($\x, $\y, $\wi, $\h) = @{$\e->{'area'}};
put 	l $\win->draw_pixmap($\gc, $\bp, $\x, $\y, $\x, $\y, $\wi, $\h);
cmd 	tab
put 	l });
################################
cmd 	slide $title = "Eventi di rete"
put 	l Anche la disponibilità di un file descriptor alla
put 	l lettura o scrittura sono considerati eventi
skip 	0 $fontsize
put 	l Questo permette di integrare in una gestione unica
put 	l gli eventi delle connessioni di rete con gli eventi
put 	l dell'ambiente grafico in modo non-blocking.
skip 	0 $fontsize
put 	l La chiave di questo è la funzione:
fg 	red
put 	n Gtk::Gdk::input_add.
fg 	black
skip 	0 $fontsize
put 	l Cerchiamo di scrivere delle funzioni event-driven nella
put 	l implementazione, ma non nell'interfaccia.
################################
cmd 	slide $title = "Funzione: write_data"
font 	fixed
fg 	red
put 	l	# $\sock is an IO::Socket object
skip 	0 $fontsize
put 	l	sub write_data {
cmd 	tab 2
put 	l		my ($\sock, $\data) = @_;
put 	l		my ($\id, $\len, $\written, $\res);
put 	l		$\written=0;
put 	l		$\len = length($\data);
put 	l		$\id = Gtk::Gdk->input_add($\sock->fileno(), ['write'], sub {
cmd 	tab 3 
put 	l			$\res = shift->syswrite($\data, $\len, $\written);
put 	l			$\written += $\res if defined $\res;
put 	l			Gtk->main_quit if ($\written == $\len || !defined $\res);
cmd 	tab 2
put 	l		}, $\sock);
put 	l		Gtk->main;
put 	l		Gtk::Gdk->input_remove($\id);
put 	l		return $\written == $\len;
cmd 	tab
put 	l	}
################################
cmd 	slide $title = "Funzione: read_data"
font 	fixed
fg 	red
put 	l	sub read_data {
cmd 	tab 2
put 	l		my ($\sock, $\eod) = @_;
put 	l		my ($\data, $\id, $\res, $\read);
skip 	0 $fontsize
put 	l		$\eod = "\\n" unless defined $\eod;
put 	l		$\id = Gtk::Gdk->input_add($\sock->fileno(), ['read'], sub {
cmd 	tab 3
put 	l			$\res = shift->sysread($\data, 1, $\read);
put 	l			$\read += $\res if defined $\res;
put 	l			Gtk->main_quit if (rindex($\data, $\eod) != -1 || !defined $\res);
cmd 	tab 2
put 	l		}, $\sock);
put 	l		Gtk->main;
put 	l		Gtk::Gdk->input_remove($\id);
put 	l		return $\data;
cmd 	tab
put 	l	}
################################
cmd 	slide $title = "Debug del modulo"
put 	l Il modulo deve essere compilato con l'opzione:
skip 	0 $fontsize
font 	fixed
fg 	red
put 	l OPTIMIZE=-g
skip 	0 $fontsize
fg 	black
font 	small
put 	l Con gdb si usa il binario /usr/bin/debugperl che
put 	l contiene informazioni di debug.
skip 	0 $fontsize
put 	l Come impostare un breakpoint se il modulo viene
put 	l caricato dinamicamente?
################################
cmd 	slide $title = "Futuri sviluppi"
put 	l Supporto delle nuove features di gtk+ e Gnome.
skip 	0 $fontsize
put 	l Sviluppo indipendente dei moduli aggiuntivi.
skip 	0 $fontsize
put 	l Integrazione con gli altri moduli Perl (GL).
skip 	0 $fontsize
put 	l Ottimizzazione dell'uso della memoria.
skip 	0 $fontsize
put 	l Integrazione con ORBit (CORBA).
################################
cmd 	slide $title = "Risorse su internet"
image	tcl c $imsize $imsize 
font 	fixed
fg 	steelblue
put 	c http://www.gtk.org
put 	c http://www.perl.org
put 	c http://www.debian.org
put 	c http://www.lettere.unipd.it/~lupus/pluto-98
skip 	0 $fontsize
put 	c CVSROOT=:pserver:anonymous@anoncvs.gimp.org:/cvs/gnome/
skip 	0 $fontsize
put 	c lupus@pluto.linux.it
slide	end
