# (C) Daniel Kasak: d.j.kasak.dk@gmail.com
# See COPYRIGHT file for full license

package Gtk2::Ex::DBI;

use strict;
use warnings;
#no warnings;

use Carp;
use Data::Dumper;

use POSIX;
use XML::Simple;
use Time::HiRes;
use Glib qw/TRUE FALSE/;

use Gtk2::Ex::Dialogs (
                        destroy_with_parent => TRUE,
                        modal               => TRUE,
                        no_separator        => FALSE
);

BEGIN {
    $Gtk2::Ex::DBI::VERSION = '2.30';
}

sub new {
   	
	my ( $class, $req, $xml_options ) = @_;
	
	my $self;
	
	if ( ref $req eq "HASH" ) {
    	
    	# Assemble object from request
    	$self = {
            dbh                     => $$req{dbh}                                  # A database handle
    	  , primary_keys            => $$req{primary_keys}                         # An array of primary keys
          , sql                     => $$req{sql}                                  # A hash of SQL related stuff
          , widgets                 => $$req{widgets}                              # A hash of field definitions and stuff
          , schema                  => $$req{schema}                               # The 'schema' to use to get column info from
          , builder                 => $$req{builder}                              # The Gtk2-Builder object ... use either this or 'form', below
          , form                    => $$req{form}                                 # The Gtk2-GladeXML *object* we're using
          , formname                => $$req{formname}                             # The *name* of the window ( needed for dialogs to work properly )
          , read_only               => $$req{read_only} || FALSE                   # Whether changes to the table are allowed
          , apeture                 => $$req{apeture} || 100                       # The number of records to select at a time
          , on_current              => $$req{on_current}                           # A reference to code that is run when we move to a new record
          , before_query            => $$req{before_query}                         # A reference to code that is run *before* a query is executed ( can abort the query )
          , before_apply            => $$req{before_apply}                         # A reference to code that is run *before* the 'apply' method is called
          , on_apply                => $$req{on_apply}                             # A reference to code that is run *after* the 'apply' method is called
          , on_undo                 => $$req{on_undo}                              # A reference to code that is run *after* teh 'undo' method is called
          , on_changed              => $$req{on_changed}                           # A reference to code that is run *every* time a managed field is changed
          , on_initial_changed      => $$req{on_initial_changed}                   # A reference to code that is run when the recordset status *initially* changes to CHANGED 
          , auto_apply              => $$req{auto_apply}                           # Boolean to force all records to be applied automatically when querying, closing, etc
          , calc_fields             => $$req{calc_fields}                          # Calculated field definitions
          , defaults                => $$req{defaults}                             # Default values
          , disable_find            => $$req{disable_find} || FALSE                # Do we build the right-click 'find' item on GtkEntrys?
          , disable_full_table_find => $$req{disable_full_table_find} || FALSE     # Can the user search the whole table ( sql=>{from} ) or only the current recordset?
          , combos                  => $$req{combos}                               # Definitions to set up combos
          , autocompletions         => $$req{autocompletions}                      # Definitions to set up autocompletions
          , data_lock_field         => $$req{data_lock_field} || undef             # A field to use as a data-driven lock ( positive values will lock the record )
          , status_label            => $$req{status_label} || "lbl_RecordStatus"   # The name of a field to use as the record status indicator
          , record_spinner          => $$req{record_spinner} || "RecordSpinner"    # The name of a GtkSpinButton to use as the RecordSpinner
          , quiet                   => $$req{quiet} || FALSE                       # A flag to silence warnings such as missing widgets
          , friendly_table_name     => $$req{friendly_table_name}                  # Table name to use when issuing GUI errors
          , custom_changed_text	    => $$req{custom_changed_text}                  # Text ( including markup ) to use in GUI questions when changes need to be applied
          , changed                 => FALSE                                       # A flag indicating that the current record has been changed
          , changelock              => FALSE                                       # Prevents the 'changed' flag from being set when we're moving records
          , constructor_done        => FALSE                                       # A flag that indicates whether the new() method has completed yet
          , debug                   => $$req{debug} || FALSE                       # Dump info to terminal
          , skip_query              => $$req{skip_query}                           # Don't call query() in the constructor
          , dont_update_keys        => $$req{dont_update_keys}                     # Don't include primary keys in update statements
          , widget_prefix           => $$req{widget_prefix}                        # A string to prefix ( glade ) widget names with when searching for them
          , auto_incrementing       => $$req{auto_incrementing}                    # A flag to indicate whether we should try to poll the last inserted ID after an insert
    	};
    	
	} else {
	    
	    # Assume we're loading an XML
	    my $xml_cfg = XML::Simple->new(
            AttrIndent          => TRUE,                    # XML formatting option - doesn't affect performance
            OutputFile          => $self->{xml_file},
            KeyAttr             => [ ]                      # Stops XML::Simple from squishing some data structures
        );
        
        $self = $xml_cfg->XMLin( $req );
        
        # Attach to the libglade / builder object
        if ( exists $xml_options->{glade_xml} ) {
            $self->{form} = $xml_options->{glade_xml};
        } elsif ( exists $xml_options->{gtk_builder} ) {
        	$self->{builder} = $xml_options->{gtk_builder};
        }
        
        
        # Link DBI connections
        $self->{dbh} = $xml_options->{connections}->{ $self->{Connection} };
        
        foreach my $combo ( keys %{$self->{combos}} ) {
            $self->{combos}->{$combo}->{alternate_dbh} = $xml_options->{connections}->{ $self->{combos}->{$combo}->{connection_name} };
        }
        
	}
	
	my $legacy_warnings;
	
	if ( $self->{debug} ) {
		print "\nGtk2::Ex::DBI version $Gtk2::Ex::DBI::VERSION initialising ...\n\n";
	}
	
	# Check we've been passed enough stuff to continue ...
	
	if ( ! $self->{dbh} ) {
        croak( "Gtk2::Ex::DBI constructor missing a dbh!\n" );
    }
	
	if ( ! $self->{form} && ! $self->{builder} ) {
		croak( "Gtk2::Ex::DBI constructor missing a 'form' ( Gtk2::GladeXML ) and a 'builder' ( Gtk2::Builder ) ..."
		  . " You need one or the other" );
	}
	
    # Set window object for later ( optionally based on legacy 'formname' string )
    if ( ! $self->{formname} ) {
        if ( exists $self->{form} && ref $self->{form} eq "Gtk2::GladeXML" ) {
            foreach my $item ( $self->{form}->get_widget_prefix( "" ) ) {
                if ( ref $item eq "Gtk2::Window" || ref $item eq "Gtk2::Dialog") {
                    $self->{window} = $item;
                    last;
                }
            }
        } elsif ( exists $self->{builder} && ref $self->{builder} eq "Gtk2::Builder" ) {
            foreach my $item ( $self->{builder}->get_objects() ) {
                if ( ref $item eq "Gtk2::Window" || ref $item eq "Gtk2::Dialog") {
                    $self->{window} = $item;
                    last;
                }
            }
        }
        # Now check that we have a window
        if ( ! $self->{window} ) {
            croak( "Gtk2::Ex::DBI wasn't passed a formname,"
                . " AND failed to find a Gtk2::Window or Gtk2::Dialog to manage!\n" );
        }
    } else {
        # This doens't really warrant a 'legacy warnings' type thing, but a warning anyway ...
        carp( "\nThe formname key in now depreciated. Gtk2::Ex::DBI can now find"
            . " the Gtk2::Window object to manage without being passed a formname ... but make"
            . " sure you only have ONE GtkWindow object per GladeXML file ( for many reasons ).\n" );
        $self->{window} = $self->get_widget( $self->{formname} );
	}
    
    if ( $self->{sql} ) {
        if ( exists $self->{sql}->{pass_through} ) {
            # pass_throughs are read-only at the moment ... it's all a bit hackish
            $self->{read_only} = TRUE;
        } elsif ( ! ( exists $self->{sql}->{select} && exists $self->{sql}->{from} ) ) {
            croak( "Gtk2::Ex::DBI constructor missing a complete sql definition!\n"
                . "You either need to specify a pass_through key ( 'pass_through' )\n"
                . "or BOTH a 'select' AND and a 'from' key\n" );
        }
    }
    
    if ( exists $self->{readonly} ) {
        carp( "\n\n Gtk2::Ex::DBI option 'readonly' renamed to 'read_only' ...\n"
            . "... Sorry about that ... done for consistancy.\n\n" );
        $self->{read_only} = $self->{readonly};
    }
    
    bless $self, $class;
    
    if ( $self->{data_lock_field} && ! $self->get_widget($self->{data_lock_field}) ) {
        carp( "\n\n Gtk2::Ex::DBI created with a data_lock_field,\n"
            . " but couldn't find a matching widget!\n"
            . " You *need* a matching widget.\n"
            . " Make it invisible if you don't want to see it.\n"
            . " Patches to remove this requirement gladly accepted :)\n"
            . " * * * DATA DRIVEN LOCKING DISABLED * * *\n\n" );
        delete $self->{data_lock_field};
    }
    
    # Set up combo box models
    foreach my $combo ( keys %{$self->{combos}} ) {
        $self->setup_combo( $combo );
    }
    
    # ... and autocompletions
    foreach my $autocompletion ( keys %{$self->{autocompletions}} ) {
        $self->setup_autocompletion( $autocompletion );
    }
    
    # Reconstruct sql object if needed
    if ( $self->{sql_select} || $self->{table} || $self->{sql_where} || $self->{sql_order_by} ) {
        
        # Strip out SQL directives
        if ( $self->{sql_select} ) {
            $self->{sql_select}   =~ s/^select //i;
        }
        if ( $self->{sql_table} ) {
            $self->{sql_table}    =~ s/^from //i;
        }
        if ( $self->{sql_where} ) {
            $self->{sql_where}    =~ s/^where //i;
        }
        if ( $self->{sql_order_by} ) {
            $self->{sql_order_by} =~ s/^order by //i;
        }
        
        # Assemble things
        my $sql = {
            select      => $self->{sql_select},
            from        => $self->{table},
            where       => $self->{sql_where},
            order_by    => $self->{sql_order_by}
        };
        
        $self->{sql} = $sql;
        
        $legacy_warnings .= " - use the new sql object for the SQL string\n";
        
    }
    
    # Set the table name to use for GUI errors
    if ( ! $self->{friendly_table_name} ) {
        $self->{friendly_table_name} = $self->{sql}->{from};
    }
    
    # Primary Key - oldest
    if ( ref $req eq 'HASH' ) {
        if ( exists $$req{primarykey} ) {
            push @{$self->{primary_keys}}, $$req{primarykey};
            $legacy_warnings .= " - primarykey pushed onto primary_keys array\n";
        }
        
        # Primary Key - 2nd oldest
        if ( exists $$req{primary_key} ) {
            push @{$self->{primary_keys}}, $$req{primary_key};
            $legacy_warnings .= " - primary_key pushed onto primary_keys array\n";
        }
        
    }
    
    if ( $legacy_warnings || $self->{legacy_mode} ) {
        carp ( "**** Gtk2::Ex::DBI starting in legacy mode ***\n"
            .  "While quite some effort has gone into supporting this, it would be wise to take action now.\n"
            .  "Warnings triggered by your request:\n$legacy_warnings\n" );
    }
    
    # NOTE The code below that constructs the widgets hash has been copied into axis::form_editor
    # Please make sure any changes here also get reflected there
    
    # TODO Should we move this code to a central location instead of having 2 copies?
    
    $self->{server} = $self->{dbh}->get_info( 17 );
    
    # Some PostGreSQL stuff - DLB
    if ( $self->{server} =~ /postgres/i ) {
        if ( ! $self->{search_path} ) {
            if ( $self->{schema} ) {
                $self->{search_path} = $self->{schema} . ",public";
            } else {
                $self->{search_path} = "public";
            }
        }
        my $sth = $self->{dbh}->prepare ( "SET search_path to " . $self->{search_path} );
        eval {
            $sth->execute or die $self->{dbh}->errstr;
        };
        if ( $@ ) {
            carp( "Failed to set search_path to " . $self->{search_path}
                . " for a Postgres database. I'm not sure what the implications of this are. Postgres users, please report ...\n" );
        }
    }
    
    if ( $self->{widgets} && ! $self->{sql}->{select} && ! $self->{sql}->{pass_through} ) {
        
        # Reconstruct SQL select string if we've got a 'widgets' hash but no SQL select
        
        $self->{sql}->{select} = "";
        
        foreach my $fieldname ( keys %{$self->{widgets}} ) {
            if ( $self->{widgets}->{$fieldname}->{sql_fieldname} ) {
                # Support for aliases
                $self->{sql}->{select} .= " $self->{widgets}->{$fieldname}->{sql_fieldname} as $fieldname";
            } else {
                # Otherwise just use the default fieldname
                $self->{sql}->{select} .= " $fieldname";
            }
            $self->{sql}->{select} .= ",";
        }
        
        chop( $self->{sql}->{select} );
        
    } elsif ( $self->{sql}->{select} && $self->{sql}->{select} !~ /[\*|%]/ ) {
        
        # Construct a widgets hash from the select string
        
        # TODO: Breaks with new-line characters OR ( excess )leading spaces
        
        foreach my $fieldname ( split( / *, */, $self->{sql}->{select} ) ) {
            if ( $fieldname =~ m/ as /i ) {
                my ( $sql_fieldname, $alias ) = split( / as /i, $fieldname );
                $self->{widgets}->{$alias} = { sql_fieldname    => $sql_fieldname };
            } else {
                if ( ! exists $self->{widgets}->{$fieldname} ) {
                    $self->{widgets}->{$fieldname} = {};
                }
            }
        }
        
    } else {
        
        # If we're using a wildcard SQL select or a pass-through, then we use the fieldlist
        # to construct the widgets hash
        
        my $sth;
        
        eval {
            if ( exists $self->{sql}->{pass_through} ) {
                $sth = $self->{dbh}->prepare( $self->{sql}->{pass_through} )
                    || croak( $self->{dbh}->errstr );
            } else {
                $sth = $self->{dbh}->prepare(
                    "select " . $self->{sql}->{select} . " from " . $self->{sql}->{from} . " where 0=1")
                        || croak( $self->{dbh}->errstr );
            }
        };
        
        if ( $@ ) {
            Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
                title   => "Error in Query!",
                icon    => "error",
                text    => "<b>Database Server Says:</b>\n\n$@"
            );
            return FALSE;
        }
        
        eval {
            $sth->execute || croak( $self->{dbh}->errstr );
        };
        
        if ( $@ ) {
            Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
                title   => "Error in Query!",
                icon    => "error",
                text    => "<b>Database Server Says:</b>\n\n$@"
            );
            return FALSE;
        }
        
        foreach my $fieldname ( @{$sth->{'NAME'}} ) {
            if ( ! $self->{widgets}->{$fieldname} ) {
                $self->{widgets}->{$fieldname} = {};
            }
        }
        
        $sth->finish;
        
    }
    
    # Construct a hash to map SQL fieldnames to widgets
    foreach my $widget ( keys %{$self->{widgets}} ) {
        $self->{sql_to_widget_map}->{$self->{widgets}->{$widget}->{sql_fieldname} || $widget} = $widget;
    }
    
    my $sth;
    
    # Set the auto_incrementing flag if this value is not already defined.
    if ( ! exists $self->{auto_incrementing} ) {
        $self->{auto_incrementing} = 1;
    }
    
    # Fetch primary key(s), but only if we haven't been passed one in the constructor
    if ( ! $self->{primary_keys} ) {
        eval {
            $sth = $self->{dbh}->primary_key_info( undef, undef, $self->{sql}->{from} )
                || die $self->{dbh}->errstr;
        };
        if ( ! $@ ) {
            while ( my $row = $sth->fetchrow_hashref ) {
                if ( $self->{debug} ) {
                    print "Gtk2::Ex::DBI bound to $self->{friendly_table_name} detected primary key item: $row->{COLUMN_NAME}\n";
                }
                push @{$self->{primary_keys}}, $row->{COLUMN_NAME};
                if ( exists $row->{KEY_SEQ} ) {
                    if ( ! $row->{KEY_SEQ} ) {
                        if ( $self->{debug} ) {
                            print "This primary key is NOT auto-incrementing. I hope you know what you're doing ...\n";
                        }
                        $self->{auto_incrementing} = 0;
                    }
                }
            }
        }
    }
    
    # Fetch column_info for current table
    eval {
        if ( $self->{sql}->{pass_through} ) {
            $sth = $self->{dbh}->column_info( undef, $self->{schema}, $self->{sql}->{pass_through}, '%' )
                || die $self->{dbh}->errstr;
        } else {
            $sth = $self->{dbh}->column_info( undef, $self->{schema}, $self->{sql}->{from}, '%' )
                || die $self->{dbh}->errstr;
        }
    };
    
    if ( $@ && ! $self->{primary_keys} ) {
        
        # Old versions of SQLite don't support column_info, but do support primary_key_info
        # This might be the case for other database servers, so we'll try primary_key_info and
        # see what happens ...
        
        eval {
            $sth = $self->{dbh}->primary_key_info( undef, undef, $self->{sql}->{from} )
                || die $self->{dbh}->errstr;
        };
        
        if ( ! $@ ) {
            # It works!
            while ( my $row = $sth->fetchrow_hashref ) {
                print "Gtk2::Ex::DBI bound to $self->{friendly_table_name} detected primary key item: $row->{COLUMN_NAME}\n";
                push @{$self->{primary_keys}}, $row->{COLUMN_NAME};
            }
        }
        
        if ( ! $self->{primary_keys} ) {
            # That's it. I give up. No read-write access for you!
            if ( ! $self->{quiet} ) {
                carp( "\nAll known methods of fetching the primary key from " . $self->{server} . " failed :("
                    . " ... If column_info fails ( eg multi-table queries ), then you MUST ...\n"
                    . " ... provide a primary_keys array in the constructor ...\n"
                    . " ... if you want to be able to update the recordset ...\n"
                    . " ... Defaulting to READ-ONLY mode ...\n" );
            }
            $self->{read_only} = TRUE;
        }
        
    } else {
        
        while ( my $column_info_row = $sth->fetchrow_hashref ) {
            # Loop through the list of columns from the database, and
            # add only columns that we're actually dealing with
            for my $fieldname ( keys %{$self->{sql_to_widget_map}} ) {
                if ( $column_info_row->{COLUMN_NAME} eq ( $fieldname ) ) {
                    # Note that we want to store this against the fieldname and NOT the sql_fieldname
                    $self->{column_info}->{ $self->{sql_to_widget_map}->{$fieldname} } = $column_info_row;
                    last;
                }
            }
        }
        
    }
    
    # Make sure we've got the primary key in the widgets hash and the sql_to_widget_map hash
    # It will NOT be here unless it's been specified in the SQL select string or the widgets hash already
    # Note that we test the sql_to_widget_map, and NOT the widgets hash, as we don't know what
    # the widget might be called, but we DO know what the name of the key in the sql_to_widget_map
    # should be
    foreach my $primary_key ( @{$self->{primary_keys}} ) {
        if ( ! exists $self->{sql_to_widget_map}->{ $primary_key } ) {
            $self->{widgets}->{ $primary_key } = {};
            $self->{sql_to_widget_map}->{ $primary_key } = $primary_key;
        }
        if ( $self->{dont_update_keys} ) {
            $self->{widgets}->{ $primary_key }->{dont_update} = 1;
        }
    }
    
    # If things failed above, we mightn't have a $sth to finish, so
    # check we do first ...
    if ( $sth ) {
        $sth->finish;
    }
    
    if ( ! $self->{skip_query} ) {
        $self->query;
    }
    
    # We connect a few little goodies to various widgets ...
    
    # - Connect our 'changed' method to whatever signal each widget emits when it's 'changed'
    
    # - Gtk's ComboBoxEntry has a bug where it only registers a change and set's the currect iter if
    # the combo box functionality is used. If the Entry functionality is used ( ie someone types a
    # string that matches one in the list ), NOTHING is registered, and the active iter is not set.
    # We *NEED* to work around this until the bug is fixed, otherwise ComboBoxEntrys are horribly broken.
    # Therefore we connect the sub set_active_iter_for_broken_combo_box to the on_focus_out event.
    
    # See http://bugzilla.gnome.org/show_bug.cgi?id=156017
    # Note that while the above bug page shows this bug as being 'FIXED', I've yet to see this
    # fix materialise in Gtk2 - when it does I will limit our work-around to those affected
    # versions of Gtk2.
    
    # - Use the populate-popup signal of Gtk2::Entry widgets to add the 'find' menu item
    
    # - Connect to the 'key-press-event' signal of various widgets to move the focus along
    # ( ie as if the TAB key was pressed )
    
    # We also keep an array of widgets and signal ids so that we can disconnect all signal handlers
    # and cleanly destroy ourselves when requested
    
    # We also set up input / output formatters based on widget ( ie $self->{widgets} )
        
	# Set up some defaults for different widget types
    foreach my $fieldname ( keys %{$self->{widgets}} ) {
    
    	# Get hold of the widget def ...
        my $widget_def = $self->{widgets}->{$fieldname};
        
        if ( exists $widget_def->{number} ) {
        	
        	# Properties of the number format:
            # - decimals				- number of decimal places
            # - decimal_fill			- whether to pad decimals out to the number of decimals
            # - separate_thousands		- whether to separate thousands groups with a comma
            # - currency				- whether to apply currency formatting
            
            # Set some defaults for properties that haven't been specified ...
            
            if ( ! exists $widget_def->{number}->{decimal_fill} ) {
            	$widget_def->{number}->{decimal_fill} = TRUE;
            }
            
            if ( ! exists $widget_def->{number}->{separate_thousands} ) {
            	$widget_def->{number}->{separate_thousands} = TRUE;
            }
            
            # If this is a currency widget, default to 2 decial places
            if ( exists $widget_def->{currency} && $widget_def->{currency} && ! exists $widget_def->{number}->{decimals} ) {
            	$widget_def->{number}->{decimals} = 2;
            }
            
        }
        
        my @widgets;
        my $this_widget = $self->get_widget( $fieldname );
        
        if ( $this_widget ) {
            
            push @widgets, $this_widget;
            
        } else {
        	
        	# TODO Remove dodgy split-widget support and replace with custom widgets
            # Check for split-widget widgets ... at present, TimeSpinners
            foreach my $type qw / hh mm ss / {
                $this_widget = $self->get_widget( $fieldname . "_" . $type );
                if ( $this_widget ) {
                    push @widgets, $this_widget;
                }
            }
            
        }
        
        # Now we've either got nothing, or 1 widget in an array, or a number of widgets in an array
        foreach my $widget ( @widgets ) {
            
            my @signals;
            my $type = (ref $widget);
            
            # To aid in debugging, I first push these onto a temporary array ...
            if ( $type eq "Gtk2::Calendar" ) {
                
                push @signals, $widget->signal_connect_after(
                    day_selected =>                       sub { $self->changed( $fieldname ) } );
                
            } elsif ( $type eq "Gtk2::ToggleButton" ) {
                
                push @signals, $widget->signal_connect_after(
                    toggled =>              sub { $self->changed( $fieldname ) } );
                
            } elsif ( $type eq "Gtk2::TextView" ) {
                
                # In this case, we don't connect to the widget, but to the widget's buffer ...
                # ... so we swap the buffer into $widget, so we can disconnect our signal later
                $widget = $widget->get_buffer;
                push @signals, $widget->signal_connect_after(
                    changed =>              sub { $self->changed( $fieldname ) } );
                
            } elsif ( $type eq "Gtk2::ComboBoxEntry" ) {
                
                push @signals, $widget->signal_connect_after(
                    changed =>              sub { $self->changed( $fieldname ) } );
                
                # Append our work-around for broken combo directly to the objects_and_signals array ...
                #  ... We can't use the code below to append more than 1 widget at a time
                my $child_widget = $widget->get_child;
                
                my $signal = $child_widget->signal_connect_after(
                    changed =>              sub { $self->set_active_iter_for_broken_combo_box($widget) } );
                
                if ( $self->{debug} ) {
                    warn "Remembering object / signal pair for later disconnection ...\n"
                        . " Field:  $fieldname\n"
                        . " Widget: $child_widget\n"
                        . " Signal: $signal\n\n";
                }
                
                push @{$self->{objects_and_signals}},
                [
                    $child_widget,
                    $signal
                ];
                
                # Trigger 2 tab-forward events;
                #  1 to get to the combo part ( ie the child's parent widget )
                #  and 1 to get to the next widget
                $signal = $child_widget->signal_connect(
                    'activate' => sub { 
                        $self->{window}->child_focus('tab-forward');
                        $self->{window}->child_focus('tab-forward');
                } );
                
                if ( $self->{debug} ) {
                    warn "Remembering object / signal pair for later disconnection ...\n"
                        . " Field:  $fieldname\n"
                        . " Widget: $child_widget\n"
                        . " Signal: $signal\n\n";
                }
                
                push @{$self->{objects_and_signals}},
                [
                    $child_widget,
                    $signal
                ];
                
                # We also want a right-click menu for a Combo's child ( entry )
                $signal = $child_widget->signal_connect_after(
                    'populate-popup' =>     sub { $self->build_right_click_menu(@_) } );
                
                if ( $self->{debug} ) {
                    warn "Remembering object / signal pair for later disconnection ...\n"
                        . " Field:  $fieldname\n"
                        . " Widget: $child_widget\n"
                        . " Signal: $signal\n\n";
                }
                push @{$self->{objects_and_signals}},
                [
                    $child_widget,
                    $signal
                ];
                
            } elsif ( $type eq "Gtk2::CheckButton" ) {
                
                push @signals, $widget->signal_connect_after(
                    toggled =>              sub { $self->changed( $fieldname ) } );
                
            } elsif ( $type eq "Gtk2::Entry" ) {
                
                push @signals, $widget->signal_connect_after(
                    changed =>              sub { $self->changed( $fieldname ) } );
                push @signals, $widget->signal_connect_after(
                    'populate-popup' =>     sub { $self->build_right_click_menu(@_) } );
                push @signals, $widget->signal_connect(
                    'activate' => sub { $self->{window}->child_focus('tab-forward') } );
                
            } elsif ( $type eq "Gtk2::SpinButton" ) {
                
                push @signals, $widget->signal_connect_after(
                    changed =>              sub { $self->changed( $fieldname ) } );
                push @signals, $widget->signal_connect_after(
                    'populate-popup' =>     sub { $self->build_right_click_menu(@_) } );
                push @signals, $widget->signal_connect(
                    'key-press-event' =>    sub { $self->process_entry_keypress(@_) } );
                
            } else {
                
                push @signals, $widget->signal_connect_after(
                    changed =>              sub { $self->changed( $fieldname ) } );
                
            }
            # ... and then warn() some info about what we're doing, and also append
            # the objects and signals to the *real* list
            foreach my $signal ( @signals ) {
                if ( $self->{debug} ) {
                    warn "Remembering object / signal pair for later disconnection ...\n"
                        . " Field:  $fieldname\n"
                        . " Widget: $widget\n"
                        . " Signal: $signal\n\n";
                }
                push @{$self->{objects_and_signals}},
                [
                    $widget,
                    $signal
                ];
            }
        }
    }
    
    $self->{spinner} = $self->get_widget( $self->{record_spinner} );
    
    if ( $self->{spinner} ) {
        
        $self->{record_spinner_value_changed_signal}
            = $self->{spinner}->signal_connect_after( value_changed => sub {
                        $self->{spinner}->signal_handler_block( $self->{record_spinner_value_changed_signal} );
                        $self->move( undef, $self->{spinner}->get_text - 1 );
                        $self->{spinner}->signal_handler_unblock( $self->{record_spinner_value_changed_signal} );
                        return TRUE;
                    }
              );
        
        push @{$self->{objects_and_signals}},
        [
            $self->{spinner},
            $self->{record_spinner_value_changed_signal}
        ];
        
    }
    
    # Check recordset status when window is destroyed
    push @{$self->{objects_and_signals}},
    [
        $self->{window},
        $self->{window}->signal_connect( delete_event   => sub {
            if ( $self->{changed} ) {
                my $answer = TRUE;
                if ( ! $self->{auto_apply} ) {
                    my $answer = Gtk2::Ex::Dialogs::Question->new_and_run(
                        title   => "Apply changes to " . $self->{friendly_table_name} . " before closing?",
                        icon    => "question",
                        text    => $self->{custom_changed_text} ? $self->{custom_changed_text} : 
                                            "There are changes to the current record ( " . $self->{friendly_table_name} . " )\n"
                                             . "that haven't yet been applied. Would you like to apply them before closing the form?"
                    );
                }
                # We return FALSE to allow the default signal handler to
                # continue with destroying the window - all we wanted to do was check
                # whether to apply records or not
                if ( $answer ) {
                    if ( $self->apply ) {
                        return FALSE;
                    } else {
                            # ie don't allow the form to close if there was an error applying
                        return TRUE;
                    }
                } else {
                    return FALSE;
                }
            }
        } )
    ];
    
    $self->{constructor_done} = TRUE;
    
    $self->set_record_spinner_range;
    
    if ( $self->{debug} ) {
        print " ... Gtk2::Ex::DBI version $Gtk2::Ex::DBI::VERSION successfully initialised.\n\n";
    }
    
    return $self;
    
}

