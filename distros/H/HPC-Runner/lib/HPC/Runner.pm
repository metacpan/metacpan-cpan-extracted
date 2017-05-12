package HPC::Runner;

#use Carp::Always;
use Data::Dumper;
use IPC::Open3;
use IO::Select;
use Symbol;
use Log::Log4perl qw(:easy);
use DateTime;
use DateTime::Format::Duration;
use Cwd;
use File::Path qw(make_path);
use File::Spec;

use Moose;
use namespace::autoclean;

use Moose::Util::TypeConstraints;
#with 'MooseX::Getopt';
with 'MooseX::Getopt::Usage';
with 'MooseX::Getopt::Usage::Role::Man';
with 'MooseX::Object::Pluggable';

# For pretty man pages!
$ENV{TERM}='xterm-256color';

=head1 NAME

HPC::Runner - HPC Runner::Slurm, Runner::MCE and Runner::Threads base class

=head1 VERSION

Version 2.4.2

=cut

our $VERSION = '2.48';

=head1 SYNOPSIS

This is a base class for HPC::Runner::MCE and HPC::Runner:Threads. You should not need to call this module directly.

=head1 EXPORT

=cut

=head1 VARIABLES

=cut

=head2 infile

File of commands separated by newline. The command 'wait' indicates all previous commands should finish before starting the next one.

=cut

has 'infile' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    documentation => q{File of commands separated by newline. The command 'wait' indicates all previous commands should finish before starting the next one.},
    trigger => \&_set_infile,
);

=head2 _set_infile

Internal variable

=cut

sub _set_infile{
    my($self, $infile) = @_;

    $infile = File::Spec->rel2abs($infile);
    $self->{infile} = $infile;
}

=head2 outdir

Directory to write out files and logs.

=cut

has 'outdir' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => sub {return getcwd()."/logs" },
    documentation => q{Directory to write out files.},
    trigger => \&_set_outdir,
);

=head2 _set_outdir

Internal variable

=cut

sub _set_outdir{
    my($self, $outdir) = @_;

    make_path($outdir) if -d $outdir;
    $outdir = File::Spec->rel2abs($outdir);
    $self->{outdir} = $outdir;
}

=head2 logdir

Pattern to use to write out logs directory. Defaults to outdir/prunner_current_date_time/log1 .. log2 .. log3.

=cut

has 'logdir' => (
    is => 'rw',
    isa => 'Str',
    lazy => 1,
    required => 1,
    default => \&set_logdir,
    documentation => q{Directory where logfiles are written. Defaults to current_working_directory/prunner_current_date_time/log1 .. log2 .. log3'},
);

=head2 procs

Total number of running children allowed at any time. Defaults to 10. The command 'wait' can be used to have a variable number of children running. It is best to wrap this script in a slurm job to not overuse resources. This isn't used within this module, but passed off to mcerunner/parallelrunner.

=cut

has 'procs' => (
    is => 'rw',
    isa => 'Int',
    default => 4,
    required => 0,
    documentation => q{Total number of running jobs allowed at any time. The command 'wait' can be used to have a variable number of children running.}
);

#TODO add to Log
has 'show_processid' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    documentation => q{Show the process ID per logging message. This is useful when aggregating logs.}
);

#TODO add to Log
has 'metastr' => (
    is => 'rw',
    isa => 'Str',
    default => "",
    documentation => q{Meta str passed from HPC::Runner::Scheduler},
    required => 0,
);

=head1 Internal VARIABLES

You shouldn't be calling these directly.

=cut

has 'dt' => (
    traits  => ['NoGetopt'],
    is => 'rw',
    isa => 'DateTime',
    default => sub { return DateTime->now(time_zone => 'local'); },
    lazy => 1,
);

=head2 wait

Boolean value indicates any job dependencies

=cut

