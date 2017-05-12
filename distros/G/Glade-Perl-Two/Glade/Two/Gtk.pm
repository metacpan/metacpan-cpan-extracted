package Glade::Two::Gtk;
require 5.000; use strict 'vars', 'refs', 'subs';

# Copyright (c) 1999 Dermot Musgrove <dermot.musgrove@virgin.net>
#
# This library is released under the same conditions as Perl, that
# is, either of the following:
#
# a) the GNU General Public License as published by the Free
# Software Foundation; either version 1, or (at your option) any
# later version.
#
# b) the Artistic License.
#
# If you use this library in a commercial enterprise, you are invited,
# but not required, to pay what you feel is a reasonable fee to perl.org
# to ensure that useful software is available now and in the future. 
#
# (visit http://www.perl.org/ or email donors@perlmongers.org for details)

BEGIN {
    use Exporter    qw( );
    use Data::Dumper;
    use Glade::Two::Source qw( :VARS :METHODS);
    use vars              qw( 
                            @ISA
                            $PACKAGE $VERSION $AUTHOR $DATE
                            @VARS @METHODS
                            @EXPORT @EXPORT_OK %EXPORT_TAGS 
                            $CList_column
                            $CTree_column
                            $nb
                            $enums
                         );
    $PACKAGE      = __PACKAGE__;
    $VERSION      = q(0.01);
    $AUTHOR       = q(Dermot Musgrove <dermot.musgrove@virgin.net>);
    $DATE         = q(Sun Nov 17 06:02:01 GMT 2002 );
    @VARS           = qw( 
                            $CList_column
                            $CTree_column
                            $nb
                            $enums
                       );
    @ISA            = qw(
                            Exporter
                            Glade::Two::Source
                       );
    # These symbols (globals and functions) are always exported
    @EXPORT         =   qw( );
    # Optionally exported package symbols (globals and functions)
    @EXPORT_OK    = ( @METHODS, @VARS);
    # Tags (groups of symbols) to export		
    %EXPORT_TAGS  = (
                        'METHODS' => [@METHODS] , 
                        'VARS'    => [@VARS]    
                   );
}

$CList_column    = 0;
$CTree_column    = 0;

sub DESTROY {
    # This sub will be called on object destruction
} # End of sub DESTROY

#===============================================================================
#=========== Gtk utilities                                          ============
#===============================================================================
sub lookup {
    my ($class, $self) = @_;
    # Check cached enums first
    my $lookup = $enums->{$self};
    my $type;
    unless ($lookup) {
        $lookup = $self;
#        foreach $type ( 
#            'TOOLBAR_CHILD',
#           ) {
#            # Remove leading GTK type
#            last if $lookup =~ s/GTK_$type\_/Gtk2::$type->CHILD/; # finish early
#        }
        $lookup =~ s/^G[DT]K_//;    # strip off leading GDK_ or GTK_
        foreach $type ( 
            'WINDOW',       'WIN_POS',      'JUSTIFY',      
            'POLICY',       'SELECTION',    'ORIENTATION',
            'TOOLBAR_SPACE','EXTENSION_EVENTS',
            'CORNER',
            'TOOLBAR_CHILD','TOOLBAR','TREE_VIEW', 
            'BUTTONBOX',    'UPDATE',       'PACK',
            'POS',          'ARROW',        'BUTTONBOX', 
            'CURVE_TYPE',   'PROGRESS',     'VISUAL',       
            'IMAGE',        'CALENDAR',     'SHADOW',
            'CLOCK',        'RELIEF',       'SIDE',
            'ANCHOR',       'WRAP',
           ) {
            # Remove leading GTK type
            last if $lookup =~ s/^${type}_//; # finish early
        }
        $lookup = lc($lookup);
        # Cache this enum for later use
        $enums->{$self} = $lookup;
    }
    $Glade_Perl->diag_print(5, "Looked up '%s' and found %s", $self, $lookup); 
    return $lookup;
}

