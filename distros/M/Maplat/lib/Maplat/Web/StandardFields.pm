# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::StandardFields;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;
use Maplat::Helpers::DBSerialize;
use Sys::Hostname;

our $VERSION = 0.995;


use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    # copy general config options to field-hash
        foreach my $keyname (keys %{$self->{static}->{fields}}) {
            next if($keyname eq 'hosts');
            $self->{fields}->{$keyname} = $self->{static}->{fields}->{$keyname};
        }
    
    
    # copy host-specific settings from sub-hash to field-hash
    my $hname = hostname;
    print "   Host-specific configuration for '$hname'\n";
    if(defined($self->{static}->{fields}->{hosts}->{$hname})) {
        foreach my $keyname (keys %{$self->{static}->{fields}->{hosts}->{$hname}}) {
            $self->{fields}->{$keyname} = $self->{static}->{fields}->{hosts}->{$hname}->{$keyname};
        }
    }
    
    return $self;
}

sub reload {
    my ($self) = shift;
    # Nothing to do.. in here, we only use the template and database module
    return;
}

sub register {
    my $self = shift;
    $self->register_defaultwebdata("get_defaultwebdata");
    return;
}

sub get_defaultwebdata {
    my ($self, $webdata) = @_;
    
    $webdata->{CurrentTime} = Maplat::Helpers::DateStrings::getISODate();
    
    foreach my $key (keys %{$self->{fields}}) {
        next if($key eq "hosts");
        $webdata->{$key} = $self->{fields}->{$key};
    }
    
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    
    foreach my $key (keys %{$self->{memory}->{fields}}) {
        my $data = $memh->get($self->{memory}->{fields}->{$key});
        if(defined($data) && $self->{memory}->{fields}->{$key} =~ /^(BUILD|VERSION)\:\:/go) {
            $data = dbderef($data);
        }
        $webdata->{$key} = $data;

    }
    
    return;
}

1;
__END__

=head1 NAME

Maplat::Web::StandardFields - provide some standard fields for default_webdata

=head1 SYNOPSIS

This module provides static as well as dynamic data fields for default_webdata

=head1 DESCRIPTION

With this module, you can set static information in default_webdata directly from
the configuration file. It also allows to set them host-specific.

StandardFields also can use memcached-keys to set data fields in default_webdata. So, nearly
all data that doesn't require logic (e.g. database, calculation etc), this is the simplest
to use module to provide data to the template renderer.

=head1 Configuration

        <module>
                <modname>defaultwebdata</modname>
                <pm>StandardFields</pm>
                <options>
                        <memcache>memcache</memcache>
                        <static>
                                <fields>
                                        <!-- set menuitem width -->
                                        <toplink_width>140px</toplink_width>

                                        <!-- per host configuration -->
                                        <hosts>
                                                <WXPDEV>
                                                        <!-- Display an info message on development system -->
                                                        <header_message>Testsystem</header_message>
                                                </WXPDEV>
                                        </hosts>
                                </fields>
                        </static>
                        <memory>
                                <fields>
                                        <!-- versions and buildnums read from memcached -->
                                        <SVCVersion>VERSION::Maplat SVC</SVCVersion>
                                        <SVCBuildNum>BUILD::Maplat SVC</SVCBuildNum>
                                        <WebGuiVersion>VERSION::Maplat WebGui</WebGuiVersion>
                                        <WebGuiBuildNum>BUILD::Maplat WebGui</WebGuiBuildNum>
                                        <MaplatWorkerVersion>VERSION::Maplat Worker</MaplatWorkerVersion>
                                        <MaplatWorkerBuildNum>BUILD::Maplat Worker</MaplatWorkerBuildNum>
                                        <MaplatAdmWorkerVersion>VERSION::MaplatAdm Worker</MaplatAdmWorkerVersion>
                                        <MaplatAdmWorkerBuildNum>BUILD::MaplatAdm Worker</MaplatAdmWorkerBuildNum>
                                </fields>
                        </memory>
                </options>
        </module>


=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Web::Memcache as "memcache"

=head1 SEE ALSO

Maplat::Web
Maplat::Web::Memcache

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