sub destroy_signal_handlers {
    
    my $self = shift;
    
    foreach my $set ( @{$self->{objects_and_signals}} ) {
        if ( $self->{debug} ) {
            warn "Disconnecting object / signal pair:\n"
                . " Object: $$set[0]\n"
                . " Signal: $$set[1]\n";
        }
        $$set[0]->signal_handler_disconnect( $$set[1] );
        if ( $self->{debug} ) {
            warn "\n\n";
        }
    }
    
}

sub destroy_self {
    
    undef $_[0];
    
}

sub destroy {
    
    my $self = shift;
    
    $self->destroy_signal_handlers;
    $self->destroy_self;
    
}

sub fieldlist {
    
    # Provide legacy fieldlist method
    
    my $self = shift;
    
    return keys %{$self->{widgets}};
    
}

sub query {
    
    # Query / Re-query
    
    my ( $self, $where_object ) = @_;
    
    # In version 2.x, $where_object *should* be a hash, containing the keys:
    #  - where
    #  - bind_values
    
    # Update database from current hash if necessary
    if ( $self->{changed} ) {
        
        my $answer = TRUE;
        
        if ( ! $self->{auto_apply} ) {
            $answer = Gtk2::Ex::Dialogs::Question->ask(
                title   => "Apply changes to " . $self->{friendly_table_name} . " before querying?",
                icon    => "question",
                text    => "There are outstanding changes to the current record ( "
                            . $self->{friendly_table_name} . " )."
                            . " Do you want to apply them before running a new query?"
            );
        }
        
        if ( $answer ) {
            if ( ! $self->apply ) {
                return FALSE; # Apply method will already give a dialog explaining error
            }
        }
        
    }
    
    # Execute any before_query code
    if ( $self->{before_query} ) {
        if ( ! $self->{before_query}( $where_object ) ) {
            return FALSE;
        }
    }
    
    # If we're using a stored procedure, we don't keep a keyset - there's not much point.
    # We simply pull all records at once ... which we do now.
    # We can't wait for move() to call fetch_new_slice() because move() wants to know
    # how many records there are ( which usually comes from the keyset, which we're not fetching
    # here ). So anyway, we need to do the query here.
    
    my ( $query_start_time, $query_end_time );
    
    $query_start_time = Time::HiRes::gettimeofday;
    
    if ( exists $self->{sql}->{pass_through} ) {
        
        eval {
            $self->{records} = $self->{dbh}->selectall_arrayref (
                    $self->{sql}->{pass_through},   {Slice=>{}}
            ) || croak( "Error in SQL:\n\n" . $self->{sql}->{pass_through} );
        };
        
        if ( $@ ) {
            Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
                    title   => "Error in Query!",
                    icon    => "error",
                    text    => "<b>Database Server Says:</b>\n\n$@"
            );
            return FALSE;
        }
        
    } else {
        
        # Deal with legacy mode - the query method used to accept an optional where clause
        if ( $where_object ) {
            if ( ref( $where_object ) ne "HASH" ) {
                # Legacy mode
                # Strip 'where ' out of clause
                if ( $where_object ) {
                    $where_object =~ s/^where //i;
                }
                # Transfer new sql_where clause if defined
                $self->{sql}->{where} = $where_object;
                # Also remove any bound values if called in legacy mode
                $self->{sql}->{bind_values} = undef;
            } else {
                # NOT legacy mode
                if ( $where_object->{where} ) {
                    $self->{sql}->{where} = $where_object->{where};
                }
                if ( $where_object->{bind_values} ) {
                    $self->{sql}->{bind_values} = $where_object->{bind_values};
                }
            }
        }
        
        $self->{keyset_group} = undef;
        $self->{slice_position} = undef;
        
        # Get an array of primary keys
        my $sth;
        
        my $local_sql = "select " . join( ", ", @{$self->{primary_keys}} )
            . " from " . $self->{sql}->{from};
        
        # Add where clause if defined
        if ( $self->{sql}->{where} ) {
            $local_sql .= " where " . $self->{sql}->{where};
        }
        
        # Add order by clause of defined
        if ( $self->{sql}->{order_by} ) {
            $local_sql .= " order by " . $self->{sql}->{order_by};
        }
        
        eval {
            $sth = $self->{dbh}->prepare( $local_sql )
                || croak( $self->{dbh}->errstr );
        };
        
        if ( $@ ) {
            Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
                title   => "Error in Query!",
                icon    => "error",
                text    => "<b>Database Server Says:</b>\n\n$@"
            );
            if ( $self->{debug} ) {
                croak( "Gtk2::Ex::DBI::query died with the SQL:\n\n$local_sql\n" );
            }
            return FALSE;
        }
        
        eval {
            if ( $self->{sql}->{bind_values} ) {
                $sth->execute( @{$self->{sql}->{bind_values}} ) || croak( $self->{dbh}->errstr );
            } else {
                $sth->execute || croak( $self->{dbh}->errstr );
            }
        };
        
        if ( $@ ) {
            Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
                title   => "Error in Query!",
                icon    => "error",
                text    => "<b>Database Server Says:</b>\n\n$@"
            );
            if ( $self->{debug} ) {
                $sth->finish;
                croak( "Gtk2::Ex::DBI::query died with the SQL:\n\n$local_sql\n" );
            } else {
                return FALSE;
            }
        }
        
        $self->{keyset} = ();
        $self->{records} = ();
        
        while ( my @row = $sth->fetchrow_array ) {
            my $key_no = 0;
            my @keys;
            foreach my $primary_key ( @{$self->{primary_keys}} ) {
                push @keys, $row[$key_no];
                $key_no ++;
            }
            push @{$self->{keyset}}, @keys;   
        }
        
        $sth->finish;
        
    }
    
    $query_end_time = Time::HiRes::gettimeofday;
    
    $self->{query_execution_time} = $query_end_time - $query_start_time;
    
    $self->move( 0, 0 );
    
    $self->set_record_spinner_range;
    
    return TRUE;
    
}

