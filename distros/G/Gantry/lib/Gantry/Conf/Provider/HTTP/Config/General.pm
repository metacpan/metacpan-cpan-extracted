package Gantry::Conf::Provider::HTTP::Config::General; 

#####################################################################
# 
#  Name        :    Gantry::Conf::Provider::FlatFile::Config::General; 
#  Author      :    Frank Wiles <frank@revsys.com> 
#
#  Description :    Gantry::Conf provider that allows the use of
#                   Config::General config files. 
#
#####################################################################

use strict;
use warnings; 

use Carp qw(croak); 

use Config::General; 
use base qw( Gantry::Conf::Provider::HTTP ); 

#------------------------------------------------
# config 
#------------------------------------------------
# Configure ourself with a Config::General
# config file 
#------------------------------------------------
sub config { 
    my $self    =   shift; 
    my $url     =   shift; 

    my $page    = $self->fetch( $url );

    my $config = Config::General->new( -String => $page ) or
        croak "Unable to create Config::General object: $!"; 

    my %confs = $config->getall; 

    return( \%confs ); 

} # END config 

1;

__END__

=head1 NAME

Gantry::Conf::Provider::HTTP::Config::General -- Uses Config::General to configure your Gantry application 

=head1 SYNOPSIS

use Gantry::Conf::Provider::HTTP::Config::General; 

my $config_hash = Gantry::Conf::Provider::HTTP::Config::General->config($url);

=head1 DESCRIPTION

This is the provider to allow Gantry::Conf to be able to handle Config::General
aka Apache style configuration files received via the web. 

=head1 METHODS

=over 4

=item config

Returns a conf subhash constructed by using Config::General on the result
of an http(s) query.

=back

=head1 SEE ALSO

Gantry(3), Gantry::Conf(3), Config::General(3)

=head1 AUTHOR

Frank Wiles <frank@revsys.com> 

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Revolution Systems, LLC. 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

