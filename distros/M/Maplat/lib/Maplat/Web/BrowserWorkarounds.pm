# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::BrowserWorkarounds;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);
use Maplat::Helpers::DateStrings;

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
    
    $self->register_prefilter("prefilter");
    $self->register_postfilter("postfilter");
    $self->register_defaultwebdata("get_defaultwebdata");
    return;
}


sub prefilter {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
    my $userAgent = $cgi->user_agent() || "Unknown";
    
    my $browser = "Unknown";
    if($userAgent =~ /Firefox/) {
        $browser = "Firefox";
    }
    
    my %browserData = (
        Browser        =>    $browser,
        UserAgent    =>    $userAgent,
    );
    
    $self->{BrowserData} = \%browserData;
    
    return;
    
}
sub postfilter {
    my ($self, $cgi, $header, $result) = @_;
    
    if(!defined($self->{BrowserData}->{Browser})) {
        return;
    } elsif($self->{BrowserData}->{Browser} eq "Firefox") {
        # *** Workarounds for Firefox ***
        if($result->{status} eq "307") {
            # some versions of Firefox make troubles with a 307 resulting
            # from a POST (for example viewselect), it pops
            # up a completly stupid extra YES/NO box.
            # Soo... rewrite to a 303 and also add a HTML-redirect the page
            # instead
            # Of course, in case of POST and then redirecting, the correct return code
            # *IS* a 303, *not* the 307. But strangely enough, only Firefox shows this
            # very annoying behavior.
            
            my $location = $result->{location};
            $result->{status} = 303;
            $result->{statustext} = "Using HTML redirect for Firefox";
            
            my %webdata = (
                $self->{server}->get_defaultwebdata(),
                PageTitle           =>  "Redirect",
                ExtraHEADElements    => "<meta HTTP-EQUIV=\"REFRESH\" content=\"3; url=$location\">",
                NextLocation        => $location,
            );
                
            my $template = $self->{server}->{modules}->{templates}->get("browserworkarounds_redirect", 1, %webdata);
            $result->{data} = $template;
        }
    }
    
    return;
}

sub get_defaultwebdata {
    my ($self, $webdata) = @_;
    
    $webdata->{BrowserData} = $self->{BrowserData};
    return;
}

1;
__END__

=head1 NAME

Maplat::Web::BrowserWorkarounds - filter pages to display correctly in various browsers

=head1 SYNOPSIS

This module filters generated pages and headers so they will display correctly in different browsers

=head1 DESCRIPTION

This module registers itself in pre- and postfilter. It does various things to the browser request
and server response to compensate for different browser issues. Currently, only a workaround for
Firefox is implemented.

=head1 Configuration

        <module>
                <modname>workarounds</modname>
                <pm>BrowserWorkarounds</pm>
                <options>
                        <pagetitle>Workarounds</pagetitle>
                </options>
        </module>

it is highly recommended to configure this module as the last module, so it can clean up after everything
else is done.

=head2 prefilter

Internal function.

=head2 postfilter

Internal function.

=head1 Dependencies

This module does not depend on other webgui modules.

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
