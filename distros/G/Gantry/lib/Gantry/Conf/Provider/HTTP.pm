package Gantry::Conf::Provider::HTTP; 

#####################################################################
# 
#  Name        :    Gantry::Conf::Provider::HTTP
#  Author      :    Phil Crow <pcrow@sunflowerbroadband.com> 
#
#  Description :    Base class that all Gantry::Conf::Provider::HTTP::*
#                   modules should inherit from.  
#
#####################################################################

use strict;
use warnings; 

use base 'Gantry::Conf::Provider';

use Carp;
use LWP::UserAgent;

sub fetch {
    my $self     = shift;
    my $url      = shift;

    my $ua       = LWP::UserAgent->new();
    $ua->agent( 'GantryConf/0.1' );

    my $request  = HTTP::Request->new( GET => $url );
    my $response = $ua->request( $request );

    return $response->content if ( $response->is_success );

    croak $response->status_line;
}

1;

__END__

=head1 NAME

Gantry::Conf::Provider::HTTP - Base class for all Gantry::Conf::Provider::HTTP modules

=head1 SYNOPSIS

    use base 'Gantry::Conf::Provider::HTTP';

    my $response = $self->fetch( $url );

=head1 DESCRIPTION

This module handle the transport over http for all modules that want to
pull content from a web server.  I know it's easy to do, but I want it in
one place.

=head1 METHODS

=over 4

=item fetch

Give it a url, it'll give you the content from it (including error
responses).

=back

=head1 SEE ALSO

Gantry(3), Gantry::Conf(3), Gantry::Conf::Tutorial(3), Ganty::Conf::FAQ(3)

=head1 LIMITATIONS

=head1 AUTHOR

Phil Crow <pcrow@sunflowerbroadband.com> 

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Phil Crow. 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

