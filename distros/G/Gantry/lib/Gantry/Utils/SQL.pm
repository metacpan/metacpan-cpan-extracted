package Gantry::Utils::SQL;
use strict; 

use Carp qw( confess );

############################################################
# Variables                                                #
############################################################
############################################################
# Functions                                                #
############################################################
sub new {
    my ( $class, $opt ) = @_;

    my $self = {};  
    bless( $self, $class );

    # populate self with data from site
    return( $self );    

} # end new

#-------------------------------------------------
# $sql_helper->sql_bool( $bool_string )
#-------------------------------------------------
sub sql_bool {
    my( $self, $input ) = shift;

    return( 'FALSE' ) if ( ( ! defined $input ) || ( ! length $input ) );

    if ( $input =~ /^(t|y|1)$/i ) {
        return( 'TRUE' );
    }
    elsif ( $input =~ /^(f|n|0)$/i ) {
        return( 'FALSE' );
    }
    elsif ( defined $input ) {
        return( 'TRUE' );
    }
    else {
        return( 'FALSE' );
    }

} # END sql_bool

#-------------------------------------------------
# $sql_helper->sql_insert( $table, %data )
#-------------------------------------------------
sub sql_insert {
    my ( $self, $table, @vals ) = @_;

    my ( @fields, @values );

    while ( @vals ) {
    push ( @fields, shift( @vals ) );
        
        if ( @vals ) {
            push( @values, shift( @vals ) );
        }
        else {
            confess( 'Error: Incorrect number of arguements.' );
        }
    }

    return( "INSERT INTO $table ( ". join( ', ', @fields ). ' ) VALUES ( '. 
            join( ', ', @values ). ' )' );
} # END sql_insert 

#-------------------------------------------------
# $sql_helper->sql_num( $number )
#-------------------------------------------------
sub sql_num {
    my ( $self, $number ) = ( shift, shift );

    return( 'NULL' ) if ( ( ! defined $number ) || ! length ( $number) );

    $number =~ s/\\/\\\\/g;
    $number =~ s/\'/\\'/g;
    
    return( "'$number'" );
} # END sql_num

#-------------------------------------------------
# $sql_helper->sql_str( $string )
#-------------------------------------------------
sub sql_str {
    my( $self, $string ) = ( shift, shift );

    return( "''" ) if ( !defined( $string ) || ! length( $string ) );

    $string =~ s/\\/\\\\/g;
    $string =~ s/\'/\\'/g;

    return( "'$string'" );
} # END sql_str

#-------------------------------------------------
# $sql_helper->sql_update( $table, $clause, $data )
#-------------------------------------------------
sub sql_update {
    my ( $self, $table, $clause, @vals ) = @_;

    $clause = '' if ( ! defined $clause );

    my @updates;

    while ( @vals ) {
        my $field = shift( @vals );
        
        if ( @vals ) {
            push( @updates, "$field=". shift( @vals ) );
        }
        else {
            confess( 'Error: Incorrect number of arguements.' );
        }
    }

    return( "UPDATE $table SET ". join( ', ', @updates ). ' '. $clause );
} # END sql_update

#-------------------------------------------------
# $sql_helper->sql_quote( $string )
#-------------------------------------------------
sub sql_quote {
    my ( $self, $sql ) = ( shift, shift );

    return( '' ) if ( ! defined $sql );

    $sql =~ s/\\/\\\\/g;
    $sql =~ s/'/''/g;

    return( $sql );
} # END sql_quote

# EOF
1;

__END__

=head1 NAME 

Gantry::Utils::SQL - SQL routines.

=head1 SYNOPSIS

 my $sql = Gantry::Utils::SQL->new();

 $sql_boolean = $sql->sql_bool( $string );

 $sql = $sql->sql_insert( $table, %vals );

 $sql_number = $sql->sql_num( $number );
  
 $sql_string = $sql->sql_str( $string );
  
 $sql = $sql->sql_update( $table, $clause, %vals );
  
 $sql_quoted = $sql->sql_quote( $string );

=head1 DESCRIPTION

This module supplies easy ways to make strings sql safe as well as 
allowing the creation of sql commands. All of these commands should 
work with any database as they do not do anything database specfic, 
well as far as I know anyways.

=head1 METHODS 

=over 4

=item new

Standard constructor.  Call it first to gain a helper through which to
call the other methods.  Pass it nothing.

=item $sql_boolean = $sql_helper->sql_bool( $string )

This function takes a string and returns either TRUE or FALSE depending 
on whether or not the function thinks it's true or not. True is defined 
as containing any of the following, 't', 'y', '1', or after
the false test if the string is defined. False is defined as 'f', 'n' or '0'.
Defined and not false is true, and not defined is false. Hopefully this 
is fairly confusing. 

=item $sql = $sql_helper->sql_insert( $table, %vals )

This function takes the table to insert into C<$table'>, and the information
to insert into said table, C<%vals>. The function will build an insert 
statement based on this information. The C<%vals> variable should contain
the keys corrisponding to the columns in the database where the values
should be the values to insert into those fields. The function will return,
hopefully, a valid sql insert string.

=item $sql_number = $sql_helper->sql_num( $number )

This function takes a number, C<$number>, and quotes it in such a way as 
it may be used in a sql call safely. It handles anything that is a number 
at all. A properly quoted number is return, including the quotes.

=item $sql_string = $sql_helper->sql_str( $string )

This function takes a string, C<$string>, and quotes in in such a way as 
it may be used safely in a sql call. The string is then returned, including
the quotes arround it.

=item $sql = $sql_helper->sql_update( $table, $clause, %vals )

This function creates a valid sql update string. It is identical in form
to the C<sql_insert()> function save it takes a where clause, C<$clause>.
The clause must contain a valid test against the database, in a pinch use
a where clause that will always return true. The 'WHERE' in the clause need
not be supplied as it is assumed and alwas inserted into the update string.
A valid sql update string is returned, hopefully anyways.

=item $sql_quoted = $sql_helper->sql_quote( $string )

This function works the same way as C<sql_str()> save it doesn't really
care what it opperates on. A properly quoted version of whatever is passed
in is returned.

=back

=head1 SEE ALSO

Gantry(3), Gantry::Utils::DB(3)

=head1 LIMITATIONS

There is no sql_date function, which there probably should be.

The quoting method has been tested with Postgresql.

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>
Nicholas Studt <nstudt@angrydwarf.org>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
