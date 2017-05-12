# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz

package Maplat::Web::DirCleaner;
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
    
    my $dirstatus = $memh->get("dircleanstatus");
    my @dirlines;
    if($dirstatus) {
        $dirstatus = dbderef($dirstatus);
        foreach my $dir (sort keys %{$dirstatus}) {
            my %hline = (
                path        => $th->quote($dir),
                status        => $dirstatus->{$dir}->{status},
                maxage        => $dirstatus->{$dir}->{maxage},
            );
            push @dirlines, \%hline;
        }
    }
    $webdata{dirlines} = \@dirlines;
    
    my $template = $th->get("dircleaner", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

1;
__END__

=head1 NAME

Maplat::Web::DirCleaner - view worker DirCleaner status

=head1 SYNOPSIS

This module displays the dircleaner background worker status via memcache.

=head1 DESCRIPTION

In the background worker, you can configure a DirCleaner module to clean out old/stale files from
directories. Success/Failure of the last cleaning operation is saved in memcached. You can use this
module to visualize the result.

=head1 Configuration

        <module>
                <modname>dircleaner</modname>
                <pm>DirCleaner</pm>
                <options>
                        <pagetitle>DirCleaner</pagetitle>
                        <webpath>/admin/dircleaner</webpath>
                        <memcache>memcache</memcache>
                </options>
        </module>

=head2 get

The dircleaner form.

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Web::Memcache as "memcache"

=head1 SEE ALSO

Maplat::Web
Maplat::Worker::DirCleaner

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
