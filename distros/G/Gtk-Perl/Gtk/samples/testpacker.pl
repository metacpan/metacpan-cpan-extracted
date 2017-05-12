#!/usr/bin/perl -w

# Be warned, this thing is slightly out of whack...

#TITLE: Packer
#REQUIRES: Gtk



#use strict;
use Gtk;

sub destroy {
	my($widget) = @_;
	Gtk->main_quit;
}

sub main {

	my($info) = {};

	init Gtk;
	
	my($window) = new Gtk::Window -toplevel;
	
	$window->signal_connect( "destroy" => \&destroy);
	
	my($window_pack) = new Gtk::Packer;
	$window->add($window_pack);
	$window->border_width(4);
	
	my($top_pack) = new Gtk::Packer;
	$window_pack->add_defaults($top_pack, -top, -center, [-fill_x, -fill_y, -expand]);
	
	my($frame) = new Gtk::Frame("Packing Area");
	$frame->set_usize(400,400);
	$top_pack->add($frame, -left, -center, [-fill_x, -fill_y, -expand], 0, 8, 8, 0, 0);
	my($packer) = new Gtk::Packer;
	$frame->add($packer);
	
	my($button_pack) = new Gtk::Packer;
	$top_pack->add($button_pack, -left, -north, [], 
					0, 0, 0, 0, 0);
	
	my($button_add) = new Gtk::Button "Add Button";
	$top_pack->add($button_add, -top, -center, -fill_x, 0, 8, 8, 8, 0);
	$button_add->signal_connect(clicked => \&add_widget, $info);
	
	my($button_quit) = new Gtk::Button "Quit";
	$top_pack->add($button_quit, -top, -center, -fill_x, 0, 8, 8, 0, 0);
	$button_quit->signal_connect(clicked => sub { destroy $window });
	
	my($bottom_pack) = new Gtk::Packer;
	$window_pack->add_defaults($bottom_pack, -top, -center, -fill_x);
	
	my($side_frame) = new Gtk::Frame "Side";
	$window_pack->add($side_frame, -left, -west, -fill_y, 0, 10, 10, 0, 0);
	
	my($side_pack) = new Gtk::Packer;
	$side_frame->add($side_pack);
	
	my($button_top) = new Gtk::ToggleButton "Top";
	my($button_bottom) = new Gtk::ToggleButton "Bottom";
	my($button_left) = new Gtk::ToggleButton "Left";
	my($button_right) = new Gtk::ToggleButton "Rght";
	
	$button_top->{side} = -top;
	$button_bottom->{side} = -bottom;
	$button_left->{side} = -left;
	$button_right->{side} = -right;

	$button_top->set_usize(50, -1);
	$button_bottom->set_usize(50, -1);
	$button_left->set_usize(50, -1);
	$button_right->set_usize(50, -1);
	$side_pack->add($button_top, -top, -center, [], 0, 5, 5, 0, 0);
	$side_pack->add($button_bottom, -bottom, -center, [], 0, 5, 5, 0, 0);
	$side_pack->add($button_left, -left, -center, [], 0, 10, 5, 0, 0);
	$side_pack->add($button_right, -right, -center, [], 0, 10, 5, 0, 0);
	
	$button_top->signal_connect(toggled => \&toggle_side, $info);
	$button_bottom->signal_connect(toggled => \&toggle_side, $info);
	$button_left->signal_connect(toggled => \&toggle_side, $info);
	$button_right->signal_connect(toggled => \&toggle_side, $info);
	
	my($anchor_frame) = new Gtk::Frame "Anchor";
	$window_pack->add($anchor_frame, -left, -west, -fill_y, 0, 10, 10, 0, 0);
	
	my($anchor_pack) = new Gtk::Packer;
	$anchor_frame->add($anchor_pack);
	
	my($anchor_table) = new Gtk::Table(3, 3, 1);
	$anchor_pack->add($anchor_table, -top, -center, [-fill_y, -fill_x, -expand], 0, 10, 5, 0, 0);
	
	my($button_n) = new Gtk::ToggleButton "N";
	my($button_ne) = new Gtk::ToggleButton "NE";
	my($button_e) = new Gtk::ToggleButton "E";
	my($button_se) = new Gtk::ToggleButton "SE";
	my($button_s) = new Gtk::ToggleButton "S";
	my($button_sw) = new Gtk::ToggleButton "SW";
	my($button_w) = new Gtk::ToggleButton "W";
	my($button_nw) = new Gtk::ToggleButton "NW";
	my($button_center) = new Gtk::ToggleButton "";
	
	$button_n->{anchor} = "north";
	$button_ne->{anchor} = "ne";
	$button_e->{anchor} = "east";
	$button_se->{anchor} = "se";
	$button_s->{anchor} = "south";
	$button_sw->{anchor} = "sw";
	$button_w->{anchor} = "west";
	$button_nw->{anchor} = "nw";
	$button_center->{anchor} = "center";
	
	$button_n->signal_connect(toggled => \&toggle_anchor, $info);
	$button_ne->signal_connect(toggled => \&toggle_anchor, $info);
	$button_e->signal_connect(toggled => \&toggle_anchor, $info);
	$button_se->signal_connect(toggled => \&toggle_anchor, $info);
	$button_s->signal_connect(toggled => \&toggle_anchor, $info);
	$button_sw->signal_connect(toggled => \&toggle_anchor, $info);
	$button_w->signal_connect(toggled => \&toggle_anchor, $info);
	$button_nw->signal_connect(toggled => \&toggle_anchor, $info);
	$button_center->signal_connect(toggled => \&toggle_anchor, $info);
	
	$anchor_table->attach_defaults($button_nw, 0, 1, 0, 1);
	$anchor_table->attach_defaults($button_n, 1, 2, 0, 1);
	$anchor_table->attach_defaults($button_ne, 2, 3, 0, 1);
	$anchor_table->attach_defaults($button_w, 0, 1, 1, 2);
	$anchor_table->attach_defaults($button_center, 1, 2, 1, 2);
	$anchor_table->attach_defaults($button_e, 2, 3, 1, 2);
	$anchor_table->attach_defaults($button_sw, 0, 1, 2, 3);
	$anchor_table->attach_defaults($button_s, 1, 2, 2, 3);
	$anchor_table->attach_defaults($button_se, 2, 3, 2, 3);
	
	my($options_frame) = new Gtk::Frame "Options";
	$window_pack->add($options_frame, -left, -west, -fill_y, 0, 10, 10, 0, 0);
	
	my($options_pack) = new Gtk::Packer;
	$options_frame->add($options_pack);
	
	my($button_fillx) = new Gtk::ToggleButton "Fill X";
	my($button_filly) = new Gtk::ToggleButton "Fill Y";
	my($button_expand) = new Gtk::ToggleButton "Expand";
	
	$options_pack->add($button_fillx, -top, -north, [-fill_x, -expand], 0, 10, 5, 0, 0);
	$options_pack->add($button_filly, -top, -center, [-fill_x, -expand], 0, 10, 5, 0, 0);
	$options_pack->add($button_expand, -top, -south, [-fill_x, -expand], 0, 10, 5, 0, 0);
	
	$button_fillx->{option} = -fill_x;
	$button_filly->{option} = -fill_y;
	$button_expand->{option} = -expand;
	
	$button_fillx->signal_connect(toggled => \&toggle_options, $info);
	$button_filly->signal_connect(toggled => \&toggle_options, $info);
	$button_expand->signal_connect(toggled => \&toggle_options, $info);
	
	$info->{widgets} = [];
	$info->{packer} = $packer;
	$info->{button_top} = $button_top;
	$info->{button_bottom} = $button_bottom;
	$info->{button_left} = $button_left;
	$info->{button_right} = $button_right;
	$info->{button_n} = $button_n;
	$info->{button_ne} = $button_ne;
	$info->{button_e} = $button_e;
	$info->{button_se} = $button_se;
	$info->{button_s} = $button_s;
	$info->{button_sw} = $button_sw;
	$info->{button_w} = $button_w;
	$info->{button_nw} = $button_nw;
	$info->{button_center} = $button_center;
	$info->{button_fillx} = $button_fillx;
	$info->{button_filly} = $button_filly;
	$info->{button_expand} = $button_expand;
	
	add_widget(undef, $info);
	
	$window->show_all;
	
	Gtk->main;
	
	return 0;
}

