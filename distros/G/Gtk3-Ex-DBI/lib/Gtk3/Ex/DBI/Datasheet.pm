# (C) Daniel Kasak: d.j.kasak.dk@gmail.com
# See COPYRIGHT file for full license

package Gtk3::Ex::DBI::Datasheet;

use parent 'Gtk3::Ex::DBI';

use strict;

# Perl throws up some pretty stupid warnings. If you want to hear all about them,
# go ahead and 'use warnings'. I've checked all the warnings produced, and they're
# all harmless ...

#use warnings;
no warnings;

use Data::Dumper;
use Carp;

use Glib qw/TRUE FALSE/;
#use Pango;
use Time::HiRes;

# Record Status Indicators
use constant {
                                        UNCHANGED               => 0,
                                        CHANGED                 => 1,
                                        INSERTED                => 2,
                                        DELETED                 => 3,
                                        LOCKED                  => 4
};

# Record Status column
use constant {
                                        STATUS_COLUMN           => 0
};

BEGIN {
    $Gtk3::Ex::DBI::Datasheet::VERSION                          = '3.2';
}

sub new {
    
    my ( $class, $req ) = @_;
    
    # Assemble object from request
    my $self = {
        dbh                  => $$req{dbh}                           # A database handle
      , schema               => $$req{schema}                        # Database schema ( not required for MySQL )
      , search_path          => $$req{search_path}                   # Schema search paths ( not required for MySQL )
      , sql                  => $$req{sql}                           # A hash of SQL related stuff
      , force_upper_case_fields => $$req{force_upper_case_fields}    # Forces fieldnames to be upper-case ( set this to match upper-case glade object names )
      , treeview             => $$req{treeview}                      # A Gtk2::Treeview to connect to
      , footer_treeview      => $$req{footer_treeview}               # A Gtk2::Treeview to connect to ( for the footer )
      , vbox                 => $$req{vbox}                          # A vbox to create treeview(s) in
      , footer               => $$req{footer}                        # A boolean to activate the footer treeview
      , sw_footer_no_scroll  => $$req{sw_footer_no_scroll}           # A boolean to de-activate the automatic ( vertical ) scrollbar for footers
      , fields               => $$req{fields}                        # Field definitions
      , column_info          => $$req{column_info} || undef          # 'Faked' column_info
      , multi_select         => $$req{multi_select}                  # Boolean to enable multi selection mode
      , column_sorting       => $$req{column_sorting} || 0           # Boolean to activate ( incomplete ) column sorting
      , default_font_size    => $$req{default_font_size} || undef    # Default font size
      , fixed_row_height     => $$req{fixed_row_height} || 0         # Boolean to activate fixed-height mode 
      , read_only            => $$req{read_only}                     # Boolean to indicate read-only mode
      , before_insert        => $$req{before_insert}                 # Code that runs *before* each record is inserted
      , on_insert            => $$req{on_insert}                     # Code that runs *after* each record is inserted
      , before_apply         => $$req{before_apply}                  # Code that runs *before* each record is applied
      , on_apply             => $$req{on_apply}                      # Code that runs *after* each record is applied
      , on_row_select        => $$req{on_row_select}                 # Code that runs when a row is selected
      , on_changed           => $$req{on_changed}                    # Code that runs when a record is changed ( any column )
      , auto_apply           => $$req{auto_apply}                    # Boolean to force all records to be applied automatically when querying, closing, etc
      , after_size_allocate  => $$req{after_size_allocate} || undef  # Code that runs after the columns have responded to a size_allocate
      , dump_on_error        => $$req{dump_on_error}                 # Boolean to dump SQL command on DBI error
      , friendly_table_name  => $$req{friendly_table_name}           # Table name to use when issuing GUI errors
      , custom_changed_text  => $$req{custom_changed_text} || undef  # Text ( including markup ) to use in GUI questions when changes need to be applied
      , data_lock_field      => $$req{data_lock_field} || undef      # A field ( sql fieldname ) to use as a data-driven lock ( positive values will lock the record )
      , quick_renderers      => $$req{quick_renderers} || 0          # Boolean to force all renderers to quick, default text renderers
      , primary_keys         => $$req{primary_keys}                  # An array of primary keys ( overrides the default detected ones )
      , dont_update_keys     => $$req{dont_update_keys} || 0         # Boolean to allow primary key updates
      , auto_incrementing    => defined $$req{auto_incrementing}
                                   ? $$req{auto_incrementing} : 1    # A flag to indicate whether we should try to poll the last inserted ID after an insert
      , quiet                => $$req{quiet} || 0                    # Boolean to supress non-fatal warnings
      , recordset_tools_box  => $$req{recordset_tools_box}           # A box to create recordset tools in ( add / insert / update / delete / undo / spinnner )
      , recordset_tool_items => $$req{recordset_tool_items}          # An array of item names to add to the recordset tools box
      , auto_tools_box       => $$req{auto_tools_box}                # Boolean to turn on creation of the tools box ( requires vbox )
      , no_autosizing        => $$req{no_autosizing}                 # Disable column auto-sizing
      , recordset_extra_tools => $$req{recordset_extra_tools}        # Extra buttons to add to the recordset tools box
    };
    
    $self->{months_array} = qw/ Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec /;
    
    # Sanity checks ...
    if ( ! $self->{dbh} ) {
        croak( "Gtk3::Ex::DBI::Datasheet constructor missing a dbh!" );
    }
    
    if ( ! $self->{treeview} && ! $self->{vbox} ) {
        croak( "Gtk3::Ex::DBI::Datasheet constructor requires either a treeview or a vbox!" );
    }
    
    if ( $self->{treeview} && $self->{vbox} ) {
        croak( "You passed BOTH a treeview AND a vbox. Use one or the other!" );
    }
    
    if ( $self->{sql} ) {
        if ( exists $self->{sql}->{pass_through} ) {
            $self->{read_only} = TRUE;
        } elsif ( ! ( exists $self->{sql}->{select} && exists $self->{sql}->{from} ) ) {
            croak( "Gtk3::Ex::DBI::Datasheet constructor missing a complete sql definition!\n"
                . "You either need to specify a pass_through key\n"
                . "or BOTH a 'select' AND and a 'from' key" );
        }
    }
    
    bless $self, $class;
    
    $self->{supported_recordset_items} = {
#        navigator   => {
#                            type        => 'navigator'
#                       }
#      , label       => {
#                            type        => 'label'
#                       }
        insert      => {
                            type        => 'button'
                          , icon_name   => 'document-new'
                       }
      , undo        => {
                            type        => 'button'
                          , icon_name   => 'edit-undo'
                       }
      , delete      => {
                            type        => 'button'
                          , icon_name   => 'edit-delete'
                       }
      , apply       => {
                            type        => 'button'
                          , icon_name   => 'document-save'
                       }
      , data_to_csv => {
                            type        => 'button'
                          , icon_name   => 'document-save-as'
                       }
    };
    
    my $legacy_warnings;
    
    # Reconstruct sql object if needed
    if ( $$req{sql_select} || $$req{table} || $$req{sql_where} || $$req{sql_order_by} ) {
        
        # Strip out SQL directives
        if ( $$req{sql_select} ) {
            $$req{sql_select}           =~ s/^select //i;
        }
        if ( $$req{table} ) {
            $$req{table}                =~ s/^from //i;
        }
        if ( $$req{sql_where} ) {
            $$req{sql_where}            =~ s/^where //i;
        }
        if ( $$req{sql_order_by} ) {
            $$req{sql_order_by}         =~ s/^order by //i;
        }
        
        # Assemble things
        my $sql = {
                        select          => $$req{sql_select},
                        from            => $$req{table},
                        where           => $$req{sql_where},
                        order_by        => $$req{sql_order_by}
        };
        
        $self->{sql} = $sql;
        
        $legacy_warnings = " - use the new sql object for the SQL string\n";
        
    }
    
    # Set the table name to use for GUI errors
    if ( ! $self->{friendly_table_name} ) {
        $self->{friendly_table_name} = $self->{sql}->{from};
    }
    
    # Convert legacy primary_key to new primary_keys
    if ( exists $req->{primary_key} ) {
        push @{$self->{primary_keys}}, $req->{primary_key};
        carp( "Converting legacy 'primary_key' key to new 'primary_keys' array" );
    }
    
    if ( $legacy_warnings || $self->{legacy_mode} ) {
        warn "\n\n **** Gtk3::Ex::DBI::Datasheet starting in legacy mode ***\n"
           . "While quite some effort has gone into supporting this, it would be wise to take action now.\n"
           . "Warnings triggered by your request:\n$legacy_warnings\n";
    }
    
    $self->{server} = $self->{dbh}->get_info( 17 );
    
    # Some Database-specific stuff ...
    
    # PostGreSQL stuff - DLB
    if ( $self->{server} =~ /postgres/i ) {
        
        if ( $self->{schema} ) {
            if ( ! $self->{search_path} ) {
                $self->{search_path} = $self->{schema} . ",public";
            }
            
            my $sth = $self->{dbh}->prepare ( "SET search_path to " . $self->{search_path} );
            $sth->execute or die $self->{dbh}->errstr;
        }
        
    } elsif ( lc($self->{server}) eq "sqlserver" ) {
        
        # SQL Server doesn't allow you to update primary keys
        $self->{dont_update_keys} = 1;
        
    }
    
    if ( ! $self->setup_fields ) {
        # If there's an error setting up fields, we don't want to continue,
        # as we'll ( sometimes ) then create a treeview which is awkward to detect
        # and delete by the caller. The result is that if *another* datasheet object is constructed,
        # we'll have 2 treeviews. This would happen, for example, when a user has to select a connection
        # and database to run a given query against, and they get it wrong. Or alternatively when we're executing
        # some SQL from a user and they get something wrong.
        return undef;
    }
    
    $self->setup_treeview( "treeview" );
    
    if ( $self->{auto_tools_box} ) {
        $self->{recordset_tools_box} = Gtk3::Box->new( 'GTK_ORIENTATION_HORIZONTAL', 0 );
        $self->{vbox}->pack_end( $self->{recordset_tools_box}, FALSE, TRUE, 0 );
    }
    
    if ( $self->{recordset_tools_box} ) {
        $self->setup_recordset_tools;
    }
    
    if ( $self->{footer} ) {
        
        $self->setup_treeview( "footer_treeview" );
        
        # Unlike the main treeview's model, which gets constructed each time
        # we query, the footer model stays the same, and the values get updated
        
        $self->{footer_model} = Gtk3::ListStore->new( @{ $self->{footer_treeview_treestore_def} } );
        
        # Insert a row
        $self->{footer_model}->set(
            $self->{footer_model}->append,
            0, 0
        );
        
        $self->{footer_treeview}->set_model( $self->{footer_model} );
        
    }
    
    # Check recordset status when window is destroyed
    my $parent_widget = $self->{treeview}->get_parent;
    my $toplevel_widget;
    
    # Climb up through the widget heirarchy to find the toplevel widget ( the window )
    while ( $parent_widget ) {
        $toplevel_widget = $parent_widget;
        $parent_widget = $toplevel_widget->get_parent;
    }
    
    push @{$self->{objects_and_signals}},
        [
            $toplevel_widget,
            $toplevel_widget->signal_connect( delete_event => sub {
                if ( ! $self->{read_only} && $self->any_changes ) {
                    my $answer = TRUE;
                    if ( ! $self->{auto_apply} ) {
                        $answer = $self->dialog(
                            {
                                title       => "Apply changes to " . $self->{friendly_table_name} . " before closing?",
                                type        => "question",
                                text        => $self->{custom_changed_text} ? $self->{custom_changed_text} : 
                                                "There are changes to the current datasheet ( " . $self->{friendly_table_name} . " )\n"
                                                 . "that haven't yet been applied. Would you like to apply them before closing the form?"
                            }
                        );
                    }
                    # We return FALSE to allow the default signal handler to
                    # continue with destroying the window - all we wanted to do was check
                    # whether to apply records or not
                    if ( $answer eq 'yes' ) {
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
    
    $self->query;
    
    # TODO: this crashes:
    # *** unhandled exception in callback:
    # ***   undefined value for mandatory argument 'str' encountered at window/main.pm line 1107.
    # ***  ignoring at /usr/local/lib64/perl5/5.16.3/x86_64-linux-thread-multi/Glib/Object/Introspection.pm line 59.
    # undef is not of type Gtk3::Style at /usr/local/lib64/perl5/5.16.3/x86_64-linux-thread-multi/Glib/Object/Introspection.pm line 247.
    
    #push @{$self->{objects_and_signals}},
    #    [
    #        $self->{treeview},
    #        $self->{treeview}->signal_connect(
    #            cursor_changed => sub {
    #                    my ( $path, $focus_column ) = $self->{treeview}->get_cursor;
    #                    if ( $path && $focus_column ) {
    #                        $self->{treeview}->scroll_to_cell( undef, $focus_column, FALSE, 0.0, 0.0 );
    #                    }
    #            }
    #        )
    #    ];
    
    return $self;
    
}

sub destroy_self {
    
    undef $_[0];
    
}

sub destroy {
    
    my $self = shift;
    
    # Destroy signal handlers
    
    foreach my $set ( @{$self->{objects_and_signals}} ) {
        $$set[0]->signal_handler_disconnect( $$set[1] );
    }
    
    if ( $self->{changed_signal} ) {
        $self->{treeview}->get_model->signal_handler_disconnect( $self->{changed_signal} );
    }
    
    if ( $self->{row_select_signal} ) {
        $self->{treeview}->get_selection->signal_handler_disconnect( $self->{row_select_signal} );
    }
    
    $self->destroy_recordset_tools;
    
    # If we've been passed a vbox to create the scrolled window & treeview in, then
    # destroy everything in that vbox ... otherwise, leave things alone
    # ( in this case, the scrolled window and treeview would have been created by
    #   glade / builder ... and we shouldn't destroy that )
    
    if ( $self->{vbox} ) {
        foreach my $widget( $self->{vbox}->get_children ) {
            $widget->destroy;
        }
    }
    
    # Destroy renderers and treeview columns
    #foreach my $field ( @{$self->{fields}} ) {
    #    if ( exists $field->{treeview_column} ) {
    #        # TODO: can't destroy these in Gtk3???
    #        #$field->{treeview_column}->{renderer}->destroy;
    #        $field->{treeview_column}->destroy;
    #        if ( $self->{footer} ) {
    #            $field->{footer_treeview_column}->{renderer}->destroy;
    #            #$field->{footer_treeview_column}->destroy;
    #        }
    #    }
    #    $field = undef;
    #}
    
    $self->destroy_self;
    
}

sub setup_fields {
    
    my $self     = shift;
    my $options  = shift;
    
    if ( exists $options->{rebuild} && $options->{rebuild} ) {
        delete $self->{fields};
    }
    
    # Cache the fieldlist array so we don't have to continually query the Database Server for it
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
        my $escaped = Glib::Markup::escape_text( $@ );
        $self->dialog(
            {
                title   => "Error in Query!",
                type    => "error",
                text    => "<b>Database server says:</b>\n\n$escaped"
            }
        );
        if ( $self->{dump_on_error} ) {
            if ( exists $self->{sql}->{pass_through} ) {
                print "SQL was:\n\n" . $self->{sql}->{pass_through} . "\n\n";
            } else {
                print "SQL was:\n\n" . $self->{sql}->{select} . "\n\n";
            }
        }
        return FALSE;
    }
    
    eval {
        $sth->execute || croak( $self->{dbh}->errstr );
    };
    
    if ( $@ ) {
        my $escaped = Glib::Markup::escape_text( $@ );
        $self->dialog(
            {
                title   => "Error in Query!",
                type    => "error",
                text    => "<b>Database server says:</b>\n\n$escaped"
            }
        );
        if ( $self->{dump_on_error} ) {
            if ( exists $self->{sql}->{pass_through} ) {
                print "SQL was:\n\n" . $self->{sql}->{pass_through} . "\n\n";
            } else {
                print "SQL was:\n\n$self->{sql}->{select}\n\n";
            }
        }
        return FALSE;
    }
    
    my $name_req_string = 'NAME';
    
    if ( $self->{force_upper_case_fields} ) {
        $name_req_string .= '_uc';
    }
    
    $self->{fieldlist} = $sth->{$name_req_string};
    
    $sth->finish;
    
    # Fetch primary key(s), but only if we haven't been passed one in the constructor
    if ( ! $self->{primary_keys} && ! $self->{read_only} ) {
        eval {
            $sth = $self->{dbh}->primary_key_info( undef, undef, $self->{sql}->{from} )
                || die $self->{dbh}->errstr;
        };
        if ( ! $@ ) {
            while ( my $row = $sth->fetchrow_hashref ) {
                print "$self->{friendly_table_name} detected primary key item: $row->{COLUMN_NAME}\n";
                push @{$self->{primary_keys}}, $row->{COLUMN_NAME};
            }
        }
    }
    
    # If there are no field definitions, then create some from our fieldlist from the database
    # TODO: fix no_autosizing
#    if ( ! $self->{fields} && ! exists $self->{no_autosizing} ) {
    if ( ! $self->{fields} ) {
        my $no_of_fields = scalar @{$self->{fieldlist}};
        my $field_percentage = $no_of_fields < 8 ? 100 / $no_of_fields : 12.5; # Don't set percentages < 12.5 - doesn't really work so well ...
        for my $field ( @{$self->{fieldlist}} ) {
            push @{$self->{fields}},
                {
                    name        => $field
                  , x_percent   => $field_percentage
                };
        }
    }
    
    # Now scan for each primary key item in the fieldlist
    # If we don't find them, append them to the end of the list and create a hidden column for them
    foreach my $primary_key_item ( @{$self->{primary_keys}} ) {
        my @matches = grep( /^$primary_key_item$/, @{$self->{fieldlist}} );
        if ( ! @matches ) {
            push @{$self->{fieldlist}}, $primary_key_item;
            # Create a hidden column to store the PK item in
            my $next_column_no = scalar @{$self->{fields}};            
            push @{$self->{fields}},
                {
                    column      => $next_column_no,
                    name        => $primary_key_item,
                    renderer    => "hidden"
                };
        }
    }
    
    # Shove a _status_column_ at the front of $self->{fieldlist} and also $self->{fields}
    # so we don't have off-by-one BS everywhere
    unshift @{$self->{fieldlist}}, "_status_column_";
    
    unshift @{$self->{fields}}, {
        name            => "_status_column_",
        renderer        => "status_column",
        header_markup   => ""
    };
    
    if ( ! $self->{sql}->{pass_through} ) {
        
        # Fetch column_info for current table ( for those that support it )
        eval {
            $sth = $self->{dbh}->column_info ( undef, $self->{schema}, $self->{sql}->{from}, '%' )
                || die $self->{dbh}->errstr;
        };
        
        if ( $@ && ! $self->{quiet} ) {
            
            # We don't really want a dialog error message in this case. Dump a warning to the console
            # that we can't get column info, and continue ( renderers will default to text )
            carp( "\nCouldn't get column info for " . $self->{friendly_table_name} . " ) ...\n"
                . " ... This will happen in a multi-table query ...\n"
                . " ... Defaulting to text renderers for undefined fields\n\n" );
            
        } else {
            
            while ( my $column_info_row = $sth->fetchrow_hashref ) {
                # Loop through the list of columns from the database, and
                # add only columns that we're actually dealing with
                for my $field ( @{$self->{fieldlist}} ) {
                    # Allow column_info injection - skip if column_info already exists for this field
                    if ( $column_info_row->{COLUMN_NAME} eq $field  && ! exists $self->{column_info}->{$field} ) {
                        $self->{column_info}->{$field} = $column_info_row;
                        last;
                    }
                }
            }
            
            $sth->finish;
            
        }
        
    }
    
    if ( ! $self->{primary_keys} ) {
        $self->{read_only} = TRUE;
        if ( ! $self->{quiet} ) {
            carp( "\nCouldn't fetch a primary key for " . $self->{friendly_table_name} . " ) ...\n"
                . " ... This will happen in a multi-table query ...\n"
                . " ... Defaulting to read-only ...\n\n" );
        }
    }
    
    # Fill in renderer types
    my $column_no = 0;
    
    for my $field ( @{$self->{fields}} ) {
        
        # Set up column name <==> column number mapping
        $self->{column_name_to_number_mapping}->{ $field->{name} } = $column_no;
        
        # Grab a default renderer type if one hasn't been defined
        if ( ! $field->{renderer} ) {
            my $sql_name = $self->column_name_to_sql_name( $field->{name} );
            my $fieldtype = $self->{column_info}->{$sql_name}->{TYPE_NAME};
            if ( ! $fieldtype ) {
                $field->{renderer} = "text";
            } elsif ( $fieldtype =~ m/INT|DOUBLE/ ) {
                $field->{renderer} = "number";
                # Setting up a number hash forces numeric sorting
                if ( ! exists $field->{number} ) {
                    $field->{number} = {};
                }
            } elsif ( $fieldtype =~ m/CHAR/ ) {
                $field->{renderer} = "text";
            } elsif ( $fieldtype eq "TIMESTAMP" || $fieldtype =~ m/DATE/ ) {
                $field->{renderer} = "date";
            } elsif ( $fieldtype eq "TIME" ) {
                $field->{renderer} = "time";
            } else {
                $field->{renderer} = "text";
            }
        }
        
        if ( $field->{renderer} eq "none" ) {
            carp( "Renaming renderer 'none' to 'hidden'" );
            $field->{renderer} = "hidden";
        }
        
        if ( exists $field->{number} && exists $field->{number}->{decimals} ) {
            carp( "Renaming legacy 'decimals' key of number hash to 'decimal_places'" );
            $field->{number}->{decimal_places} = $field->{number}->{decimals};
            delete $field->{number}->{decimals};
        }
        
        $field->{column} = $column_no;
        
        $column_no ++;
        
    }
    
    # Remember the primary key column for later
    $self->{primary_key_column} = $self->{column_name_to_number_mapping}->{ $self->{primary_key} };
    
    return TRUE;
    
}

sub setup_treeview {
    
    my ( $self, $treeview_type, $options ) = @_;
    
    if ( exists $options->{rebuild} && $options->{rebuild} ) {
        
        # TODO: This is pretty hacked up ...
        #       Need to do it properly
        
        if ( $treeview_type eq "treeview" ) {
            
            if ( $self->{changed_signal} ) {
                $self->{treeview}->get_model->signal_handler_disconnect( $self->{changed_signal} );
                delete $self->{changed_signal};
            }
            
            my $parent = $self->{treeview}->get_parent;
            $self->{treeview}->destroy;
            $self->{treeview} = Gtk3::TreeView->new;
            
            eval { # This might fail, but if so, we don't care
                $self->{treeview}->set_grid_lines( "both" );
            };
            
            $self->{treeview}->set_rules_hint( TRUE );
            $parent->add( $self->{treeview} );
            $parent->show_all;
            
            delete $self->{treeview_treestor_def};
            
        } elsif ( $treeview_type eq "footer_treeview" ) {
            
            my $parent = $self->{footer_treeview}->get_parent;
            $self->{footer_treeview}->destroy;
            
        }
        
    }
    
    # Sets up the TreeView, *and* a definition for the TreeStore
    # ( which is used to create a new TreeStore whenever we requery )
    
    # $type is either 'treeview' or 'footer_treeview'
    
    # If we're setting up the main treeview, and we've been given a vbox, construct a treeview and put it in the vbox
    
    if ( $treeview_type eq "treeview" && $self->{vbox} ) {
        
        my $sw = Gtk3::ScrolledWindow->new;
        
        if ( ! $self->{sw_no_scroll} ) {
            $sw->set_policy( "automatic", "always" );
        } else {
            $sw->set_policy( "automatic", "never" );
        }
        
        $self->{vbox}->pack_start( $sw, TRUE, TRUE, 0 );
        $self->{treeview} = Gtk3::TreeView->new;
        
        eval { # This might fail, but if so, we don't care
            $self->{treeview}->set_grid_lines( "both" );
        };
        
        $self->{treeview}->set_rules_hint( TRUE );
        $sw->add( $self->{treeview} );
        $sw->show_all;
        
    } elsif ( $treeview_type eq "footer_treeview" && $self->{vbox} ) {
        
        my $hseparator = Gtk3::HSeparator->new;
        $self->{vbox}->pack_start( $hseparator, FALSE, TRUE, 0 );
        $hseparator->show;
        
        my $sw = Gtk3::ScrolledWindow->new;
        
        if ( ! $self->{sw_footer_no_scroll} ) {
            $sw->set_policy( "automatic", "always" );
        } else {
            $sw->set_policy( "automatic", "never" );
        }
        
        $self->{vbox}->pack_start( $sw, FALSE, TRUE, 0 );
        $self->{footer_treeview} = Gtk3::TreeView->new;
        $self->{footer_treeview}->set_headers_visible( FALSE );
        
        eval { # This might fail, but if so, we don't care
            $self->{footer_treeview}->set_grid_lines( "both" );
        };
        
        $self->{footer_treeview}->set_rules_hint( TRUE );
        $sw->set_size_request( 0, 25 ); # TODO How do we determine the row height?
        $sw->add( $self->{footer_treeview} );
        $sw->show_all;
        
    }
    
    # Set up icons for use in the record status column
    if ( $treeview_type eq "treeview" ) {
        $self->{icons}[UNCHANGED]   = $self->{treeview}->render_icon( "gtk-yes",                    "menu" );
        $self->{icons}[CHANGED]     = $self->{treeview}->render_icon( "gtk-refresh",                "menu" );
        $self->{icons}[INSERTED]    = $self->{treeview}->render_icon( "gtk-add",                    "menu" );
        $self->{icons}[DELETED]     = $self->{treeview}->render_icon( "gtk-delete",                 "menu" );
        $self->{icons}[LOCKED]      = $self->{treeview}->render_icon( "gtk-dialog-authentication",  "menu" );
        
        foreach my $icon ( @{$self->{icons}} ) {
            # Gtk3 is fucked :( Icon handling is broken now, with no default
            # icons, and sometimes the above ->render_icon() calls can return UNDEF!
            if ( $icon ) {
                my $icon_width = $icon->get_width;
                if ( $icon_width > $self->{status_icon_width} ) {
                    $self->{status_icon_width} = $icon_width;
                }
            }
        }
        
        # Icons don't seem to take up the entire cell, so we need some more room. This will do ...
        $self->{status_icon_width} += 10;
    }
    
    # Now set up the model and columns
    for my $field ( @{$self->{fields}} ) {
        
        my $renderer;
        
        # We try to default to a stock text renderer ( as it's the fastest ) where possible
        # We can't do that for combo cells, but otherwise if cells are read-only or hidden,
        # use the stock text renderer
        if (
            $field->{renderer} eq "text"
            || $field->{renderer} eq "hidden"
            || $field->{renderer} eq "number"
            || (
                ( $field->{read_only} || $self->{read_only} )
                    && $field->{renderer} !~ m/combo/
                    && $field->{renderer} ne "toggle"
                    && $field->{renderer} ne "progress"
                    && $field->{renderer} ne "status_column"
                    && $field->{renderer} ne "image"
                )
            || ( $self->{quick_renderers} && ! $field->{renderer} eq "status_column" )
        ) {
            
            if (
                $treeview_type eq "footer_treeview"
                || $field->{renderer} eq "hidden"
                || $field->{read_only}
                || $self->{read_only}
            ) {
                $renderer = Gtk3::CellRendererText->new;
            } else {
                #$renderer = Gtk3::Ex::Datasheet::DBI::CellRendererText->new;
                $renderer = Gtk3::CellRendererText->new;
            }
            
            $renderer->{column} = $field->{column};
            
            if ( $treeview_type ne "footer_treeview" && ! $self->{read_only} && ! $field->{read_only} ) {
                $renderer->set( editable => TRUE );
            } else {
                $renderer->set( editable => FALSE );
            }
            
            if ( $field->{wrap_text} ) {
                #$renderer->set( 'wrap-mode', 'word' );
                $renderer->set( 'wrap-width', 30 );
            }
            
            $field->{ $treeview_type . "_column" } = Gtk3::TreeViewColumn->new_with_attributes(
                $field->{name},
                $renderer,
                'text'  => $field->{column}
            );
            
            # 'date_only' render functions need to be converted to 'date_only_text' for text renderers
            # ( and we're in the text renderer section here )
            my $counter = 0;
            foreach my $render_function ( @{$field->{builtin_render_functions}} ) {
                if ( $render_function eq "date_only" ) {
                    $render_function = "date_only_text";
                }
                $counter ++;
            }
            
            if ( $field->{renderer} eq "hidden" ) {
                $field->{ $treeview_type . "_column" }->set_visible( FALSE );
            }
            
            push @{$self->{objects_and_signals}},
            [
                $renderer,
                $renderer->signal_connect( edited => sub { $self->process_text_editing( @_ ); } )
            ];
            
            $self->{ $treeview_type }->append_column( $field->{ $treeview_type . "_column" } );
            
            # Add a string column to the TreeStore definition ( recreated when we query() )
            push @{ $self->{ $treeview_type . "_treestore_def" } }, "Glib::String";
            
        } elsif ( $field->{renderer} eq "combo" ) {
            
            $renderer = Gtk3::CellRendererCombo->new;
            $renderer->{column} = $field->{column};
            
            # Get the data type and attach it to the renderer, so we know what kind of comparison
            # ( string vs numeric ) to use later
            my $sql_name = $self->column_name_to_sql_name( $field->{name} );
            my $fieldtype = $self->{column_info}->{$sql_name}->{TYPE_NAME};
            
            if ( $fieldtype =~ m/INT/ ) {
                $renderer->{data_type} = "numeric";
            } else {
                $renderer->{data_type} = "string";
            }
            
            if ( ! $self->{read_only} && ! $field->{read_only} ) {
                
                $renderer->set(
                    editable        => TRUE,
                    text_column     => 1,
                    has_entry       => FALSE # TODO Periodically investigate: Gtk3::CellRendererCombos's 'has_entry' MUST be disabled to avoid http://bugzilla.gnome.org/show_bug.cgi?id=317387
                );
                
                # It's possible that we won't have a model at this point
                if ( $field->{model} ) {
                    $renderer->set( model   => $field->{model} );
                }
                
            } else {
                
                $renderer->set( editable    => FALSE );
                
            }
            
            $field->{ $treeview_type . "_column" } = Gtk3::TreeViewColumn->new_with_attributes(
                $field->{name},
                $renderer,
                text    => $field->{column}
            );
            
            push @{$self->{objects_and_signals}},
            [
                $renderer,
                $renderer->signal_connect( edited => sub { $self->process_text_editing( @_ ) } )
            ];
            
            $self->{ $treeview_type }->append_column( $field->{ $treeview_type . "_column" } );
            
            # We have to do this *after* the column is added ( directly above )
            if ( $field->{model_setup} ) {
                $self->setup_combo( $field->{name} ) ;
            }
            
            push @{$field->{ $treeview_type . "_column" }->{builtin_render_functions}}, sub { $self->render_combo_cell( @_ ) };
            
            # Add a string column to the TreeStore definition ( recreated when we query() )
            push @{ $self->{ $treeview_type . "_treestore_def" } }, "Glib::String";
            
        } elsif ( $field->{renderer} eq "dynamic_combo" ) {
            
            $renderer = Gtk3::CellRendererCombo->new;
            $renderer->{column} = $field->{column};
            
            # In Gtk3, for dynamic combos, you store a ListStore ( that holds combo values )
            # in the main ListStore ( that holds the rows ), and then point the combo to the
            # column that holds this ListStore
            
            my $next_column_no = scalar @{$self->{fields}};
            
            push @{$self->{fields}},
            {
                column      => $next_column_no,
                name        => $field->{name} . "_dynamic_model",
                renderer    => "dynamic_model"
            };
            
            $renderer->{dynamic_model_position} = $next_column_no;
            
            # Keep this position number in the field has as well
            $field->{dynamic_model_position} = $next_column_no;
            
            if ( ! $self->{read_only} && ! $field->{read_only} ) {
                $renderer->set(
                    editable    => TRUE,
                    text_column => 1,
                    has_entry   => FALSE # TODO Periodically investigate: Gtk3::CellRendererCombos's 'has_entry' MUST be disabled to avoid http://bugzilla.gnome.org/show_bug.cgi?id=317387
                );
            } else {
                $renderer->set(
                    editable    => FALSE
                );
            }
            
            # Get the data type and attach it to the renderer, so we know what kind of comparison
            # ( string vs numeric ) to use later
            my $sql_name = $self->column_name_to_sql_name( $field->{name} );
            my $fieldtype = $self->{column_info}->{$sql_name}->{TYPE_NAME};
            
            if ( $fieldtype =~ m/INT/ ) {
                $renderer->{data_type} = "numeric";
            } else {
                $renderer->{data_type} = "string";
            }
            
            $field->{ $treeview_type . "_column" } = Gtk3::TreeViewColumn->new_with_attributes(
                $field->{name},
                $renderer,
                text    => $field->{column},
                model   => $renderer->{dynamic_model_position}
            );
            
            push @{$self->{objects_and_signals}},
            [
                $renderer,
                $renderer->signal_connect( edited => sub { $self->process_text_editing( @_ ); } )
            ];
            
            $self->{ $treeview_type }->append_column( $field->{ $treeview_type . "_column" } );
            
            push @{$field->{ $treeview_type . "_column" }->{builtin_render_functions}}, sub { $self->render_combo_cell( @_ ) };
            
            # Add a string column to the TreeStore definition ( recreated when we query() )
            push @{ $self->{ $treeview_type . "_treestore_def" } }, "Glib::String";
            
        } elsif ( $field->{renderer} eq "toggle" ) {
            
            $renderer = Gtk3::CellRendererToggle->new;
            
            if ( ! $self->{read_only} && ! $field->{read_only} ) {
                $renderer->set( activatable => TRUE );
            } else {
                $renderer->set( activatable => FALSE );
            }
            
            $renderer->{column} = $field->{column};
            
            $field->{ $treeview_type . "_column" } = Gtk3::TreeViewColumn->new_with_attributes(
                $field->{name},
                $renderer,
                active  => $field->{column}
            );
            
            push @{$self->{objects_and_signals}},
            [
                $renderer,
                $renderer->signal_connect( toggled => sub { $self->process_toggle( @_ ); } )
            ];
            
            $self->{ $treeview_type }->append_column( $field->{ $treeview_type . "_column" } );
            
            # Add an integer column to the TreeStore definition ( recreated when we query() )
            push @{ $self->{ $treeview_type . "_treestore_def" } }, "Glib::Boolean";
            
        } elsif ( $field->{renderer} eq "progress" ) {
            
            $renderer = Gtk3::CellRendererProgress->new;
            
            $renderer->{column} = $field->{column};
            
            $renderer->set( text    => "" );
            
            $field->{ $treeview_type . "_column" } = Gtk3::TreeViewColumn->new_with_attributes(
                $field->{name},
                $renderer,
                value  => $field->{column}
            );
            
            $self->{ $treeview_type }->append_column( $field->{ $treeview_type . "_column" } );
            
            # Add an integer column to the TreeStore definition ( recreated when we query() )
            push @{ $self->{ $treeview_type . "_treestore_def" } }, "Glib::Int";
            
        } elsif ( $field->{renderer} eq "date" ) {
            
            $renderer = Gtk3::Ex::DBI::Datasheet::CellRendererDate->new;
            $renderer->{column} = $field->{column};
            $renderer->set( mode => "editable" );
            
            if ( $field->{read_only} || $self->{read_only} ) {
                push @{$field->{builtin_render_functions}}, "date_only_text";
            } else {
                push @{$field->{buildin_render_functions}}, "date_only";
            }
            
            # Check for a dd-mm-yyyy or dd-mm-yy builtin_render_function.
            # Read-only cells get a text renderer ( ie not this one ), and the corresponding
            # buildin_render_function_ddmmyyyy
            # If the cell is *not* read-only, then CellRendererDate is used, so we
            # *remove* dd-mm-yyyy from builtin_render_functions, and mark the column so
            # CellRendererDate knows what to do ( ie our CellRendererDate knows about
            # dd-mm-yyyy format internally )
            
            my $counter = 0;
            
            foreach my $render_function ( @{$field->{builtin_render_functions}} ) {
                if ( $render_function eq "dd-mm-yyyy" ) {
                    delete $field->{builtin_render_functions}[$counter];
                    $renderer->set( format => "dd-mm-yyyy" );
                } elsif ( $render_function eq "dd-mm-yy" ) {
                    delete $field->{builtin_render_functions}[$counter];
                    $renderer->set( format => "dd-mm-yy" );
                } elsif ( $render_function eq "mmm-yyyy" ) {
                    delete $field->{builtin_render_functions}[$counter];
                    $renderer->set( format => "mmm-yyyy" );
                }
                $counter ++;
            }
            
            $field->{ $treeview_type . "_column" } = Gtk3::TreeViewColumn->new_with_attributes(
                $field->{name},
                $renderer,
                'date'  => $field->{column}
            );
            
            push @{$self->{objects_and_signals}},
            [
                $renderer,
                $renderer->signal_connect( edited => sub { $self->process_text_editing( @_ ); } )
            ];
            
            $self->{ $treeview_type }->append_column( $field->{ $treeview_type . "_column" } );
            
            # Add a string column to the TreeStore definition ( recreated when we query() )
            push @{ $self->{ $treeview_type . "_treestore_def" } }, "Glib::String";
            
        } elsif ( $field->{renderer} eq "time" || $field->{renderer} eq "access_time" ) {
            
            $renderer = Gtk3::Ex::DBI::Datasheet::CellRendererTime->new;
            $renderer->{column} = $field->{column};
            
            if ( $field->{renderer} eq "access_time" ) {
                $renderer->{access_time} = 1;
            }
            
            if ( ! $self->{read_only} && ! $field->{read_only} ) {
                $renderer->set( mode => "editable" );
            }
            
            $field->{ $treeview_type . "_column" } = Gtk3::TreeViewColumn->new_with_attributes(
                $field->{name},
                $renderer,
                'time'  => $field->{column}
            );
            
            push @{$self->{objects_and_renderers}},
            [
                $renderer,
                $renderer->signal_connect( edited => sub { $self->process_text_editing( @_ ); } )
            ];
            
            if ( $field->{renderer} eq "access_time" ) {
                push @{$field->{ $treeview_type . "_column" }->{builtin_render_functions}}, "access_time";
            }
            
            $self->{ $treeview_type }->append_column($field->{ $treeview_type . "_column" });
            
            # Add a string column to the TreeStore definition ( recreated when we query() )
            push @{ $self->{ $treeview_type . "_treestore_def" } }, "Glib::String";
            
        } elsif ( $field->{renderer} eq "image" ) {
            
            $renderer = Gtk3::CellRendererPixbuf->new;
            $field->{ $treeview_type . "_column" } = Gtk3::TreeViewColumn->new_with_attributes( $field->{name}, $renderer );
            $self->{ $treeview_type }->append_column( $field->{ $treeview_type . "_column" } );
            
            # ... and the TreeStore column that goes with it
            push @{ $self->{ $treeview_type . "_treestore_def" } }, "Glib::String";
            
        } elsif ( $field->{renderer} eq "status_column" ) {
            
            # The 1st column ( column 0 ) is the record status indicator: a CellRendererPixbuf
            
            $renderer = Gtk3::CellRendererPixbuf->new;
            $field->{ $treeview_type . "_column" } = Gtk3::TreeViewColumn->new_with_attributes( "", $renderer );
            $self->{ $treeview_type }->append_column( $field->{ $treeview_type . "_column" } );
            
            if ( $self->{read_only} ) {
                # Hide status indicator if read-only ...
                $field->{ $treeview_type . "_column" }->set_visible( FALSE );
                #  ... and set our status_icon_width to 0
                $self->{status_icon_width} = 0;
            } else {
                # Otherwise set fixed width
                $field->{x_absolute} = $self->{status_icon_width};
                $field->{ $treeview_type . "_column" }->set_cell_data_func( $renderer, sub { $self->render_pixbuf_cell( @_ ); } );
            }
            
            # ... and the TreeStore column that goes with it
            push @{ $self->{ $treeview_type . "_treestore_def" } }, "Glib::Int";
            
        } elsif ( $field->{renderer} eq "dynamic_model" ) {
            
            # We don't set up a renderer for dynamic models
            # ( which are only there to serve as a data source for dynamic_combo renderers )
            
            push @{ $self->{ $treeview_type . "_treestore_def" } }, "Gtk3::ListStore";
                
        } else {
            
            warn "Unknown render: " . $field->{renderer} . "\n";
            
        }
        
        $field->{ $treeview_type . "_column" }->set( resizable => TRUE );
        
        if ( $field->{renderer} ne "dynamic_model" ) {
            
            # Set up sorting
            if ( $self->{column_sorting} ) {
                $field->{ $treeview_type . "_column" }->set_sort_column_id( $field->{column} );
            }
            
            # Set up on_changed stuff for this field
            # TODO Document $field->{on_changed} support
            
            $renderer->{on_changed} = $field->{on_changed};
            
            # Pack some definition stuff into the TreeViewColumn so we can easily access it from other places ...
            my $definition = {
                name        => $field->{name},
                number      => $field->{number},
                date        => $field->{date}
            };
            
            $field->{ $treeview_type . "_column" }->{definition} = $definition;
            
            #  ... and also shove the renderer into the treeviewcolumn hash so we can destroy it later
            $field->{ $treeview_type . "_column" }->{renderer} = $renderer;
            
            # Replace the default ( whatever it is ) column header with a GtkLabel so
            # we can format the text somewhat
            my $label = Gtk3::Label->new( '' );
            
            if ( exists $field->{header_markup} ) {
                $label->set_markup( $field->{header_markup} );
            } else {
                $label->set_text( "$field->{name}" );
            }
            
            $label->show;
            
            $field->{ $treeview_type . "_column" }->set_widget( $label );
            
            # Set up column sizing stuff
            # TODO: Gtk3: this breaks scrolled window scrolling :()
            
#            if ( $field->{x_absolute} || $field->{x_percent} ) {
#                $field->{ $treeview_type . "_column" }->set_sizing("fixed");
#            }
            
            # Add any absolute x values to our total and set their column size ( once only for these )
            if ( $field->{x_absolute} ) {
                $field->{ $treeview_type . "_column" }->set_fixed_width( $field->{x_absolute} );
                if ( $treeview_type eq "treeview" ) { # only add these once, ie in the main treeview cycle
                    $self->{sum_absolute_x} += $field->{x_absolute};
                    $field->{current_width} = $field->{x_absolute};
                }
            }
            
            # Set up static colouring ...
            foreach my $property ( "foreground", "background" ) {
                if ( $field->{ $property . "_colour" } ) {
                    $renderer->set( $property . "_set"  => TRUE );
                    $renderer->set( $property           => $field->{ $property . "_colour" } );
                }
            }
            
            # ... and formatting ...
            # TODO: Gtk3 - re-enable bold
#            if ( $field->{bold} ) {
#                $renderer->set( weight  => PANGO_WEIGHT_BOLD );
#            }
            
            # ( some renderers don't support the font property and stuff )
            if ( $field->{renderer} =~ /(text|combo|date|number)/ ) {
                
                # ... and font size ...
                if ( $field->{font_size} ) {
                    $renderer->set( font    => $field->{font_size} );
                } elsif ( $self->{default_font_size} ) {
                    $renderer->set( font    => $self->{default_font_size} );
                }
                
            }
            
            if ( $self->{fixed_row_height} ) {
                $renderer->set_fixed_size( -1, $self->{default_font_size} * 1.8 ); # Dodgy, but approximately right
            }
            
            # ... and alignment ...
            if ( $field->{align} ) {
                # Test for decimal ( from PerlFaq4 )
                if ( $field->{align} =~ /^-?(?:\d+(?:\.\d*)?|\.\d+)$/ ) {
                    $renderer->set( xalign      => $field->{align} );
                } elsif ( lc( $field->{align} ) eq "left" ) {
                    $renderer->set( xalign      => 0 );
                } elsif ( lc( $field->{align} ) eq "right" ) {
                    $renderer->set( xalign      => 1 );
                } elsif ( lc( $field->{align} ) eq "centre" || lc( $field->{align} ) eq "center" ) {
                    $renderer->set( xalign      => 0.5 );
                } else {
                    warn "$field->{name} has unknown alignment: $field->{align}\n";
                }
            } elsif ( $field->{renderer} eq "number" || $field->{renderer} eq "currency" ) {
                $renderer->set( xalign  => 1 );
            }
            
            # Some number formatting stuff
            if ( exists $field->{number} ) {
                
                # Activate 'number' builtin render function if we've got a number definition
                unshift @{$field->{builtin_render_functions}}, "number";
                
                # Also swap out the legacy 'red_if_negative' flag for the new 'highlight_negative' flag
                if ( exists $field->{number}->{red_if_negative} && $field->{number}->{red_if_negative} ) {
                    carp( "\nMoving legacy 'red_if_negative' flag to new 'highlight_negative' flag\n"
                        . " ... Please update your core accordingly ...\n" );
                    delete $field->{number}->{red_if_negative};
                    $field->{number}->{highlight_negative} = TRUE;
                }
                
            }
            
            # Copy custom render functions from field definition into column
            # We have to put it into the column thing, otherwise it's very hard
            # to get to inside $self->process_render_functions
            
            if ( exists $field->{custom_render_functions} ) {
                # We have to suppress ticking over the Gtk3 main loop inside the query if there are any
                # custom render function ( some can crash things in a nasty way, particularly with the
                # footer functionality enabled
                # TODO Investigate Gtk3 main loop with footers and custom render functions further
                $self->{suppress_gtk3_main_iteration_in_query} = TRUE;
                $field->{ $treeview_type . "_column" }->{custom_render_functions} = $field->{custom_render_functions};
            }
            
            if ( exists $field->{builtin_render_functions} && scalar @{$field->{builtin_render_functions}} ) {
                $field->{ $treeview_type . "_column" }->{builtin_render_functions} = $field->{builtin_render_functions};
            }
            
            if (
                    ( exists $field->{ $treeview_type . "_column" }->{builtin_render_functions} && @{$field->{ $treeview_type . "_column" }->{builtin_render_functions}} )
                 || ( exists $field->{ $treeview_type . "_column" }->{custom_render_functions} && @{$field->{ $treeview_type . "_column" }->{custom_render_functions}} )
            ) {
                $field->{ $treeview_type . "_column" }->set_cell_data_func(
                    $renderer,
                    sub { $self->process_render_functions( @_ ) }
                );
            }
            
            if ( exists $field->{on_clicked} ) {
                print $field->{ $treeview_type . "_column" }->get_clickable . "\n";
                $field->{ $treeview_type . "_column" }->set_clickable( TRUE );
                # TODO TRACK AND DISCONNECT THIS SIGNAL!
                # This isn't documented yet, and I also don't use it myself, so there's no PARTICULAR hurry ...
                $field->{ $treeview_type . "_column" }->signal_connect( clicked  => sub { $field->{on_clicked}( @_ ) } );
            }
            
        }
        
    }
    
    # Now that all the columns are set up, loop over them again looking for dynamic models, so we can
    # set up automatic requerying of models when a column they depend on changes. We *could* have done this
    # in the above loop, but there's a ( remote ) chance that someone will want to set up a dynamic combo
    # that depends on a column *after* it ... while I can't see why people would do this, it's easy relatively
    # easy to accomodate anyway.
    
    for my $field ( @{$self->{fields}} ) {
        if ( $field->{renderer} && $field->{renderer} eq "dynamic_combo" ) {
            for my $criteria ( @{$field->{model_setup}->{criteria}} ) {
                push @{($self->{fields}[ $self->column_from_name( $criteria->{column_name} ) ]->{ $treeview_type . "_column" }->get_cells)[0]->{dependant_columns}},
                    $field->{column};
            }
        }
    }
    
    $self->{ $treeview_type . "_resize_signal" } = $self->{ $treeview_type }->signal_connect_after(
        size_allocate => sub { $self->on_size_allocate( @_, $treeview_type ) } );
    
    push @{$self->{objects_and_signals}},
    [
        $self->{ $treeview_type },
        $self->{ $treeview_type . "_resize_signal" }
    ];
    
    # The expose signal gets destroyed after the 1st expose event ...
    #  ... we only use it to align the column headers, and this only happens once
    # TODO: Gtk3 - fix label alignment
    #$self->{ $treeview_type . "_expose_signal" } = $self->{ $treeview_type }->signal_connect( expose_event => sub { $self->on_expose_event( @_, $treeview_type ); } );
    
    # Turn on multi-select mode if requested
    if ($self->{multi_select}) {
        $self->{ $treeview_type }->get_selection->set_mode("multiple");
    }
    
    $self->{current_width} = 0; # Prevent warnings
    
}

sub process_render_functions {
    
    my ( $self, $tree_column, $renderer, $model, $iter, @all_other_stuff ) = @_;
    
    # This sub handles multiple rendering functions
    
    # To allow these functions to be chained together,
    # we copy the value from the model into the $tree_column hash, and then
    # ALL FUNCTIONS SHOULD USE THIS VALUE AND UPDATE IT ACCORDINGLY
    
    # ie In your custom render functions, you should pull the value from
    # $tree_column->{render_value}, which gets set right here:
    
    if ( exists $renderer->{column} ) { # for images and other types, we may not have $renderer->{column} set ...
        $tree_column->{render_value} = $model->get( $iter, $renderer->{column} );
    }
    
    # First we do custom render functions ...
    foreach my $render_function ( @{$tree_column->{custom_render_functions}} ) {
        &$render_function( $tree_column, $renderer, $model, $iter, @all_other_stuff );
    }
    
    # ... and then the built-in ones
    foreach my $render_function ( @{$tree_column->{builtin_render_functions}} ) {
        if ( ref $render_function eq "CODE" ) {
            &$render_function( $tree_column, $renderer, $model, $iter );
        } elsif ( $render_function eq "access_time" ) {
            $self->builtin_render_function_access_time( $tree_column, $renderer, $model, $iter );
        } elsif ( $render_function eq "number" ) {
            $self->builtin_render_function_number( $tree_column, $renderer, $model, $iter );
        } elsif ( $render_function eq "dd-mm-yyyy" ) {
            $self->builtin_render_function_ddmmyyyy( $tree_column, $renderer, $model, $iter );
        } elsif ( $render_function eq "dd-mm-yy" ) {
            $self->builtin_render_function_ddmmyy( $tree_column, $renderer, $model, $iter );
        } elsif ( $render_function eq "date_only" ) {
            $self->builtin_render_function_date_only( $tree_column, $renderer, $model, $iter, { renderer => "date" } );
        } elsif ( $render_function eq "date_only_text" ) {
            $self->builtin_render_function_date_only( $tree_column, $renderer, $model, $iter, { renderer => "text" } );
        } elsif ( $render_function eq "mmm-yyyy" ) {
            $self->builtin_render_function_mmmyyyy( $tree_column, $renderer, $model, $iter );
        } else {
            warn "Unknown builtin_renderer: $render_function\n";
        }
    }
    
}

sub builtin_render_function_number {
    
    my ( $self, $tree_column, $renderer, $model, $iter ) = @_;
    
    # The $tree_column has a 'definition' hash, which is our entire field definition
    # In this hash, we pay attention to the 'number' hash, which may have the following keys:
    #  - percentage             BOOLEAN
    #  - currency               BOOLEAN
    #  - decimal_places         INT
    #  - decimal_fill           BOOLEAN
    #  - separate_thousands     BOOLEAN
    #  - null_if_zero           BOOLEAN
    #  - highlight_negative     ( new ) # TODO Port to PDF::ReportWriter
    
    my $number = $tree_column->{definition}->{number};
    my $value = $tree_column->{render_value};
    
    # Strip out currency / numeric formatting
    $value =~ s/\$|,//g;
    
    # Skip numeric stuff if possible
    if ( ( $number->{null_if_zero} ) && ! ( $value - 0 ) ) { # Need this to strip decimals from values such as 0.00
        
        $tree_column->{render_value} = "";
        
    } else {
        
        my $final;
        
        # Allow for our number of decimal places
        if ( $number->{decimal_places} ) {
            $value *= 10 ** $number->{decimal_places};
        }
        
        # For percentages, multiply by 100
        if ( $number->{percentage} ) {
            $value *= 100;
        }
        
        # Round
        $value = int( $value + .5 * ( $value <=> 0 ) );
        
        # Get decimals back
        if ( $number->{decimal_places} ) {
            $value /= 10 ** $number->{decimal_places};
        }
        
        # Split whole and decimal parts
        my ( $whole, $decimal ) = split /\./, $value;
        
        # Pad decimals
        if ( $number->{decimal_places} && ( ( $number->{decimal_fill} ) || ( $number->{currency} && ! exists $number->{decimal_fill} ) ) ) {
            if ( defined $decimal ) {
                $decimal = $decimal . "0" x ( $number->{decimal_places} - length( $decimal ) );
            } else {
                $decimal = "0" x $number->{decimal_places};
            }
        }
        
        # Separate thousands if specified, OR make it the default to separate them if we're dealing with currency
        if ( $number->{separate_thousands} || ( $number->{currency} && ! exists $number->{separate_thousands} ) ) {
            # This BS comes from 'perldoc -q numbers'
            $whole =~ s/(^[-+]?\d+?(?=(?>(?:\d{3})+)(?!\d))|\G\d{3}(?=\d))/$1,/g;
        }
        
        if ( $number->{decimal_places} ) {
            $value = $whole . "." . $decimal;
        } else {
            $value = $whole;
        }
        
        # TODO Why are we still getting commas here? Very rare anyway ...
        if ( $number->{highlight_negative} ) {
            if ( $value < 0 ) {
                $renderer->set( foreground  => $Gtk3::Ex::DBI::Datasheet::highlight_colour ?
                                                $Gtk3::Ex::DBI::Datasheet::highlight_colour : "red" );
            } else {
                $renderer->set( foreground  => $Gtk2::Ex::DBI::Datasheet::standard_text_colour ?
                                                $Gtk2::Ex::DBI::Datasheet::standard_text_colour : "black" );
            }
        }
        
        # Prepend a dollar sign for currency
        if ( $number->{currency} ) {
            $value = "\$" . $value;
            # If this is a negative value, we want to force the negative sign to the left of the dollar sign ...
            $value =~ s/\$-/-\$/;
        }
        
        # Append a percentage sign for percentages
        if ( $number->{percentage} ) {
            $value .= '%';
        }
        
        $tree_column->{render_value} = $value;
        
    }
    
    $renderer->set( text    => $tree_column->{render_value} );
    
    return FALSE;
    
}

# TODO Rewrite a better date formatter - something more generic

sub builtin_render_function_ddmmyyyy {
    
    my ( $self, $tree_column, $renderer, $model, $iter ) = @_;
    
    # Only do something if we've got a value
    
    if ( $tree_column->{render_value} ) {
        
        my ( $yyyy, $mm, $dd ) = split /-/,$tree_column->{render_value};
        
        $tree_column->{render_value} = $dd . "-" . $mm . "-" . $yyyy;
        
        $renderer->set( text => $tree_column->{render_value} );
        
    }
    
}

sub builtin_render_function_ddmmyy {
    
    # TODO Document builtin_render_function_ddmmyy
    
    my ( $self, $tree_column, $renderer, $model, $iter ) = @_;
    
    # Only do something if we've got a value
    
    if ( $tree_column->{render_value} ) {
        
        my ( $yyyy, $mm, $dd ) = split /-/,$tree_column->{render_value};
        
        $tree_column->{render_value} = $dd . "-" . $mm . "-" . substr( $yyyy, 2, 2 );
        
        $renderer->set( text => $tree_column->{render_value} );
        
    }
    
}

sub builtin_render_function_mmmyyyy {
    
    # TODO Document builtin_render_function_ddmmyy
    
    my ( $self, $tree_column, $renderer, $model, $iter ) = @_;
    
    # Only do something if we've got a value
    
    if ( $tree_column->{render_value} ) {
        my ( $yyyy, $mm, $dd ) = split /-/,$tree_column->{render_value};
        $tree_column->{render_value} = $self->{months_array}[ $mm - 1 ] . " " . $yyyy;
        $renderer->set( text => $tree_column->{render_value} );
    }
    
}

sub builtin_render_function_access_time {
    
    my ( $self, $tree_column, $renderer, $model, $iter ) = @_;
    
    my $access_time = $model->get( $iter, $renderer->{column} );
    my $real_time;
    
    # If the time has been edited already, it will be a sane value,
    # Otherwise it will have the date '1899-12-30' shoved at the front
    if ( length($access_time) == 19 ) {
        $real_time = substr( $access_time, 11, 8 );
    } else {
        $real_time = $access_time;
    }
    
    $tree_column->{render_value} = $real_time;
    
    $renderer->set( time => $real_time );
    
    return FALSE;
    
}

sub builtin_render_function_date_only {
    
    my ( $self, $tree_column, $renderer, $model, $iter, $options ) = @_;
    
    my $date_string = $model->get( $iter, $renderer->{column} );
    my $real_date;
    
    if ( length( $date_string ) > 10 ) {
        $real_date = substr( $date_string, 0, 10 );
    } else {
        $real_date = $date_string;
    }
    
    $tree_column->{render_value} = $real_date;
    
    if ( $options->{renderer} eq "date" ) {
        $renderer->date( time   => $real_date ); # TODO Is this right? Doesn't exactly look right ...
    } else {
        $renderer->set( text    => $real_date );
    }
    
    return FALSE;
    
}

sub render_pixbuf_cell {
    
    my ( $self, $tree_column, $renderer, $model, $iter ) = @_;
    
    my $status = $model->get( $iter, STATUS_COLUMN );
    $renderer->set( pixbuf => $self->{icons}[$status] );
    
    return FALSE;
    
}

sub render_combo_cell {
    
    my ( $self, $tree_column, $renderer, $model, $iter ) = @_;
    
    # Get the ID that represents the text value to display
    my $key_value = $model->get( $iter, $renderer->{column} );
    
    my $combo_model = $renderer->get( "model" );
    
    if ( $combo_model ) {
        
        # Loop through our combo's model and find a match for the above ID to get our text value
        my $combo_iter = $combo_model->get_iter_first;
        my $found_match = FALSE;
        
        while ( $combo_iter ) {
            
            if ( $renderer->{data_type} eq "numeric" ) {
                if (
                    $combo_model->get( $combo_iter, 0 )
                     && $key_value
                     && $combo_model->get( $combo_iter, 0 ) == $key_value
                   )
                {
                    $found_match = TRUE;
                    $renderer->set( text    => $combo_model->get( $combo_iter, 1 ) );
                    last;
                }
            } else {
                if (
                    $combo_model->get( $combo_iter, 0 )
                     && $key_value
                     && $combo_model->get( $combo_iter, 0 ) eq $key_value
                   )
                {
                    $found_match = TRUE;
                    $renderer->set( text    => $combo_model->get( $combo_iter, 1 ) );
                    last;
                }
            }
            
            if ( ! $combo_model->iter_next( $combo_iter ) ) {
                last;
            }
            
        }
        
        # If we haven't found a match, default to displaying an empty value
        if ( ! $found_match ) {
            $renderer->set( text    => "" );
        }
        
    } else {
        
        carp( "Gtk3::Ex::DBI::Datasheet::render_combo_cell called without a model being attached!\n" );
        
    }
    
    return FALSE;
    
}

sub refresh_dynamic_combos {
    
    # If this column has dependant cells ...
    # ( ie dynamic combos - in this case *this* renderer will have an array of
    # dependant_columns pointing to the *dependant* columns )
    #  ... refresh them
    
    my ( $self, $renderer, $path ) = @_;
    
    my $model = $self->{treeview}->get_model;
    my $iter = $model->get_iter( $path ); # I've been told not to pass iters around, so we'd better get a fresh one
    
    if ( $renderer->{dependant_columns} ) {
        
        # Get the current row in an array
        my @data = $model->get( $model->get_iter( $path ) );
        
        for my $dependant ( @{$renderer->{dependant_columns}} ) {
            
            # Create a new model
            my $new_model = $self->create_dynamic_model(
                $self->{fields}[$dependant]->{model_setup},
                \@data
            );
            
            # Dump the combo model in the main TreeView model
            $model->set(
                $iter,
                $self->{fields}[$dependant]->{dynamic_model_position},
                $new_model
            );
            
        }
        
    }
    
    return TRUE;
    
}

sub process_text_editing {
    
    my ( $self, $renderer, $text_path, $new_text ) = @_;
    
    my $column_no = $renderer->{column};
    my $path = Gtk3::TreePath->new_from_string( $text_path );
    my $model = $self->{treeview}->get_model;
    my $iter = $model->get_iter ( $path );
    
    if ( $self->{data_lock_field} ) {
        if ( $self->get_column_value( $self->{data_lock_field} ) ) {
            warn "Record locked!\n";
            return FALSE;
        }
    }
    
    # If this is a CellRendererCombo, then we have to look up the ID to match $new_text
    if ( ref($renderer) eq "Gtk3::CellRendererCombo" ) {
        
        my $combo_model;
        
        # If this is a dynamic combo, we can't get the model simply by $render->get("model") because
        # this is unreliable if the user has clicked outside the current row to end editing.
        if ( $renderer->{dynamic_model_position} ) {
                $combo_model = $model->get( $iter, $renderer->{dynamic_model_position} );
        } else {
                $combo_model = $renderer->get("model");
        }
        
        my $combo_iter = $combo_model->get_iter_first;
        my $found_match = FALSE;
        
        while ( $combo_iter ) {
            
            if ( $combo_model->get( $combo_iter, 1 ) eq $new_text ) {
                $found_match = TRUE;
                $new_text = $combo_model->get( $combo_iter, 0 ); # It's possible that this is a bad idea
                last;
            }
            
            if ( ! $combo_model->iter_next( $combo_iter ) ) {
                last;
            }
            
        }
        
        # If we haven't found a match, default to a zero
        if ( ! $found_match ) {
            $new_text = 0; # This may also be a bad idea
        }
        
    }
    
    # If this is an access_time renderer, we have to shove the date '1899-12-30' at the
    # front of the time ( if the length of $new_text indicates it doesn't already have this )
    if ( $renderer->{access_time} && length( $new_text ) == 8 ) {
        $new_text = "1899-12-30 " . $new_text;
    }
    
    # Test to see if there is *really* a change or whether we've just received a double-click
    # or something else that hasn't actually changed the data
    my $old_text = $model->get( $iter, $column_no );
    
    if ( $old_text ne $new_text ) {
        
        if ( $self->{fields}->[$column_no]->{validation} && ! $self->{suppress_validation} ) { # Array of field defs starts at zero
            $self->{suppress_validation} = TRUE;
            if ( ! $self->{fields}->[$column_no]->{validation}(
                {
                    renderer    => $renderer,
                    text_path   => $text_path,
                    new_text    => $new_text,
                    model       => $model # TODO Document!
                }
            ) ) {
                    return FALSE; # Error dialog should have already been produced by validation code
            }
        }
        
        # Supress setting the record status if the changed column is an sql_ignore / dont_update column
        # TOD: Consolidate into 1 attribute ... probably used for exactly the same thing
        if (
                ( exists $self->{columns}[$column_no]->{sql_ignore} && $self->{columns}[$column_no]->{sql_ignore} )
             || ( exists $self->{columns}[$column_no]->{dont_update} && $self->{columns}[$column_no]->{dont_update} )
        ) {
            $model->signal_handler_block( $self->{changed_signal} );
            $model->set( $iter, $column_no, $new_text );
            $model->signal_handler_unblock( $self->{changed_signal} );
        } else {
            $model->set( $iter, $column_no, $new_text );
        }
        
        $self->{suppress_validation} = FALSE;
        
        # Refresh dependant columns if any
        if ( $renderer->{dependant_columns} ) {
            $self->refresh_dynamic_combos( $renderer, $path );
        }
        
    }
    
    # Execute user-defined functions
    if ( $renderer->{on_changed} ) {
        $renderer->{on_changed}();
    }
    
    return FALSE;
    
}

sub process_toggle {
    
    my ( $self, $renderer, $text_path, $something ) = @_;
    
    my $column_no = $renderer->{column};
    my $path = Gtk3::TreePath->new ( $text_path );
    my $model = $self->{treeview}->get_model;
    my $iter = $model->get_iter ( $path );
    my $old_value = $model->get( $iter, $renderer->{column} );
    my $new_text = ! $old_value;
    
    if ( $self->{data_lock_column} ) {
        if ( $self->get_column_value( $self->{data_lock_column} ) ) {
            warn "Record locked!\n";
            return FALSE;
        }
    }
    
    if ( exists $self->{fields}->[$column_no]->{validation} && ! $self->{fields}->[$column_no]->{validation}(
        {
            renderer    => $renderer,
            text_path   => $text_path,
            new_text    => $new_text,
            model       => $model
        }
    ) ) {
        return FALSE; # Error dialog should have already been produced by validation code
    } else {
        
        $model->set ( $iter, $renderer->{column}, $new_text );
        
        # Refresh dependant columns if any
        if ( $renderer->{dependant_columns} ) {
            $self->refresh_dynamic_combos( $renderer, $path );
        }
        
    }
    
    return FALSE;
    
}

sub query {
    
    my ( $self, $where_object, $dont_apply ) = @_;
    
    # TODO Record paging desperately required!
    
    # TODO Re-apply user-defined column sorting after querying
    
    my $model = $self->{treeview}->get_model;
    
    if ( ! $dont_apply && ! $self->{read_only} && $model ) {
        
        # First test to see if we have any outstanding changes to the current datasheet
        my $iter = $model->get_iter_first;
        
        while ( $iter ) {
            
            my $status = $model->get( $iter, STATUS_COLUMN );
            
            # Decide what to do based on status
            if ( $status != UNCHANGED  && $status != LOCKED ) {
                
                my $answer = TRUE;
                
                if ( ! $self->{auto_apply} ) {
                    $answer = $self->dialog(
                        {
                            title       => "Apply changes to " . $self->{friendly_table_name} . " before querying?",
                            type        => "question",
                            text        => $self->{custom_changed_text} ? $self->{custom_changed_text} :
                                                "There are outstanding changes to the current datasheet ( " . $self->{friendly_table_name} . " )."
                                                . " Do you want to apply them before running a new query?"
                        }
                    );
                }
                
                if ( $answer eq 'yes' ) {
                    if ( ! $self->apply ) {
                        return FALSE; # Apply method will already give a dialog explaining error
                    }
                }
                
            }
            
            if( ! $model->iter_next( $iter ) ) {
                last;
            }
            
        }
        
    }
    
    my $sql;
    
    if ( exists $self->{sql}->{pass_through} ) {
        
        $sql = $self->{sql}->{pass_through};
        
    } else {
        
        # Deal with legacy mode - the query method used to accept an optional where clause
        if ( $where_object ) {
            
            if ( ref( $where_object ) ne "HASH" ) {
                
                # Legacy mode
                # Strip 'where ' out of clause
                $where_object =~ s/^where //i;
                
                # Transfer new where clause if defined
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
        
        $sql = "select " . $self->{sql}->{select};
        
        foreach my $primary_key_item ( @{$self->{primary_keys}} ) {
            $sql .= ", $primary_key_item";
        }
        
        $sql .= " from " . $self->{sql}->{from};
        
        if ( $self->{sql}->{where} ) {
            $sql .= " where " . $self->{sql}->{where};
        }
        
        if ( $self->{sql}->{order_by} ) {
            $sql .= " order by " . $self->{sql}->{order_by};
        }
        
    }
    
    my ( $sth, $query_start_time, $query_end_time );
    
    $query_start_time = Time::HiRes::gettimeofday;
    
    eval {
        $sth = $self->{dbh}->prepare( $sql ) || die $self->{dbh}->errstr;
    };
    
    if ( $@ ) {
        my $escaped = Glib::Markup::escape_text( $@ );
        $self->dialog(
            {
                title   => "Error preparing select statement!",
                icon    => "error",
                text    => "<b>Database server says:</b>\n\n$escaped"
            }
        );
        if ( $self->{dump_on_error} ) {
            print "SQL was:\n\n$sql\n\n";
        }
        return FALSE;
    }
    
    # Create a new ListStore
    my $liststore = Gtk3::ListStore->new( @{ $self->{treeview_treestore_def} } );
    
    eval {
        if ( $self->{sql}->{bind_values} ) {
            $sth->execute( @{$self->{sql}->{bind_values}} ) || die $self->{dbh}->errstr;
        } else {
            $sth->execute || die $self->{dbh}->errstr;
        }
    };
    
    if ( $@ ) {
        my $escaped = Glib::Markup::escape_text( $@ );
        $self->dialog(
            {
                title   => "Error executing statement!",
                type    => "error",
                text    => "<b>Database server says:</b>\n\n$escaped"
            }
        );
        if ( $self->{dump_on_error} ) {
            print "SQL was:\n\n$sql\n\n";
        }
        return FALSE;
    }
    
    $query_end_time = Time::HiRes::gettimeofday;
    
    $self->{query_execution_time} = $query_end_time - $query_start_time;
    
    # Remember the data_lock_field's position in the field array ...
    my $lock_position;
    if ( $self->{data_lock_field} ) {
        # Minus one because the status column ( taken into account by column_from_sql_name ) isn't in the SQL select string
        $lock_position = $self->column_from_sql_name( $self->{data_lock_field} ) - 1;
    }
    
    while ( my @row = $sth->fetchrow_array ) {
        
        my @model_row;
        my $column = 0;
        
        for my $field ( @{$self->{fields}} ) {
            
            if ( $column == 0 ) {
                
                my $record_status = UNCHANGED;
                
                # Check whether this record should be locked
                if ( $self->{data_lock_field} ) {
                    if ( $row[$lock_position] ) {
                        $record_status = LOCKED;
                    }
                }
                
                # Append a new treeiter, and the status indicator
                push @model_row, $liststore->append, STATUS_COLUMN, $record_status;
                
            } elsif ( $field->{renderer} ne "dynamic_model" ) { # Skip these, as they aren't in the data set
                
                push @model_row,
                    $column,
                    $row[$column - 1]; # 1 back for the status column, which isn't in the SQL select string
                
                # If this is a dynamic combo, append it to the end of the 'normal' columns
                # Luckily we have already figured out it's position ...
                if ( $field->{renderer} && $field->{renderer} eq "dynamic_combo" ) {
                    push @model_row,
                        $field->{dynamic_model_position},
                        $self->create_dynamic_model( $field->{model_setup}, \@row );
                }
                
            }
            
            $column++;
        }
        
        $liststore->set( @model_row );
        
        if ( $Gtk3::Ex::DBI::Datasheet::gtk3_main_iteration_in_query && ! $self->{suppress_gtk3_main_iteration_in_query} ) {
            Gtk3->main_iteration while ( Gtk3->events_pending );
        }
        
    }
    
    # Destroy changed_signal attached to old model ...
    if ( $self->{changed_signal} ) {
        $self->{treeview}->get_model->signal_handler_disconnect( $self->{changed_signal} );
    }
    
    # ... and the row_select_signal
    if ( $self->{row_select_signal} ) {
        $self->{treeview}->get_selection->signal_handler_disconnect( $self->{row_select_signal} );
    }
    
    # Set up column sorting
    
    foreach my $field ( @{$self->{fields}} ) {
        if ( exists $field->{number} ) {
            $liststore->set_sort_func(
                $field->{column},
                sub { $self->custom_sort( @_, $field->{column}, "numeric" ) }
            );
        }
        if ( $field->{renderer} eq "date" ) {
            $liststore->set_sort_func(
                $field->{column},
                sub { $self->custom_sort( @_, $field->{column}, "date" ) }
            );
        }
    }
    
    $self->{treeview}->set_model( $liststore );
    
    # Refresh all dynamic combos
    my $iter = $liststore->get_iter_first;
    
    while ( $iter ) {
        my $treepath = $liststore->get_path( $iter );
        foreach my $field ( @{$self->{fields}} ) {
            if ( exists $field->{treeview_column} ) {
                my $renderer = ($field->{treeview_column}->get_cells)[0];
                foreach my $dependant_column ( @{$renderer->{dependant_columns}} ) {
                    $self->refresh_dynamic_combos( $renderer, $treepath );
                }
            }
        }
        if ( ! $liststore->iter_next( $iter ) ) {
            last;
        }
    }
    
    $self->{changed_signal} = $liststore->signal_connect( "row-changed" => sub { $self->changed(@_) } );
    
    if ( $self->{on_row_select} ) {
        $self->{row_select_signal} = $self->{treeview}->get_selection->signal_connect( changed  => sub { $self->{on_row_select}(@_); } );
    }
    
    if ( $self->{footer} ) {
        $self->update_footer;
    }
    
    return TRUE;
    
}

sub undo {
    
    # undo and revert are synonyms of each other
    
    my $self = shift;
    
    $self->query( undef, TRUE );
    
    return TRUE;
    
}

sub revert {
    
    # undo and revert are synonyms of each other
    
    my $self = shift;
    
    $self->query( undef, TRUE );
    
    return TRUE;
    
}

sub changed {
    
    my ( $self, $liststore, $treepath, $iter ) = @_;
    
    my $model = $self->{treeview}->get_model;
    
    # Only change the record status if it's currently unchanged 
    if ( ! $model->get( $iter, STATUS_COLUMN ) ) {
        $model->signal_handler_block( $self->{changed_signal} );
        $model->set( $iter, STATUS_COLUMN, CHANGED );
        $model->signal_handler_unblock( $self->{changed_signal} );
    }
    
    # Execute user-defined functions
    if ( $self->{on_changed} ) {
        
        $self->{on_changed}(
            {
                treepath      => $treepath,
                iter          => $iter
            }
        );
        
    }
    
    if ( $self->{footer} ) {
        $self->update_footer;
    }
    
    return FALSE;
    
}

sub update_footer {
    
    my $self = shift;
    
    my @model_row;
    
    foreach my $field ( @{$self->{fields}} ) {
        if ( $field->{footer_function} eq "sum" ) {
            push @model_row, $field->{column}, $self->sum_column( $field->{column} );
        } elsif ( $field->{footer_function} eq "max" ) {
            push @model_row, $field->{column}, $self->max_column( $field->{column} );
        } elsif ( $field->{footer_function} eq "average" ) {
            push @model_row, $field->{column}, $self->average_column( $field->{column} );
        } elsif ( $field->{footer_text} ) {
            push @model_row, $field->{column}, $field->{footer_text};
        } else {
            push @model_row, $field->{column}, undef;
        }
    }
    
    $self->{footer_model}->set(
        $self->{footer_model}->get_iter_first,
        @model_row
    );
    
}

sub apply {
    
    my $self = shift;
    
    my ( @iters_to_remove );
    
    if ( $self->{read_only} ) {
        $self->dialog(
            {
                title   => "Read Only!",
                type    => "warning",
                text    => "Datasheet is open in read-only mode!"
            }
        );
        return FALSE;
    }
    
    my $model = $self->{treeview}->get_model;
    my $iter = $model->get_iter_first;
    
    while ( $iter ) {
        
        my $status = $model->get( $iter, STATUS_COLUMN );
        
        # Decide what to do based on status
        if ( $status == UNCHANGED || $status == LOCKED ) {
            if ( ! $model->iter_next( $iter ) ) {
                last;
            } else {
                next;
            }
        }
        
        # Now assemble a hash of primary key items and values
        my $primary_keys;
        
        foreach my $primary_key_item ( @{$self->{primary_keys}} ) {
            $primary_keys->{$primary_key_item} = $model->get( $iter, $self->column_from_sql_name( $primary_key_item ) );
        }
        
        if ( $self->{before_apply} ) {
            
            # Better change the status indicator back into text, rather than make
            # people use our constants. I think, anyway ...
            my $status_txt;
            
            if ( $status            == INSERTED ) {
                $status_txt         = "inserted";
            } elsif ( $status       == CHANGED ) {
                $status_txt         = "changed";
            } elsif ( $status       == DELETED ) {
                $status_txt         = "deleted";
            }
            
            # Do people want the whole row? I don't. Maybe others would? Wait for requests...
            my $result = $self->{before_apply}(
                {
                    status          => $status_txt,
                    primary_keys    => $primary_keys,
                    model           => $model,
                    iter            => $iter
                }
            );
            
            # If the user-defined before_apply() function returns 0, we abort this
            # update and continue with the next
            if ( $result == 0 ) {
                if ( ! $model->iter_next( $iter ) ) {
                    last;
                } else {
                    next;
                }
            }
            
        }
        
        if ( $status == DELETED ) {
            
            my ( @primary_key_filter_components, @values );
            
            my $sql = "delete from " . $self->{sql}->{from} . " where ";# . $self->{primary_key} . "=?";
            
            foreach my $primary_key_item ( keys %{$primary_keys} ) {
                push @primary_key_filter_components, "$primary_key_item=?";
                push @values, $primary_keys->{$primary_key_item};
            }
            
            $sql .= join( " and ", @primary_key_filter_components );
            
            my $sth = $self->{dbh}->prepare( $sql ) || die( $self->{dbh}->errstr );
            
            eval {
                $sth->execute( @values ) || die( $sth->errstr );
            };
            
            if ( $@ ) {
                my $escaped = Glib::Markup::escape_text( $@ );
                $self->dialog(
                    {
                        title   => "Error deleting record!",
                        type    => "error",
                        text    => "<b>Database server says:</b>\n\n$escaped"
                    }
                );
                if ( $self->{dump_on_error} ) {
                    print "SQL was:\n\n$sql\n\n";
                }
                return FALSE;
            };
            
        } else {
            
            # We process the insert / update operations in a similar fashion
            
            my $sql;                    # Final SQL to send to Database Server
            my $sql_fields;             # A comma-separated list of fields
            my @values;                 # An array of values taken from the current record
            my $placeholders;           # A string of placeholders, eg ( ?, ?, ? )
            # my $primary_key = undef;    # We pass this to the before_apply() and on_apply() functions
            
            foreach my $fieldname ( @{$self->{fieldlist}} ) {
                
                # SQL Server doesn't allow updates of primary keys
                # TODO Fix for non-auto_increment primary keys
                if (
                        (
                            grep( /^$fieldname$/, @{$self->{primary_keys}} )
                         && $self->{dont_update_keys}
                         && $status == CHANGED
                        )
                     || $fieldname eq "_status_column_" || ! $fieldname ) { # Also skip the _status_column_
                    next;
                };
                
                my $column_no = $self->column_from_sql_name( $fieldname );
                
                # Skip if this column is set as sql_ignore
                # TODO Document sql_ignore ... currently incomplete and not in use
                # TODO Consolidate into 1 attribute ...
                if (
                        ( exists $self->{fields}[$column_no]->{sql_ignore} && $self->{fields}[$column_no]->{sql_ignore} )
                     ||
                        (   exists $self->{fields}[$column_no]->{dont_update} && $self->{fields}[$column_no]->{dont_update}
                         && $status == CHANGED
                        )
                ) {
                    next;
                }
                
                if ( $status == INSERTED ) {
                    $sql_fields .= " $fieldname,";
                    if (
                        lc($self->{server}) eq 'oracle'
                        && $self->{fields}[$column_no]->{renderer} eq "date"
                    ) {
                        $placeholders .= " to_date( ?, 'yyyy-mm-dd' ),";
                    } else {
                        $placeholders .= " ?,";
                    }
                } else {
                    if (
                        lc($self->{server}) eq 'oracle'
                        && $self->{fields}[$column_no]->{renderer} eq "date"
                    ) {
                        $sql_fields .= " $fieldname=to_date( ?, 'yyyy-mm-dd' ),";
                    } else {
                        $sql_fields .= " $fieldname=?,";
                    }
                }
                
                my $value = $model->get( $iter, $column_no );
                
                if ( exists $self->{fields}[$column_no]->{number}
                        && $self->{fields}[$column_no]->{number} ) {
                    $value =~ s/[\$\,]//g;
                }
                
                push @values, $value;
                
            }
            
            # Remove trailing comma
            chop( $sql_fields );
            
            if ( $status == INSERTED ) {
                chop( $placeholders );
                $sql = "insert into " . $self->{sql}->{from} . " ( $sql_fields ) values ( $placeholders )";
            } elsif ( $status == CHANGED ) {
                $sql = "update " . $self->{sql}->{from} . " set $sql_fields where ";
                my @placeholder_array;
                foreach my $primary_key_item ( keys %{$primary_keys} ) {
                    push @placeholder_array, "$primary_key_item = ?";
#                    $sql .= "$primary_key_item=?,";
                    push @values, $primary_keys->{$primary_key_item};
                }
                $sql .= join( " and ", @placeholder_array );
#                chop( $sql );
            } else {
                warn "WTF? Unknown status: $status in status column! Skipping ...\n";
            }
            
            my $sth;
            
            eval {
                $sth = $self->{dbh}->prepare( $sql ) || die;
            };
            
            if ( $@ ) {
                my $escaped = Glib::Markup::escape_text( $@ );
                $self->dialog(
                    title   => "Error preparing statement!",
                    type    => "error",
                    text    => "<b>Database server says:</b>\n\n$escaped"
                );
                if ( $self->{dump_on_error} ) {
                    print "SQL was:\n\n$sql\n\n";
                }
                return FALSE;
            }
            
            eval {
                $sth->execute( @values ) || die( $sth->errstr );
            };
            
            if ( $@ ) {
                if ( $self->{dump_on_error} ) {
                    print "\n\nError was $@\n";
                    print "SQL was:\n\n$sql\n";
                }
                my $escaped = Glib::Markup::escape_text( $@ );
                $self->dialog(
                    {
                        title   => "Error processing recordset!",
                        type    => "error",
                        text    => "<b>Database server says:</b>\n\n$escaped"
                    }
                );
                return FALSE;
            }
            
            # If we just inserted a record, we have to fetch the primary key and replace the current '!' with it
            if ( $status == INSERTED ) {
                if ( $self->{auto_incrementing} ) {
                    my $primary_key = $self->last_insert_id;
                    $model->set( $iter, $self->{column_name_to_number_mapping}->{ $self->{primary_keys}[0] }, $primary_key );
                    foreach my $key ( keys %{$primary_keys} ) { # easiest way to get the *only* key ( hopefully ) in an auto-incrementing setup
                        $primary_keys->{$key} = $primary_key;
                    }
                }
            }
            
            # If we've gotten this far, the update was OK, so we'll reset the 'changed' flag
            # and move onto the next record
            $model->signal_handler_block( $self->{changed_signal} );
            
            if ( $self->{data_lock_field} ) {
                if ( $model->get( $iter, $self->column_from_sql_name( $self->{data_lock_field} ) ) ) {
                    $model->set( $iter, STATUS_COLUMN, LOCKED );
                } else {
                    $model->set( $iter, STATUS_COLUMN, UNCHANGED );
                }
            } else {
                $model->set( $iter, STATUS_COLUMN, UNCHANGED );
            }
            
            $model->signal_handler_unblock( $self->{changed_signal} );
            
        }
        
        # Execute user-defined functions
        if ( $self->{on_apply} ) {
            
            # Better change the status indicator back into text, rather than make
            # people use our constants. I think, anyway ...
            my $status_txt;
            
            if ( $status            == INSERTED ) {
                $status_txt         = "inserted";
            } elsif ( $status       == CHANGED ) {
                 $status_txt        = "changed";
            } elsif ( $status       == DELETED ) {
                $status_txt         = "deleted";
            }
            
            # Do people want the whole row? I don't. Maybe others would? Wait for requests...
            $self->{on_apply}(
                {
                    status        => $status_txt,
                    primary_keys  => $primary_keys,
                    model         => $model,
                    iter          => $iter
                }
            );
            
        }
        
        if ( $status == DELETED ) {
            # Delete row from treeview - Gtk3 doesn't like us storing these iters for
            # later removal, so we have to do it now, or convert it to a treepath or some BS
            # Note that this MUST happen after the on_apply() code, above
            $model->remove( $iter );
        }
        
        if ( ! $model->iter_next( $iter ) ) {
            last;
        }
        
    }
    
    return TRUE;
    
}

sub insert {
    
    my ( $self, @columns_and_values ) = @_;
    
    if ( $self->{read_only} ) {
        $self->dialog(
            {
                title   => "Read Only!",
                type    => "warning",
                text    => "Datasheet is open in read-only mode!"
            }
        );
        return FALSE;
    }
    
    if ( $self->{before_insert} ) {
        
        my $result = $self->{before_insert}();
        
        # If the user-defined before_insert() function returns 0,
        # we abort this insert
        
        if ( $result == 0 ) {
            return FALSE;
        }
        
    }
    
    my $model = $self->{treeview}->get_model;
    my $iter = $model->append;
    
    # Append any remaining fields ( ie that haven't been explicitely defined in @columns_and_values )
    # with default values from the database to the @columns_and_values array
    
    for my $column_no ( 1 .. @{$self->{fieldlist}} - 1) {
        
        if ( exists $self->{fields}->[$column_no]->{sequence_sql} ) {
            
            my $sequence_dbh = exists $self->{fields}->[$column_no]->{sequence_dbh} ? $self->{fields}->[$column_no]->{sequence_dbh} : $self->{dbh};
            
            my $sth;
            
            eval {
                $sth = $sequence_dbh->prepare( $self->{fields}->[$column_no]->{sequence_sql} )
                    || die $sequence_dbh->errstr;
                $sth->execute()
                    || die $sequence_dbh->errstr;
            };
            
            if ( $@ ) {
                $self->dialog(
                    {
                        title   => "Error selecting an ID from a sequence"
                      , type    => "error"
                      , text    => "Do NOT proceed to insert. You should probably restart this application."
                                 . " The error encountered was:\n\n$@"
                    }
                );
                return FALSE;
            }
            
            if ( my @row = $sth->fetchrow_array ) {
                push @columns_and_values
                   , $column_no
                   , $row[0];
            }
            
        } else {
            
            my $found = FALSE;
            
            for ( my $x = 0; $x < ( scalar(@columns_and_values) / 2 ); $x ++ ) {
                #if ( $columns_and_values[ ( $x * 2 ) ] - 1 == $column_no ) { # The array is 2 wide, plus 1 for status
                if ( $columns_and_values[ ( $x * 2 ) ] == $column_no ) { # The array is 2 wide
                    $found = TRUE;
                    last;
                }
            }
            
            if ( ! $found ) {
                my $default = $self->{column_info}->{$self->{fieldlist}[$column_no]}->{COLUMN_DEF};
                if ( $default && $self->{server} =~ /microsoft/i ) {
                    $default = $self->parse_sql_server_default( $default );
                }
                push @columns_and_values,
                    $column_no,
                    $default
            }
            
        }
        
    }
    
    my @new_record;
    
    push @new_record,
        $iter,
        STATUS_COLUMN,
        INSERTED;
    
    if ( scalar(@columns_and_values) ) {
        push @new_record,
             @columns_and_values;
    }
    
    $model->set( @new_record );
    
    # Refresh dynamic combos
    my $treepath = $model->get_path( $iter );
    foreach my $field ( @{$self->{fields}} ) {
        if ( exists $field->{treeview_column} ) {
            my $renderer = ($field->{treeview_column}->get_cells)[0];
            foreach my $dependant_column ( @{$renderer->{dependant_columns}} ) {
                $self->refresh_dynamic_combos( $renderer, $treepath );
            }
        }
    }
    
    # As of gtk+-2.8.19 ( or so ), this DOES NOT WORK if you have a CellRendererDate as the 1st column
    # ( after the status column, of course ). I don't know why. I've posted to the gtk-devel list,
    # but it seems like a bit of a corner-case. Perhaps someone else knows what's up.
    #$self->{treeview}->set_cursor( $model->get_path($iter), $self->{columns}[1], 1 );
    
    # This, however, works :)
    $self->{treeview}->set_cursor( $model->get_path($iter), $self->{fields}[0]->{treeview_column}, 0 );
    
    # Now scroll the scrolled window to the end
    # Using an idle timer is required because gtk needs time to add the new row ...
    #  ... if we don't use an idle timer, we end up scrolling to the 2nd-last row
    
    # TODO: Gtk3 - adjustments are different - don't have "upper" method any more
    #Glib::Idle->add( sub {
    #    my $adjustment = $self->{treeview}->get_vadjustment;
    #    my $upper = $adjustment->upper;
    #    $adjustment->set_value( $upper - $adjustment->page_increment - $adjustment->step_increment );
    #} );
    
    if ( $self->{on_insert} ) {
        $self->{on_insert}();
    }
    
    return TRUE;
    
}

sub delete {
    
    my $self = shift;
    
    if ( $self->{read_only} ) {
        $self->dialog(
            {
                title   => "Read Only!",
                type    => "warning",
                text    => "Datasheet is open in read-only mode!"
            }
        );
        return FALSE;
    }
    
    # We only mark the selected record for deletion at this point
    my ( $selected_paths, $model ) = $self->{treeview}->get_selection->get_selected_rows;
    my $model = $self->{treeview}->get_model;
    
    for my $path ( @{$selected_paths} ) {
        my $iter = $model->get_iter( $path );
        # Prevent people from deleting locked records
        if ( $self->{data_lock_field} && $model->get( $iter, $self->column_from_sql_name( $self->{data_lock_field} ) ) ) {
            next;
        }
        $model->set( $iter, STATUS_COLUMN, DELETED );
    }
    
    return TRUE;
    
}

sub lock {
    
    # Locks the current record from further edits
    
    my $self = shift;
    
    if ( ! $self->{data_lock_field} ) {
        warn "\nGtk3::Ex::DBI::Datasheet::lock called without having a data_lock_field defined!\n";
        return FALSE;
    }
    
    $self->set_column_value( $self->{data_lock_field}, 1 );
    
    # Apply it ( which will implement the lock )
    if ( ! $self->apply ) {
        $self->dialog(
            {
                title   => "Failed to lock record!",
                icon    => "error",
                text    => "There was an error applying the current record.\n"
                                . "The lock operation has been aborted."
            }
        );
        $self->set_column_value( $self->{data_lock_field}, 0 ); # Reset the lock column
        return FALSE;
    }
    
    return TRUE;
    
}

sub unlock {
    
    # Unlocks the current record
    
    my $self = shift;
    
    if ( ! $self->{data_lock_field} ) {
        warn "\nGtk3::Ex::DBI::Datasheet::unlock called without having a data_lock_field defined!\n";
        return FALSE;
    }
    
    # Unset the lock field 
    $self->set_column_value( $self->{data_lock_field}, 0 );
    
    # Set the STATUS indicator ( which actually implements the lock )
    my ( $path, $column ) = $self->{treeview}->get_cursor;
    my $model = $self->{treeview}->get_model;
    my $iter = $model->get_iter( $path );
    $model->set( $iter, STATUS_COLUMN, CHANGED );
    
    if ( ! $self->apply ) {
        $self->dialog(
            {
                title   => "Failed to unlock record!",
                type    => "error",
                text    => "There was an error applying the current record.\n"
                                . "The unlock operation has been aborted."
            }
        );
        $self->set_column_value( $self->{data_lock_field}, 1 ); # Removes our changes to the lock column
        $model->set( $iter, STATUS_COLUMN, LOCKED );
        return FALSE;
    }
    
    return TRUE;
    
}

sub on_size_allocate {
    
    my ( $self, $widget, $rectangle, $treeview_type ) = @_;
    
    if ( $self->{ $treeview_type . "_current_width" } != $rectangle->{width} ) { # TODO Remove on_size_allocate blocking workaround when blocking actually works
        
        # Absolute values are calculated in setup_treeview as they only have to be calculated once
        # We take the sum of the absolute values away from the width we've just been passed, and *THEN*
        # allocate the remainder to fields according to their x_percent values
        
        my $available_x = $rectangle->{width} - $self->{sum_absolute_x};
        
        $self->{ $treeview_type . "_current_width" } = $rectangle->{width};
        
        # TODO Resize signal blocking doesn't currently work ( completely )
        $self->{ $treeview_type }->signal_handler_block( $self->{ $treeview_type . "_resize_signal" } );
        
        for my $field ( @{$self->{fields}} ) {
            
            if ( $field->{x_percent} ) { # Only need to set ones that have a percentage
                $field->{current_width} = $available_x * ( $field->{x_percent} / 100 );
                # TODO Figure out why we're getting very small values when constructing our own treeview
                # and avoid this some other way ... this works, but ... hmmmmm
                if ( $field->{current_width} < 1 ) {
                    $field->{current_width} = 1;
                }
                Glib::Idle->add( sub {
                    $field->{ $treeview_type . "_column" }->set_fixed_width( $field->{current_width} );
                    if ( $field->{wrap_text} ) {
                        $field->{treeview_column}->{renderer}->set( 'wrap-width', $field->{current_width} );
                    }
                    return FALSE;
                } );
            }
            
        }
        
        # TODO Blocking resize signals doesn't currently work ( completely )
        $self->{ $treeview_type }->signal_handler_unblock( $self->{ $treeview_type . "_resize_signal" } );
        
    }
    
    if ( $self->{after_size_allocate} ) {
        # TODO Document after_size_allocate()? Or Remove?
        # Still could be handy, especially for setting up headers ( ie multi-row headers )
        $self->{after_size_allocate}();
    }
    
    return FALSE;
    
}

sub on_expose_event {
    
    my ( $self, $widget, $expose, $treeview_type ) = @_;
    
    # We set up the label alignment when an expose_event is triggered
    # ( ie when the treeview is rendered )
    # because the label doesn't ( apparently ) exist before this
    # ( ie if the treeview isn't visible ... on a notebook page that isn't selected, etc )
    
    for my $field ( @{$self->{fields}} ) {
        
        if ( $field->{renderer} eq "dynamic_model" ) {
            next;
        }
        
        my $label = $field->{ $treeview_type . "_column" }->get_widget;
        
        if ( $label ) {
                
            # TODO Support user-defined alignment of header text
            # Alignment
            $label->get_parent->set( 0.5, 0.5, 1, 1 );
            
            # Markup
            if ( exists $field->{header_markup} ) {
                $label->set_justify( 'center' );
                $label->set_markup( $field->{header_markup} );
            }
            
        }
        
    }
    
    $self->{ $treeview_type }->signal_handler_disconnect( $self->{ $treeview_type . "_expose_signal" } );
    
    return FALSE;
    
}

sub column_from_name {
    
    my ( $self, $sql_fieldname ) = @_;
    
    # Legacy support of stoopid function name
    return $self->column_from_sql_name( $sql_fieldname );
    
}

sub column_from_sql_name {
    
    # Take an *SQL* field name and return the column that the field is in
    
    my ( $self, $sql_fieldname ) = @_;
    
    my $counter = 0;
    
    for my $field ( @{$self->{fieldlist}} ) {
        if ( $field eq $sql_fieldname ) {
            return $counter;
        }
        $counter ++;
    }
    
}

sub column_from_column_name {
    
    # Take a *COLUMN* name and returns the column that the field is in
    
    my ( $self, $column_name ) = @_;
    
    if ( exists $self->{column_name_to_number_mapping}->{ $column_name } ) {
        return $self->{column_name_to_number_mapping}->{ $column_name };
    } else {
        warn "Gtk3::Ex::DBI::Datasheet->column_from_column_name called with an unknown column name! ( $column_name )\n";
        return -1;
    }
    
}

sub column_name_to_sql_name {
    
    # This function converts a column name to an SQL field name
    
    my ( $self, $column_name ) = @_;
    
    my $column_no = $self->column_from_column_name ( $column_name );
    return $self->{fieldlist}[$column_no];
    
}

sub column_value {
    
    # This sub has been renamed to get_column_value, and is here for legacy support
    
    my ( $self, $sql_fieldname ) = @_;
    
    return $self->get_column_value( $sql_fieldname );
    
}

sub get_column_value {
    
    # This function returns the value in the requested column in the currently selected row
    # If multi_select is turned on and more than 1 row is selected, it looks in the 1st row
    
    my ( $self, $sql_fieldname ) = @_;
    
    my ( $selected_paths, $model ) = $self->{treeview}->get_selection->get_selected_rows;
    
    # Gtk2 used to return an array ( possibly empty ). Gtk3 seems to be returning undef instead of empty array
    if ( ! $selected_paths || ! scalar( @{$selected_paths} ) ) {
        return 0;
    }
    
    my @selected_values;
    
    foreach my $selected_path ( @{$selected_paths} ) {
        
        my $column_no = $self->column_from_name( $sql_fieldname );
        my $value = $model->get( $model->get_iter( $selected_path ), $column_no );
        
        # Strip out dollars and commas for numeric columns
        # We *don't* look for a number column with currency turned on,
        # because sometimes you don't want to display currency formatting,
        # and in this case, we still want to strip out currency formatting
        # if people have entered it into a cell
        
        if ( exists $self->{fields}[$column_no]->{number} && $self->{fields}[$column_no]->{number} ) {
            $value =~ s/[\$\,\%]//g;
            if ( exists $self->{fields}[$column_no]->{number}->{percentage} && $self->{fields}[$column_no]->{number}->{percentage} ) {
                $value *= 100;
            }
        }
        
        push @selected_values, $value;
        
    }
    
    # Previous behaviour was to only return the 1st selected value
    # To preserve backwards compatibility, we return a scalar if multi_select is off,
    # and we return an array if multi_select is turned on
    if ( $self->{multi_select} ) {
        return @selected_values;
    } else {
        return $selected_values[0];
    }
    
}

sub set_column_value {
    
    # This function sets the value in the requested column in the currently selected row
    
    my ( $self, $sql_fieldname, $value ) = @_;
    
    if ( $self->{mult_select} ) {
        warn "Gtk3::Ex::DBI::Datasheet->set_column_value called with multi_select enabled!\n"
            . " ... setting value in 1st selected row\n";
    }
    
    my ( $selected_paths, $model ) = $self->{treeview}->get_selection->get_selected_rows;
    
    if ( ! scalar( @{$selected_paths} ) ) {
        return 0;
    }
    
    my $model = $self->{treeview}->get_model;
    my $iter = $model->get_iter( $$selected_paths[0] );
    
    $model->set(
        $iter,
        $self->column_from_name( $sql_fieldname ),
        $value
    );
    
    return TRUE;
    
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
        # The below works for MySQL and SQL Server, and possibly others
        
        my $sth = $self->{dbh}->prepare('select @@IDENTITY');
        $sth->execute;
        
        if ( my $row = $sth->fetchrow_array ) {
            $primary_key = $row;
        } else {
            $primary_key = undef;
        }
        
    }
    
    return $primary_key;
    
}

sub replace_combo_model {
    
    # This function replaces a *normal* combo ( NOT a dynamic one ) with a new one
    
    my ( $self, $column_no, $model ) = @_;
    
    my $column = $self->{treeview}->get_column($column_no);
    my $renderer = ($column->get_cells)[0];
    $renderer->set( model => $model );
    
    return TRUE;
    
}

sub create_dynamic_model {
    
    # This function accepts a combo definition and a row of data ( *MINUS* the record status column ),
    # and creates a combo model to insert back into the main TreeView's model
    # We currently only support a model with 2 columns: an ID column and a Display column
    
    # TODO create_dynamic_model: Support adding more columns to the model
    
    my ( $self, $model_setup, $data ) = @_;
    
    # Firstly we clone the database handle, as the DBD::ODBC / FreeTDS combo won't allow
    # multiple active statements on the same connection
    
    # TODO Test for the DBD::ODBC driver type so we don't clone the dbh unless we need to
    
    my $dbh = $self->{dbh}->clone;
    
    my $liststore = Gtk3::ListStore->new(
        "Glib::String",
        "Glib::String"
    );
    
    # Deal with legacy mode
    my $legacy_warnings;
    
    if ( $model_setup->{table} ) {
        $model_setup->{from} = $model_setup->{table};
        $legacy_warnings .= " - \$model_setup->{table} renamed to \$model_setup->{from} for consistency\n";
    }
    
    if ( $model_setup->{order_by} && $model_setup->{order_by} =~ m/^order by /i ) {
        $model_setup->{order_by} =~ s/^order by //i;
        $legacy_warnings .= " - ommit the words \'order by\' from \$model_setup->{order_by}\n";
    }
    
    if ( $model_setup->{group_by} && $model_setup->{group_by} =~ m/^group by /i ) {
        $model_setup->{group_by} =~ s/^group by //i;
        $legacy_warnings .= " - ommit the words \'order by\' from \$model_setup->{group_by}\n";
    }
    
    if ( $legacy_warnings ) {
        print "Gtk3::Ex::DBI::Datasheet::create_dynamic_model raised the following warnings:\n$legacy_warnings\n";
    }
    
    my $sql = "select " . $model_setup->{id} . ", " . $model_setup->{display} . " from " . $model_setup->{from};
    my @bind_variables;
    
    if ( $model_setup->{criteria} ) {
        $sql .= " where";
        for my $criteria ( @{$model_setup->{criteria}} ) {
            $sql .= " " . $criteria->{field} . "=? and";
            #push @bind_variables, $$data[$self->column_from_name( $criteria->{column_name} ) - 1];
            push @bind_variables, $$data[ $self->column_from_name( $criteria->{column_name} ) ];
        }
    }
    
    $sql = substr( $sql, 0, length($sql) - 3 ); # Remove trailing 'and'
    
    if ( $model_setup->{group_by} ) {
        $sql .= " " . $model_setup->{group_by};
    }
    
    if ( $model_setup->{order_by} ) {
        $sql .= " order by " . $model_setup->{order_by};
    }
    
    my $sth;
    
    eval {
        $sth = $dbh->prepare( $sql ) || die $dbh->errstr;
    };
    
    if ( $@ ) {
        my $escaped = Glib::Markup::escape_text( $@ );
        $self->dialog(
            {
                title   => "Error creating combo model!",
                type    => "error",
                text    => "<b>Database Server Says:</b>\n\n$escaped"
            }
        );
        if ( $self->{dump_on_error} ) {
            print "SQL was:\n\n$sql\n\n";
        }
        return FALSE;
    }
    
    $sth->execute( @bind_variables );
    
    my $iter;
    
    while ( my @record = $sth->fetchrow_array ) {
        $iter = $liststore->append;
        $liststore->set(
            $iter,
            0, $record[0],
            1, $record[1]
        );
    }
    
    $sth->finish;
    $dbh->disconnect;
    
    return $liststore;
    
}

sub setup_combo {
    
    # Convenience function that creates / refreshes a combo's model
    
    my ( $self, $combo_name ) = @_;
    
    my $column_no = $self->column_from_column_name($combo_name);
    
    my $combo = $self->{fields}[$column_no]->{model_setup};
    
    # For SQL Server, we clone a connection, as I've had issues with multiple
    # active statement handles. This will probably also affect Netezza as well,
    # but for now, I'm just adding cloning for SQL Server
    
    my ( $local_dbh , $cloned );
    
    if ( lc($self->{server}) eq "sqlserver" ) {
        if ( exists $combo->{alternate_dbh} ) {
            $local_dbh = $combo->{alternate_dbh}->clone;
        } else {
            $local_dbh = $self->{dbh}->clone;
        }
        $cloned = 1;
    } else {
        if ( exists $combo->{alternate_dbh} ) {
            $local_dbh = $combo->{alternate_dbh};
        } else {
            $local_dbh = $self->{dbh};
        }
    }
    
    
    if ( ! $combo->{sql} ) {
        warn "\nMissing an SQL object in the combo definition for $combo_name!\n\n";
        return FALSE;
    } elsif ( ! $combo->{sql}->{from} ) {
        warn "\nMissing the 'from' key in the sql object in the combo definition for $combo_name!\n\n";
        return FALSE;
    }
    
    # Assemble items for liststore and SQL to get the data
    my ( @liststore_def, $sql );
    
    $sql = "select";
    
    foreach my $field ( @{$combo->{fields}} ) {
        push @liststore_def, $field->{type};
        $sql .= " $field->{name},";
    }
    
    chop( $sql );
    
    $sql .= " from $combo->{sql}->{from}";
    
    if ( $combo->{sql}->{where_object} ) {
        if ( ! $combo->{sql}->{where_object}->{bind_variables} && ! $self->{quiet} ) {
            carp( "Gtk3::Ex::DBI::Datasheet::setup_combo called with a where clause but *WITHOUT* an array of variables to bind!\n"
                . " While this method is supported, it is a security hazard. *PLEASE* take advantage of our support of bind variables\n" );
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
        my $escaped = Glib::Markup::escape_text( $@ );
        $self->dialog(
            {
                title   => "Error setting up combo box: $combo_name",
                icon    => "error",
                text    => "<b>Database Server Says:</b>\n\n$escaped"
            }
        );
        return FALSE;
    }
    
    # We have to use 'exists' here, otherwise we inadvertently create the where_object hash,
    # just by testing for it ... ( or by testing for bind_variables anyway )
    if ( exists $combo->{sql}->{where_object} && exists $combo->{sql}->{where_object}->{bind_variables} ) {
        eval {
                $sth->execute( @{$combo->{sql}->{where_object}->{bind_variables}} )
                    || die $local_dbh->errstr;
        };
    } else {
        eval {
                $sth->execute || die $local_dbh->errstr;
        };
    }
    
    if ( $@ ) {
        my $escaped = Glib::Markup::escape_text( $@ );
        $self->dialog(
            title   => "Error setting up combo box: $combo_name",
            icon    => "error",
            text    => "<b>Database Server Says:</b>\n\n$escaped\n\n"
                        . "Check the definintion of the table:"
                        . " $combo->{sql}->{from}"
        );
        return FALSE;
    }
    
    # Create the model
    my $model = Gtk3::ListStore->new( @liststore_def );
    
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
    
    if ( $cloned ) {
        $local_dbh->disconnect;
    }
    
    # Connect the model to the widget
    $self->replace_combo_model( $column_no, $model );
    
    return TRUE;
    
}

sub any_changes {
    
    # This function loops through all records and returns TRUE if any record status is not UNCHANGED
    
    my $self = shift;
    
    my $model = $self->{treeview}->get_model;
    my $iter = $model->get_iter_first;
    
    while ( $iter ) {
        my $status = $model->get( $iter, STATUS_COLUMN );
        if ( $status == UNCHANGED || $status == LOCKED ) {
            if ( ! $model->iter_next( $iter ) ) {
                last;
            } else {
                next;
            }
        } else {
            return TRUE;
        }
    }
    
    return FALSE;
    
}

sub sum_column {
    
    # This function returns the sum of all values in the given column
    my ( $self, $column_no, $conditions ) = @_;
    
    my $model = $self->{treeview}->get_model;
    my $iter = $model->get_iter_first;
    my $total = 0;
    
    if ( $conditions ) {
        if ( ! ( exists $conditions->{column} && exists $conditions->{operator} && exists $conditions->{value} ) ) {
            warn "Gtk3::Ex::DBI::Datasheet->sum_column() called with an incomplete conditions hash ..."
                    . " ... must have 'column', 'operator' and 'value' keys to conditions hash!\n\n";
            return 0;
        }
    }
    
    while ( $iter ) {
        
        # Get the column value, strip out dollar signs and commas, and then figure out what to do ...
        my $value = $model->get( $iter, $column_no );
        
        if ( exists $self->{fields}[$column_no]->{treeview_column}->{definition}->{number}->{currency}
                && $self->{fields}[$column_no]->{treeview_column}->{definition}->{number}->{currency} ) {
            $value =~ s/[\$\,]//g;
        }
        
        if ( $conditions ) {
            
            my $test_value = $model->get( $iter, $conditions->{column} );
            
            if ( exists $self->{fields}[$conditions->{column}]->{treeview_column}->{definition}->{number}->{currency}
                    && $self->{fields}[$conditions->{column}]->{treeview_column}->{definition}->{number}->{currency} ) {
                $test_value =~ s/[\$\,]//g;
            }
            
            if ( $conditions->{operator} eq "==" ) {
                if ( $test_value == $conditions->{value} ) {
                    $total += $value;
                }
            } elsif ( $conditions->{operator} eq "<" ) {
                if ( $test_value < $conditions->{value} ) {
                    $total += $value;
                }
            } elsif ( $conditions->{operator} eq ">" ) {
                if ( $test_value > $conditions->{value} ) {
                    $total += $value;
                }
            } elsif ( $conditions->{operator} eq "eq" ) {
                if ( $test_value eq $conditions->{value} ) {
                    $total += $value;
                }
            } else {
                warn "Gtk3::Ex::DBI::Datasheet->sum_column() called with an invalid operator in the condition ...\n"
                    . " ... operator: $conditions->{operator}\n\n";
            }
        } else {
            $total += $value;
        }
        if ( ! $model->iter_next( $iter ) ) {
            last;
        }
    }
    
    return $total;
    
}

sub max_column {
    
    my ( $self, $column_no ) = @_;
    
    # This function returns the MAXIMUM value in a given column
    
    my $model = $self->{treeview}->get_model;
    my $iter = $model->get_iter_first;
    my $max = 0;
    
    while ( $iter ) {
        
        # Get the column value, strip out dollar signs and commas
        my $value = $model->get( $iter, $column_no );
        
        if ( exists $self->{fields}[$column_no]->{treeview_column}->{definition}->{number}->{currency}
                && $self->{fields}[$column_no]->{treeview_column}->{definition}->{number}->{currency} ) {
            $value =~ s/[\$\,]//g;
        }
        
        $max = $value > $max ? $value : $max;
        
        if ( ! $model->iter_next( $iter ) ) {
            last;
        }
        
    }
    
    return $max;
    
}

sub average_column {
    
    my ( $self, $column_no ) = @_;
    
    # This function returns the AVERAGE value in a given column
    
    my $model = $self->{treeview}->get_model;
    my $iter = $model->get_iter_first;
    my $total = 0;
    my $counter = 0;
    
    while ( $iter ) {
        
        # Get the column value, strip out dollar signs and commas
        my $value = $model->get( $iter, $column_no );
        
        if ( exists $self->{fields}[$column_no]->{treeview_column}->{definition}->{number}->{currency}
                && $self->{fields}[$column_no]->{treeview_column}->{definition}->{number}->{currency} ) {
            $value =~ s/[\$\,]//g;
        }
        
        $total += $value;
        $counter ++;
        
        if ( ! $model->iter_next( $iter ) ) {
            last;
        }
        
    }
    
    return $counter ? $total / $counter : undef;
    
}

sub count {
    
    # This function returns the number of all records ( optionally where $column_no matches $conditions )
    
    my ( $self, $column_no, $conditions ) = @_;
    
    my $model = $self->{treeview}->get_model;
    my $iter = $model->get_iter_first;
    my $count = 0;
    
    if ( $conditions ) {
        if ( ! ( exists $conditions->{column} && exists $conditions->{operator} && exists $conditions->{value} ) ) {
            warn "Gtk3::Ex::DBI::Datasheet->count() called with an incomplete conditions hash ..."
                    . " ... must have 'column', 'operator' and 'value' keys to conditions hash!\n\n";
            return 0;
        }
    }
    
    while ( $iter ) {
        
        if ( $conditions ) {
            
            my $this_value = $model->get( $iter, $conditions->{column} );
            
            if ( $self->{fields}[$column_no]->{treeview_column}->{definition}->{number}->{currency}
                    && $self->{fields}[$column_no]->{treeview_column}->{definition}->{number}->{currency} ) {
                $this_value =~ s/[\$\,]//g;
            }
            
            if ( $conditions->{operator} eq "==" ) {
                if ( $this_value == $conditions->{value} ) {
                    $count ++;
                }
            } elsif ( $conditions->{operator} eq "<" ) {
                if ( $this_value < $conditions->{value} ) {
                    $count ++;
                }
            } elsif ( $conditions->{operator} eq ">" ) {
                if ( $this_value > $conditions->{value} ) {
                    $count ++;
                }
            } elsif ( $conditions->{operator} eq "eq" ) {
                if ( $this_value eq $conditions->{value} ) {
                    $count ++;
                }
            } else {
                warn "Gtk3::Ex::DBI::Datasheet->count() called with an invalid operator in the condition ...\n"
                    . " ... operator: $conditions->{operator}\n\n";
            }
        } else {
            $count ++;
        }
        
        if ( ! $model->iter_next( $iter ) ) {
            last;
        }
        
    }
    
    return $count;
    
}

sub parse_sql_server_default {
    
    # This sub parses the string returned by SQL Server as the DEFAULT value for a given field
    
    my ( $self, $sqlserver_default ) = @_;
    
    # Find the last space in the string
    my $final_space_position = rindex( $sqlserver_default, " " );
    
    if ( ! $final_space_position || $final_space_position == -1 ) {
        # Bail out, returning undef.
        # We can't use the current default value ( as it's a string definition ), so we might as well just drop it completely
        warn "Gtk3::Ex::DBI->parse_sql_server_default failed to find the last space character in the DEFAULT definition:\n$sqlserver_default\n";
        return undef;
    } else {
        # We've got the final space character. Now get everything to the right of it ...
        my $default_value = substr( $sqlserver_default, $final_space_position + 1, length( $sqlserver_default ) - $final_space_position - 1 );
        #  ... and strip off any quotes
        $default_value =~ s/'//g;
        return $default_value;
    }
    
}

sub calculator {
    
    # This pops up a simple addition-only calculator, and returns the calculated value to the calling widget
    
    my ( $self, $column_name ) = @_;
    
    my $dialog = Gtk3::Dialog->new(
        "Gtk2::Ex::DBI calculator",
        undef,
        "modal",
        "gtk-ok"        => "ok",
        "gtk-cancel"    => "reject"
    );
    
    $dialog->set_default_size( 300, 480 );
    
    # The model
    my $model = Gtk3::ListStore->new( "Glib::Double" );
    
    # Add an initial row data to the model
    my $iter = $model->append;
    $model->set( $iter, 0, 0 );
    
    # A renderer
    my $renderer = Gtk3::CellRendererText->new;
    $renderer->set(
        editable    => TRUE,
        xalign      => 1
    );
    
    # A column
    my $column = Gtk3::TreeViewColumn->new_with_attributes(
        "Values",
        $renderer,
        'text'  => 0
    );
    
    # The TreeView
    my $treeview = Gtk3::TreeView->new( $model );
    $treeview->set_rules_hint( TRUE );
    $treeview->append_column($column);
    
    # A scrolled window to put the TreeView in
    my $sw = Gtk3::ScrolledWindow->new( undef, undef );
    $sw->set_shadow_type( "etched-in" );
    
    $sw->set_policy( "automatic", "always" );
    
    # Add treeview to scrolled window
    $sw->add( $treeview );
    
    # Add scrolled window to the dialog
    $dialog->vbox->pack_start( $sw, TRUE, TRUE, 0 );
    
    # Add a Gtk3::Entry to show the current total ...
    my $total_widget = Gtk3::Entry->new;
    $total_widget->set_alignment( 1 );
    
    # ... and a toggle button to strip GST
    my $gst_toggle = Gtk3::ToggleButton->new_with_label( "Strip GST" );
    $gst_toggle->signal_connect( toggled    => sub {
        
        my ( $widget, $signal, $something ) = @_;
        
        # Add up all the items in the model
        my $iter = $model->get_iter_first;
        my $current_total;
        
        while ( $iter ) {
            $current_total += $model->get( $iter, 0 );
            if ( ! $model->iter_next( $iter ) ) {
                last;
            }
        }
        
        if ( $widget->get_active ) {
            $current_total = $current_total / 11 * 10;
        }
        
        # Allow for our number of decimal places
        $current_total *= 10 ** 2;
        
        # Round
        $current_total = int( $current_total + .5 * ( $current_total <=> 0 ) );
        
        # Get decimals back
        $current_total /= 10 ** 2;
        
        $total_widget->set_text( $current_total );
        
    } );
    
    my $total_hbox = Gtk3::HBox->new( 1, 5 );
    $total_hbox->pack_start( $gst_toggle, TRUE, TRUE, 0 );
    $total_hbox->pack_start( $total_widget, TRUE, TRUE, 0 );
    
    $dialog->vbox->pack_start( $total_hbox, FALSE, FALSE, 0 );
    
    # Handle editing in the renderer
    $renderer->signal_connect_after( edited => sub {
        
        #$self->calculator_process_editing( @_, $treeview, $model, $column, $total_widget );
        
        my ( $renderer, $text_path, $new_text ) = @_;
        
        my $path = Gtk3::TreePath->new_from_string ($text_path);
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
            if ( ! $model->iter_next( $iter ) ) {
                last;
            }
        }
        
        if ( $gst_toggle->get_active ) {
            $current_total = $current_total / 11 * 10;
        }
        
        # Allow for our number of decimal places
        $current_total *= 10 ** 2;
        
        # Round
        $current_total = int( $current_total + .5 * ( $current_total <=> 0 ) );
        
        # Get decimals back
        $current_total /= 10 ** 2;
        
        $total_widget->set_text( $current_total );
        
    } );
    
    # Show everything
    $dialog->show_all;
    
    # Start editing in the 1st row
    $treeview->set_cursor( $model->get_path( $iter ), $column, TRUE );
    
    my $response = $dialog->run;
    
    if ( $response eq "ok" ) {
        # Transfer value back to calling widget and exit
        $self->set_column_value( $self->column_name_to_sql_name( $column_name ), $total_widget->get_text );
        $dialog->destroy;
    } else {
        $dialog->destroy;
    }
    
}

sub data_to_csv {
    
    my ( $self, $options ) = @_;
    
    if ( ! $options->{destination} ) {
        # TODO: Gtk3 FileChooser
        $options->{destination} = $self->file_chooser(
            {
                title           => "Please choose a destination"
              , action          => "save"
              , type            => "file"
              , text            => "Please choose a destination file"
            }
        );
    }
    
    if ( ! $options->{destination} ) {
        # That's it. Bail.
        return FALSE;
    }
    
    my $progress_bar = $options->{progress_bar};
    
    my $csv_file;
    
    my $writing_directive = ">";
    
    if ( $options->{encoding} ) {
        $writing_directive .= ":encoding(" . $options->{encoding} . ")";
    }
    
    eval {
        open $csv_file, $writing_directive, $options->{destination}
            or die "Unable to open $options->{destination}: $!";
    };
    
    if ( $@ ) {
        my $escaped = Glib::Markup::escape_text( $@ );
        $self->dialog(
            {
                title           => "Error opening destination file",
                type            => "error",
                text            => "I failed to open the destination file $options->{destination} for writing.\n"
                                    . "Permission problem?\n$escaped"
            }
        );
        return FALSE;
    }
    
    my $delimiter = exists $options->{delimiter} ? $options->{delimiter} : ",";
    
    # If we haven't been passed an array of columns, construct one ...
    if ( ! exists $options->{columns} ) {
        foreach my $field ( @{$self->{fields}} ) {
            if ( $field->{column} ) { # Skip the status column
                push @{$options->{columns}}, $field->{column};
            }
        }
    }
    
    my $line;
    
    if ( ! $options->{use_old_csv_writer} ) {
        
        require Text::CSV;
        
        my $csv_writer = Text::CSV->new(
            {
                quote_char              => '"'
              , binary                  => 1
              , eol                     => "\n"
              , sep_char                => $delimiter
              , escape_char             => '\\'
              , quote_space             => 1
              , blank_is_undef          => 1
              , quote_null              => 0
              , always_quote            => 1
            }
        );
        
        my $field_names_array;
        
        foreach my $column_no ( @{$options->{columns}} ) {
            push @{$field_names_array}, $self->{fields}[$column_no]->{name};
        }
        
        $csv_writer->print( $csv_file, $field_names_array );
        
        my $counter;
        
        # Now the data
        my $model = $self->{treeview}->get_model;
        my $iter = $model->get_iter_first;
        
        while ( $iter ) {
            
            my $record;
            $counter ++;
            
            foreach my $column_no ( @{$options->{columns}} ) {
                push @{$record}, $model->get( $iter, $column_no );
            }
            
            $csv_writer->print( $csv_file, $record );
            
            if ( $progress_bar ) {
                $progress_bar->set_text( $counter );
                $progress_bar->pulse;
                Gtk3::main_iteration while ( Gtk3::events_pending );
            }
            
            if ( ! $model->iter_next( $iter ) ) {
                last;
            }
            
        };
        
    } else {
        
        # First print a line of column headers
        foreach my $column_no ( @{$options->{columns}} ) {
            $line .= $self->{fields}[$column_no]->{name} . $delimiter;
        }
        
        chop $line;
        
        print $csv_file "$line\n";
        
        # Now the data
        my $model = $self->{treeview}->get_model;
        my $iter = $model->get_iter_first;
        
        while ( $iter ) {
            my $line;
            foreach my $column_no ( @{$options->{columns}} ) {
                my $value = $model->get( $iter, $column_no );
                if ( exists $self->{fields}[$column_no]->{number}
                        && $self->{fields}[$column_no]->{number} ) {
                            $value =~ s/[\$\,]//g;
                }
                if ( $options->{wrapper} ) {
                    $line .= $options->{wrapper} . $value . $options->{wrapper} . $delimiter;
                } else {
                    $line .= $value . $delimiter;
                }
            }
            chop $line;
            print $csv_file "$line\n";
            if ( ! $model->iter_next( $iter ) ) {
                last;
            }
        }
        
    }
    
    close $csv_file;
    
    # TODO: update status indicator with number of records dumped
    
    return TRUE;
    
}

sub data_to_array {
    
    my ( $self, $options ) = @_;
    
    # Convert column names to columns
    if ( exists $options->{column_names} ) {
        foreach my $column_name ( @{$options->{column_names}} ) {
            push @{$options->{columns}}, $self->{column_name_to_number_mapping}->{ $column_name };
        } 
    }
    
    # If we don't have an array of columns, construct one ...
    if ( ! exists $options->{columns} ) {
        foreach my $field ( @{$self->{fields}} ) {
            if ( $field->{column} ) { # Skip status column
                push @{$options->{columns}}, $field->{column};
            }
        }
    }
    
    my $model = $self->{treeview}->get_model;
    my $iter = $model->get_iter_first;
    my @records;
    
    while ( $iter ) {
        my @record;
        foreach my $column_no ( @{$options->{columns}} ) {
            my $value = $model->get( $iter, $column_no );
            if ( exists $self->{fields}[$column_no]->{number}
                    && $self->{fields}[$column_no]->{number} ) {
                $value =~ s/[\$\,]//g;
            }
            push @record, $value;
        }
        push @records, [ @record ];
        if ( ! $model->iter_next( $iter ) ) {
            last;
        }
    }
    
    return \@records;
    
}

sub custom_sort {
    
    my ( $self, $treeview, $iter_a, $iter_b, $something_unknown, $sort_column, $sort_type ) = @_;
    
    my $data_a = $treeview->get( $iter_a, $sort_column );
    my $data_b = $treeview->get( $iter_b, $sort_column );
    
    if ( $sort_type eq "numeric" ) {
        
        # Strip out dollar signs and commas
        $data_a =~ s/\$|,//g;
        $data_b =~ s/\$|,//g;
        return $data_a <=> $data_b;
        
    } elsif ( $sort_type eq "date" ) {
        
        # Split dates into year, month, day
        my ( $yyyy_a, $mm_a, $dd_a ) = split /-/, $data_a;
        my ( $yyyy_b, $mm_b, $dd_b ) = split /-/, $data_b;
        
        if ( $yyyy_a <=> $yyyy_b ) {
            return $yyyy_a <=> $yyyy_b;
        }
        
        if ( $mm_a <=> $mm_b ) {
            return $mm_a <=> $mm_b;
        }
        
        return $dd_a <=> $dd_b;
        
    }
    
}

sub select_rows {
    
    # This function selects rows in a datasheet based on stuff in the $conditions hash
    
    my ( $self, $conditions ) = @_;
    
    # TODO DOCUMENT select_rows() !!!
    
    # $conditions contains:
    #  - column_no
    #  - operator
    #  - value
    
    my $model = $self->{treeview}->get_model;
    my $iter = $model->get_iter_first;
    
    if ( $conditions ) {
        if ( ! ( exists $conditions->{column_no} && exists $conditions->{operator} && exists $conditions->{value} ) ) {
            warn "Gtk3::Ex::DBI::Datasheet->select_rows() called with an incomplete conditions hash ..."
                    . " ... must have 'column_no', 'operator' and 'value' keys to conditions hash!\n\n";
            return FALSE;
        }
    }
    
    my $matched_rows = 0;
    
    while ( $iter ) {
        my $this_value = $model->get( $iter, $conditions->{column_no} );
        if ( $self->{fields}[$conditions->{column_no}]->{treeview_column}->{definition}->{number}->{currency}
                && $self->{fields}[$conditions->{column_no}]->{treeview_column}->{definition}->{number}->{currency} ) {
            $this_value =~ s/[\$\,]//g;
        }
        if ( $conditions->{operator} eq "==" ) {
            if ( $this_value == $conditions->{value} ) {
                $self->{treeview}->get_selection->select_iter( $iter );
                $matched_rows ++;
            }
        } elsif ( $conditions->{operator} eq "<" ) {
            if ( $this_value < $conditions->{value} ) {
                $self->{treeview}->get_selection->select_iter( $iter );
                $matched_rows ++;
            }
        } elsif ( $conditions->{operator} eq ">" ) {
            if ( $this_value > $conditions->{value} ) {
                $self->{treeview}->get_selection->select_iter( $iter );
                $matched_rows ++;
            }
        } elsif ( $conditions->{operator} eq "eq" ) {
            if ( $this_value eq $conditions->{value} ) {
                $self->{treeview}->get_selection->select_iter( $iter );
                $matched_rows ++;
            }
        } else {
            warn "Gtk3::Ex::DBI::Datasheet->select_rows() called with an invalid operator in the condition ...\n"
                . " ... operator: $conditions->{operator}\n\n";
        }
        if ( ! $model->iter_next( $iter ) ) {
            last;
        }
    }
    
    return $matched_rows;
    
}

sub set_header_markup {
    
    my ( $self, $column_name, $markup ) = @_;
    
    $self->{fields}[ $self->{column_name_to_number_mapping}->{ $column_name } ]->{treeview_column}->get_widget->set_markup( $markup );
    
}

sub prepare_report_writer {
    
    my ( $self, $options ) = @_;
    
    eval {
            require PDF::ReportWriter
                || die;
    };
    
    if ( $@ ) {
        carp( "Missing module PDF::ReportWriter" );
        return FALSE;
    }
    
    my $report_fields;
    
    if ( ! exists $options->{fieldname_list} ) {
        # There's no fieldname list; construct one
        foreach my $field ( @{$self->{fields}} ) {
            if (
                ! $field->{column}                                                      # Skip status column
                 || ( $field->{renderer} eq "hidden" && ! $options->{show_all} )        # Skip hidden columns
            ) {
                next;
            }
            push @{$report_fields}, $field;
        }
    } else {
        # Use the provided list
        foreach my $fieldname ( @{$options->{fieldname_list}} ) {
            push @{$report_fields}, $self->{fields}[ $self->{column_name_to_number_mapping}->{$fieldname} ];
        }
    }
    
    # Now loop through all the fields we've got, and do some
    # conversions for PDF::ReportWriter
    # TODO Remove the need for this ...
    foreach my $field ( @{$report_fields} ) {
        
        # TODO Maybe we shouldn't be cross-polluting stuff?
        # We should constuct a NEW definition, not use this one ...
        
        if ( exists $field->{group_results} ) {
            delete $field->{group_results};
        }
        
        if ( exists $field->{grand_aggregate_result} ) {
            delete $field->{grand_aggregate_result};
        }
        
        if ( exists $field->{number} ) {
            # PDF::ReportWriter field definitions use a 'format' hash in the place of our 'number' hash
            $field->{format} = $field->{number};
            delete $field->{number};
        }
        
        # TODO What do we do about x_absolute fields? Should we recalculate
        # all percentages from the treeview?
        $field->{percent} = $field->{x_percent};
        $field->{header_text} = $self->{fields}[ $self->{column_name_to_number_mapping}->{ $field->{name} } ]->{treeview_column}->get_widget->get_text;
        
        if ( exists $field->{footer_function} ) {
            $field->{aggregate_function} = $field->{footer_function}
        }
        
    }
    
    my $data_array = $self->data_to_array(
        {
            column_names    => $options->{fieldname_list}
        }
    );
    
    return {
        fields              => $report_fields,
        data_array          => $data_array
    };
    
}

1;

#######################################################################################
# That's the end of Gtk3::Ex::Datasheet::DBI
# What follows is stuff I've plucked from around the place
#######################################################################################







#######################################################################################
# Custom CellRendererText
#######################################################################################

package Gtk3::Ex::Datasheet::DBI::CellEditableText;

# Copied and pasted from Odot

use strict;
use warnings;

use Glib qw(TRUE FALSE);
use Glib::Object::Subclass
  Gtk3::TextView::,
    interfaces => [ Gtk3::CellEditable:: ]
  , properties => [
                    Glib::ParamSpec->boolean(
                                                    "editing-canceled",
                                                    "Editing canceled",
                                                    "Whether editing has been canceled.",
                                                    FALSE,
                                                    [ qw( readable writable ) ]
                                           )
                ];

sub START_EDITING {
    # do nothing
}

sub EDITING_DONE {
    # do nothing
}

sub REMOVE_WIDGET {
    # do nothing
}

sub set_text {
    
    my ( $editable, $text ) = @_;
    
    $text = "" unless ( defined( $text ) );
    
    $editable->get_buffer()->set_text( $text, length( $text ) );
    
}

sub get_text {
    
    my ( $editable ) = @_;
    my $buffer = $editable->get_buffer();
    
    return $buffer->get_text( $buffer->get_bounds(), TRUE );
    
}

sub select_all {
    
    my ( $editable ) = @_;
    my $buffer = $editable->get_buffer();
    
    my ( $start, $end ) = $buffer->get_bounds();
    $buffer->move_mark_by_name( insert => $start );
    $buffer->move_mark_by_name( selection_bound => $end );
    
}

1;

package Gtk3::Ex::Datasheet::DBI::CellRendererText;

# Originally from Odot, with bits and pieces from the CellRendererSpinButton example,
# and even some of my own stuff worked in :)

use constant x_padding => 2;
use constant y_padding => 3;

use strict;
use warnings;

use Glib qw(TRUE FALSE);

use Glib::Object::Subclass
  Gtk3::CellRendererText::,
  properties => [
                    Glib::ParamSpec->object(
                                                    "editable-widget",
                                                    "Editable widget",
                                                    "The editable that's used for cell editing.",
                                                    Gtk3::Ex::Datasheet::DBI::CellEditableText::,
                                                    [ qw( readable writable ) ]
                                           ),
                    Glib::ParamSpec->boolean(
                                                    "number",
                                                    "Number",
                                                    "Should I apply number formatting to the data?",
                                                    0,
                                                    [ qw( readable writable ) ]
                                            ),
                    Glib::ParamSpec->string(
                                                    "decimals",
                                                    "Decimals",
                                                    "How many decimal places should be displayed?",
                                                    -1,
                                                    [ qw( readable writable ) ]
                                           ),
                    Glib::ParamSpec->boolean(
                                                    "currency",
                                                    "Currency",
                                                    "Should I prepend a dollar sign to the data?",
                                                    0,
                                                    [ qw( readable writable ) ]
                                            )
                ];

sub EDITING_STARTED {
    # do nothing
}

sub START_EDITING {
    
    my ( $cell, $event, $view, $path, $background_area, $cell_area, $flags ) = @_;
    
    if ( $event ) {
        return unless ( $event->button == 1 );
    }
    
    ###
    
    my $editable = Gtk3::Ex::Datasheet::DBI::CellEditableText->new();
    #my $editable = Gtk3::CellEditableText->new();
    
    $editable->set( border_width => $cell->get( "ypad" ) );
    
    $editable->signal_connect( key_press_event => sub {
        
        my ( $editable, $event ) = @_;
        
        if (
            ( $event->keyval == Gtk3::Gdk::KEY_Return || $event->keyval == Gtk3::Gdk::KEY_KP_Enter )
            and not $event-> state & qw(control-mask)
           )
        {
            
            # Grab parent
            my $parent = $editable->get_parent;
            
            $editable->{ _editing_canceled } = FALSE;
            $editable->editing_done();
            $editable->remove_widget();
            
            my ( $path, $focus_column ) = $parent->get_cursor;
            my @cols = $parent->get_columns;
            my $next_col = undef;
            
            foreach my $i (0..$#cols) {
                if ( $cols[$i] == $focus_column ) {
                    if ( $event->state >= 'shift-mask' ) {
                        # go backwards
                        $next_col = $cols[$i-1] if $i > 0;
                    } else {
                        # Go forwards
                        # First check whether the next column is read_only
                        while ( $i-1 < $#cols ) {
                            $i++;
                            if ( ! $cols[$i]->{definition}->{read_only} ) {
                                last;
                            }
                        }
                        $next_col = $cols[$i];
                    }
                    last;
                }
            }
            
            # For some reason, the last item returned by the above call to
            # $parent->get_columns isn't a Gtk3::TreeViewColumn, and therefore
            # the $parent_set_cursor line fails. Avoid this.
            if ( ref $next_col eq 'Gtk3::TreeViewColumn' ) {
                $parent->set_cursor ( $path, $next_col, 1 )
                    if $next_col;
            }
            
            return TRUE;
            
        }
        
        return FALSE;
        
    });
    
    $editable -> signal_connect( editing_done => sub {
       my ( $editable ) = @_;
       my $canceled = $editable->get( 'editing-canceled' );
       # or $editable -> { _editing_canceled } if you store it directly
       $cell->stop_editing( $canceled );
       unless ( $canceled ) {
           $cell->signal_emit( edited => $path, $editable->get_text() );
       }
    });
    
    $cell->set( editable_widget => $editable );
    
    ###
    
    #$editable->modify_font( Pango::FontDescription->from_string( "Arial " . $cell->get( "font" ) ) );
    
    $editable->{ _editing_canceled } = FALSE;
    $editable->{ _path } = $path;
    $editable->set( height_request => $cell_area->{height} );
    
    $editable->set_text( $cell->get( "text" ) );
    $editable->select_all();
    $editable->show();
    
    $editable -> signal_connect_after(
            'focus-out-event'       => sub {
                                                my ( $event_box, $event ) = @_;
                                                $cell->signal_emit( edited => $editable->{ _path }, $editable->get_text );
                                                return $event;
            }
                               );
    
    return $editable;
    
}

sub get_layout {
    
    my ( $cell, $widget ) = @_;
    
    return $widget->create_pango_layout( "" );
    
}

1;


#######################################################################################
# CellRendererDate
#######################################################################################

# Copyright (C) 2003 by Torsten Schoenfeld
# 
# This library is free software; you can redistribute it and/or modify it under
# the terms of the GNU Library General Public License as published by the Free
# Software Foundation; either version 2.1 of the License, or (at your option)
# any later version.
# 
# This library is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for
# more details.
# 
# You should have received a copy of the GNU Library General Public License
# along with this library; if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330, Boston, MA  02111-1307  USA.
#
# $Header: /cvsroot/gtk2-perl/gtk2-perl-xs/Gtk2/examples/cellrenderer_date.pl,v 1.5 2005/01/07 21:31:59 kaffeetisch Exp $
#


use strict;
use Gtk3 -init;

package Gtk3::Ex::DBI::Datasheet::CellRendererDate;

use Glib::Object::Subclass
    "Gtk3::CellRenderer",
    signals     => {
                        edited => {
                                    flags       => [qw(run-last)],
                                    param_types => [qw(Glib::String Glib::Scalar)],
                                  },
                   },
    properties  => [
                    Glib::ParamSpec->boolean(
                        "editable",
                        "Editable",
                        "Can I change that?",
                        0,
                        [qw(readable writable)]
                    ),
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
                        "What day-month-year formatting?",
                        "yyyy-mm-dd",
                        [qw(readable writable)]
                    ),
                    Glib::ParamSpec->string(
                        "font",
                        "Font",
                        "What size fonts should be used?",
                        12,
                        [qw(readable writable)]
                    ),
                    Glib::ParamSpec->string(
                        "foreground",
                        "Foreground",
                        "What colour should foreground text be?",
                        "",
                        [qw(readable writable)]
                    )
    ];

use constant x_padding => 2;
use constant y_padding => 3;

use constant arrow_width => 15;
use constant arrow_height => 15;

sub hide_popup {
    
    my ( $cell ) = @_;
    
    Gtk3->grab_remove( $cell->{ _popup } );
    $cell->{ _popup }->hide();
    
}

sub get_today {
    
    my ( $cell ) = @_;
  
    my ( $day, $month, $year ) = (localtime())[3, 4, 5];
    
    $year += 1900;
    $month += 1;
  
    return ( $year, $month, $day );
    
}

sub get_date {
    
    my ( $cell ) = @_;
    
    my $text = $cell->get("date");
    
    my ( $year, $month, $day ) = $text
        ? split(/[\/-]/, $text)
        : $cell->get_today();
    
    return ( $year, $month, $day );
    
}

sub add_padding {
    
    my ( $cell, $year, $month, $day ) = @_;
    return ( $year, sprintf("%02d", $month), sprintf("%02d", $day) );
    
}

sub INIT_INSTANCE {
    
    my ( $cell ) = @_;
    
    my $popup = Gtk3::Window->new ('popup');
    my $vbox = Gtk3::VBox->new( 0, 0 );
    
    my $calendar = Gtk3::Calendar->new();
    
    #$calendar->modify_font( Gtk3::Pango::FontDescription->from_string( "Arial " . $cell->get( "font" ) ) );
    $calendar->modify_font( Pango::FontDescription::from_string( "Arial " . $cell->get( "font" ) ) );
    
    my $hbox = Gtk3::HBox->new( 0, 0 );
    
    my $today = Gtk3::Button->new('Today');
    my $none = Gtk3::Button->new('None');
    
    # $cell -> {_arrow} = Gtk3::Arrow->new( "down", "none" );
    
    # We can't just provide the callbacks now because they might need access to
    # cell-specific variables.  And we can't just connect the signals in
    # START_EDITING because we'd be connecting many signal handlers to the same
    # widgets.
    $today->signal_connect( clicked => sub {
        $cell->{ _today_clicked_callback }->( @_ )
            if ( exists( $cell->{ _today_clicked_callback } ) );
    } );
    
    $none->signal_connect( clicked => sub {
        $cell->{ _none_clicked_callback }->( @_ )
            if ( exists( $cell->{ _none_clicked_callback } ) );
    } );
    
    $calendar->signal_connect( day_selected_double_click => sub {
        $cell->{ _day_selected_double_click_callback }->( @_ )
            if ( exists( $cell->{ _day_selected_double_click_callback } ) );
    } );
    
    $calendar->signal_connect( month_changed => sub {
        $cell->{ _month_changed }->( @_ )
            if ( exists( $cell->{ _month_changed } ) );
    } );
    
    $hbox->pack_start( $today, 1, 1, 0 );
    $hbox->pack_start( $none, 1, 1, 0 );
    
    $vbox->pack_start( $calendar, 1, 1, 0 );
    $vbox->pack_start( $hbox, 0, 0, 0 );
    
    # Find out if the click happended outside of our window.  If so, hide it.
    # Largely copied from Planner (the former MrProject).
    
    # Implement via Gtk3::get_event_widget?
    $popup->signal_connect( button_press_event => sub {
      my ( $popup, $event ) = @_;
    
      if ( $event->button() == 1 ) {
        my ( $x, $y ) = ( $event->x_root(), $event->y_root() );
        my ( $xoffset, $yoffset ) = $popup->window()->get_root_origin();
    
        my $allocation = $popup->allocation();
    
        my $x1 = $xoffset + 2 * $allocation->x();
        my $y1 = $yoffset + 2 * $allocation->y();
        my $x2 = $x1 + $allocation->width();
        my $y2 = $y1 + $allocation->height();
    
        unless ( $x > $x1 && $x < $x2 && $y > $y1 && $y < $y2 ) {
          $cell->hide_popup();
          return 1;
        }
      }
    
      return 0;
    } );
    
    $popup->add( $vbox );
    
    $cell->{ _popup } = $popup;
    $cell->{ _calendar } = $calendar;
}

sub START_EDITING {
    
    my ( $cell, $event, $view, $path, $background_area, $cell_area, $flags ) = @_;
    
    my $popup = $cell -> { _popup };
    my $calendar = $cell->{ _calendar };
    
    # Specify the callbacks.  Will be called by the signal handlers set up in
    # INIT_INSTANCE.
    $cell->{ _today_clicked_callback } = sub {
        
        my ($button) = @_;
        my ($year, $month, $day) = $cell -> get_today();
        
        $cell->signal_emit( edited=>$path, join( "-", $cell->add_padding( $year, $month, $day ) ) );
        $cell->hide_popup();
        
    };
    
    $cell->{ _none_clicked_callback } = sub {
        
        my ( $button ) = @_;
      
        $cell->signal_emit( edited=>$path, "" );
        $cell->hide_popup();
        
    };
    
    $cell->{ _day_selected_double_click_callback } = sub {
        
        my ( $calendar ) = @_;
        my ( $year, $month, $day ) = $calendar->get_date();
        
        $cell->signal_emit( edited => $path, join( "-", $cell -> add_padding( $year, ++$month, $day ) ) );
        $cell->hide_popup();
        
    };
    
    $cell->{ _month_changed } = sub {
        
        my ( $calendar ) = @_;
        
        my ( $selected_year, $selected_month ) = $calendar->get_date();
        my ( $current_year, $current_month, $current_day ) = $cell->get_today();
        
        if ( $selected_year == $current_year && ++$selected_month == $current_month ) {
            $calendar->mark_day( $current_day );
        }
        else {
            $calendar->unmark_day( $current_day );
        }
        
    };
    
    my ( $year, $month, $day ) = $cell->get_date();
    
    $calendar->select_month( $month - 1, $year );
    $calendar->select_day( $day );
    
    # Necessary to get the correct allocation of the popup.
    $popup->move( -500, -500 );
    $popup->show_all();
    
    # Figure out where to put the popup - ie don't put it offscreen,
    # as it's not movable ( by the user )
    my $screen_height = $popup->get_screen->get_height;
    my $requisition = $popup->size_request();
    my $popup_width = $requisition->width;
    my $popup_height = $requisition->height;
    my ( $x_origin, $y_origin ) = $view->get_bin_window()->get_origin();
    my ( $popup_x, $popup_y );
    
    $popup_x = $x_origin + $cell_area->{x} + $cell_area->{width} - $popup_width;
    $popup_x = 0 if $popup_x < 0;
    
    $popup_y = $y_origin + $cell_area->{y} + $cell_area->{height};
    
    if ( $popup_y + $popup_height > $screen_height ) {
      $popup_y = $y_origin + $cell_area->{y} - $popup_height;
    }
    
    $popup->move( $popup_x, $popup_y );
    
    # Grab the focus and the pointer.
    #Gtk3->grab_add( $popup );
    $popup->grab_add;
    
    $popup->grab_focus();
    
#    Gtk3::Gdk::pointer_grab(
#        $popup,
#        1,
#        [ qw( button-press-mask button-release-mask pointer-motion-mask ) ],
#        undef,
#        undef,
#        0
#    );
    
    return;
    
}

sub get_date_string {
    
    my ( $cell ) = @_;
    
    return $cell->get('date');
    
}

sub calc_size {
    
    my ( $cell, $layout ) = @_;
    
    my ( $width, $height ) = $layout -> get_pixel_size();
    
    return (
                0,
                0,
                $width + x_padding * 2 + arrow_width,
                $height + y_padding * 2
           );
    
}

sub GET_SIZE {
    
    my ( $cell, $widget, $cell_area ) = @_;
    
    my $layout = $cell->get_layout( $widget );
    $layout->set_text( $cell->get_date_string() || '' );
    
    return $cell->calc_size( $layout );
    
}

sub get_layout {
    
    my ( $cell, $widget ) = @_;
    
    return $widget->create_pango_layout("");
    
}

sub RENDERS {
    
    my ( $cell, $cairo, $widget, $background_area, $cell_area, $flags ) = @_;
    
    my $state;
    
    if ( $flags & 'selected' ) {
        $state = $widget->has_focus()
            ? 'selected'
            : 'active';
    } else {
        $state = $widget->state() eq 'insensitive'
            ? 'insensitive'
            : 'normal';
    }
    
    my $layout = $cell->get_layout( $widget );
    
    my $datestring = $cell->get_date_string() || '';
    
    if ( $datestring eq '0000-00-00' ) {
        $datestring = '';
    }
    
    if ( $cell->get('format') eq "dd-mm-yyyy" && $datestring ne '' ) {
        my ( $yyyy, $mm, $dd ) = split /-/, $datestring;
        $datestring = $dd . "-" . $mm . "-" . $yyyy;
    } elsif ( $cell->get('format') eq "dd-mm-yy" && $datestring ne '' ) {
        my ( $yyyy, $mm, $dd ) = split /-/, $datestring;
        $datestring = $dd . "-" . $mm . "-" . substr( $yyyy, 2, 2 );
    } elsif ( $cell->get('format') eq 'mmm-yyyy' && $datestring ne '' ) {
        my ( $yyyy, $mm, $dd ) = split /-/, $datestring;
        my @months_array = qw ( Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec ); # TODO how do we use the 'global' months array?
        $datestring = $months_array[ $mm - 1 ] . '-' . $yyyy;
    }
    
    #$layout->set_font_description( Gtk3::Pango::FontDescription->from_string( "Arial " . $cell->get( "font" ) ) );
    $layout->set_font_description( Pango::FontDescription->from_string( "Arial " . $cell->get( "font" ) ) );
    
    # TODO Alignment in CellRendererDate doesn't work. Why?
    
#    my $xalign = $cell->get( 'xalign' );
#    
#    if ( ! $xalign || $xalign < 0.5 ) {
#        $layout->set_alignment( 'PANGO_ALIGN_LEFT' );
#    } elsif ( $xalign > 0.5 ) {
#        $layout->set_alignment( 'PANGO_ALIGN_RIGHT' );
#    } elsif ( $layout == 0.5 ) {
#        $layout->set_alignment( 'PANGO_ALIGN_CENTER' );
#    }
    
    my $foreground = $cell->get( 'foreground' );
    
    if ( $foreground ) {
        $layout->set_markup( "<span color='$foreground'>$datestring</span>" );
    } else {
        $layout->set_text( $datestring );
    }
    
    my ( $x_offset, $y_offset, $width, $height ) = $cell->calc_size( $layout );
    
    $widget->get_style->paint_layout(
        $cairo,
        $state,
        1,
        $cell_area, # TODO: this won't work any more (?) ... $cell_area is a hash ... used to be an object
        $widget,
        "cellrenderertext",
        $cell_area->{x} + $x_offset + x_padding,
        $cell_area->{y} + $y_offset + y_padding,
        $layout
    );
    
    # TODO This slows things down a LOT in large datasheets - particularly with lots of date renderers ...
    
#    $widget->get_style->paint_arrow (
#        $window,
#        $widget->state,
#        'none',
#        $cell_area,
#        $cell->{ _arrow },
#        "",
#        "down",
#        1,
#        $cell_area->x + $cell_area->width - arrow_width,
#        $cell_area->y + $cell_area->height - arrow_height + 3, #
#        arrow_width - 3,
#        arrow_height
#    );

}

1;
#
########################################################################################
## CellRendererTime
########################################################################################
#
## Copyright (C) 2005 by Daniel Kasak ...
##  ... basically a slightly modified CellRendererDate ( see above )
## 
## This library is free software; you can redistribute it and/or modify it under
## the terms of the GNU Library General Public License as published by the Free
## Software Foundation; either version 2.1 of the License, or (at your option)
## any later version.
## 
## This library is distributed in the hope that it will be useful, but WITHOUT
## ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
## FOR A PARTICULAR PURPOSE.  See the GNU Library General Public License for
## more details.
## 
## You should have received a copy of the GNU Library General Public License
## along with this library; if not, write to the Free Software Foundation, Inc.,
## 59 Temple Place - Suite 330, Boston, MA  02111-1307  USA.
#
#use strict;
#use Gtk3 -init;
#
#package Gtk3::Ex::Datasheet::DBI::CellRendererTime;
#
#use Glib::Object::Subclass
#  "Gtk3::CellRenderer",
#  signals => {
#    edited => {
#      flags => [ qw( run-last ) ],
#      param_types => [ qw( Glib::String Glib::Scalar ) ],
#    },
#  },
#  properties => [
#    Glib::ParamSpec->boolean( "editable", "Editable", "Can I change that?", 0, [qw(readable writable)] ),
#    Glib::ParamSpec->string( "time", "Time", "What's the time again?", "", [qw(readable writable)] ),
#  ]
#;
#
#use constant x_padding => 2;
#use constant y_padding => 3;
#
#use constant arrow_width => 15;
#use constant arrow_height => 15;
#
#sub hide_popup {
#    
#    my $cell = shift;
#    
#    Gtk3->grab_remove( $cell->{ _popup } );
#    $cell->{ _popup }->hide();
#    
#}
#
#sub get_time {
#    
#    my $cell = shift;
#    
#    my $text = $cell->get( "time" );
#    my ( $h, $m, $s ) = split( /:/, $text );
#    
#    return ( $h, $m, $s );
#    
#}
#
#sub add_padding {
#    
#    my ( $cell, $h, $m, $s ) = @_;
#    
#    return ( sprintf( "%02d",$h ), sprintf( "%02d", $m ), sprintf( "%02d", $s ) );
#    
#}
#
#sub INIT_INSTANCE {
#    
#    my $cell = shift;
#    
#    my $popup = Gtk3::Window->new( 'popup' );
#    my $vbox = Gtk3::VBox->new( 0, 0 );
#    
#    my $h_spinbutton = Gtk3::SpinButton -> new_with_range( 0, 23, 1 );
#    my $m_spinbutton = Gtk3::SpinButton -> new_with_range( 0, 59, 1 );
#    my $s_spinbutton = Gtk3::SpinButton -> new_with_range( 0, 59, 1 );
#    my $colon_1 = Gtk3::Label->new( ":" );
#    my $colon_2 = Gtk3::Label->new( ":" );
#    
#    my $spin_hbox = Gtk3::HBox->new( 0, 0 );
#    my $buttons_hbox = Gtk3::HBox->new( 0, 0 );
#    
#    $cell->{_arrow} = Gtk3::Arrow->new( "down", "none" );
#    
#    $spin_hbox->pack_start( $h_spinbutton,    1, 1, 0 );
#    $spin_hbox->pack_start( $colon_1,         1, 1, 0 );
#    $spin_hbox->pack_start( $m_spinbutton,    1, 1, 0 );
#    $spin_hbox->pack_start( $colon_2,         1, 1, 0 );
#    $spin_hbox->pack_start( $s_spinbutton,    1, 1, 0 );
#    
#    my $ok = Gtk3::Button->new_from_stock( 'gtk-ok' );
#    
#    $buttons_hbox->pack_start( $ok, 1, 1, 0 );
#    
#    $vbox->pack_start( $spin_hbox, 0, 0, 0 );
#    $vbox->pack_start( $buttons_hbox, 0, 0, 0 );
#    
#    # We can't just provide the callbacks now because they might need access to
#    # cell-specific variables.  And we can't just connect the signals in
#    # START_EDITING because we'd be connecting many signal handlers to the same
#    # widgets.
#    
#    $ok->signal_connect( clicked => sub {
#        $cell->{ _ok_clicked_callback }->( @_ )
#            if ( exists( $cell->{ _ok_clicked_callback } ) );
#    } );
#    
#    # Find out if the click happended outside of our window.  If so, hide it.
#    # Largely copied from Planner (the former MrProject).
#    
#    # Implement via Gtk3::get_event_widget?
#    $popup -> signal_connect( button_press_event => sub {
#        my ( $popup, $event ) = @_;
#        if ( $event->button() == 1 ) {
#            my ( $x, $y ) = ( $event->x_root, $event->y_root );
#            my ( $xoffset, $yoffset ) = $popup->window->get_root_origin;
#            my $allocation = $popup->allocation;
#            my $x1 = $xoffset + 2 * $allocation->x;
#            my $y1 = $yoffset + 2 * $allocation->y;
#            my $x2 = $x1 + $allocation->width;
#            my $y2 = $y1 + $allocation->height;
#            unless ( $x > $x1 && $x < $x2 && $y > $y1 && $y < $y2 ) {
#                $cell->hide_popup;
#                return 1;
#            }
#        }
#        return 0;
#    } );
#    
#    $popup->add( $vbox );
#    
#    $cell->{ _popup } = $popup;
#    $cell->{ _h_spinbutton } = $h_spinbutton;
#    $cell->{ _m_spinbutton } = $m_spinbutton;
#    $cell->{ _s_spinbutton } = $s_spinbutton;
#    
#}
#
#sub START_EDITING {
#    
#    my ( $cell, $event, $view, $path, $background_area, $cell_area, $flags ) = @_;
#    
#    my $popup = $cell->{ _popup };
#    my $h_spinbutton = $cell->{ _h_spinbutton };
#    my $m_spinbutton = $cell->{ _m_spinbutton };
#    my $s_spinbutton = $cell->{ _s_spinbutton };
#    
#    my ( $h, $m, $s ) = $cell->get_time;
#    
#    $h_spinbutton->set_value( $h );
#    $m_spinbutton->set_value( $m );
#    $s_spinbutton->set_value( $s );
#    
#    $cell->{ _ok_clicked_callback } = sub {
#        
#        my ( $button ) = @_;
#        my $h = $h_spinbutton->get_text;
#        my $m = $m_spinbutton->get_text;
#        my $s = $s_spinbutton->get_text;
#        
#        $cell->signal_emit(
#            edited => $path,
#            join( ":", $cell -> add_padding( $h, $m, $s ) )
#        );
#        
#        $cell->hide_popup;
#        
#    };
#    
#    # Necessary to get the correct allocation of the popup.
#    $popup->move( -500, -500 );
#    $popup->show_all;
#    
#    # Figure out where to put the popup - ie don't put it offscreen,
#    # as it's not movable ( by the user )
#    my $screen_height = $popup->get_screen->get_height;
#    my $requisition = $popup->size_request;
#    my $popup_width = $requisition->width;
#    my $popup_height = $requisition->height;
#    my ( $x_origin, $y_origin ) =  $view->get_bin_window->get_origin;
#    my ( $popup_x, $popup_y );
#    
#    $popup_x = $x_origin + $cell_area->{x} + $cell_area->{width} - $popup_width;
#    $popup_x = 0 if $popup_x < 0;
#    
#    $popup_y = $y_origin + $cell_area->{y} + $cell_area->{height};
#    
#    if ( $popup_y + $popup_height > $screen_height ) {
#        $popup_y = $y_origin + $cell_area->{y} - $popup_height;
#    }
#    
#    $popup -> move( $popup_x, $popup_y );
#    
#    # Grab the focus and the pointer.
#    Gtk3->grab_add( $popup );
#    $popup->grab_focus;
#    
#    Gtk3::Gdk->pointer_grab(
#        $popup->window,
#        1,
#        [ qw( button-press-mask button-release-mask pointer-motion-mask ) ],
#        undef,
#        undef,
#        0
#    );
#    
#    return;
#    
#}
#
#sub get_time_string {
#    
#    my $cell = shift;
#    return $cell->get( 'time' );
#    
#}
#
#sub calc_size {
#    
#    my ( $cell, $layout ) = @_;
#    my ( $width, $height ) = $layout->get_pixel_size;
#    
#    return (
#        0,
#        0,
#        $width + x_padding * 2 + arrow_width,
#        $height + y_padding * 2
#    );
#    
#}
#
#sub GET_SIZE {
#    
#    my ( $cell, $widget, $cell_area ) = @_;
#    
#    my $layout = $cell->get_layout( $widget );
#    $layout->set_text( $cell->get_time_string || '' );
#    
#    return $cell->calc_size( $layout );
#    
#}
#
#sub get_layout {
#    
#    my ( $cell, $widget ) = @_;
#    
#    return $widget->create_pango_layout( "" );
#    
#}
#
#sub RENDER {
#    
#    my ( $cell, $window, $widget, $background_area, $cell_area, $expose_area, $flags ) = @_;
#    
#    my $state;
#    
#    if ( $flags & 'selected' ) {
#        $state = $widget->has_focus
#            ? 'selected'
#            : 'active';
#    } else {
#        $state = $widget->state eq 'insensitive'
#            ? 'insensitive'
#            : 'normal';
#    }
#    
#    my $layout = $cell->get_layout( $widget );
#    $layout->set_text( $cell->get_time_string );
#    
#    my ( $x_offset, $y_offset, $width, $height ) = $cell->calc_size( $layout );
#    
#    $widget->get_style->paint_layout(
#        $window,
#        $state,
#        1,
#        $cell_area, # TODO: doesn't work? was object, now hash
#        $widget,
#        "cellrenderertext",
#        $cell_area->{x} + $x_offset + x_padding,
#        $cell_area->{y} + $y_offset + y_padding,
#        $layout
#    );
#    
#    $widget->get_style->paint_arrow(
#        $window,
#        $widget->state,
#        'none',
#        $cell_area, # TODO: doesn't work? was object, now hash
#        $cell->{ _arrow },
#        "",
#        "down",
#        1,
#        $cell_area->{x} + $cell_area->{width} - arrow_width,
#        $cell_area->{y} + $cell_area->{height} - arrow_height - 2,
#        arrow_width - 3,
#        arrow_height
#    );
#    
#}
#
#1;

#######################################################################################


=head1 NAME

Gtk3::Ex::Datasheet::DBI

=head1 SYNOPSIS

   use DBI;

   use Gtk3 -init;

   use Gtk3::Ex::Datasheet::DBI; 

   my $dbh = DBI->connect (
       "dbi:mysql:dbname=sales;host=screamer;port=3306",
       "some_username",
       "salespass",
       {
           PrintError => 0,
           RaiseError => 0,
           AutoCommit => 1
       }
   );

   my $datasheet_def = {
       dbh          => $dbh,
       sql          => {
                           select            => "FirstName, LastName, GroupNo, Active",
                           from              => "BirdsOfAFeather",
                           order_by          => "LastName"
                       },
       treeview     => $testwindow->get_widget( "BirdsOfAFeather_TreeView" ),
       fields       => [
                           {
                               name          => "First Name",
                               x_percent     => 35,
                               validation    => sub { &validate_first_name(@_); }
                           },
                           {
                               name          => "Last Name",
                               x_percent     => 35
                           },
                           {
                               name          => "Group",
                               x_percent     => 30,
                               renderer      => "combo",
                               model_setup   => {
                                     fields     => [
                                                    {
                                                        name            => "ID",
                                                        type            => "Glib::Int"
                                                    },
                                                    {
                                                        name            => "GroupName",
                                                        type            => "Glib::String"
                                                    }
                                     ],
                                     sql        => {
                                                        from            => "Groups",
                                                        where_object    => {
                                                            where       => "Active = 1 and Location = ?",
                                                            bind_values => [ $some_location_id ]
                                                        }
                                                            
                                     }
                               }
                           },
                           {
                               name          => "Active",
                               x_absolute    => 50,
                               renderer      => "toggle"
                           }
       ],
       multi_select => TRUE
   };
   
   $birds_of_a_feather_datasheet = Gtk3::Ex::Datasheet::DBI->new( $datasheet_def )
      || die ("Error setting up Gtk3::Ex::Datasheet::DBI\n");

=head1 DESCRIPTION

This module automates the process of setting up a model and treeview based on field definitions you pass it,
querying the database, populating the model, and updating the database with changes made by the user.

Steps for use:

* Open a DBI connection

* Create a 'bare' Gtk3::TreeView - I use Gtk3::GladeXML, but I assume you can do it the old-fashioned way

* Create a Gtk3::Ex::Datasheet::DBI object and pass it your TreeView object

You would then typically create some buttons and connect them to the methods below to handle common actions
such as inserting, deleting, etc.

=head1 METHODS

=head2 new

=over 4

Object constructor. For more info, see section on CONSTRUCTION below.

=back

=head2 query ( [ where_object ], [ dont_apply ] )

=over 4

Requeries the Database Server. If there are any outstanding changes that haven't been applied to the database,
a dialog will be presented to the user asking if they want to apply updates before requerying.

If a where object is passed, the relevent parts will be replaced ( the where clause and the
bind_values ). Note that you don't have to provide both. For example, if you leave out the where
clause and only supply bind_values, the original where clause will continue to be used.

If dont_apply is set, *no* dialog will appear if there are outstanding changes to the data.

The where_object is a hash:

    {
        where         => a where clause - can include placeholders
        bind_values   => an array of values to bind to placeholders ( optional )
    }

The query method doubles as an 'undo' method if you set the dont_apply flag, eg:

$datasheet->query ( undef, TRUE );

This will requery and reset all the status indicators. See also undo method, below

=back

=head2 undo

=over 4

Basically a convenience function that calls $self->query( undef, TRUE ) ... see above.
I've come to realise that having an undo method makes understanding your code a lot easier later.

=back

=head2 apply

=over 4

Applies all changes ( inserts, deletes, alterations ) in the datasheet to the database.
As changes are applied, the record status indicator will be changed back to the original 'synchronised' icon.

If any errors are encountered, a dialog will be presented with details of the error, and the apply method
will return FALSE without continuing through the records. The user will be able to tell where the apply failed
by looking at the record status indicators ( and considering the error message they were presented ).

=back

=head2 insert ( [ @columns_and_values ] )

=over 4

Inserts a new row in the *model*. The record status indicator will display an 'insert' icon until the record
is applied to the database ( apply method ).

You can optionally set default values by passing them as an array of column numbers and values, eg:
    $datasheet->insert(
        2   => "Default value for column 2",
        5   => "Another default - for column 5"
    );

Note that there are a number of ways of fetching a column number. The recommended way is by accessing the
'column_name_to_number_mapping' hash, eg:

$datasheet->{name_to_number_mapping}->{some_column_name}

As of version 0.8, default values from the database schema are automatically inserted into all columns that
aren't explicitely set as above.

=back

=head2 delete

=over 4

Marks all selected records for deletion, and sets the record status indicator to a 'delete' icon.
The records will remain in the database until the apply method is called.

=back

=head2 column_from_sql_name ( $sql_fieldname )

=over 4

DEPRECIATED - see COLUMN NAMING section

Returns a field's column number in the model. Note that you *must* use the SQL fieldname,
and not the column heading's name in the treeview.

=back

=head2 get_column_value ( $sql_fieldname )

=over 4

Returns the value of the requested column in the currently selected row.
If multi_select is on and more than 1 row is selected, only the 1st value is returned.
You *must* use the SQL fieldname, and not the column heading's name in the treeview.

=back

=head2 set_column_value ( $sql_fieldname, $value )

=over 4

Sets the value in the given field in the current recordset.
You *must* use the SQL fieldname, and not the column heading's name in the treeview.

=back

=head2 set_header_markup( $sql_fieldname, $markup )

=over 4

Sets the column's header markup ( ie the label at the top of the column )
to the new string $markup

=back

=head2 data_to_csv ( %options )

=over 4

Export data to csv format

%options is a hash containing:

=over 4

=head3 destination

The full path to the destination file

=back

=head3 columns

=over 4

An array containing the column NUMBERS ( ie from $datasheet->{column_name_to_number_mapping } )
that you want included in the csv

=back

=back

=head2 data_to_array( %options )

=over 4

Convert data into an array of arrays ( ie like you're get from $dbh->selectall_arrayref )

%options is an optional hash containing:

=over 4

=head3 columns

An array containing the column NUMBERS ( ie from $datasheet->{column_name_to_number_mapping } )
that you want included in the array

=back

=back
 
=head2 replace_combo_model ( $column_no, $new_model )

=over 4

Replaces the model for a combo renderer with a new one.
You should only use this to replace models for a normal 'combo' renderer.
An example of when you'd want to do this is if the options in your combo depend on a value
on your *main* form ( ie not in the datasheet ), and that value changes.
If you instead want to base your list of options on a value *inside* the datasheet, use
the 'dynamic_combo' renderer instead ( and don't use replace_combo_model on it ).

=back

=head2 sum_column ( $column, [ $conditions ] )

=over 4

This is a convenience function that returns the sum of all values in the given column ( by number ).
Fetch the column number via the column_from_sql_name() or column_from_column_name() function.
Optionally, a hash description of conditions can be passed to activate 'conditional sum' functionality.
The conditions hash should contain:

=head3 column

=over 4

The column number to perform the comparison on.
Fetch the column via the column_from_sql_name() or column_from_column_name() function.

=back

=head3 operator

=over 4

The type of comparison operation, from a list of:

=over 4

    == ... a numeric equals operator

eq ... a string equals operator

<  ... less than

>  ... greater than

=back

=back

=head3 value

=over 4

The value to compare the column data to.

=back

=back

=head2 max_column( $column )

=over 4

Returns the maximum value in column $column

=back

=head2 average_column( $column )

=over 4

Returns the average value in column $column

=back

=head2 count ( $column, [ $conditions ] )

=over 4

This is a convenience function that counts the number of records.
Fetch the column number via the column_from_sql_name() or column_from_column_name() function.
Optionally, a column number AND a hash description of conditions can be passed to activate 'conditional count' functionality.
The conditions hash should contain:

=head3 column

=over 4

The column number to perform the comparison on.
Fetch the column via the column_from_sql_name() or column_from_column_name() function.

=back

=head3 operator

=over 4

The type of comparison operation, from a list of:

=over 4

    == ... a numeric equals operator

eq ... a string equals operator

<  ... less than

>  ... greater than

=back

=back

=head3 value

=over 4

The value to compare the column data to.

=back

=back

=head1 CONSTRUCTION

The new() method requires only 3 bits of information:
 - a dbh
 - an sql object
 - a treeview or vbox

Usually, you would also supply a fields array. All possible keys in the constructor hash are:

=head2 dbh

=over 4

a DBI database handle

=back

=head2 treeview

=over 4

A Gtk3::TreeView to attach to. You must either supply a treeview OR a vbox ( below )

=back

=head2 vbox

=over 4

A Gtk3::VBox to place treeviews in. You must either supply a treevie OR a vbox.
You'd use a vbox instead of a treeview if you wanted to activate the 'footer' functionality

=back

=head2 sql

=over 4

a hash describing the SQL to execute.
Note that each clause has it's directive ( ie 'select', 'from', where', 'order by' *ommitted* )
The SQL object contains the following keys:

=head3 select

=over 4

the select clause

=back

=head3 from

=over 4

the from clause

=back

=head3 where

=over 4

the where clause ( may contain values or placeholders )

=back

=head3 bind_values

=over 4

an array of values to bind to placeholders

=back

=head3 pass_through

=over 4

a command which is passsed directly to the Database Server ( that hopefully returns a recordset ).
If a pass_through key is specified, all other keys are ignored. You can use this feature to
either construct your own SQL directly, which can include executing a stored procedure that
returns a recordset. Recordsets based on a pass_through query will be forced to read_only mode,
as updates require that column_info is available. I'm only currently using this feature for
executing stored procedures, and column_info doesn't work for these. If you want to enable
updates for pass_through queries, you'll have to work on getting column_info working ...

=back

=back

=head2 column_sorting

=over 4

A boolean that activates column sorting. If this is set, the user will be able to click on a
column heading to sort by that column. All columns types should now sort properly.
Please let me know if they don't.

=back

=head2 auto_apply

=over 4

A boolean that will cause datasheets to *automatically* apply changes if a new query is run
while outstanding changes exist, or if the user tries to close a form with outstanding changes
 ... ie NO question dialog will appear
 
=back

=head2 footer

=over 4

A boolean to activate the footer treeview. This feature requires you to pass a vbox instead
of a treeview, and 2 treeviews will be created, with the footer treeview tracking changes
in the main treeview. You will also have to set up footer functions in the field definitions
( see the fields section below )

=back

=head2 footer_treeview

=over 4

A Gtk3::TreeView to render the footer in. Pass one in if you want to arrange / format the
treeview yourself, instead of having it automatically created for you ( as in the footer
support, directly above )

=back

=head2 default_font_size

=over 4

The default font size to use for cells that support the font property. This will be
overridden if you supply a font_size for an individual cell

=back

=head2 fixed_row_height

=over 4

A boolean to activate fixed-row-height mode. This will set all rows to be slightly
bigger ( x 1.8 ) than the default_font_size ( ie above ... you MUST set this value ).
FIXME: This could possibly be done in a more elegant fashion

=back

=head2 primary_keys

=over 4

POSSIBLY DANGEROUS

an array of primary keys of the table you are querying. These are detected in most cases, so you shouldn't
have to specify them. In some cases ( ie multi-table queries, which aren't exactly supported ), you can
*possibly* specify an array of primarys key here and then try to use the datasheet to update data ... but don't
look at me if things go sour :)

=back

=head2 multi_select

=over 4

a boolean to turn on the TreeView's 'multiple' selection mode. Note that if you turn this on,
the function get_column_value() will only a value return the 1st selected row. The default for this
is FALSE.

=back

=head2 read_only

=over 4

a boolean to lock the entire datasheet to read-only ( record status indicator will also disappear ).
Note that you can also set individual fields to read_only

=back

=head2 before_apply

=over 4

a coderef to a custom function to run *before* a record is applied.
For more information, see USER-DEFINED CALL-BACKS below

=back

=head2 on_apply

=over 4

a coderef to a custom function to run *after* a recordset is applied.
For more information, see USER-DEFINED CALL-BACKS below

=back

=head2 on_row_select

=over 4

a coderef to a custom function to run when a row is selected
For more information, see USER-DEFINED CALL-BACKS below

=back

=head2 dump_on_error

=over 4

a boolean to turn on dumping of SQL string to the STDOUT on a DBI error

=back

=head2 friendly_table_name

=over 4

a string to use in dialogs ( eg apply changes to XXX before continuing, etc ).
If you don't pass a friendly_table_name, the sql->{from} clause will be used

=back

=head2 custom_changed_text

=over 4

Some text ( including pango markup ) to use for a dialog to present to the user
when there are changes to the datasheet that they're about to drop, eg if they close
the window or requery without hitting apply. This is only needed if you want a CUSTOM
message; a relatively decent one is already raised in these situations

=back

=head2 fields

=over 4

an array of hashes to describe each field ( column ) in the TreeView.
If you don't supply any field definitions, they will be constructed for you, but
you will loose the ( very useful ) ability to specify column widths.
Each field, described by a hash, has the following possible keys:

=head3 name

=over 4

the name of the column. This is the name that you pass to the function:
column_from_column_name()
The column name is also used in the column's header, unless you specify some header_markup
( see below )

! * ! * ! * ! * ! * ! * ! * ! BIG FAT WARNING ! * ! * ! * ! * ! * ! * ! * !

It is *strongly* recommended that you use the SQL field-name as the column name. The reason I'm
recommending this is that I'm considering dropping support completely for NOT doing this :) Things
are getting overly complex for no real reason, having to deal with SQL names, field names, etc. The
recommended way of accessing column numbers is now via the 'column_name_to_number_mapping' hash
( see below ). If this is going to cause you a problem, you should contact me now and tell me about
it ...

! * ! * ! * ! * ! * ! * ! * ! BIG FAT WARNING ! * ! * ! * ! * ! * ! * ! * !

=back

=head3 header_markup

=over 4

some pango markup to use in the column's header - this will be used instead of the column's name

=back

=head3 align

=over 4

the text alignment for this field - possible values are:

 - left
 - centre OR center
 - right
 - a decimal value between 0 ( left aligned ) and 1 ( right aligned )

=back

=head3 x_percent

=over 4

percentage of the available width to use for this column. If you specify an x_percent,
the actual width of the field is recalculated each time the treeview is resized. The total
width of the treeview is calculated, then all the fields with absolute sizing ( see below )
are taken away from the total width, and the remaining width is divided up amongst fields
with percentage values set.

=back

=head3 x_absolute

=over 4

an absolute value to use for the width of this column - ie fixed field width

=back

=head3 renderer

=over 4

name of Gtk3::Ex::Datasheet::DBI renderer. For more information, see the section on
RENDERERS below.

=back

=head3 number

=over 4

A hash describing numeric formatting. Possible keys are:

=over 4

 - currency               - boolean - activate currency formatting
 - percentage             - boolean - activate percentage formatting
 - decimals               - number  - decimal places to render
 - decimal_fill           - boolean - fill values to decimal_places
 - null_if_zero           - boolean - don't render zero values
 - highlight_negative     - boolean - render negatives values in red OR $Gtk3::Ex::Datasheet::DBI::highlight_colour ( see below )
 - separate_thousands     - boolean - separate thousands with commas

=back

Activating the 'currency' key will also activate:
  decimals            => 2,
  decimal_fill        => TRUE,
  separate_thousands  => TRUE

If you activate percentage formatting, values should be in decimal format, ie 50% == 0.5

=back

=head3 footer_function

=over 4

A string indicating which footer function to use in the footer treeview.

Current options:

=over 4

 - sum
 - max
 - average

=back

Adding more functions is trivial

=back

=head3 foreground_colour

=over 4

the colour to use for the foreground text for this field

=back

=head3 background_colour

=over 4

the colour to use for the background for this field

=back

=head3 font_size

=over 4

the size of font to use for the cell ( in render mode ... edit mode is different )

=back

=head3 wrap_text

=over 4

a boolean to activate text wrapping for the cell

=back

=head3 bold

=over 4

a boolean flag to set bold font rendering for this field

=back

=head3 model

=over 4

a TreeModel to use for a combo renderer ( see COMBOS section below )

=back

=head3 model_setup

=over 4

hash describing the setup of a combo or dynamic_combo renderer ( see COMBOS section below )

=back

=head3 read_only

=over 4

a boolean flag that locks data in this field from user edits. Note that you can also set the
entire Gtk3::Ex::Datasheet::DBI object to read_only as well.

=back

=head3 validation

=over 4

a coderef to a custom function to validate data after editing and BEFORE the data is accepted.
For more info, see the section on DATA VALIDATION, below.

=back

=head3 custom_render_functions

=over 4

an ARRAY of CODEREFs of custom functions to perform when rendering the field. These get attached to
the CellRenderer via $renderer->set_cell_data_func .... with the added bonus that you can string one
after the other easily. These custom render functions get executed in the order that they are specified
in, and as a whole they get executed AFTER any builtin_render_functions ( see below )

Your custom render function wil be passed:

( $tree_column, $renderer, $model, $iter, @other_stuff )

 ... ie @other_stuff is where you'll get anything that you pass into the function when you set it up.
 
To allow these functions to be chained together,
we copy the value from the model into the $tree_column hash, and then
ALL FUNCTIONS SHOULD USE THIS VALUE AND UPDATE IT ACCORDINGLY

ie In your custom render functions, you should pull the value from
$tree_column->{render_value}

=back

=head3 builtin_render_functions

=over 4

an ARRAY of strings specifying built-in ( ie internal to Gtk3::Ex::Datasheet::DBI ) render functions to
format or modify field data when the cell is rendered. As with custom_render_functions ( above ), these
are attached to the CellRenderer via $renderer->set_cell_data-func. Built-in render functions are executed
in the order that they are specified, and get executed BEFORE any custom_render_functions.
Current built-in functions to choose from are:

=over 4

=head3 access_time

A Microsoft workaround that understands MS Access' ridiculous time format.
While I don't expect people to use Gtk3::Ex::Datasheet::DBI to talk to
MS Access (!), people might have DATETIME fields in their database servers to stores TIME data for
MS Access. This renderer understands, and sympathises with such problems ... ie values will have:
'1899-12-30' prepended to them, so Access recognizes them as 'time' values.

=back

=head3 date_only

=over 4

This function strips off trailing garbage from data before rendering, and is excellent for
dealing with Microsoft SQL Server's idiotic lack of a DATE type - ie SQL Server insists that
all date values have 00:00:00 appended to the end of them. This function should *only* be
used in conjunction with date renderers

=back

=head3 date_only_text

=over 4

This function is the same as the date_only function ( above ), but for text renderers. ie
if you manually force the renderer type to 'text', then use this render function instead of
the above one

=back

=head3 dd-mm-yyyy

=over 4

This function converts dates in yyyy-mm-dd format to dd-mm-yyyy before rendering

=back



=back
 
=head1 RENDERERS

=over 4

Gtk3::Ex::Datasheet::DBI offers a number of 'renderers', which are defined per-column ( or field ).
The purpose of a renderer is to present data in the datasheet, and to allow you to edit the data with
the most appropriate type of interface I can muster. Some of these trigger the use of stock
Gtk3::CellRenderer objects, others trigger the use of custom-built Gtk3::CellRenderer objects,
and yet others merely do some formatting of information. So they don't *exactly* map to 'renderers'
in the sense of Gtk3::CellRenderers, but it's close enough anyway.

Renderers currently available ( feel free to submit patches for more ), are:

=head2 text

=over 4

default if no renderer defined, and suitable for all kinds of text :)

=back

=head2 combo

=over 4

static combo box with a pre-defined list of options. Note that the model used for this
renderer *can* be replaced via the function replace_combo_model(). See below section on COMBOS
for more info.

=back

=head2 dynamic_combo

=over 4

combo box with a list of options that depends on values in the current row. As well as cutting
down on the list of options displayed, this actually improves performance significantly - particularly
if you have a lot of data. See below section on COMBOS for more info.

=back

=head2 toggle

=over 4

great for boolean values, and good looking too :)

=back

=head2 date

=over 4

good for dates. MUST be in YYYY-MM-DD format ( ie most databases should be OK )

=back

=head2 time

=over 4

uses a cell renderer with 3 spin buttons for setting the time

=back

=head2 progress

=over 4

a progress bar. Give it a decimal between 0 and 1. Read-Only ... in fact I don't know what will happen
if you try to apply a datasheet with a progress renderer - I've never tested. Looks nice in read-only
datasheets ...

=back

=head2 image

=over 4

the image renderer sets up a CellRendererPixbuf renderer for you. To render your image, you have to
specify your own rendering code in 'custom_render_functions' ( see above ). Your code will receive:

=over 4

( $tree_column, $renderer, $model, $iter )

=back

You can then decide what to render, based on the data in the current cell / row, and render it with:

=over 4

$renderer->set( pixbuf => $some_pixbuf );

=back

The datasheet model holds a Glib::String column in the place of the image column, so you can store
either numeric or string data in the image column

=back

=head2 hidden

=over 4

use this for ... hidden columns!

=back

=head2 number

=over 4

This renderer is currently broken and being defaulted back to the text renderer.
I'm keeping it in place in the hope that someone will fix it.
Alternatively, gtk-2.10.x has added a CellRendererSpinButton, which could be used here.
Either way, I'm keeping this around with the intention of one day reactivating it. It's
perfectly safe to define fields with a number renderer, and have them default back to text.

=back

=back

=head1 Accessing columns

=over 4

The new way of accessing columns ( ie fetching a column number ) is via the 'column_name_to_number_mapping'
hash, ie:

    $datasheet->{column_name_to_number_mapping}->{your_column_name}

will give you the column number.

This is meant to replace all the other dodgy BS such as:

 column_from_column_name()
 column_from_name()
 column_from_sql_name()
 column_name_to_sql_name()

 ... some of which wasn't documented anyway. If you use any of these functions, it's time to stop using
 them, or email me and tell me why I shouldn't remove them in the next release :)
 
=back
 
=head1 DATA VALIDATION

You can specify a custom function to validate data as it's entered in a cell, and before
the data is accepted into the cell. Your function will receive a hash containing:

{
   
   renderer,
   text_path,
   new_text,
   model
   
}

You can also use functions such as get_column_value() to extract the values of other columns
in the currently selected row ( as long as you don't have multi-select turned on ).

Your sub should return TRUE to accept the changes, or FALSE to reject them. If you reject
changes, you should provide your own error dialog ( eg via Gtk3::Ex::Dialogs ) explaining
what's happening.

=head1 COMBOS

For combo and dynamic_combo renderers, the 'model_setup' hash should is ( unfortunately ) quite different.
I'm planning on updating the dynamic_combo 'model_setup' hash to be more like everything else, but for now,
it's different ...

=head2 model_setup for combo renderers

=over 4

The model_setup is identical to the form in Gtk3::Ex::DBI. There is an example at the very top of this
POD. Descriptions of each hash element:

=head2 fields

=over 4

An array of field definitions. Each field definition is a hash with the following keys:

=head2 name

=over 4

The SQL fieldname / expression

=back

=head2  type

=over 4

The ( Glib ) type of column to create for this field in the Gtk3::ListStore. Possible values are
Glib::Int and Glib::String.

=back

=head2 cell_data_func ( optional )

=over 4

A reference to some perl code to use as this columns's renderer's custom cell_data_func.
You can use this to perform formatting on the column ( or cell, whatever ) based on the
current data. Your function will be passed ( $column, $cell, $model, $iter ), as well as anything
else you pass in yourself.

=back

=back

=back

=head2 sql

=over 4

A hash of SQL related stuff. Possible keys are:

=head2 from

=over 4

The from clause

=back

=head2 where_object

=over 4

This can either be a where clause, or a hash with the following keys:

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

=back

=head2 order_by

=over 4

An 'order by' clause

=back

=back

=head2 alternate_dbh

=over 4

A DBI handle to use instead of the current Gtk3::Ex::DBI DBI handle

=back

=back

---

=head2 model_setup for dynamic_combo renderers

=over 4

The current format for dynamic_combos is:

{

  id              => "ID"
  display         => "Description",
  from            => "SomeTable",
  criteria        => [
                        {
                             field          => "first_where_clause_field",
                             column_name    => "column_name_of_first_value_to_use"
                        },
                        {
                             field          => "second_where_clause_field",
                             column_name    => "column_name_of_second_value_to_use"
                        }
                     ],
  group_by        => "group by ID, Description",
  order_by        => "order by some_field_to_order_by"

}

Briefly ...

The 'id' key defines the primary key in the table you are querying. This is the value that will be
stored in the dynamic_combo column.

The 'display' key defines the text value that will be *displayed* in the the dynamic_combo column,
and also in the list of combo options.

The 'table' key is the source table to query.

The 'criteria' key is an array of hashes for you to define criteria. Inside each hash, you have:

  - 'field' key, which is the field in the table you are querying ( ie it will go into the where clause )
  - 'column_name' key, which is the *SQL* column name to use as limiting value in the where clause

The 'group_by' key is a 'group by' clause. You *shouldn't* need one, but I've added support anyway...

The 'order_by' key is an 'order by' clause

=back

=head1 USER-DEFINED CALL-BACKS

=head2 before_apply

=over 4

You can specify a custom function to run *before* changes to a recordset are applied
( see new() method ). The function will be called for *every* record that has been changed.
The user-defined code will be passed a reference to a hash:

 {
    status          => a string, with possible values: 'inserted', 'changed', or 'deleted'
    primary_key     => the primary key of the record in question
    model           => the treemodel that the datasheet it based on
    iter            => the treeiter of the current row
 }

Your code *must* return a positive value to allow the record to be applied - if your code
returns FALSE, the changes to the current record will NOT be applied.

=back

=head2 on_apply

=over 4

You can specify some code to run *after* changes to a recordset is applied ( see new() method ).
It will be called for *every* record that has been changed. The user-defined code will be
passed a reference to a hash of info about the current record:

 {
    status          => a string, with possible values: 'inserted', 'changed', or 'deleted'
    primary_key     => the primary key of the record in question
    model           => the treemodel that the datasheet it based on
    iter            => the treeiter of the current row
 }

=back

=head2 on_row_select

=over 4

You can specify some code to run when a row is selected ( see new() method ).
Your code will be passed the Gtk3::TreeSelection object ( and anything else you pass yourself ).
Nothing internal to Gtk3::Ex::Datasheet::DBI is currently passed to this code, as it is
trivial to grab the data you need via get_column_value().

=back

=head1 GENERAL RANTING

=head2 Automatic Column Widths

=over 4

You can use x_percent and x_absolute values to set up automatic column widths. Absolute values are set
once - at the start. In this process, all absolute values ( including the record status column ) are
added up and the total stored in $self->{sum_absolute_x}.

Each time the TreeView is resized ( size_allocate signal ), the size_allocate method is called which resizes
all columns that have an x_percent value set. The percentages should of course all add up to 100%, and the width
of each column is their share of available width:
 ( total width of treeview ) - $self->{sum_absolute_x} * x_percent

IMPORTANT NOTE:
The size_allocate method interferes with the ability to resize *down*. I've found a simple way around this.
When you create the TreeView, put it in a ScrolledWindow, and set the H_Policy to 'automatic'. I assume this allows
you to resize the treeview down to smaller than the total width of columns ( which automatically creates the
scrollbar in the scrolled window ). Immediately after the resize, when our size_allocate method recalculates the
size of each column, the scrollbar will no longer be needed and will disappear. Not perfect, but it works. It also
doesn't produce *too* much flicker on my system, but resize operations are noticably slower. What can I say?
Patches appreciated :)

=back

=head2 $Gtk3::Ex::Datasheet::DBI::gtk2_main_iteration_in_query

=over 4

For slow network connections, your Gtk3 GUI may appear to hang while populating the treeview from a large query.
To make things feel more fluid, you can set $Gtk3::Ex::Datasheet::DBI::gtk2_main_in_query = TRUE in your
application, which will trigger:

Gtk3->main_iteration while ( Gtk3->events_pending );

for each record appended to the treeview. While this slows down operation of your application, it *appears* to
have the opposite effect, as the GUI remains responsive. This is even the case when using high speed networks.

I am considering using a 2nd thread to fetch data, which will remove the need for this, but for now, it's a
hack that works. Please supply patches for multi-threaded operation :)

=back

=head2 $Gtk3::Ex::Datasheet::DBI::highlight_colour

=over 4

This is the colour used to highlight negative values when the 'highlight_negative' key is set in the number
hash. The default value to use is red.

=back

=head2 $Gtk3::Ex::Datasheet::DBI::standard_text_colour

=over 4

This is the standard colour to give ( positive ) values when teh 'highlight_negative' key is set in the number
hash. The default value to use is black.

=back

=head2 Use of Database Schema

=over 4

Version 0.8 introduces querying the database schema to inspect column attributes. This considerably streamlines
the process of setting up the datasheet and inserting records.

If you don't define a renderer, an appropriate one is selected for you based on the field type.
The only renderers you should now have to explicitely define
are 'hidden', 'combo', and 'dynamic_combo'  - the latter 2 you will obviously still have to set up by providing
a model.

When inserting a new record, default values from the database field definitions are also used ( unless you
specify another value via the insert() method ).

=back

=head2 CellRendererCombo

=over 4

If you have Gtk-2.6 or greater, you can use the new CellRendererCombo. Set the renderer to 'combo' and attach
your model to the field definition. You currently *must* have a model with ( numeric ) ID / String pairs, which is the
usual for database applications, so you shouldn't have any problems. See the example application for ... an example.

=back

=head1 AUTHORS

Daniel Kasak - dan@entropy.homelinux.org

=head1 CREDITS

Muppet

 - tirelessly offered help and suggestions in response to my endless list of questions

Torsten Schoenfeld

 - wrote custom CellRendererDate ( from the Gtk3-Perl examples )
 - wrote custom CellRendererText ( with improved focus policy ) in Odot which I used here

Gtk3-Perl Authors

 - obviously without them, I wouldn't have gotten very far ...

Gtk3-Perl list

 - yet more help, suggestions, and general words of encouragement

=head1 BUGS

I think you must be mistaken

=head1 ISSUES

That's right. These are 'issues', not 'bugs' :)

=head2 CellRendererTime

=over 4

For some reason, the 1st time you go to edit a cell with a CellRendererTime, it doesn't receive
the current value. It works every other time after this. Weird. Anyone know what's up?

=back

=head2 SQL Server compatibility

=over 4

To use SQL Server, you should use FreeTDS ==> UnixODBC ==> DBD::ODBC. Only this combination supports
the use of bind values in SQL statements, which is a requirement of Gtk3::Ex::Datasheet::DBI. Please
make sure you have the *very* *latest* versions of each.

The only problem I've ( recently ) encountered with SQL Server is with the 'money' column type.
Avoid using this type, and you should have flawless SQL Server action.

=back

=head1 Other cool things you should know about:

This module is part of an umbrella 'Axis' project, which aims to make
Rapid Application Development of database apps using open-source tools a reality.
The project includes:

  Gtk3::Ex::DBI                 - forms
  Gtk3::Ex::Datasheet::DBI      - datasheets
  PDF::ReportWriter             - reports

All the above modules are available via cpan, or for more information, screenshots, etc, see:
http://entropy.homelinux.org/axis

=head1 Crank ON!

=cut
