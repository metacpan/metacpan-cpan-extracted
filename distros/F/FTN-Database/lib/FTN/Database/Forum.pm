package FTN::Database::Forum;

use warnings;
use strict;
use Carp qw( croak );

=head1 NAME

FTN::Database::Forum - Fidonet/FTN Message Forum SQL Database operations.

=head1 VERSION

Version 0.42

=cut

our $VERSION = '0.42';

=head1 DESCRIPTION

FTN::Database::Forum is a Perl module containing common forum (message conference)
related functions for Fidonet/FTN Forum related processing on a Forum table in an
SQL Database, including one that defines the fields for such a Forum table. The SQL
database engine is one for which a DBD module exists, defaulting to SQLite.

=head1 EXPORT

The following functions are available in this module: define_forum_table(),
define_areasbbs_table(), ftnmsg_index_fields(), and ftnareas_index_fields().

=head1 FUNCTIONS

=head2 define_forum_table

Syntax:  $fields = define_forum_table();

This function returns a string that contains the SQL which defines a
message conference/forum table for use in an SQL database being used
for Fidonet/FTN processing,

Except for the I<id> field, which is defined in the create_ftn_table
subroutine itself, the defined fields are as follows:

=cut

sub define_forum_table {

    my $table_fields = '';

=over 4

=item ftscdate

The I<ftscdate> field is used to contain a string indicating the date of the 
FTN message. It can contain up to 20 characters and defaults to an empty string.

=cut

    $table_fields = "ftscdate     VARCHAR(20) DEFAULT '' NOT NULL, ";

=item datetime

The I<datetime> field is used to contain date and time that the FTN message was
added to the forum table.

=cut

    $table_fields .= "datetime     TIMESTAMP(14) DEFAULT '' NOT NULL, ";

=item fromnode

The I<fromnode> field is used to contain the FTN node number that the message is
from. It can contain up to 72 characters and defaults to an empty string.

=cut

    $table_fields .= "fromnode      CHAR(72) DEFAULT '' NOT NULL, ";

=item tonode

The I<tonode> field is used to contain the FTN node number that the message is
to. It can contain up to 72 characters and defaults to an empty string.

=cut

    $table_fields .= "tonode      CHAR(72) DEFAULT '' NOT NULL, ";

=item fromname

The I<fromame> field is used to contain the name of whom the FTN message is from.
It can contain up to 36 characters and defaults to an empty string.

=cut

    $table_fields .= "fromname     VARCHAR(36) DEFAULT ' ' NOT NULL, ";

=item toname

The I<toname> field is used to contain the name of whom the FTN message is to.
It can contain up to 36 characters and defaults to an empty string.

=cut

    $table_fields .= "toname     VARCHAR(36) DEFAULT ' ' NOT NULL, ";

=item subject

The I<subject> field is used to contain the subject for the FTN message. It can
contain up to 72 characters and defaults to an empty string.

=cut

    $table_fields .= "subject    VARCHAR(72) DEFAULT '' NOT NULL, ";

=item attrib

The I<attrib> field is used to contain the set of attribues from the FTN
message. Defaults to none of them being set. Defaults to being defined
as an integer.

=cut

    # The Attributes information comes from a two byte, 16 bit integer.
    # In a mysql database it could be defined as follows:
    # $table_fields .= "attrib   SET('Private', 'Crash', 'Recd', 'Sent',";
    # $table_fields .= "'FileAttached', 'InTransit', 'Orphan', 'KillSent', ";
    # $table_fields .= "'Local', 'HoldForPickup', 'unused', 'FileRequest', ";
    # $table_fields .= "'ReturnREceiptRequest', 'IsReturnReceiptRequest', ";
    # $table_fields .= "'AuditRequest', 'FileUpdateReq') DEFAULT '' NOT NULL, ";

    # Others apparently do notso for now, default to defining it as an integer
    $table_fields .= "attrib   Integer  DEFAULT '' NOT NULL, ";

=item msgid

The I<msgid> field is used to contain the FTN message ID. Defaults to an empty
string.

=cut

    $table_fields .= "msgid   VARCHAR(72)  DEFAULT '' NOT NULL, ";

=item replyid

The I<replyid> field is used to contain the FTN message reply ID.  Defaults to
an empty string.

=cut

    $table_fields .= "replyid   VARCHAR(72)  DEFAULT '' NOT NULL, ";

=item body

The required I<body> field is used to contain the body of the FTN messages and
defaults to an empty string.

=cut

    $table_fields .= "body    MEDIUMBLOG DEFAULT '' NOT NULL, ";

=item ctrlinfo

The I<ctrlinfo> field is used to contain the FTN control information for the
message being stored in the table.  Defaults to an empty string.

=back

=cut

    $table_fields .= "ctrlinfo   BLOB DEFAULT ''";

    return($table_fields);

}


=head2 define_areasbbs_table

Syntax:  $fields = define_areasbbs_table();

This function returns a string that contains the SQL which defines an
areasbbs table for use in an SQL database being used for Fidonet/FTN
to track message/forum or file echo processing.

