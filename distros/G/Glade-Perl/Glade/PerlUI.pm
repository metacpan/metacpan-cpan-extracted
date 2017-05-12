package Glade::PerlUI;
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
    use UNIVERSAL         qw( can );          # in lots of subs
    use Gtk               qw(  );             # Everywhere
# Comment out the line below if you have a really old version of Gtk-Perl
    use Gtk::Keysyms;
    use Glade::PerlSource qw( :VARS :METHODS );
    use Glade::PerlUIGtk  qw( :VARS );;
    use Glade::PerlUIExtra;
    use vars              qw( 
                            @ISA 
                            $PACKAGE $VERSION $AUTHOR $DATE
                            @EXPORT @EXPORT_OK %EXPORT_TAGS 
                            @VARS @METHODS

                            $gnome_widgets
                            $gnome_db_widgets
                            $gnome_libs_depends
                            $gtk_perl_depends
                            $gtk_perl_cant_do
                            $concept_widgets
                            $ignore_widgets
                            $ignored_widgets
                            $missing_widgets
                            $cxx_properties
                            $dialogs
                            $composite_widgets
                            $toplevel_widgets
                            );

    $ignored_widgets = 0;
    $missing_widgets = 0;
    $PACKAGE      = __PACKAGE__;
    $VERSION      = q(0.61);
    $AUTHOR       = q(Dermot Musgrove <dermot.musgrove@virgin.net>);
    $DATE         = q(Sun Nov 17 03:21:11 GMT 2002);
    @METHODS =          qw(  );
    @VARS =             qw(
        $gnome_widgets
        $gnome_db_widgets
        $gnome_libs_depends
        $gtk_perl_depends
        $gtk_perl_cant_do
        $concept_widgets
        $ignore_widgets
        $ignored_widgets
        $missing_widgets
        $cxx_properties
        $dialogs
        $composite_widgets
        $toplevel_widgets
        );
    # Tell interpreter who we are inheriting from
    @ISA            =   qw( Glade::PerlUIGtk Glade::PerlUIExtra );
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

sub DESTROY {
    # This sub will be called on object destruction
} # End of sub DESTROY

#===============================================================================
#=========== Constants and globals                                          ====
#===============================================================================
$gnome_libs_depends     = { 
    'MINIMUM REQUIREMENTS'  => '1.2.0',
    };

$gtk_perl_depends       = { 
    'MINIMUM REQUIREMENTS'  => '0.7000',
    'LATEST_CPAN'           => '0.7008',
    'LATEST_CVS'            => '20010629',
    
    '0.6123'                => '19990818',
    '0.7000'                => '20000102',
    '0.7001'                => '20000123',
    '0.7002'                => '20000129',
    '0.7003'                => '20000816',
    '0.7004'                => '20001020',
    '0.7005'                => '20010219',
    '0.7006'                => '20010328',
    '0.7007'                => '20010601',
    '0.7008'                => '20010629',

    # Those below don't work yet even in the latest CVS version
    'GnomeDbGrid'           => '99999999',
    'GnomeDbList'           => '99999999',
    'GnomeDbCombo'          => '99999999',
    'GnomeDbReport'         => '99999999',
    'GnomeDbError'          => '99999999',
    'GnomeDbLogin'          => '99999999',
    'GnomeDbBrowser'        => '99999999',
    'GnomeDbErrorDlg'       => '99999999',
    'GnomeDbLoginDlg'       => '99999999',

    # Those below work in the CPAN version after 0.7003 (CVS after 20000410)
    'gtk_pixmap_menu_item'  => '20000410',
    # Those below work in the CPAN version after 0.7003 (CVS after 20000301)
    'gnome_dialog_append_button' 
                            => '20000301',
    # Those below work in the CPAN version after 0.7002 (CVS after 20000129)
    'Gnome::UIInfo'         => '0.7002',

    };

$gtk_perl_cant_do       = { 
    # Those below will NOT work in specific version
    'GtkDial'             => '0.7005',
};

$cxx_properties = join(' ',
    'cxx_separate_class',
    'cxx_separate_file',
    'cxx_use_heap',
    'cxx_visibility',
    );

$ignore_widgets = join (' ', 
    'Placeholder',
    'Custom',
    );

$dialogs = join(' ',
    'Gnome::About',
    'Gnome::App',
    'Gnome::Dialog',
    'Gnome::MessageBox',
    'Gnome::PropertyBox',
    'Gtk::ColorSelectionDialog',
    'Gtk::Dialog',
    'Gtk::FileSelection',
    'Gtk::FontSelectionDialog',
    'Gtk::InputDialog',
    );

$toplevel_widgets = join(' ',
    'Gnome::About',
    'Gnome::App',
    'Gnome::Dialog',
    'Gnome::MessageBox',
    'Gnome::PropertyBox',
    'Gtk::Dialog',
    'Gtk::InputDialog',
    'Gtk::Window',
    );

$composite_widgets = join(' ',
    'Gnome::Entry',
    'Gnome::FileEntry',
    'Gnome::NumberEntry',
    'Gnome::PixmapEntry',
    'Gtk::Combo',
    );

$gnome_widgets = join( " ",
    'GnomeAbout',
    'GnomeApp',
    'GnomeAppBar',
    'GnomeCalculator',
    'GnomeColorPicker',
    'GnomeDateEdit',
    'GnomeDialog',
    'GnomeDock',
    'GnomeDockItem',
    'GnomeDruid',
    'GnomeDruidPageFinish',
    'GnomeDruidPageStandard',
    'GnomeDruidPageStart',
    'GnomeEntry',
    'GnomeFileEntry',
    'GnomeFontPicker',
    'GnomeHRef',
    'GnomeIconEntry',
    'GnomeIconList',
    'GnomeIconSelection',
    'GnomeLess',
    'GnomeMessageBox',
    'GnomeNumberEntry',
    'GnomePaperSelector',
    'GnomePixmap',
    'GnomePixmapEntry',
    'GnomePropertyBox',
    'GnomeSpell',
    'GtkCalendar',          # In Gtk after CVS-19990914
    'GtkClock',
    'GtkDial',
    'GtkPixmapMenuItem',
    );

$gnome_db_widgets = join( " ",
    'GnomeDbGrid',
    'GnomeDbList',
    'GnomeDbCombo',
    'GnomeDbReport',
    'GnomeDbError',
    'GnomeDbLogin',
    'GnomeDbBrowser',
    'GnomeDbErrorDlg',
    'GnomeDbLoginDlg',
);

#===============================================================================
#=========== Version utilities                                      ============
#===============================================================================
sub my_gtk_perl_can_do {
    my ($class, $action) = @_;
    my $depends = $gtk_perl_depends->{$action} || '';
    my $cant_do = $gtk_perl_cant_do->{$action} || '';
    unless ($depends or $cant_do) { 
        # There is no required/cant_do information for $action
        return 1;
    }
    my ($cpan, $cvs);
    my $check = $action;

    # Check that we have at least the minimum required
    $check = $gtk_perl_depends->{$depends} || $depends;
    if ($check and $check > $Glade_Perl->glade2perl->my_gtk_perl) {
        $cpan = $gtk_perl_depends->{'LATEST_CPAN'};
        $cpan = $gtk_perl_depends->{$cpan} if $gtk_perl_depends->{$cpan};
        if ($check > $cpan) {
            # We need a CVS version
            if ($check > $gtk_perl_depends->{'LATEST_CVS'}) {
                # The CVS version can't even do it yet
                $Glade_Perl->diag_print(1, 
                    "warn  Gtk-Perl dated %s cannot do '%s' (properly)".
                    " and neither can the CVS version !!!",
                    $Glade_Perl->glade2perl->my_gtk_perl, $action);
                    
            } else {
                # We need a new CVS version
                $Glade_Perl->diag_print(1, 
                    "warn  Gtk-Perl dated %s cannot do '%s' (properly)".
                    " we need CVS module 'gnome-perl' after %s",
                    $Glade_Perl->glade2perl->my_gtk_perl, $action, $check);
            }

        } else {
            # We need a new CPAN version
            $Glade_Perl->diag_print(1, 
                "warn  Gtk-Perl version %s cannot do '%s' (properly)".
                " we need CPAN version %s or CVS module 'gnome-perl' after %s",
                $Glade_Perl->glade2perl->my_gtk_perl, $action, 
                    $gtk_perl_depends->{$action}, $check);
        }
        return undef;
    }

    # Check that we dont have a cant_do version
    $check = $gtk_perl_depends->{$cant_do} || $cant_do;
    unless ($check and $check == $Glade_Perl->glade2perl->my_gtk_perl) {
        # We can do required $action in our version
        return 1;
    } else {
        # This version can't do it although earlier and later versions may
        $Glade_Perl->diag_print(1, 
            "warn  Gtk-Perl dated %s cannot do '%s' (properly)".
            " although older and newer versions may",
            $Glade_Perl->glade2perl->my_gtk_perl, $action);
        return undef;
    }
    return undef;
}

