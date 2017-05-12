#!/usr/bin/perl

#TITLE: HTML test
#REQUIRES: Gtk GtkXmHTML

use Gtk;
use Gtk::XmHTML;

@urls = (
	"unknown", "named (...)", "jump (#...)",
	"file_local (file.html)", "file_remote (file://foo.bar/file)",
	"ftp", "http", "gopher", "wais", "news", "telnet", "mailto",
	"exec:foo_bar", "internal"
);

$test_string2 =
"<html>\n".
"<head><title>The Gtk/XmHTML test</title></head>\n".
"This is the Gtk/XmHTML test program<p>\n".
"You can invoke this program with a command line argument, like this:\n".
"<hr>".
"<tt>./xtest filename.html</tt>".
"<hr>".
"Click here to load a different <a href=\"nothing\">test message</a>".
"</html>";

$test_string =
"<html><head><title>h</title></head>".
"<body>Item: %s<p>Frame: %s<p>".
"We want all the people in the world to use free software, because".
"free software is a very nice way of sharing code and learning new".
"things you had never thought of before".
"</body>".
"</html>";

$test_string3 =
"<html><head><title>h</title></head>".
"<body>I love you world".
"</body>".
"</html>";

sub click {
	my($widget, $info, $track) = @_;
	print "Click!\n";
	foreach (keys %{$info}) {
		print "$_ -> $info->{$_}\n";
	}
	$widget->source($test_string3) unless $track;
}

#
#void
#click (GtkWidget *widget, gpointer data)
#{
#	XmHTMLAnchorCallbackStruct *cbs = (XmHTMLAnchorCallbackStruct *) data;
#	
#	printf ("click!\n");
#	printf ("URLtype: %s\n", urls [cbs->url_type]);
#	printf ("line:    %d\n", cbs->line);
#	printf ("href:    %s\n", cbs->href);
#	printf ("target:  %s\n", cbs->target);
#	printf ("rel:     %s\n", cbs->rel);
#	printf ("rev:     %s\n", cbs->rev);
#	printf ("title:   %s\n", cbs->title);
#	printf ("doit:    %d\n", cbs->doit);
#	printf ("visited: %s\n", cbs->visited);
#	gtk_xmhtml_source (GTK_XMHTML (widget), test_string3);
#}

sub frame {
	my($widget) = @_;
	
	print "Frame!\n";
}

#void
#frame (GtkWidget *widget, gpointer data)
#{
#	XmHTMLFrameCallbackStruct *cbs = (void *) data;
#
#	printf ("Frame callback: ");
#	if (cbs->reason == XmCR_HTML_FRAME){
#		char buffer [1024];
#		GtkXmHTML *html = GTK_XMHTML (cbs->html);
#
#		sprintf (buffer, test_string, cbs->src, cbs->name);
#		printf ("frame: %s\n", buffer);
#		gtk_xmhtml_source (html, buffer);
#		return;
#	}
#
#	if (cbs->reason == XmCR_HTML_FRAMECREATE){
#		printf ("create\n");
#		return;
#	}
#	if (cbs->reason == XmCR_HTML_FRAMEDESTROY){
#		printf ("destroy\n");
#		return;
#	}
#}

init Gtk;

$window = new Gtk::Window -toplevel;

$file = shift;

if (open (F, "<$file")) {
	while (<F>) {
		$contents .= $_;
	}
	close (F);
} else {
	$contents = $test_string2;
}

$html = new Gtk::XmHTML;

$window->add($html);
$html->source($contents);
show $html;

$html->signal_connect('activate' => \&click);
$html->signal_connect('anchor_track' => \&click);
# bug here $html->signal_connect('anchor_track' => \&click, 1);
$html->signal_connect('frame' => \&frame);
$window->signal_connect('delete_event' => sub {Gtk->exit(0)});

$window->set_usize(400, 400);

show $window;

main Gtk;

