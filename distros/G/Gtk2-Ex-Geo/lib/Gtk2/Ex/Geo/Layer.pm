## @class Gtk2::Ex::Geo::Layer
# @brief A root class for visual geospatial layers
# @author Copyright (c) Ari Jolma
# @author This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself, either Perl version 5.8.5 or,
# at your option, any later version of Perl 5 you may have available.
package Gtk2::Ex::Geo::Layer;

=pod

=head1 NAME

Gtk2::Ex::Geo::Layer - A root class for visual geospatial layers

The <a href="http://geoinformatics.aalto.fi/doc/Geoinformatica/html/">
documentation of Gtk2::Ex::Geo</a> is written in doxygen format.

=cut

use strict;
use warnings;
use Scalar::Util qw(blessed);
use Carp;
use Glib qw /TRUE FALSE/;
use Gtk2::Ex::Geo::Dialogs;
use Gtk2::Ex::Geo::Dialogs::Symbols;
use Gtk2::Ex::Geo::Dialogs::Colors;
use Gtk2::Ex::Geo::Dialogs::Labeling;

use vars qw/%PALETTE_TYPE %GRAYSCALE_SUBTYPE %SYMBOL_TYPE %LABEL_PLACEMENT $SINGLE_COLOR/;

BEGIN {
    use Exporter 'import';
    our %EXPORT_TAGS = ( 'all' => [ qw(%PALETTE_TYPE %GRAYSCALE_SUBTYPE %SYMBOL_TYPE %LABEL_PLACEMENT) ] );
    our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
}

# default values for new objects

$SINGLE_COLOR = [0, 0, 0, 255];

# the integer values are the same as in libral visualization code:

%PALETTE_TYPE = ( 'Single color' => 0, 
		  Grayscale => 1, 
		  Rainbow => 2, 
		  'Color table' => 3, 
		  'Color bins' => 4,
		  'Red channel' => 5, 
		  'Green channel' => 6, 
		  'Blue channel' => 7,
    );

%GRAYSCALE_SUBTYPE = ( Gray => 0,
		       Hue => 1,
		       Saturation => 2,
		       Value => 3,
		       Opacity => 4,
    );

%SYMBOL_TYPE = ( 'No symbol' => 0, 
		 'Flow_direction' => 1, 
		 Square => 2, 
		 Dot => 3, 
		 Cross => 4, 
		 'Wind rose' => 6,
    );

%LABEL_PLACEMENT = ( 'Center' => 0, 
		     'Center left' => 1, 
		     'Center right' => 2, 
		     'Top left' => 3, 
		     'Top center' => 4, 
		     'Top right' => 5, 
		     'Bottom left' => 6, 
		     'Bottom center' => 7, 
		     'Bottom right' => 8,
    );

## @cmethod registration()
# @brief Returns the dialogs and commands implemented by this layer
# class.
#
# The dialogs is an object of a subclass of
# Gtk2::Ex::Geo::DialogMaster. The commands is a reference to a
# command hash. The keys of the command hash are top-level commands
# for the GUI. The value of the command is a reference to a hash,
# which has keys: nr, text, tip, pos, and sub. The 'sub' is a
# reference to a subroutine, which is executed when the user executes
# the command. The commands are currently implemented as buttons in
# Gtk2::Ex::Geo::Glue.
#
# @return an anonymous hash containing the dialogs (key: 'dialogs')
# and commands (key: 'commands')
sub registration {
    my($glue) = @_;
    if ($glue->{resources}{icons}{dir}) {
	#print STDERR "reg: @{$glue->{resources}{icons}{dir}}\n";
    }
    my $dialogs = Gtk2::Ex::Geo::Dialogs->new();
    return { dialogs => $dialogs };
}

## @cmethod @palette_types()
#
# @brief Returns a list of valid palette types (strings).
# @return a list of valid palette types (strings).
sub palette_types {
    return sort {$PALETTE_TYPE{$a} <=> $PALETTE_TYPE{$b}} keys %PALETTE_TYPE;
}

## @cmethod @symbol_types()
#
# @brief Returns a list of valid symbol types (strings).
# @return a list of valid symbol types (strings).
sub symbol_types {
    return sort {$SYMBOL_TYPE{$a} <=> $SYMBOL_TYPE{$b}} keys %SYMBOL_TYPE;
}

## @cmethod @label_placements()
#
# @brief Returns a list of valid label_placements (strings).
# @return a list of valid label_placements (strings).
sub label_placements {
    return sort {$LABEL_PLACEMENT{$a} <=> $LABEL_PLACEMENT{$b}} keys %LABEL_PLACEMENT;
}

## @cmethod $upgrade($object) 
#
# @brief Upgrade a known data object to a layer object.
#
# @return true (either 1 or a new object) if object is known (no need
# to look further) and false otherwise.
sub upgrade {
    my($object) = @_;
    return 0;
}

## @cmethod new(%params)
# @brief constructs a new layer object or blesses an object into a layer class
# Calls defaults with the given parameters.
sub new {
    my($class, %params) = @_;
    my $self = $params{self} ? $params{self} : {};
    bless $self => (ref($class) or $class);
    $self->defaults(%params);
    return $self;
}

