#!/usr/bin/perl
# -*- Mode: cperl; mode: folding; -*-

##############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     edittask.pl
# Description:  Add a new task to the goo database
#
# Date          Change
# -----------------------------------------------------------------------------
# 24/10/2005    Version 1
#
###############################################################################

use strict;

use lib "$ENV{GOOBASE}/shared/bin";

use CGIScript;
use GooEmailer;
use GooDatabase;

my $cgi    = CGIScript->new();
my $taskid = $cgi->{taskid};
my $title  = $cgi->{title};

print "Content-type: text/html\n\n";
print getForm(GooDatabase::getRow("task", "taskid", $taskid));


###############################################################################
#
# getForm - return the form to show the task in detail
#
###############################################################################

sub getForm {

    my ($task) = @_;

    my $requested_by_list =
        getSelectList("requestedby", $task->{requestedby}, qw(nigel megan sven rena));
    my $finished_by_list =
        getSelectList("finishedby", $task->{finishedby}, qw(nobody nigel megan sven rena));
    my $company_list    = getSelectList("company",    $task->{company},    qw(turbo10 trexy));
    my $importance_list = getSelectList("importance", $task->{importance}, 1 .. 10);
    my $status_list     = getSelectList("status",     $task->{status},     qw(pending finished));

    my $FormID;
    if ($task->{taskid}) {
        $FormID = "Form TaskID " . $task->{taskid};
    } else {
        $FormID = "Form to enter a new Task";
    }

    my $form = <<FORM;
	<html>
	<head>
	<title>Edit Task</title>
	</head>
	<body>
	<form action="./savetask.pl" method=GET>
<input type=hidden name="taskid" value="$task->{taskid}"><br>
<input type=hidden name="requestedon" value="$task->{requestedon}"><br>
<input type=hidden name="finishedon" value="$task->{finishedon}"><br>
<table border=0 cellpadding=5 cellspacing=5 align="left">
			 <tr>
			 		 <td width="100" align="left"><h4>$FormID</h4></td>
					 <td width="400" align="left"><h4>$task->{title}</h4></td>
				</tr>
				<tr>
			 		 <td width="100" align="left">Requested by</td>
					 <td width="400" align="left">$requested_by_list</td>
				</tr>
				<tr>
			 		 <td width="100" align="left">Finished by</td>
					 <td width="400" align="left">$finished_by_list</td>
				</tr>
				<tr>
			 		 <td width="100" align="left">Company</td>
					 <td width="400" align="left">$company_list</td>
				</tr>
				<tr>
                                         <td width="100" align="left">Status</td>
                                         <td width="400" align="left">$status_list</td>
                                </tr>

				<tr>
			 		 <td width="100" align="left">Task Title</td>
					 <td width="400" align="left"><input type=text size=70 name=title value="$task->{title}"></td>
				</tr>
				<tr>
			 		 <td width="100" align="left">Importance</td>
					 <td width="400" align="left">$importance_list</td>
				</tr>
				<tr>
			 		 <td width="100" align="left" valign="top">Description <br>(why/what/where/how/when?)</td>
					 <td width="400" align="left"><textarea cols=60 rows=17 name="description">$task->{description}</textarea></td>
				</tr>
				<tr>
			 		 <td width="100" align="left"><a href="tasklist.pl?company=$cgi->{company}"><< Go Back</a></td>
					 <td width="400" align="left"><input type="submit" value="Save Task">&nbsp;</td>
				</tr>
</table>

</form>
</body>
</html>
FORM

    return $form;


}


###############################################################################
#
# getSelectList - return a select list with something selected
#
###############################################################################

sub getSelectList {

    my ($name, $selected_value, @options) = @_;

    my $list = "<select name='$name'>";

    foreach my $option (@options) {

        my $selected = ($option eq $selected_value) ? "selected" : "";

        $list .= "<option value='$option' $selected>$option</option>";

    }

    return $list . "</select>";

}


###############################################################################
#
# addTaskToDatabase - return a select list with something selected
#
###############################################################################

sub addTaskToDatabase {

    my ($cgi) = @_;

    my $query = GooDatabase::prepareSQL(<<EOSQL);

    replace into task ( taskid,
			title,
                        description,
                        requestedby,
			requestedon,
			finishedon,
			status,
                        importance,
                        finishedby,
			company)
    values            (?, ?, ?, ?, now(), now(), ?, ?, ?, ?)

EOSQL

    GooDatabase::bindParam($query, 1, $cgi->{taskid});
    GooDatabase::bindParam($query, 2, $cgi->{title});
    GooDatabase::bindParam($query, 3, $cgi->{description});
    GooDatabase::bindParam($query, 4, $cgi->{requestedby});
    GooDatabase::bindParam($query, 5, $cgi->{status});
    GooDatabase::bindParam($query, 6, $cgi->{importance});
    GooDatabase::bindParam($query, 7, $cgi->{finishedby});
    GooDatabase::bindParam($query, 8, $cgi->{company});

    # what is the pain associated with this task???
    GooDatabase::execute($query);


    # default to the taskid or get last inserted taskid
    return $cgi->{taskid} || GooDatabase::getMax("taskid", "task");

}




__END__

=head1 NAME

edittask.pl - Add a new task to the goo database

=head1 SYNOPSIS

edittask.pl

=head1 DESCRIPTION



=head1 METHODS

=over

=item getForm

return the form to show the task in detail

=item getSelectList

return a select list with something selected

=item addTaskToDatabase

return a select list with something selected


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

