# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Worker::BackupCommand;
use strict;
use warnings;

use base qw(Maplat::Worker::BaseModule);
use Maplat::Helpers::DateStrings;
use Carp;
use XML::Simple;
use Sys::Hostname;

use Carp;

our $VERSION = 0.995;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    my %commands;

    foreach my $cmd (qw[BACKUP]) {
        my $cmdfunc = "do_" . lc($cmd);
        $commands{$cmd} = $cmdfunc;
    }
    $self->{extcommands} = \%commands;

    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we are pretty much self contained
    return;
}

sub register {
    my $self = shift;

    # Register ourselfs in the RBSCommands module with additional commands
    my $comh = $self->{server}->{modules}->{$self->{commands}};
    
    foreach my $cmd (sort keys %{$self->{extcommands}}) {
        $comh->register_extcommand($cmd, $self);
    }
    return;
}

sub execute {
    my ($self, $command, $arguments) = @_;
    
    if(defined($self->{extcommands}->{$command})) {
        my $cmdfunc = $self->{extcommands}->{$command};
        return $self->$cmdfunc($arguments);
    }
    return;
}

sub do_backup {
    my ($self, $arguments) = @_;
    my $done = 1;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $reph = $self->{server}->{modules}->{$self->{reporting}};

    my $logtype = "OTHER"; # make logging visible only to admin user
    
    my $fname = $self->{basedir} . '/' . hostname() . '_' . getFileDate() . '.backup';
    $reph->debuglog("Starting database backup to $fname");
    $reph->dblog("COMMAND", "Database backup to $fname");
    
    my $fullcommand = $self->{pgdump} .
                ' --host ' . $self->{host} .
                ' --port ' . $self->{port} .
                ' --username ' . $self->{username} .
                ' --format custom ' .
                ' --blobs ' .
#                ' --verbose ' .
                ' --file ' . $fname .
                ' ' . $self->{database};
    if(defined($self->{sudouser}) && $self->{sudouser} ne '') {
        $fullcommand = "sudo -u " . $self->{sudouser} . " $fullcommand";
    }
    $reph->debuglog("Backup command $fullcommand");
    $dbh->commit;
    
    # This may take quite long, so disable the lifetick
    $memh->disable_lifetick;
    
    # Backticks seem just right in this case, ignore perl::Critic
    my @lines = `$fullcommand`; ## no critic (InputOutput::ProhibitBacktickOperators)
    
    # Reenable lifetick
    $memh->refresh_lifetick;
    
    foreach my $line (@lines) {
        if($line =~ /error/i) {
            $done = 0;
        }
        $reph->debuglog($line);
    }
    
    if(!$done) {
        $dbh->rollback;
        return (0, $logtype);
    }
    return (1, $logtype);
}


1;
__END__

=head1 NAME

Maplat::Worker::BackupCommand - database backup command module

=head1 SYNOPSIS

This module does PostgreSQL database backups.

=head1 DESCRIPTION

This module is a plugin module for the "Commands" module and handles
PostgreSQL backups.

=head1 Configuration

    <module>
        <modname>backupcommand</modname>
        <pm>BackupCommand</pm>
        <options>
            <db>maindb</db>
            <memcache>memcache</memcache>
            <commands>commands</commands>
            <reporting>reporting</reporting>
            <pgdump>/usr/bin/pg_dump</pgdump>
            <basedir>/path/to/backups</basedir>
            <host>localhost</host>
            <port>5432</port>
            <username>postgres</username>
            <database>RBS_DB</database>
            <sudouser>someusername</sudouser>
        </options>
    </module>



=head2 execute

Callback to run a command.

=head2 do_backup

Internal function, call the external pg_dump command to execute a full database backup.

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Worker::PostgresDB as "db"
Maplat::Worker::Memcache as "memcache"
Maplat::Worker::Commands as "commands"
Maplat::Worker::Reporting as "reporting"

=head1 SEE ALSO

Maplat::Worker

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