## @method defaults(%params)
# @brief assigns default values to attributes
# The default values are hard-coded, but they can be overridden with
# given values.  The given values are lower case.
# @todo: document the attributes
sub defaults {
    my($self, %params) = @_;

    # set defaults for all

    $self->{NAME} = '' unless exists $self->{NAME};
    $self->{ALPHA} = 255 unless exists $self->{ALPHA};
    $self->{VISIBLE} = 1 unless exists $self->{VISIBLE};
    $self->{PALETTE_TYPE} = 'Single color' unless exists $self->{PALETTE_TYPE};

    $self->{SYMBOL_TYPE} = 'No symbol' unless exists $self->{SYMBOL_TYPE};
    # symbol size is also the max size of the symbol, if symbol_scale is used
    $self->{SYMBOL_SIZE} = 5 unless exists $self->{SYMBOL_SIZE}; 
    # symbol scale is similar to grayscale scale
    $self->{SYMBOL_SCALE_MIN} = 0 unless exists $self->{SYMBOL_SCALE_MIN}; 
    $self->{SYMBOL_SCALE_MAX} = 0 unless exists $self->{SYMBOL_SCALE_MAX};

    $self->{HUE_AT_MIN} = 235 unless exists $self->{HUE_AT_MIN}; # as in libral visual.h
    $self->{HUE_AT_MAX} = 0 unless exists $self->{HUE_AT_MAX}; # as in libral visual.h
    $self->{INVERT} = 0 unless exists $self->{HUE_DIR}; # inverted scale or not; RGB is not inverted
    $self->{GRAYSCALE_SUBTYPE} = 'Gray' unless exists $self->{GRAYSCALE_SUBTYPE}; # grayscale is gray scale

    @{$self->{GRAYSCALE_COLOR}} = @$SINGLE_COLOR unless exists $self->{GRAYSCALE_COLOR};

    @{$self->{SINGLE_COLOR}} = @$SINGLE_COLOR unless exists $self->{SINGLE_COLOR};

    $self->{COLOR_TABLE} = [] unless exists $self->{COLOR_TABLE};
    $self->{COLOR_BINS} = [] unless exists $self->{COLOR_BINS};

    # scales are used in rendering in some palette types
    $self->{COLOR_SCALE_MIN} = 0 unless exists $self->{COLOR_SCALE_MIN};
    $self->{COLOR_SCALE_MAX} = 0 unless exists $self->{COLOR_SCALE_MAX};

    # focus field is used in rendering and rasterization
    # this is the name of the field
    $self->{COLOR_FIELD} = '' unless exists $self->{COLOR_FIELD};
    $self->{SYMBOL_FIELD} = 'Fixed size' unless exists $self->{SYMBOL_FIELD};
    $self->{LABEL_FIELD} = 'No Labels'  unless exists $self->{LABEL_FIELD};

    $self->{LABEL_PLACEMENT} = 'Center' unless exists $self->{LABEL_PLACEMENT};
    $self->{LABEL_FONT} = 'sans 12' unless exists $self->{LABEL_FONT};
    $self->{LABEL_COLOR} = [0, 0, 0, 255] unless exists $self->{LABEL_COLOR};
    $self->{LABEL_MIN_SIZE} = 0 unless exists $self->{LABEL_MIN_SIZE};
    $self->{INCREMENTAL_LABELS} = 0 unless exists $self->{INCREMENTAL_LABELS};
    $self->{LABEL_VERT_NUDGE} = 0.3 unless exists $self->{LABEL_VERT_NUDGE};
    $self->{LABEL_HORIZ_NUDGE_LEFT} = 6 unless exists $self->{LABEL_HORIZ_NUDGE_LEFT};
    $self->{LABEL_HORIZ_NUDGE_RIGHT} = 10 unless exists $self->{LABEL_HORIZ_NUDGE_RIGHT};

    $self->{BORDER_COLOR} = [] unless exists $self->{BORDER_COLOR};

    $self->{SELECTED_FEATURES} = [];
    
    $self->{RENDERER} = 0; # the default, later 'Cairo' will be implemented fully
  
    # set from input
    
    $self->{NAME} = $params{name} if exists $params{name};
    $self->{ALPHA} = $params{alpha} if exists $params{alpha};
    $self->{VISIBLE} = $params{visible} if exists $params{visible};
    $self->{PALETTE_TYPE} = $params{palette_type} if exists $params{palette_type};
    $self->{SYMBOL_TYPE} = $params{symbol_type} if exists $params{symbol_type};
    $self->{SYMBOL_SIZE} = $params{symbol_size} if exists $params{symbol_size};
    $self->{SYMBOL_SCALE_MIN} = $params{scale_min} if exists $params{scale_min};
    $self->{SYMBOL_SCALE_MAX} = $params{scale_max} if exists $params{scale_max};
    $self->{HUE_AT_MIN} = $params{hue_at_min} if exists $params{hue_at_min};
    $self->{HUE_AT_MAX} = $params{hue_at_max} if exists $params{hue_at_max};
    $self->{INVERT} = $params{invert} if exists $params{invert};
    $self->{SCALE} = $params{scale} if exists $params{scale};
    @{$self->{GRAYSCALE_COLOR}} = @{$params{grayscale_color}} if exists $params{grayscale_color};
    @{$self->{SINGLE_COLOR}} = @{$params{single_color}} if exists $params{single_color};
    $self->{COLOR_TABLE} = $params{color_table} if exists $params{color_table};
    $self->{COLOR_BINS} = $params{color_bins} if exists $params{color_bins};
    $self->{COLOR_SCALE_MIN} = $params{color_scale_min} if exists $params{color_scale_min};
    $self->{COLOR_SCALE_MAX} = $params{color_scale_max} if exists $params{color_scale_max};
    $self->{COLOR_FIELD} = $params{color_field} if exists $params{color_field};
    $self->{SYMBOL_FIELD} = $params{symbol_field} if exists $params{symbol_field};
    $self->{LABEL_FIELD} = $params{label_field} if exists $params{label_field};
    $self->{LABEL_PLACEMENT} = $params{label_placement} if exists $params{label_placement};
    $self->{LABEL_FONT} = $params{label_font} if exists $params{label_font};
    @{$self->{LABEL_COLOR}} = @{$params{label_color}} if exists $params{label_color};
    $self->{LABEL_MIN_SIZE} = $params{label_min_size} if exists $params{label_min_size};
    @{$self->{BORDER_COLOR}} = @{$params{border_color}} if exists $params{border_color};

}

