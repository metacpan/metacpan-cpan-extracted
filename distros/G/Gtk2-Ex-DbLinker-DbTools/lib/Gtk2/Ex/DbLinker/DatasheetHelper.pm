package Gtk2::Ex::DbLinker::DatasheetHelper;

use Gtk2::Ex::DbLinker::DbTools;
our $VERSION = $Gtk2::Ex::DbLinker::DbTools::VERSION;

=head1 NAME

Gtk2::Ex::DbLinker::DatasheetHelper - Common methods for Gtk2::Ex::DbLinker::Datasheet and Wx::Perl::DbLinker::Wxdatasheet. None of these are called directly by the end user.

=head1 SYNOPSIS

See L<Gtk2::Ex::DbLinker::Datasheet> and L<Wx::Perl::DbLinker::Wxdatasheet>. 

=cut

use strict;
use warnings;
# use Carp qw(confess);
# use Data::Dumper;

use constant {
    UNCHANGED     => 0,
    CHANGED       => 1,
    INSERTED      => 2,
    DELETED       => 3,
    LOCKED        => 4,
};

my %fieldtype = (
    serial  => "number",
    varchar => "text",
    char    => "text",
    integer => "number",
    enum    => "text",
    date    => "time",
    boolean => "boolean",
    set     => "text",
);

use constant STATUS_LAB => ( ' ', '!', '*', 'x', 'o' );

=head2 new

parameters:

=over

=item cols

Array ref of fields name

=item dman 

A xxxDataManager object

=back

    $self->{ds_helper} = Gtk2::Ex::DbLinker::DatasheetHelper->new(
        cols       => $self->{cols},
        dman       => $self->{dman},
    );

=cut

sub new {
    my $class = shift;
    my %def   = ();
    my %arg   = ( ref $_[0] eq "HASH" ? ( %def, %{ $_[0] } ) : ( %def, @_ ) );
    my $missing;
    my $self;
    @$self{ keys %arg } = values(%arg);
    bless $self, $class;
     $self->{log} = Log::Log4perl->get_logger(__PACKAGE__);
    $self->{log}->logconfess( __PACKAGE__, " new : ", join( " ", @$missing ), " keys with values missing" ) if ( defined( $missing = $self->_get_missing_arg( \%arg, [qw(cols dman)] ) ) );
    $self->{log}->debug("new called ** cols are ", join(" ", @{ $self->{cols}}) );
    my %hcols = map { $_ => 1 } @{ $self->{cols} };
    $self->{hcols} = \%hcols;
    return $self;
}

sub _has_more_row {
    my $self = shift;

    # $self->_next;
    return $self->{has_more_row};

}

sub _get_val {
    my $self = shift;
    my ( $row, $col, $name ) = @_;
    $self->{log}->debug("_get_val \$name: ", (defined $name ? $name : "undef"));
    #wx grid : $col is -1 without a corresponding name
    #so the call to colnumber_from_name fails
    #return undef for db columns (from @cols) not in the @fields list
    #return unless defined $self->colnumber_from_name($name);
    $self->{log}->logconfess ("col number undef") unless defined $col;
    # $self->{log}->debug( "_get_val \n", Dumper $row);
    $self->{get_val}->( $row, $col, $name );

}

sub _set_val {
    my $self = shift;
    my ( $row, $col, $val ) = @_;
    $self->{log}->debug( "_set_val row: ", $row, " col: ", $col, " val: ", $val );
    $self->{set_val}->( $row, $col, $val );
}

sub _get_row {
    my $self = shift;
    $self->{iter};
}

sub _next {
    my $self = shift;
    my $iter = $self->{next}->( $self->{iter} );
    $self->{has_more_row} = ( defined $iter ? 1 : 0 );
    $self->{curr_row}++;
    $self->{iter} = $iter;

}

=head2 init_apply

In a datasheet module, calls init_apply to pass a list of code refs that will be used when apply is called.

Mandatory parameters: a list of function references, the keys are

=over

=item next

returning the next row. Parameter the current iterator or row number 

=item set_val

setting the value for a given row and column. Parameters are row and column number, value

=item get_val

returning the value for a given row and column. Parameters: row and column number

=item del_row

