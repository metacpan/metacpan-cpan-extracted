# $Id: Config.pm,v 1.2 2001/08/20 20:37:30 joern Exp $

package JaM::GUI::Config;

@ISA = qw ( JaM::GUI::Window );

use strict;
use JaM::GUI::Window;
use JaM::Filter::IO;
use File::Basename;

my $DEBUG = 1;

# get/set gtk object for subjects clist
sub gtk_win		{ my $s = shift; $s->{gtk_win}
		          = shift if @_; $s->{gtk_win}		}

sub gtk_parameter_list	{ my $s = shift; $s->{gtk_parameter_list}
		          = shift if @_; $s->{gtk_parameter_list}	}

sub gtk_parameter_frame	{ my $s = shift; $s->{gtk_parameter_frame}
		          = shift if @_; $s->{gtk_parameter_frame}	}

sub parameter_names	{ my $s = shift; $s->{parameter_names}
		          = shift if @_; $s->{parameter_names}	}

sub selected_parameter	{ my $s = shift; $s->{selected_parameter}
		          = shift if @_; $s->{selected_parameter}	}

sub selected_parameter_value	{ my $s = shift; $s->{selected_parameter_value}
		         	  = shift if @_; $s->{selected_parameter_value}	}

sub single_instance_window { 1 }

sub DESTROY {
	my $self = shift; $self->trace_in;
	$self->comp('input_filter', undef);
}

sub build {
	my $self = shift; $self->trace_in;

	my $win = Gtk::Window->new;
	$win->set_position ("center");
	$win->set_title ("Edit Configuration Parameters");
	$win->border_width(5);
	$win->set_default_size (450, 400);
	$win->realize;
	$win->show;

	my $vpane = new Gtk::VPaned();
	$vpane->show();
	$win->add ($vpane);
	$vpane->set_handle_size( 10 );
	$vpane->set_gutter_size( 15 );
	
	my $fr = Gtk::Frame->new ("Select configuration parameter");
	$fr->show;

	my $hbox = Gtk::HBox->new(0,5);
	$hbox->show;
	$hbox->set_border_width(5);
	$fr->add($hbox);

	my $sw = new Gtk::ScrolledWindow( undef, undef );
	$sw->set_policy( 'never', 'automatic' );
	$sw->set_usize(250, 200);
	$sw->show();

	my $list = Gtk::CList->new_with_titles ( "" );
	$list->set_selection_mode( 'browse' );
	$list->set_shadow_type( 'none' );
	$list->set_usize (350, 200);
	$list->signal_connect( "select_row", sub { $self->cb_select_parameter(@_) } );
	$list->show();

	$sw->add ($list);

	$hbox->pack_start ($sw, 1, 1, 0);
	
	my $vbox = Gtk::VBox->new(0,5);
	$vbox->show;
	
	my $ok_button = Gtk::Button->new( "Ok" );
	$ok_button->show;
	$ok_button->signal_connect('clicked', sub {
		$self->save_selected_parameter;
		$win->destroy;
	});
	$vbox->pack_start($ok_button, 0, 1, 1);

	my $text_label = Gtk::Label->new (
		"Most parameter changes will only\n".
		"take effect, when JaM is restarted."
	);
	$text_label->show;
	$text_label->set_line_wrap(1);

	$vbox->pack_start($text_label, 0, 1, 1);

	$hbox->pack_start ($vbox, 0, 0, 0);

	$vpane->add1 ($fr);
	
	my $filter_frame = Gtk::Frame->new ("Edit selected parameter");
	$filter_frame->show;
	
	$vpane->add2 ($filter_frame);

	$self->gtk_win ($win);
	$self->gtk_parameter_list  ($list);
	$self->gtk_parameter_frame ($filter_frame);
	$self->gtk_window_widget ($win);

	$self->parameter_names([]);

	$self->show_parameters;

	$self->comp('config' => $self);

	1;
}

sub show_parameters {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($type) = @par{'type'};
	
	if ( $self->selected_parameter ) {
		$self->save_selected_parameter;
	}

	my $list = $self->gtk_parameter_list;
	$list->freeze;
	$list->clear;
	$list->set_column_title(
		0,
		'Parameter Description'
	);

	my $parameter_names = $self->parameter_names([]);

	my $parameters = $self->config_object->config;

	foreach my $par ( sort { $a->{name} cmp $b->{name} } values %{$parameters} ) {
		next if not $par->{visible};
		$list->append($par->{description});
		push @{$parameter_names}, $par->{name};
	}

	$list->thaw;

	$self->blank_edit_pane;

	$list->select_row (0, 0);
	
	1;
}