##@ignore
sub DESTROY {
    my $self = shift;
    while (my($key, $widget) = each %$self) {
	$widget->destroy if blessed($widget) and $widget->isa("Gtk2::Widget");
	delete $self->{$key};
    }
}

## @method close($gui)
# @brief Close and destroy all resources of this layer, as it has been
# removed from the GUI.
#
# If you override this, remember to call the super method:
# @code
# $self->SUPER::close(@_);
# @endcode
sub close {
    my($self, $gui) = @_;
    for (keys %$self) {
	if (blessed($self->{$_}) and $self->{$_}->isa("Gtk2::GladeXML")) {
	    $self->{$_}->get_widget($_)->destroy;
	}
	delete $self->{$_};
    }
}

## @method $type($format)
#
# @brief Reports the type of the layer class for the GUI (short but human readable code).
# @param format (optional) If 'tooltip' returns a string suitable for tooltip.
# @return a string.
sub type {
    my $self = shift;
    return '?';
}

## @method $name($name)
#
# @brief Get or set the name of the layer. Also a callback function. 
# @param[in] name (optional) Layers name.
# @return Name of layer, if no name is given to the method.
sub name {
    my($self, $name) = @_;
    defined $name ? $self->{NAME} = $name : $self->{NAME};
}

## @method $alpha($alpha)
#
# @brief Get or set the alpha (transparency) of the layer.
# @param[in] alpha (optional) Layers alpha channels value (0 ... 255).
# @return Current alpha value, if no parameter is given.
sub alpha {
    my($self, $alpha) = @_;
    if (defined $alpha) {
	$alpha = 0 if $alpha < 0;
	$alpha = 255 if $alpha > 255;
	$self->{ALPHA} = $alpha;
    }
    $self->{ALPHA};
}

## @method visible($visible)
# 
# @brief Show or hide the layer.
# @param visible If true then the layer is made visible, else hidden.
sub visible {
    my($self, $visible) = @_;
    defined $visible ? $self->{VISIBLE} = $visible : $self->{VISIBLE};
}

## @method got_focus($gui)
#
# @brief Called by the GUI when this layer has received the focus.
sub got_focus {
    my($self, $gui) = @_;
}

## @method lost_focus($gui)
#
# @brief Called by the GUI when this layer has lost the focus.
sub lost_focus {
    my($self, $gui) = @_;
}

## @method border_color($red, $green, $blue)
# @brief Set or get the border color of the features.
# @code
# $self->border_color($red, $green, $blue); # set 
# $self->border_color(); # clear, no border
# @color = $self->border_color(); # get
# @endcode
sub border_color {
    my($self, @color) = @_;
    @{$self->{BORDER_COLOR}} = @color if @color;
    return @{$self->{BORDER_COLOR}} if defined wantarray;
    @{$self->{BORDER_COLOR}} = () unless @color;
}

## @method inspect_data
# @brief Return data for the inspect window.
sub inspect_data {
    my $self = shift;
    return $self;
}

## @method void properties_dialog(Gtk2::Ex::Glue gui)
# 
# @brief A request to invoke the properties dialog for this layer object.
# @param gui A Gtk2::Ex::Glue object (contains predefined dialogs).
sub open_properties_dialog {
    my($self, $gui) = @_;
}

## @method void open_features_dialog($gui, $soft_open)
# 
# @brief A request to invoke a features dialog for this layer object.
# @param gui A Gtk2::Ex::Glue object (contains predefined dialogs).
# @param soft_open Whether to "soft open", i.e., reset an already open dialog.
sub open_features_dialog {
    my($self, $gui, $soft_open) = @_;
}