deleting a row. Parameter: row and column number

=item has_more_row

returning 1 or 0 if there are more rows after the curreont one. 

=item iter

the iterator or row position of the first row.

=item status_col

the position of the status column or -1 if the status is set as a row label (ie a property of the row instead of a modified column).

=back

    $self->{ds_helper}->init_apply(
   	sig =>  $self->{changed_signal},
	sig_block => sub { $self->{log}->debug("sig_block"); $model->signal_handler_block($_[0])},
   	sig_unblock =>  sub { $model->signal_handler_unblock($_[0]) },
   	next =>  sub {$model->iter_next($_[0])},
   	get_val => sub {$self->{log}->debug("get_val col: ", $_[1]); 
                                my $x = $model->get($_[0], $_[1]); 
                                $self->{log}->debug("get_val found ",  $x); 
                                 return $x
                        },
   	set_val => sub {  $self->{log}->debug("set_val", $_[2]); $model->set($_[0], $_[1], $_[2])},
   	del_row =>  sub  { $model->remove($_[0]) },
   	has_more_row => sub { return ( defined $iter ? 1 : 0 )},
	status_col => 0,
    	iter => $iter,

   );


=cut

sub init_apply {
    my $self = shift;
    my %arg = ( ref $_[0] eq "HASH" ? %$_[0] : (@_) );

    #my @given  = keys %arg;
    #my @needed = qw(next get_val set_val del_row has_more_row iter);
    my $missing;
     $self->{log}->logconfess( __PACKAGE__, " init : ", join( " ", @$missing ), " keys with code ref missing" ) if ( defined( $missing = $self->_get_missing_arg( \%arg, [qw(next get_val set_val del_row has_more_row iter status_col)] ) ) );

    #$self->{log}->debug( Dumper %seen);
    @$self{ ( keys %arg ) } = values %arg;
    $self->{curr_row} = 0;

}

=head2 get_gui_type

Returns the home_made userinterface types (text, boolean, time, number) using the hash %fieldtype

Param: the type from the database (serial, integer, varchar, set, boolean ...)

=cut

sub get_gui_type {
	my ($self, $dbtype) = @_;
	$fieldtype{ $dbtype };
}

=head2 get_grid_fields

Return the names of the columns passed in the fields arg

=cut

sub get_grid_fields {
    my $self = shift;
    return keys %{$self->{colname_to_number}};

}

=head2 colnumber_from_name

Return the column position (0 based)

Param: the name of the column.

=cut

sub colnumber_from_name {

    my ( $self, $fieldname ) = @_;
     $self->{log}->logconfess( "fieldname undef") unless ( defined $fieldname );
    
    return $self->{colname_to_number}->{$fieldname}

}

=head2 apply

Call apply after init to transmit to the database via the datamanager, the changes (a row deletion, a row addition, a row modification) made in the datasheet

=cut