sub insert {
    
    # Inserts a record at the end of the *in-memory* recordset.
    
    my $self = shift;
    my $newposition = $self->count; # No need to add one, as the array starts at zero.
    
    # Open RecordSpinner range
    if ( $self->{spinner} ) {
        $self->{spinner}->signal_handler_block( $self->{record_spinner_value_changed_signal} );
        $self->{spinner}->set_range( 1, $self->count + 1 );
        $self->{spinner}->signal_handler_unblock( $self->{record_spinner_value_changed_signal} );
    }
    
    if ( ! $self->move( 0, $newposition ) ) {
        warn "Insert failed ... probably because the current record couldn't be applied\n";
        return FALSE;
    }
    
    # Assemble new record and put it in place
    $self->{records}[$self->{slice_position}] = $self->assemble_new_record;
    
    # Finally, paint the current recordset onto the widgets
    # This is the 2nd time this is called in this sub ( 1st from $self->move ) but we need to do it again to paint the default values
    $self->paint;
    
    return TRUE;
    
}

sub assemble_new_record {
    
    # This sub assembles a new hash record and sets default values
    
    my $self = shift;
    
    my $new_record;
    
    # First, we create fields with default values from the database ...
    foreach my $fieldname ( keys %{$self->{column_info}} ) {
        # COLUMN_DEF is DBI speak for 'column default'
        my $default = $self->{column_info}->{$fieldname}->{COLUMN_DEF};
        if ( $default && $self->{server} =~ /microsoft/i ) {
            $default = $self->parse_sql_server_default( $default );
        }
        $new_record->{$fieldname} = $default;
    }
    
    # ... and then we set user-defined defaults
    foreach my $fieldname ( keys %{$self->{defaults}} ) {
        $new_record->{$fieldname} = $self->{defaults}->{$fieldname};
    }
    
    # Finally, set the 'inserting' flag ( but don't set the changed flag until the user actually changes something )
    $self->{inserting} = 1;
    
    return $new_record;
    
}

sub count {
    
    # Counts the records ( items in the keyset array ).
    # Note that this returns the REAL record count, and keep in mind that the first record is at position 0.
    
    my $self = shift;
    
    my $count_this;
    
    if ( exists $self->{sql}->{pass_through} ) {
        $count_this = "records";
    } else {
        $count_this = "keyset";
    }
    
    if ( ref($self->{$count_this}) eq "ARRAY" ) {
        return scalar @{$self->{$count_this}};
    } else {
        return 0;
    }
    
}

sub paint {
    
    my $self = shift;
    
    #carp( $self->{friendly_table_name} . " painting ..." );
    
    # Set the changelock so we don't trigger more changes
    $self->{changelock} = TRUE;
    
    foreach my $fieldname ( keys %{$self->{widgets}} ) {
        my $data = $self->{records}[$self->{slice_position}]->{$fieldname};
        $self->set_widget_value(
            $fieldname,
            $data
        );
    }
    
    # Paint calculated fields
    $self->paint_calculated;
    
    # Execute external on_current code
    # ( only if we have been constructed AND returned to calling code 1st - otherwise references to us won't work )
    if ( $self->{on_current} && $self->{constructor_done} ) {
        $self->{on_current}();
    }
    
    # Unlock the changelock
    $self->{changelock} = FALSE;
    
}

sub move {
    
    # Moves to the requested position, either as an offset from the current position,
    # or as an absolute value. If an absolute value is given, it overrides the offset.
    # If there are changes to the current record, these are applied to the Database Server first.
    # Returns TRUE ( 1 ) if successful, FALSE ( 0 ) if unsuccessful.
    
    my ( $self, $offset, $absolute ) = @_;
    
    # Update database from current hash if necessary
    if ( $self->{changed} ) {
        my $answer = TRUE;
        if ( ! $self->{auto_apply} ) {
            $answer = Gtk2::Ex::Dialogs::Question->ask(
                title   => "Apply changes to " . $self->{friendly_table_name} . " before moving?",
                icon    => "question",
                text    => "There are outstanding changes to the current record ( "
                            . $self->{friendly_table_name} . " )."
                            . " Do you want to apply them before moving to a different record?"
            );
        }
        if ( $answer ) {
            if ( ! $self->apply ) {
                # Update failed. If RecordSpinner exists, set it to the current position PLUS ONE.
                if ( $self->{spinner} ) {
                    $self->{spinner}->signal_handler_block( $self->{record_spinner_value_changed_signal});
                    $self->{spinner}->set_value( $self->position + 1 );
                    $self->{spinner}->signal_handler_block( $self->{record_spinner_value_changed_signal});
                }
                return FALSE;
            }
        } else {
            $self->{changed} = FALSE;
        }
    }
    
    my ( $new_keyset_group, $new_position);
    
    if ( defined $absolute ) {
        $new_position = $absolute;
    } else {
        $new_position = ( $self->position || 0 ) + $offset;
        # Make sure we loop around the recordset if we go out of bounds.
        if ( $new_position < 0 ) {
            $new_position = $self->count - 1;
        } elsif ( $new_position > $self->count - 1 ) {
            $new_position = 0;
        }
    }
    
    # Check if we now have a sane $new_position.
    # Some operations ( insert, then revert part-way through ... or move backwards when there are no records ) can cause this.
    if ( $new_position < 0 ) {
        $new_position = 0;
    }
    
    # Skip this bit for sps
    if ( ! exists $self->{sql}->{pass_through} ) {
        
        # Check if we need to roll to another slice of our recordset
        $new_keyset_group = int($new_position / $self->{apeture} );
        
        if (defined $self->{slice_position}) {
            if ( $self->{keyset_group} != $new_keyset_group ) {
                $self->{keyset_group} = $new_keyset_group;
                $self->fetch_new_slice;
            };
        } else {
            $self->{keyset_group} = $new_keyset_group;
            $self->fetch_new_slice;
        }
        
        $self->{slice_position} = $new_position - ( $new_keyset_group * $self->{apeture} );
        
    } else {
        
        $self->{slice_position} = $new_position;
        
    }
    
    if ( $self->{data_lock_field} ) {
        if ( $self->{records}[$self->{slice_position}]->{$self->{data_lock_field}} ) {
            $self->{data_lock} = TRUE;
        } else {
            $self->{data_lock} = FALSE;
        }
    }
    
    $self->record_status_label_set;
    
    $self->paint;
    
    # Set the RecordSpinner
    if ( $self->{spinner} ) {
        $self->{spinner}->signal_handler_block( $self->{record_spinner_value_changed_signal} );
        $self->{spinner}->set_value( $self->position + 1 );
        $self->{spinner}->signal_handler_unblock( $self->{record_spinner_value_changed_signal} );
    }
    
    return TRUE;
    
}

sub fetch_new_slice {
    
    # Fetches a new 'slice' of records ( based on the aperture size )
    
    my $self = shift;
    
    # Get max value for the loop ( not sure if putting a calculation inside the loop def slows it down or not )
    my $lower = $self->{keyset_group} * $self->{apeture};
    my $upper = ( ($self->{keyset_group} + 1) * $self->{apeture} ) - 1;
    
    # Don't try to fetch records that aren't there ( at the end of the recordset )
    my $keyset_count = $self->count; # So we don't keep running $self->count...
    
    if ( ( $keyset_count == 0 ) || ( $keyset_count == $lower ) ) {
        
        # If $keyset_count == 0 , then we don't have any records.
        
        # If $keyset_count == $lower, then the 1st position ( lower ) is actually out of bounds
        # because our keyset STARTS AT ZERO.
        
        # Either way, there are no records, so we're inserting ...
        
        # First, we have to delete anything in $self->{records}
        # This would *usually* just be overwritten if we actually got a keyset above,
        # but since we didn't, we have to make sure there's nothing left
        $self->{records} = ();
        
        # Now create a new record ( with defaults and insertion marker )
        
        # Note that we don't set the changed marker at this point, so if the user starts entering data,
        # this is treated as an inserted record. However if the user doesn't enter data, and does something else
        # ( eg another query ), this record will simply be discarded ( changed marker = 0 )
        
        # Keep in mind that this doens't take into account other requirements for a valid record ( eg foreign keys )
        push @{$self->{records}}, $self->assemble_new_record;
        
    } else {
        
        # Reset 'inserting' flag
        $self->{inserting} = 0;
        
        if ( $upper > $keyset_count - 1 ) {
        	$upper = $keyset_count - 1;
        }
        
        my $key_list;
        
        # Assemble query
        my $local_sql = "select " . $self->{sql}->{select};
        
        # Do we have an SQL wildcard ( * or % ) in the select string?
        if (  $self->{sql}->{select} !~ /[\*|%]/ ){
            # No? In that case, check we have the primary keys; append them if we don't - we need them
            $local_sql .= ", " . join( ', ', @{$self->{primary_keys}} );
        }
        
        $local_sql .= " from " . $self->{sql}->{from}
            . " where ( " . join( ', ', @{$self->{primary_keys}} ) . " ) in ( ";
        
        # The where clause we're trying to build should look like:
        #
        # where ( key_1, key_2, key_3 ) in
        # (
        #    ( 1, 5, 8 ),
        #    ( 2, 4, 9 )
        # )
        # ... etc ... assuming we have a primary key spanning 3 columns
        
        for ( my $counter = $lower; $counter < $upper+1; $counter++ ) {
            $local_sql .= " ( " . join( ",", $self->{keyset}[$counter] ) . " ),";
            #$key_list .= " " . $self->{keyset}[$counter] . ",";
        }
        
        # Chop off trailing comma
        chop( $local_sql );
        
        $local_sql .= " )";
        
        if ( $self->{sql}->{order_by} ) {
            $local_sql .= " order by " . $self->{sql}->{order_by};
        }
        
        eval {
            $self->{records} = $self->{dbh}->selectall_arrayref (
                $local_sql, {Slice=>{}}
            ) || croak( $self->{dbh}->errstr . "\n\nLocal SQL was:\n$local_sql" );
        };
        
        if ( $@ ) {
            Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
                title   => "Error fetching record slice!",
                icon    => "error",
                text    => "<b>Database server says:</b>\n\n" . $@
            );
            return FALSE;
        }
        
        return TRUE;
        
    }
    
}

sub apply {
    
    # Applys the data from the current form back to the Database Server.
    # Returns TRUE ( 1 ) if successful, FALSE ( 0 ) if unsuccessful.
    
    my $self = shift;
    
    if ( $self->{read_only} ) {
        Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
            title   => "Read Only!",
            icon    => "authentication",
            text    => "Sorry. This form is open\nin read-only mode!"
        );
        return FALSE;
    }
    
    if ( $self->{data_lock} && $self->{data_lock} == TRUE ) {
        Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
            title   => "Data Lock!",
            icon    => "authentication",
            text    => "Sorry. This record has been locked to prevent further changes!\n"
                            . "This usually occurs to ensure data integrity,\n"
                            . "or prevent unwanted editing"
        );
        return FALSE;
    }
    
    if ( $self->{before_apply} ) {
        if ( ! $self->{before_apply}() ) {
            return FALSE;
        }
    }
    
    my @fieldlist = ();
    my @bind_values = ();
    
    my $placeholders;  # We need to append to the placeholders while we're looping through fields, so we know how many fields we actually have
    
    foreach my $fieldname ( keys %{$self->{widgets}} ) {
        
        my $widget_definition = $self->{widgets}->{$fieldname};
        
        if ( $self->{debug} ) {
            print "Processing field $fieldname ...\n"
                . Dumper( $widget_definition ) . "\n";
        }
        
        # Support for aliases
        my $sql_fieldname = $widget_definition->{sql_fieldname} || $fieldname;
        
        if ( $self->{inserting} && $widget_definition->{dont_insert} ) {
            
            # ie if we're inserting and the current widget definition says we
            # shouldn't insert values into this field
            next;
            
        } elsif ( ! $self->{inserting} && $widget_definition->{dont_update} ) {
            
            # ie if we're updating and the current widget definition says we
            # shouldn't update values in this field
            next;
            
        }
        
#        # TODO Remove dodged-up multi-widget support
#        my $widget = $self->get_widget( $fieldname ) || $self->get_widget( $fieldname . "_" . "hh" );
#        
#        # TODO Document read-only labels
#        if ( defined $widget && ref $widget ne "Gtk2::Label" ) { # Labels are read-only
            push @fieldlist, $sql_fieldname;
            push @bind_values, $self->get_widget_value( $fieldname );
#        }
        
    }
    
    my $update_sql;
    
    if ( $self->{inserting} ) {
        
        $update_sql = "insert into " . $self->{sql}->{from} . " ( " . join( ",", @fieldlist, ) . " )"
            . " values ( " . "?," x ( @fieldlist - 1 ) . "? )";
        
    } else {
        
        $update_sql = "update " . $self->{sql}->{from} . " set " . join( "=?, ", @fieldlist ) . "=? where "
            . join( "=? and", @{$self->{primary_keys}} ) . "=?";
        
        foreach my $primary_key ( @{$self->{primary_keys}} ) {
            push @bind_values, $self->{records}[$self->{slice_position}]->{ $self->{sql_to_widget_map}->{$primary_key} };
        }
        
    }
    
    if ( $self->{debug} ) {
        print "Final SQL:\n\n$update_sql\n\n";
        
        my $counter = 0;
        
        for my $value ( @bind_values ) {
            no warnings 'uninitialized';
            print " " x ( 20 - length( $fieldlist[$counter] ) ) . $fieldlist[$counter] . ": $value\n";
            $counter ++;
        }
    }
    
    my $sth;
    
    # Evaluate the results of attempting to prepare the statement
    eval {
        $sth = $self->{dbh}->prepare( $update_sql )
            || die $self->{dbh}->errstr;
    };
    
    if ( $@ ) {
        Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
            title   => "Error preparing statement to update recordset!",
            icon    => "error",
            text    => "<b>Database server says:</b>\n\n$@"
        );
        carp( "Error preparing statement to update recordset:\n\n$update_sql\n\n@bind_values\n" . $@ );
    }
    
    # Evaluate the results of the update.
    my $affected_rows;
    eval {
        $affected_rows = $sth->execute( @bind_values ) || die $self->{dbh}->errstr;
    };
    
    if ( $self->{debug} ) {
        no warnings 'uninitialized';
        print "apply() affected [$affected_rows] rows";
    }
    
    if ( $@ ) {
        Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
            title   => "Error updating recordset!",
            icon    => "error",
            text    => "<b>Database server says:</b>\n\n" . $@
        );
        carp( "Error updating recordset:\n\n$update_sql\n\n@bind_values\n" . $@ . "\n" );
    }
    
    eval {
        $sth->finish;
    };
    
    # If this was an INSERT, we need to fetch the primary key value and apply it to the local slice,
    # and also append the primary key to the keyset
    
    if ( $self->{inserting} ) {
        
        if ( $self->{auto_incrementing} ) {
            
            # We only support a *single* primary key in the case of
            # an auto-incrementing setup. There shouldn't really
            # be any other options to cover ...
            
            my $new_key = $self->last_insert_id;
            my $primary_key = $self->{primary_keys}[0];
            
            $self->{records}[$self->{slice_position}]->{ $self->{sql_to_widget_map}->{$primary_key} } = $new_key;
            
            # Apply primary key to form ( if field exists )
            my $widget = $self->get_widget( $self->{sql_to_widget_map}->{$primary_key} );
            if ( $widget ) {
                $widget->set_text( $primary_key ); # Assuming the widget has a set_text method of course ... can't see when this wouldn't be the case
            }
            
        }
        
    }
    
    # SQL update successfull. Now apply update to local array.
    foreach my $fieldname ( keys %{$self->{widgets}} ) {
        my $widget = $self->get_widget( $fieldname );
        if ( defined $widget ) {
            $self->{records}[$self->{slice_position}]->{$fieldname} = $self->get_widget_value( $fieldname );
        }
    }
    
    if ( $self->{inserting} ) {
        
        # Note: For non-auto-incrementing primary keys, this MUST happen after we've copied values
        # from the GUI back to our in-memory slice ( ie immediately above )
        
        my @keys;
        
        foreach my $primary_key ( @{$self->{primary_keys}} ) {
            push @keys, $self->{records}[$self->{slice_position}]->{ $self->{sql_to_widget_map}->{$primary_key} };
        }
        
        push @{$self->{keyset}}, @keys;
        
        $self->{changelock} = FALSE;
        $self->set_record_spinner_range;
        $self->{changelock} = FALSE;
        
    }
    
    $self->{changed} = FALSE;
    
    $self->paint;
    
    # Execute external an_apply code
    if ( $self->{on_apply} ) {
        
        my $apply_info;
        
        foreach my $primary_key ( @{$self->{primary_keys}} ) {
            $apply_info->{primary_key} = $primary_key; # Legacy support. Single primary-key setups. DON'T break existing sane setups.
            $apply_info->{primary_keys}->{$primary_key} = $self->{records}[$self->{slice_position}]->{ $self->{sql_to_widget_map}->{$primary_key} };
        }
        
        if ( $self->{inserting} ) {
            $apply_info->{status} = "inserted";
        } else {
            $apply_info->{status} = "changed";
        }
        
        $self->{on_apply}($apply_info);
        
    }
    
    $self->record_status_label_set;
    
    $self->{inserting} = 0; # Reset this flag ( doesn't matter if we were inserting or not )
    
    return TRUE;
    
}

