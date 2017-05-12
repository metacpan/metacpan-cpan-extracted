package ETLp::Plugin::Iterative::Validate;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin::Iterative::Validate - Plugin for validating data

=cut

class ETLp::Plugin::Iterative::Validate extends ETLp::Plugin {
    use Try::Tiny;
    use ETLp::File::Validate;
    use File::Basename;
    use Mail::Sendmail;
    use Data::Dumper;
    
=head1 METHODS

=head2 type 

Registers the plugin type.

=head2 run

Executes the pipeline

=cut
    sub type {
        return 'validate';
    }
    
    method run (Str $filename) {
        my $item = $self->item;
        my $app_config = $self->config->{config};
        my $aud_file_process = $self->audit->item->file_process;

        $self->logger->debug("file proc id: " . $aud_file_process->id);

        my $skip = $item->{skip} || '0';
        my $on_error = $item->{on_error} || $app_config->{on_error} || 'die';
        
        $aud_file_process->update_message('validating file');
    
        my $validator;
    
        unless (-s $filename == 0) {
            my $localize = $item->{localize} || $app_config->{localize} || 0;
            
            $self->logger->debug("CSV Options: " . Dumper($item->{csv_options}));
            
            $validator = ETLp::File::Validate->new(
                file_config_directory => $app_config->{controlfile_dir},
                file_definition       => $app_config->{controlfile},
                type                  => $item->{file_type},
                skip                  => $skip,
                ignore_field_count    => $item->{ignore_field_count},
                localize              => $localize,
                csv_options           => $item->{csv_options} || {}
            );

            unless ($validator->validate($filename)) {
                $self->logger->debug(Dumper($validator->get_errors));
                my @errors;

                foreach my $error (@{$validator->get_errors})  {
                    push @errors,
                        "Line number: "    . $error->{line_number}
                      . "\n\tfield name:"  . $error->{field_name}
                      . "\n\tfield value:" . $error->{field_value}
                      . "\n\terror:"       . $error->{message};
                }

                if ($item->{email_alerts}) {
                    my %email = (
                        To      => $item->{email_alerts},
                        From    => $self->env_config->{email_sender},
                        Subject => "Error Validating " . basename($filename),
                        Message => join("\n", @errors)
                    );

                    sendmail(%email) || $self->logger->error(
                        "Problem sending validation error to "
                          . $item->{email_alerts} . "\n"
                          . $Mail::Sendmail::error
                    );

                    $self->logger->debug("Validation email sent");
                }

                my $error = basename($filename) .
                        " failed validation:\n" . join("\n", @errors);
                        
                $aud_file_process->update_status('failed');
                $aud_file_process->update_message($error);

                ETLpException->throw(error => $error);
            }
                   
            $aud_file_process->update_status('succeeded');
            return $filename;
        }
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application