sub blank_edit_pane {
	my $self = shift; $self->trace_in;

	my $frame = $self->gtk_parameter_frame;
	my (@children) = $frame->children;
	foreach my $child ( @children ) {
		$frame->remove ($child);
		$child->destroy;
		$child = undef;
	}

	$self->selected_parameter(undef);

	1;	
}

sub cb_select_parameter {
	my $self = shift; $self->trace_in;
	
	if ( $self->selected_parameter ) {
		$self->save_selected_parameter;
	}
	
	my $row = $self->gtk_parameter_list->selection;
	return 1 if not defined $row;

	my $parameter_names = $self->parameter_names;
	my $parameter_name = $parameter_names->[$row];

	return if not defined $parameter_name;

	$self->debug("row=$row parameter=$parameter_name");
	
	$self->build_edit_pane ( parameter_name => $parameter_name );

	1;
}

sub build_edit_pane {
	my $self = shift; $self->trace_in;
	my %par = @_;
	my ($parameter_name) = @par{'parameter_name'};

	$parameter_name ||= $self->selected_parameter;

	$self->blank_edit_pane;

	$self->selected_parameter($parameter_name);

	my $parameter_value =
		$self->selected_parameter_value(
			$self->config($parameter_name)
		);

	my $par = $self->config_object->config->{$parameter_name};

	my $vbox = Gtk::VBox->new(0, 5);
	$vbox->set_border_width(5);
	$vbox->show;
	$self->gtk_parameter_frame->add($vbox);

	my $hbox = Gtk::HBox->new(0, 20);
	$hbox->show;
	$vbox->pack_start($hbox, 0, 0, 0);
	
	my $left_vbox  = Gtk::VBox->new(0, 0);
	$left_vbox->show;
	my $right_vbox = Gtk::VBox->new(0, 0);
	$right_vbox->show;

	$hbox->pack_start($left_vbox, 0, 0, 0);
	$hbox->pack_start($right_vbox, 1, 1, 0);

	my ($label, $value);

	$label = Gtk::Label->new ("Description:");
	$label->show;
	$label->set_justify('left');
	
	$value = Gtk::Label->new ($par->{description});
	$value->show;
	$value->set_justify('left');

	$left_vbox->pack_start($label, 0, 0, 0);
	$right_vbox->pack_start($value, 0, 0, 0);

	$label = Gtk::Label->new ("Current Value:");
	$label->show;
	$label->set_justify('left');

	my $val = $par->{value};
	if ( $par->{type} eq 'list' ) {
		$val = join (", ", @{$val});
	} elsif ( $par->{type} eq 'bool' ) {
		$val = $par->{value} ? "Yes" : "No";
	}
	$value = Gtk::Label->new ($val);
	$value->show;
	$value->set_justify('left');

	$left_vbox->pack_start($label, 0, 0, 0);
	$right_vbox->pack_start($value, 0, 0, 0);
	
	$label = Gtk::Label->new ("Change Value:");
	$label->show;
	$label->set_justify('left');

	my $value = $self->create_edit_widget (
		par => $par
	);

	$left_vbox->pack_start($label, 0, 0, 0);
	$right_vbox->pack_start($value, 0, 0, 0);

	1;
}

