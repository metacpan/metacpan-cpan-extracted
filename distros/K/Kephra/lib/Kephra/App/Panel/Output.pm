package Kephra::App::Panel::Output;
our $VERSION = '0.11';

use strict;
use warnings;
use Cwd();
use Wx qw(wxTheClipboard);
use Wx::Perl::ProcessStream qw( 
	EVT_WXP_PROCESS_STREAM_STDOUT
	EVT_WXP_PROCESS_STREAM_STDERR
	EVT_WXP_PROCESS_STREAM_EXIT
);
use Wx::DND;

my $output;
my $proc;
sub _ref { if (ref $_[0] eq 'Wx::TextCtrl') {$output = $_[0]} else {$output} }
sub _config   { Kephra::API::settings()->{app}{panel}{output} }
sub _splitter { $Kephra::app{splitter}{bottom} }
sub _process  { $proc }
sub is_process { 1 if ref $_[0] eq 'Wx::Perl::ProcessStream::Process' }

sub create {
	my $win = Kephra::App::Window::_ref();
	my $edit = Kephra::App::EditPanel::_ref();
	my $output;
	if (_ref()) {$output = _ref()}
	else {
		$output = Wx::TextCtrl->new
			($win, -1,'', [-1,-1], [-1,-1],
			&Wx::wxTE_READONLY|&Wx::wxTE_PROCESS_ENTER|&Wx::wxTE_MULTILINE|&Wx::wxTE_LEFT);
	}
	_ref($output);
	my $config = _config();
	my $color = \&Kephra::Config::color;
	$output->SetForegroundColour( &$color( $config->{fore_color} ) );
	$output->SetBackgroundColour( &$color( $config->{back_color} ) );
	$output->SetFont( Wx::Font->new
		($config->{font_size}, &Wx::wxFONTSTYLE_NORMAL, &Wx::wxNORMAL, &Wx::wxLIGHT, 0,
		$config->{font_family})
	);
	#$output->SetEditable(0);

	Kephra::EventTable::add_call('panel.output.run', 'panel_output', sub {
	});
	Kephra::EventTable::add_call
		( 'app.splitter.bottom.changed', 'panel_notepad', sub {
			if ( get_visibility() and not _splitter()->IsSplit() ) {
				show( 0 );
				return;
			}
			save_size();
	});

	EVT_WXP_PROCESS_STREAM_STDOUT( $win, sub {
		my ($self, $event) = @_;
		$event->Skip(1);
		say( $event->GetLine );
	} );
	EVT_WXP_PROCESS_STREAM_STDERR( $win, sub {
		my ($self, $event) = @_;
		$event->Skip(1);
		say( $event->GetLine );
	} );
	EVT_WXP_PROCESS_STREAM_EXIT  ( $win, sub {
		my ($self, $event) = @_;
		$event->Skip(1);
		$event->GetProcess->Destroy;
		Kephra::EventTable::trigger('panel.output.run');
	} );
	Wx::Event::EVT_LEFT_DOWN($output, sub {
		my ($op, $event) = @_;
		unless ($^O =~ /darwin/i) {
			my ($beside, $col, $row) = $op->HitTest( Wx::Point->new($event->GetX, $event->GetY) );
			my ($begin, $end) = $op->GetSelection;
			if ($beside !=  &Wx::wxTE_HT_UNKNOWN and $begin != $end) {
				my $pos = $op->XYToPosition($col, $row);
				copy_selection() if $pos >= $begin and $pos <= $end;
			}
		}
		$event->Skip;
	});
	Wx::Event::EVT_MIDDLE_DOWN($output,  sub {
		my ($op, $event) = @_;
		Kephra::Edit::Search::set_find_item( $op->GetStringSelection() );
		Kephra::Edit::Search::find_next();
	});
	Wx::Event::EVT_KEY_DOWN( $output, sub {
		my ( $op, $event ) = @_;
		my $key = $event->GetKeyCode;
		if ($key ==  &Wx::WXK_RETURN) {
			copy_selection();
		} elsif ($key == &Wx::WXK_F12) {
			Kephra::App::Panel::Notepad::append( $output->GetStringSelection() )
				if $event->ShiftDown;
		}
	});

	$output->Show( get_visibility() );
	$output;
}

