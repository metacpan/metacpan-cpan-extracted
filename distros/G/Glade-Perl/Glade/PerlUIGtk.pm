package Glade::PerlUIGtk;
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
    use Glade::PerlSource qw( :VARS :METHODS );
    use vars              qw( 
                            $PACKAGE $VERSION $AUTHOR $DATE
                            @VARS @METHODS
                            @EXPORT @EXPORT_OK %EXPORT_TAGS 
                            $CList_column
                            $CTree_column
                            $nb
                            @Notebook_panes
                            $Notebook_pane
                            $Notebook_tab
                            $enums
                          );
    $PACKAGE      = __PACKAGE__;
    $VERSION      = q(0.61);
    $AUTHOR       = q(Dermot Musgrove <dermot.musgrove@virgin.net>);
    $DATE         = q(Sun Nov 17 03:21:11 GMT 2002);
    @VARS           = qw( 
                            $CList_column
                            $CTree_column
                            $nb
                            @Notebook_panes
                            $Notebook_pane
                            $Notebook_tab
                            $enums
                        );
    # These symbols (globals and functions) are always exported
    @EXPORT         =   qw(  );
    # Optionally exported package symbols (globals and functions)
    @EXPORT_OK    = ( @METHODS, @VARS );
    # Tags (groups of symbols) to export		
    %EXPORT_TAGS  = (
                        'METHODS' => [@METHODS] , 
                        'VARS'    => [@VARS]    
                    );
}

$CList_column    = 0;
$CTree_column    = 0;
$Notebook_pane   = 0;
$Notebook_tab    = 0;

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
    unless ($lookup) {
        $lookup = $self;
        $lookup =~ s/^G[DT]K_//;    # strip off leading GDK_ or GTK_
        foreach my $type ( 
            'WINDOW',       'WIN_POS',      'JUSTIFY',      
            'POLICY',       'SELECTION',    'ORIENTATION',
            'TOOLBAR_SPACE','EXTENSION_EVENTS',
            'TOOLBAR',      'TOOLBAR_CHILD','TREE_VIEW', 
            'BUTTONBOX',    'UPDATE',       'PACK',
            'POS',          'ARROW',        'BUTTONBOX', 
            'CURVE_TYPE',   'PROGRESS',     'VISUAL',       
            'IMAGE',        'CALENDAR',     'SHADOW',
            'CLOCK',        'RELIEF',       'SIDE',
            'ANCHOR', 
            ) {
            # Remove leading GTK type
            last if $lookup =~ s/^${type}_//; # finish early
        }
        $lookup = lc($lookup);
        # Cache this enum for later use
        $enums->{$self} = $lookup;
    }
    return $lookup;
}

#===============================================================================
#=========== Gtk widget constructors                                ============
#===============================================================================
sub new_GtkAccelGroup {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkAccelGroup";
    my $name = $proto->{name};

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gtk::AccelGroup;" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkAccelLabel {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkAccelLabel";
    my $name = $proto->{'name'};
    my $label   = $class->use_par($proto,'label',   $DEFAULT, '' );
    my $justify = $class->use_par($proto, 'justify',$LOOKUP,  'left' );
    my $wrap    = $class->use_par($proto, 'wrap', $BOOL, 'False' );
    my $pattern = $label;

    if ($label =~ /_/) {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
            "new Gtk::AccelLabel('');" );
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->parse_uline(".
            "_('$label') );" );
    } else {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
            "new Gtk::AccelLabel(_('$label'));" );
    }
