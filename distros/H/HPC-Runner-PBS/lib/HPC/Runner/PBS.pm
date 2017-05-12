package HPC::Runner::PBS;

use File::Path qw(make_path remove_tree);
use File::Temp qw/ tempfile tempdir /;
use IO::File;
use IO::Select;
use Cwd;
use IPC::Open3;
use Symbol;
use Template;
use Log::Log4perl qw(:easy);
use DateTime;
use Data::Dumper;
use List::Util qw/shuffle/;
# use IPC::Cmd qw/can_run/;

use Moose;
use namespace::autoclean;

extends 'HPC::Runner::Scheduler';
#extends 'HPC::Runner::Slurm';
with 'MooseX::SimpleConfig';

our $VERSION = '0.12';

# For pretty man pages!
$ENV{TERM}='xterm-256color';

=encoding utf-8

=head1 NAME

HPC::Runner::PBS - Submit jobs to a PBS job scheduler.

=head1 DESCRIPTION

HPC::Runner::PBS is a wrapper around qsub and can be used to submit arbirtary bash commands to PBS.

It has two levels of management. The first is the main qsub command, and the second is the actual job, which runs commands in parallel, controlled by HPC::Runner::Threads or HPC::Runner::MCE.

It supports job dependencies. Put in the command 'wait' to tell PBS that some job or jobs depend on some other jobs completion. Put in the command 'newnode' to tell HPC::Runner::PBS to submit the job to a new node.

The only necessary option is the --infile, and --queue if you wish to run on a queue besides s48.

The bulk of this code is extended from HPC::Runner::Slurm.

=head2 queue

Same as the partition in HPC::Runner::Slurm

=cut

has 'queue' => (
    is => 'rw',
    isa => 'Str|Undef',
    required => 0,
    documentation => q{PBS queue for job submission. Defaults is none, pbs decides.},
    predicate => 'has_queue',
    clearer => 'clear_queue',
);

has '+partition' =>(
    isa => 'Str | Undef',
    #alias => 'queue',
    #predicate => 'has_queue',
    #clearer => 'clear_queue',
);

=head2 walltime

Define PBS walltime

=cut

has 'walltime' => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    default => '04:00:00',
    predicate => 'has_walltime',
    clearer => 'clear_walltime,'
);

=head2 mem

=cut

has 'mem' => (
    is => 'rw',
    isa => 'Str|Undef',
    predicate => 'has_mem',
    clearer => 'clear_mem',
    required => 0,
    documentation => q{Supply a memory limit},
);

=head2 template_file

actual template file

One is generated here for you, but you can always supply your own with --template_file /path/to/template

=cut

has '+template_file' => (
    is => 'rw',
    isa => 'Str',
    default => sub {
        my $self = shift;

        my($fh, $filename) = tempfile();

        my $tt =<<EOF;
#!/bin/bash
#
#PBS -N [% JOBNAME %]
[% IF self.has_queue %]
#PBS -q [% self.queue %]
[% END %]
#PBS -l nodes=[% self.nodes_count %]:ppn=[% CPU %]
[% IF self.has_walltime %]
#PBS -l walltime=[% self.walltime %]
[% END %]
#PBS -j oe
#PBS -o localhost:[% OUT %]
[% IF self.has_mem %]
#PBS -l mem=[% self.mem %]
[% END %]

[% IF AFTEROK %]
#PBS -W depend=afterok:[% AFTEROK %]
[% END %]

[% IF MODULE %]
    [% FOR d = MODULE %]
module load [% d %]
    [% END %]
[% END %]

[% COMMAND %]
EOF

        print $fh $tt;
        $DB::single=2;
        return $filename;
    },
);

=head1 SUBROUTINES/METHODS

=cut

=head2 run()

First sub called
Calling system module load * does not work within a screen session!

=cut

sub BUILD {
    my $self = shift;
    $self->logname('pbs_logs');
    $self->log($self->init_log);
}

sub get_nodes {
    my($self) = @_;

    #$self->partition($self->queue) if $self->partition eq "";

    $DB::single=2;

    $self->nodelist([]);

    $DB::single=2;
}

=head2 submit_slurm()

Submit jobs to PBS using qsub

Uses almost the same logic as submit_slurm, so we'll keep that.

This subroutine was just about 100% from the following perlmonks discussions. All that I did was add in some logging.

http://www.perlmonks.org/?node_id=151886
You can use the script at the top to test the runner. Just download it, make it executable, and put it in the infile as

perl command.pl 1
perl command.pl 2
#so on and so forth

=cut

sub submit_slurm{
    my $self = shift;

    my ($infh,$outfh,$errfh);
    $errfh = gensym(); # if you uncomment this line, $errfh will
    # never be initialized for you and you
    # will get a warning in the next print
    # line.
    my $cmdpid;
    eval{
        $cmdpid = open3($infh, $outfh, $errfh, "qsub ".$self->slurmfile);
    };
    die $@ if $@;

    my $sel = new IO::Select; # create a select object
    $sel->add($outfh,$errfh); # and add the fhs

    my($stdout, $stderr, $jobid);

    while(my @ready = $sel->can_read) {
        foreach my $fh (@ready) { # loop through them
            my $line;
            # read up to 4096 bytes from this fh.
            my $len = sysread $fh, $line, 4096;
            if(not defined $len){
                # There was an error reading
                #$self->log->fatal("Error from child: $!");
                $self->log_main_messages('fatal', "Error from child: $!");
            } elsif ($len == 0){
                # Finished reading from this FH because we read
                # 0 bytes.  Remove this handle from $sel.
                $sel->remove($fh);
                next;
            } else { # we read data alright
                if($fh == $outfh) {
                    $stdout .= $line;
                    #$self->log->info($line);
                    $self->log_main_messages('debug', $line);
                } elsif($fh == $errfh) {
                    $stderr .= $line;
                    #$self->log->error($line);
                    $self->log_main_messages('error', "There was an error!\n".$line);
                } else {
                    #$self->log->fatal("Shouldn't be here!\n");
                    $self->log_main_messages('fatal', "We shouldn't be here, something has gone wrong\n");
                }
            }
        }
    }

    waitpid($cmdpid, 1);
    my $exitcode = $?;

    #($jobid) = $stdout =~ m/(\w.*)$/ if $stdout;
    ($jobid) = $stdout;
    chomp($jobid);

    if(!$jobid){
        print "No job was submitted! Please check your things!\nFull error is:\t$stderr\n$stdout\nEnd Job error";
        print "Submit scripts will be written, but will not be submitted to the queue. Please look at your files in ".$self->outdir." for more information\n";
        $self->submit_to_slurm(0);
    }
    else{
        push(@{$self->jobref->[-1]}, $jobid);
        print "Submitting job ".$self->slurmfile."\n\tWith PBS jobid $jobid\n";
    }
    #Fix for jobs not showing up...
    sleep(5);
}


__PACKAGE__->meta->make_immutable;

1;

__END__


=head1 SYNOPSIS

  use HPC::Runner::PBS;

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 Acknowledgements

This module was originally developed at and for NYU Abu Dhabi in the Center for Genomics and Systems Biology.
With approval from NYUAD, this information was generalized and put on github, for which
the authors would like to express their gratitude.

=head1 COPYRIGHT

Copyright 2015- Jillian Rowe

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
