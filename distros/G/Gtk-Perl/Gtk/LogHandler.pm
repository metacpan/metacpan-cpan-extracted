
package Gtk::LogHandler;

require Gtk;

require Carp;

$LogWindow = undef;
$List = undef;
$Text = undef;

$CurrentItem = undef;

sub redisplay {
	$Text->realize;
	$Text->freeze;
	$Text->delete_text(0, $Text->get_length);
	
	if (defined $CurrentItem) {
		my($msg);
		
		$msg = $CurrentItem->{longmess};

		$Text->insert_text($msg, 0);
	}
	
	$Text->thaw;
}

sub set_current_item {
	my($item) = @_;
	
	$CurrentItem = $item;
	
	redisplay;
}

sub add_log {
	my($domain, $level, $message, $fatal) = @_;
	
	if (not defined $LogWindow) {
		
		$LogWindow = new Gtk::Window 'toplevel';
		$LogWindow->set_title("Perl/Gtk log for $0");
		$LogWindow->set_border_width(5);
		
		my($vbox) = new Gtk::VBox 0,0;
		show $vbox;
		
		$ScrolledList = new Gtk::ScrolledWindow;
		$ScrolledList->set_policy('automatic', 'automatic');
		$vbox->pack_start($ScrolledList, 1, 1, 5);
		show $ScrolledList;
		
		$List = new Gtk::List;
		$List->set_selection_mode('browse');
		$ScrolledList->add_with_viewport($List);
		show $List;
		
		$TextTable = new Gtk::Table(2,2,0);
        $TextTable->set_row_spacing(0,2);
        $TextTable->set_col_spacing(0,2);
        $vbox->pack_start($TextTable,0,1,5);
        $TextTable->show;
                
        $Text = new Gtk::Text;
        
        $TextTable->attach_defaults($Text, 0,1,0,1);
        show $Text;
                
        $hscrollbar = new Gtk::HScrollbar($Text->hadj);
        $TextTable->attach($hscrollbar, 0, 1,1,2,[-expand,-fill],[-fill],0,0);
        $hscrollbar->show;

        $vscrollbar = new Gtk::VScrollbar($Text->vadj);
        $TextTable->attach($vscrollbar, 1, 2,0,1,[-fill],[-expand,-fill],0,0);
        $vscrollbar->show;
		
		$ButtonBox = new Gtk::HButtonBox;
		$ButtonBox->set_layout('spread');
		$vbox->pack_start($ButtonBox, 0, 0, 5);
		show $ButtonBox;

		$Dismiss = new Gtk::Button 'Dismiss';
		$ButtonBox->add($Dismiss);
		show $Dismiss;
		
		$Clear = new Gtk::Button 'Clear';
		$ButtonBox->add($Clear);
		show $Clear;
		
		$LogWindow->add($vbox);

		$List->signal_connect("select_child" => sub {
			my($widget, $item) = @_;
			set_current_item $item;
		});

		$Dismiss->signal_connect("clicked" => sub {
			$LogWindow->hide;
		});
		$Clear->signal_connect("clicked" => sub {
			$List->remove_items($List->children);
			set_current_item undef;
		});
		
		$LogWindow->signal_connect("destroy" => sub { $Dismiss->clicked });

	}

	my(@callers);
	my($i);
	my($longmess);
	
	for($i=1;;$i++) {
		my(@c);
		{ package DB; @c = (caller($i)); }
		if (@c) {
			push @callers,[@c];
		} else {
			last;
		}
	}
	
	{
		local($Carp::CarpLevel) = $Carp::CarpLevel;
		$CarpLevel++;
		$longmess = Carp::longmess($message);
	}
	
	my($ListItem) = new Gtk::ListItem $message;
	
	$ListItem->{message} = $message;
	$ListItem->{longmess} = $longmess;
	$ListItem->{stack} = \@callers;
	$ListItem->{domain} = $domain;
	$ListItem->{fatal} = $fatal;
	show $ListItem;
	
	$List->add($ListItem);
	$List->select_child($ListItem);
	
	redisplay;
	
	if ($fatal) {
		set_modal $LogWindow 1;
		$Dismiss->signal_connect('clicked' => sub { Gtk->main_quit; });
	}
	
	show $LogWindow;
	$LogWindow->window->raise;
	$LogWindow->window->show;
	$LogWindow->position('center');

	if ($fatal) {
		Gtk->main;
	}
	
	if ($fatal) {
		die $message;
	} else {
		warn $message;
	}
};

$Gtk::log_handler = \&add_log;

1;
