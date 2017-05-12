# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::CommandQueue;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::CommandHelper;

our $VERSION = 0.995;


use Carp;

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
    $self->register_webpath($self->{admin}->{webpath}, "get_admin");
    $self->register_webpath($self->{user}->{webpath}, "get_user");
    return;
}

sub get_admin {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $th = $self->{server}->{modules}->{templates};

    my %webdata = 
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{admin}->{pagetitle},
        LinkTitle        =>  $self->{linktitle},
        webpath            =>  $self->{admin}->{webpath},
    );
    
    my %allcommands = (
        VACUUM_ANALYZE        => 'simple',
        VACUUM_FULL            => 'simple',
        ANALYZE_TABLE        => 'table',
        VACUUM_ANALYZE_TABLE=> 'table',
        REINDEX_ALL_TABLES    => 'simple',
        REINDEX_TABLE        => 'table',
        BACKUP                => 'simple',
        CALCULATE_STATS        => 'simple',
        NOP_OK                => 'simple',
        NOP_FAIL            => 'simple',
        UPDATE_SIGNALS_TRIGGER        => 'simple',
        ACTIVATE_PRODLINE    => 'prodline',
        DEACTIVATE_PRODLINE    => 'prodline',
        ACTIVATE_ALL_LINES    => 'alllines',
        DEACTIVATE_ALL_LINES=> 'alllines',
        ADMIN_REPORT        => 'report',
        VNC_REPORT          => 'report',
        BACKUP              => 'simple',
    );
    my @commandorder = ('ADMIN_REPORT', 'VNC_REPORT',
                        'ANALYZE_TABLE', 'VACUUM_ANALYZE_TABLE', 'VACUUM_ANALYZE', 'VACUUM_FULL',
                        'REINDEX_TABLE', 'REINDEX_ALL_TABLES',
                        'BACKUP',
                        'ACTIVATE_PRODLINE', 'DEACTIVATE_PRODLINE',
                        'ACTIVATE_ALL_LINES', 'DEACTIVATE_ALL_LINES',
                        #'BACKUP', 'CALCULATE_STATS',
                        'UPDATE_SIGNALS_TRIGGER',
                        'NOP_OK', 'NOP_FAIL',
                        );
    
    my @reportusers = ($webdata{userData}->{email_addr}, '*');
    $webdata{Recievers} = \@reportusers;
    
    # Read some extra data
    my $prodlinesth = $dbh->prepare_cached("SELECT * " .
                                           "FROM prodlines " .
                                           "ORDER BY line_id")
                    or croak($dbh->errstr);
    my @prodlines;
    #my @prodline_ids;
    $prodlinesth->execute or croak($dbh->errstr);
    while((my $pline = $prodlinesth->fetchrow_hashref)) {
        push @prodlines, $pline;
        #push @prodline_ids, $pline
    }
    $prodlinesth->finish;
    $webdata{Prodlines} = \@prodlines;
    
    my $rbstablessth = $dbh->prepare_cached("SELECT * " .
                                            "FROM pg_tables " .
                                            "WHERE tableowner = 'RBS_Server' " .
                                            "ORDER BY tablename")
                    or croak($dbh->errstr);
    my @rbstables;
    $rbstablessth->execute or croak($dbh->errstr);
    while((my $tabline = $rbstablessth->fetchrow_hashref)) {
        push @rbstables, $tabline;
    }
    $rbstablessth->finish;
    $webdata{Tables} = \@rbstables;
    
    
    my $submitform = $cgi->param('submitform') || '';
    if($submitform eq "1") {
        my $command = $cgi->param('command') || '';
        if($command ne "") {            
            my $mode = $cgi->param('mode') || 'view';
            
            if($mode eq "schedulecommand") {
                my $isodate = $cgi->param('starttime') || '';
                if($isodate eq "") {
                    $isodate = getISODate();
                } else {
                    # try to parse date as a "natural" date, e.g. like "tommorow morning" or "next sunday afternoon"
                    $isodate = parseNaturalDate($isodate);
                }
                my $sth = $dbh->prepare_cached("INSERT INTO commandqueue " .
                                         "(command, starttime, arguments) " .
                                         "VALUES (?, ?, ?)")
                                or croak($dbh->errstr);

                my @arglist = ();
                
                if($allcommands{$command} ne "alllines") {
                    if($allcommands{$command} eq "prodline") {
                        push @arglist, ($cgi->param('prodline') || '');
                    } elsif($allcommands{$command} eq "table") {
                        push @arglist, ($cgi->param('tablename') || '');
                    } elsif($allcommands{$command} eq "report") {
                        my $reciever = $cgi->param('reciever') || '';
                        if($reciever eq '*') {
                            $reciever = '';
                        }
                        push @arglist, ($reciever);
                    }

                    if(!$sth->execute($command, $isodate, \@arglist)) {
                        my $errstr = $dbh->errstr;
                        $sth->finish;
                        $dbh->rollback;
                        $webdata{statustext} = "$errstr";
                        $webdata{statuscolor} = "errortext";
                    } else {
                        $sth->finish;
                        $dbh->commit;
                        $webdata{statustext} = "Command $command scheduled at $isodate";
                        $webdata{statuscolor} = "oktext";
                    }
                } else {
                    my $ok = 1;
                    
                    my $statusstr;
                    my $xcommand;
                    if($command eq "DEACTIVATE_ALL_LINES") {
                        $xcommand = "DEACTIVATE_PRODLINE";
                    } else {
                        $xcommand = "ACTIVATE_PRODLINE";
                    }
                    foreach my $prodline (@prodlines) {
                        @arglist = ($prodline->{line_id});
                        if(!$sth->execute($xcommand, $isodate, \@arglist)) {
                            $statusstr .= $dbh->errstr . "<br>";
                            $sth->finish;
                            $dbh->rollback;
                            $ok = 0;
                        } else {
                            $dbh->commit;
                            $statusstr .= "Command $command scheduled at $isodate<br>";
                        }
                    }
                    $webdata{statustext} = $statusstr;
                    if($ok) {
                        $webdata{statuscolor} = "oktext";
                    } else {
                        $webdata{statuscolor} = "errortext";
                    }
                }

            } elsif($mode eq "deletecommand") {
                # $command is the command id (ID in database) in this case
                my $sth = $dbh->prepare_cached("DELETE FROM commandqueue WHERE id = ?")
                        or croak($dbh->errstr);
                if(!$sth->execute($command)) {
                    my $errstr = $dbh->errstr;
                    $sth->finish;
                    $dbh->rollback;
                    $webdata{statustext} = "$errstr";
                    $webdata{statuscolor} = "errortext";
                } else {
                    $dbh->commit;
                    $webdata{statustext} = "Command id $command deleted";
                    $webdata{statuscolor} = "oktext";
                }
            }
        }
    }
    
    $webdata{commands} = getCommandQueue($dbh, $memh);
    
    my @admincommands;
    foreach my $admincommand (@commandorder) {
        my %cmd = (
            name    => $admincommand,
            type    => $allcommands{$admincommand},
        );
        push @admincommands, \%cmd;
    }
    $webdata{admincommands} = \@admincommands;
    
    my $template = $th->get("commandqueue_admin", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub get_user {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $th = $self->{server}->{modules}->{templates};

    my %webdata = 
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{user}->{pagetitle},
        LinkTitle        =>  $self->{linktitle},
        webpath            =>  $self->{user}->{webpath},
        commands        => getCommandQueue($dbh, $memh),
    );
    
    my $template = $th->get("commandqueue_user", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}


1;
__END__

=head1 NAME

Maplat::Web::CommandQueue - command ihandling module

=head1 SYNOPSIS

This module allows to view the commandqueue. It also allows admins to schedule
various PostgreSQL admin commands to the backend worker.

=head1 DESCRIPTION

This module gives you complete control over the command queue. It allows to schedule
various admin commands as well as delete commands from the queue. The module automatically
checks if the user is an admin and gives an extended view.

=head1 Configuration

        <module>
                <modname>command</modname>
                <pm>CommandQueue</pm>
                <options>
                        <linktitle>Commands</linktitle>
                        <admin>
                            <webpath>/admin/command</webpath>
                            <pagetitle>Commands</pagetitle>
                        </admin>
                        <user>
                            <webpath>/rbs/command</webpath>
                            <pagetitle>Commands</pagetitle>
                        </user>
                        <db>maindb</db>
                        <memcache>memcache</memcache>
                </options>
        </module>

=head2 get_user

The CommandQueue form (user mode)

=head2 get_admin

The CommandQueue form (admin mode)

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Web::PostgresDB as "db"
Maplat::Web::Memcache as "memcache"

=head1 SEE ALSO

Maplat::Web

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
