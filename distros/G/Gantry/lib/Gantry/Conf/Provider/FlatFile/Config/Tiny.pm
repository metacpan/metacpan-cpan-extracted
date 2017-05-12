package Gantry::Conf::Provider::FlatFile::Config::Tiny; 

#####################################################################
# 
#  Name        :    Gantry::Conf::Provider::FlatFile::Config::Tiny; 
#  Author      :    Frank Wiles <frank@revsys.com> 
#
#  Description :    Provider for using Config::Tiny style config
#                   files
#
#####################################################################

use strict;
use warnings; 

use Carp qw(croak); 
use Gantry::Conf::Provider; 
use Config::Tiny;
use base qw( Gantry::Conf::Provider ); 

#------------------------------------------------
# config
#------------------------------------------------
# Configure ourselves via Config::Tiny
#------------------------------------------------
sub config { 
    my $self    =   shift; 
    my $file    =   shift; 
    
    # Create our Config::Tiny object 
    my $conf = Config::Tiny->new(); 

    # Retrieve the configuration file 
    $conf = Config::Tiny->read( $file ); 

    # Fixup our data because Config::Tiny uses an odd format. 
    # We need to move the "root" parameters into being actual
    # keys instead of members of the '_' sub-hash
    my %return_hash; 
    foreach my $k ( keys( %{ $conf } ) ) { 

        if( $k eq '_' ) { 
            foreach my $inner_key ( keys( %{ $conf->{_} } ) ) { 
                $return_hash{$inner_key} = $conf->{_}->{$inner_key}; 
            }
        }
        else { 
            $return_hash{$k} = $conf->{$k}; 
        }
    }

    return( \%return_hash ); 

} # END config 

1;

__END__

=head1 NAME

Gantry::Conf::Provider::FlatFile::Config::Tiny -- Uses Config::Tiny to configure your Gantry application 

=head1 SYNOPSIS

  use Gantry::Conf::Provider::FlatFile::Config::Tiny; 

  my $config_hash = Gantry::Conf::Provider::FlatFile::Config::Tiny->config( $file );
=head1 DESCRIPTION

This allows Gantry::Conf to handle files in a Config::Tiny ( aka INI ) style. 

=head1 METHODS

=over 4

=item config

Returns a config subhash by applying Config::Tiny to an ini style file.

=back

=head1 SEE ALSO

Gantry(3), Gantry::Conf(3), Config::Tiny(3)

=head1 AUTHOR

Frank Wiles <frank@revsys.com> 

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Revolution Systems, LLC. 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