sub apply {
    my $self = shift;
    my $pkref = ( defined $_[0] ? $_[0] : undef );
    my @iters_to_remove;
    my @rowpos_to_remove;

    #my $row_pos = 0;
    my $row;
    $self->{log}->debug( "apply called dman->row_count : ", $self->{dman}->row_count );
    #  $self->{log}->debug( "pkref ", Dumper($pkref) ) if ($pkref);
    my @fields_to_save;
    if ($pkref) {
        my %seen;    #remove from cols the fields received in arg
        %seen = map { $_ => $seen{$_}++ } ( @{ $self->{cols} }, @{$pkref} );
        @fields_to_save = grep { $seen{$_} < 1 } keys %seen;
    } else {
        # bug here ? since $self->cols holds field name from the tables that 
        # could not be in the grid 
        # @fields_to_save = @{ $self->{cols} };
        @fields_to_save = $self->get_grid_fields;
        $self->{log}->debug("grid_fields ", join(" ", @fields_to_save));
    }
    $self->{sig_block}->( $self->{sig} ) if ( $self->{sig} );
    while ( $self->_has_more_row ) {
        my $status = $self->_get_val( $self->_get_row, $self->{status_col} );
        $self->{log}->debug( "status ", ( defined $status ? $status : " undef") );
        $self->{dman}->set_row_pos( $self->{curr_row} );
        if ( $status == UNCHANGED || $status == LOCKED ) {
            $self->{log}->debug("move to next row without saving");
            $self->_next;
            next;
        }

        if ( $status == INSERTED ) {    # new row for the database
            $self->{dman}->new_row;
        }

        if ( $status == DELETED ) {

            push @iters_to_remove,  $self->_get_row;
            push @rowpos_to_remove, $self->{curr_row};

        } else {    #update, insert
            my $count_update;

            #for my $field ( @{$self->{fields}} )
            for my $name (@fields_to_save) {

                #my $name = $field->{name};

                # if ( $field->{name} ~~ @{$self->{cols}})
                if ( defined $self->{hcols}->{$name} ) {

                    #die ref $self->{col_number};
                    my $col = $self->colnumber_from_name($name);

                    my $x = $self->_get_val( $self->_get_row, $col, $name );

                    # $model->get( $iter, $self->{colname_to_number}->{$name} );
                    $count_update++;
                    $self->{log}->debug( "Set dman field: " . $name . " col_pos " . $col . " row_pos " . $self->{curr_row} . " value: " . ( defined  $x ? $x : "undef" ) );
                    $self->{dman}->set_field( $name, $x );

                } else {
                    $self->{log}->debug( "apply : " . $name . " not found in " . join( " ", @{ $self->{cols} } ) );

                }

            }    # for
            if ($count_update) {
                $self->{log}->debug("saving...");

                #$row->save;
                $self->{dman}->save;
            } else {
                $self->{log}->debug("no field updated, not saving");
            }

            #$row_pos++;
            #$iter = $model->iter_next($iter);

        }    #else update / insert

        #replace the unchanged icon in the col 0
        #with Wx widget the row label is not delete with the row it stay for the row at pos i
        #
        $self->_set_val( $self->_get_row, $self->{status_col}, UNCHANGED );

        $self->_next;
    }    # while

    foreach my $i (@iters_to_remove) {

        #$self->{log}->debug("deleting in the datasheet and in the db row: ", $rowpos_to_remove[$i] );
        #$model->remove($iter);
        #$self->{log}->debug("iters ", Dumper (@iters_to_remove));
        #$self->{log}->debug("rowpos ", Dumper (@rowpos_to_remove));
        $self->{del_row}->($i);
        my $row_pos = shift @rowpos_to_remove;
        $self->{log}->debug( "deleting in dman at row : ", $row_pos );
        $self->{dman}->set_row_pos($row_pos);
        $self->{dman}->delete;
    }

    $self->{sig_unblock}->( $self->{sig} ) if ( $self->{sig} );
}    # apply

=head2 setup_fields

Must be called after new, to build the colname_to_number hash used by colnumber_from_name and by get_grid_fields.
Return an array ref of hash ref defining the fields of the grid + an array ref of the names of the columns of the underlying table.

Parameters

=over

=item allfields 

A reference to an array of hash ref received in the constructor of the datasheet object holding the fields used in the grid. 
This array ref is returned completed with the render

=item cols

A array ref of the names of the columns in the table

=item status_col

The fields definitions of the first column holding the bitmap with Gtk2. Not use with Wx.

=back

=cut

