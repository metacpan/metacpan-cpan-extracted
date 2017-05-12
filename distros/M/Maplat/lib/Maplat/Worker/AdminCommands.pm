# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Worker::AdminCommands;
use strict;
use warnings;

use base qw(Maplat::Worker::BaseModule);
use Maplat::Helpers::DateStrings;
use Carp;
use XML::Simple;

use Carp;

our $VERSION = 0.995;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    my %commands;

    foreach my $cmd (qw[VACUUM_ANALYZE VACUUM_FULL REINDEX_ALL_TABLES REINDEX_TABLE ANALYZE_TABLE VACUUM_ANALYZE_TABLE
                        NOP_OK NOP_FAIL]) {
        my $cmdfunc = "do_" . lc($cmd);
        $commands{$cmd} = $cmdfunc;
    }
    $self->{extcommands} = \%commands;

    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
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

BEGIN {
    # Auto-magically generate a number of similar functions without actually
    # writing them down one-by-one. This makes consistent changes much easier, but
    # you need perl wizardry level +10 to understand how it works...
    #
    # Added wizardry points are gained by this module beeing a parent class to
    # all other web modules, so this auto-generated functions are subclassed into
    # every child.
    #
    # This database admin commands block the worker and run with an unkown
    # runlength, so we choose to temporarly disable lifetick handling
    my %simpleFuncs = (
            vacuum_analyze            =>    "VACUUM ANALYZE",
            vacuum_full                =>  "VACUUM FULL ANALYZE",
            reindex_table            =>    "REINDEX TABLE __ARGUMENT__",
            analyze_table            =>    "ANALYZE __ARGUMENT__",
            vacuum_analyze_table    =>    "VACUUM ANALYZE __ARGUMENT__",
            );
    
    no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)

    # -- Deep magic begins here...
    for my $a (keys %simpleFuncs){
        
        *{__PACKAGE__ . "::do_$a"} =
            sub {
                
                my ($self, $arguments) = @_;
                
                my $done = 0;
            
                my $dbh = $self->{server}->{modules}->{$self->{db}};
                my $reph = $self->{server}->{modules}->{$self->{reporting}};
                my $memh = $self->{server}->{modules}->{$self->{memcache}};
            
                my $logtype = "OTHER"; # make logging visible only to admin user
                
                # If SQL function needs an argument, we'll get it from our input array
                my $dbhfunc = $simpleFuncs{$a};
                $dbhfunc =~ s/__ARGUMENT__/$arguments->[0]/g;
                
                # Debuglog what we are doing
                $reph->debuglog(" ** $dbhfunc");
                
                # Function does NOT allow transactions - so turn it off after
                # a rollback() call (just to be certain)
                $dbh->rollback;
                $dbh->AutoCommit(1);
                $memh->disable_lifetick;
                $done = $dbh->do($dbhfunc);
                $memh->refresh_lifetick;
                $dbh->AutoCommit(0);
                
                if(!$done && $done ne "0E0") {
                    $dbh->rollback;
                    return (0, $logtype);
                }
                return (1, $logtype);
                
                
            };
    }
    # ... and ends here
}

sub do_reindex_all_tables {
    my ($self, $arguments) = @_;
    my $done = 0;

    my $dbh = $self->{server}->{modules}->{$self->{db}};
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $reph = $self->{server}->{modules}->{$self->{reporting}};

    my $logtype = "OTHER"; # make logging visible only to admin user
    
    # Vacuum analyze - does NOT allow transaction
    my $error = 0;
    my $seltabsth = $dbh->prepare_cached("SELECT tablename " .
                                    "FROM pg_tables " .
                                    "WHERE tableowner = 'RBS_Server' " .
                                    "ORDER BY tablename")
                or croak($dbh->errstr);
    
    my @tabnames;
    if($seltabsth->execute()) {
        while((my @row = $seltabsth->fetchrow_array)) {
            push @tabnames, $row[0];
        }
        $seltabsth->finish;
    } else {
        $error = 1;
    }
    $dbh->rollback; # no writes so far, *and* we need to turn of
                    # transactions for reindexing
    
    if(!$error) {
        $dbh->AutoCommit(1);
        foreach my $tabname (@tabnames) {
            $reph->debuglog(" ** REINDEX $tabname");
            if(!$dbh->do("REINDEX TABLE $tabname")) {
                $error = 1;
                $reph->dblog("COMMAND", "REINDEX TABLE $tabname failed");
            }
        }
        $dbh->AutoCommit(0);
    }
    
    if(!$error) {
        $done = 1;
    }
    
    if(!$done) {
        $dbh->rollback;
        return (0, $logtype);
    }
    return (1, $logtype);
}

sub do_nop_ok {
    return (1, "OTHER");
}

sub do_nop_fail {
    return (0, "OTHER");
}

1;
__END__

=head1 NAME

Maplat::Worker::AdminCommands - database admin command module

=head1 SYNOPSIS

This module executes PostgreSQL admin commands like "VACUUM ANALYZE"

=head1 DESCRIPTION

This module is a plugin module for the "Commands" module and handles
PostgreSQL admin commands scheduled from the WebGUI.

=head1 Configuration

        <module>
                <modname>admincommands</modname>
                <pm>AdminCommands</pm>
                <options>
                        <db>maindb</db>
                        <memcache>memcache</memcache>
                        <commands>commands</commands>
                        <reporting>reporting</reporting>
                </options>
        </module>


=head2 execute

Run an admin command.

=head2 do_analyze_table

Internal functions.

=head2 do_nop_fail

Internal functions.

=head2 do_nop_ok

Internal functions.

=head2 do_reindex_all_tables

Internal functions.

=head2 do_reindex_table

Internal functions.

=head2 do_vacuum_analyze

Internal functions.

=head2 do_vacuum_analyze_table

Internal functions.

=head2 do_vacuum_full

Internal functions.

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
