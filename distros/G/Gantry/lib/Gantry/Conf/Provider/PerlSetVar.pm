package Gantry::Conf::Provider::PerlSetVar; 

#####################################################################
# 
#  Name        :    Gantry::Conf::Provider::PerlSetVar;
#  Author      :    Frank Wiles <frank@revsys.com> 
#
#  Description :    Provider that allows the application admin to
#                   configure via PerlSetVar's in the httpd.conf. 
#
#####################################################################

use strict;
use warnings; 

use base qw(Gantry::Conf::Provider); 

use Carp;

#------------------------------------------------
# config 
#------------------------------------------------
# This loads our configuration from the 
# httpd.conf's PerlSetVars 
#------------------------------------------------
sub config { 
    my $self            =   shift;
    my $instance        =   shift; 
    my $instance_ref    =   shift; 

    # Make sure we have an instance 
    croak "Gantry::Conf ERROR - No instance given to ".
          "Gantry::Conf::Provider::PerlSetVar::config()"
          if !$instance or $instance eq ''; 

    my $load_parameters = $$instance_ref{LoadParameters}; 

    croak "Gantry::Conf ERROR - No LoadParameters defined for instance ".
          "'$instance'" if !$load_parameters or $load_parameters eq ''; 

    # Temp hash to return to caller 
    my %return; 

    # Check to see if we're in a mod_perl environment 
    if( $ENV{MOD_PERL} ) { 

        my $r; 

        # Load the proper modules depending on if we're in mod_perl 1 or 2
        if( $ENV{MOD_PERL_API_VERSION} >= 2 ) { 
            require Apache2::RequestUtil;
            $r = Apache2::RequestUtil->request; 

            # Give a meaningful error message 
            if( !defined( $r ) ) { 
                croak "Gantry::Conf ERROR - Unable to load request from ".
                      "Apache2::RequestUtil->request.  Perhaps you need ".
                      "to set Options +GlobalRequest in httpd.conf?";
            }

        }
        else { 
            require Apache; 
            $r = Apache->request; 

            if( !defined( $r ) ) { 
                croak "Gantry::Conf ERROR - Unable to load request from ". 
                      "Apache->request."; 
            }

        }

        # Load each PerlSetVar defined in our instance 
        foreach my $p ( split( /\s+/, $load_parameters ) ) { 
            $return{$p} = $r->dir_config($p);
        } 

    } 
    else { 

        ###############################################
        # Since we are not in a mod_perl environment 
        # we need to parse the httpd.conf file and 
        # determine what PerlSetVar's apply to this 
        # application 
        ###############################################

        # Make sure we have a config file to use and that it is 
        # readable 
        my $httpd_conf = $$instance_ref{ApacheConfigFile}; 

        if( !-e $httpd_conf ) { 
            croak "Gantry::Conf ERROR - ApacheConfigFile '$httpd_conf' for ".
                  "instance '$instance' does not exist."; 
        }
        if( !-r $httpd_conf ) { 
            croak "Gantry::Conf ERROR - ApacheConfigFile '$httpd_conf' for ".
                  "instance '$instance' is not readable. Check permissions.";
        }

    } 

    return( \%return ); 

} # END config 

1;

__END__

=head1 NAME

Gantry::Conf::Provider::PerlSetVar - Configure via PerlSetVar's in httpd.conf

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 METHODS

=over 4

=item config

Returns config based on set vars in an httpd.conf excerpt.

=back

=head1 SEE ALSO

Gantry(3), Gantry::Conf(3), Gantry::Conf::Tutorial(3), Ganty::Conf::FAQ(3), Apache2::RequestUtil(3), Apache2::ServerUtil(3)

=head1 LIMITATIONS

=head1 AUTHOR

Frank Wiles <frank@revsys.com> 

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Revolution Systems, LLC. 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