sub my_gnome_libs_can_do {
    my ($class, $action) = @_;
    my $depends = $gnome_libs_depends->{$action};
    unless ($depends and $depends gt $Glade_Perl->glade2perl->my_gnome_libs) {
        # There is no specified version or ours is sufficient
        return 1;
    }
    if ($depends ge 19990914) {
        # We need a CVS version
        if ($depends gt 29990000) {
            # The CVS version can't even do it yet
            $Glade_Perl->diag_print(1, 
                "warn  gnome_libs version %s cannot do '%s' (properly)".
                " and neither can the CVS version !!!",
                $Glade_Perl->glade2perl->my_gnome_libs, $action);
        } else {
            # We need a new CVS version
            $Glade_Perl->diag_print(1, 
                "warn  gnome_libs version %s cannot do '%s' (properly)".
                " we need CVS module 'gnome-libs' after %s",
                $Glade_Perl->glade2perl->my_gnome_libs, $action, $depends);
        }
    } else {
        # We need a new released version
        $Glade_Perl->diag_print(1, 
            "warn  gnome_libs version %s cannot do '%s' (properly)".
            " we need version %s",
            $Glade_Perl->glade2perl->my_gnome_libs, $action, $depends);
    }
    return undef;
}

#===============================================================================
#=========== Utilities to construct UI                              ============
#===============================================================================
sub use_par {
    my ($class, $proto, $key, $request, $default, $dont_undef) = @_;
    my $me = "$class->use_par";

    my $type;
    my $self = $proto->{$key};
    unless (defined $self) {
        if (defined $default) {
            $self = $default;
#            $Glade_Perl->diag_print (8, "$indent- No value in proto->{'$key'} ".
#                "so using DEFAULT of '$default' in $me");
        } else {
            # We have no value and no default to use so bail out here
            $Glade_Perl->diag_print (1, "error No value in supplied ".
                "%s and NO default was supplied in ".
                "%s called from %s line %s",
                "$proto->{'name'}\->{'$key'}", $me, (caller)[0], (caller)[2] );
            return undef;
        }
    } else {
        # We have a value to use
#        $Glade_Perl->diag_print (8, "$indent- Value supplied in ".
#            "proto->{'$key'} was '$self'");
    }
    # We must have some sort of value to use by now
    unless ($request) {
        # Nothing to do, we are already $proto->{$key} so
        # just drop through to undef the supplied prot->{$key}
#        $Glade_Perl->diag_print(8, "I have used par->{'$key'} => '$self' in $me");
        
    } elsif ($request eq $DEFAULT) {
        # Nothing to do, we are already $proto->{$key} (or default) so
        # just drop through to undef the supplied prot->{$key}
#        $Glade_Perl->diag_print(8, "I have converted '$key' from ".
#            ($proto->{$key} || 'undef')." to default ('$self') in $me");
        
    } elsif ($request == $LOOKUP) {
        return '' unless $self;
        
        my $lookup;
        # make an effort to convert from Gtk to Gtk-Perl constant/enum name
        if ($self =~ /^GNOME/) {
            $lookup = Glade::PerlUIExtra->lookup($self);

        } else {
            $lookup = Glade::PerlUIGtk->lookup($self);
        }
        unless ($lookup) {
            if (defined $default) {
                $Glade_Perl->diag_print(2, 
                    "warn  Unable to lookup '%s' using default of '%s'",
                    $self, $default);
                $self = $default;
            } else {
                $Glade_Perl->diag_print(1, 
                    "error Unable to lookup '%s' and no default",
                    $self);
            }
        } else {
            $self = $lookup;
        }
            
#        $Glade_Perl->diag_print(8, "$indent- I have converted '$key' from '".
#            ($proto->{$key} || $default)."' to '$self' (LOOKUP) in $me");

    } elsif ($request == $BOOL) {
        # Now convert whatever we have ended up with to a BOOL
        # undef becomes 0 (== false)
        $type = $self;
        $self = ('*true*y*yes*on*1*' =~ m/\*$self\*/i) ? '1' : '0';
#        $Glade_Perl->diag_print(8, "$indent- I have converted proto->{'$key'} ".
#            "from '$type' to $self (BOOL) in $me");

    } elsif ($request == $KEYSYM) {
        $self =~ s/GDK_//;
## If you have an old version of Gtk-Perl that doesn't have Gtk::Keysyms
## use the next line instead of the Gtk::Keysyms{$self} line below it
##        $self = ord ($self );
#        $self = $Gtk::Keysyms{$self} || Gtk::Gdk->keyval_from_name($self);
##        $Glade_Perl->diag_print(8, "$indent- I have converted '$key' from ".
##            ($proto->{$key})." to '$self' (Gtk::Keysyms)in $me");
    } 
    # undef the parameter so that we can report any unused attributes later
    undef $proto->{$key} unless $dont_undef;
    # Backslash escape any single quotes (unless they are already backslashed)
    $self =~ s/(?!\\)(.)'/$1\\'/g;
    $self =~ s/^'/\\'/g;
    return "$self";
}

sub construct_widget {
    my ($class, $parentname, $proto, $depth, $wh, $ch) = @_;
    my $me = "$class->prepare_widget";
    my ($widget_hierarchy, $class_hierarchy);
    my ($name, $constructor, $expr);
    unless ($proto->{name}) {
        $Glade_Perl->diag_print (2, 
            "You have supplied a proto without a name to %s", $me);
        $Glade_Perl->diag_print (2, $proto);
    } else {
        $name = $proto->{name};

    }
    if ($depth == 1) {
        $name = $class->fix_name($name);
        $forms->{$name} = {};
        if (keys %{$forms->{$name}}) {
            die "You have already defined a form called '$name'";
        }

        # We are a toplevel window so create a new hash and 
        # set $current_form with its name
        # All these back-slashes are really necessary as this string
        # is passed through so many others
        $current_form_name = "$name-\\\\\\\$instance";
        $current_form = "\$forms->{'$name'}";
        $current_data = "\$data->{'$name'}\{__DATA}";
        $current_name = $name;
        $current_window = "\$forms->{'$name'}\{'$name'}";
        $first_form ||= $name;

        if ($Glade_Perl->source->hierarchy =~ /^(widget|both)/) {
            $widget_hierarchy = "\$forms->{'$name'}{__WH}";
        }
        if ($Glade_Perl->source->hierarchy =~ /^(class|both)/) {
            $class_hierarchy = "\$forms->{'$name'}{__CH}";
        }

    } else {
        $widget_hierarchy = "$wh\{'$name'}" if $wh;
        $class_hierarchy  = "$ch\{'$proto->{class}'}{'$name'}" if $ch; 
    }
    $class->add_to_UI( $depth,  "#" );
    $class->add_to_UI( $depth,  "# ".S_("Construct a").
        " $proto->{class} '$name'");
    $constructor = "new_$proto->{class}";
    if ($class->can($constructor)) {
        # Construct the widget
        my $eval_class = 'Glade::PerlProject';#ref $class || $class;
        $expr =  "\$widgets->{'$name'} = ".
            "$eval_class->$constructor('$parentname', \$proto, $depth );";
        eval $expr or 
            ($@ && die  "\nin $me\n\t".("while trying to eval").
                " '$expr'\n\t".("FAILED with Eval error")." '$@'\n" );
        if ($widget_hierarchy) {
            # Add to form widget hierarchy
            $class->add_to_UI( $depth,  
                "$widget_hierarchy\{__W} = $current_form\{'$name'};" );
#                    "\$class->W($widget_hierarchy, $current_form\{'$name'});" );
#            if ($Glade_Perl->source->hierarchy =~ /order/) {
#                if ($depth > 1) {
#                    $class->add_to_UI( $depth,  
#                        "push \@{$wh\{__C}}, $current_form\{'$name'};" );
##                            "\$class->C($wh, $current_form\{'$name'});" );
#                }
#            }
        }
        if ($class_hierarchy) {
            # Add to form class hierarchy
            $class->add_to_UI( $depth,  
                "$class_hierarchy\{__W} = $current_form\{'$name'};" );
#                    "\$class->W($class_hierarchy, $current_form\{'$name'});" );
#            if ($Glade_Perl->source->hierarchy =~ /order/) {
#                if ($depth > 1) {
#                    $class->add_to_UI( $depth,  
#                        "push \@{$ch\{__C}}, $current_form\{'$name'};" );
##                            "\$class->C($ch, $current_form\{'$name'});" );
#                }
#            }
        }
        if ($Glade_Perl->source->hierarchy =~ /order/) {
            if ($depth > 1) {
                $class->add_to_UI( $depth,  
                    "push \@{$wh\{__C}}, $current_form\{'$name'};" );
            }
        }
    } else {
        $Glade_Perl->diag_print(1, "error I don't have a constructor called '%s'".
            "- I guess that it isn't written yet :-)",
            "$class->$constructor");
    }
    return ($widget_hierarchy, $class_hierarchy);
}

