package ETLp::Plugin::Iterative::OracleSQLLoader;

use MooseX::Declare;

=head1 NAME

ETLp::Plugin::Iterative::OracleSQLLoader - Plugin for loading data
using ORACLE SQL*Loader

=cut

class ETLp::Plugin::Iterative::OracleSQLLoader extends ETLp::Plugin {
    use ETLp::Loader::OracleSQLLoader;
    use Try::Tiny;
    use File::Basename;
    use DBI::Const::GetInfoType;
    use File::Copy;
    
=head1 METHODS

=head2 type 

Registers the plugin type.

=head2 run

Executes the pipeline

=cut

    sub type {
        return 'sql_loader';
    }
    
    method run (Str $filename) {
        my $base_filename = basename($filename);
        my $userid;
        my $item = $self->item;
        my $app_config = $self->config->{config};
        
        my $on_error = $item->{on_error} || $app_config->{on_error} || 'die';

        my %sqlldr_retcodes = (
            0 => 'EX_SUCC',
            1 => 'EX_FAIL',
            2 => 'EX_WARN',
            3 => 'EX_FTL'
        );

        my $aud_file_process = $self->audit->item->file_process;        
        my $file_id = $aud_file_process->get_canonical_id;
        $self->logger->debug("file proc id: " . $aud_file_process->id);
        $self->logger->debug("file audit rec: $file_id");

        # The SQL*Loader userid will either be one that the
        # user has explicitly stated, or it will use the
        # default auth details specified in the environment
        # config file
        if ($item->{user_id}) {
            $userid = $item->{user_id};
        } else {
            my $db = $self->dbh->get_info($GetInfoType{SQL_SERVER_NAME});
            $userid = $self->env_conf->{user} . '/' .
                $self->env_conf->{password};
            $userid .= '@' . $db if $db;
        }

        my ($retcode, $sqlldr);
        
        $item->{specification} =~ s/%file_id%/$file_id/;

        try {
            $sqlldr = ETLp::Loader::OracleSQLLoader->new(
                userid           => $userid,
                filename         => $filename,
                controlfile      => $item->{controlfile},
                table            => $item->{table},
                mode             => $item->{mode},
                specification    => $item->{specification},
                controlfile      => $item->{controlfile},
                logfile          => $item->{logfile},
                badfile          => $item->{badfile},
                discardfile      => $item->{discardfile},
                keep_controlfile => $item->{keep_controlfile},
                keep_badfile     => $item->{keep_badfile},
                keep_logfile     => $item->{keep_logfile},
                keep_discardfile => $item->{keep_discardfile},
                parameters       => $item->{parameters},
                localize         => $item->{localize},
            );

            $retcode = $sqlldr->run;
        } catch {
            $aud_file_process->update_status('failed');
            
            if ($on_error eq 'ignore') {
                return;
            }
            
            ETLpException->throw(error => $_);
        };

        $self->logger->debug("Controlfile: " . $sqlldr->controlfile_content);
        $self->logger->debug("Command: " . join(' ', @{$sqlldr->command}));

        $aud_file_process->update_message(join(' ', @{$sqlldr->command}));

        # Compre the SQL*loader return code with our 
        if ($sqlldr_retcodes{$retcode} eq 'EX_SUCC') {
            $aud_file_process->update_status('succeeded');
        } elsif ($sqlldr_retcodes{$retcode} =~ /^(?:EX_FAIL|EX_FTL)$/)  {
            $aud_file_process->update_status('failed');
            $aud_file_process->update_message("Command: "
                  . $sqlldr->command
                  . "\nError: "
                  . $sqlldr->error);
            ETLpException->throw(error => $sqlldr->error);
        } elsif ($sqlldr_retcodes{$retcode} eq 'EX_WARN') {
            my $log_message = 'SQL*Loader returned a warning';
            $log_message .= "\n\tFile: $filename";
            $log_message .= "\n\tError: " . $sqlldr->error
              if $sqlldr->error;
            $log_message .=
              "\n\n" . join(" ", @{$sqlldr->command});

            if ($sqlldr->error) {
                $aud_file_process->update_message("Command: "
                    . join(" ", @{$sqlldr->command})
                    . "\nError: "
                    . $sqlldr->error);
            }

            if ($item->{is_warning_error}) {
                $aud_file_process->update_status('failed');
                ETLpException->throw(error => $log_message);
            } else {
                $aud_file_process->update_status('warning');
                $self->logger->warn($log_message);
            }
        }
        
        move($filename, $app_config->{archive_dir}) ||
                ETLpException->throw(error => "Unable to move $filename to "
                  . $app_config->{archive_dir} . ": $|");

        return $app_config->{archive_dir} . '/' . basename($filename);
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application