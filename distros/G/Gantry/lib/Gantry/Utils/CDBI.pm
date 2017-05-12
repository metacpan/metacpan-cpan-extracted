package Gantry::Utils::CDBI;
use strict; use warnings;

use Gantry::Utils::ModelHelper qw(
    db_Main
    retrieve_all_for_main_listing
    get_listing
    get_form_selections
);

use POSIX qw( strftime );

use base 'Class::DBI::Sweet';

my $db_options = { __PACKAGE__->_default_attributes, AutoCommit => 0 };

__PACKAGE__->_remember_handle('Main');

sub get_db_options {
    return $db_options;
}

#-------------------------------------------------
# db_Main
#-------------------------------------------------   
# This method is exported by Gantry::Utils::ModelHelper

#-------------------------------------------------
# $class->get_form_selctions
#-------------------------------------------------
# This method is exported by Gantry::Utils::ModelHelper

#-------------------------------------------------
# $class->get_listing
#-------------------------------------------------
# This method is exported by Gantry::Utils::ModelHelper

#-------------------------------------------------
# $class->retrieve_all_for_main_listing
#-------------------------------------------------
# This deprecated method is exported by Gantry::Utils::ModelHelper

#-------------------------------------------------
# $class->pretty_date( $strftime_format, $sql_date )
#-------------------------------------------------
sub pretty_date {
    my ( $class, $fmt, $input_date ) = @_;

    return unless defined $input_date and $input_date;

    my ( $date, $time )         = split /\s+/, $input_date;
    my ( $year, $mon, $day )    = split /-/,   $date;
    my ( $trim_time, $useless ) = split /\./,  $time;
    my ( $hour, $min, $sec )    = split /:/,   $trim_time;

    my $output_time = strftime(
            $fmt,
            $sec, $min, $hour,
            $day, $mon - 1, $year - 1900
    );

    return $output_time;
}

1;

=head1 NAME

Gantry::Utils::CDBI - Class::DBI base class for Gantry applications

=head1 SYNOPSIS

This module expects to retrieve the database connection,
username, and password from one of two places.

=head2 In mod_perl

If it lives in mod_perl, it expects these to come
from the apache conf file.  You might supply them like this:

    <Location / >
        PerlSetVar dbconn 'dbi:Pg:dbname=your_db_name'
        PerlSetVar dbuser 'your_user'
        PerlSetVar dbpass 'your_password'
    </Location>

It then retrieves them roughly like this (the mod_perl version affects this):

    $r = Apache->request();

    $r->dir_config( 'dbconn' ),  
    $r->dir_config( 'dbuser' ),
    $r->dir_config( 'dbpass' ),

The handle is cached using pnotes to avoid recreating it.

=head2 In scripts

On the other hand, if the module does not live in mod_perl, it
needs to directly use Gantry::Utils::DBConnHelper::Script like this:

    use Gantry::Utils::DBConnHelper::Script {
            dbconn => 'dbi:Pg:dbname=your_db_name',
            dbuser => 'your_user',
            dbuser => 'your_pass',
    };

If you can't put the connection info into the use statement (say because
you take it from the command line) do the above in two steps:

    use Gantry::Utils::DBConnHelper::Script;

    # figure out your connection info

    Gantry::Utils::DBConnHelper::Script->set_conn_info(
            dbconn => $dsn,
            dbuser => $dbuser,
            dbuser => $dbpass,
    );

The database handle is cached by the helper.  To get hold of it say:

    my $dbh = Gantry::Utils::DBConnHelper::Script->get_dbh();

=head1 DESCRIPTION

This module provides the base methods for Class:DBI, including the db conection
method within a mod_perl environment.

=head1 METHODS

=over 4

=item get_db_options

Default database attributes usually supplied by Class::DBI's
_default_attributes method.

=item pretty_date

A failed attempt at date format beautification.  Probably should be removed.

=back

Note that these other methods are mixed in from Gantry::Utils::ModelHelper:

    db_Main
    retrieve_all_for_main_listing
    get_form_selections

See its docs for details.

=head1 AUTHOR

Tim Keefer <tkeefer@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2005-6, Tim Keefer.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