sub new_sub_widget {
    my ($class, $parentname, $proto, $depth, $wh, $ch) = @_;
    my $me = "$class->new_sub_widget";
    my $childname;
    if ($class->my_gtk_perl_can_do($proto->{'class'})) {
        unless (" $ignore_widgets " =~ / $proto->{'class'} /) {
            # This is a real widget subhash so recurse to expand
            $childname = $class->Widget_from_Proto( 
                $parentname, $proto, $depth, 
                $wh, $ch );
            $class->set_child_packing(
                $parentname, $childname, $proto, $depth );
            if ($Glade_Perl->diagnostics) {
                # Check that we have used all widget properties
                $class->check_for_unused_elements($proto);
            }

        } else {
            unless (" $gnome_widgets " =~ / $proto->{'class'} /) {
                $Glade_Perl->diag_print(3, 
                    "warn  %s in %s ignored in %s", 
                    $proto->{'class'}, $parentname, $me);
            } else {
                $Glade_Perl->diag_print(1, "error %s in %s ignored in %s", 
                $proto->{'class'}, ($parentname || 'Glade project'), $me);
            }
            $ignored_widgets++;
        }
    }
    return $childname;
}

sub Widget_from_Proto {
    my ($class, $parentname, $proto, $depth, $wh, $ch) = @_;
    my $me = "$class->Widget_from_Proto";
#$Glade_Perl->diag_print(2, $forms);
    my $typekey = $class->typeKey;
    my ($name, $widget_hierarchy, $class_hierarchy, $childname, 
        $window, $sig);
    my ($key, $dm, $self, $expr, $object, $refself, $packing );
    $parentname ||= "Top level application";

    if ($depth) {
        # We are a widget of some sort (toplevel window or child)
        ($widget_hierarchy, $class_hierarchy) = 
            $class->construct_widget($parentname, $proto, $depth, $wh, $ch);

    } else {
        # We are a complete GTK-Interface - ie we are the application
#$Glade_Perl->diag_print(2, $proto);
        unless ($Glade_Perl->app->allow_gnome) {
            $ignore_widgets .= " $gnome_widgets";
        }
        unless ($Glade_Perl->app->allow_gnome_db) {
            $ignore_widgets .= " $gnome_db_widgets";
        }
    }

    $self = $widgets->{$proto->{name}};
    $refself = ref $self;

    # Iterate through keys looking for sub widgets and properties
    foreach $key (sort keys %{$proto}) {
        if (ref $proto->{$key} eq 'HASH') {
            # this is a ref to a sub hash so expand it
            $object = $proto->{$key}{$typekey};
            if ($object) {
#$Glade_Perl->diag_print(2, "Considering $key $object");
                if ( $object eq 'widget') {
                    $childname = $class->new_sub_widget(
                        $proto->{name}, $proto->{$key}, $depth+1, 
                        $widget_hierarchy, $class_hierarchy);

                } elsif ($object eq 'signal') {
                    # we are a SIGNAL
                    $class->new_signal(
                        $proto->{name}, $proto->{$key}, $depth );

                } elsif ($object eq 'accelerator') {
                    # we are an ACCELERATOR
                    $class->new_accelerator(
                        $proto->{name}, $proto->{$key}, $depth );

                } elsif ($object eq 'style') {
                    # Perhaps should be in set_widget_properties
                    if ($current_form) {
                        $class->new_style(
                            $proto->{name}, $proto->{$key}, $depth );
                    }

                } elsif ($object eq 'project') {
                    # We rely on this appearing before the rest of the proto
                    # so that we know which files to write (if needed)
                    # It was dealt with in new_from_Glade so just ignore it

                } elsif ($object eq 'child') {
                    # Already dealt with above so just ignore it

                } else {
                    # I don't recognise it so do nothing but report it
                    $Glade_Perl->diag_print (1, "error Object '%s' not recognised ".
                        "or processed for %s '%s' by %s",
                        $object, $proto->{'class'}, $proto->{name}, $me);
                    $Glade_Perl->diag_print(1, $proto);
                }

#            } else {
#                # I don't recognise it so do nothing but report it
#                $Glade_Perl->diag_print (1, "error Undefined object for %s '%s' by $s".
#                    $proto->{'class'}, '$proto->{name}', $me );
#                $Glade_Perl->diag_print(1, $proto);
            }
        } elsif (ref $proto->{$key} eq 'ARRAY') {
            # We are a new type array of widgets so construct each in order
        }
    }
#================== Check this and TIDY it up
    if ($depth == 1) {
        # We are a toplevel window so now connect all signals
        if (eval "scalar(\@{${current_form}\{Signal_Strings}})") {
            # We have some signals to connect
            $class->add_to_UI( $depth,  "#" );
            $class->add_to_UI( $depth,  
                "# ".S_("Connect all signals now that widgets are constructed" ));
            $expr = "foreach \$sig (\@{${current_form}\{Signal_Strings}}) {
                eval \$sig;
            }";
            eval $expr;
        }
    }
    unless ($depth)             {
        # We are the Application level (above all toplevel windows)
        return $childname;
    } elsif ($proto->{name})     {
        # We are the bottom widget in the branch of the proto tree
        return $proto->{name};
    } elsif ($childname)         {
        # We are somewhere in the middle of the tree
        return $childname;
    } else                         {
        # What has happened?
        die 'error $me - failed to return anything';
    }
}

