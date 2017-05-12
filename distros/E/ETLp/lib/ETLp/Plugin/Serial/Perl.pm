package ETLp::Plugin::Serial::Perl;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin::Iterative::Perl- Plugin for calling the Perl Subroutines

=head1 METHODS

=head2 type 

Registers the plugin type.

=head2 run

Executes the supplied perl code.

=head3 parameters

    * none
    
=head3 returns

    * void
    
=head1 ITEM

The item attribute hashref contains specific configuration information
for ETLp::Plugin::Serial::OS

=head2 command

The operating system command being run

=head2 timeout

This is an optional parameter that specifies when the command execution
should abort (in seconds).

=cut

class ETLp::Plugin::Serial::Perl extends ETLp::Plugin {
    use autodie;
    use UNIVERSAL::require;
    use Try::Tiny;
    
    sub type {
        return 'perl';
    }
    
    method run {
        my $item = $self->item;
        my $package  = $item->{package};
        my $sub      = $item->{sub};
        my $params   = $item->{params};
        my $interim_params;
        
        my $call = "${package}::$sub($params)";
        $self->logger->debug("Call: $call");
        
        $self->audit->item->update_message($call);
        
        try {
            $package->require;
            eval "$call" ||
                ETLpException->throw(error =>"Unable to run $call: $!");
        } catch {
            my $error = $_;
            $self->logger->error($error);
            my $error_message = $call . ' ' . $error;
            ETLpException->throw(error => $error_message);
        };
    }
    
}