#===============================================================================
#=========== Gtk widget constructors                                ============
#===============================================================================
sub new_GtkAccelGroup {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkAccelGroup";
    my $name = $proto->{name};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::AccelGroup;");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

#===============================================================================
#=========== Gtk label widgets
#===============================================================================
sub new_GtkAccelLabel {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkAccelLabel";
    my $name = $proto->{'widget'}{'name'};
    my $label   = $class->use_par($proto,'label',   $DEFAULT, '');
#    my $pattern = $label;

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = ".
        "new Gtk2::AccelLabel(_('$label'));");

    my $mnemonic_widget = $class->use_par($proto, 'mnemonic_widget');

    # This needs to be deferred until all widgets are constructed (like signal_connects)
    my $expr = "push \@{${current_form}\{'Accel_Strings'}}, ".
            "\"".(ref $class||$class)."->add_to_UI(1, \\\"".
            "\\\\\\${current_form}\{'$name'}->set_accel_widget(".
            "\\\\\\${current_form}\{'$mnemonic_widget'});\\\");\"";
#print "'$expr'\n";
    eval $expr;

    $class->use_set_property($name, $proto, 'use_underline', $BOOL, $depth);
    $class->set_label_properties($parent, $name, $proto, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkLabel {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkLabel";
    my $name = $proto->{'widget'}{'name'};
#    my $label   = $proto->{widget}{property}{'label'}{value} || '';
    my $label   = $class->use_par($proto, 'label',   $DEFAULT, '');
    
    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::Label(".
        "_('$label'));");

    $class->use_set_property($name, $proto, 'use_underline', $BOOL, $depth);
    $class->set_label_properties($parent, $name, $proto, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkAlignment {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkAlignment";
    my $name = $proto->{'widget'}{'name'};
    my $xalign    = $class->use_par($proto, 'xalign',    $DEFAULT,    0.5);
    my $yalign    = $class->use_par($proto, 'yalign',    $DEFAULT,    0.5);
    my $xscale    = $class->use_par($proto, 'xscale',    $DEFAULT,    0.5);
    my $yscale    = $class->use_par($proto, 'yscale',    $DEFAULT,    0.5);

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::Alignment(".
        "$xalign, $yalign, $xscale, $yscale);");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkArrow {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkArrow";
    my $name = $proto->{'widget'}{'name'};
    my $arrow_type  = $class->use_par($proto, 'arrow_type',  $LOOKUP,    'right');
    my $shadow_type = $class->use_par($proto, 'shadow_type', $LOOKUP,    '');

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::Arrow(".
        "'$arrow_type', '$shadow_type');");

    $class->set_misc_properties($parent, $name, $proto, $depth);
    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkAspectFrame {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkAspectFrame";
    my $name = $proto->{'widget'}{'name'};
    my $label        = $class->use_par($proto, 'label',        $DEFAULT,    ''    );
    my $xalign       = $class->use_par($proto, 'xalign',       $DEFAULT,    0.5   );
    my $yalign       = $class->use_par($proto, 'yalign',       $DEFAULT,    0.5   );
    my $ratio        = $class->use_par($proto, 'ratio',        $DEFAULT,    1     );
    my $obey_child   = $class->use_par($proto, 'obey_child',   $BOOL,       'True');

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::AspectFrame(".
        "_('$label'), $xalign, $yalign, $ratio, $obey_child);");

    $class->use_set_property($name, $proto, 'shadow_type', $LOOKUP, $depth);

    my $label_xalign = $class->use_par($proto, 'label_xalign', $DEFAULT,    0.5   );
    my $label_yalign = $class->use_par($proto, 'label_yalign', $DEFAULT,    0.5   );
    $class->add_to_UI($depth, "\$widgets->{'$name'}->set_label_align(".
        "$label_xalign, $label_yalign);");

    $class->set_label_properties($parent, $name, $proto, $depth);
    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

#===============================================================================
#=========== Gtk button widgets
#===============================================================================
sub new_GtkButton {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkButton";
    my $name = $proto->{'widget'}{'name'};

# FIXME - toolbar buttons with a removed label don't have a child_name
#   but can have a sub-widget. allow this
    unless ($class->get_internal_child($parent, $name, $proto, $depth)) {
        my $label  = $class->use_par($proto, 'label', $DEFAULT, '');
        my $stock_button = $class->use_par($proto, 'stock_button',  $LOOKUP, '');
        if ($stock_button) {
            $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
                "new_from_stock Gtk2::Button('$stock_button');");

        } elsif ($class->use_par($proto, 'use_stock',  $BOOL|$MAYBE)) {
            $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
                "new_from_stock Gtk2::Button('$label');");
        } elsif ($label) {
            $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
                "new_with_label Gtk2::Button(_('$label'));");

        } elsif (! $proto->{'stock_pixmap'}) {
            $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
                "new Gtk2::Button;");
        }
        delete $proto->{'internal-child'};
#        delete $failures->{$INTERNAL_CHILD}{$parentname}{$proto->{'internal-child'}};
    }
    $class->set_button_properties($parent, $name, $proto, $depth);
    $class->pack_widget($parent, $name, $proto, $depth);

    return $widgets->{$name};
}

sub new_GtkCheckButton {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCheckButton";
    my $name = $proto->{'widget'}{'name'};
    my $label   = $class->use_par($proto, 'label',  $STRING|$MAYBE);

    if ($label) {
        $class->add_to_UI($depth,  "\$widgets->{'$name'} = ".
            "new_with_label Gtk2::CheckButton(_('$label'));");
    } else {
        $class->add_to_UI($depth,  "\$widgets->{'$name'} = ".
            "new Gtk2::CheckButton;");
    }
    $class->use_set_property($name, $proto, 'draw_indicator', $BOOL, $depth, 'set_mode');
    $class->use_set_property($name, $proto, 'active', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'inconsistent', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'active', $BOOL, $depth);
    $class->set_button_properties($parent, $name, $proto, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkRadioButton {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkRadioButton";
    my $name = $proto->{'widget'}{'name'};
#    my $label  = $class->use_par($proto, 'label'    ,  $DEFAULT, '');

    my $group  = $class->use_par($proto, 'group', $DEFAULT, $name);
    my $group_widget = "$current_form\{'rb_group'}{'$group'}";
    if (eval "defined $group_widget") {
        $class->add_to_UI($depth,  "\$widgets->{'$name'} = ".
            "new Gtk2::RadioButton($group_widget->get_group());");
    } else {
        $class->add_to_UI($depth,  "\$widgets->{'$name'} = ".
            "new Gtk2::RadioButton(undef);");

        $class->add_to_UI($depth, "$group_widget = \$widgets->{'$name'};");
    }
    $class->use_set_property($name, $proto, 'draw_indicator', $BOOL, $depth, 'set_mode');
    $class->use_set_property($name, $proto, 'inconsistent', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'active', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'always_show_toggle', $BOOL, $depth, 'set_show_toggle');
    $class->set_button_properties($parent, $name, $proto, $depth);
    $class->pack_widget($parent, $name, $proto, $depth);
    
    return $widgets->{$name};
}

sub new_GtkToggleButton {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkToggleButton";
    my $name = $proto->{'widget'}{'name'};

#    my $label = $class->use_par($proto, 'label', $DEFAULT, '');
#    if ($label) {
#        $class->add_to_UI($depth,  "\$widgets->{'$name'} = ".
#            "new_with_label Gtk2::ToggleButton(_('$label'));");
    $class->add_to_UI($depth,  "\$widgets->{'$name'} = ".
        "new Gtk2::ToggleButton();");
#    }
    $class->use_set_property($name, $proto, 'inconsistent', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'active', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'always_show_toggle', $BOOL, $depth, 'set_show_toggle');
    $class->set_button_properties($parent, $name, $proto, $depth);
    $class->pack_widget($parent, $name, $proto, $depth);

    return $widgets->{$name};
}

sub new_radio {&new_button(@_)}
sub new_toggle{&new_button(@_)}
sub new_button {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_button";
    my $name = $proto->{'widget'}{'name'};
    my $type = "button";
    my $label_widget_name = 'undef';
    my $image_widget_name = 'undef';
    my ($group, $group_widget);
    my $label   = $class->use_par($proto, 'label', $MAYBE);
    my $icon    = $class->use_par($proto, 'icon',  $MAYBE);
#    my $stock_button = $class->use_par($proto, 'stock_button',  $LOOKUP|$MAYBE);
    my $stock_pixmap = $class->use_par($proto, 'stock_pixmap',  $LOOKUP|$MAYBE);

    my $tooltip = $class->use_par($proto, 'tooltip', $DEFAULT, $label);
    if (eval "$current_form\{'$parent'}{'tooltips'}" && !$tooltip) {
        $Glade_Perl->diag_print (1, "warn  Toolbar '%s' is expecting ".
            "a tooltip but you have not set one for %s '%s'",
            $parent, $proto->{'widget'}{'class'}, $name);
    }            

    my $new_group = $class->use_par($proto->{'packing'}, 'new_group', $BOOL, 0);
    if ($new_group) {
        $class->add_to_UI($depth, 
            "${current_form}\{'$parent'}->append_space;");
    }

#FIXME
    if ($icon) {
        $image_widget_name = "${current_form}\{'$name-image'}";
        $class->add_to_UI($depth, 
            "$image_widget_name = \$class->create_image(".
            "\"$icon\", [\"\$Glade::Two::Run::pixmaps_directory\"]);");

    } elsif ($stock_pixmap) {
        $image_widget_name = "${current_form}\{'$name-image'}";
        $class->add_to_UI($depth, 
            "$image_widget_name = new_from_stock Gtk2::Button(".
                "'$stock_pixmap');"); 

    } else {
        $image_widget_name = 0;
    }
#    unless (eval "$image_widget_name") {
    $label_widget_name = "${current_form}\{'$name-label'}";
    $class->load_class("Gtk2::Label");
    $class->add_to_UI($depth, "$label_widget_name = ".
#        "new Gtk2::Label();");
        "new Gtk2::Label(_('$label'));");

    # We have label and so on to add
    $group_widget = 'undef';
#    $group_widget = 0;
    if ($proto->{'widget'}{'class'} eq 'toggle') {
        $class->load_class('Gtk2::ToggleButton');
        $type = "'togglebutton'";
#        $type = 'Gtk2::Toolbar->CHILD_TOGGLEBUTTON';

    } elsif ($proto->{'widget'}{'class'} eq 'radio') {
        $class->load_class('Gtk2::RadioButton');
        $type = "'radiobutton'";
#        $type = 'Gtk2::Toolbar->CHILD_RADIOBUTTON';
        $group  = $class->use_par($proto, 'group', $DEFAULT, 0);
        $group_widget = "$current_form\{'rb_group'}{'$group'}" if $group;

    } else {
        $class->load_class('Gtk2::Button');
#        $type = 'Gtk2::Toolbar->CHILD_BUTTON';
        $type = "'button'";
    }
    $class->add_to_UI($depth, 
        "\$widgets->{'$name'} = ".
            "${current_form}\{'$parent'}->append_element(".
                    "$type".                  # toolbar child type
                    ", $group_widget".          # widget
                    ", _('$label')".            # Text
                    ", _('$tooltip')".          # Tooltip text
                    ", ''".                     # Tooltip private text
                    ", $image_widget_name".     # Icon
                    ", sub{}".
#                    ", sub{print \"'$name' clicked\\n\"}".
#                    ", undef ".                 # Callback
#                    ", ''".                     # User data
                ");");

    unless ($group_widget) {
        $class->add_to_UI($depth, 
            "$current_form\{'rb_group'}{'$name'} = \$widgets->{'$name'};");
    }
    $class->use_set_property($name, $proto, 'active', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'always_show_toggle', $BOOL, $depth, 'set_show_toggle');
    $class->use_set_property($name, $proto, 'inconsistent', $BOOL, $depth);
    if ($class->use_par($proto, 'visible', $BOOL|$MAYBE)) {
        $class->add_to_UI($depth, "\$widgets->{'$name'}->show;");
    }
    $class->set_button_properties($parent, $name, $proto, $depth);
    $class->add_to_UI($depth, 
        "${current_form}\{'$name'} = \$widgets->{'$name'};");
    # Delete the $widget to show that it has been packed
    delete $widgets->{$name};

    $class->set_widget_properties($parent, $name, $proto, $depth);
    $class->set_container_properties($parent, $name, $proto, $depth);
    $class->set_tooltip($name, $proto, $depth);

}
            
#===============================================================================
#=========== Gtk
#===============================================================================
sub new_GtkCalendar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCalendar";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::Calendar;");

    my $display_options = $class->use_par($proto, 'display_options', $DEFAULT, '');
    $class->add_to_UI($depth, "\$widgets->{'$name'}->display_options(".
        $class->string_to_arrayref($display_options).");");

    $class->add_to_UI($depth, "\$work->{'$name-date'} = [localtime];");
    $class->add_to_UI($depth, "\$widgets->{'$name'}->select_day(".
        "\$work->{'$name-date'}[3]);");
    $class->add_to_UI($depth, "\$widgets->{'$name'}->select_month(".
        "\$work->{'$name-date'}[4], \$work->{'$name-date'}[5] + 1900);");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkCList {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCList";
    my $name = $proto->{'widget'}{'name'};
    my $n_columns      = $class->use_par($proto, 'n_columns');
    my $selection_mode = $class->use_par($proto, 'selection_mode', $LOOKUP);
    my $shadow_type    = $class->use_par($proto, 'shadow_type',    $LOOKUP);
#print Dumper($proto);
    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::CList(".
        "$n_columns);");
    $class->use_set_property($name, $proto, 'selection_mode', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'shadow_type', $LOOKUP, $depth);
    if ($class->use_par($proto, 'show_titles', $BOOL|$MAYBE)) {
        $class->add_to_UI($depth,  "\$widgets->{'$name'}->column_titles_show();");
    } else {
        $class->add_to_UI($depth,  "\$widgets->{'$name'}->column_titles_hide();");
    }

    my @column_widths = split(',', $class->use_par($proto, 'column_widths'));
    $CList_column = 0;
    my $i = 0;
    while ($i < scalar(@column_widths)) { 
        $Glade_Perl->diag_print(8, 
            "%s- Setting column %s to width %s in %s",
            $indent, $i, $column_widths[$i], $me);
        $class->add_to_UI($depth,  "\$widgets->{'$name'}->set_column_width(".
            "$i, $column_widths[$i]);");
        $i++;
    }

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkCTree {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCTree";
    my $name = $proto->{'widget'}{'name'};
    my $n_columns      = $class->use_par($proto, 'n_columns');
    my $selection_mode = $class->use_par($proto, 'selection_mode', $LOOKUP);
    my $shadow_type    = $class->use_par($proto, 'shadow_type',    $LOOKUP);
#    my $tree_column    = $class->use_par($proto, 'tree_column', $MAYBE);

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::CTree(".
        "$n_columns);");#, ".($tree_column || 0).");");
    $class->use_set_property($name, $proto, 'selection_mode', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'shadow_type', $LOOKUP, $depth);
    if ($class->use_par($proto, 'show_titles', $BOOL|$MAYBE)) {
        $class->add_to_UI($depth,  "\$widgets->{'$name'}->column_titles_show();");
    } else {
        $class->add_to_UI($depth,  "\$widgets->{'$name'}->column_titles_hide();");
    }

    my @column_widths = split(',', $class->use_par($proto, 'column_widths'));
    $CTree_column = 0;
    my $i = 0;
    while ($i < scalar(@column_widths)) { 
        $Glade_Perl->diag_print(8, 
            "%s- Setting column %s to width %s in %s",
            $indent, $i, $column_widths[$i], $me);
        $class->add_to_UI($depth,  "\$widgets->{'$name'}->set_column_width(".
            "$i, $column_widths[$i]);");
        $i++;
    }
    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkColorSelection {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkColorSelection";
    my $name = $proto->{'widget'}{'name'};

    unless ($class->get_internal_child($parent, $name, $proto, $depth)) {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::ColorSelection;");
    }
    $class->use_set_property($name, $proto, 'update_policy', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'has_opacity_control', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'has_palette', $BOOL, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkCombo {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCombo";
    my $name = $proto->{'widget'}{'name'};
#print Dumper($proto);exit;
    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::Combo;");

    $class->use_set_property($name, $proto, 'case_sensitive', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'enable_arrow_keys', $BOOL, $depth, 'set_use_arrows');
    $class->use_set_property($name, $proto, 'enable_arrows_always', $BOOL, $depth, 'set_use_arrows_always');

    my $allow_empty    = $class->use_par($proto, 'allow_empty',    $BOOL|$MAYBE);
    my $items = $class->use_par($proto, 'items', $MAYBE);
    unless ($allow_empty) {
        if ($items eq '') {
            $Glade_Perl->diag_print (1, "warn  Widget '%s' does not have any ".
                "items specified in %s", $name, $me);
        }
    }

    my $value_in_list  = $class->use_par($proto, 'value_in_list',  $BOOL|$MAYBE);
    if ($value_in_list) {
        $class->add_to_UI($depth, "\$widgets->{'$name'}->set_value_in_list(".
            "$value_in_list, $allow_empty);");
    }
    if (defined $items) {
        my @popdown_strings = split(/\n/, $items);
        my $popdown_strings = "'".join("', '",  @popdown_strings)."'";
        $class->add_to_UI($depth, "\$widgets->{'$name'}->set_popdown_strings(".
            " $popdown_strings);");
    }

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

#===============================================================================
#=========== Gtk curve widgets
#===============================================================================
sub new_GtkCurve {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCurve";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::Curve;");

#    my $curve_type = $class->use_par($proto, 'curve_type', $LOOKUP, 'spline');
#    $class->add_to_UI($depth, "\$widgets->{'$name'}->set_curve_type('$curve_type');");
    $class->use_set_property($name, $proto, 'curve_type', $LOOKUP, $depth);

    my $min_x      = $class->use_par($proto, 'min_x',      $DEFAULT,    0);
    my $min_y      = $class->use_par($proto, 'min_y',      $DEFAULT,    0);
    my $max_x      = $class->use_par($proto, 'max_x',      $DEFAULT,    1);
    my $max_y      = $class->use_par($proto, 'max_y',      $DEFAULT,    1);
    $class->add_to_UI($depth, "\$widgets->{'$name'}->set_range(".
        "$min_x, $min_y, $max_x, $max_y);");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkGammaCurve {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkGammaCurve";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::GammaCurve;");

#    my $curve_type = $class->use_par($proto, 'curve_type',   $LOOKUP, 'spline');
#    $class->add_to_UI($depth, "\$widgets->{'$name'}->curve->set_curve_type(".
#        "'$curve_type');");
    $class->use_set_property($name, $proto, 'curve_type', $LOOKUP, $depth);

    my $min_x      = $class->use_par($proto, 'min_x',        $DEFAULT,    0);
    my $min_y      = $class->use_par($proto, 'min_y',        $DEFAULT,    0);
    my $max_x      = $class->use_par($proto, 'max_x',        $DEFAULT,    1);
    my $max_y      = $class->use_par($proto, 'max_y',        $DEFAULT,    1);
    $class->add_to_UI($depth, "\$widgets->{'$name'}->curve->set_range(".
        "$min_x, $min_y, $max_x, $max_y);");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

#===============================================================================
#=========== Gtk window widgets
#===============================================================================
sub new_GtkColorSelectionDialog {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkColorSelectionDialog";
    my $name = $proto->{'widget'}{'name'};
    my $ignore = $class->use_par($proto, 'type',  $LOOKUP,  '');
    my $title  = $class->use_par($proto,'title',  $DEFAULT, 'File Selection');
    
    $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
        "new Gtk2::ColorSelectionDialog(_('$title'));");

    $class->set_window_properties($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkDialog {
    my ($class, $parent, $proto, $depth, $mainmenu) = @_;
    my $me = "$class->new_GtkDialog";
    my $name = $proto->{'widget'}{'name'};
    my $ignore = $class->use_par($proto, 'type',  $LOOKUP,  '');

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::Dialog;");
    $class->use_set_property($name, $proto, 'title', $STRING, $depth, 'set_title');
    $class->use_set_property($name, $proto, 'has_separator', $BOOL, $depth);

    $class->set_window_properties($parent, $name, $proto, $depth);
#    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkFileSelection {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkFileSelection";
    my $name = $proto->{'widget'}{'name'};
    my $ignore = $class->use_par($proto,'type', $DEFAULT, '');
    my $title = $class->use_par($proto,'title', $DEFAULT, 'File Selection');
    my $show_fileops  = $class->use_par($proto,'show_fileops',    $BOOL|$MAYBE);

#    $class->add_to_UI($depth, "use Gtk2::FileSelection;");
    $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
        "new Gtk2::FileSelection(_('$title'));");
    if ($show_fileops) {
        $class->add_to_UI($depth, "\$widgets->{'$name'}->show_fileop_buttons;");
    } else {
        $class->add_to_UI($depth, "\$widgets->{'$name'}->hide_fileop_buttons;");
    }
    $class->set_window_properties($parent, $name, $proto, $depth);
#    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkFontSelectionDialog {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkFontSelectionDialog";
    my $name = $proto->{'widget'}{'name'};
    my $ignore= $class->use_par($proto, 'type',  $LOOKUP,  '');
    my $title = $class->use_par($proto,'title', $DEFAULT, 'Font Selection');

    $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
        "new Gtk2::FontSelectionDialog(_('$title'));");

    $class->set_window_properties($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkInputDialog {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHInputDialog";
    my $name = $proto->{'widget'}{'name'};
    my $ignore= $class->use_par($proto, 'type',  $LOOKUP,  '');
    my $title        = $class->use_par($proto, 'title', $DEFAULT, '');

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::InputDialog;");
    $class->use_set_property($name, $proto, 'title', $STRING, $depth, 'set_title');
#    $class->add_to_UI($depth, "\$widgets->{'$name'}->set_title(_('$title'));");

    $class->set_window_properties($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkWindow {
    my ($class, $parent, $proto, $depth, $mainmenu) = @_;
    my $me = "$class->new_GtkWindow";
    my $name = $proto->{'widget'}{'name'};

    my $title = $class->use_par($proto, 'title', $DEFAULT, '');
    my $type  = $class->use_par($proto,'type', $LOOKUP, 'toplevel');

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::Window(".
        "'$type');");
    $class->use_set_property($name, $proto, 'title', $STRING, $depth, 'set_title');
#    $class->add_to_UI($depth, "\$widgets->{'$name'}->set_title(_('$title'));");

    $class->set_window_properties($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

#===============================================================================
#=========== Gtk container widgets
#===============================================================================
sub new_GtkScrolledWindow {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkScrolledWindow";
    my $name = $proto->{'widget'}{'name'};
    my $hscrollbar_policy = $class->use_par($proto, 'hscrollbar_policy', $LOOKUP, 'always');
    my $vscrollbar_policy = $class->use_par($proto, 'vscrollbar_policy', $LOOKUP, 'always');
#    my $hupdate_policy    = $class->use_par($proto, 'hupdate_policy',    $LOOKUP, 'continuous');
#    my $vupdate_policy    = $class->use_par($proto, 'vupdate_policy',    $LOOKUP, 'continuous');

    $class->add_to_UI($depth,  
        "\$widgets->{'$name'} = new Gtk2::ScrolledWindow( undef, undef);");
    $class->add_to_UI($depth, "\$widgets->{'$name'}->set_policy(".
        "'$hscrollbar_policy', '$vscrollbar_policy');");

    $class->use_set_property($name, $proto, 'shadow_type', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'window_placement', $LOOKUP, $depth, 'set_placement');

#    $class->add_to_UI($depth, "\$widgets->{'$name'}->get_hadjustment->".
#        "set_update_policy('$hupdate_policy');");
#    $class->add_to_UI($depth, "\$widgets->{'$name'}->get_vadjustment->".
#        "set_update_policy('$vupdate_policy');");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkDrawingArea {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkDrawingArea";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::DrawingArea;");
    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkEntry {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkEntry";
    my $name = $proto->{'widget'}{'name'};

    unless ($class->get_internal_child($parent, $name, $proto, $depth)) {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::Entry;");
    }

    $class->use_set_property($name, $proto, 'text', $STRING, $depth);
    $class->use_set_property($name, $proto, 'max_length', $MAYBE, $depth);
    $class->use_set_property($name, $proto, 'visibility', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'editable', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'activates_default', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'invisible_char', $MAYBE, $depth);
    $class->use_set_property($name, $proto, 'has_frame', $BOOL, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkEventBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkEventBox";
    my $name = $proto->{'widget'}{'name'};
    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::EventBox;");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkFixed {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkFixed";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::Fixed;");
    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkFontSelection {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkFontSelection";
    my $name = $proto->{'widget'}{'name'};
    unless ($class->get_internal_child($parent, $name, $proto, $depth)) {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::FontSelection;");
    }
    $class->use_set_property($name, $proto, 'preview_text', $STRING, $depth);
    # Glade supplies values for set_child_packing() even for packing in
    # a FontSelectionDialog which is a container  (NOT a box)
    if (eval "$current_form\{$parent}->isa('Gtk2::FontSelectionDialog')") {
        delete $proto->{'packing'};
    }
    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkFrame {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkFrame";
    my $name = $proto->{'widget'}{'name'};
#    my $label        = $class->use_par($proto, 'label');
    my $label_xalign = $class->use_par($proto, 'label_xalign', $DEFAULT, 0);
    my $label_yalign = $class->use_par($proto, 'label_yalign', $DEFAULT, 0);

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = ".
        "new Gtk2::Frame('');");
#        "new Gtk2::Frame(_('$label'));");
    $class->add_to_UI($depth, "\$widgets->{'$name'}->set_label_align(".
        "$label_xalign, $label_yalign);");
    $class->use_set_property($name, $proto, 'shadow_type', $LOOKUP, $depth);
    $class->set_label_properties($parent, $name, $proto, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkHandleBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHandleBox";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::HandleBox;");

    $class->use_set_property($name, $proto, 'handle_position', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'shadow_type', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'snap_edge', $LOOKUP, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkHBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHBox";
    my $name = $proto->{'widget'}{'name'};
    my $homogeneous = $class->use_par($proto, 'homogeneous', $BOOL,    'False');
    my $spacing     = $class->use_par($proto, 'spacing'    , $DEFAULT, 0);

    unless ($class->get_internal_child($parent, $name, $proto, $depth)) {
        $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::HBox(".
            "$homogeneous, $spacing);");
    }
    
    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkVBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkVBox";
    my $name = $proto->{'widget'}{'name'};
    my $homogeneous  = $class->use_par($proto, 'homogeneous',  $BOOL,   'False');
    my $spacing      = $class->use_par($proto, 'spacing'    ,  $DEFAULT, 0);

    unless ($class->get_internal_child($parent, $name, $proto, $depth)) {
        $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::VBox(".
            "$homogeneous, $spacing);");
    }

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkViewport {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkViewport";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth,  
        "\$widgets->{'$name'} = new Gtk2::Viewport(".
            "new Gtk2::Adjustment( 0.0, 0.0, 101.0, 0.1, 1.0, 1.0), ".
            "new Gtk2::Adjustment( 0.0, 0.0, 101.0, 0.1, 1.0, 1.0));");
    $class->use_set_property($name, $proto, 'shadow_type', $LOOKUP, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkHButtonBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHButtonBox";
    my $name = $proto->{'widget'}{'name'};

    unless ($class->get_internal_child($parent, $name, $proto, $depth)) {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::HButtonBox;");
    }
    $class->use_set_property($name, $proto, 'layout_style', $LOOKUP, $depth, 'set_layout');
    $class->use_set_property($name, $proto, 'spacing', $INT|$MAYBE, $depth);

    my $child_min_width = $class->use_par($proto, 'child_min_width', $MAYBE);
    my $child_min_height = $class->use_par($proto, 'child_min_height', $MAYBE);
    if (defined $child_min_width or defined $child_min_height) {
        $class->add_to_UI($depth, "\$widgets->{'$name'}->set_child_size(".
            "$child_min_width, $child_min_height);");
    }
    my $child_ipad_x    = $class->use_par($proto, 'child_ipad_x', $MAYBE);
    my $child_ipad_y    = $class->use_par($proto, 'child_ipad_y', $MAYBE);
    if (defined $child_ipad_x or defined $child_ipad_y) {
        $class->add_to_UI($depth, "\$widgets->{'$name'}->set_child_ipadding(".
            "$child_ipad_x, $child_ipad_y);");
    }

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkVButtonBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkVButtonBox";
    my $name = $proto->{'widget'}{'name'};

    unless ($class->get_internal_child($parent, $name, $proto, $depth)) {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::VButtonBox;");
    }
    $class->use_set_property($name, $proto, 'layout_style', $LOOKUP, $depth, 'set_layout');
    $class->use_set_property($name, $proto, 'spacing', $INT|$MAYBE, $depth);

    my $child_min_width = $class->use_par($proto, 'child_min_width', $MAYBE);
    my $child_min_height = $class->use_par($proto, 'child_min_height', $MAYBE);
    if (defined $child_min_width or defined $child_min_height) {
        $class->add_to_UI($depth, "\$widgets->{'$name'}->set_child_size(".
            "$child_min_width, $child_min_height);");
    }
    my $child_ipad_x    = $class->use_par($proto, 'child_ipad_x', $MAYBE);
    my $child_ipad_y    = $class->use_par($proto, 'child_ipad_y', $MAYBE);
    if (defined $child_ipad_x or defined $child_ipad_y) {
        $class->add_to_UI($depth, "\$widgets->{'$name'}->set_child_ipadding(".
            "$child_ipad_x, $child_ipad_y);");
    }

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkHPaned {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHPaned";
    my $name = $proto->{'widget'}{'name'};
    $class->add_to_UI($depth,  "\$widgets->{'$name'} = Gtk2::HPaned->new();");

    $class->use_set_property($name, $proto, 'position', $MAYBE, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkVPaned {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkVPaned";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::VPaned;");
    $class->use_set_property($name, $proto, 'position', $MAYBE, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkHRuler {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHRuler";
    my $name = $proto->{'widget'}{'name'};
    my $lower    = $class->use_par($proto, 'lower',    $DEFAULT, 0);
    my $upper    = $class->use_par($proto, 'upper',    $DEFAULT, 10);
    my $position = $class->use_par($proto, 'position', $DEFAULT, 0);
    my $max_size = $class->use_par($proto, 'max_size', $DEFAULT, 10);

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::HRuler;");
    $class->add_to_UI($depth, "\$widgets->{'$name'}->set_range(".
        "$lower, $upper, $position, $max_size);");
    $class->use_set_property($name, $proto, 'metric', $LOOKUP, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkVRuler {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkVRuler";
    my $name = $proto->{'widget'}{'name'};
    my $lower    = $class->use_par($proto, 'lower',      $DEFAULT, 0);
    my $upper    = $class->use_par($proto, 'upper',      $DEFAULT, 0);
    my $position = $class->use_par($proto, 'position',   $DEFAULT, 0);
    my $max_size = $class->use_par($proto, 'max_size',   $DEFAULT, 0);

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::VRuler;");
    $class->add_to_UI($depth, "\$widgets->{'$name'}->set_range(".
        "$lower, $upper, $position, $max_size);");
    $class->use_set_property($name, $proto, 'metric', $LOOKUP, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkHScale {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHScale";
    my $name = $proto->{'widget'}{'name'};

    my $adjustment = $class->use_par($proto, 'adjustment', $DEFAULT, '0 0 100 1 10 10');
    my ($value, $lower, $upper, $step, $page, $page_size) =
        split(" ", $adjustment);
    $class->add_to_UI($depth,  "\$work->{'$name-adj'} = new Gtk2::Adjustment(".
        "$value, $lower, $upper, $step, $page, $page_size);");
    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::HScale(".
        "\$work->{'$name-adj'});");

    $class->use_set_property($name, $proto, 'draw_value', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'digits', $MAYBE, $depth);
    $class->use_set_property($name, $proto, 'value_pos', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'update_policy', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'inverted', $BOOL, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkVScale {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkVScale";
    my $name = $proto->{'widget'}{'name'};

    my $adjustment = $class->use_par($proto, 'adjustment', $DEFAULT, '0 0 100 1 10 10');
    my ($value, $lower, $upper, $step, $page, $page_size) =
        split(" ", $adjustment);
    $class->add_to_UI($depth,  "\$work->{'$name-adj'} = new Gtk2::Adjustment(".
        "$value, $lower, $upper, $step, $page, $page_size);");
    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::VScale(".
        "\$work->{'$name-adj'});");

    $class->use_set_property($name, $proto, 'draw_value', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'digits', $MAYBE, $depth);
    $class->use_set_property($name, $proto, 'value_pos', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'update_policy', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'inverted', $BOOL, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkHScrollbar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHScrollbar";
    my $name = $proto->{'widget'}{'name'};

    my $adjustment = $class->use_par($proto, 'adjustment', $DEFAULT, '0 0 100 1 10 10');
    my ($value, $lower, $upper, $step, $page, $page_size) =
        split(" ", $adjustment);

    $class->load_class("Gtk2::Adjustment");
    $class->add_to_UI($depth,  "\$work->{'$name-adj'} = new Gtk2::Adjustment(".
        "$value, $lower, $upper, $step, $page, $page_size);");
    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::HScrollbar(".
        "\$work->{'$name-adj'});");

    $class->use_set_property($name, $proto, 'update_policy', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'inverted', $BOOL, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkVScrollbar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkVScrollbar";
    my $name = $proto->{'widget'}{'name'};

    my $adjustment = $class->use_par($proto, 'adjustment', $DEFAULT, '0 0 100 1 10 10');
    my ($value, $lower, $upper, $step, $page, $page_size) =
        split(" ", $adjustment);

    $class->add_to_UI($depth,  "\$work->{'$name-adj'} = new Gtk2::Adjustment(".
        "$value, $lower, $upper, $step, $page, $page_size);");
    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::VScrollbar(".
        "\$work->{'$name-adj'});");

    $class->use_set_property($name, $proto, 'update_policy', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'inverted', $BOOL, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkHSeparator {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHSeparatorDrawingArea";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::HSeparator;");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkVSeparator {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_VSeparator";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::VSeparator;");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkLayout {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkLayout";
    my $name = $proto->{'widget'}{'name'};

    $class->load_class("Gtk2::Adjustment");
    my $hadjustment = $class->use_par($proto, 'hadjustment',  $MAYBE);
    my ($value, $lower, $upper, $step, $page, $page_size) =
        split(" ", $hadjustment);
    $class->add_to_UI($depth,  "\$work->{'$name-hadj'} = new Gtk2::Adjustment(".
        "$value, $lower, $upper, $step, $page, $page_size);");

    my $vadjustment = $class->use_par($proto, 'vadjustment',  $MAYBE);
    ($value, $lower, $upper, $step, $page, $page_size) =
        split(" ", $hadjustment);
    $class->add_to_UI($depth,  "\$work->{'$name-vadj'} = new Gtk2::Adjustment(".
        "$value, $lower, $upper, $step, $page, $page_size);");

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::Layout(".
        "\$work->{'$name-hadj'}, \$work->{'$name-vadj'});");

    my $width  = $class->use_par($proto, 'width',  $DEFAULT, 0);
    my $height = $class->use_par($proto, 'height',  $DEFAULT, 0);
    $class->add_to_UI($depth, "\$widgets->{'$name'}->set_size(".
        "$width, $height);");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkList {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkList";
    my $name = $proto->{'widget'}{'name'};

#    unless ($class->get_internal_child($parent, $name, $proto, $depth)) {
        $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::List;");
#    }
    $class->use_set_property($name, $proto, 'selection_mode', $LOOKUP, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkMenu {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkMenu";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::Menu;");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkMenuBar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkMenuBar";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::MenuBar;");

    $class->use_set_property($name, $proto, 'shadow_type', $LOOKUP, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkMenuFactory {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkMenuFactory";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::MenuFactory(".");");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkImageMenuItem {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkImageMenuItem";
    my $name = $proto->{'widget'}{'name'};
    my $label = $class->use_par($proto, 'label', $DEFAULT, '');

    if ($proto->{'widget'}{'property'}{'stock'}) {
        # This is a stock menu item
        my $stock = $class->use_par($proto, 'stock', $MAYBE);
#        $label = Glade::Gnome->lookup($stock_item);
#        $stock_item = $Glade::Gnome::gnome_enums->{"GNOME_STOCK_PIXMAP_$stock_item"};
        $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
            "Gtk2::ImageMenuItem->new_from_stock('$stock', 
                $current_form\{'accelgroup'});");
    } elsif ($label) {
        if ($class->use_par($proto, 'use_underline', $BOOL)) {
            $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
                "new_with_mnemonic Gtk2::ImageMenuItem(_('$label'));");
        } else {
            $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
                "new_with_label Gtk2::ImageMenuItem(_('$label'));");
        }
    } else {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
            "new Gtk2::ImageMenuItem;");
    }
    $class->load_class("Gtk2::AccelLabel");
    
    $class->set_label_properties($parent, $name, $proto, $depth);
    $class->pack_widget($parent, $name, $proto, $depth);

    return $widgets->{$name};
}

sub new_GtkListItem {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkListItem";
    my $name = $proto->{'widget'}{'name'};
    my $label = $class->use_par($proto, 'label', $DEFAULT, '');

    if ($proto->{'widget'}{'property'}{'stock_item'}) {
# FIXME - this is a Gnome stock menu item and should be in Gnome
        my $stock_item = $class->use_par($proto, 'stock_item', $DEFAULT, '');
        $proto->{'widget'}{'property'}{'label'} = 
            {'value' => Glade::Gnome->lookup($stock_item)};
#        $label = Glade::Gnome->lookup($stock_item);
#        $stock_item = $Glade::Gnome::gnome_enums->{"GNOME_STOCK_PIXMAP_$stock_item"};
#        $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
#            "Gnome::Stock->menu_item('$stock_item', '$stock_item');");
    }
    if ($label) {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new_with_label Gtk2::ListItem(".
            "_('$label'));");
    } else {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::ListItem;");
    }
    $class->set_label_properties($parent, $name, $proto, $depth);
    $class->pack_widget($parent, $name, $proto, $depth);

    return $widgets->{$name};
}

sub new_GtkMenuItem {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkMenuItem";
    my $name = $proto->{'widget'}{'name'};

    $class->load_class("Gtk2::AccelLabel");
    if ($proto->{'widget'}{'property'}{'stock_item'}) {
# FIXME - this is a Gnome stock menu item and should be in Gnome
        my $stock_item = $class->use_par($proto, 'stock_item', $DEFAULT, '');
        $proto->{'widget'}{'property'}{'label'} = 
            {'value' => Glade::Gnome->lookup($stock_item)};
#        $label = Glade::Gnome->lookup($stock_item);
#        $stock_item = $Glade::Gnome::gnome_enums->{"GNOME_STOCK_PIXMAP_$stock_item"};
#        $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
#            "Gnome::Stock->menu_item('$stock_item', '$stock_item');");
    }
    my $use_underline = $class->use_par($proto, 'use_underline', $BOOL|$MAYBE);
    my $label = $class->use_par($proto, 'label', $DEFAULT, '');
    if ($label) {
        if ($use_underline) {
            $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
                "new_with_mnemonic Gtk2::MenuItem(_('$label'));");
        } else {
            $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
                "new_with_label Gtk2::MenuItem(_('$label'));");
        }
    } else {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::MenuItem();");
    }
    $class->set_label_properties($parent, $name, $proto, $depth);
    $class->pack_widget($parent, $name, $proto, $depth);

    return $widgets->{$name};
}

sub new_GtkCheckMenuItem {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCheckMenuItem";
    my $name = $proto->{'widget'}{'name'};

    $class->load_class("Gtk2::AccelLabel");

    my $use_underline = $class->use_par($proto, 'use_underline', $BOOL|$MAYBE);
    my $label  = $class->use_par($proto, 'label',  $DEFAULT, '');
    if ($label) {
        if ($use_underline) {
            $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
                "new_with_mnemonic Gtk2::CheckMenuItem(_('$label'));");
        } else {
            $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
                "new_with_label Gtk2::CheckMenuItem(_('$label'));");
        }
    } else {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::CheckMenuItem();");
    }
#    $class->add_to_UI($depth,  "\$widgets->{'$name'} = ".
#        "new Gtk2::CheckMenuItem();");

#    if ($class->use_par($proto, 'right_justify',    $BOOL, 'False')) {
#        $class->add_to_UI($depth, "\$widgets->{'$name'}->right_justify;");
#    }
    $class->use_set_property($name, $proto, 'active', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'always_show_toggle', $BOOL, $depth, 'set_show_toggle');

    $class->set_label_properties($parent, $name, $proto, $depth);
    $class->pack_widget($parent, $name, $proto, $depth);

    return $widgets->{$name};
}


sub new_GtkRadioMenuItem {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkRadioMenuItem";
    my $name = $proto->{'widget'}{'name'};
    my $label  = $class->use_par($proto, 'label', $DEFAULT, '');
    my $use_underline = $class->use_par($proto, 'use_underline',  $MAYBE);
    $class->load_class("Gtk2::AccelLabel");
    my $method;
    if ($use_underline) {
        $method = "new_with_mnemonic";
    } else {
        $method = "new_with_label";
    }
    my $group  = $class->use_par($proto, 'group',  $DEFAULT, $name);
    my $group_widget = "$current_form\{'rb_group'}{'$group'}";
    if (eval "defined $group_widget") {
        $class->add_to_UI($depth,  "\$widgets->{'$name'} = ".
            "$method Gtk2::RadioMenuItem($group_widget->get_group(), _('$label'));");
    } else {
        $class->add_to_UI($depth,  "\$widgets->{'$name'} = ".
            "$method Gtk2::RadioMenuItem(undef, _('$label'));");

        $class->add_to_UI($depth, "$group_widget = \$widgets->{'$name'};");
    }

    $class->use_set_property($name, $proto, 'active', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'always_show_toggle', $BOOL, $depth, 'set_show_toggle');

#    $class->set_label_properties($parent, $name, $proto, $depth);
    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkNotebook {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkNotebook";
    my $name = $proto->{'widget'}{'name'};

    my $ignore      = $class->use_par($proto, 'num_pages',   $DEFAULT, 0);
    
    unless ($class->get_internal_child($parent, $name, $proto, $depth)) {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::Notebook;");
    }

    $class->use_set_property($name, $proto, 'tab_pos', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'show_tabs', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'show_border', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'scrollable', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'tab_hborder', $INT, $depth);
    $class->use_set_property($name, $proto, 'tab_vborder', $INT, $depth);

    if ($class->use_par($proto, 'enable_popup', $BOOL|$MAYBE)) { 
        $class->add_to_UI($depth,  "\$widgets->{'$name'}->popup_enable();");
    } else {
        $class->add_to_UI($depth,  "\$widgets->{'$name'}->popup_disable();");
    }
    # 'num_pages'
    $nb->{$name} = {'panes' => [], 'pane' => 0, 'tab' => 0};

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkObject {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkObject";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::Object;");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkOptionMenu {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkOptionMenu";
    my $name = $proto->{'widget'}{'name'};
    my $item;
    my @items;
    my $count = 0;
    my $items          = $class->use_par($proto, 'items');
    my $history = $class->use_par($proto, 'history', $DEFAULT, 0);

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::OptionMenu;");
    $class->pack_widget($parent, $name, $proto, $depth);

    $class->add_to_UI($depth,  "\$widgets->{'${name}_menu'} = new Gtk2::Menu;");
    $class->pack_widget("$name", "${name}_menu", $proto, $depth);
    if (defined $items) {
        @items = split(/\n/, $items);
        foreach $item (@items) {
            if ($item) {
                $class->add_to_UI($depth,  "\$widgets->{'${name}_item$count'} = ".
                    "new Gtk2::MenuItem('$item');");
                $class->pack_widget("${name}_menu", "${name}_item$count", $proto, $depth+1);
                if ($count == $history) {
                    $class->add_to_UI($depth, 
                        "${current_form}\{'${name}_item$count'}\->activate;");
                }
                $count++;
            }
        }
        $class->add_to_UI($depth, 
            "${current_form}\{'$name'}->set_history( $history);");
    }
    return $widgets->{$name};
}

#sub new_image {&new_GtkImage(@_);}
sub new_GtkImage {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkImage";
    my $name = $proto->{'widget'}{'name'};
    my $stock  = $class->use_par($proto, 'stock',  $MAYBE);
    my $icon_sizes = [
        'invalid',          #GTK_ICON_SIZE_INVALID,
        'menu',             #GTK_ICON_SIZE_MENU,
        'small-toolbar',    #GTK_ICON_SIZE_SMALL_TOOLBAR,
        'large-toolbar',    #GTK_ICON_SIZE_LARGE_TOOLBAR,
        'button',           #GTK_ICON_SIZE_BUTTON,
        'dnd',              #GTK_ICON_SIZE_DND,
        'dialog',           #GTK_ICON_SIZE_DIALOG
    ];
#    unless ($class->get_internal_child($parent, $name, $proto, $depth)) {
        if ($stock) {
            my $icon_size  = $class->use_par($proto, 'icon_size',  $DEFAULT, 0);
            $class->add_to_UI($depth,  "\$widgets->{'$name'} = ".
                "new_from_stock Gtk2::Image('$stock', '$icon_sizes->[$icon_size]');");

        } else {
            my $filename = $class->use_par($proto, 'pixbuf', $DEFAULT, '');
            unless ($filename) {
                $Glade_Perl->diag_print(2, "warn  No image file specified for $me ".
                    "'%s' so we are using the project logo instead", $name);
                $filename = $Glade_Perl->app->logo;
            }
            $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
                "\$class->create_image(\"$filename\", [\"\$Glade::Two::Run::pixmaps_directory\"]);");
            unless ($Glade_Perl->source->quick_gen or defined $widgets->{$name}) { 
    #            die sprintf(("\nerror %s failed to create pixmap from file '%s'"),
                $class->log_error("\$class->create_image($filename)", 
                    (sprintf(_("\nerror %s failed to create image from file '%s'"),
                        $me, $filename)));
            }
        }
#    }
    $class->set_misc_properties($parent, $name, $proto, $depth);
#print Dumper($proto);exit;
    delete $failures->{$INTERNAL_CHILD}{$parent}{$proto->{'internal-child'}};
    delete $proto->{'internal-child'};
    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub xnew_GtkPixmap {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkPixmap";
    my $name = $proto->{'widget'}{'name'};

    my $filename = $class->use_par($proto, 'filename', $DEFAULT, '');
    unless ($filename) {
        $Glade_Perl->diag_print(2, "warn  No pixmap file specified for GtkPixmap ".
            "'%s' so we are using the project logo instead", $name);
        $filename = $Glade_Perl->app->logo;
    }
    $filename = "\"\$Glade::Two::Run::pixmaps_directory/$filename\"";
    $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
        "\$class->create_pixmap($current_window, $filename);");
    unless ($Glade_Perl->source->quick_gen or defined $widgets->{$name}) { 
        die sprintf(("\nerror %s failed to create pixmap from file '%s'"),
#        $class->log_error(sprintf(("\nerror %s failed to create pixmap from file '%s'"),
            $me, $filename), "\n";
    }
    $class->use_set_property($name, $proto, 'build_insensitive', $BOOL, $depth);
    
    $class->set_misc_properties($parent, $name, $proto, $depth);
    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkPreview {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkPreview";
    my $name = $proto->{'widget'}{'name'};

    my $type = $class->use_par($proto, 'type', $BOOL) ? 'color' : 'grayscale';
    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::Preview(".
        "'$type');");

    $class->use_set_property($name, $proto, 'expand', $BOOL, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkProgressBar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkProgressBar";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::ProgressBar;");

    $class->use_set_property($name, $proto, 'orientation', $LOOKUP, $depth);
#    $class->use_set_property($name, $proto, 'bar_style', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'show_text', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'activity_mode', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'format', $LOOKUP, $depth, 'set_format_string');
    $class->use_set_property($name, $proto, 'fraction', $MAYBE, $depth);
    $class->use_set_property($name, $proto, 'pulse_step', $MAYBE, $depth);
    $class->use_set_property($name, $proto, 'text', $STRING, $depth);

#    my $text_xalign   = $class->use_par($proto, 'text_xalign', $MAYBE);
#    my $text_yalign   = $class->use_par($proto, 'text_yalign', $MAYBE);
#    if (defined $text_xalign or defined $text_yalign) {
#        $class->add_to_UI($depth, "\$widgets->{'$name'}->set_text_alignment(".
#            ($text_xalign||0.5).", ".($text_yalign||0.5).");");
#    }
#    my $value         = $class->use_par($proto, 'value', $DEFAULT, 0);
#    my $lower         = $class->use_par($proto, 'lower', $DEFAULT, 0);
#    my $upper         = $class->use_par($proto, 'upper', $DEFAULT, 0);
#    $class->add_to_UI($depth, "\$widgets->{'$name'}->configure(".
#        "$value, $lower, $upper);");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkSpinButton {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkSpinButton";
    my $name = $proto->{'widget'}{'name'};

    my $adjustment = $class->use_par($proto, 'adjustment', $DEFAULT, '0 0 100 1 10 10');
    my ($value, $lower, $upper, $step, $page, $page_size) =
        split(" ", $adjustment);
    my $climb_rate    = $class->use_par($proto, 'climb_rate',    $DEFAULT, 1);
    my $digits        = $class->use_par($proto, 'digits',        $DEFAULT, 1);
    
    $class->add_to_UI($depth,  "\$work->{'$name-adj'} = new Gtk2::Adjustment(".
        "$value, $lower, $upper, $step, $page, $page_size);");
    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::SpinButton(".
        "\$work->{'$name-adj'}, $climb_rate, $digits);");

    $class->use_set_property($name, $proto, 'update_policy', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'numeric', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'wrap', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'snap_to_ticks', $BOOL, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkStatusbar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkStatusbar";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::Statusbar;");
    $class->use_set_property($name, $proto, 'has_resize_grip', $BOOL, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkStyle {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkStyle";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::Style;");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkTable {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkTable";
    my $name = $proto->{'widget'}{'name'};
    my $rows            = $class->use_par($proto, 'n_rows');
    my $columns         = $class->use_par($proto, 'n_columns');
    my $homogeneous     = $class->use_par($proto, 'homogeneous',    $BOOL,    'False');
    
    unless ($class->get_internal_child($parent, $name, $proto, $depth)) {
        $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::Table(".
            "$rows, $columns, $homogeneous);");
    }
    $class->use_set_property($name, $proto, 'row_spacing', $MAYBE, $depth, 'set_row_spacings');
    $class->use_set_property($name, $proto, 'column_spacing', $MAYBE, $depth, 'set_col_spacings');

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkTextView {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkTextView";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::TextView;");

    $class->use_set_property($name, $proto, 'editable', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'cursor_visible', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'justification', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'wrap_mode', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'pixels_above_lines', $MAYBE, $depth);
    $class->use_set_property($name, $proto, 'pixels_below_lines', $MAYBE, $depth);
    $class->use_set_property($name, $proto, 'pixels_inside_wrap', $MAYBE, $depth);
    $class->use_set_property($name, $proto, 'left_margin', $MAYBE, $depth);
    $class->use_set_property($name, $proto, 'right_margin', $MAYBE, $depth);
    $class->use_set_property($name, $proto, 'indent', $MAYBE, $depth);

    $class->use_set_property($name, $proto, 'text', $STRING, $depth, 'get_buffer->set_text', ', -1');
#    my $text      = $class->use_par($proto, 'text'    ,  $DEFAULT, '');
#    $text =~ s/\n/\\n/g; # to get through add_to_UI()
#    ($text) && 
#    $class->add_to_UI($depth, "\$widgets->{'$name'}->get_buffer->set_text(".
#        "_(\"$text\"), -1);");

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub xnew_GtkTipsQuery {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkTipsQuery";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::TipsQuery;");
    $class->set_label_properties($parent, $name, $proto, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkToolbar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkTabbar";
    my $name = $proto->{'widget'}{'name'};
#    my $space_style = $class->use_par($proto, 'space_style', $LOOKUP,  'empty');
#    my $space_size  = $class->use_par($proto, 'space_size',  $DEFAULT, 5);
#    my $relief      = $class->use_par($proto, 'relief',      $LOOKUP,  'normal');

    $class->add_to_UI($depth,  "\$widgets->{'$name'} = new Gtk2::Toolbar();");

    $class->use_set_property($name, $proto, 'orientation', $LOOKUP, $depth);
    $class->use_set_property($name, $proto, 'tooltips', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'toolbar_style', $LOOKUP, $depth, 'set_style');

    $class->pack_widget($parent, $name, $proto, $depth);
    # Store the tooltips parameter for append_element to check later
#    eval "$current_form\{'$name'}{'tooltips'} = $tooltips";
    return $widgets->{$name};
}

sub new_GtkTreeView {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkTreeView";
    my $name = $proto->{'widget'}{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk2::TreeView;");

    $class->use_set_property($name, $proto, 'headers_visible', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'enable_search', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'reorderable', $BOOL, $depth);
    $class->use_set_property($name, $proto, 'rules_hint', $BOOL, $depth);

    $class->pack_widget($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

1;

__END__