#===============================================================================
#=========== Utilities to build UI                                    ============
#===============================================================================
sub internal_pack_widget {
    my ($class, $parentname, $childname, $proto, $depth) = @_;
    my $me = "$class->internal_pack_widget";
    my $refpar;
    # When we add/pack/append we do it to ${current_form}->{$parentname} 
    # rather than $widgets->{$parentname} so that we are sure that everything 
    # is packed in the right order and we can check for duplicate names
    my $refwid = (ref $widgets->{$childname} );
    my $child_type;
    my $postpone_show;
    if ($current_form && eval "exists ${current_form}\{'$childname'}") {
        die sprintf(("\nerror %s - There is already a widget called ".
            "'%s' constructed and packed - I will not overwrite it !"),
            $me, $childname);
    }
    if (" $dialogs $toplevel_widgets " =~ m/ $refwid /) {
        # We are a window so don't have a parent to pack into
        $Glade_Perl->diag_print (4, "%s- Constructing a toplevel component ".
            "(window/dialog) '%s'", $indent, $childname);
#        $child_type = $widgets->{$childname}->type;
#        if (' toplevel dialog '=~ m/ $child_type /) {
            # Add a default delete_event signal connection
            $class->add_to_UI($depth,   
                "${current_form}\{'tooltips'} = new Gtk::Tooltips;" );
            $class->add_to_UI($depth,   
                "${current_form}\{'accelgroup'} = new Gtk::AccelGroup;" );
            $class->add_to_UI( $depth, 
                "${current_form}\{'accelgroup'}->attach(\$widgets->{'$childname'} );" );
#        } else {
#            die "\nerror F$me   $indent- This is a $child_type type Window".
#                " - what should I do?";
#        }
        $postpone_show = 1;

    } else {
        # We probably have a parent to pack into somehow
        eval "\$refpar = (ref ${current_form}\{'$parentname'})||'UNDEFINED !!';";
        unless (eval "exists ${current_form}\{'$parentname'}") {
            if ($Glade_Perl->source->quick_gen or 'Gtk::Menu' eq $refwid) {
                # We are a popup menu so we don't have a root window
#            $class->add_to_UI( $depth, "${first_form}->popup_enable;" );
                $class->add_to_UI($depth,   
                    "${current_form}\{'tooltips'} = new Gtk::Tooltips;" );
                $class->add_to_UI($depth,   
                    "${current_form}\{'accelgroup'} = new Gtk::AccelGroup;" );
                $class->add_to_UI( $depth, 
                    "${current_form}\{'accelgroup'}->attach(\$widgets->{'$childname'} );" );
                $postpone_show = 1;
            } else {
                die sprintf(("\nerror %s - Unable to find a widget called '%s' - ".
                    "I can not pack widget '%s' into a non-existant widget!"),
                    $me, $parentname, $childname);
            }
        }
        if ($postpone_show) {
            # Do nothing
            
#---------------------------------------
        } elsif (" $composite_widgets " =~ m/ $refpar /) {
            # We do not need to do anything for this widget
            
#---------------------------------------
        } elsif (eval "${current_form}\{'$parentname'}->can(".
            "'query_child_packing')") {# and !defined $proto->{'child_name'}) {
            # We have a '$refpar' widget '$parentname' that can query_child_packing
            my $ignore = $class->use_par($proto, 'child_name', $DEFAULT, '' );
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->add(".
                    "\$widgets->{'$childname'} );");

#---------------------------------------
        } elsif (' Gtk::CList ' =~ m/ $refpar /) {
            $child_type = $class->use_par($proto, 'child_name', $DEFAULT, '' );
            if ($child_type eq 'CList:title') {
                # We are a CList column widget (title widget)
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->set_column_widget(".
                        "$CList_column, \$widgets->{'$childname'} );" );
                $CList_column++;
            } else {
                $Glade_Perl->diag_print (1, 
                    "error I don't know what to do with %s element %s",
                    $refpar, $child_type);
            }

#---------------------------------------
        } elsif (' Gtk::CTree ' =~ m/ $refpar /) {
            $child_type = $class->use_par($proto, 'child_name', $DEFAULT, '' );
            if ($child_type eq 'CTree:title') {
                # We are a CTree column widget (title widget)
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->set_column_widget(".
                        "$CTree_column, \$widgets->{'$childname'} );" );
                $CTree_column++;
            } else {
                $Glade_Perl->diag_print (1, 
                    "error I don't know what to do with %s element %s".
                    $refpar, $child_type);
            }

#---------------------------------------
        } elsif (' Gtk::Layout ' =~ m/ $refpar /) {
#            $Glade_Perl->diag_print(2, $proto);
            my $x      = $class->use_par($proto, 'x');
            my $y      = $class->use_par($proto, 'y');
#            my $width  = $class->use_par($proto, 'width');
#            my $height = $class->use_par($proto, 'height');
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->put(".
                    "\$widgets->{'$childname'}, $x, $y);" );

#---------------------------------------
        } elsif (' Gtk::MenuBar Gtk::Menu ' =~ m/ $refpar /) {
            # We are a menuitem
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->append(".
                    "\$widgets->{'$childname'} );" );

#---------------------------------------
        } elsif (' Gtk::MenuItem Gtk::PixmapMenuItem ' =~ m/ $refpar /) {
            # We are a menu for a meuitem
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->set_submenu(".
                    "\$widgets->{'$childname'} );" );
            $postpone_show = 1;

#---------------------------------------
        } elsif (' Gtk::OptionMenu ' =~ m/ $refpar /) {
            # We are a menu for an optionmenu
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->set_menu(".
                    "\$widgets->{'$childname'} );" );
            $postpone_show = 1;

#---------------------------------------
        } elsif (' Gtk::Notebook ' =~ m/ $refpar /) {
            $child_type = $class->use_par($proto, 'child_name', $DEFAULT, '' );
            if ($child_type eq 'Notebook:tab') {
                # We are a notebook tab widget (eg label) so we can add the 
                # previous notebook page with ourself as the  label
                unless ($nb->{$parentname}{'panes'}[$nb->{$parentname}{'tab'}]) {
                    $Glade_Perl->diag_print (1, "warn  There is no widget on the ".
                        "notebook page linked to notebook tab '%s' - ".
                        "a Placeholder label was used instead",
                        $childname);
                    my $message = sprintf(S_("This is a message generated by %s\n\n".
                                "No widget was specified for the page linked to\n".
                                "notebook tab \"%s\"\n\n".
                                "You should probably use Glade to create one"),
                                $PACKAGE, $childname);
                    $class->add_to_UI( $depth, 
                        "${current_form}\{'Placeholder_label'} = ".
                            "new Gtk::Label('$message');");
                    $class->add_to_UI( $depth, 
                        "${current_form}\{'Placeholder_label'}->show;");
                    $nb->{$parentname}{'panes'}[$nb->{$parentname}{'tab'}] = 
                        'Placeholder_label';
                }
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->append_page(".
                        "${current_form}\{'$nb->{$parentname}{'panes'}[$nb->{$parentname}{'tab'}]'}, ".
                        "\$widgets->{'$childname'} );" );
                $nb->{$parentname}{'tab'}++;

            } else {
                # We are a notebook page so just store for adding later 
                # when we get the tab widget
                push @{$nb->{$parentname}{'panes'}}, $childname;
                $nb->{$parentname}{'pane'}++;
            }

#---------------------------------------
        } elsif (' Gtk::Packer ' =~ m/ $refpar /) {
            my $anchor  = $class->use_par($proto->{'child'}, 'anchor', $LOOKUP, 'center', 'DONT_UNDEF');
            my $side    = $class->use_par($proto->{'child'}, 'side',   $LOOKUP, 'top', 'DONT_UNDEF');
            my $expand  = $class->use_par($proto->{'child'}, 'expand', $BOOL,   'False', 'DONT_UNDEF');
            my $xfill   = $class->use_par($proto->{'child'}, 'xfill',  $BOOL,   'False', 'DONT_UNDEF');
            my $yfill   = $class->use_par($proto->{'child'}, 'yfill',  $BOOL,   'False', 'DONT_UNDEF');
            my $use_default = $class->use_par($proto->{'child'}, 'use_default',  $BOOL,'True', 'DONT_UNDEF');
            my $options = "";
            if ($expand) {
                $options .= "'expand', ";
            }
            $xfill  && ($options .= "'fill_x', ");
            $yfill  && ($options .= "'fill_y', ");
            $options =~ s/, $//;
            if ($options) {$options = "[$options]";} else {$options = "[]";}
            if ($use_default) {
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->add_defaults(".
                        "\$widgets->{'$childname'}, ".
                        "'$side', '$anchor', $options);" );
            } else {
                my $border_width = $class->use_par($proto->{'child'}, 'border_width', $DEFAULT, 0, 'DONT_UNDEF');
                my $xipad   = $class->use_par($proto->{'child'}, 'xipad',  $DEFAULT, 0, 'DONT_UNDEF');
                my $xpad    = $class->use_par($proto->{'child'}, 'xpad',   $DEFAULT, 0, 'DONT_UNDEF');
                my $yipad   = $class->use_par($proto->{'child'}, 'yipad',  $DEFAULT, 0, 'DONT_UNDEF');
                my $ypad    = $class->use_par($proto->{'child'}, 'ypad',   $DEFAULT, 0, 'DONT_UNDEF');
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->add(".
                        "\$widgets->{'$childname'}, ".
                        "'$side', '$anchor', $options, $border_width, ".
                        "$xpad, $ypad, $xipad, $yipad);" );
            }
                      
#---------------------------------------
        } elsif (' Gtk::ScrolledWindow ' =~ m/ $refpar /) {
            if (' Gtk::CList Gtk::CTree Gtk::Text Gnome::IconList ' =~ m/ $refwid /) {
                # These handle their own scrolling and
                # Ctree/CList column labels stay fixed
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->add(".
                        "\$widgets->{'$childname'} );" );

            } else {
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->add_with_viewport(".
                        "\$widgets->{'$childname'} );" );
            }
            
#---------------------------------------
        } elsif (' Gtk::Table ' =~ m/ $refpar /) {
            # We are adding to a table so do the child packing
            my $left_attach =   $class->use_par($proto->{'child'}, 'left_attach'   );
            my $right_attach =  $class->use_par($proto->{'child'}, 'right_attach'  );
            my $top_attach =    $class->use_par($proto->{'child'}, 'top_attach'    );
            my $bottom_attach = $class->use_par($proto->{'child'}, 'bottom_attach' );

            my (@xoptions, @yoptions);
            my ($xoptions, $yoptions);
            push @xoptions, 'expand' if $class->use_par($proto->{'child'}, 'xexpand', $BOOL, 'True' );
            push @xoptions, 'fill'   if $class->use_par($proto->{'child'}, 'xfill',   $BOOL, 'True' );
            push @xoptions, 'shrink' if $class->use_par($proto->{'child'}, 'xshrink', $BOOL, 'False');
            push @yoptions, 'expand' if $class->use_par($proto->{'child'}, 'yexpand', $BOOL, 'True' );
            push @yoptions, 'fill'   if $class->use_par($proto->{'child'}, 'yfill',   $BOOL, 'True' );
            push @yoptions, 'shrink' if $class->use_par($proto->{'child'}, 'yshrink', $BOOL, 'False');
            if (scalar @xoptions) {$xoptions = "['".join("', '", @xoptions)."']"} else {$xoptions = '[]'};
            if (scalar @yoptions) {$yoptions = "['".join("', '", @yoptions)."']"} else {$yoptions = '[]'};

            my $xpad =    $class->use_par($proto->{'child'}, 'xpad',    $DEFAULT, 0 );
            my $ypad =    $class->use_par($proto->{'child'}, 'ypad',    $DEFAULT, 0 );

            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->attach(".
                    "\$widgets->{'$childname'}, ".
                    "$left_attach, $right_attach, $top_attach, $bottom_attach, ".
                    "$xoptions, $yoptions, $xpad, $ypad );" );
            
#---------------------------------------
        } elsif (' Gtk::Toolbar ' =~ m/ $refpar /) {
# FIXME - toolbar buttons with a removed label don't have a child_name
#   but can have a sub-widget. allow for this
#   test all possibilities
            # Untested possibilities
            # 4 Other type of widget
            my $tooltip =  $class->use_par($proto, 'tooltip',  $DEFAULT, '' );
            if (eval "$current_form\{'$parentname'}{'tooltips'}" && 
                !$tooltip &&
                (' Gtk::VSeparator Gtk::HSeparator Gtk::Combo Gtk::Label ' !~ / $refwid /)) {
                $Glade_Perl->diag_print (1, 
                    "warn  Toolbar '%s' is expecting ".
                    "a tooltip but you have not set one for %s '%s'",
                    $parentname, $refwid, $childname);
            }            

            if ($proto->{'child'}{'new_group'} && $proto->{'child'}{'new_group'} eq 'True') {
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->append_space;" );
            }
            # We must have a widget already constructed
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->append_widget(".
                    "\$widgets->{'$childname'}, _('$tooltip'), '' );" );
            
#---------------------------------------
        } elsif (" Gnome::App "=~ m/ $refpar /) {
            my $type = $class->use_par($proto, 'child_name', $DEFAULT, '' );
            if (' Gnome::AppBar ' =~ m/ $refwid /) {
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->set_statusbar(".
                        "\$widgets->{'$childname'} );" );
            
            } elsif (' GnomeApp:appbar ' =~ m/ $type /) {
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->set_statusbar(".
                        "\$widgets->{'$childname'} );" );
            
            } elsif (' Gnome::Dock ' =~ m/ $refwid /) {
# FIXME why have I commented this out? Is it because Gnome::Dock should not
# be constructed within a Gnome::App - add Gnome::DockItems by using method
# Gnome::App::add_docked() or Gnome::App::add_dock_item() instead?
#                $class->add_to_UI( $depth, 
#                    "${current_form}\{'$parentname'}->set_contents(".
#                        "\$widgets->{'$childname'} );" );

            } elsif (' Gtk::MenuBar ' =~ m/ $refwid /) {
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->set_menus(".
                        "\$widgets->{'$childname'} );" );

            } else {
                $Glade_Perl->diag_print (1, 
                    "error Don't know how to pack %s %s (type '%s') - what should I do?",
                    $refwid, "${current_form}\{'${childname}'}{'child_name'}", $type);
            }
                        
#---------------------------------------
        } elsif (" Gnome::Dock "=~ m/ $refpar /) {
            # We are a Gnome::DockItem
            my $placement= $class->use_par($proto, 'placement', $LOOKUP, 'top' );
            my $band     = $class->use_par($proto, 'band',      $DEFAULT, 0 );
            my $position = $class->use_par($proto, 'position',  $DEFAULT, 0 );
            my $offset   = $class->use_par($proto, 'offset',    $DEFAULT, 0 );
            my $in_new_band = $class->use_par($proto, 'in_new_band', $DEFAULT, 0 );

            # 'Usage: Gnome::Dock::add_item(dock, item, placement, band_num, position, offset, in_new_band)
            # Actually should be Gnome::App->add_docked() or
            # Gnome::App->add_dock_item() if this widget is in a Gnome::App
# I quote Damon 20000301 on glade-devel list
# I think it was OK to treat dock items as children of the dock.
# A GnomeDock could be used in other places besides a GnomeApp (though
# I don't think Glade supports that completely at the moment).
# I also had to think about GnomeDockBands, but I decided to skip those
# in the output since they are created and destroyed automatically
# and can't be manipulated independantly.
# 
# I think you're right in that libglade shouldn't create a GnomeDock inside
# a GnomeApp, and should be adding the dock items via the GnomeApp's
# GnomeDockLayout, e.g. using gnome_app_add_docked() or gnome_app_add_dock_item().

            if (" Gnome::DockItem " =~/ $refwid /) {
                $class->add_to_UI( $depth, 
                    "${current_form}\{'$parentname'}->add_item(".
                        "\$widgets->{'$childname'}, '$placement', $band, ".
                        "$position, $offset, $in_new_band );" );
            } else {
                # We are not a dock_item - just using set_contents
                undef $proto->{'child_name'};
                $class->add_to_UI( $depth, 
                    "${current_window}->set_contents(".
                        "\$widgets->{'$childname'} );" );
            }
            
#---------------------------------------
        } elsif (" Gnome::Druid "=~ m/ $refpar /) {
            # We are a Gnome::DruidPage of some sort
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parentname'}->append_page(".
                    "\$widgets->{'$childname'} );" );
            if (' Gnome::DruidPageStart ' =~ / $refwid /) {
                $class->add_to_UI( $depth, "${current_form}\{'$parentname'}->".
                    "set_page(\$widgets->{'$childname'});" );
            }
            
#---------------------------------------
        } elsif (" $dialogs "=~ m/ $refpar /) {
            # We use a dialog->method to get a ref to our widget
#            my $ignore = $class->use_par($proto, 'label', $DEFAULT,  '' );
            my $type =  $class->use_par($proto, 'child_name' );
            $type =~ s/.*:(.*)/$1/;
            $class->add_to_UI( $depth, "\$widgets->{'$childname'} = ".
                "${current_form}\{'$parentname'}->$type;" );

#---------------------------------------
        } else {
            # We are not a special case
            $class->add_to_UI( $depth, "${current_form}\{'$parentname'}->add(".
                "\$widgets->{'$childname'} );" );
        }
    }
    unless ($postpone_show || !$class->use_par($proto, 'visible', $BOOL, 'True') ) {
        $class->add_to_UI($depth, "\$widgets->{'$childname'}->show;" );
    }