main;

sub toggle_options {
	my($widget, $info) = @_;
	
	my($option, $fillx, $filly, $expand, $pchild, @options);
	
	$option = $widget->{option};
	
	if (not defined $info->{pchild}) {
		die;
	}
	
	$pchild = $info->{pchild};
	
	push @options, -fill_x if $info->{button_fillx}->active;
	push @options, -fill_y if $info->{button_filly}->active;
	push @options, -expand if $info->{button_expand}->active;
	
	$info->{packer}->configure($info->{current},
								$pchild->side,
								$pchild->anchor,
								\@options,
								$pchild->border_width,
								$pchild->pad_x,
								$pchild->pad_y,
								$pchild->ipad_x,
								$pchild->ipad_y);

}


sub toggle_anchor {
	my($widget,$info) = @_;
	
	if ($widget->active) {
		my($anchor) = $widget->{anchor};
		
		my($pchild) = $info->{pchild};
		if (not defined $pchild) {
			die;
		}
		
		$info->{packer}->configure($info->{current}, 
									$pchild->side,
									$anchor,
									$pchild->options,
									$pchild->border_width,
									$pchild->pad_x,
									$pchild->pad_y,
									$pchild->ipad_x,
									$pchild->ipad_y);

		foreach (	$info->{button_n},
					$info->{button_ne},
					$info->{button_e},
					$info->{button_se},
					$info->{button_s},
					$info->{button_sw},
					$info->{button_w},
					$info->{button_nw},
					$info->{button_center}
				) {
			if ($_ != $widget) {
				$_->set_state(0);
				$_->set_sensitive(1);
			}
		}
		
		$widget->set_sensitive(0);
		
	}
}