sub changed {
    
    # Sets the 'changed' flag, and update the RecordStatus indicator ( if there is one ).
    
    my ( $self, $fieldname ) = @_;
    
    if ( ! $self->{changelock} ) {
        
        if ( ! $self->{read_only} && ! $self->{data_lock} ) {
            
            if ( $self->{debug} ) {
                warn "Gtk2::Ex::DBI::changed triggered in object [" . $self->{friendly_table_name} . "] by field [$fieldname]\n";
            }
            
            my $recordstatus = $self->get_widget( $self->{status_label} );
            
            if ( $recordstatus ) {
                $recordstatus->set_markup( "<b><span color='"
                    . ( $Gtk2::Ex::DBI::highlight_colour ? $Gtk2::Ex::DBI::highlight_colour : "red" )
                    . "'>Changed</span></b>" );
            }
            
            if ( ! $self->{changed} ) {
                
                # If our changed flag is not already set, this is the 1st edit for this record
                # ( whether it's a new one or not )
                
                $self->{changed} = TRUE; # We need to set this now, otherwise recursion occurs
                
                # If we're inserting, scan for sequences
                if ( $self->{inserting} ) {
                    foreach my $widget_name ( keys %{$self->{widgets}} ) {
                        my $widget = $self->{widgets}->{$widget_name};
                        if ( exists $widget->{sequence_sql} ) {
                            my $sequence_dbh = exists $widget->{sequence_dbh} ? $widget->{sequence_dbh} : $self->{dbh};
                            my $sth;
                            eval {
                                $sth = $sequence_dbh->prepare( $widget->{sequence_sql} )
                                    || die $sequence_dbh->errstr;
                                $sth->execute()
                                    || die $sequence_dbh->errstr;
                            };
                            if ( $@ ) {
                                carp( "Failed to select the next sequence:\n$@" );
                                return FALSE;
                            }
                            if ( my @row = $sth->fetchrow_array ) {
                                $self->set_widget_value( $widget_name, $row[0] );
                            }
                        }
                    }
                }
            
                if ( $self->{on_initial_changed} ) {
                    # Execute on_initial_changed code ( only for the *initial* change of recordset status )
                    
                    if ( ! $self->{on_initial_changed}() ) {
                        $self->undo;
                        return FALSE;
                    }
                }
                
            }
            
            if ( $self->{on_changed} ) {
                # ... and also any on_changed code, which gets executed for EVERY change in data
                # ... ( ie not recordset status )
                $self->{on_changed}();
            }
            
        }
        
        $self->paint_calculated;
        
    }
    
    return FALSE; # Have to do this otherwise other signal handlers won't be fired
    
}

sub record_status_label_set {
    
    # This function is called from move() and apply()
    # It will set the record status label to either:
    #  - Synchronized, or
    #  - Locked
    
    my $self = shift;
    
    my $recordstatus = $self->get_widget( $self->{status_label} );
    
    if ( $recordstatus ) {
        if ( $self->{data_lock} ) {
            $recordstatus->set_markup( "<b><i><span color='"
                . ( $Gtk2::Ex::DBI::highlight_colour ? $Gtk2::Ex::DBI::highlight_colour : "red" )
                . "'>Locked</span></i></b>" );
        } else {
            $recordstatus->set_markup( "<b><span color='"
                . ( $Gtk2::Ex::DBI::highlight_ok_colour ? $Gtk2::Ex::DBI::highlight_ok_colour : "blue" )
                . "'>Synchronized</span></b>" );
        }
    }
    
}

sub paint_calculated {
    
    # Paints calculated fields. If a field is passed, only that one gets calculated. Otherwise they all do.
    
    my ( $self, $field_to_paint ) = @_;
    
    foreach my $fieldname ( $field_to_paint || keys %{$self->{calc_fields}} ) {
        my $widget = $self->get_widget($fieldname);
        my $calc_value = eval $self->{calc_fields}->{$fieldname};
        if ( ! defined $widget ) {
            if ( ! $self->{quiet} ) {
                warn "*** Calculated Field $fieldname is missing a widget! ***\n";
            }
        } else {
            if ( ref $widget eq "Gtk2::Entry" || ref $widget eq "Gtk2::Label" ) {
                $self->{changelock} = TRUE;
                $widget->set_text( $calc_value || 0 );
                $self->{changelock} = FALSE;
            } else {
                warn "FIXME: Unknown widget type in Gtk2::Ex::DBI::paint_calculated: " . ref $widget . "\n";
            }
        }
    }
    
}

sub revert {
    
    # Reverts the form to the state of the in-memory recordset ( or deletes the in-memory record if we're adding a record )
    
    my $self = shift;
    
    if ( $self->{inserting} ) {
        # We're insering. Drop record and roll back one
        my $garbage_record = pop @{$self->{records}};
        $self->{changed} = FALSE;
        $self->{inserting} = 0;
        # Force a new slice to be fetched when we move(), which in turn deals with possible problems
        # if there are no records ( ie we want to set the 'inserting' flag if there are no records )
        $self->{keyset_group} = -1;
        $self->move( -1 );
    } else {
        # Existing record
        $self->{changed} = FALSE;
        $self->move( 0 );
    }
    
    $self->set_record_spinner_range;
    
    if ( $self->{on_undo} ) {
        $self->{on_undo}();
    }
    
}

sub undo {
    
    # undo is a synonym of revert
    
    my $self = shift;
    
    $self->revert;
    
}

sub delete {
    
    # Deletes the current record from the Database Server and from memory
    
    my $self = shift;
    
    my $sth = $self->{dbh}->prepare( "delete from " . $self->{sql}->{from} . " where "
        . join( "=? and", @{$self->{primary_keys}} ) . "=?" );
    
    my @bind_values;
    
    foreach my $primary_key ( @{$self->{primary_keys}} ) {
        push @bind_values, $self->{records}[$self->{slice_position}]->{ $self->{sql_to_widget_map}->{$primary_key} };
    }
    
    eval {
        $sth->execute( @bind_values )
            || die $self->{dbh}->errstr;
    };
    
    if ( $@ ) {
        Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
            title   => "Error Deleting Record!",
            icon    => "error",
            text    => "<b>Database Server Says:</b>\n\n$@"
        );
        $sth->finish;
        return FALSE;
    }
    
    $sth->finish;
    
    # Cancel any updates ( if the user changed something before pressing delete )
    $self->{changed} = FALSE;
    
    # First remove the record from the keyset
    splice( @{$self->{keyset}}, $self->position, 1) ;
    
    # Force a new slice to be fetched when we move(), which in turn handles with possible problems
    # if there are no records ( ie we want to set the 'inserting' flag if there are no records )
    $self->{keyset_group} = -1;
    
    # Moving forwards will give problems if we're at the end of the keyset, so we move backwards instead
    # If we're already at the start, move() will deal with this gracefully
    $self->move( -1 );
    
    $self->set_record_spinner_range;
    
}

sub lock {
    
    # Locks the current record from further edits
    
    my $self = shift;
    
    if ( ! $self->{data_lock_field} ) {
        croak( "\nGtk2::Ex::DBI::lock called without having a data_lock_field defined!\n" );
    }
    
    # Apply the current record first
    if ( ! $self->apply ) {
        Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
            title   => "Failed to lock record!",
            icon    => "authentication",
            text    => "There was an error applying the current record.\n"
                            . "The lock operation has been aborted."
        );
        return FALSE;
    }
    
    # Set the lock field
    $self->set_widget_value( $self->{data_lock_field}, 1 );
    
    # Apply it ( which will implement the lock )
    if ( ! $self->apply ) {
        Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
            title   => "Failed to lock record!",
            icon    => "authentication",
            text    => "There was an error applying the current record.\n"
                            . "The lock operation has been aborted."
        );
        $self->revert; # Removes our changes to the lock field
        return FALSE;
    }
    
    $self->{data_lock} = TRUE;
    
    return TRUE;
    
}

sub unlock {
    
    # Unlocks the current record
    
    my $self = shift;
    
    if ( ! $self->{data_lock_field} ) {
        croak( "\nGtk2::Ex::DBI::unlock called without having a data_lock_field defined!\n" );
    }
    
    # Have to force this off, otherwise apply() method will fail
    $self->{data_lock} = FALSE;
    
    # Unset the lock field
    $self->set_widget_value( $self->{data_lock_field}, 0 );
    
    if ( ! $self->apply ) {
        Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
            title   => "Failed to unlock record!",
            icon    => "authentication",
            text    => "There was an error applying the current record.\n"
                            . "The unlock operation has been aborted."
        );
        $self->revert; # Removes our changes to the lock field
        return FALSE;
    }
    
    return TRUE;
    
}

sub position {
    
    # Returns the absolute position ( starting at 0 ) in the recordset ( taking into account the keyset and slice positions )
    
    my $self = shift;
    return ( $self->{keyset_group} * $self->{apeture} ) + $self->{slice_position};
    
}

sub set_record_spinner_range {
    
    # Convenience function that sets the min / max value of the record spinner
    
    my $self = shift;
    
    if ( $self->{spinner} ) {
        $self->{spinner}->signal_handler_block( $self->{record_spinner_value_changed_signal} );
        $self->{spinner}->set_range( 1, $self->count );
        $self->{spinner}->signal_handler_unblock( $self->{record_spinner_value_changed_signal} );
    }
    
    return TRUE;
    
}

sub setup_combo {
    
    # Convenience function that creates / refreshes a combo's model & sets up autocompletion
    
    my ( $self, $combo_name, $new_where_object ) = @_;
    
    my $combo = $self->{combos}->{$combo_name};
    
    # Remember the current value.
    # After setting up the model, we then try to select this value in the new model
    my $previous_value;
    
    if ( $self->{constructor_done} ) {
        $previous_value = $self->get_widget_value( $combo_name );
    } 
    
    # Transfer new where object if one is passed
    if ( $new_where_object ) {
        $combo->{sql}->{where_object} = $new_where_object;
    }
    
    # Deal with legacy bind_variables key
    if ( exists $combo->{sql}->{where_object} && exists $combo->{sql}->{where_object}->{bind_variables} ) {
        if ( $self->{debug} ) {
            carp( "Gtk2::Ex::DBI::setup_combo called with a legacy bind_variables key!\n" );
        }
        $combo->{sql}->{where_object}->{bind_values} = $combo->{sql}->{where_object}->{bind_variables};
        delete $combo->{sql}->{where_object}->{bind_variables};
    }
    
    # First we clone a database connection - in case we're dealing with SQL Server here ...
    #  ... SQL Server doesn't like it if you do too many things ( > 1 ) with one connection :)
    my $local_dbh;
    
    if ( exists $combo->{alternate_dbh} ) {
        $local_dbh = $combo->{alternate_dbh}->clone;
    } else {
        $local_dbh = $self->{dbh}->clone;
    }
    
    my $widget = $self->get_widget( $combo_name ) || 0;
    
    if ( ! $widget ) {
        warn "\n" . $self->{friendly_table_name} . " missing combo widget: $combo_name\n";
        return FALSE;
    }
    
    if ( ! $combo->{sql} ) {
        warn "\nMissing an SQL object in the combo definition for $combo_name!\n\n";
        return FALSE;
    } elsif ( ! $combo->{sql}->{from} ) {
        warn "\nMissing the 'from' key in the sql object in the combo definition for $combo_name!\n\n";
        return FALSE;
    }
    
    # Support using an SQL select string *instead* of an array of field definitions
    if ( exists $combo->{sql}->{select} && ! exists $combo->{fields} ) {
        
        # In this case, we clobber whatever was in the array of field definitions
        # ( if there was anything ) and construct our own ...
        
        $combo->{fields} = ();
        
        #  ... and screw supporing aliases and other stuff
        my @fields = split /\,/, $combo->{sql}->{select};
        
        foreach my $field ( @fields ) {
            push @{$combo->{fields}},
                {
                    name    => $field,
                    type    => "Glib::String" # TODO Detect type from database? Factor out detection from constructor?
                };
        }
        
    }
    
    # Assemble items for liststore and SQL to get the data
    my ( @liststore_def, $sql );
    
    $sql = "select";
    
    my $column_no = 0;
    
    foreach my $field ( @{$combo->{fields}} ) {
        
        push @liststore_def, $field->{type}; # TODO automatically select type based on column_info from DB server
        $sql .= " $field->{name},";
        
        # Add additional renderers for columns if defined
        # We only want to do this the 1st time ( renderers_setup flag ), otherwise we get lots of renderers 
        if ( $column_no > 1 && ! $combo->{renderers_setup} ) {
            
            my $renderer = Gtk2::CellRendererText->new;
            $widget->pack_start( $renderer, FALSE );
            $widget->set_attributes( $renderer, text => $column_no );
            
            # Set up custom cell data func if defined
            if ( exists $field->{cell_data_func} ) {
                $widget->set_cell_data_func( $renderer, sub { $field->{cell_data_func}( @_ ) } );
            }
            
        }
        
        $column_no ++;
        
    }
    
    $combo->{renderers_setup} = TRUE;
    
    chop( $sql );
    
    $sql .= " from $combo->{sql}->{from}";
    
    if ( $combo->{sql}->{where_object} ) {
        if ( ! $combo->{sql}->{where_object}->{bind_values} && ! $self->{quiet} ) {
            warn "\n* * * Gtk2::Ex::DBI::setup_combo called with a where clause but *WITHOUT* an array of values to bind!\n"
                . "* * * While this method is supported, it is a security hazard. *PLEASE* take advantage of our support of bind values\n\n";
        }
        $sql .= " where $combo->{sql}->{where_object}->{where}";
    }
    
    if ( $combo->{sql}->{group_by} ) {
        $sql .= " group by $combo->{sql}->{group_by}";
    }
    
    if ( $combo->{sql}->{order_by} ) {
        $sql .= " order by $combo->{sql}->{order_by}";
    }
    
    my $sth;
    
    eval {
        $sth = $local_dbh->prepare( $sql )
            || die $local_dbh->errstr;
    };
    
    if ( $@ ) {
        Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
            title   => "Error setting up combo box: $combo_name",
            icon    => "error",
            text    => "<b>Database Server Says:</b>\n\n$@"
        );
        if ( $self->{debug} ) {
            warn "\n$sql\n";
        }
        return FALSE;
    }
    
    # We have to use 'exists' here, otherwise we inadvertently create the where_object hash,
    # just by testing for it ... ( or by testing for bind_variables anyway )
    if ( exists $combo->{sql}->{where_object} && exists $combo->{sql}->{where_object}->{bind_values} ) {
        eval {
            $sth->execute( @{$combo->{sql}->{where_object}->{bind_values}} )
                || die $local_dbh->errstr;
        };
    } else {
        eval {
            $sth->execute || die $local_dbh->errstr;
        };
    }
    
    if ( $@ ) {
        Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
            title   => "Error setting up combo box: $combo_name",
            icon    => "error",
            text    => "<b>Database Server Says:</b>\n\n$@\n\n"
                        . "Check the definintion of the table: $combo->{sql}->{from}"
        );
        return FALSE;
    }
    
    # Create the model
    my $model = Gtk2::ListStore->new( @liststore_def );
    
    while ( my @row = $sth->fetchrow_array ) {
        
        # We use fetchrow_array instead of fetchrow_hashref so
        # we can support the use of aliases in the fields
        
        my @model_row;
        my $column = 0;
        push @model_row, $model->append;
        
        foreach my $field ( @{$combo->{fields}} ) {
            push @model_row, $column, $row[$column];
            $column ++;
        }
        
        $model->set( @model_row );
        
    }
    
    $sth->finish;
    $local_dbh->disconnect;
    
    # Connect the model to the widget
    $widget->set_model( $model );
    
    if ( ref $widget eq "Gtk2::ComboBoxEntry" ) {
        
        # We can only call $combo->set_text_column *once* per combo, so we
        # have to remember when we've set it up
        if ( ! $self->{combos_set}->{$combo_name} ) {
            $widget->set_text_column( 1 );
            $self->{combos_set}->{$combo_name} = TRUE;
        }
        
        # Set up autocompletion in the Combo's entry
        my $entrycompletion = Gtk2::EntryCompletion->new;
        $entrycompletion->set_minimum_key_length( 1 );
        $entrycompletion->set_model( $model );
        $entrycompletion->set_text_column( 1 );
        $widget->get_child->set_completion( $entrycompletion );
        
    }
    
    # Finally select the previous value in the new model
    if ( $self->{constructor_done} ) {
        my $changelock_status = $self->{changelock}; # Remember the state of the changelock
        $self->{changelock} = TRUE;
        $self->set_widget_value( $combo_name, $previous_value );
        $self->{changelock} = $changelock_status;
    }
    
    return TRUE;
    
}