sub get_visibility    { _config()->{visible} }
sub switch_visibility { show( get_visibility() ^ 1 ) }
sub ensure_visibility { switch_visibility() unless get_visibility() }
sub show {
	my $visibile = shift;
	my $config = _config();
	$visibile  = $config->{visible} unless defined $visibile;
	my $win    = Kephra::App::Window::_ref();
	my $cpanel = $Kephra::app{panel}{center};
	my $output = _ref();
	my $splitter = _splitter();
	if ($visibile) {
		$splitter->SplitHorizontally( $cpanel, $output );
		$splitter->SetSashPosition( -1*$config->{size}, 1);
	} else {
		$splitter->Unsplit();
		$splitter->Initialize( $cpanel );
	}
	$output->Show($visibile);
	$win->Layout;
	$config->{visible} = $visibile;
	Kephra::EventTable::trigger('panel.output.visible');
}

sub save { save_size() }
sub save_size {
	my $splitter = _splitter();
	return unless $splitter->IsSplit();
	my $wh=Kephra::App::Window::_ref()->GetSize->GetHeight;
	_config()->{size} = -1*($wh-($wh-$splitter->GetSashPosition));
}


sub clear {
	_ref()->Clear;
	if (Wx::wxMAC()) {_ref()->SetFont
		( Wx::Font->new(_config()->{font_size}, &Wx::wxFONTSTYLE_NORMAL,
		  &Wx::wxNORMAL, &Wx::wxLIGHT, 0, _config()->{font_family})
	)}
}
sub print { _ref()->AppendText( $_ ) for @_ }
sub say   { &print; _ref()->AppendText( "\n" ) }
sub new_output {
	ensure_visibility();
	_config()->{append}
		? &print(_ref()->IsEmpty ? '' : "\n\n")
		: &clear();
	&print( @_ );
}

sub copy_selection {
	my $selection = _ref()->GetStringSelection();
	return unless $selection;
	wxTheClipboard->Open;
	wxTheClipboard->SetData( Wx::TextDataObject->new( $selection ) );
	wxTheClipboard->Close;

}
# 
sub display_inc { new_output('@INC:'."\n"); &say("  -$_") for @INC }
sub display_env { 
	new_output('%ENV:'."\n");
	&say( "  -$_:" . $ENV{$_} ) for sort keys %ENV;
}
sub display_selection_dec {
	my $selection = Kephra::Edit::get_selection();
	return unless defined $selection and $selection;
	my @output = map { ' ' . $_ } unpack 'C*', $selection;
	new_output(@output);
}
sub display_selection_hex {
	my $selection = Kephra::Edit::get_selection();
	return unless defined $selection and $selection;
	my @output = map { sprintf '%3X', $_ } unpack 'C*', $selection;
	new_output(@output);
}
# to be outsourced into interpreter plugin
sub run {
	my $win = Kephra::App::Window::_ref();
	my $doc = Kephra::Document::Data::get_file_path();
	my $cmd = _config->{interpreter_path};
	my $dir = Kephra::File::_dir();
	Kephra::File::save();
	if ($doc) {
		my $cwd = Cwd::cwd();
		chdir $dir;
		my $proc = Wx::Perl::ProcessStream->OpenProcess
			(qq~"$cmd" "$doc"~ , 'Interpreter-Plugin', $win); # -I$dir
		chdir $cwd;
		new_output();
		Kephra::EventTable::trigger('panel.output.run');
		if (not $proc) {}
	} else {
		my $l18n = Kephra::Config::Localisation::strings()->{app};
		Kephra::App::StatusBar::info_msg
			($l18n->{menu}{document}.' '.$l18n->{general}{untitled}."\n" );
	}
}

sub is_running {
	my $proc = _process();
	$proc->IsAlive if is_process($proc);
}

sub stop {
	my $proc = _process();
	if ( is_process($proc) ) {
		$proc->KillProcess;
		$proc->TerminateProcess;
		Kephra::EventTable::trigger('panel.output.run');
	}
}

1;

=head1 NAME

Kephra::App::Panel::Output - output panel

=head1 DESCRIPTION

=cut