## @method arrayref menu_items()
#
# @brief Return menu items for the layer menu.
#
# A menu item consists of an entry and action. The action may be an
# anonymous subroutine or FALSE, in which case a separator item is
# added. A '_' in front of a letter makes that letter a shortcut key
# for the item. The final layer menu is composed of entries added by
# Glue.pm, and all classes in the layers lineage. The subroutine is
# called with [$self, $gui] as user data.
#
# @todo add machinery for multiselection.
#
# @return a reference to the items array.
sub menu_items {
    my($self) = @_;
    my @items;
    push @items, (
	'_Unselect all' => sub {
	    my($self, $gui) = @{$_[1]};
	    $self->select;
	    $gui->{overlay}->update_image;
	    $self->open_features_dialog($gui, 1);
	},
	'_Symbol...' => sub {
	    my($self, $gui) = @{$_[1]};
	    $self->open_symbols_dialog($gui);
	},
	'_Colors...' => sub {
	    my($self, $gui) = @{$_[1]};
	    $self->open_colors_dialog($gui);
	},
	'_Labeling...' => sub {
	    my($self, $gui) = @{$_[1]};
	    $self->open_labeling_dialog($gui);
	},
	'_Inspect...' => sub {
	    my($self, $gui) = @{$_[1]};
	    $gui->inspect($self->inspect_data, $self->name);
	},
	'_Properties...' => sub {
	    my($self, $gui) = @{$_[1]};
	    $self->open_properties_dialog($gui);
	}
    );
    return @items;
}

sub open_symbols_dialog {
    Gtk2::Ex::Geo::Dialogs::Symbols::open(@_);
}
sub open_colors_dialog {
    Gtk2::Ex::Geo::Dialogs::Colors::open(@_);
}
sub open_labeling_dialog {
    Gtk2::Ex::Geo::Dialogs::Labeling::open(@_);
}

## @method $palette_type($palette_type)
#
# @brief Get or set the palette type.
# @param[in] palette_type (optional) New palette type to set to the layer.
# @return The current palette type of the layer.
sub palette_type {
    my($self, $palette_type) = @_;
    if (defined $palette_type) {
	croak "Unknown palette type: $palette_type" unless defined $PALETTE_TYPE{$palette_type};
	$self->{PALETTE_TYPE} = $palette_type;
    } else {
	return $self->{PALETTE_TYPE};
    }
}

## @method @supported_palette_types()
#
# The palette type is set by the user and the layer class is expected
# to understand its own types in its render method.
# 
# @brief Return a list of all by this class supported palette types.
# @return A list of all by this class supported palette types.
sub supported_palette_types {
    my($class) = @_;
    my @ret;
    for my $t (sort {$PALETTE_TYPE{$a} <=> $PALETTE_TYPE{$b}} keys %PALETTE_TYPE) {
	push @ret, $t;
    }
    return @ret;
}

## @method $symbol_type($type)
#
# @brief Get or set the symbol type.
# @param[in] type (optional) New symbol type to set to the layer.
# @return The current symbol type of the layer.
sub symbol_type {
    my($self, $symbol_type) = @_;
    if (defined $symbol_type) {
	croak "Unknown symbol type: $symbol_type" unless defined $SYMBOL_TYPE{$symbol_type};
	$self->{SYMBOL_TYPE} = $symbol_type;
    } else {
	return $self->{SYMBOL_TYPE};
    }
}

## @method @supported_symbol_types()
# 
# @brief Return a list of all symbol types that this class supports.
# @return A list of all by this class supported symbol types.
sub supported_symbol_types {
    my($self) = @_;
    my @ret;
    for my $t (sort {$SYMBOL_TYPE{$a} <=> $SYMBOL_TYPE{$b}} keys %SYMBOL_TYPE) {
	push @ret, $t;
    }
    return @ret;
}

## @method $symbol_size($size)
# 
# @brief Get or set the symbol size.
# @param[in] size (optional) The layers symbols new size.
# @return The current size of the layers symbol.
# @note Even if the layer has at the moment no symbol, the symbol size can be 
# defined.
sub symbol_size {
    my($self, $size) = @_;
    defined $size ?
	$self->{SYMBOL_SIZE} = $size+0 :
	$self->{SYMBOL_SIZE};
}

## @method @symbol_scale($scale_min, $scale_max)
# 
# @brief Get or set the symbol scale.
# @param[in] scale_min (optional) The layers symbols new minimum scale. Scale under
# which the symbol is hidden even if the layer is visible.
# @param[in] scale_max (optional) The layers symbols new maximum scale. Scale over
# which the symbol is hidden even if the layer is visible.
# @return The current scale minimum and maximum of the layers symbol.
# @note Even if the layer has at the moment no symbol, the symbol scales can be 
# defined.
sub symbol_scale {
    my($self, $min, $max) = @_;
    if (defined $min) {
		$self->{SYMBOL_SCALE_MIN} = $min+0;
		$self->{SYMBOL_SCALE_MAX} = $max+0;
    }
    return ($self->{SYMBOL_SCALE_MIN}, $self->{SYMBOL_SCALE_MAX});
}