sub setup_fields {
	my $self = shift;
	my %args =  ( ref $_[0] eq "HASH" ? %$_[0] : (@_) );
	my $missing;
	  $self->{log}->logconfess( __PACKAGE__, "setup_fields : ", join( " ", @$missing ), " keys with value missing" ) if ( defined( $missing = $self->_get_missing_arg( \%args, [qw(allfields cols )] ) ) );
	my $fields = $args{allfields};

	    if ( !$fields ) {
        my $no_of_fields = scalar @{ $args{cols} };
        my $field_percentage =
          $no_of_fields < 8
          ? 100 / $no_of_fields
          : 12.5;    # Don't set percentages < 12.5 - doesn't really work so well ...
        for my $field ( @{ $args{cols} } ) {
            my $gtktype = $fieldtype{ $self->{dman}->get_field_type($field) };
            push @{ $fields },
              {
                name      => $field,
                x_percent => $field_percentage,
                renderer  => $gtktype,
              };
            $self->{log}->debug( " * set field : " . $field . " renderer : " . $gtktype );
        }
    }

    if ($args{status_col}){
    
        # Gtk2::Ex::DbLinker::Datasheet Put a _status_column_ at the front of $self->{fields}
         $self->{log}->debug("add ", $args{status_col}, " on top of \@{ \$fields }");
        unshift @{ $fields }, $args{status_col};

    } #if

       my $column_no=0;
       my %name2pos;
       my @hiddencols;
    for my $field ( @{ $fields } ) {

        # $self->{log}->debug("field name : " . $field->{name});

	#$self->{colname_to_number}->{ $field->{name} } = $column_no;
	$name2pos{$field->{name}} = $column_no;
	if ( defined $field->{renderer} && $field->{renderer} eq "hidden" ) {
            push @hiddencols, $column_no;
        }

        if ( !$field->{renderer} ) {

            #my $x = ( $fieldtype{ $self->{fieldsType}->{$field->{name}}}  ?  $fieldtype{$self->{fieldsType}->{$field->{name}}} : "text");
            my $ftype = $self->{dman}->get_field_type( $field->{name} );
            my $x = ( $fieldtype{$ftype} ? $fieldtype{$ftype} : "text" );
            $field->{renderer} = $x;
            $self->{log}->debug( "reset renderer for field " . $field->{name} . " to " . $x );

        }

        #if ($field->{renderer} eq "combo") {
        #    $self->setup_combo($field->{name});
        #}
        $self->{log}->debug( " ** set field : " . $field->{name} . " renderer : " . $field->{renderer} );
        $field->{column} = $column_no++;
    }

$self->{colname_to_number} = \%name2pos;
# $self->{log}->debug("setup_fields colname_to_number hash:", Dumper %{$self->{colname_to_number}});
return ( $fields, \@hiddencols);


}

=head2 init_combo_setup

Calls in datasheet->_set_upcombo to build the array of column names. Return the array reference.

parameters

=over

=item fields 

Array ref of hash ref received in the datasheet constructor 

=item name

Name of the field return by the combo, corresponding to a field in the underlying table

=back

=cut

sub init_combo_setup {

	my $self = shift;
	my %args =  ( ref $_[0] eq "HASH" ? %$_[0] : (@_) );
	my $missing;
	  $self->{log}->logconfess( __PACKAGE__, " init_combo_setup : ", join( " ", @$missing ), " keys with value missing" ) if ( defined( $missing = $self->_get_missing_arg( \%args, [qw(name fields)] ) ) );
	   my $fields = $args{fields};
    my @cols;
    if ( $fields->{fieldnames} ) {
        @cols = @{$fields->{fieldnames} };
    } else {
        @cols = $fields->{data_manager}->get_field_names;
    }
    return \@cols;

}

=head2 get_liste_def

Calls by Gtk2::Ex::DbLinker:Datasheet->_set_upcombo to build the array that will construct the model. Return this array.

parameters

=over

=item fields 

Array ref of hash ref received in the datasheet constructor 


=item col_ref

Array ref of the fields in the combo

=item renderer 

A hash reference of type return by C<%fieldtype> and an array ref of two elements. The first is a code ref to a Gtk2::CellRenderer constructor of the corresponding type. The second is the corresponding Glib type. Use for the id of the combo.

=item default_renderer

A string of the Glib type to use for the the column(s) displayed in the combo.

=back

=cut

sub get_liste_def {

	my $self = shift;
	my %args =  ( ref $_[0] eq "HASH" ? %$_[0] : (@_) );
	my $missing;
	  $self->{log}->logconfess( __PACKAGE__, " get_liste_def : ", join( " ", @$missing ), " keys with value missing" ) if ( defined( $missing = $self->_get_missing_arg( \%args, [qw(fields renderer default_renderer col_ref)] ) ) );
    my $fields = $args{fields};
    my @cols = @{$args{col_ref}};
    my $rdbtype = $fieldtype{ $fields->{data_manager}->get_field_type( $cols[0] ) };
    my @liste_def;
    my $pos = 0;
    foreach my $name (@cols) {
        if ( $pos++ == 0 ) {

            push @liste_def, $args{renderer}->{$rdbtype}[1];

            # push @liste_def, "Glib::String";
        } else {
            push @liste_def, $args{default_renderer};
        }

    }
 return @liste_def;
}

