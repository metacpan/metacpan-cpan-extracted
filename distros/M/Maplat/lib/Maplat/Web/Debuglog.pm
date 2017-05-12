# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

package Maplat::Web::Debuglog;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::DBSerialize;

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
    $self->register_webpath($self->{webpath}, "get");
    return;
}

sub get {
    my ($self, $cgi) = @_;
    
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $th = $self->{server}->{modules}->{templates};
    
    my %webdata = (
        $self->{server}->get_defaultwebdata(),
        PageTitle   =>  $self->{pagetitle},
        PostLink        =>  $self->{webpath}
    );
    
    my $debuglog = $memh->get($self->{worker});
    my @loglines;
    if($debuglog) {
        $debuglog = dbderef($debuglog);
        foreach my $line (reverse @{$debuglog}) {
            if($line =~ /(\d\d\d\d\-\d\d\-\d\d\ \d\d\:\d\d\:\d\d)\ (.*)/o) { ## no critic (RegularExpressions::RequireExtendedFormatting)
                my %hline = (
                    timestamp    => $1,
                    message        => $th->quote($2),
                );
                push @loglines, \%hline;
            }
        }
    }
    $webdata{debuglines} = \@loglines;
    
    my $template = $th->get("debuglog", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}


1;
__END__

=head1 NAME

Maplat::Web::Debuglog - view debuglog (STDOUT) from workers

=head1 SYNOPSIS

This module displays the debuglog (STDOUT) from workers via memcache.

=head1 DESCRIPTION

A very helpfull module, this one lets you view the STDOUT messages from workers written
by the debuglog worker module (via memcache). You can use this module multiple times to
display the debuglog of more than one worker.

=head1 Configuration

        <module>
                <modname>rbsdebuglog</modname>
                <pm>Debuglog</pm>
                <options>
                        <pagetitle>RBS Worker</pagetitle>
                        <webpath>/admin/rbsdebuglog</webpath>
                        <memcache>memcache</memcache>
                        <worker>Admin Worker</worker>
                </options>
        </module>

worker ... APPNAME of the worker to display

=head2 get

Display the worker debuglog.

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

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