sub setup_autocompletion {
    
    # Convenience function that creates / refreshes a combo's model & sets up autocompletion
    
    my ( $self, $autocompletion_name, $new_where_object ) = @_;
    
    my $autocompletion = $self->{autocompletions}->{$autocompletion_name};
    
    # Transfer new where object if one is passed
    if ( $new_where_object ) {
        $autocompletion->{sql}->{where_object} = $new_where_object;
    }
    
    # First we clone a database connection - in case we're dealing with SQL Server here ...
    #  ... SQL Server doesn't like it if you do too many things ( > 1 ) with one connection :)
    my $local_dbh;
    
    if ( exists $autocompletion->{alternate_dbh} ) {
        $local_dbh = $autocompletion->{alternate_dbh}->clone;
    } else {
        $local_dbh = $self->{dbh}->clone;
    }
    
    my $widget = $self->get_widget( $autocompletion_name ) || 0;
    
    if ( ! $widget ) {
        warn "\n" . $self->{friendly_table_name} . " missing autocompletion widget: $autocompletion_name\n";
        return FALSE;
    }
    
    if ( ! $autocompletion->{sql} ) {
        warn "\nMissing an SQL object in the combo definition for $autocompletion_name!\n\n";
        return FALSE;
    } elsif ( ! $autocompletion->{sql}->{from} ) {
        warn "\nMissing the 'from' key in the sql object in the autocompletion definition for $autocompletion_name!\n\n";
        return FALSE;
    }
    
    # Support using an SQL select string *instead* of an array of field definitions
    if ( exists $autocompletion->{sql}->{select} && ! exists $autocompletion->{fields} ) {
        
        # In this case, we clobber whatever was in the array of field definitions
        # ( if there was anything ) and construct our own ...
        
        $autocompletion->{fields} = ();
        
        #  ... and screw supporing aliases and other stuff
        my @fields = split /\,/, $autocompletion->{sql}->{select};
        
        foreach my $field ( @fields ) {
            push @{$autocompletion->{fields}},
                {
                    name    => $field,
                    type    => "Glib::String" # TODO Detect type from database? Factor out detection from constructor?
                };
        }
        
    }
    
    # Assemble items for liststore and SQL to get the data
    my ( @liststore_def, $sql );
    
    $sql = "select";
    
    my $column_no = 0;
    
    foreach my $field ( @{$autocompletion->{fields}} ) {
        
        push @liststore_def, $field->{type}; # TODO automatically select type based on column_info from DB server
        $sql .= " $field->{name},";
        
        $column_no ++;
        
    }
    
    chop( $sql );
    
    $sql .= " from " . $autocompletion->{sql}->{from};
    
    if ( $autocompletion->{sql}->{where_object} ) {
        if ( ! $autocompletion->{sql}->{where_object}->{bind_values} && ! $self->{quiet} ) {
            warn "\n* * * Gtk2::Ex::DBI::setup_combo called with a where clause but *WITHOUT* an array of values to bind!\n"
                . "* * * While this method is supported, it is a security hazard. *PLEASE* take advantage of our support of bind values\n\n";
        }
        $sql .= " where $autocompletion->{sql}->{where_object}->{where}";
    }
    
    if ( $autocompletion->{sql}->{group_by} ) {
        $sql .= " group by " . $autocompletion->{sql}->{group_by};
    }
    
    if ( $autocompletion->{sql}->{order_by} ) {
        $sql .= " order by " . $autocompletion->{sql}->{order_by};
    }
    
    my $sth;
    
    eval {
        $sth = $local_dbh->prepare( $sql )
            || die $local_dbh->errstr;
    };
    
    if ( $@ ) {
        Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
            title   => "Error setting up combo box: $autocompletion_name",
            icon    => "error",
            text    => "<b>Database Server Says:</b>\n\n$@"
        );
        if ( $self->{debug} ) {
            warn "\n$sql\n";
        }
        return FALSE;
    }
    
    # We have to use 'exists' here, otherwise we inadvertently create the where_object hash,
    # just by testing for it ... ( or by testing for bind_variables anyway )
    if ( exists $autocompletion->{sql}->{where_object} && exists $autocompletion->{sql}->{where_object}->{bind_values} ) {
        eval {
            $sth->execute( @{$autocompletion->{sql}->{where_object}->{bind_values}} )
                || die $local_dbh->errstr;
        };
    } else {
        eval {
            $sth->execute || die $local_dbh->errstr;
        };
    }
    
    if ( $@ ) {
        Gtk2::Ex::Dialogs::ErrorMsg->new_and_run(
            title   => "Error setting up combo box: $autocompletion_name",
            icon    => "error",
            text    => "<b>Database Server Says:</b>\n\n$@\n\n"
                        . "Check the definintion of the table: " . $autocompletion->{sql}->{from}
        );
        return FALSE;
    }
    
    # Create the model
    my $model = Gtk2::ListStore->new( @liststore_def );
    
    while ( my @row = $sth->fetchrow_array ) {
        
        # We use fetchrow_array instead of fetchrow_hashref so
        # we can support the use of aliases in the fields
        
        my @model_row;
        my $column = 0;
        push @model_row, $model->append;
        
        foreach my $field ( @{$autocompletion->{fields}} ) {
            push @model_row, $column, $row[$column];
            $column ++;
        }
        
        $model->set( @model_row );
        
    }
    
    $sth->finish;
    $local_dbh->disconnect;
    
    # Set up autocompletion in the Combo's entry
    my $entrycompletion = Gtk2::EntryCompletion->new;
    $entrycompletion->set_minimum_key_length( 0 );
    $entrycompletion->set_model( $model );
    $entrycompletion->set_text_column( 1 );
    $widget->set_completion( $entrycompletion );
    
    return TRUE;
    
}

sub get_widget {
	
    # Returns a given widget, whether from a Gtk2::GladeXML object,
    # or a Gtk2::Builder object
    
    my ( $self, $widget_name ) = @_;
    
    if ( exists $self->{form} && ref $self->{form} eq "Gtk2::GladeXML" ) {
    	
        my $widget = $self->{form}->get_widget( $widget_name );
        
        if ( ! $widget && $self->{widget_prefix} ) {
            $widget = $self->{form}->get_widget( $self->{widget_prefix} . $widget_name );
        }
        
        return $widget;
        
    } elsif ( exists $self->{builder} && ref $self->{builder} eq "Gtk2::Builder" ) {
        
        my $widget = $self->{form}->get_object( $widget_name );
        
        if ( ! $widget && $self->{widget_prefix} ) {
            $widget = $self->{form}->get_object( $self->{widget_prefix} . $widget_name );
        } 
        
        return $widget;
        
    } else {
        
        carp( "get_widget() called but we don't have a form ( Gtk2::GladeXML ) or builder ( Gtk2::Builder ) object available" );
        return undef;
        
    }
    
}

sub get_widget_value {
    
    # Returns the *current* value of the given *widget*
    
    my ( $self, $fieldname ) = @_;
    
    my $widget = $self->get_widget( $fieldname );
    
    if ( ! $widget ) {
        
        # No widget by this name. Check for split-widget widgets ( currently TimeSpinners )
        # At the moment, we only check for the presence of a $field_hh - named field
        
        # TODO Remove this bullshit. We need to create a custom widget for Time
        
        my $hh_test = $self->get_widget( $fieldname . "_hh" );
        my $time_value;
        if ( $hh_test ) {
            foreach my $type qw / hh mm ss / {
                $time_value .= sprintf( "%02d", $self->get_widget_value( $fieldname . "_" . $type ) || 0 )  . ":";
            }
            chop ( $time_value );
            if ( $time_value eq "00:00:00" ) {
                $time_value = undef;
            }
            return $time_value;
        } else {
            carp( "\nGtk2::Ex::DBI::get_widget_value called on non-existant field: $fieldname!" );
            return undef;
        }
        
    }
    
    my $type = ref $widget;
    
    my $value;
    
    if ( $type eq "Gtk2::Calendar" ) {
        
        my ( $year, $month, $day ) = $widget->get_date;
        my $date;
        
        if ( $day > 0 ) {
            
            # NOTE! NOTE! Apparently GtkCalendar has the months starting at ZERO!
            # Therefore, add one to the month...
            $month ++;
            
            # Pad the $month and $day values
            $month = sprintf( "%02d", $month );
            $day = sprintf( "%02d", $day );
            
            $date = $year . "-" . $month . "-" . $day;
            
        } else {
            $date = undef;
        }
        
        $value = $date;
        
        
    } elsif ( $type eq "Gtk2::ToggleButton" ) {
        
        if ( $widget->get_active ) {
            $value = 1;
        } else {
            $value = 0;
        }
        
    } elsif ( $type eq "Gtk2::ComboBoxEntry" || $type eq "Gtk2::ComboBox" ) {
        
        my $iter = $widget->get_active_iter;
        
        # If $iter is defined ( ie something is selected ), push the ID of the selected row
        # onto @bind_values,  otherwise test the column type.
        # If we find a "Glib::Int" column type, we push a zero onto @bind_values otherwise 'undef'
        
        if ( defined $iter ) {
            $value = $widget->get_model->get( $iter, 0 );
        } else {
            my $columntype = $widget->get_model->get_column_type( 0 );
            if ( $columntype eq "Glib::Int" ) {
                $value = 0;
            } else {
                $value = undef;
            }
        }
        
    } elsif ( $type eq "Gtk2::TextView" ) {
        
        my $textbuffer = $widget->get_buffer;
        my ( $start_iter, $end_iter ) = $textbuffer->get_bounds;
        $value = $textbuffer->get_text( $start_iter, $end_iter, 1 );
        
    } elsif ( $type eq "Gtk2::CheckButton" ) {
        
        if ( $widget->get_active ) {
            $value = 1;
        } else {
            $value = 0;
        }
        
    } else {
        
        my $txt_value = $widget->get_text;
        
        if ( $txt_value || $txt_value eq "0" ) { # Don't push an undef value just because our field has a zero in it
            $value = $txt_value;
        } else {
            $value = undef;
        }
        
    }
    
    # To allow us to use get_widget_value on non-managed fields, we have to be careful we don't
    # accidentally add the widget name to our widgets hash, or the widget will end up being included
    # in SQL commands
    
    if ( exists $self->{widgets}->{ $fieldname } ) {
        
        my $widget_def = $self->{widgets}->{$fieldname};
        
        foreach my $item ( keys %{$widget_def}) {
    		
    	    # Possible values are:
    	    # - sql_fieldname	- ( not related to formatting )
    	    # - number 			- a hash describing numeric formatting
    	    # - date			- a hash describing date formatting
    	    
    	    if ( $item        eq "number" ) {
    	        $value        = $self->formatter_number_from_widget( $value, $widget_def->{number} );
    	    } elsif ( $item   eq "date" ) {
    	        $value        = $self->formatter_date_from_widget( $value, $widget_def->{date} );
    	    }
    	    
        }
        
    }
    
    return $value;
    
}

