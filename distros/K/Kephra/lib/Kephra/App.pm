package Kephra::App;
our $VERSION = '0.12';

use strict;
use warnings;

our @ISA = 'Wx::App';       # $NAME is a wx application
my $obj;
sub _ref { $obj = ref $_[0] eq __PACKAGE__ ? $_[0] : $obj }

# main layout, main frame
sub warn { Kephra::Dialog::warning_box(Kephra::App::Window::_ref(), @_, 'Warning') }
sub splashscreen {
	my $img_file = shift;
	$img_file = Kephra::Config::filepath( $img_file );
	Wx::InitAllImageHandlers();
	my $sc = Wx::SplashScreen->new(
		Wx::Bitmap->new( $img_file, &Wx::wxBITMAP_TYPE_ANY ),
		&Wx::wxSPLASH_CENTRE_ON_SCREEN | &Wx::wxSPLASH_NO_TIMEOUT, 0, undef, -1,
		&Wx::wxDefaultPosition, &Wx::wxDefaultSize,
		&Wx::wxSIMPLE_BORDER | &Wx::wxFRAME_NO_TASKBAR | &Wx::wxSTAY_ON_TOP
	) if $img_file and -e $img_file;
	return $sc;
}

sub assemble_layout {
	my $win = Kephra::App::Window::_ref();
	my $tg = &Wx::wxTOP | &Wx::wxGROW;
	Kephra::EventTable::freeze
		( qw(app.splitter.right.changed app.splitter.bottom.changed) );

	$Kephra::app{splitter}{right} = Wx::SplitterWindow->new
		($win, -1, [-1,-1], [-1,-1], &Wx::wxSP_PERMIT_UNSPLIT)
			unless exists $Kephra::app{splitter}{right};
	my $right_splitter = $Kephra::app{splitter}{right};
	Wx::Event::EVT_SPLITTER_SASH_POS_CHANGED( $right_splitter, $right_splitter, sub {
		Kephra::EventTable::trigger( 'app.splitter.right.changed' );
	} );
	Wx::Event::EVT_SPLITTER_DOUBLECLICKED($right_splitter, $right_splitter, sub {
		Kephra::App::Panel::Notepad::show(0);
	});
	$right_splitter->SetSashGravity(1);
	$right_splitter->SetMinimumPaneSize(10);

	$Kephra::app{panel}{main} = Wx::Panel->new($right_splitter)
		unless exists $Kephra::app{panel}{main};
	my $column_panel = $Kephra::app{panel}{main};
	$column_panel->Reparent($right_splitter);

	# setting up output splitter
	$Kephra::app{splitter}{bottom} = Wx::SplitterWindow->new
		($column_panel, -1, [-1,-1], [-1,-1], &Wx::wxSP_PERMIT_UNSPLIT)
			unless exists $Kephra::app{splitter}{bottom};
	my $bottom_splitter = $Kephra::app{splitter}{bottom};
	Wx::Event::EVT_SPLITTER_SASH_POS_CHANGED( $bottom_splitter, $bottom_splitter, sub {
		Kephra::EventTable::trigger( 'app.splitter.bottom.changed' );
	} );
	Wx::Event::EVT_SPLITTER_DOUBLECLICKED($bottom_splitter, $bottom_splitter, sub {
		Kephra::App::Panel::Output::show(0);
	});
	$bottom_splitter->SetSashGravity(1);
	$bottom_splitter->SetMinimumPaneSize(10);

	$Kephra::app{panel}{center} = Wx::Panel->new($bottom_splitter)
		unless exists $Kephra::app{panel}{center};
	my $center_panel = $Kephra::app{panel}{center};
	$center_panel->Reparent($bottom_splitter);

	my $tab_bar    = Kephra::App::TabBar::_ref();
	my $search_bar = Kephra::App::SearchBar::_ref();
	my $search_pos = Kephra::App::SearchBar::position();
	my $notepad_panel = Kephra::App::Panel::Notepad::_ref();
	my $output_panel = Kephra::App::Panel::Output::_ref();
	$tab_bar->Reparent($center_panel);
	$search_bar->Reparent($center_panel);
	$search_bar->Reparent($column_panel) if $search_pos eq 'bottom';
	$notepad_panel->Reparent($right_splitter);
	$output_panel->Reparent($bottom_splitter);

	my $center_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	$center_sizer->Add( $search_bar, 0, $tg, 0) if $search_pos eq 'above';
	$center_sizer->Add( $tab_bar,    1, $tg, 0 );
	$center_sizer->Add( $search_bar, 0, $tg, 0 ) if $search_pos eq 'below';
	$center_panel->SetSizer($center_sizer);
	$center_panel->SetAutoLayout(1);

	my $column_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	$column_sizer->Add( $bottom_splitter, 1, $tg, 0);
	$column_sizer->Add( $search_bar,      0, $tg, 0) if $search_pos eq 'bottom';
	$column_panel->SetSizer($column_sizer);
	$column_panel->SetAutoLayout(1);

	my $win_sizer = Wx::BoxSizer->new(&Wx::wxVERTICAL);
	$win_sizer->Add( $right_splitter, 1, $tg, 0 );
	$win->SetSizer($win_sizer);
	$win->SetAutoLayout(1);
	$column_panel->Layout();
	$center_panel->Layout();
	#$win->SetBackgroundColour($tab_bar->GetBackgroundColour);

	Kephra::EventTable::thaw
		( qw(app.splitter.right.changed app.splitter.bottom.changed) );
	Kephra::App::SearchBar::show();
	Kephra::App::Panel::Notepad::show();
	Kephra::App::Panel::Output::show();
}

