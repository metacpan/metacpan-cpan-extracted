# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Worker::PostgresDB;
use strict;
use warnings;

use base qw(Maplat::Worker::BaseModule);
use Maplat::Helpers::DateStrings;

use DBI;
use Carp;
use XML::Simple;

our $VERSION = 0.995;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    if(defined($config{include})) {
        if(!-f $config{include} ) {
            croak("Can't find include config " . $config{include});
        }
        my $include = XMLin($config{include});
        foreach my $key (qw[dburl dbuser dbpassword]) {
            if(defined($include->{$key})) {
                $config{$key} = $include->{$key};
            }
        }
    }
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class

    my $dbh = DBI->connect($self->{dburl}, $self->{dbuser}, $self->{dbpassword},
                               {AutoCommit => 0, RaiseError => 0}) or croak($@);
    $self->{mdbh} = $dbh;

    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. 
    return;
}

sub register {
    my $self = shift;
    
    $self->register_cleanup("cleanup");
    
    return;
}

sub cleanup {
    my ($self) = @_;
    
    $self->{mdbh}->rollback;
    
    return;
}

BEGIN {
    # Auto-magically generate a number of similar functions without actually
    # writing them down one-by-one. This makes changes much easier, but
    # you need perl wizardry level +10 to understand how it works...
    my @stdFuncs = qw(prepare prepare_cached do quote);
    my @simpleFuncs = qw(commit rollback errstr);
    my @varSetFuncs = qw(AutoCommit RaiseError);
    my @varGetFuncs = qw();

    for my $a (@simpleFuncs){
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::$a"} = sub { return $_[0]->{mdbh}->$a(); };
    }
        
    for my $a (@stdFuncs){
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::$a"} = sub { return $_[0]->{mdbh}->$a($_[1]); };
    }

    for my $a (@varSetFuncs){
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::$a"} = sub { return $_[0]->{mdbh}->{$a} = $_[1]; };
    }
    
    for my $a (@varGetFuncs){
        no strict 'refs'; ## no critic (TestingAndDebugging::ProhibitNoStrict)
        *{__PACKAGE__ . "::$a"} = sub { return $_[0]->{mdbh}->{$a}; };
    }

}
1;
__END__

=head1 NAME

Maplat::Worker::PostgresDB - Worker module for accessing PostgreSQL databases

=head1 SYNOPSIS

This module is a wrapper around DBI/DBD::Pg.

=head1 DESCRIPTION

With this worker module, you can easely maintain connections to multiple databases (just
declare multiple modules with different modnames).

=head1 Configuration

=begin text
        <module>
                <modname>maindb</modname>
                <pm>PostgresDB</pm>
                <options>
                        <dburl>dbi:Pg:dbname=Maplat_DB</dburl>
                        <dbuser>Maplat_Server</dbuser>
                        <dbpassword>SECRET</dbpassword>
                </options>
        </module>
=end text

As an alternative, the DB connection info can be included from an external file. The
file should look like this:

=begin text
        <postgresql>
                <dburl>dbi:Pg:dbname=Maplat_DB</dburl>
                <dbuser>Maplat_Server</dbuser>
                <dbpassword>SECRET</dbpassword>
        </postgresql>
=end text
        
with the options section of the module like this:

=begin text
        <options>
                <include>/path/to/configuration.xml</include>
        </options>
=end text

A combination of these two is possible, the setting from the included file overwriting
the directly configured ones.


dburl is the DBI connection string, see DBD::Pg.

=head2 AutoCommit

Get/Set the DBD::Pg "AutoCommit" setting

=head2 RaiseError

Get/Set the DBD::Pg "RaiseError" setting

=head2 errstr

Get the DBI errorstring.

=head2 do

Execute a DBI statement with "do"

=head2 prepare

Prepare a (non-cached) Statement.

=head2 prepare_cached

Prepare a server cached statement (may fall back to non-cached transparently, see DBD::Pg and PostgreSQL documentation
for details).

=head2 quote

Quote a variable for use in PostgreSQL statements.

=head2 commit

Commit transaction.

=head2 rollback

Rollback transaction.

=head2 cleanup

Internal callback function, makes sure there is no active transaction after a work cycle.

=head1 Dependencies

This module is a basic module which does not depend on other worker modules.

=head1 SEE ALSO

Maplat::Worker
DBD::Pg

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
