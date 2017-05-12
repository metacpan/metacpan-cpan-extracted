# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Helpers::CommandHelper;
use strict;
use warnings;

use 5.010;
use Maplat::Helpers::DateStrings;
use Carp;

use base qw(Exporter);
our @EXPORT = qw(getCommandQueue); ## no critic (Modules::ProhibitAutomaticExportation)

our $VERSION = 0.995;

sub getCommandQueue {
    my ($dbh, $memh, $command) = @_;
    
    my %active = $memh->get_activecommands();
    
    my @commands;
    
    my $where = "";
    if(defined($command) and $command ne "") {
        $where .= $command . " ";
    }
    if($where ne "") {
        $where = " WHERE $where ";
    }
    
    
    my $stmt = "SELECT id, queuetime AS time, command AS name, arguments, starttime FROM commandqueue $where ORDER BY starttime, command, arguments[0]";
    
    my $sth = $dbh->prepare_cached($stmt) or croak($dbh->errstr);
    $sth->execute;
    while((my $line = $sth->fetchrow_hashref)) {
        $line->{time} = fixDateField($line->{time});
        $line->{starttime} = fixDateField($line->{starttime});

        if(defined($line->{arguments}->[0])) {
            $line->{args} = join("<br>", @{$line->{arguments}});
        } else {
            $line->{args} = "";
        }
        
        if($line->{id} ~~ %active) {
            $line->{class} = "activecommand";
            $line->{worker} = $active{$line->{id}};
            $line->{worker} =~ s/\ Worker//go;
        } else {
            $line->{worker} = "";
        }
        
        push @commands, $line;
    }
    
    $sth->finish;
    $dbh->commit;
    return \@commands;
}

1;

__END__

=head1 NAME

Maplat::Helpers::CommandHelper - get the current command queue

=head1 SYNOPSIS

  use Maplat::Helpers::CommandHelper;
  
  my @commands = getCommandQueue($dbh, $memh);
  my @commands = getCommandQueue($dbh, $memh, $command);

=head1 DESCRIPTION

This module is mostly an internal helper module to read out the command queue
and Memcached, return a complex array of all commands in the queue, with
the current active commands flagged.

=head2 getCommandQueue

Takes two or three arguments: The database handle, the memcached-module handle
and (optionally) a command (database where clause snippet).

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