=head2 setup_combo

Calls by datasheet->_set_upcombo in _setup_grid or _setup_treeview. 

parameters

=over

=item fields 

Array ref of hash ref received in the datasheet constructor 

=item name

Name of the field return by the combo, corresponding to a field in the underlying table

=item col_ref

Array ref of the fields in the combo

=item model

For C<Gtk2::Ex::Datasheet> the Treemodel of the combo, or undef

=back

Return the C<$model> with the combo rows if C<$model> was given or a list of two array ref: the rows displayed in the combo, and the id returned by the combo

=cut

sub setup_combo {
    my $self = shift;
    my %args = ( ref $_[0] eq "HASH" ? %$_[0] : (@_) );
    my $missing;
     $self->{log}->logconfess( __PACKAGE__, " setup_combo : ", join( " ", @$missing ), " keys with value missing" ) if ( defined( $missing = $self->_get_missing_arg( \%args, [qw(fields name col_ref)] ) ) );
    my $fields    = $args{fields};
    my $column_no = $self->colnumber_from_name( $args{name} );
    my $dman      = $fields->{data_manager};
    my $last      = $dman->row_count;

    $self->{log}->debug( "setup_combo cols : " . join( " ", @{ $args{col_ref} } ) );
    my @rows;
    my @ids;
    my $model = $args{model};

    for ( my $row_pos = 0 ; $row_pos < $last ; $row_pos++ ) {
        $dman->set_row_pos($row_pos);
        my @model_row;
        push @model_row, $model->append if ($model);

        my $lastcol = @{ $args{col_ref} } - 1;
        my $rowval;
        my $pos = 0;

        foreach my $name ( @{ $args{col_ref} } ) {

            #push @model_row, $pos++, $row->$name();
            if ( $pos == 0 ) { push @ids, $dman->get_field($name); }
            else {
                $rowval .= $dman->get_field($name) . " ";
            }
            push @rows, $rowval if ( $pos == $lastcol );
            push @model_row, $pos, $dman->get_field($name);
            $pos++;

        }
        $model->set(@model_row) if ($model);

    }

    defined $model ? return $model : return ( \@rows, \@ids );
}

=head2 _get_missing_arg

  sub method
    my $self = shift;
    my %arg = ( ref $_[0] eq "HASH" ? %$_[0] : (@_) );
    my $missing;
     $self->{log}->logconfess( __PACKAGE__, " method : ", join( " ", @$missing ), " keys with code ref missing" )
           if ( defined( $missing = $self->_get_missing_arg
               ( 
		    \%arg, 
		     [qw(next get_val set_val del_row has_more_row iter status_col)] 
	       ) 
             ) );

Return an array ref of missing parameters

Parameters:

=over

=item *

A hash ref of the parameters received by the methods to check. The hash is of the form name => value, ...

=item *

An array ref of the required argument names

=back

=cut

sub _get_missing_arg {

    my ( $self, $arg, $needed ) = @_;
    my @given = keys %$arg;
    my %seen;    #find if some value from needed are not in arg
    %seen = map { $_ => $seen{$_}++ } @given;
    my @missing;
    foreach my $v (@$needed) {

        #$self->{log}->debug("Testing arg $v", exists $seen{$v} ? " found it " : " not found");
        push @missing, $v unless ( exists $seen{$v} );
    }
    #$self->{log}->debug("missing array ", (@missing ? " not empty": " empty"));
    return ( @missing ? \@missing : undef );

}

1;

__END__

=head1 SUPPORT

Any Gk2::Ex::DbLinker questions or problems can be posted to me (rappazf) on my gmail account.  

The current state of the source can be extract using Mercurial from
L<http://sourceforge.net/projects/gtk2-ex-dblinker/>.

=head1 AUTHOR

FranE<ccedil>ois Rappaz <rappazf@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2016-2017 by F. Rappaz.  All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=head1 SEE ALSO

L<Gtk2::Ex::DbLinker::Datasheet> L<Wx::Perl::DbLinker::Wxdatasheet>.

=cut
