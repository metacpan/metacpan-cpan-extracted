# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::PathRedirection;
use strict;
use warnings;

use base qw(Maplat::Web::BaseModule);

our $VERSION = 0.995;


use Carp;

sub new {
    my ($proto, %config) = @_;
    my $class = ref($proto) || $proto;
    
    my $self = $class->SUPER::new(%config); # Call parent NEW
    bless $self, $class; # Re-bless with our class
    
    my %paths;
    
    # pre-parse the options for faster response
    foreach my $path (@{$self->{redirect}}) {
        my %tmp = (status       => $path->{statuscode},
                   statustext   => $path->{statustext},
                   location     => $path->{destination},
                   data         => "<html><body>If you are not automatically redirected, click " .
                                    "<a href=\"" . $path->{destination} . "\">here</a>.</body></html>",
                   type         => "text/html",
                  );
        $paths{$path->{source}} = \%tmp;
    }
    
    $self->{paths} = \%paths;
        
    return $self;
}

sub reload {
    # Nothing to do
    return;
}

sub register {
    my $self = shift;
    $self->register_prefilter("prefilter");
    return;
}

sub prefilter {
    my ($self, $cgi) = @_;
    
    my $webpath = $cgi->path_info();
    
    # if there is a redirect for the current path, just return the
    # pre-parsed response
    if(defined($self->{paths}->{$webpath})) {
        return %{$self->{paths}->{$webpath}};
    }
    
    return; # No redirection
}

1;
__END__

=head1 NAME

Maplat::Web::PathRedirection - redirect web access to other pages

=head1 SYNOPSIS

Prefilter access to pages and redirect the calls to other pages.

=head1 DESCRIPTION

This module prefilters access to maplat webpages and redirects the browser to other pages if
necessary. This is very usefull in fixing broken links and also work around common user errors
and stale bookmarks.

=head1 Configuration

        <module>
                <modname>pathcorrection</modname>
                <pm>PathRedirection</pm>
                <options>
                        <redirect>
                                <source>/</source>
                                <destination>/user/login</destination>
                                <statuscode>307</statuscode>
                                <statustext>Please use the login module</statustext>
                        </redirect>
                        <redirect>
                                <source>/dev/search</source>
                                <destination>/user/search</destination>
                                <statuscode>301</statuscode>
                                <statustext>Out of BETA - Moved permanently to user namespace</statustext>
                        </redirect>
                </options>
        </module>

It is recommended to use this module as a "fallback", e.g. configure it after nearly all other modules. The only
module that should follow is the BrowserWorkarounds module (mostly to fix redirects for broken browsers like firefox)

=head2 prefilter

Internal function.

=head1 Dependencies

This module does not depend directly on any other module, but it SHOULD be used in conjunction with the BrowserWorksarounds module
to give a smooth ride with different browsers.

=head1 SEE ALSO

Maplat::Web
Maplat::Web::BrowserWorksarounds

=head1 AUTHOR

Rene Schickbauer, E<lt>rene.schickbauer@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2011 by Rene Schickbauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut
