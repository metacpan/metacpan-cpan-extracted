package Gtk::ColorSelectButton;

=head1 NAME

Gtk::ColorSelectButton - Choose a color

=head1 SYNOPSIS

	use Gtk;
    use Gtk::ColorSelectButton;
    
    ...
    init Gtk;
    init Gtk::ColorSelectButton;
    ...

    $color_button = Gtk::ColorSelectButton->new();
    $hbox->pack_start($color_button, 1,1,0);
    $color_button->show();

    ...
    print $color_button->color; #shortcut for ->get('color')
    ...
    $color_button->set( color => "10 40 250" ); # R G B

=head1 DESCRIPTION

Gtk::ColorSelectButton shows a button with a uniform color. Pressing
this buton pops up the color_selection dialog in which a new color
may be chosen. When the color selection dialog is closed, the chosen
color is reflected in the color of the button.

The gtk variable C<color> provides a way to access the chosen color.

=head1 AUTHOR

Dov Grobgeld <dov@imagic.weizmann.ac.il>, with modifications by
Kenneth Albanowski <kjahds@kjahds.com>.

=head1 COPYRIGHT

Copyright (c) 1998 Dov Grobgeld. All rights reserved. This program may
be redistributed and copied under the same licence as Perl itself.

=cut

use strict;
use vars qw($VERSION @ISA);
use Gtk;

$VERSION = "0.22";
@ISA = qw(Gtk::Button);

# Class defaults data
my @class_def_color = (255,175,0);

sub init {
	my($class) = shift;

	Gtk::Button->register_subtype($class);

}

sub GTK_CLASS_INIT {
	my($class) = shift;
	
	if (Gtk->major_version < 1 or (Gtk->major_version == 1 and Gtk->minor_version < 1)) {
		add_arg_type $class "color", "string", 3; #R/W
	} else {
		add_arg_type $class "color", "GtkString", 3; #R/W
	}
}

sub GTK_OBJECT_INIT {
    my (@color) = @class_def_color;
    
    my($color_button) = @_;
    
    $color_button->{_color} ||= [@color];

    my $preview = new Gtk::Preview -color;
    
    signal_connect $color_button "size_allocate" => sub {
    	my($self,$allocation) = @_;
    	my($x,$y,$w,$h) = @$allocation;
    	$w -= 6;
    	$h -= 6;
    	$self->{_preview_width} = $w;
    	$self->{_preview_height} = $h;
    	$self->{_preview}->size($w,$h);
    	update_color $self;
    };
    
    $color_button->{_preview} = $preview;
    $color_button->add($preview);
        
    signal_connect $color_button "clicked" => \&cb_color_button;
    
    $preview->show;
}

sub GTK_OBJECT_SET_ARG {
	my($self,$arg,$id, $value) = @_;
	$self->{_color} = [split(' ',$value)];
	$self->update_color;
}

sub GTK_OBJECT_GET_ARG {
	my($self,$arg,$id) = @_;
	return join(' ',@{$self->{_color}});
}

sub new {
    my $pkg = shift;
    return new Gtk::Widget $pkg, @_;
}

sub update_color($) {
    my($this) = shift;
    
    return unless defined $this->{_preview} and defined $this->{_preview_width};
    
    my($preview, $color) = ($this->{_preview}, $this->{_color});
    my($width, $height) = ($this->{_preview_width}, $this->{_preview_height});
    
    my($buf) = pack("C3", @$color) x $width;

    for(my $i=0;$i<$height;$i++) {
	$preview->draw_row($buf, 0, $i, $width);
    }
    $preview->draw(undef);
}

sub color_selection_ok {
    my($widget, $dialog, $color_button) = @_;
	
    my(@color) = $dialog->colorsel->get_color;
    @{$color_button->{_color}} = map(int(255.99*$_),@color);

	$color_button->update_color();
    $dialog->destroy();
    delete $color_button->{_cs_window};
}

sub cb_color_button {
    my($color_button) = @_;
    
    if (defined $color_button->{_cs_window}) {
    	if (!$color_button->{_cs_window}->mapped) {
	    	$color_button->{_cs_window}->hide;
	    }
    	$color_button->{_cs_window}->show;
    	$color_button->{_cs_window}->window->raise;
    	return;
    }

    my $cs_window=new Gtk::ColorSelectionDialog("Color");
    $cs_window->colorsel->set_color(map($_*1/255,@{$color_button->{_color}}));
    $cs_window->show();
    $cs_window->ok_button->signal_connect("clicked",
					  \&color_selection_ok,
					  $cs_window,
					  $color_button);
    $cs_window->cancel_button->signal_connect("clicked",
					      sub { $cs_window->destroy; delete $color_button->{_cs_window} });
	$color_button->{_cs_window} = $cs_window;
}

1;
