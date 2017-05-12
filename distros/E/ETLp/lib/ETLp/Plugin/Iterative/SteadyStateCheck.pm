package ETLp::Plugin::Iterative::PLSQL;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin::Iterative::SteadyStateCheck - Check that a file's size isn't
changing

=cut

class ETLp::Plugin::Iterative::SteadyStateCheck extends ETLp::Plugin {

    sub type {
        return 'steady_state_check';
    }

    method run (Str $filename) {
        my $interval = $self->item->{interval} || 5;
        
        my $curr_size = -s $filename;
        sleep $interval;

        while ((-s $filename) != $curr_size) {
            $curr_size = -s $filename;
            sleep $interval;
        }
        
        return $filename;
    }
}

=head1 METHODS

=head2 type 

Registers the plugin type.
    
=head2 run

Wait until the size of the supplied file stops changing. Will pause for
the interval defined in the item before repeating the check. The
interval defaults to five seconds if none is provided.

=head3 paramaters

    * filename - the name of the file under consideration
    
-head3 returns

    * filename - this will be the same as the supplied file name


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application