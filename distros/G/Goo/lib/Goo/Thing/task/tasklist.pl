#!/usr/bin/perl

##############################################################################
# Nigel Hamilton
#
# Copyright Nigel Hamilton 2005
# All Rights Reserved
#
# Author:       Nigel Hamilton
# Filename:     tasklist.pl
# Description:  Show a list of tasks
#
# Date          Change
# -----------------------------------------------------------------------------
# 24/10/2005    Version 1
#
###############################################################################

use strict;

use lib '/home/search/shared/bin';
use lib '/home/search/trexy/bin';
use CGIScript;
use GooDatabase;
use TabHeaderWidget;

my $cgi     = CGIScript->new();
my $company = $cgi->{company} || "trexy";

my $list = getList($company);

print <<HTML;
Content-type: text/html

<html>
<head>
<style type="text/css">body,td,a,p,.h{font-family:verdana, arial; font-size: 8pt;}
A:hover {color:#330066;}
.atb {font-size:9pt; color: white; font-weight:bold; backround-color: #3EAA54;}
</style> 
</head>
<body>
<center>
$list
</center>
</body>
</html>
HTML


###############################################################################
#
# getList - return the a list of each task
#
###############################################################################

sub getList {

    my ($company) = @_;

    $company = lc($company);

    my $query = GooDatabase::executeSQL(<<EOSQL);

		select 		*
		from		task
		where		company	= "$company"
		order by 	status 		desc, 
					importance 	desc, 
					requestedon desc

EOSQL

    # limit 200

    my $other_company;
    if($company eq "trexy"){
	$other_company = "turbo10";
    } else {
	$other_company = "trexy";
    }
    
    my $thw = TabHeaderWidget->new();

    if ($cgi->{company} eq "trexy") {
        $thw->addTab("Trexy Tasks", "", "#3EAA54");
    } else {
        $thw->addTab("Trexy Tasks", "window.location='./tasklist.pl?company=trexy'");
    }

    if ($cgi->{company} eq "turbo10") {
        $thw->addTab("Turbo10 Tasks", "", "#330066");
    } else {
        $thw->addTab("Turbo10 Tasks", "window.location='./tasklist.pl?company=turbo10'");
    }

    $thw->addTab("Trexy Bugs", "window.location='./buglist.pl?company=trexy'");
    $thw->addTab("Turbo10 Bugs", "window.location='./buglist.pl?company=turbo10'");

    $thw->addTab("Add New Task", "window.location='edittask.pl?company=$company'");

    my $tabs = $thw->getContents();

    my $list = <<TABLE;
        $tabs
    <table>
    <tr>
         <td height=30 width=70 align="center" style="font-style:normal; font-size:small; font-weight=bold;">Importance</td>
         <td height=30 width=70 align="center" style="font-style:normal; font-size:small; font-weight=bold;">Status</td>
         <td height=30 width=350 align="center" style="font-style:normal; font-size:small; font-weight=bold;">Task</td>
         <td height=30 width=90 align="center"  style="font-style:normal; font-size:small; font-weight=bold;">Requested by</td>
         <td height=30 width=90 align="center"  style="font-style:normal; font-size:small; font-weight=bold;">Date Requested</td>
         <td height=30 width=90 align="center"  style="font-style:normal; font-size:small; font-weight=bold;">Finished by</td>
         <td height=30 width=90 align="center"  style="font-style:normal; font-size:small; font-weight=bold;">Date Finished</td>
         <td height=30 width=60 align="right" style="font-style:normal; font-size:small; font-weight=bold;">TaskID</td>
    </tr>
TABLE

    	while (my $row = GooDatabase::getResultHash($query)) {
        my $date_requested = conv_date($row->{requestedon});
	my $date_finished = conv_date($row->{finishedon});
	my $style = style($row->{status});
	my $link = style_link($row->{status});
        $list .= <<ROW;

	<tr>
		<td align="center" $style>$row->{importance}</td>
		<td align="center" $style>$row->{status}</td>
		<td align="left" $style><a href="./edittask.pl?company=$company&taskid=$row->{taskid}" $link>$row->{title}</a></td>
		<td align="center" $style>$row->{requestedby}</td>
		<td align="center" $style>$date_requested</td>
		<td align="center" $style>$row->{finishedby}</td>
		<td align="center" $style>$date_finished</td>
		<td align="right" $style>$row->{taskid}</td>
	</tr>
ROW

    }

    return $list .= "</table>";
}

sub conv_date {
    my $date = shift;
    $date =~ s/(\d\d\d\d)-(\d\d)-(\d\d) (\d\d:\d\d:\d\d)/$3-$2-$1/;
    return $date;
}

sub style {
    my $state = shift;
    my $color;
    if ($state eq "finished"){
	$color = 'style="font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
			 font-size: 10pt;
			 font-style: normal;
			 font-variant: normal;
			 font-weight: normal;
			 color: #AFAFAF;"';
    } else {
	$color = 'style="font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
                         font-size: 10pt;
                         font-style: normal;
                         font-variant: normal;
                         font-weight: normal;
                         color: #000000;"';
    }
    return $color;
}

sub style_link {
    my $state = shift;
    my $color;
    if ($state eq "finished"){
        $color = 'style="font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
                         font-size: 10pt;
                         font-style: normal;
                         font-variant: normal;
                         font-weight: normal;
                         color: #AAABFF;"';
    } else {
        $color = 'style="font-family: Verdana, Geneva, Arial, Helvetica, sans-serif;
                         font-size: 10pt;
                         font-style: normal;
                         font-variant: normal;
                         font-weight: normal;
                         color: #0002FB;"';
    }
    return $color;
}




__END__

=head1 NAME

tasklist.pl - Show a list of tasks

=head1 SYNOPSIS

tasklist.pl

=head1 DESCRIPTION



=head1 METHODS

=over

=item getList

return the a list of each task


=back

=head1 AUTHOR

Nigel Hamilton <nigel@turbo10.com>

=head1 SEE ALSO

