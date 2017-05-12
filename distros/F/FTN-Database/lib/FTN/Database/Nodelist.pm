package FTN::Database::Nodelist;

use warnings;
use strict;
use Carp qw( croak );

=head1 NAME

FTN::Database::Nodelist - Fidonet/FTN Nodelist SQL Database operations.

=head1 VERSION

Version 0.42

=cut

our $VERSION = '0.42';

=head1 DESCRIPTION

FTN::Database::Nodelist is a Perl module containing common nodelist related functions
for Fidonet/FTN Nodelist related processing on a Nodelist table in an SQL Database,
including one that defines the fields for such a Nodelist table. The SQL database
engine is one for which a DBD module exists, defaulting to SQLite.

=head1 EXPORT

The following functions are available in this module:  define_nodelist_table(),
drop_nodelist_table(), ftnnode_index_fields(), remove_ftn_domain().

=head1 FUNCTIONS

=head2 define_nodelist_table

Syntax:  $fields = define_nodelist_table();

This function returns a string that contains the SQL which defines a
Nodelist table for use in an SQL database being used for Fidonet/FTN
processing,

Except for the I<id> field, which is defined in the create_ftn_table
subroutine itself, the defined fields are as follows:

=cut

sub define_nodelist_table {

    my $table_fields = '';

=over 4

=item type

The I<type> field may by empty or may contain one of the following keywords:
Zone, Region, Host, Hub, Pvt, Hold, or Down. Defaults to an empty string, which
indicates a normal nodelist entry.

=cut

    $table_fields  = "type      VARCHAR(6) DEFAULT '' NOT NULL, ";

=item zone

The I<zone> field is a number in the range of 0 to 32767 that is the zone number
for a particular nodelist table entry. Defaults to the number one.

=cut

    $table_fields .= "zone      SMALLINT  DEFAULT '1' NOT NULL, ";

=item net

The I<net> field is used to contain a number in the range of 0 to 32767 that is
the net number for a particular nodelist table entry. Defaults to the number one.

=cut

    $table_fields .= "net       SMALLINT  DEFAULT '1' NOT NULL, ";

=item node

The I<node> field is used to contain a number in the range of 0 to 32767 that is
the node number for a particular nodelist table entry. Defaults to the number one.

=cut

    $table_fields .= "node      SMALLINT  DEFAULT '1' NOT NULL, ";

=item point

The I<point> field is used to contain a number in the range of 0 to 32767 that is
the point number for a particular nodelist table entry. Defaults to the number zero.

=cut

    $table_fields .= "point     SMALLINT  DEFAULT '0' NOT NULL, ";

=item region

The I<region> field is used to contain a number in the range of 0 to 32767 that is
the region number for a particular nodelist table entry. Defaults to the number zero.

=cut

    $table_fields .= "region    SMALLINT  DEFAULT '0' NOT NULL, ";

=item name

The I<name> field is used to contain the system name as a string.
It can contain up to 48 characters and defaults to an empty string.

=cut

    $table_fields .= "name      VARCHAR(48) DEFAULT '' NOT NULL, ";

=item location

The I<location> field is used to contain the location of the system as a string.
It can contain up to 48 characters and defaults to an empty string.

=cut

    $table_fields .= "location  VARCHAR(48) DEFAULT '' NOT NULL, ";

=item sysop

The I<sysop> field is used to contain a string indicating the system operator.
It can contain up to 48 characters and defaults to an empty string.

=cut

    $table_fields .= "sysop     VARCHAR(48) DEFAULT '' NOT NULL, ";

=item phone

The I<phone> field is used to contain a string indicating the phone number for
the system. It can contain up to 32 characters and defaults to the string
I<'000-000-000-000>.

=cut

    $table_fields .= "phone     VARCHAR(32) DEFAULT '000-000-000-000' NOT NULL, ";

=item baud

The I<baud> field is used to contain the baud rate for the system that a particular
nodelist table entry is for. It can contain up to 6 characters and defaults to I<300>.

=cut

    $table_fields .= "baud      CHAR(6) DEFAULT '300' NOT NULL, ";

=item flags

The I<flags> field is used to contain the nodelist flags for the system that a particular
nodelist table entry is for. It can contain up to 128 characters and defaults to a string
containing a single space.

=cut

    $table_fields .= "flags     VARCHAR(128) DEFAULT ' ' NOT NULL, ";

=item domain

The I<domain> field is used to contain the domain name for the system that a particular
nodelist table entry is for. It can contain up to 8 characters and defaults to the
string I<fidonet>.

=cut

    $table_fields .= "domain    VARCHAR(8) DEFAULT 'fidonet' NOT NULL, ";

=item ftnyear

The I<ftnyear> field is used to contain the 4 digit integer representing the 
year that a particular nodelist table entry is valid. Defaults to the number
zero.

=cut

    $table_fields .= "ftnyear   SMALLINT  DEFAULT '0' NOT NULL, ";

=item yearday

The I<yearday> field is used to contain the three digit day of the year that
a particular nodelist table entry is valid for. Defaults to the number zero.

=cut

    $table_fields .= "yearday   SMALLINT  DEFAULT '0' NOT NULL, ";

=item source

The I<source> field is used to indicate the source of the data that a particular
nodelist table entry is from. For instance, it could be used to give the name of
the nodelist file that the data is from. It can contain up to 16 characters and
defaults to the string I<local>.

=cut

    $table_fields .= "source    VARCHAR(16) DEFAULT 'local' NOT NULL, ";

=item updated

The I<updated> field is used to contain a timestamp for when a particular
nodelist table entry was last updated. Defaults to now.

=back

=cut

    $table_fields .= "updated   TIMESTAMP DEFAULT 'now' NOT NULL ";

    return($table_fields);

}

=head2 ftnnode_index_fields

Syntax:  $fields = ftnnode_index_fields();

This is a function that returns a string containing a comma separated list of
the fields that are intended for use in creating the ftnnode database index.
The index contains the following fields:  zone, net, node, point, domain,
ftnyear, and yearday.

=cut

sub ftnnode_index_fields {

    my $field_list = 'zone,net,node,point,domain,ftnyear,yearday';

    return($field_list);

}

=head1 EXAMPLES

An example of opening an FTN database, then creating a nodelist table,
loading data to it, then creating an index on it, and the closing
the database:

    use FTN::Database;
    use FTN::Database::Nodelist;

    my $db_handle = open_ftn_database(\%db_option);
    $fields = define_nodelist_table();
    create_ftn_table($db_handle, $table_name, $fields);
    ...   (Load data to nodelist table)
    ftnnode_index_tables($db_handle, $table_name);
    close_ftn_database($db_handle);

=head1 AUTHOR

Robert James Clay, C<< <jame at rocasa.us> >>

=head1 BUGS

Please report any bugs or feature requests via the web interface at
L<https://sourceforge.net/p/ftnpl/ftn-database/tickets/>. I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Note that you can also report any bugs or feature requests to
C<bug-ftn-database at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FTN-Database>;
however, the FTN-Database Issue tracker at the SourceForge project
is preferred.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FTN::Database::Nodelist


You can also look for information at:

=over 4

=item * FTN::Database issue tracker

L<http://sourceforge.net/p/ftnpl/ftn-database/tickets/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FTN-Database>

=item * Search CPAN

L<http://search.cpan.org/dist/FTN-Database>

=back

=head1 SEE ALSO

 L<FTN::Database>,  L<FTN::Database::ToDo>,
 L<http://www.ftsc.org/docs/fts-0005.003>

=head1 COPYRIGHT & LICENSE

Copyright 2010-2013 Robert James Clay, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of FTN::Database::Nodelist