sub set_widget_value {
    
    # Sets a widget to a given value
    
    my ( $self, $fieldname, $value ) = @_;
    
    my $widget = $self->get_widget( $fieldname );
    
    my $local_value = $value;
    
    # To allow us to use set_widget_value on non-managed fields, we have to be careful we don't
    # accidentally add the widget name to our widgets hash, or the widget will end up being included
    # in SQL commands
    
    if ( exists $self->{widgets}->{$fieldname} ) {
    	
    	my $widget_def = $self->{widgets}->{$fieldname};
    	
    	foreach my $item ( keys %{$widget_def}) {
    	    
    	    if ( $item          eq "number" ) {
    	        $local_value    = $self->formatter_number_to_widget( $local_value, $widget_def->{number} );
    	    } elsif ( $item     eq "date" ) {
    	        $local_value    = $self->formatter_date_to_widget( $local_value, $widget_def->{date} );
    	    }
    	    
        }
        
    }
    
    if ( ! $widget ) {
        
        # Check for split-widget widgets ( currently TimeSpinners )
        # At the moment, we only check for the presence of a $field_hh - named field
        
        # TODO Remove this bullshit. We need to create a custom widget for Time
        
        my $hh_test = $self->get_widget( $fieldname . "_hh" );
        my $time_value;
        if ( $hh_test ) {
            # Found an hour widget. Split time into 3 values and apply
            my @hhmmss;
            if ( $local_value ) {
                @hhmmss = split /:/, $local_value;
            } else {
                @hhmmss = ( 0, 0, 0 );
            }
            my $counter = 0;
            foreach my $type qw / hh mm ss / {
                $self->set_widget_value( $fieldname . "_" . $type, $hhmmss[$counter] || 0 );
                $counter ++;
            }
        } elsif ( ! $self->{quiet} && $fieldname ne $self->{primary_key} ) {
            # We don't warn on a missing primary key *widget*, as this is perfectly safe
            # ( updates use the in-memory primary key )
            carp( "Field $fieldname is missing a widget" );
            return FALSE;
        }
        
    }
    
    
    my $type = ( ref $widget );
    
    if ( $type eq "Gtk2::Calendar" ) {
        
        if ( $local_value ) {
            
            my $year = substr( $local_value, 0, 4 );
            my $month = substr( $local_value, 5, 2 );
            my $day = substr( $local_value, 8, 2 );
            
            # Months start at zero ...
            $month --;
            
            if ( $month != -1 ) {
                if ( $self->{debug} ) {
                    warn "Setting Day: $day, Month: $month, Year: $year"
                }
                $widget->select_month( $month, $year );
                $widget->select_day( $day );
            } else {
                # Select the current month / year
                ( $month, $year ) = (localtime())[4, 5];
                $year += 1900;
                $widget->select_month( $month, $year );
                # But de-select the day
                $widget->select_day( 0 );
            }
            
        } else {
            # Select the current month / year
            my ( $month, $year ) = (localtime())[4, 5];
            $year += 1900;
            $widget->select_month( $month, $year );
            $widget->select_day( 0 );
        }
        
    } elsif ( $type eq "Gtk2::ToggleButton" ) {
        
        $widget->set_active( $local_value );
        
    } elsif ( $type eq "Gtk2::ComboBoxEntry" || $type eq "Gtk2::ComboBox" || $type eq "Gtk2::Combo" ) {
        
        # This is some ugly stuff. Gtk2 doesn't support selecting an iter in a model based on the string
        
        # See http://bugzilla.gnome.org/show_bug.cgi?id=149248
        
        # TODO Broken Gtk2 combo box entry workaround
        # If we can't get above bug resolved, perhaps load the ID / value pairs into something
        # that supports rapid searching so we don't have to loop through the entire list, which
        # could be *very* slow if the list is large
        
        # Check to see whether this combo has a model
        my $model = $widget->get_model;
        
        if ( ! $model ) {
            carp( "Field $fieldname has a matching combo, but there is no model attached!\n"
                    . "    You MUST set up all your combo's models before creating a Gtk2::Ex::DBI object" );
            return FALSE;
        }
        
        my $iter = $model->get_iter_first;
        
        if ( $type eq "Gtk2::ComboBoxEntry" ) {
            $widget->get_child->set_text( "" );
        }
        
        my $match_found = FALSE;
        
        while ( $iter ) {
            if ( ( defined $local_value ) &&
                ( $local_value eq $model->get( $iter, 0 ) ) ) {
                    $match_found = TRUE;
                    $widget->set_active_iter( $iter );
                    last;
            }
            $iter = $model->iter_next( $iter );
        } 
        
        # There's only really a need to warn if we've actually been passed a value, because
        # if we've been passed a 0 or undef, we de-select the combo, and this will return a zero
        # when we call $self->get_widget_value() anyway, so this is as good as finding a match
         
        if ( ! $match_found && $value ) {
            carp( "Failed to set $fieldname to value $value\n ( wasn't in the model )" );
        }
        
    } elsif ( $type eq "Gtk2::TextView" ) {
        
        $widget->get_buffer->set_text( $local_value || "" );
        
    } elsif ( $type eq "Gtk2::CheckButton" ) {
        
        $widget->set_active( $local_value );
        
    } elsif ( $type eq "Gtk2::SpinButton" ) {
        
        $widget->set_value( $local_value || 0 );
        
    } else {
        
        # Assume everything else has a 'set_text' method. Add more types if necessary...
        $widget->set_text( defined $local_value ? $local_value : "" );
        
    }
    
    return TRUE;
    
}

sub sum_widgets {
    
    # Return the sum of all given fields ( they don't have to be fields we manage; just on the same form )
    
    my ( $self, $fields ) = @_;
    
    my $total;
    
    if ( $self->{debug} ) {
        print "\n\nGtk2::Ex::DBI::sum_widgets calling Gtk2::Ex::DBI::get_widget_value ... ... ...\n";
    }
    
    foreach my $fieldname ( @{$fields} ) {
        $total += $self->get_widget_value( $fieldname ) || 0;
    }
    
    if ( $self->{debug} ) {
        print "\nGtk2::Ex::DBI::sum_widgets final value: $total\n\n";
    }
    
    return $total;
    
}

sub original_value {
    
    my ( $self, $fieldname ) = @_;
    
    return $self->{records}[$self->{slice_position}]->{$fieldname};
    
}

sub set_active_iter_for_broken_combo_box {
    
    # This function is called when a ComboBoxEntry's value is changed
    # See http://bugzilla.gnome.org/show_bug.cgi?id=156017
    
    my ( $self, $widget ) = @_;
    
    my $string = $widget->get_child->get_text;
    my $model = $widget->get_model;
    
    if ( ! $model ) {
        return FALSE;
    }
    
    my $current_iter = $widget->get_active_iter;
    my $iter = $model->get_iter_first;
    
    while ( $iter ) {
        if ( $string eq $model->get( $iter, 1 ) ) {
            $widget->set_active_iter( $iter );
            if ( ! $current_iter || $iter != $current_iter ) {
                $self->changed;
            }
            last;
        }
        $iter = $model->iter_next( $iter );
    }
    
    return FALSE; # Apparently we must return FALSE so the entry gets the event as well
    
}

sub last_insert_id {
    
    my $self = shift;
    
    my $primary_key;
    
    if ( $self->{server} =~ /postgres/i ) {
        
        # Postgres drivers support DBI's last_insert_id()
        
        $primary_key = $self->{dbh}->last_insert_id (
            undef,
            $self->{schema},
            $self->{sql}->{from},
            undef
        );
        
    } elsif ( lc($self->{server}) eq "sqlite" ) {
        
        $primary_key = $self->{dbh}->last_insert_id(
            undef,
            undef,
            $self->{sql}->{from},
            undef
        );
        
    } else {
        
        # MySQL drivers ( recent ones ) claim to support last_insert_id(), but I'll be
        # damned if I can get it to work. Older drivers don't support it anyway, so for
        # maximum compatibility, we do something they can all deal with.
        
        # The below works for MySQL and SQL Server, and possibly others ( Sybase ? )
        
        my $sth = $self->{dbh}->prepare( 'select @@IDENTITY' );
        $sth->execute;
        
        if ( my $row = $sth->fetchrow_array ) {
            $primary_key = $row;
        } else {
            $primary_key = undef;
        }
        
    }
    
    return $primary_key;
    
}

sub process_entry_keypress {
    
    my ( $self, $widget, $event ) = @_;
    
    if (
        $event->keyval == $Gtk2::Gdk::Keysyms{ Return } ||
        $event->keyval == $Gtk2::Gdk::Keysyms{ KP_Enter }
    ) {
        $self->{window}->child_focus('tab-forward');
        # If this was a combo ( keep in mind this event occurs in the Combo's child entry ),
        # then tab-forward again, otherwise our focus has only moved along
        # to the drop-down button thingy ...
        if ( ref $widget->get_parent eq "Gtk2::ComboBoxEntry" ) {
            $self->{window}->child_focus('tab-forward');
        }
    }
   
    return FALSE; # This return value is required otherwise the event doesn't propogate and the keypress has no effect
       
}

sub reset_record_status {
    
    # This sub resets the record status ( changed flag ) so that Gtk2::Ex::DBI considers the record SYNCHRONISED
    
    my $self = shift;
    
    $self->{changed} = FALSE;
    $self->record_status_label_set;
    
}

sub formatter_number_to_widget {
    
    my ( $self, $value, $options ) = @_;
    
    # $options can contain:
    #  - currency
    #  - percentage
    #  - decimals
    #  - decimal_fill
    #  - separate_thousands
    
    # Avoid stoopid warnings - this will replace NULL values zeros, which is OK by me ...
    if ( ! $value ) {
        $value = 0;
    }
    
    # Strip out dollar signs
    $value =~ s/\$//g;
    
    # Allow for our number of decimal places
    if ( $options->{decimals} ) {
        $value *= 10 ** $options->{decimals};
    }
    
    # For percentages, multiply by 100
    if ( $options->{percentage} ) {
    	$value *= 100;
    }
    
    # Round
    $value = int( $value + .5 * ( $value <=> 0 ) );
    
    # Get decimals back
    if ( $options->{decimals} ) {
        $value /= 10 ** $options->{decimals};
    }
    
    # Split whole and decimal parts
    my ( $whole, $decimal ) = split /\./, $value;
    
    # Pad decimals
    if ( $options->{decimal_fill} && $options->{decimals} ) {
        if ( defined $decimal ) {
            $decimal = $decimal . "0" x ( $options->{decimals} - length( $decimal ) );
        } else {
            $decimal = "0" x $options->{decimals};
        }
    }
    
    # Separate thousands if specified, OR make it the default to separate them if we're dealing with currency
    if ( $options->{separate_thousands} || ( $options->{currency} && ! exists $options->{separate_thousands} ) ) {
        # This BS comes from 'perldoc -q numbers'
        $whole =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
    }
    
    if ( $options->{decimals} ) {
        $value = "$whole.$decimal";
    } else {
        $value = $whole;
    }
    
    # Prepend a dollar sign for currency
    if ( $options->{currency} ) {
        $value = '$' . $value;
        # If this is a negative value, we want to force the negative sign to the left of the dollar sign ...
        $value =~ s/\$-/-\$/;
    }
    
    # Append a percentage sign for percentages
    if ( $options->{percentage} ) {
    	$value .= '%';
    }
    
    return $value;
    
}

sub formatter_date_to_widget {
	
	my ( $self, $value, $options ) = @_;
	
	# $options can contain:
    #  - strip_time				- useful for cases where you have a datetime field, but are only storing / viewing dates
    #  - format					- format for date display ( currently only ddmmyyyy supported )
	
	if ( $value ) { # Don't bother with any formatting if we haven't been passed anything
		
		if ( $options->{strip_time} ) {
			$value = substr( $value, 0, 10 ); # Assuming 10 characters of course ( dd-mm-yyyy )
		}
		
		if ( $options->{format} eq "ddmmyyyy" ) {
			my ( $yyyy, $mm, $dd ) = split /[-\/]/, $value;
        	$value = $dd . "-" . $mm . "-" . $yyyy;
		}
		
	}
	
	return $value;
	
}

sub formatter_number_from_widget {
    
    # This sub strips dollar signs and commas from values, so they can
    # be passed back to the database as numeric values
    
    my ( $self, $value ) = @_;
    
    if ( $value ) {
        # Strip dollar signs
        $value =~ s/\$//g;
        
        # Strip commas
        $value =~ s/\,//g;
    }
    
    if ( $value =~ /%/ ) {
        $value =~ s/%//g;
        $value /= 100;
    }
    
    return $value;
    
}

sub formatter_date_from_widget {
    
    # Converts date values from a widget ( which may be formatted ) back to
    # a DB-friendly format if required
    
    my ( $self, $value, $options ) = @_;
    
    if ( $value ) {
        if ( $options->{format} eq "ddmmyyyy" ) {
	        
	        my ( $dd, $mm, $yyyy ) = split /[-\/]/, $value;
	        
	        if ( length( $yyyy) == 2 ) {
	            $yyyy = '20' . $yyyy;
	        }
	        
    	    $value = $yyyy . "-"
    	       . sprintf( "%02d", $mm ) . "-"
    	       . sprintf( "%02d", $dd );
    	    
        }
    } else {
        $value = undef;
    }
    
    return $value;
    
}

sub parse_sql_server_default {
    
    # This sub parses the string returned by SQL Server as the DEFAULT value for a given field
    
    my ( $self, $sqlserver_default ) = @_;
    
    # Find the last space in the string
    my $final_space_position = rindex( $sqlserver_default, " " );
    
    if ( ! $final_space_position || $final_space_position == -1 ) {
        # Bail out, returning undef.
        # We can't use the current default value ( as it's a string definition ), so we might as well just drop it completely
        warn "Gtk2::Ex::DBI::parse_sql_server_default failed to find the last space character in the DEFAULT definition:\n$sqlserver_default\n";
        return undef;
    } else {
        # We've got the final space character. Now get everything to the right of it ...
        my $default_value = substr( $sqlserver_default, $final_space_position + 1, length( $sqlserver_default ) - $final_space_position - 1 );
        #  ... and strip off any quotes
        $default_value =~ s/'//g;
        return $default_value;
    }
    
}

sub build_right_click_menu {
        
    # This sub appends menu items to the right-click menu of widgets
    
    # TODO Add some custom icons, particularly for the calculator ... find is OK
    
    my ( $self, $widget, $menu ) = @_;
    
    my $menu_item;
    
    # Get the parent widget so we know if we're an entry in a combo box or not
    my $parent_widget = $widget->get_parent;
    
    # The 'find' menu item
    if ( ! $self->{disable_find} && ! exists $self->{sql}->{pass_through} ) {
        $menu_item = Gtk2::ImageMenuItem->new_from_stock("gtk-find");
        if ( ref $parent_widget eq "Gtk2::ComboBoxEntry" ) {
            $menu_item->signal_connect_after( activate => sub { $self->find_dialog($parent_widget); } );
        } else {
            $menu_item->signal_connect_after( activate => sub { $self->find_dialog($widget); } );
        }
        $menu->append($menu_item);
        $menu_item->show;
    }
    
    # The 'calculator' menu item
    $menu_item = Gtk2::ImageMenuItem->new("Calculator");
    my $pixbuf = $widget->render_icon( "gtk-index", "menu" );
    my $image = Gtk2::Image->new_from_pixbuf($pixbuf);
    $menu_item->set_image($image);
    $menu_item->signal_connect_after( activate => sub { $self->calculator($widget); } );
    $menu->append($menu_item);
    $menu_item->show;
    
    # The 'refresh combo' menu item
    # ( but only if we've got a definition handy to rebuild it with )
    if ( ref $parent_widget eq "Gtk2::ComboBoxEntry"
        && $self->{combos}
        && $self->{combos}->{$parent_widget->get_name}
       ) {
        $menu_item = Gtk2::ImageMenuItem->new("Refresh Combo");
        $pixbuf = $widget->render_icon( "gtk-refresh", "menu" );
        $image = Gtk2::Image->new_from_pixbuf($pixbuf);
        $menu_item->set_image($image);
        $menu_item->signal_connect_after( activate => sub { $self->setup_combo($parent_widget->get_name); } );
        $menu->append($menu_item);
        $menu_item->show;
    }
    
    return FALSE;
        
}

sub find_dialog {
    
    # Pops up a find dialog for the user to search the *existing* recordset
    my ( $self, $widget ) = @_;
    
    # TODO This needs a rewrite, but I've never used it anyway ...
    warn "find_dialog() functionality currently broken ... needs a rewrite ...";
    
    $self->{find}->{window} = Gtk2::Window->new ( "toplevel" );
    $self->{find}->{window}->set_title( "Gtk2::Ex::DBI advanced query" );
    $self->{find}->{window}->set_default_size( 300, 480 );
    $self->{find}->{window}->set_position( "center-always" );
    
    $self->{find}->{criteria_vbox} = Gtk2::VBox->new( 0, 5 );
    
    $self->{find}->{criteria} = ();
    
    # Construct a model to use for the 'operator' combo box in the criteria builder
    $self->{find}->{operator_model} = Gtk2::ListStore->new(
        "Glib::String",
        "Glib::String"
    );
    
    foreach my $operator(
        [ "=",      "equals" ],
        [ "!=",     "does not equal" ],
        [ "<",      "less than" ],
        [ ">",      "greater than" ],
        [ "like",   "like" ]
    ) {
        $self->{find}->{operator_model}->set(
            $self->{find}->{operator_model}->append,
            0,  $$operator[0],
            1,  $$operator[1]
        );
    }
    
    # Construct a model to use for the 'field' combo box in the criteria builder
    $self->{find}->{field_model} = Gtk2::ListStore->new( "Glib::String" );
    
    foreach my $field ( $self->fieldlist ) {
        $self->{find}->{field_model}->set(
             $self->{find}->{field_model}->append,
             0,  $field
        );
    }
    
    # Add a blank row ( and set the field of the first criteria row )
    $self->find_dialog_add_criteria( $widget->get_name );
    
    # A scrolled window to put the criteria selectors in
    my $sw = Gtk2::ScrolledWindow->new( undef, undef );
    $sw->set_shadow_type( "etched-in" );
    $sw->set_policy( "never", "always" );
    $sw->add_with_viewport( $self->{find}->{criteria_vbox} );
    
    # A button to add more criteria
    my $add_criteria_button = Gtk2::Button->new_from_stock( 'gtk-add' );
    $add_criteria_button->signal_connect_after( clicked	=> sub { $self->find_dialog_add_criteria } );
    
    # The find button
    my $find_button = Gtk2::Button->new_from_stock( 'gtk-find' );
    $find_button->signal_connect_after( clicked	=> sub { $self->find_do_search } );
    
    # An hbox to hold the buttons
    my $hbox = Gtk2::HBox->new( 0, 5 );
    $hbox->pack_start( $add_criteria_button, TRUE, TRUE, 5 );
    $hbox->pack_start( $find_button, TRUE, TRUE, 5 );
    
    # Another hbox to hold the headings
    my $headings_hbox = Gtk2::HBox->new( 0, 5 );
    
    # The headings
    my $field_heading = Gtk2::Label->new;
    $field_heading->set_markup( "<b>Field</b>" );
    
    my $operator_heading = Gtk2::Label->new;
    $operator_heading->set_markup( "<b>Operator</b>" );
    
    my $criteria_heading = Gtk2::Label->new;
    $criteria_heading->set_markup( "<b>Criteria</b>" );
    
    $headings_hbox->pack_start( $field_heading, TRUE, TRUE, 0 );
    $headings_hbox->pack_start( $operator_heading, TRUE, TRUE, 0 );
    $headings_hbox->pack_start( $criteria_heading, TRUE, TRUE, 0 );
    
    # Add everything to the dialog
    my $vbox = Gtk2::VBox->new( 0, 5 );
    
    my $title = Gtk2::Label->new;
    $title->set_markup( "<big><b>Enter criteria for the search ...</b></big>" );
    
    $vbox->pack_start( $title, FALSE, FALSE, 0 );
    $vbox->pack_start( $headings_hbox, FALSE, FALSE, 0 );
    $vbox->pack_start( $sw, TRUE, TRUE, 0 );
    $vbox->pack_start( $hbox, FALSE, FALSE, 0 );
    
    $self->{find}->{window}->add( $vbox );
    
    # Show everything
    $self->{find}->{window}->show_all;
    
}