sub create_edit_widget {
	my $self = shift;
	my %par = @_;
	my ($par) = @par{'par'};
	
	my $widget;

	my $type = $par->{type};
	$self->debug ("type=$type");

	if ( $type eq 'text' ) {
		$widget = Gtk::Entry->new;
		$widget->set_text ($par->{value});
		$widget->signal_connect(
			"changed", sub {
				$self->selected_parameter_value($widget->get_text);
			}
		);
	} elsif ( $type eq 'dir' ) {
		$widget = Gtk::Button->new ("Choose Directory");
		$widget->signal_connect(
			"clicked", sub {
				$self->show_file_dialog (
					dir => $par->{value},
					title => $par->{description},
					confirm => 0,
					cb => sub {
						my ($filename) = @_;
						$filename = dirname $filename if -f $filename;
						$filename =~ s!/$!!;
						$self->selected_parameter_value($filename);
						$self->save_selected_parameter;
						$self->build_edit_pane,
					}
				);
			}
		);
	} elsif ( $type eq 'list' ) {
		$widget = Gtk::Entry->new;
		$widget->set_text (join (", ", @{$par->{value}}));
		$widget->signal_connect(
			"changed", sub {
				my @list = split (/\s*,\s*/, $widget->get_text);
				$self->selected_parameter_value(\@list);
			}
		);

	} elsif ( $type eq 'file' ) {
		$widget = Gtk::Button->new ("Choose Filename");
		$widget->signal_connect(
			"clicked", sub {
				$self->show_file_dialog (
					dir => dirname($par->{value}),
					filename => $par->{value},
					title => $par->{description},
					confirm => 0,
					cb => sub {
						my ($filename) = @_;
						return if not -f $filename;
						$self->selected_parameter_value($filename);
						$self->save_selected_parameter;
						$self->build_edit_pane,
					}
				);
			}
		);

	} elsif ( $type eq 'bool' ) {
		$widget = Gtk::HBox->new (0, 10);
		my $yes_radio = Gtk::RadioButton->new("Yes");
		$yes_radio->show;
		$yes_radio->set_active(1) if $par->{value};
		$widget->pack_start($yes_radio, 0, 0, 0);
		my $no_radio =  Gtk::RadioButton->new("No", $yes_radio);
		$no_radio->show;
		$no_radio->set_active(1) if not $par->{value};
		$widget->pack_start($no_radio, 0, 0, 0);
		$yes_radio->signal_connect(
			"clicked", sub {
				$self->debug("select yes");
				$self->selected_parameter_value(1);
				$self->save_selected_parameter;
			}
		);
		$no_radio->signal_connect(
			"clicked", sub {
				$self->debug("select no");
				$self->selected_parameter_value(0);
				$self->save_selected_parameter;
			}
		);

	} elsif ($type eq 'html_color' ) {
		$widget = Gtk::Button->new ("Select Color");
		$widget->signal_connect(
			"clicked", sub {
				my $dialog = Gtk::ColorSelectionDialog->new ( $par->{description} );
				$dialog->position('center');
				$dialog->show;
				my $html_color = $self->selected_parameter_value;
				$html_color =~ s/^#//;
				my ($r, $g, $b) = ( $html_color =~ /(..)(..)(..)/ );
				my @color = (hex($r) / 255, hex($g) / 255,  hex($b) / 256);
				$dialog->colorsel->set_color(@color);
				$dialog->ok_button->signal_connect(
					"clicked", sub {
						my @color = $dialog->colorsel->get_color;
						my ($r, $g, $b);
						$self->dump(\@color);
						$r = int($color[0] * 255);
						$g = int($color[1] * 255);
						$b = int($color[2] * 255);

						$self->debug ($r, $g, $b);

						$r = uc( sprintf( "%lx", $r ) );
						$g = uc( sprintf( "%lx", $g ) );
						$b = uc( sprintf( "%lx", $b ) );

						$r = "0" . $r if ( $r =~ /^\d$/ );
						$g = "0" . $g if ( $g =~ /^\d$/ );
						$b = "0" . $b if ( $b =~ /^\d$/ );
						
						$self->selected_parameter_value("#".$r.$g.$b);
						$self->save_selected_parameter;
						$dialog->destroy;
						$self->build_edit_pane,
					},
				);
				$dialog->cancel_button->signal_connect(
					"clicked", sub {
						$dialog->destroy;
					},
				);
			}
		);

	} elsif ( $type eq 'font' ) {
		$widget = Gtk::Button->new ("Select Font");
		$widget->signal_connect(
			"clicked", sub {
				my $dialog = Gtk::FontSelectionDialog->new ( $par->{description} );
				$dialog->position('center');
				$dialog->show;
				$dialog->set_font_name($self->selected_parameter_value);
				$dialog->ok_button->signal_connect(
					"clicked", sub {
						my $font = $dialog->get_font_name;
						$self->selected_parameter_value($font);
						$self->save_selected_parameter;
						$dialog->destroy;
						$self->build_edit_pane,
					},
				);
				$dialog->cancel_button->signal_connect(
					"clicked", sub {
						$dialog->destroy;
					},
				);
			}
		);
	}	

	$widget->show;

	return $widget;
}

sub save_selected_parameter {
	my $self = shift; $self->trace_in;
	return if not $self->selected_parameter;
	
	$self->config_object->set_value(
		$self->selected_parameter,
		$self->selected_parameter_value
	);

	1;
}

1;