## @method @hue_range($min, $max, $dir)
#
# @brief Determines the hue range
# @param min The minimum hue value.
# @param max The maximum hue value.
# @param dir (1 or -1) Determines whether the rainbow is from min to
# max (hue increases, red->green->blue), or from max to min (hue
# decreases, red->blue->green). Default is increase.
sub hue_range {
    my($self, $min, $max, $dir) = @_;
    if (defined $min) {
		$self->{HUE_AT_MIN} = $min+0;
		$self->{HUE_AT_MAX} = $max+0;
		$self->{INVERT} = (!(defined $dir) or $dir == 1) ? 0 : 1;
    }
    return ($self->{HUE_AT_MIN}, $self->{HUE_AT_MAX}, $self->{INVERT} ? -1 : 1);
}

## @method $grayscale_subtype($subtype)
#
# @brief Get or set the subtype of grayscale palette.
# @param subtype (optional) The subtype (one of %GRAYSCALE_SUBTYPE).
# @return Returns the subtype.
sub grayscale_subtype {
    my($self, $scale) = @_;
    if (defined $scale) {
	croak "unknown grayscale subtype: $scale" unless exists $GRAYSCALE_SUBTYPE{$scale};
	$self->{GRAYSCALE_SUBTYPE} = $scale;
    } else {
	$self->{GRAYSCALE_SUBTYPE};
    }
}

## @method $invert_scale($invert)
#
# @brief Get or set the invertedness attribute of grayscale palette.
# @param invert (optional) True or false.
# @return Returns the invertedness.
sub invert_scale {
    my($self, $invert) = @_;
    if (defined $invert) {
	$self->{INVERT} = $invert and 1;
    } else {
	$self->{INVERT};
    }
}

## @method @grayscale_color(@rgba)
#
# @brief Get or set the color, which is used as the base color for grayscale palette.
# @param[in] rgba (optional) A list of channels defining the RGBA color.
# @return The current color.
# @exception Croaks unless exactly all four channels are specified.
sub grayscale_color {
    my $self = shift;
    croak "@_ is not a RGBA color" if @_ and @_ != 4;
    $self->{GRAYSCALE_COLOR} = [@_] if @_;
    return @{$self->{GRAYSCALE_COLOR}};
}

## @method $symbol_field($field_name)
#
# @brief Get or set the field, which is used for determining the size of the 
# symbol.
# @param[in] field_name (optional) Name of the field determining symbol size.
# @return Name of the field determining symbol size.
# @exception If field name is given as a parameter, but the field does not 
# exist in the layer.
sub symbol_field {
    my($self, $field_name) = @_;
    if (defined $field_name) {
	if ($field_name eq 'Fixed size' or $self->schema->field($field_name)) {
	    $self->{SYMBOL_FIELD} = $field_name;
	} else {
	    croak "Layer ".$self->name()." does not have field with name: $field_name";
	}
    }
    return $self->{SYMBOL_FIELD};
}

## @method @single_color(@rgba)
#
# @brief Get or set the color, which is used if palette is 'single color'
# @param[in] rgba (optional) A list of channels defining the RGBA color.
# @return The current color.
# @exception Croaks unless exactly all four channels are specified.
sub single_color {
    my $self = shift;
    croak "@_ is not a RGBA color" if @_ and @_ != 4;
    $self->{SINGLE_COLOR} = [@_] if @_;
    return @{$self->{SINGLE_COLOR}};
}

## @method @color_scale($scale_min, $scale_max)
# 
# @brief Get or set the range, which is used for coloring in continuous palette 
# types.
# @param[in] scale_min (optional) The layers colors new minimum scale. Scale under
# which the color is not shown even if the layer is visible.
# @param[in] scale_max (optional) The layers colors new maximum scale. Scale over
# which the color is not shown even if the layer is visible.
# @return The current scale minimum and maximum of the layers color.
sub color_scale {
    my($self, $min, $max) = @_;
    if (defined $min) {
	$min = 0 unless $min;
	$max = 0 unless $max;
	$self->{COLOR_SCALE_MIN} = $min;
	$self->{COLOR_SCALE_MAX} = $max;
    }
    return ($self->{COLOR_SCALE_MIN}, $self->{COLOR_SCALE_MAX});
}

## @method $color_field($field_name)
#
# @brief Get or set the field, which is used for determining the color.
# @param[in] field_name (optional) Name of the field determining color.
# @return Name of the field determining color.
# @exception If field name is given as a parameter, but the field does not 
# exist in the layer.
sub color_field {
    my($self, $field_name) = @_;
    if (defined $field_name) {
	if ($self->schema->field($field_name)) {
	    $self->{COLOR_FIELD} = $field_name;
	} else {
	    croak "Layer ", $self->name, " does not have field: $field_name";
	}
    }
    return $self->{COLOR_FIELD};
}

## @method @color_table($color_table)
#
# @brief Get or set the color table.
# @param[in] color_table (optional) Name of file from where the color table can be 
# read.
# @return Current color table, if no parameter is given.
# @exception A filename is given, which can't be opened/read or does not have a 
# color table.

