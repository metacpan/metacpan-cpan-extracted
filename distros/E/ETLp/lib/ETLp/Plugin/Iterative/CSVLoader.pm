package ETLp::Plugin::Iterative::CSVLoader;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin::Iterative::CSVLoader - Plugin to load delimited files


=head1 METHODS

=head2 type 

Registers the plugin type.

=head2 run

Executes the pipeline

=head1 ITEM

The item attribute hashref contains specific configuration information

=head2 localize

Whether to localize eol markers for the file being loaded

=head1 CONFIGURATION SETTINGS

The "config" section within the configuration file must contain the
following settings

=head2 controlfile_dir

Where the contrfolfile is located

=head2 controlfile

The name of the controlfile

=cut

class ETLp::Plugin::Iterative::CSVLoader extends ETLp::Plugin {
    use ETLp::File::Config;
    use File::Copy;
    use Try::Tiny;
    use File::Basename;
    use ETLp::Loader::CSV;

    sub type {
        return 'csv_loader';
    }

    method run(Str $filename) {
        my $app_config = $self->config->{config};
        my $item     = $self->item;

        my $rule_conf = ETLp::File::Config->new(
            directory  => $app_config->{controlfile_dir},
            definition => $app_config->{controlfile}
        );

        # Audit the file
        my $aud_file_process =  $self->audit->item->file_process;
        
        my $file_id = $aud_file_process->get_canonical_id;

        unless (-s $filename == 0) {
            # The number of rows to skip (allows for headers in
            # the files)
            my $skip = $item->{skip} || '0';

            $aud_file_process->update_message('loading the file');
            
            my $csv_options = $item->{csv_options};

            my $loader = ETLp::Loader::CSV->new(
                table              => $app_config->{table_name},
                columns            => $rule_conf->fields,
                rules              => $rule_conf->rules,
                logger             => $self->logger,
                file_id            => $file_id,
                skip               => $skip,
                ignore_field_count => $item->{ignore_field_count},
                csv_options        => $csv_options || {},
                localize => $item->{localize} || $app_config->{localize} || 0,
            );

            unless ($loader->load($filename)) {
                $aud_file_process->update_status('failed');
                $aud_file_process->update_message($loader->error);
                ETLpException->throw(error => $loader->error);
            }

            $aud_file_process->record_count($loader->rows_loaded);
        } else {
            $aud_file_process->record_count(0);
        }
        
        $aud_file_process->update_status('succeeded');

        move($filename, $app_config->{archive_dir}) ||
            ETLpException->throw( error => "Unable to move $filename to "
              . $app_config->{archive_dir} . ": "
              . $!);
        
        return $app_config->{archive_dir} . '/' . basename($filename);
    }

}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application
