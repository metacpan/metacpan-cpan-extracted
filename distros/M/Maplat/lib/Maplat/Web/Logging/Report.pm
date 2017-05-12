# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::Logging::Report;
use strict;
use warnings;
use 5.010;

use base qw(Maplat::Web::BaseModule);

use Maplat::Helpers::DateStrings;
use Maplat::Helpers::Padding qw(doFPad);
use Maplat::Helpers::DBSerialize;
use Maplat::Helpers::Logging::Graphs;
use PDF::Report;
use Carp;

our $VERSION = 0.995;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    return $self;
}

sub reload {
    my ($self) = shift;
    
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    $self->register_webpath($self->{reportedit}->{webpath}, "get_edit");
    $self->register_webpath($self->{reportselect}->{webpath}, "get_select");
    $self->register_webpath($self->{reportview}->{webpath}, "get_view");
    $self->register_webpath($self->{reportgraph}->{webpath}, "get_graph");
    $self->register_webpath($self->{reportpdf}->{webpath}, "get_pdf");
    $self->register_loginitem("on_login");
    return;
}

sub on_login {
    my ($self, $username, $sessionid) = @_;
    
    my $sesh = $self->{server}->{modules}->{$self->{session}};
    
    # Select Reportreader as default
    $sesh->set("SelectedReport", "ReportReader");
    return;
}