sub find_do_search {
    
    my $self = shift;
    
    my ( $where_clause, $bind_values );
    
    # Limit to current recordset?
    if ( $self->{disable_full_table_find} ) {
        $where_clause = $self->{sql}->{where};
        $bind_values = $self->{sql}->{bind_values};
    }
    
    # Loop through criteria array and assemble where clause
    for my $criteria ( @{$self->{find}->{criteria}} ) {
        
        my $operator;
        my $iter = $criteria->{operator_combo}->get_active_iter;
        
        if ( $iter ) {
            
            my $field_name = $criteria->{field_combo}->get_child->get_text;
            
            $operator = $criteria->{operator_combo}->get_model->get( $iter, 0 );
            
            if ( $where_clause ) {
                    $where_clause .= " and ";
            }
            
            $where_clause .= $field_name . " " . $operator . " " . "?";
            
            my ( $criteria_text, $criteria_value );
            
            # We need to put wildcards around a 'like' search
            if ( $operator eq "like" ) {
                $criteria_text = "%" . $criteria->{criteria_widget}->get_text . "%";
            } else {
                $criteria_text = $criteria->{criteria_widget}->get_text;
            }
            
            # Check if this field's widget is a combo. If it is, we can't search the table
            # on the text entered. We have to look up the text in the combo's model, and
            # search on that instead
            
            my $widget = $self->get_widget( $field_name );
            
            if ( $widget && ref( $widget ) eq 'Gtk2::ComboBoxEntry' ) {
                my $model = $widget->get_model;
                my $iter = $model->get_iter_first;
                while ( $iter ) {
                    if ( $criteria_text eq $model->get( $iter, 1 ) ) {
                        $criteria_value = $model->get( $iter, 0 );
                        last;
                    }
                    $iter = $model->iter_next( $iter );
                }
                if ( ! defined $criteria_value ) {
                    # We haven't found a match in the combo's model. Not much we can do
                    # other than use the text we've been given.
                    # In cases where the key text is the display text, this would work.
                    # In other cases, it probably won't
                    $criteria_value = $criteria_text;
                }
            } else {
                $criteria_value = $criteria_text;
            }
            
            push @{$bind_values}, $criteria_value;
            
        }
        
    }
    
    print "Find Dialog querying with:\n$where_clause\n" . Dumper( $bind_values );
    
    $self->query(
        {
            where           => $where_clause,
            bind_values     => $bind_values
        }
    );
    
    $self->{find}->{window}->destroy;
    
}

sub find_dialog_add_criteria {
    
    # Creates a new row of widgets for more criteria for our search operation, and store them
    # in an array ( $self->{find}->{criteria} )
    
    my ( $self, $widget ) = @_;
    
    # Create 3 widgets for the row
    my $field_combo = Gtk2::ComboBoxEntry->new( $self->{find}->{field_model}, 0 );
    my $operator_combo = Gtk2::ComboBoxEntry->new( $self->{find}->{operator_model}, 1 );
    my $criteria_widget = Gtk2::Entry->new;
    
    # Set the field if we've been passed one
    if ( $widget ) {
        $field_combo->get_child->set_text( $widget );
    }
    
    # Create an hbox to hold the 3 widgets
    my $hbox = Gtk2::HBox->new( TRUE, 5 );
    
    # Put widgets into hbox
    $hbox->pack_start( $field_combo,        TRUE, TRUE, 5 );
    $hbox->pack_start( $operator_combo,     TRUE, TRUE, 5 );
    $hbox->pack_start( $criteria_widget,    TRUE, TRUE, 5 );
    
    # Make a hash of the current criteria widgets
    my $new_criteria = {
        field_combo     => $field_combo,
        operator_combo  => $operator_combo,
        criteria_widget => $criteria_widget
    };
    
    # Append this hash onto our list of all criteria widgets
    push @{$self->{find}->{criteria}}, $new_criteria;
    
    # Add the hbox to the main vbox
    $self->{find}->{criteria_vbox}->pack_start( $hbox, FALSE, FALSE, 5 );
    
    # Show them
    $hbox->show_all;
    
}

sub calculator {
    
    # This pops up a simple addition-only calculator, and returns the calculated value to the calling widget
    
    my ( $self, $widget ) = @_;
    
    my $dialog = Gtk2::Dialog->new (
        "Gtk2::Ex::DBI calculator",
        undef,
        "modal",
        "gtk-ok"        => "ok",
        "gtk-cancel"    => "reject"
    );
    
    $dialog->set_default_size( 300, 480 );
    
    # The model
    my $model = Gtk2::ListStore->new( "Glib::Double" );
    
    # Add an initial row data to the model
    my $iter = $model->append;
    $model->set( $iter, 0, 0 );
    
    # A renderer
    my $renderer = Gtk2::CellRendererText->new;
    $renderer->set( editable => TRUE );
    
    # A column
    my $column = Gtk2::TreeViewColumn->new_with_attributes(
        "Values",
        $renderer,
        'text'  => 0
    );
    
    # The TreeView
    my $treeview = Gtk2::TreeView->new( $model );
    $treeview->set_rules_hint( TRUE );
    $treeview->append_column($column);
    
    # A scrolled window to put the TreeView in
    my $sw = Gtk2::ScrolledWindow->new( undef, undef );
    $sw->set_shadow_type( "etched-in" );
    $sw->set_policy( "never", "always" );
    
    # Add treeview to scrolled window
    $sw->add( $treeview );
    
    # Add scrolled window to the dialog
    $dialog->vbox->pack_start( $sw, TRUE, TRUE, 0 );
    
    # Add a Gtk2::Entry to show the current total
    my $total_widget = Gtk2::Entry->new;
    $dialog->vbox->pack_start( $total_widget, FALSE, FALSE, 0 );
    
    # Handle editing in the renderer
    $renderer->signal_connect_after( edited => sub {
        $self->calculator_process_editing( @_, $treeview, $model, $column, $total_widget );
    } );
    
    # Show everything
    $dialog->show_all;
    
    # Start editing in the 1st row
    $treeview->set_cursor( $model->get_path( $iter ), $column, TRUE );
    
    my $response = $dialog->run;
    
    if ( $response eq "ok" ) {
        # Transfer value back to calling widget and exit
        $widget->set_text( $total_widget->get_text );
        $dialog->destroy;
    } else {
        $dialog->destroy;
    }
    
}

sub calculator_process_editing {
    
    my ( $self, $renderer, $text_path, $new_text, $treeview, $model, $column, $total_widget ) = @_;
    
    my $path = Gtk2::TreePath->new_from_string ($text_path);
    my $iter = $model->get_iter ($path);
    
    # Only do something if we get a numeric value that isn't zero
    if ( $new_text !~ /\d/ || $new_text == 0 ) {
        return FALSE;
    }
    
    $model->set( $iter, 0, $new_text);
    my $new_iter = $model->append;
    
    $treeview->set_cursor(
        $model->get_path( $new_iter ),
        $column,
        TRUE
    );
    
    # Calculate total and display
    $iter = $model->get_iter_first;
    my $current_total;
    
    while ( $iter ) {
        $current_total += $model->get( $iter, 0 );
        $iter = $model->iter_next( $iter );
    }
    
    $total_widget->set_text( $current_total );
    
}

1;


########################################################################################################

package Gtk2::Ex::DBI::CalendarButton;

use Gtk2;

# this big hairy statement registers our Glib::Object-derived class
# and sets up all the signals and properties for it.

# TODO Complete CalendarButton functionality
# We want the same as the gnome date combo selector thing
# ( but we can't use it because it doesn't work on Windows / OSX )

use Glib::Object::Subclass
    Gtk2::Button::,
    signals => {
                    clicked => \&on_clicked
               },
    properties => [
                        Glib::ParamSpec->string(
                                                    "date",
                                                    "Date",
                                                    "What's the date again?",
                                                    "",
                                                    [qw(readable writable)]
                                               ),
                        Glib::ParamSpec->string(
                                                    "format",
                                                    "Format",
                                                    "What format should the date be displayed in?",
                                                    "",
                                                    [qw(readable writable)]
                                               )
                  ];


1;

=head1 NAME

Gtk2::Ex::DBI - Bind a Gtk2::GladeXML - generated window to a DBI data source

=head1 SYNOPSIS

use DBI;
use Gtk2 -init;
use Gtk2::GladeXML;
use Gtk2::Ex::DBI; 

my $dbh = DBI->connect (
                          "dbi:mysql:dbname=sales;host=screamer;port=3306",
                          "some_username",
                          "salespass", {
                                           PrintError => 0,
                                           RaiseError => 0,
                                           AutoCommit => 1,
                                       }
);

my $prospects_form = Gtk2::GladeXML->new("/path/to/glade/file/my_form.glade", 'Prospects');

my $prospects_form = Gtk2::Ex::DBI->new( {
            dbh         => $dbh
         ,  sql         => {
                              select       => "*"
                            , from         => "Prospects"
                           }
         ,  form        => $prospects
}
);

=head1 DESCRIPTION

This class ties data from a DBI datasource to widgets in a Gtk2+ window ( generated by Glade ).
All that is required is that you name your widgets the same as the fields in your data source.
You have to set up combo boxes ( ie create your Gtk2::ListStore and
attach it to your combo box ) *before* creating your Gtk2::Ex::DBI object.

Steps for use:

* Open a DBI connection

* Create a window from a Gtk2::GladeXML object

* Create a Gtk2::Ex::DBI object and link it to your window

You would then typically create some buttons ( in your Glade object )
and connect them to the methods below to handle common actions
such as inserting, moving, deleting, etc.

=head1 METHODS

=head2 new

=over 4

Object constructor. For more info, see section on CONSTRUCTION below.

=back

=head2 query ( [ where_object ] )

=over 4

Requeries the Database Server, either with the current where clause, or with a new one ( if passed ).

Version 2.x expects a where_object hash, containing the following keys:

=back

=head3 where

=over 4

The where key should contain the where clause, with placeholders ( ? ) for each value.
Using placeholders is particularly important if you're assembling a query based on
values taken from a form, as users can initiate an SQL injection attack if you
insert values directly into your where clause.

=back

=head3 bind_values

=over 4

bind_values should be an array of values, one for each placeholder in your where clause.

