# $Id: Base.pm,v 1.15 2001/11/02 12:32:06 joern Exp $

package JaM::GUI::Base;

@ISA = qw ( JaM::Debug );

use strict;
use Carp;
use Data::Dumper;
use Cwd;
use JaM::Debug;
use JaM::Config;
use JaM::GUI::HTMLSurface;

my $CONFIG_OBJECT;
my %COMPONENTS;
my %SESSION_PARAMETERS;

sub new {
	my $type = shift;
	my %par = @_;
	
	my  ($dbh) = @par{'dbh'};

	my $self = {
		dbh => $dbh,
	};
	
	if ( not defined $CONFIG_OBJECT and $dbh ) {
		$CONFIG_OBJECT = JaM::Config->new ( dbh => $dbh );
	}
	
	return bless $self, $type;
}

# return database handle
sub dbh 		{ shift->{dbh}			}
sub htdocs_dir		{ return "lib/JaM/htdocs" }
sub session_parameters	{ \%SESSION_PARAMETERS		}

# get/set component objects
sub comp {
	my $self = shift;
	my ($name, $object) = @_;
	return $COMPONENTS{$name} = $object if @_ == 2;
	confess "unknown component '$name'"
		if not defined $COMPONENTS{$name};
	return $COMPONENTS{$name};
}

# get/set configuration parameters
sub config {
	my $thingy = shift;
	my ($name, $value) = @_;

	if ( @_ == 2 ) {
		$value = $CONFIG_OBJECT->set_value ($name, $value);
	} else {
		$value = $CONFIG_OBJECT->get_value ($name);
	}

	return $value;
}

# get config object
sub config_object {
	$CONFIG_OBJECT;
}

# restart program (needed during initalization process)
sub restart_program {
	exec ("bin/jam.pl", @ARGV);
}

sub show_file_dialog {
	my $self = shift;
	my %par = @_;
	my  ($dir, $filename, $cb, $title, $confirm) =
	@par{'dir','filename','cb','title','confirm'};
	
	my $cwd = cwd;
	chdir ( $dir );
	
	# Create a new file selection widget
	my $dialog = new Gtk::FileSelection( $title );

	# Connect the ok_button to file_ok_sel function
	$dialog->ok_button->signal_connect(
		"clicked",
		sub { $self->cb_commit_file_dialog (@_, $confirm) },
		$cb, $dialog
	);

	# Connect the cancel_button to destroy the widget
	$dialog->cancel_button->signal_connect(
		"clicked", sub { $dialog->destroy }
	);

	$dialog->set_filename( $filename );
	$dialog->set_position ( "mouse" );
	$dialog->show();
	
	chdir ($cwd);

	1;
}

sub cb_commit_file_dialog {
	my $self = shift;
	my ($button, $cb, $dialog, $confirm) = @_;
	
	my $filename = $dialog->get_filename();
	
	if ( -f $filename and $confirm ) {
		$self->confirm_window (
			message => "Overwrite existing file '$filename'?",
			yes_callback => sub { &$cb($filename); $dialog->destroy },
			position => 'mouse'
		);
	} else {
		&$cb($filename);
		$dialog->destroy;
	}

	1;
}

sub confirm_window {
	my $self = shift;
	my %par = @_;
	my  ($message, $yes_callback, $no_callback, $position, $yes_label, $no_label) =
	@par{'message','yes_callback','no_callback','position','yes_label','no_label'};
	
	$yes_label ||= "Ok";
	
	my $confirm = Gtk::Dialog->new;
	my $label = Gtk::Label->new ($message);
	$confirm->vbox->pack_start ($label, 1, 1, 0);
	$confirm->border_width(10);
	$confirm->set_title ("Confirmation");
	$label->show;

	my $cancel = Gtk::Button->new ("Cancel");
	$confirm->action_area->pack_start ( $cancel, 1, 1, 0 );
	$cancel->signal_connect( "clicked", sub { $confirm->destroy } );
	$cancel->show;

	if ( $no_label ) {
		my $no = Gtk::Button->new ($no_label);
		$confirm->action_area->pack_start ( $no, 1, 1, 0 );
		$no->signal_connect( "clicked", sub { $confirm->destroy; &$no_callback } );
		$no->show;
	}

	my $ok = Gtk::Button->new ($yes_label);
	$confirm->action_area->pack_start ( $ok, 1, 1, 0 );
	$ok->can_default(1);
	$ok->grab_default;
	$ok->signal_connect( "clicked", sub { $confirm->destroy; &$yes_callback } );
	$ok->show;

	$confirm->set_position ($position);
	$confirm->set_modal (1);
	$confirm->show;

	1;
}

sub help_window {
	my $self = shift;
	my %par = @_;
	my ($file, $title) = @par{'file','title'};
	
	my $win = new Gtk::Window;
	$win->set_title( "Help: $title" );
	$win->set_usize ( 420, 350 );
	$win->border_width(0);
	$win->position ('center');
	$win->signal_connect("destroy", sub { $win->destroy } );

	my $vbox = Gtk::VBox->new (0,0);
	$vbox->show;	

	my $sw = new Gtk::ScrolledWindow(undef, undef);
	$sw->set_policy('automatic', 'automatic');

	my $html = JaM::GUI::HTMLSurface->new (
		image_dir => $self->htdocs_dir,
	);


	$HELP::HEADER = qq{
		<html><body bgcolor="white">
		<h1>JaM Help: $title</h1>
		<hr>
		<p>
	};
	$HELP::FOOTER = qq{
		</body>
		</html>
	};

	$html->show_eval (
		file => "help/$file"
	);

	my $widget = $html->widget;
	$sw->show;
	$sw->add($widget);

	$vbox->pack_start($sw, 1, 1, 0);

	$win->add ($vbox);
	$win->show;

	1;	
	
}

sub message_window {
	my $self = shift;
	my %par = @_;
	my ($message) = @par{'message'};
	
	my $dialog = Gtk::Dialog->new;

	my $label = Gtk::Label->new ("\n".$message."\n");
	$dialog->vbox->pack_start ($label, 1, 1, 0);
	$dialog->border_width(10);
	$dialog->set_title ("JaM Message");
	$dialog->set_default_size (250, 150);
	$label->show;

	my $ok = Gtk::Button->new ("Ok");
	$dialog->action_area->pack_start ( $ok, 1, 1, 0 );
	$ok->signal_connect( "clicked", sub { $dialog->destroy } );
	$ok->show;

	$dialog->set_position ("center");
	$dialog->show;

	1;	
	
}

sub gdk_color {
	my $self = shift;
	my ($html_color) = @_;
	
	$html_color =~ s/^#//;
	
	my ($r, $g, $b) = ( $html_color =~ /(..)(..)(..)/ );

	my $cmap = Gtk::Gdk::Colormap->get_system();
	my $color = {
		red   => hex($r) * 256,
		green => hex($g) * 256,
		blue  => hex($b) * 256,
	};
	
	if ( not $cmap->color_alloc ($color) ) {
		warn ("Couldn't allocate color $html_color");
	}
	
	return $color;
}
	

1;
