# MAPLAT  (C) 2008-2011 Rene Schickbauer
# Developed under Artistic license
# for Magna Powertrain Ilz
package Maplat::Web::PreventGetWithArgs;
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
    return;
}


sub prefilter {
    my ($self, $cgi) = @_;
    
    if($cgi->request_method() !~ /^(?:PUT|POST)$/io) {
        my @names = $cgi->param;
        my $count = scalar @names;
        
        if($count) {
            return (status  =>  $self->{errorcode},
                type    => "text/plain",
                data    => $self->{pagetext});
        }
    }

    return;
    
}

1;
__END__

=head1 NAME

Maplat::Web::PreventGetWithArgs - prevent GET requests with arguments

=head1 SYNOPSIS

This module prevents GET requests with arguments.

=head1 DESCRIPTION

Most XSS attacks (cross site scripting) use GET requests with arguments/parameters to craft
harmfull links. Since all maplat modules (at least the ones from this author) only
POST arguments and/or use dynamically created URLS (and that only hold ID's), using
this module should increase safety without bad side effects.

=head1 Configuration

        <module>
                <modname>preventgetargs</modname>
                <pm>PreventGetWithArgs</pm>
                <options>
                        <errorcode>414</errorcode>
                        <pagetext>414 Request-URI Too Long. Did you try to XSS?</pagetext>
                </options>
        </module>

it is highly recommended to configure this module as the cwfirstlast module, so it can catch this requests very
early.

=head2 prefilter

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
