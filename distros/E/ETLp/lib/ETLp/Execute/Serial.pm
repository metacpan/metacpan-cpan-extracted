package ETLp::Execute::Serial;

use MooseX::Declare;

=head1 NAME

ETLp::Execute::Serial - Execute a Serial Pipeline

=head1 DESCRIPTION

Takes the array ref of Pipeline items and executes each item in turn

=head1 METHODS

=head2 new

=head3 parameters

All of the following parameters are mandatory

    * pipeline. an arrayref pipeline items
    * config. The application configuration
    
=head3 retuns

    * void

=cut

class ETLp::Execute::Serial with ETLp::Role::Config {
    use Try::Tiny;
    use Carp;
    use ETLp::Exception;
    use Data::Dumper;
    
    has 'pipeline' => (is => 'ro', isa => 'ArrayRef', required => 1);
    has 'config'   => (is => 'ro', isa => 'HashRef', required => 1);
    
    method run {
        my $warning = 0;
        
        try {
            ITEM_LOOP: foreach my $item (@{$self->pipeline}) {
                $self->logger->debug("Item: " . Dumper($item));
    
                # Create an audit entry for the item
                my $audit_item = $self->audit->create_item(
                    name  => $item->{name},
                    type  => $item->{type},
                    phase => $item->{phase},
                );
    
                # The action to be taken when an error is encountered
                my $on_error = (defined $item->{item}->{on_error}) ?
                    $item->{item}->{on_error} :
                    $self->config->{config}->{on_error} || 'die';
                
                my $run_ok = 1;
                # Execute the item
                try {
                    my $res = $item->{runner}();
                }
                catch {
                    # Yes, we encountered an error. Set the item status to
                    # failed
                    my $error = $_;
                    
                    $audit_item->update_message(''.$error);
                    $audit_item->update_status('failed');
                    
                    if ($on_error ne 'ignore') {
                        $error->rethrow if ref $error;
                        ETLpException->throw(error => $error);
                    }
    
                    $self->logger->error(''.$error);
                    $run_ok = 0;
                    $warning = 1;
                };
    
                $audit_item->update_status('succeeded') if $run_ok;
            }
        }
        catch {
            my $error = $_;
            $self->audit->update_message(''.$error);
            $self->audit->update_status('failed');
            ETLpException->throw(error => ''.$error);
        };
    
        # We may have a warning is we encountered an error, but the on_error
        # flag was set to ignore.
        if ($warning) {
            $self->audit->update_status('warning');
        } else {
            $self->audit->update_status('succeeded');
        }
    }    
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