# FIXME How do we know which widget/signal to emit?
# Should we use set_accel_widget? Probably I guess but how?
# How should we check that this is all correct?
# Look at gnome-libs gnome-libs/libgnomeui/gnome-app-helper.c
#use Data::Dumper; print Dumper($proto);
#    $class->add_to_UI( -$depth, "\$widgets->{'$name'}->set_accel_widget(".
#        "$current_form\{$proto->{'signal'}{'object'}});" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_justify(".
        "'$justify' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_line_wrap($wrap );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    $class->set_misc_properties($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkAdjustment {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkAdjustment";
    my $name = $proto->{'name'};
    my $hvalue   = $class->use_par($proto, 'hvalue',       $DEFAULT,    0 );
    my $hlower   = $class->use_par($proto, 'hlower',       $DEFAULT,    0 );
    my $hupper   = $class->use_par($proto, 'hupper',       $DEFAULT,    0 );
    my $hstep    = $class->use_par($proto, 'hstep',        $DEFAULT,    0 );
    my $hpage    = $class->use_par($proto, 'hpage',        $DEFAULT,    0 );
    my $hpage_size = $class->use_par($proto, 'hpage_size', $DEFAULT,    0 );

    $class->add_to_UI( $depth,  "\$widgets->{$name-adj} = new Gtk::Adjustment(".
                        "$hvalue, $hlower, $hupper, ".
                        "$hstep, $hpage, $hpage_size );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkAlignment {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkAlignment";
    my $name = $proto->{'name'};
    my $xalign    = $class->use_par($proto, 'xalign',    $DEFAULT,    0.5 );
    my $yalign    = $class->use_par($proto, 'yalign',    $DEFAULT,    0.5 );
    my $xscale    = $class->use_par($proto, 'xscale',    $DEFAULT,    0.5 );
    my $yscale    = $class->use_par($proto, 'yscale',    $DEFAULT,    0.5 );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Alignment(".
        "$xalign, $yalign, $xscale, $yscale );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkArrow {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkArrow";
    my $name = $proto->{'name'};
    my $arrow_type  = $class->use_par($proto, 'arrow_type',  $LOOKUP,    'right' );
    my $shadow_type = $class->use_par($proto, 'shadow_type', $LOOKUP,    '' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Arrow(".
        "'$arrow_type', '$shadow_type' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    $class->set_misc_properties($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkAspectFrame {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkAspectFrame";
    my $name = $proto->{'name'};
    my $label        = $class->use_par($proto, 'label',        $DEFAULT,    ''     );
    my $xalign       = $class->use_par($proto, 'xalign',       $DEFAULT,    0.5    );
    my $yalign       = $class->use_par($proto, 'yalign',       $DEFAULT,    0.5    );
    my $ratio        = $class->use_par($proto, 'ratio',        $DEFAULT,    1      );
    my $obey_child   = $class->use_par($proto, 'obey_child',   $BOOL,       'True' );
    my $label_xalign = $class->use_par($proto, 'label_xalign', $DEFAULT,    0.5    );
    my $label_yalign = $class->use_par($proto, 'label_xalign', $DEFAULT,    0.5    );
    my $shadow_type  = $class->use_par($proto, 'shadow_type',  $LOOKUP,    'right' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::AspectFrame(".
        "_('$label'), $xalign, $yalign, $ratio, $obey_child );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_label_align(".
        "$label_xalign, $label_yalign );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_shadow_type(".
        "'$shadow_type' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkButton {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkButton";
    my $name = $proto->{'name'};
    my $relief = $class->use_par($proto, 'relief', $LOOKUP, 'normal' );
# FIXME - toolbar buttons with a removed label don't have a child_name
#   but can have a sub-widget. allow this
    unless ($class->new_from_child_name($parent, $name, $proto, $depth )) {
        my $label = $class->use_par($proto, 'label', $DEFAULT,  '' );
        my $stock_button = $class->use_par($proto, 'stock_button',  $LOOKUP, '');
        if ($label) {
# FIXME This should probably be split into GnomeStock(Button) and GtkButton
            if ($stock_button) {
                $Glade_Perl->diag_print(2, $proto);
                $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
                    "new Gnome::Stock->button('$stock_button' );" );

            } else {
                $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
                    "new Gtk::Button(_('$label'));");
            }

        } else {
            if ($stock_button) {
                $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
                    "Gnome::Stock->button('$stock_button' );" );
            } elsif (! $proto->{'stock_pixmap'}) {
                $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
                    "new Gtk::Button;" );
            }
        }
        $class->pack_widget($parent, $name, $proto, $depth );
        if (_($label) =~ /_/) {
            $class->add_to_UI( $depth,
                "$current_form\{'$name-key'} = ".
                    "$current_form\{'$name'}->child->parse_uline(_('$label') );");
            $class->add_to_UI( $depth,
                "$current_form\{'$name'}->add_accelerator(".
                    "'clicked', $current_form\{'accelgroup'}, ". 
                    "$current_form\{'$name-key'}, 'mod1_mask', ['visible', 'locked'] );");
            undef $widgets->{"$name-key"};
        }
    }
    if ($relief ne 'normal') {
        $class->add_to_UI( $depth, 
            "$current_form\{'$name'}->set_relief('$relief');");
    }
    return $widgets->{$name};
}

sub new_GtkCalendar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCalendar";
    my $name = $proto->{'name'};
    my @options;
    push @options, 'show_heading'       if 
        $class->use_par($proto, 'show_heading',      $BOOL, 'False' );
    push @options, 'show_day_names'     if 
        $class->use_par($proto, 'show_day_names',    $BOOL, 'False' );
    push @options, 'no_month_change'    if 
        $class->use_par($proto, 'no_month_change',   $BOOL, 'False' );
    push @options, 'show_week_numbers'  if 
        $class->use_par($proto, 'show_week_numbers', $BOOL, 'False' );
    push @options, 'week_start_monday'  if 
        $class->use_par($proto, 'week_start_monday', $BOOL, 'False' );
    my $display_options;
    if (scalar @options) {
        $display_options = "['".join("', '", @options)."']"
    } else {
        $display_options = '[]'
    }

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Calendar;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->display_options(".
        "$display_options );" );
    $class->add_to_UI( $depth, "\$work->{'$name-date'} = [localtime];");
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->select_day(".
        "\$work->{'$name-date'}[3] );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->select_month(".
        "\$work->{'$name-date'}[4], \$work->{'$name-date'}[5] + 1900);" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkCheckButton {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCheckButton";
    my $name = $proto->{'name'};
    my $label   = $class->use_par($proto, 'label',  $DEFAULT, '' );
    my $draw_indicator = $class->use_par($proto, 'draw_indicator', $BOOL, 'False' );
    my $active  = $class->use_par($proto, 'active', $BOOL,    'False' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::CheckButton(".
        "_('$label'));" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_mode($draw_indicator );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_state($active );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    if (_($label) =~ /_/) {
        $class->add_to_UI( $depth,
            "$current_form\{'$name-key'} = ".
                "$current_form\{'$name'}->child->parse_uline(_('$label') );");
        $class->add_to_UI( $depth,
            "$current_form\{'$name'}->add_accelerator(".
                "'clicked', $current_form\{'accelgroup'}, ". 
                "$current_form\{'$name-key'}, 'mod1_mask', ['visible', 'locked'] );");
        undef $widgets->{"$name-key"};
    }
    return $widgets->{$name};
}

sub new_GtkCheckMenuItem {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCheckMenuItem";
    my $name = $proto->{'name'};
    my $label  = $class->use_par($proto, 'label',  $DEFAULT, '' );
    my $active = $class->use_par($proto, 'active', $BOOL,    'False' );
    my $always_show_toggle= $class->use_par($proto, 'always_show_toggle', $BOOL, 'False' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
        "new_with_label Gtk::CheckMenuItem(_('$label'));" );

    if ($class->use_par($proto, 'right_justify',    $BOOL, 'False' )) {
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->right_justify;" );
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_state($active );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_show_toggle($always_show_toggle );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    if (_($label) =~ /_/) {
        $class->add_to_UI( $depth,
            "$current_form\{'$name-key'} = ".
                "$current_form\{'$name'}->child->parse_uline(_('$label') );");
        $class->add_to_UI( $depth,
            "$current_form\{'$name'}->add_accelerator(".
                "'activate', $current_form\{'accelgroup'}, ". 
                "$current_form\{'$name-key'}, 'mod1_mask', ['visible', 'locked'] );");
        undef $widgets->{"$name-key"};
    }
    return $widgets->{$name};
}


sub new_GtkCList {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCList";
    my $name = $proto->{'name'};
    my $columns        = $class->use_par($proto, 'columns' );
    my $selection_mode = $class->use_par($proto, 'selection_mode', $LOOKUP );
    my $shadow_type    = $class->use_par($proto, 'shadow_type',    $LOOKUP );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::CList(".
        "$columns );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_selection_mode(".
        "'$selection_mode' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_border(".
        "'$shadow_type' );" );
    if ($class->use_par($proto, 'show_titles', $BOOL, 'True' )) {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'}->column_titles_show;" );
    }
    my @column_widths     = split(',', $class->use_par($proto, 'column_widths' ));
    $CList_column = 0;
    my $i = 0;
    while ($i < scalar(@column_widths)) { 
        $Glade_Perl->diag_print(8, 
            "%s- Setting column %s to width %s in %s",
            $indent, $i, $column_widths[$i], $me);
        $class->add_to_UI( $depth,  "\$widgets->{'$name'}->set_column_width(".
            "$i, $column_widths[$i] );" );
        $i++;
    }

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkCTree {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCTree";
    my $name = $proto->{'name'};
    my $columns        = $class->use_par($proto, 'columns' );
    my $selection_mode = $class->use_par($proto, 'selection_mode', $LOOKUP );
    my $shadow_type    = $class->use_par($proto, 'shadow_type',    $LOOKUP );
    my $tree_column    = $class->use_par($proto, 'tree_column',    $DEFAULT,    0 );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::CTree(".
        "$columns, $tree_column );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_selection_mode(".
        "'$selection_mode' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_border(".
        "'$shadow_type' );" );
    if ($class->use_par($proto, 'show_titles',    $BOOL,    'True'    )) {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'}->column_titles_show;" );
    }
    my @column_widths     = split(',', $class->use_par($proto, 'column_widths' ));
    $CTree_column = 0;
    my $i = 0;
    while ($i < scalar(@column_widths)) { 
        $Glade_Perl->diag_print(8, 
            "%s- Setting column %s to width %s in %s",
            $indent, $i, $column_widths[$i], $me);
        $class->add_to_UI( $depth,  "\$widgets->{'$name'}->set_column_width(".
            "$i, $column_widths[$i] );" );
        $i++;
    }
    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkColorSelection {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkColorSelection";
    my $name = $proto->{'name'};
    my $policy  = $class->use_par($proto, 'policy',  $LOOKUP, 'continuous');

    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gtk::ColorSelection;");
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_update_policy(".
        "'$policy' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkColorSelectionDialog {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkColorSelectionDialog";
    my $name = $proto->{'name'};
    my $title  = $class->use_par($proto,'title',  $DEFAULT, 'File Selection' );
    my $policy = $class->use_par($proto,'policy', $LOOKUP, 'continuous' );
    
    $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
        "new Gtk::ColorSelectionDialog(_('$title') );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->colorsel->".
        "set_update_policy( '$policy' );" );

    $class->set_window_properties($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkCombo {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCombo";
    my $name = $proto->{'name'};
    my $case_sensitive = $class->use_par($proto, 'case_sensitive', $BOOL,   'False' );
    my $use_arrows     = $class->use_par($proto, 'use_arrows',     $BOOL,   'True' );
    my $use_arrows_always= $class->use_par($proto, 'use_arrows_always', $BOOL, 'False' );
    my $items          = $class->use_par($proto, 'items',          $DEFAULT, '' );
    my $ok_if_empty    = $class->use_par($proto, 'ok_if_empty',    $BOOL,   'True' );
    my $value_in_list  = $class->use_par($proto, 'value_in_list',  $BOOL,   'False' );
    unless ($ok_if_empty) {
        if ($items eq '') {
            $Glade_Perl->diag_print (1, "warn  Widget '%s' does not have any ".
                "items specified in %s", $name, $me);
        }
    }
    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Combo;" );
    if ($value_in_list) {
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_value_in_list(".
            "$value_in_list, $ok_if_empty );" );
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_case_sensitive(".
        "$case_sensitive );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_use_arrows(".
        "$use_arrows );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_use_arrows_always(".
        "$use_arrows_always );" );
    my @popdown_strings;
    my $popdown_strings;
    if (defined $items) {
        @popdown_strings = split(/\n/, $items );
        $popdown_strings = "'".join("', '",  @popdown_strings)."'";
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_popdown_strings(".
            " $popdown_strings );" );
    }

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkCurve {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkCurve";
    my $name = $proto->{'name'};
    my $min_x      = $class->use_par($proto, 'min_x',      $DEFAULT,    0 );
    my $min_y      = $class->use_par($proto, 'min_y',      $DEFAULT,    0 );
    my $max_x      = $class->use_par($proto, 'max_x',      $DEFAULT,    1 );
    my $max_y      = $class->use_par($proto, 'max_y',      $DEFAULT,    1 );
    my $curve_type = $class->use_par($proto, 'curve_type', $LOOKUP, 'spline' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Curve;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_curve_type('$curve_type' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_range(".
        "$min_x, $min_y, $max_x, $max_y );" );
    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkDialog {
    my ($class, $parent, $proto, $depth, $mainmenu) = @_;
    my $me = "$class->new_GtkDialog";
    my $name = $proto->{'name'};
    my $title        = $class->use_par($proto, 'title', $DEFAULT, '' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Dialog;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_title(_('$title') );" );

    $class->set_window_properties($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkDrawingArea {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkDrawingArea";
    my $name = $proto->{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::DrawingArea;" );
    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkEntry {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkEntry";
    my $name = $proto->{'name'};
    my $text         = $class->use_par($proto, 'text',            $DEFAULT, '' );
    my $text_max_length = $class->use_par($proto, 'text_max_length', $DEFAULT,    0 );
    my $text_visible = $class->use_par($proto, 'text_visible',    $BOOL,    'True' );
    my $editable     = $class->use_par($proto, 'editable',        $BOOL,    'True' );
    my $max_length   = $class->use_par($proto, 'text_max_length', $DEFAULT, 0 );

    unless ($class->new_from_child_name($parent, $name, $proto, $depth )) {
        if ($max_length) {
            $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
                "new_with_max_length Gtk::Entry($max_length );" );
        } else {
            $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gtk::Entry;" );
        }
        $class->pack_widget($parent, $name, $proto, $depth );
    }
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_text(_('$text') );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_max_length(".
        "$text_max_length );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_visibility(".
        "$text_visible );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_editable($editable );" );

    return $widgets->{$name};
}

sub new_GtkEventBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkEventBox";
    my $name = $proto->{'name'};
    $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gtk::EventBox;" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkFileSelection {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkFileSelection";
    my $name = $proto->{'name'};
    my $title = $class->use_par($proto,'title', $DEFAULT, 'File Selection' );
    my $show_file_op_buttons    = $class->use_par($proto,'show_file_op_buttons',    $BOOL,    'True' );

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::FileSelection(_('$title') );" );
    if ($show_file_op_buttons) {
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->show_fileop_buttons;" );
    } else {
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->hide_fileop_buttons;" );
    }
    $class->set_window_properties($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkFixed {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkFixed";
    my $name = $proto->{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::Fixed;" );
    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkFontSelection {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkFontSelection";
    my $name = $proto->{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::FontSelection;" );
    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkFontSelectionDialog {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkFontSelectionDialog";
    my $name = $proto->{'name'};
    my $title = $class->use_par($proto,'title', $DEFAULT, 'Font Selection' );

    $class->add_to_UI($depth, "\$widgets->{'$name'} = ".
        "new Gtk::FontSelectionDialog(_('$title') );" );

    $class->set_window_properties($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkFrame {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkFrame";
    my $name = $proto->{'name'};
    my $label        = $class->use_par($proto, 'label'    ,    $DEFAULT, '');
    my $shadow_type  = $class->use_par($proto, 'shadow_type',  $LOOKUP     );
    my $label_xalign = $class->use_par($proto, 'label_xalign', $DEFAULT, 0 );
    my $label_yalign = $class->use_par($proto, 'label_yalign', $DEFAULT, 0 );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
        "new Gtk::Frame(_('$label'));" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_label_align(".
        "$label_xalign, $label_yalign );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_shadow_type(".
        "'$shadow_type' );" );
    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkGammaCurve {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkGammaCurve";
    my $name = $proto->{'name'};
    my $min_x      = $class->use_par($proto, 'min_x',        $DEFAULT,    0 );
    my $min_y      = $class->use_par($proto, 'min_y',        $DEFAULT,    0 );
    my $max_x      = $class->use_par($proto, 'max_x',        $DEFAULT,    1 );
    my $max_y      = $class->use_par($proto, 'max_y',        $DEFAULT,    1 );
    my $curve_type = $class->use_par($proto, 'curve_type',   $LOOKUP, 'spline' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::GammaCurve;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->curve->set_curve_type(".
        "'$curve_type' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->curve->set_range(".
        "$min_x, $min_y, $max_x, $max_y );" );
    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}


sub new_GtkHandleBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHandleBox";
    my $name = $proto->{'name'};
    my $handle_position = $class->use_par($proto, 'handle_position', $LOOKUP, 'left' );
    my $shadow_type     = $class->use_par($proto, 'shadow_type',     $LOOKUP , 'out');
    my $snap_edge       = $class->use_par($proto, 'snap_edge',       $LOOKUP, 'top' );

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::HandleBox;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_handle_position(".
        "'$handle_position' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_shadow_type(".
        "'$shadow_type' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_snap_edge(".
        "'$snap_edge' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkHBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHBox";
    my $name = $proto->{'name'};
    my $homogeneous = $class->use_par($proto, 'homogeneous', $BOOL,    'False' );
    my $spacing     = $class->use_par($proto, 'spacing'    , $DEFAULT, 0 );

    unless ($class->new_from_child_name($parent, $name, $proto, $depth )) {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::HBox(".
            "$homogeneous, $spacing );" );
        $class->pack_widget($parent, $name, $proto, $depth );
    }
    
    return $widgets->{$name};
}

sub new_GtkHButtonBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHButtonBox";
    my $name = $proto->{'name'};
    my $layout_style    = $class->use_par($proto, 'layout_style',    $LOOKUP, 'default' );
    my $spacing         = $class->use_par($proto, 'spacing',         $DEFAULT,    0 );
    my $child_min_width = $class->use_par($proto, 'child_min_width', $DEFAULT,    0 );
    my $child_min_height = $class->use_par($proto, 'child_min_height', $DEFAULT,    0 );
    my $child_ipad_x    = $class->use_par($proto, 'child_ipad_x',    $DEFAULT,    0 );
    my $child_ipad_y    = $class->use_par($proto, 'child_ipad_y',    $DEFAULT,    0 );

    unless ($class->new_from_child_name($parent, $name, $proto, $depth )) {
        $class->add_to_UI( $depth, "\$widgets->{'$name'} = new Gtk::HButtonBox;" );
        $class->pack_widget($parent, $name, $proto, $depth );
    }
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_layout(".
        "'$layout_style' );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_spacing(".
        "$spacing );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_child_size(".
        "$child_min_width, $child_min_height );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_child_ipadding(".
        "$child_ipad_x, $child_ipad_y );" );

    return $widgets->{$name};
}

sub new_GtkHPaned {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHPaned";
    my $name = $proto->{'name'};
    my $handle_size = $class->use_par($proto, 'handle_size', $DEFAULT, 0 );
    my $gutter_size = $class->use_par($proto, 'gutter_size', $DEFAULT, 0 );
    my $position = $class->use_par($proto, 'position', $DEFAULT, 0);

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::HPaned;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->handle_size(".
        "$handle_size );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->gutter_size(".
        "$gutter_size );" );
    $position &&
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_position(".
            "$position );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkHRuler {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHRuler";
    my $name = $proto->{'name'};
    my $lower    = $class->use_par($proto, 'lower',    $DEFAULT, 0 );
    my $upper    = $class->use_par($proto, 'upper',    $DEFAULT, 10 );
    my $position = $class->use_par($proto, 'position', $DEFAULT, 0 );
    my $max_size = $class->use_par($proto, 'max_size', $DEFAULT, 10 );
    my $metric   = $class->use_par($proto, 'metric',   $BOOL,    'False' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::HRuler;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_range(".
        "$lower, $upper, $position, $max_size );" );
    if ($metric) {
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_metric;" );
    }
    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkHScale {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHScale";
    my $name = $proto->{'name'};
    my $pre = '';
    $pre = 'h' if $proto->{'hlower'}; # cater for Glade <= 0.5.1
    my $lower     = $class->use_par($proto, $pre.'lower',     $DEFAULT, 0 );
    my $upper     = $class->use_par($proto, $pre.'upper',     $DEFAULT, 100 );
    my $step      = $class->use_par($proto, $pre.'step',      $DEFAULT, 1 );
    my $page      = $class->use_par($proto, $pre.'page',      $DEFAULT, 10 );
    my $page_size = $class->use_par($proto, $pre.'page_size', $DEFAULT, 10 );
    my $value     = $class->use_par($proto, $pre.'value',     $DEFAULT, 0 );
    my $policy     = $class->use_par($proto, 'policy',     $LOOKUP, 'continuous' );
    my $draw_value = $class->use_par($proto, 'draw_value', $BOOL,    'True' );
    my $digits     = $class->use_par($proto, 'digits',     $DEFAULT, 1 );
    my $value_pos  = $class->use_par($proto, 'value_pos',  $LOOKUP, 'top' );

    $class->add_to_UI( $depth,  "\$work->{'$name-adj'} = new Gtk::Adjustment(".
        "$value, $lower, $upper, $step, $page, $page_size );" );
    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::HScale(".
        "\$work->{'$name-adj'} );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_draw_value(".
        "$draw_value );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_digits(".
        "$digits );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_value_pos(".
        "'$value_pos' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_update_policy(".
        "'$policy' );" );
    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkHScrollbar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHScrollbar";
    my $name = $proto->{'name'};
    my $pre = '';
    $pre = 'h' if $proto->{'hlower'}; # Glade <= 0.5.1
    my $lower     = $class->use_par($proto, $pre.'lower',     $DEFAULT, 0 );
    my $upper     = $class->use_par($proto, $pre.'upper',     $DEFAULT, 100 );
    my $step      = $class->use_par($proto, $pre.'step',      $DEFAULT, 1 );
    my $page      = $class->use_par($proto, $pre.'page',      $DEFAULT, 10 );
    my $page_size = $class->use_par($proto, $pre.'page_size', $DEFAULT, 10 );
    my $value     = $class->use_par($proto, $pre.'value',     $DEFAULT, 0 );
    my $policy     = $class->use_par($proto, 'policy',     $LOOKUP, 'continuous' );

    $class->add_to_UI( $depth,  "\$work->{'$name-adj'} = new Gtk::Adjustment(".
        "$value, $lower, $upper, $step, $page, $page_size );" );
    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::HScrollbar(".
        "\$work->{'$name-adj'} );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_update_policy(".
        "'$policy' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkHSeparator {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHSeparatorDrawingArea";
    my $name = $proto->{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::HSeparator;" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkImage {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkImage";
    my $name = $proto->{'name'};
    my $image_width  = $class->use_par($proto, 'image_width',  $DEFAULT, 100 );
    my $image_height = $class->use_par($proto, 'image_height', $DEFAULT, 100 );
    my $image_type   = $class->use_par($proto, 'image_type',   $LOOKUP, 'normal' );
    my $image_visual = $class->use_par($proto, 'image_visual', $LOOKUP, 'system' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Image(".
        "Gtk::Gdk::Image->new('$image_type', ".
            "Gtk::Gdk::Visual->$image_visual, $image_width, $image_height ), ".
        "undef );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    $class->set_misc_properties($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkInputDialog {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkHInputDialog";
    my $name = $proto->{'name'};
    my $title        = $class->use_par($proto, 'title', $DEFAULT, '' );

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::InputDialog;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_title(_('$title') );" );

    $class->set_window_properties($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkLabel {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkLabel";
    my $name = $proto->{'name'};
    my $label   = $class->use_par($proto, 'label',   $DEFAULT, '' );
    my $justify = $class->use_par($proto, 'justify', $LOOKUP,  'center' );
    my $wrap    = $class->use_par($proto, 'wrap', $BOOL, 'False' );

    if ($label =~ /_/) {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Label('');" );
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->parse_uline(".
            "_('$label') );" );
    } else {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Label(".
            "_('$label'));" );
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_justify('$justify' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_line_wrap($wrap );" );

    $class->pack_widget($parent, $name, $proto, $depth);
    $class->set_misc_properties($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkLayout {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkLayout";
    my $name = $proto->{'name'};
    my $hstep = $class->use_par($proto, 'hstep', $DEFAULT, 10 );
    my $vstep = $class->use_par($proto, 'vstep', $DEFAULT, 10 );
    my $area_width  = $class->use_par($proto, 'area_width',  $DEFAULT, 0 );
    my $area_height = $class->use_par($proto, 'area_height',  $DEFAULT, 0 );
    
    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::Layout(".
        "undef, undef );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_size(".
        "$area_width, $area_height );" );
    $class->add_to_UI( $depth, 
        "\$widgets->{'$name'}->get_hadjustment->step_increment($hstep );" );
    $class->add_to_UI( $depth, 
        "\$widgets->{'$name'}->get_vadjustment->step_increment($vstep );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkList {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkList";
    my $name = $proto->{'name'};
    my $selection_mode = $class->use_par($proto, 'selection_mode', $LOOKUP, 'single' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::List;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_selection_mode(".
        "'$selection_mode' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkMenu {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkMenu";
    my $name = $proto->{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::Menu;" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkMenuBar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkMenuBar";
    my $name = $proto->{'name'};
    my $shadow_type = $class->use_par($proto, 'shadow_type', $LOOKUP, 'out' );

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::MenuBar;" );
    $shadow_type &&
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_shadow_type(".
            "'$shadow_type' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkMenuFactory {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkMenuFactory";
    my $name = $proto->{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::MenuFactory("." );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkMenuItem {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkMenuItem";
    my $name = $proto->{'name'};
    my $label = $class->use_par($proto, 'label', $DEFAULT, '' );
    my $right_justify = $class->use_par($proto, 'right_justify', $BOOL, 'False' );

    if ($proto->{'stock_item'}) {
# FIXME - this is a Gnome stock menu item and should be in UIExtra
# FIXME convert this to do a proper lookup (maybe with new sub)
        my $stock_item = $class->use_par($proto, 'stock_item', $DEFAULT, '' );
        $stock_item =~ s/GNOMEUIINFO_MENU_(.*)_TREE/$1/;
# FIXME this creates the string - we should look it up instead
        $stock_item = ucfirst(lc($stock_item));
# FIXME this only does uline for first character wrong, wrong, wrong
        $label = "_".$stock_item;
#        $stock_item = $Glade::PerlUIExtra::gnome_enums->{"GNOME_STOCK_PIXMAP_$stock_item"};
#        $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
#            "Gnome::Stock->menu_item('$stock_item', '$stock_item');" );
    } 
    if ($label) {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::MenuItem(".
            "_('$label'));" );
    } else {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::MenuItem;" );
    }
    if ($right_justify) { 
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->right_justify;" );
    }
    $class->pack_widget($parent, $name, $proto, $depth );
    if (_($label) =~ /_/) {
        $class->add_to_UI( $depth,
            "$current_form\{'$name-key'} = ".
                "$current_form\{'$name'}->child->parse_uline(_('$label') );");
        $class->add_to_UI( $depth,
            "$current_form\{'$name'}->add_accelerator(".
                "'activate_item', $current_form\{'accelgroup'}, ". 
                "$current_form\{'$name-key'}, 'mod1_mask', ['visible', 'locked'] );");
        undef $widgets->{"$name-key"};
    }
    return $widgets->{$name};
}

sub new_GtkNotebook {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkNotebook";
    my $name = $proto->{'name'};
    my $tab_pos     = $class->use_par($proto, 'tab_pos'    , $LOOKUP, 'top' );
    my $show_tabs   = $class->use_par($proto, 'show_tabs',   $BOOL,   'True' );
    my $show_border = $class->use_par($proto, 'show_border', $BOOL,   'True' );
    my $scrollable  = $class->use_par($proto, 'scrollable',  $BOOL,   'True' );
    my $tab_hborder = $class->use_par($proto, 'tab_hborder', $DEFAULT, 0 );
    my $tab_vborder = $class->use_par($proto, 'tab_vborder', $DEFAULT, 0 );
    my $ignore      = $class->use_par($proto, 'num_pages',   $DEFAULT, 0 );
    
    unless ($class->new_from_child_name($parent, $name, $proto, $depth )) {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::Notebook;" );
        $class->pack_widget($parent, $name, $proto, $depth );
    }
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_tab_pos('$tab_pos' );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_show_tabs($show_tabs );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_show_border($show_border );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_scrollable($scrollable );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_tab_hborder($tab_hborder );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_tab_vborder($tab_vborder );" );
    if ($class->use_par($proto, 'popup_enable',    $BOOL,    'True'    )) { 
        $class->add_to_UI( $depth,  "$current_form\{'$name'}->popup_enable;" );
    }
    # 'num_pages'
    $nb->{$name} = {'panes' => [], 'pane' => 0, 'tab' => 0};
    @Notebook_panes = ();
    $Notebook_pane = 0;
    $Notebook_tab = 0;

    return $widgets->{$name};
}

sub new_GtkObject {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkObject";
    my $name = $proto->{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::Object;" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkOptionMenu {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkOptionMenu";
    my $name = $proto->{'name'};
    my $item;
    my @items;
    my $count = 0;
    my $items          = $class->use_par($proto, 'items' );
    my $initial_choice = $class->use_par($proto, 'initial_choice', $DEFAULT, 0 );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::OptionMenu;" );
    $class->pack_widget($parent, $name, $proto, $depth );

    $class->add_to_UI( $depth,  "\$widgets->{'${name}_menu'} = new Gtk::Menu;" );
    $class->pack_widget("$name", "${name}_menu", $proto, $depth );
    if (defined $items) {
        @items = split(/\n/, $items );
        foreach $item (@items) {
            if ($item) {
                $class->add_to_UI( $depth,  "\$widgets->{'${name}_item$count'} = ".
                    "new Gtk::MenuItem('$item' );" );
                $class->pack_widget("${name}_menu", "${name}_item$count", $proto, $depth+1 );
                if ($count == $initial_choice) {
                    $class->add_to_UI( $depth, 
                        "${current_form}\{'${name}_item$count'}\->activate;" );
                }
                $count++;
            }
        }
        $class->add_to_UI( $depth, 
            "${current_form}\{'$name'}->set_history( $initial_choice );" );
    }
    return $widgets->{$name};
}

sub new_GtkPacker {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkPacker";
    my $name = $proto->{'name'};
    my $default_border_width = $class->use_par($proto, 'default_border_width', $DEFAULT, 0 );
    my $default_ipad_x = $class->use_par($proto, 'default_ipad_x', $DEFAULT, 0 );
    my $default_ipad_y = $class->use_par($proto, 'default_ipad_y', $DEFAULT, 0 );
    my $default_pad_x  = $class->use_par($proto, 'default_pad_x',  $DEFAULT, 0 );
    my $default_pad_y  = $class->use_par($proto, 'default_pad_y',  $DEFAULT, 0 );
    my $use_default    = $class->use_par($proto, 'use_default',    $BOOL,    'True' );

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::Packer;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_default_border_width(".
        "$default_border_width );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_default_pad(".
        "$default_pad_x, $default_pad_y );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_default_ipad(".
        "$default_ipad_x, $default_ipad_y );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkPixmap {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkPixmap";
    my $name = $proto->{'name'};
    my $filename = $class->use_par($proto, 'filename', $DEFAULT, '' );
    my $build_insensitive = $class->use_par($proto, 'build_insensitive', $BOOL, 'False' );
    unless ($filename) {
        $Glade_Perl->diag_print(2, "warn  No pixmap file specified for GtkPixmap ".
            "'%s' so we are using the project logo instead", $name);
        $filename = $Glade_Perl->app->logo;
    }
    $filename = "\"\$Glade::PerlRun::pixmaps_directory/$filename\"";
    $class->add_to_UI( $depth, "\$widgets->{'$name'} = ".
        "\$class->create_pixmap($current_window, $filename );" );
    unless ($Glade_Perl->source->quick_gen or defined $widgets->{$name}) { 
        die sprintf(("\nerror %s failed to create pixmap from file '%s'"),
            $me, $filename), "\n";
    }
    unless ($build_insensitive) {
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_build_insensitive(".
            "$build_insensitive );" );
    }
    
    $class->pack_widget($parent, $name, $proto, $depth );
    $class->set_misc_properties($parent, $name, $proto, $depth);
    return $widgets->{$name};
}

sub new_GtkPreview {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkPreview";
    my $name = $proto->{'name'};
    my $type;
    my $color  = $class->use_par($proto, 'type',   $DEFAULT, 'True' );
    my $expand = $class->use_par($proto, 'expand', $BOOL,    'False' );
    if ($color) {$type='color'} else {$type = 'grayscale'}

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Preview(".
        "'$type' );" );

    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_expand(".
        "$expand );" );
    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkProgressBar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkProgressBar";
    my $name = $proto->{'name'};
    my $bar_style     = $class->use_par($proto, 'bar_style',   $LOOKUP, 'continuous' );
    my $activity_mode = $class->use_par($proto, 'activity_mode', $BOOL, 'False' );
    my $show_text     = $class->use_par($proto, 'show_text',   $BOOL,   'False' );
    my $text_xalign   = $class->use_par($proto, 'text_xalign', $DEFAULT, 0.5 );
    my $text_yalign   = $class->use_par($proto, 'text_yalign', $DEFAULT, 0.5 );
    my $format        = $class->use_par($proto, 'format',      $DEFAULT, '%P %%');
    my $value         = $class->use_par($proto, 'value',       $DEFAULT, 0 );
    my $lower         = $class->use_par($proto, 'lower',       $DEFAULT, 0 );
    my $upper         = $class->use_par($proto, 'upper',       $DEFAULT, 0 );
    my $orientation   = $class->use_par($proto, 'orientation',   $LOOKUP, 'left_to_right' );

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::ProgressBar;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_orientation(".
        "'$orientation' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_bar_style(".
        "'$bar_style' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_show_text(".
        "$show_text );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_activity_mode(".
        "$activity_mode );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_text_alignment(".
        "$text_xalign, $text_yalign );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_format_string(".
        "_('$format' ));" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->configure(".
        "$value, $lower, $upper );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkRadioButton {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkRadioButton";
    my $name = $proto->{'name'};
    my $label  = $class->use_par($proto, 'label'    ,  $DEFAULT, '' );
    my $draw_indicator = $class->use_par($proto, 'draw_indicator', $BOOL, 'False' );
    my $active = $class->use_par($proto, 'active',     $BOOL,    'False' );

    unless ($class->new_from_child_name($parent, $name, $proto, $depth )) {
        my $group  = $class->use_par($proto, 'group'    ,  $DEFAULT, '' );
        my $rb_group = "$current_form\{'rb-group-$group'}";

        if ($group) {
            if (eval "defined $rb_group") {
                $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
                    "new Gtk::RadioButton(_('$label'), $rb_group );" );
            } else {
                $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
                    "new Gtk::RadioButton(_('$label') );" );
                $class->add_to_UI( $depth,  "$rb_group = \$widgets->{'$name'};" );

            }
        } else {
            $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
                "new Gtk::RadioButton(_('$label') );" );
        }
        $class->pack_widget($parent, $name, $proto, $depth );
        if (_($label) =~ /_/) {
            $class->add_to_UI( $depth,
                "$current_form\{'$name-key'} = ".
                    "$current_form\{'$name'}->child->parse_uline(_('$label') );");
            $class->add_to_UI( $depth,
                "$current_form\{'$name'}->add_accelerator(".
                    "'clicked', $current_form\{'accelgroup'}, ". 
                    "$current_form\{'$name-key'}, 'mod1_mask', ['visible', 'locked'] );");
            undef $widgets->{"$name-key"};
        }
    }
    
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_mode(".
        "$draw_indicator );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_state(".
        "$active );" );

    return $widgets->{$name};
}

sub new_GtkRadioMenuItem {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkRadioMenuItem";
    my $name = $proto->{'name'};
    my $label  = $class->use_par($proto, 'label',  $DEFAULT, '' );
    my $right_justify = $class->use_par($proto, 'right_justify', $BOOL, 'False' );
    my $active = $class->use_par($proto, 'active', $BOOL,    'False' );
    my $always_show_toggle = $class->use_par($proto, 'always_show_toggle', $BOOL, 'True' );
    my $group  = $class->use_par($proto, 'group',  $DEFAULT, '' );
    my $rmi_group = "$current_form\{'rmi-group-$group'}";

    if ($group) {
        if (eval "defined $rmi_group") {
            $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
                "new Gtk::RadioMenuItem(_('$label'), $rmi_group );" );
        } else {
            $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
                "new Gtk::RadioMenuItem(_('$label') );" );
        }
        $class->add_to_UI( $depth,  "$rmi_group = \$widgets->{'$name'};" );
    } else {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = ".
            "new Gtk::RadioMenuItem(_('$label') );" );
    }

    if ($right_justify) {
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->right_justify;" );
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_state(".
        "$active );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_show_toggle(".
        "$always_show_toggle );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    if (_($label) =~ /_/) {
        $class->add_to_UI( $depth,
            "$current_form\{'$name-key'} = ".
                "$current_form\{'$name'}->child->parse_uline(_('$label') );");
        $class->add_to_UI( $depth,
            "$current_form\{'$name'}->add_accelerator(".
                "'activate', $current_form\{'accelgroup'}, ". 
                "$current_form\{'$name-key'}, 'mod1_mask', ['visible', 'locked'] );");
        undef $widgets->{"$name-key"};
    }
    return $widgets->{$name};
}

sub new_GtkScrolledWindow {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkScrolledWindow";
    my $name = $proto->{'name'};
    my $hscrollbar_policy = $class->use_par($proto, 'hscrollbar_policy', $LOOKUP, 'always' );
    my $vscrollbar_policy = $class->use_par($proto, 'vscrollbar_policy', $LOOKUP, 'always' );
    my $border_width      = $class->use_par($proto, 'border_width',      $DEFAULT,    0 );
    my $hupdate_policy    = $class->use_par($proto, 'hupdate_policy',    $LOOKUP, 'continuous' );
    my $vupdate_policy    = $class->use_par($proto, 'vupdate_policy',    $LOOKUP, 'continuous' );

    $class->add_to_UI( $depth,  
        "\$widgets->{'$name'} = new Gtk::ScrolledWindow( undef, undef);" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_policy(".
        "'$hscrollbar_policy', '$vscrollbar_policy' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->border_width(".
        "$border_width );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->hscrollbar->".
        "set_update_policy('$hupdate_policy' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->vscrollbar->".
        "set_update_policy('$vupdate_policy' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkSpinButton {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkSpinButton";
    my $name = $proto->{'name'};
    my $pre = '';
    $pre = 'h' if $proto->{'hlower'}; # cater for Glade <= 0.5.1
    my $lower     = $class->use_par($proto, $pre.'lower',     $DEFAULT, 0 );
    my $upper     = $class->use_par($proto, $pre.'upper',     $DEFAULT, 100 );
    my $step      = $class->use_par($proto, $pre.'step',      $DEFAULT, 1 );
    my $page      = $class->use_par($proto, $pre.'page',      $DEFAULT, 10 );
    my $page_size = $class->use_par($proto, $pre.'page_size', $DEFAULT, 10 );
    my $value     = $class->use_par($proto, $pre.'value',     $DEFAULT, 0 );
    my $climb_rate    = $class->use_par($proto, 'climb_rate',    $DEFAULT, 1 );
    my $digits        = $class->use_par($proto, 'digits',        $DEFAULT, 1 );
    my $numeric       = $class->use_par($proto, 'numeric',       $BOOL,    'False' );
    my $wrap          = $class->use_par($proto, 'wrap',          $BOOL,    'False' );
    my $update_policy = $class->use_par($proto, 'update_policy', $LOOKUP, 'continuous' );
    my $snap          = $class->use_par($proto, 'snap',          $BOOL,    'False' );
    
    $class->add_to_UI( $depth,  "\$work->{'$name-adj'} = new Gtk::Adjustment(".
        "$value, $lower, $upper, $step, $page, $page_size );" );
    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::SpinButton(".
        "\$work->{'$name-adj'}, $climb_rate, $digits );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_update_policy(".
        "'$update_policy' );" );
    if ($numeric) {
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_numeric(1);" );
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_wrap($wrap);" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_snap_to_ticks(".
        "$snap );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkStatusbar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkStatusbar";
    my $name = $proto->{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::Statusbar;" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkStyle {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkStyle";
    my $name = $proto->{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::Style;" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkTable {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkTable";
    my $name = $proto->{'name'};
    my $rows            = $class->use_par($proto, 'rows' );
    my $columns         = $class->use_par($proto, 'columns' );
    my $homogeneous     = $class->use_par($proto, 'homogeneous',    $BOOL,    'False' );
    my $row_spacing     = $class->use_par($proto, 'row_spacing',    $DEFAULT, 0 );
    my $column_spacing  = $class->use_par($proto, 'column_spacing', $DEFAULT, 0 );
    
    unless ($class->new_from_child_name($parent, $name, $proto, $depth )) {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Table(".
            "$rows, $columns, $homogeneous );" );
    }
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_row_spacings(".
        "$row_spacing );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_col_spacings(".
        "$column_spacing );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkText {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkText";
    my $name = $proto->{'name'};
    my $text      = $class->use_par($proto, 'text'    ,  $DEFAULT, '' );
    my $editable  = $class->use_par($proto, 'editable',  $BOOL,    'False' );

    $text =~ s/\n/\\n/g;
    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Text(".
        " undef, undef );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_editable(".
        "$editable );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->insert(".
        "undef, \$widgets->{'$name'}->style->text('normal'), undef, _(\"$text\"));" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkTipsQuery {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkTipsQuery";
    my $name = $proto->{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::TipsQuery;" );
    $class->pack_widget($parent, $name, $proto, $depth );
    $class->set_misc_properties($parent, $name, $proto, $depth);
    return $widgets->{$name};
}


sub new_GtkToggleButton {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkToggleButton";
    my $name = $proto->{'name'};
    my $active       = $class->use_par($proto, 'active', $BOOL, 'False' );
    my $relief = $class->use_par($proto, 'relief', $LOOKUP, 'normal' );

    unless ($class->new_from_child_name($parent, $name, $proto, $depth )) {
        my $label        = $class->use_par($proto, 'label'    ,    $DEFAULT, '' );
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::ToggleButton(".
            "_('$label') );" );
        $class->pack_widget($parent, $name, $proto, $depth );
        if (_($label) =~ /_/) {
            $class->add_to_UI( $depth,
                "$current_form\{'$name-key'} = ".
                    "$current_form\{'$name'}->child->parse_uline(_('$label') );");
            $class->add_to_UI( $depth,
                "$current_form\{'$name'}->add_accelerator(".
                    "'clicked', $current_form\{'accelgroup'}, ". 
                    "$current_form\{'$name-key'}, 'mod1_mask', ['visible', 'locked'] );");
            undef $widgets->{"$name-key"};
        }
    }
    $class->add_to_UI( $depth, "$current_form\{'$name'}->active(".
        "$active );" );
    if ($relief ne 'normal') {
        $class->add_to_UI( $depth, 
            "$current_form\{'$name'}->set_relief('$relief');");
    }

    return $widgets->{$name};
}

sub new_GtkToolbar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkTabbar";
    my $name = $proto->{'name'};
    my $orientation = $class->use_par($proto, 'orientation', $LOOKUP,  'horizontal' );
    my $type        = $class->use_par($proto, 'type'    ,    $LOOKUP,  'icons' );
    my $space_style = $class->use_par($proto, 'space_style', $LOOKUP,  'empty' );
    my $space_size  = $class->use_par($proto, 'space_size',  $DEFAULT, 5 );
    my $tooltips    = $class->use_par($proto, 'tooltips',    $BOOL,    'True' );
    my $relief      = $class->use_par($proto, 'relief',      $LOOKUP,  'normal' );
    
    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Toolbar(".
        "'$orientation', '$type' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_space_size(".
        "$space_size );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_space_style(".
        "'$space_style' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_button_relief(".
        "'$relief' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_tooltips(".
        "$tooltips );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    # Store the tooltips parameter for append_element to check later
    eval "$current_form\{'$name'}{'tooltips'} = $tooltips";
    return $widgets->{$name};
}

sub new_GtkTree {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkTree";
    my $name = $proto->{'name'};
    my $selection_mode = $class->use_par($proto, 'selection_mode', $LOOKUP, 'single' );
    my $view_mode      = $class->use_par($proto, 'view_mode',      $LOOKUP, 'line' );
    my $view_line      = $class->use_par($proto, 'view_line',      $BOOL,   'False' );

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::Tree;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_selection_mode(".
        "'$selection_mode' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_view_mode(".
        "'$view_mode' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_view_lines(".
        "$view_line );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkVBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkVBox";
    my $name = $proto->{'name'};
    my $homogeneous  = $class->use_par($proto, 'homogeneous',  $BOOL,   'False' );
    my $spacing      = $class->use_par($proto, 'spacing'    ,  $DEFAULT, 0 );

    unless ($class->new_from_child_name($parent, $name, $proto, $depth )) {
        $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::VBox(".
            "$homogeneous, $spacing );" );
        $class->pack_widget($parent, $name, $proto, $depth );
    }

    return $widgets->{$name};
}

sub new_GtkVButtonBox {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkVButtonBox";
    my $name = $proto->{'name'};
    my $layout_style     = $class->use_par($proto, 'layout_style',     $LOOKUP, 'default' );
    my $spacing          = $class->use_par($proto, 'spacing',          $DEFAULT, 0 );
    my $child_min_width  = $class->use_par($proto, 'child_min_width',  $DEFAULT, 0 );
    my $child_min_height = $class->use_par($proto, 'child_min_height', $DEFAULT, 0 );
    my $child_ipad_x     = $class->use_par($proto, 'child_ipad_x',     $DEFAULT, 0 );
    my $child_ipad_y     = $class->use_par($proto, 'child_ipad_y',     $DEFAULT, 0 );

    unless ($class->new_from_child_name($parent, $name, $proto, $depth )) {
        $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::VButtonBox;" );
        $class->pack_widget($parent, $name, $proto, $depth );
    }
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_layout(".
        "'$layout_style' );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_spacing(".
        "$spacing );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_child_size(".
        "$child_min_width, $child_min_height );" );
    $class->add_to_UI( $depth, "$current_form\{'$name'}->set_child_ipadding(".
        "$child_ipad_x, $child_ipad_y );" );

    return $widgets->{$name};
}

sub new_GtkViewport {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkViewport";
    my $name = $proto->{'name'};
    my $shadow_type  = $class->use_par($proto, 'shadow_type',  $LOOKUP, '' );

    $class->add_to_UI( $depth,  
        "\$widgets->{'$name'} = new Gtk::Viewport(".
            "new Gtk::Adjustment( 0.0, 0.0, 101.0, 0.1, 1.0, 1.0), ".
            "new Gtk::Adjustment( 0.0, 0.0, 101.0, 0.1, 1.0, 1.0) );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_shadow_type(".
        "'$shadow_type' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}


sub new_GtkVPaned {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkVPaned";
    my $name = $proto->{'name'};
    my $handle_size = $class->use_par($proto, 'handle_size', $DEFAULT, 0 );
    my $gutter_size = $class->use_par($proto, 'gutter_size', $DEFAULT, 0 );
    my $position = $class->use_par($proto, 'position', $DEFAULT, 0);

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::VPaned;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->handle_size(".
        "$handle_size );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->gutter_size(".
        "$gutter_size );" );
    $position && 
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_position(".
            "$position );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkVRuler {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkVRuler";
    my $name = $proto->{'name'};
    my $lower    = $class->use_par($proto, 'lower',      $DEFAULT, 0 );
    my $upper    = $class->use_par($proto, 'upper',      $DEFAULT, 0 );
    my $position = $class->use_par($proto, 'position',   $DEFAULT, 0 );
    my $max_size = $class->use_par($proto, 'max_size',   $DEFAULT, 0 );
    my $metric   = $class->use_par($proto, 'metric',     $BOOL,    'False' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::VRuler;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_range(".
        "$lower, $upper, $position, $max_size );" );
    if ($metric) {
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_metric;" );
    }

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkVScale {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkVScale";
    my $name = $proto->{'name'};
    my $pre = '';
    $pre = 'v' if $proto->{'vlower'}; # cater for Glade <= 0.5.1
    my $lower     = $class->use_par($proto, $pre.'lower',     $DEFAULT, 0 );
    my $upper     = $class->use_par($proto, $pre.'upper',     $DEFAULT, 100 );
    my $step      = $class->use_par($proto, $pre.'step',      $DEFAULT, 1 );
    my $page      = $class->use_par($proto, $pre.'page',      $DEFAULT, 10 );
    my $page_size = $class->use_par($proto, $pre.'page_size', $DEFAULT, 10 );
    my $value     = $class->use_par($proto, $pre.'value',     $DEFAULT, 0 );
    my $draw_value = $class->use_par($proto, 'draw_value', $BOOL, 'True' );
    my $digits     = $class->use_par($proto, 'digits',     $DEFAULT, 1 );
    my $numeric    = $class->use_par($proto, 'numeric',    $BOOL, 'False' );
    my $value_pos  = $class->use_par($proto, 'value_pos',  $LOOKUP, 'top' );
    my $policy     = $class->use_par($proto, 'policy',     $LOOKUP, 'continuous' );

    $class->add_to_UI( $depth,  "\$work->{'$name-adj'} = new Gtk::Adjustment(".
        "$value, $lower, $upper, $step, $page, $page_size );" );
    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::VScale(".
        "\$work->{'$name-adj'} );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_draw_value(".
        "$draw_value );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_digits(".
        "$digits );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_value_pos(".
        "'$value_pos' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_update_policy(".
        "'$policy' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkVScrollbar {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_GtkVScrollbar";
    my $name = $proto->{'name'};
    my $pre = '';
    $pre = 'v' if $proto->{'vlower'}; # cater for Glade <= 0.5.1
    my $lower     = $class->use_par($proto, $pre.'lower',     $DEFAULT, 0 );
    my $upper     = $class->use_par($proto, $pre.'upper',     $DEFAULT, 100 );
    my $step      = $class->use_par($proto, $pre.'step',      $DEFAULT, 1 );
    my $page      = $class->use_par($proto, $pre.'page',      $DEFAULT, 10 );
    my $page_size = $class->use_par($proto, $pre.'page_size', $DEFAULT, 10 );
    my $value     = $class->use_par($proto, $pre.'value',     $DEFAULT, 0 );
    my $policy     = $class->use_par($proto, 'policy',     $LOOKUP, 'continuous' );

    $class->add_to_UI( $depth,  "\$work->{'$name-adj'} = new Gtk::Adjustment(".
        "$value, $lower, $upper, $step, $page, $page_size );" );
    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::VScrollbar(".
        "\$work->{'$name-adj'} );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_update_policy(".
        "'$policy' );" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkVSeparator {
    my ($class, $parent, $proto, $depth) = @_;
    my $me = "$class->new_VSeparator";
    my $name = $proto->{'name'};

    $class->add_to_UI($depth, "\$widgets->{'$name'} = new Gtk::VSeparator;" );

    $class->pack_widget($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

sub new_GtkWindow {
    my ($class, $parent, $proto, $depth, $mainmenu) = @_;
    my $me = "$class->new_GtkWindow";
    my $name = $proto->{'name'};
    my $title        = $class->use_par($proto, 'title',        $DEFAULT, '' );

    $class->add_to_UI( $depth,  "\$widgets->{'$name'} = new Gtk::Window;" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_title(_('$title') );" );

    $class->set_window_properties($parent, $name, $proto, $depth );
    return $widgets->{$name};
}

1;

__END__

