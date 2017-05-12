#!/usr/bin/perl -w

# Note: this is a generic launcher script, designed to work with all Gtk versions.
# If you are interested in the Perl port of the Gtk widget demo, please look at
# Gtk/samples/test.pl.

use Gtk;

if (!init_check Gtk) {
	print STDERR "You have to run make test under X\n";
	exit(0);
}

# Build list of available sample scripts

foreach $file (<*/samples/*.pl>) {
	open(F, "<$file");
	
	$file =~ m!^(.*/)!;
	$directory = $1;
	$file = $';
	
	$title = undef;
	$requires = undef;
	
	while (<F>) {
		chop;
		if (/TITLE:\s+(.*?)\s*$/) {
			$title = $1;
		}
		if (/REQUIRES:\s+(.*?)\s*$/) {
			$requires = $1;
		}
	}
	
	close(F);

	if (defined $title or defined $requires) {
		push @samples, {file => $file, directory => $directory, title => $title, requires => $requires};
	}
	
}

# Build execution environment

push @exec, $^X, "-w";

foreach (@INC) {
	if (m!^/!) {
		push @exec, "-I$_";
	} else {
		push @exec, "-I../../$_";
	}
}

sub run {
	my($script) = @_;
	my(@blib) = ();
	
	foreach (split(/\s+/, $script->{requires})) {
		next if /^Gtk$/;
		push(@blib, "-Mblib=../../$_") if -d "$_/blib";
		push(@blib, "-Mblib=../../GdkImlib") 
			if (/^Gnome$/ && -d "GdkImlib/blib");
	}
	print "\nExecuting (in $script->{directory}: ", join(' ', @exec, @blib, $script->{file}), "\n";
	
	if (!fork) {
		chdir($script->{directory});
		exec @exec, @blib, $script->{file};
	}
}

# Build UI

$main_window = new Gtk::Window -toplevel;
$main_window->set_title("Samples for Perl/Gtk+");
$main_window->set_border_width(5);
$main_window->set_usize(600, 500);

$hbox = new Gtk::HBox 0, 0;
show $hbox;

$main_window->add($hbox);

$list_scroller = new Gtk::ScrolledWindow(undef, undef);
$list_scroller->set_policy(-automatic, -automatic);
$list_scroller->border_width(5);

show $list_scroller;

$sample_list = new Gtk::List;
$sample_list->set_selection_mode(-multiple);
$sample_list->signal_connect( "select_child" => sub { 
	show_sample($_[1]->{sample});
} );

$list_scroller->add_with_viewport($sample_list);
$list_scroller->set_usize(150, 100);

$hbox->pack_start($list_scroller, 0, 1, 5);
show $sample_list;

$vbox = new Gtk::VBox 0, 0;
show $vbox;

$title_label = new Gtk::Label "";
show $title_label;
$vbox->pack_start($title_label, 0, 1, 0);

$file_label = new Gtk::Label "";
show $file_label;
$vbox->pack_start($file_label, 0, 1, 0);

$requires_label = new Gtk::Label "";
show $requires_label;
$vbox->pack_start($requires_label, 0, 1, 0);

$source_hbox = new Gtk::HBox 0, 0;

$source = new Gtk::Text undef, undef;
show $source;

sub show_sample {
	my($sample) = @_;
	open (F, "<" . $sample->{directory} . $sample->{file});
	
	$source->freeze;
	$source->realize;
	$source->delete_text(0, $source->get_length);
	
	while (<F>) {
		$source->insert_text($_, $source->get_length);
	}
	
	$source->thaw;
	
	close(F);
	
	$current_sample = $sample;
	$run->set_sensitive(1);
	
	$title_label->set("Title: " . $sample->{title});
	$file_label->set("File: " . $sample->{directory}.$sample->{file});
	$requires_label->set("Requires: " . $sample->{requires});

}

$source_hbox->pack_start($source, 1, 1, 0);
show $source_hbox;

$source_vscroll = new Gtk::VScrollbar($source->vadj);
$source_vscroll->show;

$source_hbox->pack_end($source_vscroll, 0, 0, 0);

$vbox->pack_start($source_hbox, 1, 1, 0);

$hbbox = new Gtk::HButtonBox;

$run = new Gtk::Button "Quit";
$run->signal_connect("clicked" => sub { Gtk->exit(0);} );
show $run;
$hbbox->add($run);

$run = new Gtk::Button "Run";
$run->signal_connect("clicked" => sub { run $current_sample if defined $current_sample;} );
show $run;
$run->can_default(1);
$run->set_sensitive(0);
$hbbox->add($run);

show $hbbox;
$vbox->pack_end($hbbox, 0, 1, 5);

$hbox->pack_start($vbox, 1, 1, 5);

foreach (sort {$a->{title} cmp $b->{title}} @samples) {

	$list_item = new Gtk::ListItem $_->{title};
	$list_item->{sample} = $_;

	$sample_list->add($list_item);
	$list_item->show;

}		

sub idle {
	$sample_list->set_selection_mode(-browse);
	$sample_list->select_item(0);
	return 0;
}

Gtk->idle_add(\&idle);

$main_window->signal_connect("destroy" => sub { destroy $main_window; exit } );

$run->grab_default();
show $main_window;

main Gtk;
