package Gantry::Conf::Provider; 

#####################################################################
# 
#  Name        :    Gantry::Conf::Provider 
#  Author      :    Frank Wiles <frank@revsys.com> 
#
#  Description :    Base class that all Gantry::Conf::Provider::*
#                   modules should inherit from.  
#
#####################################################################

use strict;
use warnings; 

1;

__END__

=head1 NAME

Gantry::Conf::Provider - Base class for all Gantry::Conf providers 

=head1 SYNOPSIS

    package Gantry::Conf::Provider::SomeNewProvider; 
    use strict; 
    use warnings; 

    use base 'Gantry::Conf::Provider'; 

    use Carp; 

    sub config { 
        my $self    =   shift; 
        my %config; 

        # Retrieve your configuration here. 
        # And return a hash ref 

        return( \%config ); 

    } 

=head1 DESCRIPTION

=head1 METHODS

=head1 SEE ALSO

Gantry(3), Gantry::Conf(3), Gantry::Conf::Tutorial(3), Ganty::Conf::FAQ(3)

=head1 AUTHOR

Frank Wiles <frank@revsys.com> 

=head1 COPYRIGHT and LICENSE

Copyright (c) 2006, Frank Wiles. 

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut

