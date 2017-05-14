use Gtk;
use Gtk::Atoms;

init Gtk;

use strict;

use vars qw($have_selection $selection_text $selection_button
			$selection_string);

sub TRUE { 1; }
sub FALSE { ""; }

sub selection_toggled {
	my $widget = shift;

	if ($widget->active) {
		$have_selection = $widget->selection_owner_set ($Gtk::Atoms{PRIMARY}, 0);

		if (!$have_selection) {
			$widget->set_state (FALSE);
		}
	}
	else {
		if ($have_selection) {
			if (Gtk::Gdk::Selection->owner_get ($Gtk::Atoms{PRIMARY}) == $widget->window) {
				Gtk::Widget::selection_owner_set (undef, $Gtk::Atoms{PRIMARY}, 0);
			}
			$have_selection = 0;
		}
	}
}

sub selection_handle {
	my ($widget, $selection_data) = @_;

	$selection_data->set ($selection_data->target == $Gtk::Atoms{COMPOUND_TEXT} ?
						      $Gtk::Atoms{COMPOUND_TEXT} : $Gtk::Atoms{STRING},
						  8,
						  defined $selection_string ? $selection_string : "");
}

sub selection_clear {
	my $widget = shift;

	$have_selection = FALSE;
	$widget->set_state (FALSE);

	TRUE;
}

# Subroutines to turn returned results into strings

sub stringify_atoms {
    my @atoms = unpack("L*",$_[0]);
    my $result = "";

    foreach (@atoms) {
		my $name = Gtk::Gdk::Atom->name($_);
		$result .= (defined $name ? $name : "(bad atom)")."\n";
    }

	$result;
}

sub stringify_texts {
	join("\n",split("\0",$_[0]))."\n";
}

sub stringify_xids {
    my @xids = unpack("L*",$_[0]);
	
	join("", map { sprintf("0x%x\n",$_) } @xids);
}

sub stringify_integers {
    my @ints = unpack("l*",$_[0]);
	join("", map { "$_\n" } @ints);
}

sub stringify_spans {
    my @ints = unpack("l*",$_[0]);

	my $result = "";
	while (@ints > 1) {
		my $x1 = shift @ints;
		my $x2 = shift @ints;

		$result .= "$x1 - $x2\n";
	}
	$result;
}

my %actions = (
			   ATOM => \&stringify_atoms,
			   COMPOUND_TEXT => \&stringify_texts,
			   STRING=> \&stringify_texts,
			   TEXT => \&stringify_texts,
			   BITMAP => \&stringify_xids,
			   DRAWABLE => \&stringify_xids,
			   PIXMAP => \&stringify_xids,
			   WINDOW => \&stringify_xids,
			   COLORMAP => \&stringify_xids,
			   INTEGER => \&stringify_integers,
			   PIXEL => \&stringify_integers,
			   SPAN => \&stringify_spans,
			  );

sub selection_received {
	my ($widget, $selection_data) = @_;

    my $data = $selection_data->data;

    # if $data is undefined, selection retrieval failed
    if (!defined $data) {
		warn "Selection retrieval failed\n";
		return;
    }
	
	my $name = Gtk::Gdk::Atom->name($selection_data->type);
	
	if (exists $actions{$name}) {
		$selection_string = $actions{$name}->($data);

		$selection_text->freeze;
		$selection_text->set_point (0);
		$selection_text->foreward_delete ($selection_text->get_length);

		$selection_text->insert (undef, $selection_text->style->black, undef,
								 $selection_string);
		$selection_text->thaw;
		
	} else {
		warn "Can't convert type ".defined $name ? $name : "unknown".
			"(".$selection_data->type.") to string\n";
	}
}
	
my $dialog = new Gtk::Dialog;
$dialog->set_name("Test Input");
$dialog->border_width (0);

$dialog->signal_connect ("destroy", sub { Gtk->exit(0) });

my $table = new Gtk::Table (4, 2, FALSE);
$table->border_width (10);

$table->set_row_spacing (0, 5);
$table->set_row_spacing (1, 2);
$table->set_row_spacing (2, 2);
$table->set_col_spacing (0, 2);

$dialog->vbox->pack_start ($table, TRUE, TRUE, 0);
$table->show;

$selection_button = new Gtk::ToggleButton "Claim Selection";
$table->attach ($selection_button, 0, 2, 0, 1, [ 'expand', 'fill' ], [], 
				 0, 0);

$selection_button->show;

$selection_button->signal_connect ("toggled", \&selection_toggled);
$selection_button->signal_connect ("selection_clear_event", \&selection_clear);
$selection_button->signal_connect ("selection_received", \&selection_received);

$selection_button->selection_add_handler ($Gtk::Atoms{PRIMARY}, $Gtk::Atoms{STRING},
										  \&selection_handle);

$selection_button->selection_add_handler ($Gtk::Atoms{PRIMARY}, $Gtk::Atoms{TEXT},
										  \&selection_handle);

$selection_button->selection_add_handler ($Gtk::Atoms{PRIMARY}, 
										  $Gtk::Atoms{COMPOUND_TEXT},
										  \&selection_handle);

$selection_text = new Gtk::Text (undef, undef);
$table->attach_defaults ($selection_text, 0, 1, 1, 2);
$selection_text->show;

my $hscrollbar = new Gtk::HScrollbar ($selection_text->hadj);
$table->attach ($hscrollbar, 0, 1, 2, 3, ['expand', 'fill'], 'fill', 0, 0);
$hscrollbar->show;

my $vscrollbar = new Gtk::VScrollbar ($selection_text->vadj);
$table->attach ($vscrollbar, 1, 2, 1, 2, 'fill', ['expand', 'fill'], 0, 0);
$vscrollbar->show;

my $hbox = new Gtk::HBox (FALSE, 2);
$table->attach ($hbox, 0, 2, 3, 4, ['expand', 'fill'], [], 0, 0);
$hbox->show;

my $label = new Gtk::Label "Target:";
$hbox->pack_start ($label, FALSE, FALSE, 0);
$label->show;

my $entry = new Gtk::Entry;
$hbox->pack_start ($entry, TRUE, TRUE, 0);
$entry->show;

# And create some buttons 

my $button;

$button = new Gtk::Button "Paste";
$dialog->action_area->pack_start ($button, TRUE, TRUE, 0);
$button->signal_connect ("clicked",
     sub {
               my $name = $entry->get_text;
               my $atom = $Gtk::Atoms{$name};
               if (!$atom) {
                       warn qq(Could not create atom: "$name");
                       return;
               }
               $selection_button->selection_convert ($Gtk::Atoms{PRIMARY}, $atom, 0);
       });
$button->show;

$button = new Gtk::Button "Quit";
$dialog->action_area->pack_start ($button, TRUE, TRUE, 0);
$button->signal_connect ("clicked", sub { $dialog->destroy });
$button->show;

$dialog->show;

main Gtk;

#  Local Variables:
#  tab-width: 4
#  End:
