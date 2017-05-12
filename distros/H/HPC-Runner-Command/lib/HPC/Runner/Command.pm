package HPC::Runner::Command;

use MooseX::App qw(Color);

with 'HPC::Runner::Command::Utils::Plugin';
with 'HPC::Runner::Command::Utils::ManyConfigs';

option '+config_base' => (
    default       => '.hpcrunner',
);

our $VERSION = '3.1.5';

app_strict 0;

=encoding utf-8

=head1 NAME

=begin HTML

<p><img src="http://github.com/jerowe/HPC-Runner-Command/blob/master/_docs/images/rabbit.jpeg" width="500" height="250" alt="HPC::Runner::Command" /></p>

=end HTML

HPC::Runner::Command - Create composable bioinformatics hpc analyses.

=head1 SYNOPSIS

To create a new project

    hpcrunner.pl new MyNewProject

To submit jobs to a cluster

    hpcrunner.pl submit_jobs

To run jobs on an interactive queue or workstation

    hpcrunner.pl execute_job

=head1 DESCRIPTION

HPC::Runner::Command is a set of libraries for scaffolding data analysis projects,
submitting and executing jobs on an HPC cluster or workstation, and obsessively
logging results.

Please see the complete documentation at L<HPC::Runner::Command GitBooks | https://jerowe.gitbooks.io/hpc-runner-command-docs/content/>

=head1 Quick Start - Create a New Project

You can create a new project, with a sane directory structure by using

	hpcrunner.pl new MyNewProject

=head1 Quick Start - Submit Workflows

=head2 Simple Example

Our simplest example is a single job type with no dependencies - each task is independent of all other tasks.

=head3 Workflow file

	#preprocess.sh

	echo "preprocess" && sleep 10;
	echo "preprocess" && sleep 10;
	echo "preprocess" && sleep 10;

=head3 Submit to the scheduler

	hpcrunner.pl submit_jobs --infile preprocess.sh

=head3 Look at results!

	tree hpc-runner

=head2 Job Type Dependencency Declaration

Most of the time we have jobs that depend upon other jobs.

=head3 Workflow file

	#blastx.sh

	#HPC jobname=unzip
	unzip Sample1.zip
	unzip Sample2.zip
	unzip Sample3.zip

	#HPC jobname=blastx
	#HPC deps=unzip
	blastx --db env_nr --sample Sample1.fasta
	blastx --db env_nr --sample Sample2.fasta
	blastx --db env_nr --sample Sample3.fasta

=head3 Submit to the scheduler

	hpcrunner.pl submit_jobs --infile preprocess.sh

=head3 Look at results!

	tree hpc-runner

=head2 Task Dependencency Declaration

Within a job type we can declare dependencies on particular tasks.

=head3 Workflow file

	#blastx.sh

	#HPC jobname=unzip
	#TASK tags=Sample1
	unzip Sample1.zip
	#TASK tags=Sample2
	unzip Sample2.zip
	#TASK tags=Sample3
	unzip Sample3.zip

	#HPC jobname=blastx
	#HPC deps=unzip
	#TASK tags=Sample1
	blastx --db env_nr --sample Sample1.fasta
	#TASK tags=Sample2
	blastx --db env_nr --sample Sample2.fasta
	#TASK tags=Sample3
	blastx --db env_nr --sample Sample3.fasta

=head3 Submit to the scheduler

	hpcrunner.pl submit_jobs --infile preprocess.sh

=head3 Look at results!

	tree hpc-runner

=cut

=head2 Declare Scheduler Variables

Each scheduler has its own set of variables. HPC::Runner::Command has a set of
generalized variables for declaring types across templates. For more
information please see L<< Job Scheduler Comparison|https://jerowe.gitbooks.io/hpc-runner-command-docs/content/job_submission/comparison.html >>

Additionally, for workflows with a large number of tasks, please see L<< Considerations for Workflows with a Large Number of Tasks|https://jerowe.gitbooks.io/hpc-runner-command-docs/content/design_workflow.html#considerations-for-workflows-with-a-large-number-of-tasks >> for information on how to group tasks together.

=head3 Workflow file

	#blastx.sh

	#HPC jobname=unzip
	#HPC cpus_per_task=1
	#HPC partition=serial
	#HPC commands_per_node=1
	#TASK tags=Sample1
	unzip Sample1.zip
	#TASK tags=Sample2
	unzip Sample2.zip
	#TASK tags=Sample3
	unzip Sample3.zip

	#HPC jobname=blastx
	#HPC cpus_per_task=6
	#HPC deps=unzip
	#TASK tags=Sample1
	blastx --threads 6 --db env_nr --sample Sample1.fasta
	#TASK tags=Sample2
	blastx --threads 6 --db env_nr --sample Sample2.fasta
	#TASK tags=Sample3
	blastx --threads 6 --db env_nr --sample Sample3.fasta

=head3 Submit to the scheduler

	hpcrunner.pl submit_jobs --infile preprocess.sh

=head3 Look at results!

	tree hpc-runner

=cut

1;

__END__

=head1 AUTHOR

Jillian Rowe E<lt>jillian.e.rowe@gmail.comE<gt>

=head1 Previous Release

This software was previously released under L<HPC::Runner>. L<HPC::Runner::Command> is a complete rewrite of the existing library. While it is meant to have much of the same functionality, it is not backwords compatible.

=head1 Acknowledgements

As of Version 2.41:

This modules continuing development is supported by NYU Abu Dhabi in the Center for Genomics and Systems Biology. With approval from NYUAD, this information was generalized and put on bitbucket, for which the authors would like to express their gratitude.

Before Version 2.41

This module was originally developed at and for Weill Cornell Medical College in Qatar within ITS Advanced Computing Team. With approval from WCMC-Q, this information was generalized and put on github, for which the authors would like to express their gratitude.

=head1 COPYRIGHT

Copyright 2016- Jillian Rowe

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