Version 1.x expected to be passed an optional string as a new where clause.
This behaviour is still supported for backwards compatibility. If a version 1.x call
is detected ( ie if where_object isn't a hash ), any existing bind_values will be deleted

=back

=head2 insert

=over 4

Inserts a new record in the *in-memory* recordset and sets up default values,
either from database defaults, or optionally overridden with values from the
default_values hash. If you're using sequences, the next sequence value will not
be fetched yet; this will happen when the user first starts entering data in the
new record.

=back

=head2 count

=over 4

Returns the number of records in the current recordset.

=back

=head2 move ( offset, [ absolute_position ] )

=over 4

Moves to a specified position in the recordset - either an offset, or an absolute position.
If an absolute position is given, the offset is ignored.
If there are changes to the current record, these are applied to the Database Server first.
Returns TRUE if successful, FALSE if unsuccessful.

=back

=head2 apply

=over 4

Apply changes to the current record back to the Database Server.
Returns TRUE if successful, FALSE if unsuccessful.

=back

=head2 revert

=over 4

Reverts the current record back to its original state.
Deletes the in-memory recordset if we were inserting a new record.

=back

=head2 undo

=over 4

Synonym of revert

=back

=head2 delete

=over 4

Deletes the current record.

=back

=head2 set_widget_value( fieldname, value )

=over 4

A convenience function to set a widget ( via it's fieldname ) with a given value.
This function will automatically set up data formatting for you ( eg numeric, date ),
based on the assumption that you are giving it data in the format that the database
server likes ( for example, yyyymmdd format dates ).

=back

=head2 get_widget( widget_name )

=over 4

A convenience function to get a widget. Works with both Glade and GTK Builder.
If no object with the given name exists, we also check if an object with the given name,
starting with $self->{widget_prefix} exists. widget_prefix can be passed in the constructor.

=back

=head2 get_widget_value( widget_name )

=over 4

Complimentary to the set_widget_value, this will return the value that data in a current
widget REPRESENTS from the database's point of view, ie with formatting stripped. You can
call get_widget_value() on non-managed widgets as well as managed ones.

=back

=head2 original_value( fieldname )

=over 4

A convenience function that returns the original value of the given field
( at the current position in the recordset ), since the recordset was last applied.
This is also the ONLY way of fetching the value of a field that is IN the recordset,
but NOT represented by a widget.

=back

=head2 sum_widgets( @widget_names )

=over 4

Convenience function that returns the sum of all given widgets. get_widget_value() is used
to retrieve each value, which will stips formatting from managed widgets, but you can include
non-managed widgets as well - they just have to be in the same window.

=back

=head2 lock

=over 4

Locks the current record to prevent editing. This is implemented by setting a value in a field
that you specify as a value of data_lock_field in your constructor. The apply() method is automatically
called when locking, and if apply() fails, lock() also fails.

=back

=head2 unlock

=over 4

Unlocks a locked record so the user can edit it again.

=back

=head2 setup_combo ( widget_name, [ new_where_object ] )

=over 4

Creates a new model for the combo of widget_name.
You can use this to refresh the items in a combo's list.
You can optionally pass a hash containing a new where_object
( where clause and bind_values ).

You can call this method on widgets that aren't being managed
( ie aren't in the field list ).

=back

=head2 setup_autocompletion ( widget_name, [ new_where_object ] )

=over 4

Creates an autocompletion object for a text entry. Autocompletions
are similar to combo boxes, but don't have a button thing. They're
invisible additions to a text entry that magically pop up a list
of values to select from.

=back

=head2 calculator ( Gtk2::Widget )

=over 4

Opens up a simple calculator dialog that allows the user to enter a list of values
to be added. The result will be applied to the given widget ( which assumes a
set_text() method ... ie a Gtk2::Entry would be a good choice ).

=back

=head2 find_dialog ( [ field ] )

=over 4

Opens a find 'dialog' ( a window in GTK speak ) that allows the user to query the active
table ( whatever's in the sql->{from} clause ). This will allow them to *alter* the where
clause. If you only want them to be able to *append* to the existing where clause, then
set the disable_full_table_find key to TRUE ( see 'new' method ).

If an optional field is passed, this will be inserted into the dialog as the first field
in the criteria list.

Note that the user can currently activate the find_dialog by right-clicking in a text field.
To disable this behaviour, set the disable_find key to TRUE ( see 'new' method ).

=back

=head2 position

=over 4

Returns the current position in the recordset ( starting at zero ).

=back

=head2 fieldlist

=over 4

Returns a fieldlist as an array, based on the current query.
Mainly for internal Gtk2::Ex::DBI use

=back

=head2 find_dialog

=over 4

Pops up a rudimentary 'find' dialog for searching. FIXME :)

=back

=head1 INTERNAL METHODS

=head2 assemble_new_record

=over 4

This method is called by the insert method. It actually creates the hash that
represents the new record. It sets default values using either database defaults
or from the default_values hash.

=back

=head2 paint

=over 4

Paints the form with current data.

=back

=head2 fetch_new_slice

=over 4

Fetches a new slice of records based on the apeture size.

=back

=head2 changed

=over 4

Called each time a widget value that Gtk2::Ex::DBI is managing changes.

=back

=head2 last_insert_id

=over 4

Wrapper around DBI's last_insert_id(), with some smarts for various
broken bits in different drivers.

=back

=head2 record_status_label_set

=over 4

Sets the record status label.

=back

=head2 paint_calculated

=over 4

Sets the values of all calculated fields. Called from the changed method.

=back

=head2 set_record_spinner_range

=over 4

Sets the record spinner range. Nothing to see here.

=back

=head2 process_entry_keypress

=over 4

Called on every keypress. Injects a 'tab' keypress when the user hits
'enter'.

=back

=head2 reset_record_status

=over 4

Resets the record status

=back

=head2 formatter_number_to_widget

=over 4

Performs numeric formatting

=back

=head2 formatter_date_to_widget

=over 4

Performs date formatting

=back

=head2 formatter_number_from_widget

=over 4

Opposite of formatter_number_to_widget

=back

=head2 formatter_date_from_widget

=over 4

Opposite of formatter_date_to_widget

=back

=head2 parse_sql_server_default

=over 4

Parses default definitions from SQL Server ( v7 )

=back

=head2 build_right_click_menu

=over 4

Builds the menu that pops up when you right-click most widgets that we manage

=back

=head2 set_active_iter_for_broken_combo_box

=over 4

This method is called when a ComboBoxEntry's value is changed
See http://bugzilla.gnome.org/show_bug.cgi?id=156017

Wow ... a 10-year-old bug. They're not going to fix it :(

=back

=head2 find_do_search

=over 4

Called when user activates search functionality in the find dialog

=back

=head2 find_dialog_add_criteria

=over 4

Creates a new row of widgets for entering more criteria in the find dialog

=back

=head2 calculator_process_editing

=over 4

Calculates totals in our calculator

=back

=head2 destroy_signal_handlers

=over 4

Destroys all signal handlers Gtk2::Ex::DBI has created.

=back

=head2 destroy_self

=over 4

Internal use only.

=back

=head2 destroy

=over 4

Destroys itself

=back

=head1 CONSTRUCTION

The new() method expects a hash of key / value pairs.

=head2 dbh

=over 4

A DBI database handle

=back

=head2 form

=over 4

The Gtk2::GladeXML object to bind to. You need to set either
the 'form' or 'builder' key.

=back

=head2 builder

=over 4

A Gtk2::Builder object to bind to. You need to set either
the'form' or 'builder' key.

=back

=head2 sql

=over 4

The sql object describes the query to be executed to fetch your records. Note that in contrast to
version 1.x, all the keywords ( select, from, where, order by, etc ) are *OMMITTED* ... see above
example. This is for consistency and ease of manipulating things. Trust me.

Minimum requirements for the sql object are the 'select' and 'from' keys, or alternatively a 'pass_through'.
All others are optional.

Details:

=back

=head2 select

=over 4

The SELECT clause

=back

=head2 from

=over 4

The FROM clause

=back

=head2 where

=over 4

The WHERE clause ( try '0=1' for inserting records )

=back

=head2 bind_values

=over 4

An array of values to bind to placeholders ... you ARE using placeholders, right?

=back

=head2 order_by

=over 4

The ORDER BY clause

=back

=head2 pass_through

=over 4

A command which is passsed directly to the Database Server ( that hopefully returns a recordset ).
If a pass_through key is specified, then this will be used as the SQL command, and all the other keys will be ignored.
You can use this feature to either construct your own SQL directly, which can include executing a stored procedure that
returns a recordset. Recordsets based on a pass_through query will be forced to read_only mode, as updates require that
column_info is available. I'm only currently using this feature for executing stored procedures, and column_info doesn't
work for these. If you want to enable updates for pass_through queries, you'll have to work on getting column_info working ...

=back

That's it for essential keys. All the rest are optional.

=head2 widgets

=over 4

The widgets hash contains information particular to each widget, including formatting information and SQL fieldname to widget
name mapping.
See the WIDGETS section for more information.

=back

=head2 combos

=over 4

The combos hash describes how to set up GtkComboBoxEntry widgets.
See COMBOS section for more informaton.

=back

=head2 primary_key

=over 4

The PRIMARY KEY of the table you are querying.

As of version 2.0, the primary key is automatically selected for you if you use MySQL. Note, however,
that this will only work if the FROM clause contains a single table. If you have a multi-table query,
you must specify the primary_key, otherwise the last primary_key encountered will be used. I recommend
against using multi-table queries anyway.

=back

=head2 on_current

=over 4

A reference to some Perl code to run when moving to a new record

=back

=head2 before_query

=over 4

A reference to some Perl code to run *before* executing a query.
Your code will be passed the 'where' object. Keep in mind this could either be a scalar or a hash,
depending on how you're using it.
Return TRUE to allow the query method to continue, or FALSE to prevent the query method from continuing.

=back

=head2 before_apply

=over 4

A reference to some Perl code to run *before* applying the current record.
Return TRUE to allow the apply method to continue, or FALSE to prevent the apply method from continuing.

=back

=head2 on_apply

=over 4

A reference to some Perl code to run *after* applying the current record.
Your code will be passed a reference to a hash of info about the current record:

 {
    status          => a string, with possible values: 'inserted', 'changed'
    primary_key     => the primary key of the record in question
 }

=back

=head2 on_undo

=over 4

A reference to some Perl code to run *after* undo() is called.
This can either be called by your code directly, or could be called if the
user makes changes to a recordset, and then wants to close the form / requery
without applying changes, which will call undo()

=back

=head2 on_changed

=over 4

A reference to some Perl code that runs *every* time the changed signal is fired.
Be careful - it's fired a LOT, eg every keypress event in entry widgets, etc

=back 

=head2 on_initial_changed

=over 4

A reference to some Perl code that runs *only* when the record status initially changes
for each record ( subsequent changes to the same record won't trigger this code )

=back

=head2 auto_apply

=over 4

A boolean that will cause datasheets to *automatically* apply changes if a new query is run
while outstanding changes exist, or if the user tries to close a form with outstanding changes
 ... ie NO question dialog will appear
 
=back

=head2 calc_fields

=over 4

A hash of fieldnames / Perl expressions to provide calculated fields

=back

=head2 apeture

=over 4

The size of the recordset slice ( in records ) to fetch into memory.
ONLY change this BEFORE querying

=back

=head2 record_spinner

=over 4

The name of a GtkSpinButton to use as the record spinner. The default is to use a
widget called RecordSpinner. However there are a number of reasons why you may want to
override this. You can simply pass the name of a widget that *doesn't* exist ( ie NONE )
to disable the use of a record spinner. Otherwise you may want to use a widget with a
different name, for example if you have a number of Gtk2::Ex::DBI objects connected to
the same Glade XML project.

=back

=head2 friendly_table_name

=over 4

This is a string you can use to override the default table name ( ie $self->{sql}->{from} )
in GUI error messages.

=back

=head2 manual_spinner

=over 4

Disable automatic move() operations when the RecordSpinner is clicked

=back

=head2 read_only

=over 4

Whether we allow updates to the recordset ( default = FALSE ; updates allowed )

=back

=head2 data_lock_field

=over 4

The name of a field that controls record locking. If this field contains a non-zero or not null value
at the point of the on_current event, the record will be LOCKED from edits and deletes.
See also the lock() and unlock() methods

=back

=head2 defaults

=over 4

A HOH of default values to use when a new record is inserted

=back

=head2 quiet

=over 4

A flag to silence warnings such as missing widgets

=back

=head2 status_label

=over 4

The name of a label to use to indicate the record status. This is especially useful if you have
more than 1 Gtk2::Ex::DBI object bound to a single Gtk2::GladeXML object

=back

=head2 schema

=over 4

The schema to query to get field details ( defaults, column types ) ... not required for MySQL

=back

=head2 disable_full_table_find

=over 4

Don't allow the user to replace the where clause; only append to the existing one

=back

=head2 disable_find

=over 4

Disable the 'find' item in the right-click menu of GtkText widgets ( ie disable user-initiated searches )

=back

=head2 dont_update_keys

=over 4

Don't include primary keys in update statements. Some databases don't like that.

=back

=head2 widget_prefix

=over 4

A string to prefix to widget names when getting hold of them ( ie via Glade or Builder ).
NOTE: we FIRST try without the widget prefix.

=back

=head2 auto_incrementing

=over 4

A flag ( default ON ) to indicate whether we should try to poll the last inserted ID after
an insert.

=back

=head1 WIDGETS

The widgets hash contains information particular to each managed widget. Each hash item in the widgets hash
should be named after a widget in your Glade XML file. The following are possible keys for each widget:

=head2 sequence_sql

=over 4

If you set this, it can be any SQL that can be executed and then fetched to return a value
that will be used as a sequence. The value will be applied to the current widget. This will happen
each time editing begins in a new record.

=back

=head2 sequence_dbh

=over 4

If you want your sequence_sql to be executed against a different connection to your main dbh,
pass a sequence_dbh.

=back

=head2 sql_fieldname

=over 4

The sql_fieldname is, as expected the SQL fieldname. This is the name used in selects, updates, deletes and inserts.
The most common use ( for me ) is to support SQL aliases. For example, if you have a complex window that has a number
of Gtk2::Ex::DBI objects attached to it, you may encounter the situation where you have name clashes. In this case, Gtk2::Ex::DBI
will use the sql_fieldname when talking to the database, but will bind to the widget which matches this widget hash's name.
Another ( perhaps more natural ) way of generating this behaviour is to simply create an alias in your SQL select string.
Gtk2::Ex::DBI parses the select string and populates the sql_fieldname key of the widgets hash where appropriate for you.

=back

=head2 number

=over 4

This is a HASH of options to control numeric formatting. Possible keys are:

=back

=head2 decimal_places

=over 4

You can specify the number of decimal places values are rounded to when being displayed. Keep in mind that if a user edits
data, when they apply, the value displayed in the widget will be the one applied. This default to 2 if you set the 'currency'
field.

=back

=head2 decimal_fill

=over 4

Whether to fill numbers out to the specified number of decimal places. This is automatically selected if you set
the 'currency' field.

=back

=head2 currency

=over 4

Whether to apply currency formatting to data. It adds a dollar sign before values. It also sets the following options
if they aren't already specified:
- decimal_places     - 2
- decimal_fill       - TRUE
- separate_thousands - TRUE

=back

=head2 percentage

=over 4

Whether to convert values to percentage when rendering to a widget. Note that if the number hash exists for a widget,
then Gtk2::Ex::DBI will *always* check for percentages, and convert when necessary, when fetching a value *from* a widget
( ie whether the percentage key is set or not )

=back

=head2 separate_thousands

=over 4

Whether to separate each group of 3 digits with a comma before rendering to a widget. If the number hash exists, values
will *always* have commas stripped from them when fetching a value *from* a widget ( ie whether the separate_thousands 
key is set or not )

=back

=head2 date

=over 4

This is a HASH of options controlling date formatting. Possible options are:

=back

=head2 format

=over 4

This formatter converts dates from the international standard ( yyyy-mm-dd ) to the Australian ( and maybe others )
fomat ( dd-mm-yyyy ). If you use this formatter, you should also use the complementary output_formatter, also called
date_dd-mm-yyyy ... but in the output_formatter array.

=back

=head2 strip_time

=over 4

This formatter strips off the end of date values. It is useful in cases where the database server returns a DATETIME
value and you only want the DATE portion. Keep in mind that when you apply data, you will only be passing a DATE value
back to the database.

=back

=head1 COMBOS

Gtk2::Ex::DBI uses the GtkComboBoxEntry widget, which is available in gtk 2.4 and above.
To populate the list of options, a model ( Gtk2::ListStore ) is attached to the combo.
Gtk::Ex::DBI expects this model to have the ID in the 1st column, and the String column 2nd column.
You can pack as many other columns in as you like ... at least for now :)

If you choose to set up each combo's model yourself, you *must* do this before constructing your
Gtk2::Ex::DBI object.

Alternatively you can pass a hash of combo definitions to the constructor, and they will be set up for you.
If you choose this method, you get a couple of other features for free. You will be able to refresh the combo's
model with the setup_combo() method ( see above ). Users will also be able to trigger this action by right-clicking
in the combo's entry and selecting 'refresh'. You will also get autocompletion set up in the combo's entry widget
( this is triggered after typing the 1st character in the combo's entry ).

To make use of the automated combo setup functionality, create a key in the combos hash, with a name that matches
the GtkComboBoxEntry's widget name in your glade xml file. Inside this key, create a hash with the following keys:

=head2 sql

=over 4

A hash of SQL related stuff. Possible keys are:

=back

=head2 select

=over 4

The select clause that defines the fields you want in your combo

=back

=head2 from

=over 4

The from clause

=back

=head2 where_object

=over 4

This can either be a where clause, or a hash with the following keys:

=back

=head2 where

=over 4

The where key should contain the where clause, with placeholders ( ? ) for each value.
Using placeholders is particularly important if you're assembling a query based on
values taken from a form, as users can initiate an SQL injection attack if you
insert values directly into your where clause.

=back

=head2 bind_values

=over 4

bind_values should be an array of values, one for each placeholder in your where clause.

=back

=head2 order_by

=over 4

An 'order by' clause

=back

=head2 alternate_dbh

=over 4

A DBI handle to use instead of the current Gtk2::Ex::DBI DBI handle

=back

=head2 fields ( optional )

=over 4

An array of field definitions. Note that the fields array is now optional.
If you ommit it, simply define a 'select' key in the SQL hash, and the
fields will be automatically set up ( with Glib::String types for each column ).
The only reason you'd really want to define a 'fields' array now is to set a
cell_data_func.

Each field definition is a hash with the following keys:

=back

=head2 name

=over 4

The SQL fieldname / expression

=back

=head2  type

=over 4

The ( Glib ) type of column to create for this field in the Gtk2::ListStore. Possible values are
Glib::Int and Glib::String.

=back

=head2 cell_data_func ( optional )

=over 4

A reference to some perl code to use as this columns's renderer's custom cell_data_func.
You can use this to perform formatting on the column ( or cell, whatever ) based on the
current data. Your function will be passed ( $column, $cell, $model, $iter ), as well as anything
else you pass in yourself.

=back

=head1 Class behaviour flags

=head2 $Gtk2::Ex::DBI::highlight_ok_colour

=over 4

The colour to use in various places for 'ok' type highlighting. Currently this only affects
the record status label, when the record is synchronised

=back

=head2 $Gtk2::Ex::DBI::highlight_colour

=over 4

The colour to use in various places for 'warning' type highlighting. Currently this only affects
the record status label, when the record is locked or changed.

=back

=head1 ISSUES

=head2 SQL Server compatibility

=over 4

To use SQL Server, you should use FreeTDS ==> UnixODBC ==> DBD::ODBC. Only this combination supports
the use of bind values in SQL statements, which is a requirement of Gtk2::Ex::DBI. Please
make sure you have the *very* *latest* versions of each.

The only problem I've ( recently ) encountered with SQL Server is with the 'money' column type.
Avoid using this type, and you should have flawless SQL Server action.

=back

=head1 BUGS

=head2 'destroy' method doesn't currently work

I don't know what the problem with this is.
I attach a *lot* of signals to widgets. I also go to great lengths to remember them all
and disconnect them later. Perhaps I'm missing one of them? Perhaps it's something else.
Patches gladly accepted :)

=head1 AUTHORS

Daniel Kasak - d.j.kasak.dk@gmail.com

=head1 CREDITS

Muppet

 - tirelessly offered help and suggestions in response to my endless list of questions

Gtk2-Perl Authors

 - obviously without them, I wouldn't have gotten very far ...

Gtk2-Perl list

 - yet more help, suggestions, and general words of encouragement

=head1 Other cool things you should know about:

This module is part of an umbrella project, which aims to make
Rapid Application Development of database apps using open-source tools a reality.
The project includes:

  Gtk2::Ex::DBI                 - forms
  Gtk2::Ex::Datasheet::DBI      - datasheets
  PDF::ReportWriter             - reports

=cut