## @method @color_table(Geo::GDAL::ColorTable color_table)
#
# @brief Get or set the color table.
# @param[in] color_table (optional) Geo::GDAL::ColorTable.
# @return Current color table, if no parameter is given.

## @method @color_table(listref color_table)
#
# @brief Get or set the color table.
# @param[in] color_table (optional) Reference to an array having the color table.
# @return Current color table, if no parameter is given.
sub color_table {
    my($self, $color_table) = @_;
    unless (defined $color_table) 
    {
	$self->{COLOR_TABLE} = [] unless $self->{COLOR_TABLE};
	return $self->{COLOR_TABLE};
    }
    if (ref($color_table) eq 'ARRAY') 
    {
	$self->{COLOR_TABLE} = [];
	for (@$color_table) {
	    push @{$self->{COLOR_TABLE}}, [@$_];
	}
    } elsif (ref($color_table)) 
    {
	$self->{COLOR_TABLE} = [];
	for my $i (0..$color_table->GetCount-1) {
	    my @color = $color_table->GetColorEntryAsRGB($i);
	    push @{$self->{COLOR_TABLE}}, [$i, @color];
	}
    } else 
    {
	open(my $fh, '<', $color_table) or croak "can't read from $color_table: $!";
	$self->{COLOR_TABLE} = [];
	while (<$fh>) {
	    next if /^#/;
	    my @tokens = split /\s+/;
	    next unless @tokens > 3;
	    $tokens[4] = 255 unless defined $tokens[4];
	    #print STDERR "@tokens\n";
	    for (@tokens[1..4]) {
		$_ =~ s/\D//g;
	    }
	    #print STDERR "@tokens\n";
	    for (@tokens[1..4]) {
		$_ = 0 if $_ < 0;
		$_ = 255 if $_ > 255;
	    }
	    #print STDERR "@tokens\n";
	    push @{$self->{COLOR_TABLE}}, \@tokens;
	}
	CORE::close($fh);
    }
}

## @method color($index, @XRGBA)
#
# @brief Get or set the single color or a color in a color table or
# bins. The index is an index to the table and not a color table index
# or upper limit of a bin (the X is) and is not to be given to set the
# single color.
sub color {
    my $self = shift;
    my $index = shift unless $self->{PALETTE_TYPE} eq 'Single color';
    my @color = @_ if @_;
    if (@color) {
	if ($self->{PALETTE_TYPE} eq 'Color table') {
	    $self->{COLOR_TABLE}[$index] = \@color;
	} elsif ($self->{PALETTE_TYPE} eq 'Color bins') {
	    $self->{COLOR_BINS}[$index] = \@color;
	} else {
	    $self->{SINGLE_COLOR} = \@color;
	}
    } else {
	if ($self->{PALETTE_TYPE} eq 'Color table') {
	    @color = @{$self->{COLOR_TABLE}[$index]};
	} elsif ($self->{PALETTE_TYPE} eq 'Color bins') {
	    @color = @{$self->{COLOR_BINS}[$index]};
	} else {
	    @color = @{$self->{SINGLE_COLOR}};
	}
    }
    return @color;
}

## @method add_color($index, @XRGBA)
# @brief Add color to color table or color bins at given index.
sub add_color {
    my($self, $index, @XRGBA) = @_;
    if ($self->{PALETTE_TYPE} eq 'Color table') {
	splice @{$self->{COLOR_TABLE}}, $index, 0, [@XRGBA];
    } else {
	splice @{$self->{COLOR_BINS}}, $index, 0, [@XRGBA];
    }
}

## @method remove_color($index)
# @brief Remove color from color table or color bins at given index.
sub remove_color {
    my($self, $index) = @_;
    if ($self->{PALETTE_TYPE} eq 'Color table') {
	splice @{$self->{COLOR_TABLE}}, $index, 1;
    } else {
	splice @{$self->{COLOR_BINS}}, $index, 1;
    }
}


## @method save_color_table($filename)
#
# @brief Saves the layers color table into the file, which name is given as 
# parameter.
# @param[in] filename Name of file where the color table is saved.
# @exception A filename is given, which can't be written to.
sub save_color_table {
    my($self, $filename) = @_;
    open(my $fh, '>', $filename) or croak "can't write to $filename: $!";
    for my $color (@{$self->{COLOR_TABLE}}) {
	print $fh "@$color\n";
    }
    CORE::close($fh);
}

## @method @color_bins($color_bins)
#
# @brief Get or set the color bins.
# @param[in] color_bins (optional) Name of file from where the color bins can be 
# read.
# @return The current color bins if no parameter is given.
# @exception A filename is given, which can't be opened/read or does not have 
# the color bins.