sub get_view {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $sesh = $self->{server}->{modules}->{$self->{session}};
    
    # Cached id
    my $reportid = $sesh->get("SelectedReport") || "";
    $reportid = dbderef($reportid);
    
    if($reportid eq "ReportReader") {
        $reportid = "";
    }
    
    # New id from form
    my $newreportid = $cgi->param('reportid') || "";
    if($newreportid ne "") {
        $reportid = $newreportid;
    }
    
    my %webdata = 
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{reportview}->{pagetitle},
        webpath        =>  $self->{reportview}->{webpath},
        graphpath    =>  $self->{reportgraph}->{webpath},
    );
    
    # Load available reports and check id
    my @availreports;
    my $devicetype;
    my $lsth = $dbh->prepare_cached("SELECT * FROM logging_reports
                                    ORDER BY device_type, report_name")
            or croak($dbh->errstr);
    $lsth->execute or croak($dbh->errstr);
    my $repidok = 0;
    while((my $report = $lsth->fetchrow_hashref)) {
        $report->{reportid} = $report->{report_name} . '_#_' . $report->{device_type};
        push @availreports, $report;
        if($reportid ne "" && $reportid eq $report->{reportid}) {
            $repidok = 1;
            $devicetype = $report->{device_type};
        }
    }
    $lsth->finish;
    $webdata{AvailReports} = \@availreports;
    if(!$repidok) {
        $reportid = "";
    }
    $webdata{ReportID} = $reportid;
    $sesh->set("SelectedReport", $reportid);
    
    # Get and Store timeframe
    my @timeframes = qw[hour day week month year];
    $webdata{Timeframes} = \@timeframes;
    my $timeframe = $sesh->get("SelectedTimeframe") || "";
    $timeframe = dbderef($timeframe);
    
    my $newtimeframe = $cgi->param('timeframe') || "";
    if($newtimeframe ne "") {
        $timeframe = $newtimeframe;
    }
    if(!($timeframe ~~ @timeframes)) {
        $timeframe = $timeframes[0];
    }
    $sesh->set("SelectedTimeframe", $timeframe);
    $webdata{SelectedTimeframe} = $timeframe;
        
    if($reportid ne "") {
        # Cached device
        my $device = $sesh->get("SelectedDevice") || "";
        $device = dbderef($device);
        my $newdevice = $cgi->param('device') || "";
        if($newdevice ne "") {
            $device = $newdevice;
        }
        
        # Available devices
        my @availdevices;
        my $devok = 0;
        my $dsth = $dbh->prepare_cached("SELECT * FROM logging_devices
                                        WHERE device_type = ?
                                        ORDER BY hostname")
                or croak($dbh->errstr);
        $dsth->execute($devicetype) or croak($dbh->errstr);
        while((my $dev = $dsth->fetchrow_hashref)) {
            push @availdevices, $dev;
            if($device ne "" && $device eq $dev->{hostname}) {
                $devok = 1;
            }
        }
        $dsth->finish;
        $webdata{Devices} = \@availdevices;
        if(!$devok) {
            $device = $availdevices[0]->{hostname};
        }
        $webdata{SelectedDevice} = $device;
        $sesh->set("SelectedDevice", $device);
    }
    
    if($reportid ne "") {
        my ($repname, $devtype) = split/\_\#\_/, $reportid;
        my $gsth = $dbh->prepare_cached("SELECT i.report_name, i.device_type, i.graph_name, i.sorting, i.graph_name, g.title
                                    FROM logging_reportitems i, logging_reportgraphs g
                                    WHERE g.graph_name = i.graph_name
                                    AND g.device_type = i.device_type
                                    AND i.report_name = ? AND i.device_type = ?
                                    ORDER BY i.sorting")
                or croak($dbh->errstr);
        if($gsth->execute($repname, $devtype)) {
            my @items;
            while((my $item = $gsth->fetchrow_hashref)) {
                $item->{rndsuffix} = int(rand(100000) + 1) . "." . int(rand(100000) + 1);
                push @items, $item;
            }
            $webdata{Graphs} = \@items;
        } else {
            $reportid = "";
        }
    }
    $dbh->rollback;
    
    my $template = $self->{server}->{modules}->{templates}->get("logging/reportview", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_edit {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $sesh = $self->{server}->{modules}->{$self->{session}};
    
    my $selectedreport = $sesh->get("SelectedReport");
    $selectedreport = dbderef($selectedreport);
    my $reportid = $selectedreport || "";
    
    # Workaround
    if($reportid eq "ReportReader") {
        $reportid = $selectedreport = "";
        $sesh->set("SelectedReport", $selectedreport);
    }
    
    my $mode = $cgi->param('mode') || 'view';
    
    # Special mode handling: Select report (POST from select view)
    if($mode eq "selectreport") {
        $selectedreport = $cgi->param('reportid');
        $mode = "view"; # disable other POST handlings
        $selectedreport = $cgi->param('reportid');
        $reportid = $selectedreport;
        $sesh->set("SelectedReport", $selectedreport);
    }
    
    my %webdata = 
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{reportedit}->{pagetitle},
        webpath        =>  $self->{reportedit}->{webpath},
        ReportSelect    =>    $self->{reportselect}->{webpath},
        SelectedReport=>    $selectedreport,
        ReportID        =>    $reportid,
        EditMode    =>    "editreport",
    );
    
    # Handle standard POST requests
    if($mode eq "deletereport") {
        $reportid = $cgi->param('reportid');
        my ($repname, $devtype) = split/\_\#\_/, $reportid;
        $webdata{ReportID} = $reportid;
        my $sth = $dbh->prepare_cached("DELETE FROM logging_reports
                                       WHERE report_name = ? AND device_type = ?")
                or croak($dbh->errstr);
        if($sth->execute($repname, $devtype)) {
            $sth->finish;
            $dbh->commit;
            $webdata{statustext} = "Report deleted";
            $webdata{statuscolor} = "oktext";
            
            # We don't have a report selected now
            $reportid = $selectedreport = "";
            $sesh->set("SelectedReport", $selectedreport);
        } else {
            $dbh->rollback;
            $webdata{statustext} = "Deletion failed";
            $webdata{statuscolor} = "errortext";
        }
    } elsif($mode eq "createreport") {
        my $reportname = $cgi->param('report_name') || 'unnamed report';
        my $reportdevice = $cgi->param('device_type') || 'PAC3200';
        my $reporttitle = $cgi->param('report_title') || 'untitled report';
        my $reportdescription = $cgi->param('report_description') || '';
        my $sth = $dbh->prepare_cached("INSERT INTO logging_reports
                                       (report_name, device_type, report_title, description)
                                       VALUES (?, ?, ?, ?)")
                or croak($dbh->errstr);
        if($sth->execute($reportname, $reportdevice, $reporttitle, $reportdescription)) {
            $sth->finish;
            $dbh->commit;
            $webdata{statustext} = "Report created";
            $webdata{statuscolor} = "oktext";
            $reportid  = $reportname . "_#_" . $reportdevice;
            $webdata{ReportID} = $reportid;
            $sesh->set("SelectedReport", $reportid);
        } else {
            $reportid  = "";
            $webdata{ReportID} = $reportid;
            $sesh->set("SelectedReport", $selectedreport);
            
            $dbh->rollback;
            $webdata{statustext} = "Creation failed";
            $webdata{statuscolor} = "errortext";
        }
    } elsif($mode eq "editreport") {
        $reportid = $cgi->param('reportid');
        my ($repname, $devtype) = split/\_\#\_/, $reportid;
        $webdata{ReportID} = $reportid;
        
        my $reportname = $cgi->param('report_name') || 'unnamed report';
        my $reportdevice = $cgi->param('device_type') || 'PAC3200';
        my $reporttitle = $cgi->param('report_title') || 'untitled report';
        my $reportdescription = $cgi->param('description') || '';
        my $itemstring = $cgi->param('graph_order') || '';
        my @items = split/\;/, $itemstring;
        
        my $error = 0;
        
        $webdata{ReportID} = $reportid;
        my $psth = $dbh->prepare_cached("UPDATE logging_reports
                                       SET report_name = ?,
                                       device_type = ?,
                                       report_title = ?,
                                       description = ?
                                       WHERE report_name = ?
                                       AND device_type = ?")
                or croak($dbh->errstr);
        if(!$psth->execute($reportname, $reportdevice, $reporttitle, $reportdescription, $repname, $devtype)) {
            $error = 1;
        }
        $psth->finish;
            
        if(!$error) {
            my $dsth = $dbh->prepare_cached("DELETE FROM logging_reportitems
                                            WHERE report_name = ?
                                            AND device_type = ?")
                    or croak($dbh->errstr);
            if(!$dsth->execute($reportname, $reportdevice)) {
                $error = 1;
            }
            $dsth->finish;
        }
        
        if(!$error) {
            my $isth = $dbh->prepare("INSERT INTO logging_reportitems
                                     (report_name, device_type, graph_name, sorting)
                                     VALUES (?,?,?,?)")
                    or croak($dbh->errstr);
            my $order = 0;
            
            foreach my $item (@items) {
                next if($item =~ /^__pc_/);
                if(!$isth->execute($reportname, $reportdevice, $item, $order)) {
                    $error = 1;
                    last;
                }
                $order++;
            }            
        }
            
        if(!$error) {
            $dbh->commit;
            $webdata{statustext} = "Report updated";
            $webdata{statuscolor} = "oktext";
            $reportid  = $reportname . "_#_" . $reportdevice;
            $webdata{ReportID} = $reportid;
            $sesh->set("SelectedReport", $reportid);
        } else {
            $dbh->rollback;
            $webdata{statustext} = "Update failed";
            $webdata{statuscolor} = "errortext";
        }
    }
    
    # Update this values again, they may have changed with POST requests
    $webdata{ReportID} = $reportid;
    $webdata{SelectedReport} = $selectedreport;
        
    my @activeitems;
    my @availitems;
    my $found = 0;
    if($reportid ne "") {
        my ($repname, $repdev) = split/\_\#\_/, $reportid;
        my $sth = $dbh->prepare_cached("SELECT *
                                       FROM logging_reports
                                       WHERE report_name = ?
                                       AND device_type = ?")
                    or croak($dbh->errstr);
        
        if($sth->execute($repname, $repdev)) {
            while((my $line = $sth->fetchrow_hashref)) {
                $found = 1;
                $webdata{report_name} = $line->{report_name};
                $webdata{device_type} = $line->{device_type};
                $webdata{report_title} = $line->{report_title};
                $webdata{description} = $line->{description};
                last;
            }
            $sth->finish;
        }
        if(!$found) {
            $reportid = "";
        }
    }
        
    if($reportid ne "") {
        my ($repname, $repdev) = split/\_\#\_/, $reportid;
        my @actgraphs;
        my $sth = $dbh->prepare_cached("SELECT i.report_name, i.device_type, i.graph_name, i.sorting, i.graph_name, g.title
                                    FROM logging_reportitems i, logging_reportgraphs g
                                    WHERE g.graph_name = i.graph_name
                                    AND g.device_type = i.device_type
                                    AND i.report_name = ? AND i.device_type = ?
                                    ORDER BY i.sorting")
                or croak($dbh->errstr);
        if($sth->execute($repname, $repdev)) {
            while((my $line = $sth->fetchrow_hashref)) {
                push @activeitems, $line;
                push @actgraphs, $line->{graph_name};
            }
        }
        $sth->finish;
        $webdata{ActiveItems} = \@activeitems;
        
        $sth = $dbh->prepare_cached("SELECT * FROM logging_reportgraphs
                                    WHERE device_type = ?
                                    ORDER BY graph_name")
                or croak($dbh->errstr);
        if($sth->execute($repdev)) {
            while((my $line = $sth->fetchrow_hashref)) {
                next if(($line->{graph_name} ~~ @actgraphs));
                push @availitems, $line;
            }
        }
        $sth->finish;
        $webdata{AvailItems} = \@availitems;
    }
    
    
    $dbh->rollback;
    
    $webdata{ReportID} = $reportid;
    #my $webreportid = $reportid;
    #$webreportid =~ s/\ /./go;
    #$webdata{ReportPDF} = $self->{reportpdf}->{webpath}. "/CCID" . $webreportid  . "/" . int(rand(100000) + 1) . "." . int(rand(100000) + 1);
    
    my $template = $self->{server}->{modules}->{templates}->get("logging/reportedit", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}


# "get_select" actually only displays the available report list, POST
# is done to the main mask to have a smoother workflow without redirects
sub get_select {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $sesh = $self->{server}->{modules}->{$self->{session}};
    
    my $sth = $dbh->prepare_cached("SELECT *
                                   FROM logging_reports
                                   ORDER BY device_type, report_name")
                or croak($dbh->errstr);
    my @reports;
    
    if($sth->execute) {
        while((my $line = $sth->fetchrow_hashref)) {
            push @reports, $line;
        }
    }
    $sth->finish;
    $dbh->rollback;
    
    my %webdata = 
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{reportedit}->{pagetitle},
        webpath        =>  $self->{reportedit}->{webpath},
        Reports        =>  \@reports,
    );
    
    my $template = $self->{server}->{modules}->{templates}->get("logging/reportselect", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
    
}

sub get_graph {
    my ($self, $cgi) = @_;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $sesh = $self->{server}->{modules}->{$self->{session}};
    
    # Cached id
    my $timeframe = $sesh->get("SelectedTimeframe") || "";
    $timeframe = dbderef($timeframe);

    my $device = $sesh->get("SelectedDevice") || "";
    $device = dbderef($device);

    my $reportid = $sesh->get("SelectedReport") || "";
    $reportid = dbderef($reportid);

    my ($reportname, $devicetype) = split/\_\#\_/, $reportid;
    
    my $graphname = $cgi->path_info();
    my $remove = '^' . $self->{reportgraph}->{webpath} . "/";
    
    # Workaround - FIXME!!!!
    $graphname =~ s/$remove//g;
    $graphname =~ s/\/.*//g;
    
    if($timeframe eq "" || $device eq "" || $graphname eq "") {
        return (status  =>  404);
    }
    
    my $img = Maplat::Helpers::Logging::Graphs::simpleGraph(
        $dbh, $devicetype, $graphname, $device, $timeframe
    );
    $dbh->rollback;
    
    if(!defined($img)) {
        return (status  =>  404);
    } else {
        return (status          =>  200,
                type            => "image/png",
                data            => $img,
                expires         => "+60s",
                cache_control   =>  "max-age=120, must-revalidate",
                );
    }
}

1;
__END__

=head1 NAME

Maplat::Web::Logging::Report - view and edit reports based on configured graphs and devices

=head1 SYNOPSIS

  use Maplat::Web;
  use Maplat::Web::Logging;
  
Then configure() the module as you would normally.

=head1 DESCRIPTION

    <module>
        <modname>loggingreport</modname>
        <pm>Logging::Report</pm>
        <options>
            <reportselect>
                <webpath>/logging/reportselect</webpath>
                <pagetitle>Report select</pagetitle>
            </reportselect>
            <reportedit>
                <webpath>/logging/reportedit</webpath>
                <pagetitle>Report Edit</pagetitle>
            </reportedit>
            <reportview>
                <webpath>/logging/reportview</webpath>
                <pagetitle>Report View</pagetitle>
            </reportview>
            <reportgraph>
                <webpath>/logging/reportgraph</webpath>
                <pagetitle>Report Graph</pagetitle>
            </reportgraph>
            <db>maindb</db>
            <session>sessionsettings</session>
        </options>
    </module>

This module provides the webmasks required to edit and configure reports. Configuring is done
by drag and dropping of configures Graphs.

=head2 get_edit

Internal function, edit mask for reports.

=head2 get_graph

Internal function, renders a single graph.

=head2 get_select

Internal function, renders the "select a report" webmask.

=head2 get_view

Internal function, renders a report in view mode.

=head2 on_login

Internal function, load some user settings on login.

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