Except for the I<id> field, which is defined in the create_ftn_table
subroutine itself, the defined fields are as follows:

=cut

sub define_areasbbs_table {

    my $table_fields = '';

=over 4

=item areaname

The I<areaname> field is used to contain a string indicating the distribution
name of the FTN message or file area. It can contain up to 32 characters and
defaults to an empty string.

=cut

    $table_fields = "areaname     VARCHAR(32) DEFAULT '' NOT NULL, ";

=item bbsname

The I<bbsname> field is used to contain a string indicating the name of the FTN
message or file area as it is referenced in the database. It can contain up to
32 characters and defaults to an empty string.

=cut

    $table_fields .= "bbsname     VARCHAR(32) DEFAULT '' NOT NULL, ";

=item description

The I<description> field is used to contain the description of the message or
file area. It can contain up to 32 characters and defaults to an empty string.

=cut

    $table_fields .= "description     VARCHAR(32) DEFAULT '' NOT NULL, ";

=item prinode

The I<prinode> field is used to contain the primary FTN node number for the
system that the area is on. It can contain up to 72 characters and defaults
to an empty string.

=cut

    $table_fields .= "prinode      CHAR(72) DEFAULT '' NOT NULL, ";

=item uplink

The I<uplink> field is used to contain the FTN node number that the system
obtains the area from. It can contain up to 72 characters and defaults to
an empty string.

=cut

    $table_fields .= "uplink      CHAR(72) DEFAULT '' NOT NULL, ";

=item domain

The I<domain> field is used to contain the name of FTN domain in which
the area is distributed. It can contain up to 8 characters and defaults
to an empty string.

=cut

    $table_fields .= "domain     VARCHAR(8) DEFAULT ' ' NOT NULL, ";

=item maxmsgs

The I<maxmsgss> field is used to indicate the maximum number of messages that
should be kept in this message/forum area. Defaults to the number zero.

=cut

    $table_fields .= "maxmsgs    MEDIUMINT DEFAULT '0' NOT NULL, ";

=item maxdays

The I<maxdays> field is used to indicate the maximum number of days that messages
should be kept for in this message/forum area. Defaults to the number zero.

=cut

    $table_fields .= "maxdays    MEDIUMINT DEFAULT '0' NOT NULL, ";

=item type

The I<type> field is used to indicate what type of FTN message/forum area this
is. Can be an I<L>, for local; an I<N>, for netmail, or an I<L>, for local.
Defaults to an I<L>. (Message/Forum areas only.)

=back

=cut

    $table_fields .= "type   CHAR(1) DEFAULT 'L'";

    return($table_fields);

}

=head2 ftnmsg_index_fields

Syntax:  $fields = ftnmsg_index_fields();

This is a function that returns a string containing a comma separated list of
the fields that are intended for use in creating the ftnmsg database index.
The index contains the following fields: msgid and replyid.

=cut

sub ftnmsg_index_fields {

    my $field_list = 'msgid,replyid';

    return($field_list);

}

=head2 ftnareas_index_fields

Syntax:  $fields = ftnareas_index_fields();

This is a function that returns a string containing a comma separated list of
the fields that are intended for use in creating the ftnareas database index.
The index contains the following fields: areaname and bbsname.

=cut

sub ftnareas_index_fields {

    my $field_list = 'areaname,bbsname';

    return($field_list);

}

=head1 EXAMPLES

An example of opening an FTN database, then creating a forum table,
loading data to it, then creating an index on it, and then closing
the database connection:

    use FTN::Database;
    use FTN::Database::Forum;

    my $db_handle = open_ftn_database(\%db_option);
    $fields = define_forum_table();
    create_ftn_table($db_handle, $table_name, $fields);
    ...   (Load data to forum table)
    ftnmsg_index_tables($db_handle, $table_name);
    close_ftn_database($db_handle);


=head1 AUTHOR

Robert James Clay, C<< <jame at rocasa.us> >>


=head1 BUGS

Please report any bugs or feature requests via the web interface at
L<http://sourceforge.net/p/ftnpl/ftn-database/tickets/>. I will be
notified, and then you'll automatically be notified of progress on
your bug as I make changes.

Note that you can also report any bugs or feature requests to
C<bug-ftn-database at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=FTN-Database>;
however, the FTN-Database Issue tracker at the SourceForge project
is preferred.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc FTN::Database::Forum


You can also look for information at:

=over 4

=item * FTN::Database issue tracker

L<http://sourceforge.net/p/ftnpl/ftn-database/tickets/>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=FTN-Database>

=item * Search CPAN

L<http://search.cpan.org/dist/FTN-Database>

=back

=head1 CREDITS

The message/forum and areasbbs table definitions were originally derived from
the bbsdbpl scripts areatable.pl and areasbbsadm.pl available at the FTN Perl
project at SourceForge: L<http://ftnpl.sourceforge.net>


=head1 SEE ALSO

 L<FTN::Database>, L<FTN::Database::ToDo>

=head1 COPYRIGHT & LICENSE

Copyright 2001-2004,2013 Robert James Clay, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of FTN::Database::Forum