sub toggle_side {
	my($widget,$info) = @_;
	
	if ($widget->active) {
		my($side) = $widget->{side};
		
		my($pchild) = $info->{pchild};
		if (not defined $pchild) {
			die;
		}
		
		$info->{packer}->configure($info->{current}, 
									$side,
									$pchild->anchor,
									$pchild->options,
									$pchild->border_width,
									$pchild->pad_x,
									$pchild->pad_y,
									$pchild->ipad_x,
									$pchild->ipad_y);

		foreach (	$info->{button_top},
					$info->{button_bottom},
					$info->{button_left},
					$info->{button_right}
				) {
			if ($_ != $widget) {
				$_->set_state(0);
				$_->set_sensitive(1);
			}
		}
		
		$widget->set_sensitive(0);
		
	}
}

sub set_widget {
	my($w,$info) = @_;
	
	my($pchild);
	
	if ($w->active) {
		$info->{current} = $w;
		
		$pchild = undef;
		foreach ($info->{packer}->children) {
			if ($_->widget eq $info->{current}) {
				$pchild = $_;
				last;
			}
		}
		$info->{pchild} = $pchild;		
		
		$info->{button_top}->set_state(1) if $pchild->side eq "top";
		$info->{button_bottom}->set_state(1) if $pchild->side eq "bottom";
		$info->{button_left}->set_state(1) if $pchild->side eq "left";
		$info->{button_right}->set_state(1) if $pchild->side eq "right";

		$info->{button_north}->set_state(1) if $pchild->anchor eq "north";
		$info->{button_ne}->set_state(1) if $pchild->anchor eq "ne";
		$info->{button_east}->set_state(1) if $pchild->anchor eq "east";
		$info->{button_se}->set_state(1) if $pchild->anchor  eq "se";
		$info->{button_south}->set_state(1) if $pchild->anchor eq "south";
		$info->{button_sw}->set_state(1) if $pchild->anchor eq "sw";
		$info->{button_west}->set_state(1) if $pchild->anchor eq "west";
		$info->{button_nw}->set_state(1) if $pchild->anchor eq "nw";
		$info->{button_center}->set_state(1) if $pchild->anchor eq "center";
		
		$info->{button_expand}->set_state($pchild->options->{expand} || 0);
		$info->{button_fillx}->set_state($pchild->options->{fill_x} || 0);
		$info->{button_filly}->set_state($pchild->options->{fill_y} || 0);
		
		$w->set_sensitive(0);
		
		foreach (@{$info->{widgets}}) {
			next if $_ eq $info->{current};
			
			$_->set_state(0);
			$_->set_sensitive(1);
		}
		
	}
}

use vars '$add_widget_n';

sub add_widget {
	my($w, $info) = @_;
	
	my($packer) = $info->{packer};
	
	$main::add_widget_n ||= 0;
	
	my($widget) = new Gtk::ToggleButton "$main::add_widget_n";
	$widget->set_usize(50, 50);
	$packer->Gtk::Container::add($widget);
	$widget->show;
	
	$widget->signal_connect(toggled => \&set_widget, $info);
	
	push @{$info->{widgets}}, $widget;
	$widget->set_state(1);
	
	set_widget($widget, $info);
	
	$main::add_widget_n++;
	
}
