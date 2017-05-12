package Goo::DatabaseInfo;

###############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     GooDatabaseInfo.pm
# Description:  Find out all the database info at once!
#
# Date          Change
# -----------------------------------------------------------------------------
# 30/04/2005    Auto generated file
# 30/04/2005    Needed for speed!
#
###############################################################################

use strict;

use Goo::TableInfo;

our $tables;


###############################################################################
#
# BEGIN - look up all the tables
#
###############################################################################

sub BEGIN {

    # could use Database::getTables for the full DB -- but took a few
    # seconds to populate in the interests of speed and RAM consumption
    # decided to start off with a simple registry instead
    my @registry = qw(tasks bugs);

    foreach my $table (@registry) {

        # print "looking up $table \n";
        $tables->{$table} = TableInfo->new($table);
    }

}


###############################################################################
#
# get_table_info - return a table info object
#
###############################################################################

sub get_table_info {

    my ($table) = @_;

    return $tables->{$table};

}


1;


__END__

=head1 NAME

Goo::DatabaseInfo - Simple access to the database schema

=head1 SYNOPSIS

use Goo::DatabaseInfo;

=head1 DESCRIPTION


=head1 METHODS

=over

=item BEGIN

look up all the tables in the database

=item get_table_info

return a table info object for a given table

=back

=head1 AUTHOR

Nigel Hamilton <nigel@trexy.com>

=head1 SEE ALSO