# FINDME This is to remove
    $class->add_to_UI( $depth, 
        "${current_form}\{'$childname'} = \$widgets->{'$childname'};" );

    # Delete the $widget to show that it has been packed
    delete $widgets->{$childname};

    return;
}

sub set_child_packing {
    my ($class, $parentname, $childname, $proto, $depth) = @_;
    my $me = "$class->set_child_packing";
    if ($proto->{'child'} && eval "${current_form}\{'$parentname'}->can("."
        'set_child_packing')") {
        my ($refpar, $refwid);
        eval "\$refpar = ref ${current_form}\{'$parentname'}";
        eval "\$refwid = ref ${current_form}\{'$childname'}";
        unless (' Gtk::Packer ' =~ / $refpar /) {
            my $expand =   $class->use_par( $proto->{'child'}, 
                'expand', $BOOL, 'False' );
            my $fill =     $class->use_par( $proto->{'child'}, 
                'fill', $BOOL, 'True' );
            my $padding =  $class->use_par( $proto->{'child'}, 
                'padding', $BOOL, 'False' );
            my $pack =        $class->use_par( $proto->{'child'}, 
                'pack', $LOOKUP, 'start' );
            $class->add_to_UI( $depth,  
                "${current_form}\{'$parentname'}->set_child_packing(".
                    "${current_form}\{'$childname'}, ".
                    "$expand, $fill, $padding, '$pack' );" );
        }
    }
}

sub set_tooltip {
    my ($class, $parentname, $proto, $depth) = @_;
    my $me = "$class->set_tooltip";
    my $tooltip = $class->use_par($proto, 'tooltip', $DEFAULT, '');
    
# FIXME What do we do if tooltip is '' - set or not ?
    if ($tooltip ne '') {
        $class->add_to_UI( $depth, "${current_form}\{'tooltips'}->set_tip(".
            "${current_form}\{'$parentname'}, _('$tooltip' ));" );

    } elsif (!defined $proto->{name}) {
        $Glade_Perl->diag_print (1, 
            "error Could not set tooltip for unnamed %s", $proto->{'class'});

    } else {
        $Glade_Perl->diag_print(6, 
            "warn  No tooltip specified for widget '%s'", $proto->{name});
    }    
}

sub set_container_properties {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = "$class->set_container_properties";
    if ($proto->{'border_width'}) {
        if (eval "$current_form\{'$name'}->can('border_width')") {
            my $border_width  = $class->use_par($proto, 'border_width', $DEFAULT, 0);
            $class->add_to_UI( $depth, "$current_form\{'$name'}->border_width(".
                "$border_width );" );
        }
    }
}

