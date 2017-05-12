package Gantry::Utils::ModelHelper;
use strict; use warnings;

sub import {
    my $class   = shift;

    my $callpkg = caller( 0 );

    foreach my $method ( @_ ) {
        if ( $method eq 'auth_db_Main' ) {
            no strict;
            *{ "$callpkg\::db_Main" } = \&{ "$class\::auth_db_Main" };
        }
        else {
            no strict;
            *{ "$callpkg\::$method" } = \&{ "$class\::$method" };
        }
    }
} # END of import

#----------------------------------------------------------------------
# db_Main
# compatible with Class::DBI and Gantry::Plugins::DBIxClassConn
#----------------------------------------------------------------------
sub db_Main {
    my $invocant = shift;
    my $class    = ( ref $invocant ) ? ref $invocant : $invocant;

    my $dbh;

    my $helper = Gantry::Utils::DBConnHelper->get_subclass();

    $dbh       = $helper->get_dbh();

    if ( not $dbh ) {
        my $conn_info  = $helper->get_conn_info();

        my $db_options = $class->get_db_options();

        $db_options->{AutoCommit} = 0 unless defined $db_options->{AutoCommit};

        $dbh = DBI->connect(
                $conn_info->{ 'dbconn' },
                $conn_info->{ 'dbuser' },
                $conn_info->{ 'dbpass' },
                $db_options
        );
        $helper->set_dbh( $dbh );
    }
    
    return $dbh;

} # end db_Main

#----------------------------------------------------------------------
# auth_db_Main
# compatible with Class::DBI and Gantry::Plugins::DBIxClassConn
#----------------------------------------------------------------------
sub auth_db_Main {
    my $invocant = shift;
    my $class    = ( ref $invocant ) ? ref $invocant : $invocant;

    my $auth_dbh;

    my $helper   = Gantry::Utils::DBConnHelper->get_subclass();

    $auth_dbh    = $helper->get_auth_dbh();

    if ( not $auth_dbh ) {
        my $auth_conn_info  = $helper->get_auth_conn_info();

        my $db_options = $class->get_db_options();

        $db_options->{AutoCommit} = 0 unless defined $db_options->{AutoCommit};
        
        $auth_dbh = DBI->connect(
                $auth_conn_info->{ 'auth_dbconn' },
                $auth_conn_info->{ 'auth_dbuser' },
                $auth_conn_info->{ 'auth_dbpass' },
                $db_options
        );
        $helper->set_auth_dbh( $auth_dbh );
    }

    return $auth_dbh;

} # end auth_db_Main

#-------------------------------------------------
# $class->get_listing
#-------------------------------------------------
sub get_listing {
    my ( $class, $params ) = @_;

    my $f_display_fields = [];
    eval {
        $f_display_fields = $class->get_foreign_display_fields;
    };
    
    if ( $params->{order_by} ) {
        return $class->retrieve_all( order_by => $params->{order_by} );
    }
    elsif ( $f_display_fields ) {
        return $class->retrieve_all( 
            order_by => join( ', ', @{ $f_display_fields } ) 
        );
    }
    else {
        return $class->retrieve_all( );
    }

}

#-------------------------------------------------
# $class->retrieve_all_for_main_listing
# DEPRECATED
#-------------------------------------------------
sub retrieve_all_for_main_listing {
    my ( $class, $order_fields ) = ( shift, shift );

    $order_fields ||= join ', ', @{ $class->get_foreign_display_fields };

    return( $class->retrieve_all( order_by => $order_fields ) );

} # retrieve_all_for_main_listing

