#!/usr/bin/perl -w

#TITLE: Gnome HTML
#REQUIRES: Gtk Gnome GtkXmHTML

use Gnome;
use Gtk::XmHTML;
use LWP::UserAgent;

init Gnome "html.pl";

$start = shift || 'http://localhost/';
print "start: $start\n";

$ua = new LWP::UserAgent();
$win = new Gtk::Window -toplevel;
$win->signal_connect('destroy', sub {Gtk->exit(0)});
$html = new Gtk::XmHTML;
$html->set_allow_images(1);
$html->set_image_procs(\&get_image);
$html->signal_connect('activate', \&goto_url);
$html->signal_connect('anchor_track', \&goto_url, 1);
$html->source("<B>Loading $start...</B>");
$html->show;
$win->add($html);
$win->set_usize(400, 400);
$win->show;

Gtk->idle_add(sub {
	goto_url($html, {'href' => $start});
	return 0;
});
main Gtk;


sub get_image {
	my ($html, $href) = @_;
	my ($request, $data);

	$href = "${base}$href" unless $href =~ m/:/;
	print "GET IMAGE: $href\n";
	$request = new HTTP::Request('GET', $href);
	$data = $ua->request($request);
	if ($data->is_success) {
		return ($href, $data->content());
	} else {
		# print $data->error_as_HTML();
		return ($href, undef);
	}
	
}

sub goto_url {
	my ($html, $p, $track) =@_;
	
	if (ref $track) {
		($track, $p) = ($p, $track);
	}
	my ($href) = $p->{'href'};
	if ($track) {
		#print "track\n";
		#foreach (keys %{$p}) {
		#	print "$_ -> $p->{$_}\n";
		#}
		return unless $href;
		print "URL: $href\n";
		return;
	}
	$base = '' unless $base;
	$href = "${base}$href" unless $href =~ m/:/;
	print "GOTO: $href\n";
	$request = new HTTP::Request('GET', $href);
	$data = $ua->request($request);
	if ($data->is_success) {
		my ($uri) = $data->base;
		$base = $uri if $uri =~ m(/$); #/
		# $html->set_def_body_image_url($base);
		$html->source($data->content());
	} else {
		$html->source($data->error_as_HTML());
	}
}