sub set_range_properties {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = "$class->set_range_properties";
# FIXME - call this from range type widgets
# For use by HScale, VScale, HScrollbar, VScrollbar
#    my $name = $proto->{name};
    my $hvalue     = $class->use_par($proto, 'hvalue',     $DEFAULT, 0 );
    my $hlower     = $class->use_par($proto, 'hlower',     $DEFAULT, 0 );
    my $hupper     = $class->use_par($proto, 'hupper',     $DEFAULT, 0 );
    my $hstep      = $class->use_par($proto, 'hstep',      $DEFAULT, 0 );
    my $hpage      = $class->use_par($proto, 'hpage',      $DEFAULT, 0 );
    my $hpage_size = $class->use_par($proto, 'hpage_size', $DEFAULT, 0 );
    my $policy     = $class->use_par($proto, 'policy',     $LOOKUP );

    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_update_policy(".
        "'$policy' );" );
}

sub set_misc_properties {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = "$class->set_alignment";
    # For use by Arrow, Image, Label, (TipsQuery), Pixmap
    # Cater for all the usual properties (defaults not stored in XML file)
    return unless ($proto->{'xalign'} || $proto->{'yalign'} || $proto->{'xpad'} || $proto->{'ypad'});
    my $xalign = $class->use_par($proto, 'xalign', $DEFAULT, 0 );
    my $yalign = $class->use_par($proto, 'yalign', $DEFAULT, 0 );
    my $xpad   = $class->use_par($proto, 'xpad',   $DEFAULT, 0 );
    my $ypad   = $class->use_par($proto, 'ypad',   $DEFAULT, 0 );

    if ($xalign || $yalign) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->set_alignment(".
            "$xalign, $yalign );" );
    }
    if ($xpad || $ypad) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->set_padding(".
            "$xpad, $ypad );" );
    }
# FIXME - handle padding (width & height) properly
}

sub set_widget_properties {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = "$class->set_widget_properties";
    # For use by all widgets
    # Cater for all the usual properties (defaults not stored in XML file)
    my $can_default = $class->use_par($proto, 'can_default',$BOOL,      'False' );
    my $has_default = $class->use_par($proto, 'has_default',$BOOL,      'False' );
    my $can_focus   = $class->use_par($proto, 'can_focus',  $BOOL,      'False' );
    my $has_focus   = $class->use_par($proto, 'has_focus',  $BOOL,      'False' );
    my $extension_events = $class->use_par($proto, 'extension_events', $LOOKUP, '' );
    my $events      = $class->use_par($proto, 'events',     $DEFAULT,   0       );
    my ($work, @events);
    foreach $work (split(/\|/, $events)) {
        $work =~ s/\s*//g; # Trim off any whitespace
        $work = Glade::PerlUIGtk->lookup($work);
        push @events, $work;
    }
    $events = '';
    $events = join("', '", @events) if $#events >= 0;

    if ( (defined $proto->{'x'}) || (defined $proto->{'y'}) ) {
        my $x = $class->use_par($proto, 'x',  $DEFAULT, 0 );
        my $y = $class->use_par($proto, 'y',  $DEFAULT, 0 );
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->set_uposition(".
            "$x, $y );" );
    }
    if ( (defined $proto->{'width'}) || (defined $proto->{'height'}) ) {
        my $width  = $class->use_par($proto, 'width',  $DEFAULT, 0 );
        my $height = $class->use_par($proto, 'height', $DEFAULT, 0 );
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->set_usize(".
            "$width, $height );" );
    }
    if ( $proto->{'sensitive'} ) {
        my $sensitive = $class->use_par($proto, 'sensitive', $BOOL, 'True'  );
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->set_sensitive($sensitive);");
    }

    if ( $can_default ) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->can_default(".
            "$can_default );" );
    }
    if ( $can_focus ) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->can_focus(".
            "$can_focus );" );
    }
    if ($has_default) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->has_default(".
            "$has_default );" );
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->grab_default;");
    }
    if ( $has_focus ) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->has_focus(".
            "$has_focus );" );
    }
    if ( $extension_events ) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->set_extension_events(".
            "'$extension_events' );" );
    }
    if ( $events ) {
        $class->add_to_UI( $depth, "${current_form}\{'$name'}->set_events(".
            "['$events'] );" );
    }
}

sub set_window_properties {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = "$class->set_window_properties";
# For use by Window, (ColorSelectionDialog, Dialog (InputDialog), FileSelection)
    my $title        = $class->use_par($proto,'title',        $DEFAULT, '' );
    my $position     = $class->use_par($proto,'position',     $LOOKUP,  'mouse' );
    my $allow_grow   = $class->use_par($proto,'allow_grow',   $BOOL,    'True' );
    my $allow_shrink = $class->use_par($proto,'allow_shrink', $BOOL,    'True' );
    my $auto_shrink  = $class->use_par($proto,'auto_shrink',  $BOOL,    'False' );
    my $modal        = $class->use_par($proto,'modal',        $BOOL,    'False' );
    my $wmclass_name  = $class->use_par($proto, 'wmclass_name',  $DEFAULT, '' );
    my $wmclass_class = $class->use_par($proto, 'wmclass_class', $DEFAULT, '' );

    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_position('$position' );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_policy(".
        "$allow_shrink, $allow_grow, $auto_shrink );" );
    $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_modal($modal );" );
    if ( (defined $proto->{'width'}) || (defined $proto->{'height'}) ) {
        my $width  = $class->use_par($proto, 'width',  $DEFAULT, 0 );
        my $height = $class->use_par($proto, 'height', $DEFAULT, 0 );
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_usize(".
            "$width, $height );" );
    }
    if ( (defined $proto->{'default_width'}) || (defined $proto->{'default_height'}) ) {
        my $default_width  = $class->use_par($proto, 'default_width',  $DEFAULT, 0 );
        my $default_height = $class->use_par($proto, 'default_height', $DEFAULT, 0 );
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_default_size(".
            "$default_width, $default_height );" );
    }
    if ( (defined $proto->{'x'}) || (defined $proto->{'y'}) ) {
        my $x = $class->use_par($proto, 'x',  $DEFAULT, 0 );
        my $y = $class->use_par($proto, 'y',  $DEFAULT, 0 );
        $Glade_Perl->diag_print(1, "warn  Toplevel window uposition has been set ".
            "but breaks the window manager's placement policy, and is almost ".
            "certainly a bad idea. (Havoc Pennington)");
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_uposition(".
            "$x, $y );" );
    }
    if ($wmclass_name && $wmclass_class) {
        $class->add_to_UI( $depth, "\$widgets->{'$name'}->set_wmclass(".
            "'$wmclass_name', '$wmclass_class' );" );
    }
    $class->add_to_UI( $depth,  "\$widgets->{'$name'}->realize;" );
#use Data::Dumper;print Dumper($Glade_Perl->source);
    unless ($Glade_Perl->source->quick_gen) {
    	$widgets->{$name}->signal_connect("destroy" => \&Gtk::main_quit);
	    $widgets->{$name}->signal_connect("delete_event" => \&Gtk::main_exit);
    }
    $class->pack_widget($parent, $name, $proto, $depth );
}

sub pack_widget {
    my ($class, $parent, $name, $proto, $depth) = @_;
    my $me = "$class->pack_widget";

    $class->internal_pack_widget($parent, $name, $proto, $depth );
    $class->set_widget_properties($parent, $name, $proto, $depth);
    $class->set_container_properties($parent, $name, $proto, $depth);
    $class->set_tooltip($name, $proto, $depth );
}

sub new_accelerator {
    my ($class, $parentname, $proto, $depth, $gnome_frig) = @_;
    my $me = "$class->new_accelerator";
    my $mods = '[]';
    my $accel_flags = "['visible', 'locked']";
#   my $key       = $class->use_par($proto, 'key', $LOOKUP);
    my $key       = $class->use_par($proto, 'key', $KEYSYM);
    my $modifiers = $class->use_par($proto, 'modifiers',    $DEFAULT, 0);
    my $signal    = $class->use_par($proto, 'signal');
    unless (defined $need_handlers->{$parentname}{$signal}) {
        $need_handlers->{$parentname}{$signal} = undef;
    }

# FIXME move this to use_par
#--------------------------------------
    # Turn GDK values into array of $LOOKUPs
    unless ($modifiers eq 0) {
        $modifiers =~ s/ *//g;
        $modifiers =~ s/GDK_//g;
        $mods = "['".lc(join ("', '", split(/\|/, $modifiers)))."']";
    }
#--------------------------------------

#  gtk_widget_add_accelerator (accellabel3, "button_press_event", accel_group,
#                              GDK_L, GDK_MOD1_MASK,
#                              GTK_ACCEL_VISIBLE);
#    $class->add_to_UI( $depth, "${current_form}\{'$parentname'}->add_accelerator(".
#        "'$signal', ${current_form}\{'accelgroup'}, '$key', $mods, $accel_flags);");

    if ($gnome_frig) {
        $class->add_to_UI( $depth, 
            "${current_window}\->set_accelerator(".
                "$gnome_frig, $key, $mods);");
    
    } elsif ($Glade_Perl->source->quick_gen) {
        # Do no checks
        
    } elsif (eval "${current_form}\{'$parentname'}->can('$signal')") {
        $class->add_to_UI( $depth, "${current_form}\{'accelgroup'}->add(".
#            ($key || "''").
            "\$Gtk::Keysyms{'$key'} || Gtk::Gdk->keyval_from_name('$key') || ".
            $Gtk::Keysyms{$key}.
            " , $mods, $accel_flags, ".
            "${current_form}\{'$parentname'}, '$signal');");
    } else {
        $Glade_Perl->diag_print (1, "error Widget '%s' can't emit signal ".
            "'%s' as requested - what's wrong?",
            $parentname, $signal);
    }
}

