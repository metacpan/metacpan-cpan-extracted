#!/usr/bin/perl

##############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     savetask.pl
# Description:  Add a new task to the goo database
#
# Date          Change
# -----------------------------------------------------------------------------
# 24/10/2005    Version 1
#
###############################################################################

use strict;

use lib '/home/search/shared/bin';
use CGIScript;
use GooEmailer;
use GooDatabase;
use StaffManager;
use CGI::Carp('fatalsToBrowser');

my $cgi = CGIScript->new();

# add a new task to the database
addTaskToDatabase($cgi);

# send the email alert!!!
# $taskid = addTaskToDatabase($cgi);
if ($cgi->{importance} > 9) {

    # keep us update about important tasks
    GooEmailer::sendEmail("goo\@turbo10.com",
                          "nigel\@turbo10.com, sven\@turbo10.com",
                          "Important Task: $cgi->{title} [$cgi->{taskid}]",
                          $cgi->{description});

}


# do a redirect back to the list
print "Location: ./tasklist.pl?company=$cgi->{company}\n\n";


###############################################################################
#
# addTaskToDatabase - return a select list with something selected
#
###############################################################################


sub addTaskToDatabase {

    my ($cgi) = @_;

    my $query = GooDatabase::prepareSQL(<<EOSQL);

    replace into task ( 			taskid,
						title,
                        			description,
						requestedby,
						status,
						
						importance,
                        			finishedby,
						company,
						requestedon,
						finishedon)
    			values            (?, ?, ?, ?, ?,  
						?, ?, ?, ?, ?)

EOSQL

    GooDatabase::bindParam($query, 1, $cgi->{taskid});
    GooDatabase::bindParam($query, 2, $cgi->{title});
    GooDatabase::bindParam($query, 3, $cgi->{description});
    GooDatabase::bindParam($query, 4, $cgi->{requestedby});
    GooDatabase::bindParam($query, 5, $cgi->{status});

    GooDatabase::bindParam($query, 6, $cgi->{importance});
    GooDatabase::bindParam($query, 7, $cgi->{finishedby});
    GooDatabase::bindParam($query, 8, $cgi->{company});
    GooDatabase::bindParam($query, 9, $cgi->{requestedon} || GooDatabase::getDate());

    # has somebody come along and finished it?
    my $finishedon = "";

    if (($cgi->{status} eq "finished") && ($cgi->{finishedby} ne "nobody")) {
        StaffManager::sendEmail("Tara the Task Master <tara\@turbo10.com>",
                                "$cgi->{finishedby} finished: $cgi->{title} [$cgi->{taskid}]",
                                $cgi->{description});
        $finishedon = GooDatabase::getDate();
    }

    GooDatabase::bindParam($query, 10, $finishedon);

    # what is the pain associated with this task???
    GooDatabase::execute($query);
}


__END__

=head1 NAME

savetask.pl - Add a new task to the goo database

=head1 SYNOPSIS

savetask.pl

=head1 DESCRIPTION



=head1 METHODS

=over

=item addTaskToDatabase

return a select list with something selected


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