#-------------------------------------------------
# $class->get_form_selctions
#-------------------------------------------------
sub get_form_selections {
    my $class = shift;

    my %retval;

    # foreach foreign key get a selection list
    FOREIGN_TABLE:
    foreach my $foreign_table ( $class->get_foreign_tables() ) {

        my $short_table_name = $foreign_table;
        $short_table_name    =~ s/.*:://;

        my $foreigners;

        eval {
            $foreigners = $foreign_table->get_foreign_display_fields();
        };
        if ( $@ ) {
            warn $@;
            next FOREIGN_TABLE;
        }

        my $order_by         = join ', ', @{ $foreigners };

        # get all rows in foreign table ordered by foreign display
        my @foreign_display_rows = $foreign_table->retrieve_all(
                { order_by => $order_by }
        );

        # push into returnable hash
        my @items;
        push( @items, { value => '', label => '- Select -' } );

        foreach my $item ( @foreign_display_rows ) {

            my $label;

            eval {
                $label = $item->foreign_display();
            };
            warn "    ERROR for " . $item->id() . " $@" if $@;

            push @items, {
                value => $item->id(),
                label => $label || '',
            };
        }

        $retval{$short_table_name} = \@items;
    }

    return( \%retval );

} # end get_form_selections

1;

=head1 NAME

Gantry::Utils::ModelHelper - mixin for model base classes

=head1 SYNOPSIS

    use Gantry::Utils::ModelHelper qw(
        db_Main
        get_listing
        get_form_selections
    );

    sub get_db_options {
        return {};  # put your default options here
        # consider calling __PACKAGE->_default_attributes
    }

=head1 DESCRIPTION

This module provides mixin methods commonly needed by model base classes.
Note that you must request the methods you want for the mixin scheme to
work.  Also note that you can request either db_Main or auth_db_Main, but
not both.  Whichever one you choose will be exported as db_Main in your
package.

=head1 METHODS

=over 4

=item db_Main

This method returns a valid dbh using the scheme described in
Gantry::Docs::DBConn.  It is compatible with Class::DBI and
Gantry::Plugins::DBIxClassConn (the later is a mixin which allows
easy access to a DBIx::Schema object for controllers).

=item auth_db_Main

This method is exported as db_Main and works with the scheme described
in Gantry::Docs::DBConn.  It too is compatible with Class::DBI and
Gantry::Plugins::DBIxClassConn.

I will repeat, if you ask for this method in your use statement:

    use lib/Gantry/Utils/ModelHelper qw( auth_db_Main ... );

it will come into your namespace as db_Main.

=item get_form_selections

This method gives you a selection list for each foriegn key in your
table.  The lists come to you as a single hash keyed by the table names
of the foreign keys.  The values in the hash are ready for use
by form.tt as options on the field (whose type should be select).
Example:

    {
        status => [
            { value => 2, label => 'Billed' },
            { value => 1, label => 'In Progress' },
            { value => 3, label => 'Paid' },
        ],
        other_table => [ ... ],
    }

To use this method, your models must implement these class methods:

=over 4

=item get_foreign_tables

(Must be implemented by the model on which get_form_selections is called.)
Returns a list of the fully qualified package names of the models
of this table's foreign keys.  Example:

    sub get_foreign_tables {
        return qw(
            Apps::AppName::Model::users
            Apps::AppName::Model::other_table
        );
    }

=item get_foreign_display_fields

(Must be implemented by all the models of this table's foreign keys.)
Returns an array reference whose elements are the names of the columns
which will appear on the screen in the selection list.  Example:

    sub get_foreign_display_fields {
        return [ qw( last_name first_name ) ];
    }

=back

=item get_listing

Replacement for retrieve_all_for_main_listing.

Returns a list of row objects (one for each row in the table).  The
ORDER BY clause is either the same as the foreign_display columns
or chosen by you.  If you want to supply the order do it like this:

    my @rows = $MODEL->get_listing ( { order_by => 'last, first' } );

Note that your order_by will be used AS IS, so it must be a valid SQL
ORDER BY clause, but feel free to include DESC or anything else you and SQL
like.

=item retrieve_all_for_main_listing

DEPRECATED use get_listing instead

Returns a list of row objects (one for each row in the table) in order
by their foreign_display columns.

=back

=head1 AUTHOR

Phil Crow <philcrow2000@yahoo.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
