# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::VariablesADM;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;

our $VERSION = 0.995;

# WARNING: This uses mainly hardcoded stuff


use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    my @variables = qw[LogoDate HeaderMessage HeaderInfo];
    $self->{variables} = \@variables;
    
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
    
    my $webpath = $cgi->path_info();
    my $memh = $self->{server}->{modules}->{$self->{memcache}};
    my $th = $self->{server}->{modules}->{templates};

    # Need to handle setting/deleting variables before getting the
    # default webdata so changes take effect instantly
    my $mode = $cgi->param('mode') || 'view';
    
    if($mode eq "setvalue") {
        my $varname = $cgi->param('varname');
        my $varvalue = $cgi->param('varvalue') || "";
        my $setter = "set_$varname";
        $self->$setter($varvalue);
    } elsif($mode eq "delvalue") {
        my $varname = $cgi->param('varname');
        my $setter = "del_$varname";
        $self->$setter;
    } elsif($mode eq "reload") {
        $self->{server}->reload;
    }

    my %webdata =
    (
        $self->{server}->get_defaultwebdata(),
        PageTitle       =>  $self->{pagetitle},
        webpath            =>  $self->{webpath},
    );
    
    my @varlist;
    foreach my $var (@{$self->{variables}}) {
        my $getter = "get_$var";
        my $val = $self->$getter;
        if(!defined($val)) {
            $val = "";
        }
        my %line = (
            name    => $var,
            value    => $th->quote($val),
        );
        push @varlist, \%line;
    }
    $webdata{variables} = \@varlist;
    
    my $template = $th->get("variablesadm", 1, %webdata);
    return (status  =>  404) unless $template;
    return (status  =>  200,
            type    => "text/html",
            data    => $template);
}

sub set_LogoDate {
    my ($self, $value) = @_;
    
    $self->{server}->{modules}->{logo}->{today} = $value;
    return;
}

sub get_LogoDate {
    my ($self) = @_;
    
    return $self->{server}->{modules}->{logo}->{today};
}

sub del_LogoDate {
    my ($self) = @_;
    
    undef $self->{server}->{modules}->{logo}->{today};
    return;
}

sub set_HeaderMessage {
    my ($self, $value) = @_;
    
    $self->{server}->{modules}->{defaultwebdata}->{fields}->{header_message} = $value;
    return;
}

sub get_HeaderMessage {
    my ($self) = @_;
    
    return $self->{server}->{modules}->{defaultwebdata}->{fields}->{header_message};
}

sub del_HeaderMessage {
    my ($self) = @_;
    
    undef $self->{server}->{modules}->{defaultwebdata}->{fields}->{header_message};
    return;
}

sub set_HeaderInfo {
    my ($self, $value) = @_;
    
    $self->{server}->{modules}->{defaultwebdata}->{fields}->{header_info} = $value;
    return;
}

sub get_HeaderInfo {
    my ($self) = @_;
    
    return $self->{server}->{modules}->{defaultwebdata}->{fields}->{header_info};
}

sub del_HeaderInfo {
    my ($self) = @_;
    
    undef $self->{server}->{modules}->{defaultwebdata}->{fields}->{header_info};
    return;
}

1;
__END__

=head1 NAME

Maplat::Web::VariablesADM - change some webgui variables online

=head1 SYNOPSIS

This modules lets you change some internal webgui variables online

=head1 DESCRIPTION

This module is mostly used for debugging. It may or may not be of use to use, since
currently all changeable variables are hardcoded.

Basically, this module lets you change the variables online, it also lets you call the main
reload() routine from the webgui, which may (or may not) work as expected.

=head1 Configuration

        <module>
                <modname>variablesadm</modname>
                <pm>VariablesADM</pm>
                <options>
                        <pagetitle>Variables</pagetitle>
                        <webpath>/admin/variables</webpath>
                        <memcache>memcache</memcache>
                </options>
        </module>

=head2 del_HeaderInfo

Internal function

=head2 del_HeaderMessage

Internal function

=head2 del_LogoDate

Internal function

=head2 get

Internal function

=head2 get_HeaderInfo

Internal function

=head2 get_HeaderMessage

Internal function

=head2 get_LogoDate

Internal function

=head2 set_HeaderInfo

Internal function

=head2 set_HeaderMessage

Internal function

=head2 set_LogoDate

Internal function

=head1 Dependencies

This module depends on the following modules beeing configured (the 'as "somename"'
means the key name in this modules configuration):

Maplat::Web::memcache as "memcache"

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