sub new_style {
    my ($class, $parentname, $proto, $depth) = @_;
    my $me = "$class->new_style";
    my ($state, $color, $value, $element, $lc_state);
    my ($red, $green, $blue);
    $class->add_to_UI( $depth, "$current_form\{'$parentname-style'} = ".
        "new Gtk::Style;");
#    $class->add_to_UI( $depth, "$current_form\{'$parentname-style'} = ".
#       "$current_form\{'$parentname'}->style;");
    my $style_font = $class->use_par($proto, 'style_font', $DEFAULT, '');
    if ($style_font) {
        $class->add_to_UI( $depth, "$current_form\{'$parentname-style'}".
            "->font(Gtk::Gdk::Font->load('$style_font'));");
    }
    foreach $state ("NORMAL", "ACTIVE", "PRELIGHT", "SELECTED", "INSENSITIVE") {
        $lc_state = lc($state);
        foreach $color ('fg', 'bg', 'text', 'base') {
            $element = "$color-$state";
            if ($proto->{$element}) {
                $value = $class->use_par($proto, $element, $DEFAULT, '');
                $Glade_Perl->diag_print(6, "%s- We have a style element ".
                    "'%s' which is '%s'", $indent, $element, $value);
                ($red, $green, $blue) = split(',', $value);
                # Yes I really mean multiply by 257 (0x101)
                # We scale these so that 0x00 -> 0x0000
                #                        0x0c -> 0x0c0c
                #                        0xff -> 0xffff
                # This spreads the values 0x00 - 0xff throughout the possible 
                # Gdk values of 0x0000 - 0xffff rather than 0x00 - 0xff00
                $red   *= 257;
                $green *= 257;
                $blue  *= 257;
                $class->add_to_UI( $depth, "$current_form\{'$parentname-$color-$lc_state'} ".
                    "= $current_form\{'$parentname-style'}->$color('$lc_state');");
                $class->add_to_UI( $depth, "$current_form\{'$parentname-$color-$lc_state'}".
                    "->red($red);");
                $class->add_to_UI( $depth, "$current_form\{'$parentname-$color-$lc_state'}".
                    "->green($green);");                
                $class->add_to_UI( $depth, "$current_form\{'$parentname-$color-$lc_state'}".
                    "->blue($blue);");                
                $class->add_to_UI( $depth, "$current_form\{'$parentname-style'}".
                    "->$color('$lc_state', $current_form\{'$parentname-$color-$lc_state'});");
            }
        }
        $element = "bg_pixmap-${state}";
        if ($proto->{$element}) {
        	$class->add_to_UI( $depth, "($current_form\{'$parentname-bg_pixmap-$lc_state'}, ".
                "$current_form\{'$parentname-bg_mask-$lc_state'}) = ".
                    "Gtk::Gdk::Pixmap->create_from_xpm($current_window->get_toplevel->window, ".
                        "$current_form\{'$parentname-style'}, '$proto->{$element}' );");
            $class->add_to_UI( $depth, "$current_form\{'$parentname-style'}".
                "->bg_pixmap('$lc_state', $current_form\{'$parentname-bg_pixmap-$lc_state'});");
        }
    }
    if (eval "$current_form\{'$parentname'}->can('child')") {
        $class->add_to_UI( $depth, "$current_form\{'$parentname'}->child->set_style(".
            "$current_form\{'$parentname-style'});");
    }
    $class->add_to_UI( $depth, "$current_form\{'$parentname'}->set_style(".
            "$current_form\{'$parentname-style'});");
}

sub new_from_child_name {
    my ($class, $parent, $name, $proto, $depth) = @_;
    return undef unless $proto->{'child_name'};

    my $type = $class->use_par($proto, 'child_name' );
    if ($type eq 'GnomeEntry:entry') {
        $type = 'gtk_entry';
#        $type =~ s/.*:(.*)/gtk_$1/;

    } elsif ($type eq 'GnomePixmapEntry:file-entry') {
        $type = 'gnome_file_entry';

    } elsif (' Toolbar:button GnomeDock:contents GnomeDruidPageStandard:vbox Dialog:action_area Dialog:vbox ' =~ m/ $type /) {
        # Keep the full child_name for later use

    } else {
        # Just use the bit after the colon
        $type =~ s/.*:(.*)/$1/;

    }
#---------------------------------------
    if ($type eq 'action_area') {
        # Gtk|Gnome::Dialog have widget tree that is not reflected by
        # the methods that access them. $dialog->action_area() points to
        # a child of $dialog->vbox() and not of $dialog. 
        # In any case, they cannot be used/accessed until something is 
        # added to them by the automagic ->new('title', 'Button_Ok',...).
        #
        # For Gnome::Dialog and derivatives we can use ->append_button() 
        # (which calls gnome_dialog_init_action_area)
        unless ($class->my_gtk_perl_can_do('gnome_dialog_append_button')) {
            # Force HButtonbox to construct its widget and add it to the VBox 
            # This will look wrong (above the separator)
            return undef;
        
        } else {
            # Append the buttons by name
#                            $childname = $class->Widget_from_Proto( $proto->{name}, 
#                                $proto->{$key}, $depth + 1, 
#                                $widget_hierarchy, $class_hierarchy );
            my $number_of_buttons = 
                $class->frig_Gnome_Dialog_buttons($parent, $proto, $depth);
            # Return the action_area now it exists
            $class->add_to_UI( $depth, 
                "\$widgets->{'$name'} = ${current_window}->$type;" );
        }
        
#---------------------------------------
    } elsif (' Dialog:action_area Dialog:vbox ' =~ / $type /) {
        $type =~ s/.*:(.*)/$1/;
        # Return the action_area now it exists
        $class->add_to_UI( $depth, 
            "\$widgets->{'$name'} = ${current_window}->$type;" );

#---------------------------------------
    } elsif ($type eq 'Toolbar:button') {
        my $pixmap_widget_name = 'undef';
        my ($group, $rb_group, $use_group);
        my $label   = $class->use_par($proto, 'label', $DEFAULT, '');
        my $icon    = $class->use_par($proto, 'icon',  $DEFAULT, '' );
#        my $stock_button = $class->use_par($proto, 'stock_button',  $LOOKUP, '' );

        my $tooltip = $class->use_par($proto, 'tooltip',       $DEFAULT, '' );
        if (eval "$current_form\{'$parent'}{'tooltips'}" && !$tooltip) {
            $Glade_Perl->diag_print (1, "warn  Toolbar '%s' is expecting ".
                "a tooltip but you have not set one for %s '%s'",
                $parent, $proto->{'class'}, $name);
        }            

        my $new_group = $class->use_par($proto->{'child'}, 'new_group', $BOOL, 0 );
        if ($new_group) {
            $class->add_to_UI( $depth, 
                "${current_form}\{'$parent'}->append_space;" );
        }

        if ($icon) {
            $pixmap_widget_name = "${current_form}\{'${name}-pixmap'}";
            $class->add_to_UI( $depth, 
                "$pixmap_widget_name = \$class->create_pixmap(".
                    "${current_window}, \"\$Glade::PerlRun::pixmaps_directory/$icon\" );" ); 

        } elsif ($proto->{'stock_pixmap'}) {
            my $stock_pixmap = $class->use_par($proto, 'stock_pixmap',  $LOOKUP, '' );
            if ($Glade_Perl->app->allow_gnome) {
                $pixmap_widget_name = "${current_form}\{'${name}-pixmap'}";
                $class->add_to_UI( $depth, 
                    "$pixmap_widget_name = Gnome::Stock->pixmap_widget(".
                        "$current_window, '$stock_pixmap');" ); 

            } else {
                $Glade_Perl->diag_print(1, "error You have specified a Gnome stock ".
                    "pixmap but this is not a Gnome project - stock pixmap omitted");
                $pixmap_widget_name = "undef";
            }

        } else {
            $pixmap_widget_name = "undef";
        }

        # We have label and so on to add
        if ($proto->{'class'} eq 'GtkToggleButton') {
            $type = 'togglebutton';

        } elsif ($proto->{'class'} eq 'GtkRadioButton') {
            $type = 'radiobutton';
            $group  = $class->use_par($proto, 'group', $DEFAULT, '' );
            $rb_group = "$current_form\{'rb-group-$group'}";
            if ($rb_group && eval "defined $rb_group") {
                $use_group = $rb_group;
            }

        } else {
            $type =~ s/.*:(.*)/$1/;
        }

        $use_group ||= 'undef';
        $class->add_to_UI( $depth, 
            "\$widgets->{'$name'} = ".
                "${current_form}\{'$parent'}->append_element(".
                    "'$type', $use_group, _('$label'), ".
                    "_('$tooltip'), '', $pixmap_widget_name );" );

        unless (!$rb_group || eval "defined $rb_group") {
            $class->add_to_UI( $depth,  
                "$rb_group = \$widgets->{'$name'};" );
        }
            
#---------------------------------------
    } elsif (' GnomeDock:contents ' =~ / $type /) {
        return undef;
        # FIXME This doesn't make sense to me, get_client_area wants a DockItem
#            $class->add_to_UI( $depth, 
#                "\$widgets->{'$name'} = ".
#                    "${current_form}\{'$parent'}->get_client_area;" );
#            $class->add_to_UI( $depth, 
#                "\$widgets->{'$name'} = ".
#                    "${current_form}\{'$parent'}->get_client_area;" );

#---------------------------------------
    } elsif (' GnomeDruidPageStandard:vbox ' =~ / $type /) {
        $class->add_to_UI( $depth, 
            "\$widgets->{'$name'} = ${current_form}\{'$parent'}->vbox;" );

#---------------------------------------
    } elsif ($Glade_Perl->source->quick_gen || eval "${current_form}\{'$parent'}->can('$type')") {
        my $label   = $class->use_par($proto, 'label', $DEFAULT, '');
        $class->add_to_UI( $depth, 
            "\$widgets->{'$name'} = ".
                "${current_form}\{'$parent'}->$type;" );

        if ($label) {
            if ($Glade_Perl->source->quick_gen) {
                $class->add_to_UI( $depth, 
                    "\$widgets->{'$name'}->child->set_text(_('$label'));", 
                    'TO_FILE_ONLY' );

            } elsif ($widgets->{$name}->can('child')) {
                my $childref = ref $widgets->{$name}->child;
            
                if ($childref eq 'Gtk::Label') {
                    $class->add_to_UI( $depth, 
                        "\$widgets->{'$name'}->child->set_text(_('$label'));", 
                        'TO_FILE_ONLY' );
                } else {
                    $Glade_Perl->diag_print (1, "error We have a label ".
                        "('%s') to set but the child of %s ".
                        "isn't a label (actually it's a %s)",
                        $label, "${current_form}\{'$name'}", $childref);
                }
            } else {
                $Glade_Perl->diag_print (1, "error We have a label ('%s') to ".
                    "set but %s doesn't have a ->child() accessor",
                    $label, "${current_form}\{'${name}'}");
            }
        }

#---------------------------------------
    } elsif ($type eq 'notebook') {
        return undef;
        
#---------------------------------------
    } else {
        $Glade_Perl->diag_print (1, "error Don't know how to get a ref to %s ".
            "(type '%s')",
            "${current_form}\{'${name}'}{'child_name'}", $type);
        return undef;
    }

    $class->add_to_UI( $depth, "\$widgets->{'$name'}->show;" );
# FINDME This is to remove
    $class->add_to_UI( $depth, 
        "${current_form}\{'$name'} = \$widgets->{'$name'};" );
    # Delete the $widget to show that it has been packed
    delete $widgets->{$name};

    # Deal with all the other widget properties that might be set
    $class->set_widget_properties($parent, $name, $proto, $depth);
    $class->set_container_properties($parent, $name, $proto, $depth);
    $class->set_tooltip($name, $proto, $depth );

    # we have constructed the widget so caller doesn't need to
    return 1;
}