has 'wait' => (
    traits  => ['NoGetopt'],
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has 'cmd' => (
    traits  => ['String', 'NoGetopt'],
    is => 'rw',
    isa => 'Str',
    #lazy_build => 1,
    required => 0,
    #default => q{},
    handles => {
        add_cmd => 'append',
        match_cmd => 'match',
    },
    predicate => 'has_cmd',
    clearer => 'clear_cmd',
);

has 'counter' => (
    traits  => ['Counter', 'NoGetopt'],
    is      => 'rw',
    isa     => 'Num',
    required => 1,
    default => 1,
    handles => {
        inc_counter   => 'inc',
        dec_counter   => 'dec',
        reset_counter => 'reset',
    },
);

#this needs to be called in the main app
has 'log' => (
    traits  => ['NoGetopt'],
    is => 'rw',
);

has 'command_log' => (
    traits => ['NoGetopt'],
    is => 'rw',
);

has 'logfile' => (
    traits  => ['String', 'NoGetopt'],
    is => 'rw',
    default => \&set_logfile,
    handles => {
        append_logfile => 'append',
        prepend_logfile => 'prepend',
        clear_logfile => 'clear',
    }
);

has 'logname' => (
    isa => 'Str',
    is => 'rw',
    default => 'hpcrunner_logs',
);

=head2 process_table

We also want to write all cmds and exit codes to a table

=cut

has 'process_table' => (
    isa => 'Str',
    is => 'rw',

    handles => {
        add_process_table => 'append',
        prepend_process_table => 'prepend',
        clear_process_table => 'clear',
    },
    default => sub {
        my $self = shift;
        return $self->logdir."/process_table.md"
    },
    lazy => 1,
);

=head2 plugins

Load plugins

=cut

has 'plugins' => (
    is => 'rw',
    isa => 'ArrayRef|Str',
    documentation => 'Add Plugins to your run',
);

=head2 jobref

Array of arrays details slurm/process/scheduler job id. Index -1 is the most recent job submissisions, and there will be an index -2 if there are any job dependencies

=cut

has 'jobref' => (
    traits  => ['NoGetopt'],
    is => 'rw',
    isa => 'ArrayRef',
    default => sub { [ [] ]  },
);

=head1 Subroutines

=cut

sub BUILD {
    my $self = shift;

    $self->process_plugins;
}

=head2 set_logdir

Set the log directory

=cut

sub set_logdir{
    my $self = shift;

    my $logdir;
    $logdir = $self->outdir."/".$self->set_logfile."-".$self->logname;

    $DB::single=2;
    $logdir =~ s/\.log$//;

    make_path($logdir) if ! -d $logdir;
    return $logdir;
}

=head2 set_logfile

Set logfile

=cut

sub set_logfile{
    my $self = shift;

    my $tt = $self->dt->ymd();
    return "$tt";
}

=head2 init_log

Initialize Log4perl log

=cut

sub init_log {
    my $self = shift;

    Log::Log4perl->easy_init(
        {
            level    => $TRACE,
            utf8     => 1,
            mode => 'append',
            file => ">>".$self->logdir."/".$self->logfile,
            layout   => '%d: %p %m%n '
        }
    );

    my $log = get_logger();
    return $log;
}

=head2 process_plugins

Split and process plugins

=cut

sub process_plugins{
    my $self = shift;

    return unless $self->plugins;

    if(ref($self->plugins)){
        my @plugins = @{$self->plugins};
        foreach my $plugin (@plugins){
            if($plugin =~ m/,/){
                my @tmp = split(',', $plugin);
                foreach my $tmp (@tmp){
                    push(@plugins, $tmp);
                }
            }
        }
        $self->load_plugins(@plugins);
    }
    else{
        $self->load_plugin($self->plugins);
    }
}

=head2 run_command_threads

Start the thread, run the command, and finish the thread

=cut

sub run_command_threads{
    my $self = shift;

    my $pid = $self->threads->start($self->cmd) and return;
    push(@{$self->jobref->[-1]}, $pid);

    my $exitcode = $self->_log_commands($pid);

    $self->threads->finish($exitcode); # pass an exit code to finish

    return;
}

#=head2 run_command_mce

#MCE knows which subcommand to use from Runner/MCE - object mce

#=cut

#sub run_command_mce{
    #my $self = shift;

    #my $pid = $$;

    #$DB::single=2;

    ##Mce doesn't take exitcode to end
    #push(@{$self->jobref->[-1]}, $pid);
    #$self->_log_commands($pid);

    #return;
#}

=head2 _log_commands

Log the commands run them. Cat stdout/err with IO::Select so we hopefully don't break things.

This example was just about 100% from the following perlmonks discussions.

http://www.perlmonks.org/?node_id=151886

You can use the script at the top to test the runner. Just download it, make it executable, and put it in the infile as

perl command.pl 1
perl command.pl 2
#so on and so forth

=cut

sub _log_commands {
    my($self, $pid) = @_;

    my $dt1 = $self->dt;

    $DB::single=2;

    my($cmdpid, $exitcode) = $self->log_job;

    $self->log_cmd_messages("info", "Finishing job ".$self->counter." with ExitCode $exitcode", $cmdpid);

    my $dt2 = DateTime->now();
    my $duration = $dt2 - $dt1;
    my $format = DateTime::Format::Duration->new(
        pattern => '%Y years, %m months, %e days, %H hours, %M minutes, %S seconds'
    );

    $self->log_cmd_messages("info", "Total execution time ".$format->format_duration($duration), $cmdpid);

    $self->log_table($cmdpid, $exitcode, $format->format_duration($duration));
    return $exitcode;
}

sub name_log {
    my $self = shift;
    my $pid = shift;

    $self->logfile($self->set_logfile);
    my $string = sprintf ("%03d", $self->counter);
    $self->append_logfile("-CMD_".$string.".log");
}

##TODO extend this in HPC-Runner-Web for ENV tags
sub log_table {
    my $self = shift;
    my $cmdpid = shift;
    my $exitcode = shift;
    my $duration = shift;

    open(my $pidtablefh, ">>".$self->process_table) or die print "Couldn't open process file $!\n";

    print $pidtablefh "### $self->{cmd}\n";
    print $pidtablefh <<EOF;
|$cmdpid|$exitcode|$duration|

EOF
}

#This should be run_job instead and in main app
sub log_job {
    my $self = shift;

    #Start running job
    my ($infh,$outfh,$errfh);
    $errfh = gensym(); # if you uncomment this line, $errfh will
    my $cmdpid;
    eval{
        $cmdpid = open3($infh, $outfh, $errfh, $self->cmd);
    };
    die $@ if $@;
    if(! $cmdpid) {
        print "There is no $cmdpid please contact your administrator with the full command given\n";
        die;
    }
    $infh->autoflush();

    $self->name_log($cmdpid);
    $self->command_log($self->init_log);

    $DB::single=2;

    $self->log_cmd_messages("info", "Starting Job: ".$self->counter." \nCmd is ".$self->cmd, $cmdpid);

    $DB::single=2;

    my $sel = new IO::Select; # create a select object
    $sel->add($outfh,$errfh); # and add the fhs

    while(my @ready = $sel->can_read) {
        foreach my $fh (@ready) { # loop through them
            my $line;
            # read up to 4096 bytes from this fh.
            my $len = sysread $fh, $line, 4096;
            if(not defined $len){
                # There was an error reading
                $self->log_cmd_messages("fatal", "Error from child: $!" , $cmdpid)
            } elsif ($len == 0){
                # Finished reading from this FH because we read
                # 0 bytes.  Remove this handle from $sel.
                $sel->remove($fh);
                next;
            } else { # we read data alright
                if($fh == $outfh) {
                    $self->log_cmd_messages("info", $line, $cmdpid)
                } elsif($fh == $errfh) {
                    $self->log_cmd_messages("error", $line, $cmdpid)
                } else {
                    $self->log_cmd_messages('fatal', "Shouldn't be here!\n");
                }
            }
        }
    }

    waitpid($cmdpid, 1);
    my $exitcode = $?;

    return($cmdpid, $exitcode);
}

sub log_cmd_messages{
    my($self, $level, $message, $cmdpid)  = @_;

    if($self->show_processid && $cmdpid){
        $self->command_log->$level("PID: $cmdpid\t$message");
    }
    else{
        $self->command_log->$level($message);
    }
}

sub log_main_messages{
    my($self, $level, $message)  = @_;

    return unless $message;
    $level = 'debug' unless $level;
    $self->log->$level($message);
}

__PACKAGE__->meta->make_immutable;

1;

=head1 AUTHOR

Jillian Rowe, C<< <jillian.e.rowe at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-runner-init at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=HPC-Runner>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc HPC::Runner

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=HPC-Runner>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/HPC-Runner>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/HPC-Runner>

=item * Search CPAN

L<http://search.cpan.org/dist/HPC-Runner/>

=back

=head1 Acknowledgements

This module was originally developed at and for Weill Cornell Medical
College in Qatar within ITS Advanced Computing Team. With approval from
WCMC-Q, this information was generalized and put on github, for which
the authors would like to express their gratitude.

=head1 LICENSE AND COPYRIGHT

Copyright 2014 Weill Cornell Medical College.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

#End of Runner::Init