## @method @color_bins(listref color_bins)
#
# @brief Get or set the color bins.
# @param[in] color_bins (optional) Array including the color bins.
# @return The current color bins if no parameter is given.
sub color_bins {
    my($self, $color_bins) = @_;
    unless (defined $color_bins) {
	$self->{COLOR_BINS} = [] unless $self->{COLOR_BINS};
	return $self->{COLOR_BINS};
    }
    if (ref($color_bins) eq 'ARRAY') {
	$self->{COLOR_BINS} = [];
	for (@$color_bins) {
	    push @{$self->{COLOR_BINS}}, [@$_];
	}
    } else {
	open(my $fh, '<', $color_bins) or croak "can't read from $color_bins: $!";
	$self->{COLOR_BINS} = [];
	while (<$fh>) {
	    next if /^#/;
	    my @tokens = split /\s+/;
	    next unless @tokens > 3;
	    $tokens[4] = 255 unless defined $tokens[4];
	    for (@tokens[1..4]) {
		$_ =~ s/\D//g;
		$_ = 0 if $_ < 0;
		$_ = 255 if $_ > 255;
	    }
	    push @{$self->{COLOR_BINS}}, \@tokens;
	}
	CORE::close($fh);
    }
}

## @method save_color_bins($filename)
#
# @brief Saves the layers color bins into the file, which name is given as 
# parameter.
# @param[in] filename Name of file where the color bins are saved.
# @exception A filename is given, which can't be written to.
sub save_color_bins {
    my($self, $filename) = @_;
    open(my $fh, '>', $filename) or croak "can't write to $filename: $!";
    for my $color (@{$self->{COLOR_BINS}}) {
	print $fh "@$color\n";
    }
    CORE::close($fh);
}

## @method hashref labeling($labeling)
#
# @brief Sets the labeling for the layer.
# @param[in] labeling An anonymous hash containing the labeling: 
# { field => , font => , color => [r, g, b, a], min_size => }
# @return labeling in an anonymous hash
sub labeling {
    my($self, $labeling) = @_;
    if ($labeling) {
	$self->{LABEL_FIELD} = $labeling->{field};
	$self->{LABEL_PLACEMENT} = $labeling->{placement};
	$self->{LABEL_FONT} = $labeling->{font};
	@{$self->{LABEL_COLOR}} =@{$labeling->{color}};
	$self->{LABEL_MIN_SIZE} = $labeling->{min_size};
        $self->{INCREMENTAL_LABELS} = $labeling->{incremental};
    } else {
	$labeling = {};
	$labeling->{field} = $self->{LABEL_FIELD};
	$labeling->{placement} = $self->{LABEL_PLACEMENT};
	$labeling->{font} = $self->{LABEL_FONT};
	@{$labeling->{color}} = @{$self->{LABEL_COLOR}};
	$labeling->{min_size} = $self->{LABEL_MIN_SIZE};
        $labeling->{incremental} = $self->{INCREMENTAL_LABELS};
    }
    return $labeling;
}

## @method select(%params)
#
# @brief Select features based on user input.
# @param params named params, the key is something that is recognized by the features method
# and the value is a geometry the user has defined
# - <I>key</I> A Geo::OGR::Geometry object representing the point or area the user has selected
# The key, value pair is fed as such to features subroutine. 
# A call without parameters deselects all features.
sub select {
    my($self, %params) = @_;
    if (@_ > 1) {
	for my $key (keys %params) {
	    my $features = $self->features($key => $params{$key});
	    $self->selected_features($features);
	}
    } else {
	$self->{SELECTED_FEATURES} = [];
    }
}

## @method $select($selected)
# @brief Get or set the selected features.
#
# @param selected Reference to an array of features that will be the
# array of selected features.
# @return Reference to the array of selected features.
sub selected_features {
    my($self, $selected) = @_;
    if (@_ > 1) {
	$self->{SELECTED_FEATURES} = $selected;
    }
    return $self->{SELECTED_FEATURES};
}

## @method $features(%params)
# @brief Virtual method called from select.
#
# @param params As in select.
# @return A reference to an array of matching features.
sub features {
}

sub has_features_with_borders {
    return 0;
}

## @method schema()
#
# @brief Return the schema of the layer as an anonymous hash. 
#
# For the structure of the schema hash see Geo::Vector::schema
sub schema {
    my $schema = Gtk2::Ex::Geo::Schema->new;
    return $schema;
}

## @class Gtk2::Ex::Geo::Schema
# @brief A class for layer schemas.
package Gtk2::Ex::Geo::Schema;

sub new {
    my $package = shift;
    my $self = { GeometryType => 'Unknown',
		 Fields => [], };
    bless $self => (ref($package) or $package);
}

## @ignore
sub fields {
    my $schema = shift;
    my @fields = (
	{ Name => '.FID', Type => 'Integer' },
	{ Name => '.GeometryType', Type => $schema->{GeometryType} }
	);
    push @fields, { Name => '.Z', Type => 'Real' } if $schema->{GeometryType} =~ /25/;
    push @fields, @{$schema->{Fields}};
    return @fields;
}

## @ignore
sub field_names {
    my $schema = shift;
    my @names = ('.FID', '.GeometryType');
    push @names, '.Z' if $schema->{GeometryType} =~ /25/;
    for my $f (@{$schema->{Fields}}) {
	push @names, $f->{Name};
    }
    return @names;
}