sub OnInit {
	use Benchmark ();
	my $t0 = new Benchmark if $Kephra::BENCHMARK;
	my $app = shift;
	_ref($app);
	#setup_logging();
	Wx::InitAllImageHandlers();
	# 2'nd splashscreen can close when app is ready, now called from Kephra.pm
	my $splashscreen = splashscreen('interface/icon/splash/start_kephra.jpg');
	my $frame = Kephra::App::Window::create();
	Kephra::Document::Data::create_slot(0);
	Kephra::App::TabBar::create();
	my $ep = Kephra::App::TabBar::add_edit_tab(0);
	Kephra::Document::Data::set_current_nr(0);
	Kephra::Document::Data::set_previous_nr(0);
	Kephra::Document::Data::set_value('buffer',1);
	Kephra::Document::Data::set_value('modified', 0);
	Kephra::Document::Data::set_value('loaded', 0);
	#Kephra::Plugin::load_all();
	#$main::logger->debug("init app pntr");
	print " init app:",
		Benchmark::timestr( Benchmark::timediff( new Benchmark, $t0 ) ), "\n"
		if $Kephra::BENCHMARK;
	my $t1 = new Benchmark;
	#$main::logger->debug("glob cfg load");
	print " glob cfg load:",
		Benchmark::timestr( Benchmark::timediff( new Benchmark, $t1 ) ), "\n"
		if $Kephra::BENCHMARK;
	my $t2 = new Benchmark;

	if (Kephra::Config::Global::autoload()) {
		Kephra::App::EditPanel::apply_settings_here($ep);
		Kephra::EventTable::freeze_all();
		print " configs eval:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t2 ) ), "\n"
			if $Kephra::BENCHMARK;
		my $t3 = new Benchmark;
		Kephra::File::Session::autoload();
		Kephra::EventTable::thaw_all();
		Kephra::Edit::Search::load_search_data();
		Kephra::Document::add($_) for @ARGV;
		print " file session:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t3 ) ), "\n"
			if $Kephra::BENCHMARK;
		my $t4 = new Benchmark;
		print " event table:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t4 ) ), "\n"
			if $Kephra::BENCHMARK;
		Kephra::App::EditPanel::gets_focus();
		Kephra::Edit::_let_caret_visible();

		$frame->Show(1);
		$splashscreen->Destroy(); 
		print "app startet:",
			Benchmark::timestr( Benchmark::timediff( new Benchmark, $t0 ) ), "\n"
			if $Kephra::BENCHMARK;
		1;                      # everything is good
	} else {
		$app->ExitMainLoop(1);
	}
}

sub exit { 
	Kephra::EventTable::stop_timer();
	if (Kephra::Dialog::save_on_exit() eq 'cancel') {
		Kephra::EventTable::start_timer();
		return;
	}
	exit_unsaved();
}

sub exit_unsaved {
	my $t0 = new Benchmark;
	Kephra::EventTable::stop_timer();
	Kephra::File::Session::autosave();
	Kephra::File::History::save();
	Kephra::Config::Global::autosave();
	Kephra::Config::set_xp_style(); #
	Kephra::App::Window::_ref()->Show(0);
	Kephra::App::Window::destroy(); # close window
	Wx::wxTheClipboard->Flush;      # set copied text free to the global Clipboard
	print "shut down in:",
		Benchmark::timestr( Benchmark::timediff( new Benchmark, $t0 ) ), "\n"
		if $Kephra::BENCHMARK;
}

sub raw_exit { Wx::Window::Destroy(shift) }
#sub new_instance { system("kephra.exe") }
# wxNullAcceleratorTable 

1;

