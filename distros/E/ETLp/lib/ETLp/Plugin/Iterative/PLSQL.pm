package ETLp::Plugin::Iterative::PLSQL;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin::Iterative::PLSQL - Plugin for calling Oracle procedures

=head1 METHODS

=head2 type 

Registers the plugin type.

=head2 run

Executes the pipeline

=cut

class ETLp::Plugin::Iterative::PLSQL extends ETLp::Plugin {
    
    use DBI;
    use Data::Dumper;
    use Try::Tiny;

    method _parse_params (HashRef $config, ArrayRef $params, Str $filename) {
        my $parsed_params;
        
        return $parsed_params;
    }

    sub type {
        return 'plsql';
    }
    
    method run (Str $filename?) {
        my $config = $self->config->{config};
        my $item = $self->item;
        my $params = $item->{parameters};
        my $sql = "BEGIN\n" . $item->{call};
        my $message;
        
        $params = [$params]
            unless (ref($params) eq 'ARRAY' || !defined($item->{parameters}));
        my $aud_file_process =  $self->audit->item->file_process;
            
        $self->logger->debug(Dumper($params));
        
        # If we have any parameters then add them to the construction list
        if ($params) {
            $sql .= '(';
            my $param_counter = 0;
            foreach my $param (@$params) {
                unless($param->{name} && $param->{value}) {
                    ETLpException->throw(
                        error => 'parameter requires a name and a value'
                    );
                }
                
                if ($param_counter++ > 0) {
                    $sql .= ",\n\t";
                } else {
                    $sql .= "\n\t"
                }
                $sql .= $param->{name}.' => :'.$param->{name};
            }
            $sql .= ");\nEND;";
        } else {
            $sql .= ";\nEND;";
        }
        
        $self->logger->debug("pl/sql block:\n$sql");
        
        my $sth = $self->dbh->prepare($sql);
        
        if($params) {
            foreach my $param (@$params) {
                if ($param->{value} eq '%message%') {
                    $sth->bind_param_inout(':'.$param->{name}, \$message,
                        4000);
                } else {
                    $sth->bind_param(':'. $param->{name}, $param->{value});
                }
            }
        }        
    
        $sth->execute || ETLpException->throw(error => DBI::errstr);
        
        if ($message) {
            $self->audit->item->update_message($message);
        };
        
        return $filename;
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application