## @ignore
sub field {
    my($schema, $field_name) = @_;
    if ($field_name eq '.FID') {
	return { Name => '.FID', Type => 'Integer' };
    }
    if ($field_name eq '.GeometryType') {
	return { Name => '.GeometryType', Type => 'String' };
    }
    if ($field_name eq '.Z') {
	return { Name => '.Z', Type => 'Real' };
    }
    my $i = 0;
    for my $f (@{$schema->{Fields}}) {
	return $f if $field_name eq $f->{Name};
	$i++;
    }
}

## @ignore
sub field_index {
    my($schema, $field_name) = @_;
    my $i = 0;
    for my $f (@{$schema->{Fields}}) {
	if ($field_name eq $f->{Name}) {
	    return $i;
	}
	$i++;
    }
}

package Gtk2::Ex::Geo::Layer;

sub value_range {
    return (0, 0);
}

## @method @world()
#
# @brief A callback function. Return the bounding box.
# @return (minx, miny, maxx, maxy)

## @method render($pb, $cr, $overlay, $viewport)
#
# @brief A callback function. Render the layer.
# @param pb Gtk2::Gdk::Pixbuf object
# @param cr Cairo context
# @param overlay Gtk2::Ex::Geo::Overlay object
# @param viewport The pixbuf / cairo surface area in map coordinates
# [minx, miny, maxx, maxy]

## @method render_selection($gc)
#
# @brief Render the selection using the given graphics context
# @param $gc Gtk2::Gdk::GC
sub render_selection {
}

## @method void render($pb, $cr, $overlay, $viewport)
#
# @brief A request to render the data of the layer onto a surface.
#
# @param[in,out] pb A (XS wrapped) pointer to a gtk2_ex_geo_pixbuf.
# @param[in,out] cr A Cairo::Context object for the surface to draw on.
# @param[in] overlay A Gtk2::Ex::Geo::Overlay object which manages the surface.
# @param[in] viewport A reference to the bounding box [min_x, min_y,
# max_x, max_y] of the surface in world coordinates.
sub render {
    my($self, $pb, $cr, $overlay, $viewport) = @_;
}

## @method $bootstrap_dialog($gui, $dialog, $title, $connects)
#
# @brief Bootstrap the requested dialog.
#
# The requested dialog is asked from a Glue object, stored into the
# layer, and presented. 
#
# @param gui A Gtk2::Ex::Geo::Glue object
# @param dialog A name by which the GladeXML object is stored into the
# layer. Also the name of the dialog widget in one of the glade
# resources given to Glue object as Gtk2::Ex::Geo::DialogMaster
# objects. Note that the name must be globally unique.
# @param title Title for the dialog.
# @param connects A hash of widget names linked to an array of signal
# name, subroutine, and user data.
# @param combos A list of simple combos that need a model and a text
# renderer in boot up.
#
# @return the GladeXML object of the dialog or the object and a
# boolean telling whether the dialog was just booted, and may need
# further boot up.
sub bootstrap_dialog {
    my($self, $gui, $dialog, $title, $connects, $combos) = @_;
    $self = {} unless $self;
    my $boot = 0;
    my $widget;
    unless ($self->{$dialog}) {
	$self->{$dialog} = $gui->get_dialog($dialog);
	croak "$dialog does not exist" unless $self->{$dialog};
	$widget = $self->{$dialog}->get_widget($dialog);
	if ($connects) {
	    for my $n (keys %$connects) {
		my $w = $self->{$dialog}->get_widget($n);
		#print STDERR "connect: '$n'\n";
		$w->signal_connect(@{$connects->{$n}});
	    }
	}
	if ($combos) {
	    for my $n (@$combos) {
		my $combo = $self->{$dialog}->get_widget($n);
		unless ($combo->isa('Gtk2::ComboBoxEntry')) {
		    my $renderer = Gtk2::CellRendererText->new;
		    $combo->pack_start($renderer, TRUE);
		    $combo->add_attribute($renderer, text => 0);
		}
		my $model = Gtk2::ListStore->new('Glib::String');
		$combo->set_model($model);
		$combo->set_text_column(0) if $combo->isa('Gtk2::ComboBoxEntry');
	    }
	}
	$boot = 1;
	$widget->set_position('center');
    } else {
	$widget = $self->{$dialog}->get_widget($dialog);
	$widget->move(@{$self->{$dialog.'_position'}}) unless $widget->get('visible');
    }
    $widget->set_title($title);
    $widget->show_all;
    $widget->present;
    return wantarray ? ($self->{$dialog}, $boot) : $self->{$dialog};
}

## @method hide_dialog($dialog)
# @brief Hide the given (name of a) dialog.
sub hide_dialog {
    my($self, $dialog) = @_;
    $self->{$dialog.'_position'} = [$self->{$dialog}->get_widget($dialog)->get_position];
    $self->{$dialog}->get_widget($dialog)->hide();
}

## @method $dialog_visible($dialog)
#
# @brief Return true is the given (name of a) dialog is visible.
sub dialog_visible {
    my($self, $dialog) = @_;
    my $d = $self->{$dialog};
    return 0 unless $d;
    return $d->get_widget($dialog)->get('visible');
}

1;