sub new_signal {
    my ($class, $parentname, $proto, $depth) = @_;
    my $me = "$class->new_signal";
    my $signal  = $proto->{name};
    my ($call, $expr, $when, $changes);
#    $class = ref $class || $class;
# FIXME to do signals properly
    if ($proto->{'handler'}) {
        my $ignore = $class->use_par($proto, 'last_modification_time');
        my $handler = $class->use_par($proto, 'handler');
        my $object  = $class->use_par($proto, 'object', $DEFAULT, '');
        my $data    = $class->use_par($proto, 'data', $DEFAULT, '');
        my $after   = $class->use_par($proto, 'after', $BOOL, 'False');

        # Triple escape any double-quotes so that they get passed through
        $changes  = $data =~ s/(?!\\)(.)"/$1\\\\\\"/g;
        $changes += $data =~ s/^"/\\\\\\"/g;
        if ($changes) {
            $Glade_Perl->diag_print (1, "warn signal handler data ('%s') ".
                "contains %s double-quote(s) which has(ve) been ".
                "escaped so that they are preserved. ",
                $handler, $changes);
        }
        unless ($object) {$object = $parentname}
        if ($after)  {
            $when = 'after_';
            $call .= 'signal_connect_after'
        } else {
            $when = '';
            $call .= 'signal_connect'
        }

        $handler = $class->fix_name($handler, 'TRANSLATE');

        if ($handler =~ /[- \.]/) {
            my %ents=('-'=>'MINUS',' '=>'SPACE','.'=>'DOT');
            $changes = $handler =~ s/([- \.])/_$ents{$1}_/g;
            $Glade_Perl->diag_print (1, "error signal handler ('%s') ".
                "contains %s minus sign/space/dot(s) which has(ve) been ".
                "substituted because they are illegal in a sub name in Perl. ",
                $handler, $changes);
        }            
        # We can check dynamically below
        # Flag that we are done
        delete $need_handlers->{$parentname}{$signal};
        # We must log the sub name for dynamic stub handlers
        unless ( ($Glade::PerlSource::subs =~ m/ $handler /) or    
            (defined $handlers->{$handler}) or 
            ($Glade_Perl->Building_UI_only) ) {
            $subs .= "$handler\n$indent".(' ' x 19 );
            eval "$current_form\{_HANDLERS}{'$handler'} = 'signal'";
        }
        if ($class->can($handler) || 
            eval "$current_name->can('$handler')"
            ) {
            # Handler already available - no need to generate a stub
            eval "delete $current_form\{_HANDLERS}{'$handler'}";
            # First connect the signal handler as best we can
            unless ($Glade_Perl->Writing_Source_only) {
                $expr = "push \@{${current_form}\{'Signal_Strings'}}, ".
                    "\"\\${current_form}\{'$object'}->$call( ".
                    "'$signal', \\\"\$class\\\::$handler\\\", '".$data."', '$object', ".
                    "'name of form instance' )\"";
                eval $expr
            }
        } else {
            # First we'll connect a default handler to hijack the signal 
            # for us to use during the Build run
            $Glade_Perl->diag_print (4, "warn  Missing signal handler '%s' ".
                "connected to widget '%s' needs to be written",
                $handler, $object);
            unless ($Glade_Perl->Writing_Source_only) {
                $expr = "push \@{${current_form}\{'Signal_Strings'}}, ".
                "\"\\${current_form}\{'$object'}->$call(".
                "'$signal', \\\"\$class\\\::missing_handler\\\", ".
                "'$parentname', '$signal', '$handler', '".
                $Glade_Perl->app->logo."' )\"";
                eval $expr
            }
        }
        # Now write a signal_connect for generated code
        # All these back-slashes are really necessary as these strings
        # are passed through so many others (evals and so on)
        my $id_string = "";
        if ($Glade_Perl->source->save_connect_id) {
            $id_string = 
                "\\\\\\${current_form}\{'__CONNECT_ID'}{'$object'}{'$when$signal'} = ";
        }
        $expr = "push \@{${current_form}\{'Signal_Strings'}}, ".
            "\"$class->add_to_UI( 1, \\\"".$id_string.
            "\\\\\\${current_form}\{'$object'}->$call(".
            "'$signal', \\\\\\\"\\\\\\\$class\\\\\\\\\::$handler\\\\\\\", '".$data."', '$object', ".
            "\\\\\\\"$current_form_name\\\\\\\" );\\\", 'TO_FILE_ONLY' );\"";
        $Glade_Perl->diag_print (4, "warn  Connecting missing signal handler '%s' ",
            $expr);
        eval $expr
            
    } else {
        # This is a signal that we will cause
    }
}

1;

__END__

