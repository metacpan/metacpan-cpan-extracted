package ETLp::Utility::Command;

use MooseX::Declare;

class ETLp::Utility::Command {
    use Data::Dumper;
    use IPC::Cmd;
    use Exception::Class ('CommandError');
    
    has 'errstr'   => (is => 'rw', isa => 'Str', required => 0, default => '');
    has 'time_out' => (is => 'rw', isa => 'Int', required => 0, default => 0);


=head1 NAME

ETLp::Utility::Command - Runs Operating System Commands

=head1 SYNOPSIS

    use FindBin qw($Bin);
    use ETLp::Utility::Command;
    
    my $os = ETLp::Utility::Command->new();
    
    my ($output, $retcode) = $os->run('ls -l');
    
    if ($retcode) {
        printf("Error %s\n", $os->errstr);
        printf("Outout %s\n", $output);
    }

=head1 METHODS

=head2 new

Create a new ETLp::Utility::Command object.

Parameters

    * time_out. optional. How long the command should run before aborting
    
=head2 run

Executes the supplied comand

=head3 Parameters

    * An Operating System command (as a string);
    
=head3 Returns

    * In a scalar context
        o The command's return code
        
    * In an array context
        o The output of the command
        o The command's return code
        
=head2 errstr

    Returns any error from the last run command
    
Paramaters

    * None
    
Returns

    * An error message (if there is one)
    
=cut

    method run (Str $command) {
        
        $self->errstr('');
    
        my ($success, $error_code, $full_buf, $stdout_buf, $stderr_buf) =
            IPC::Cmd::run(
                command => $command,
                timeout => $self->time_out
            );
    
        if ($error_code && $error_code =~ / exited with value (\d+)/) {
            $error_code = $1;
            if ($^O eq "MSWin32") {
                $error_code = $error_code >> 8;
            }
        }
            
        unless ($success) {
            $self->errstr(join("", @$stderr_buf));
        }
    
        if (wantarray) {
            return (join("", @$stdout_buf), $error_code);
        } else {
            return $error_code;
        }
    }
}

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Redbone Systems Ltd

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

The terms are in the LICENSE file that accompanies this application

1;


