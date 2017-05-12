# Overview

When designing a workflow you should keep several key components in mind.

1. Job computation requirements should be explicitly and verbosely stated.
2. Jobs should be grouped by their order in an analysis and computational requirements.
3. Tasks should be broken down to their smallest components.
4. Job dependencies must be verbosely stated.

The reasoning behind this is that each job type will have similar computation requirements.

```
#HPC jobname=qc
#HPC procs=1
#HPC commands_per_node=1
#HPC ntasks=1
#HPC cpus_per_task=2

qc --threads 2 Sample1
qc --threads 2 Sample2
qc --threads 2 Sample3
..
qc  --threads 2 Sample16

#HPC jobname=gzip
#HPC procs=1
#HPC commands_per_node=1
#HPC ntasks=1
#HPC cpus_per_task=1

gzip Sample1_results
gzip Sample2_results
..
gzip Sample16_results
```

Let's break this down job by job.

## Jobname qc - Submission

Each QC is a multithreaded process. #HPC procs=N is the number of tasks that
can be run in parallel. Our qc tasks are each running in 2 threads, so #HPC
procs= $commands_per_node/$procs = 8. In this way we make the most efficient
use of the cluster resources.

## Jobname gzip - Subission

Gzip runs in a single thread, and therefore we have cpus_per_task=1

## Workflow Submission

```
hpcrunner.pl submit_jobs --infile my_submission
```

Would produce 001_qc.sh, 001_qc.in, 002_gzip.sh, and 002_gzip.in

## Jobname qc - Execution

Once submitted to the scheduler the QC job would be executed as

```
hpcrunner.pl execute_job --infile 001_qc.in --procs 1
```

Telling our job runner to execute 1 task (qc --threads 2 Sample_N) per batch,
with the amount of concurrent tasks being handled by the resources of the
computational environment.

## Jobname gzip - Execution

While the gzip job would be executed as

```
hpcrunner.pl execute_job --infile 001_gzip.in --procs 1
```

Telling our job runner to execute 16 jobs within our infile in parallel at a
time.

More information on HPC-Runner-Command parameters is available at: SOMELINKE


## Considerations for workflows with a large number of tasks

Above, ntasks, commands_per_node and procs are always 1.

When submitting a large number of tasks, 1000+ (or different depending on the limits set by the scheduler) chances are we want to batch these differently.

For instance, lets say we are submitting thousands of blast jobs, with each task taking 1 hour to complete.

Our slurm configuration would look like this

```
#HPC commands_per_node=10
#HPC walltime=05:00:00
#HPC procs=2
#HPC ntasks=2
#HPC cpus_per_task=6
blastx --threads 6 --db env_nr --infile Sample1.fasta
blastx --threads 6 --db env_nr --infile Sample2.fasta
blastx --threads 6 --db env_nr --infile Sample3.fasta
blastx --threads 6 --db env_nr --infile Sample4.fasta
blastx --threads 6 --db env_nr --infile Sample5.fasta
...
blastx --threads 6 --db env_nr --infile Sample1000.fasta
```

And our PBS configuration would look like this

```
#HPC commands_per_node=10
#HPC walltime=05:00:00
#HPC procs=2
#HPC cpus_per_task=12
blastx --threads 6 --db env_nr --infile Sample1.fasta
blastx --threads 6 --db env_nr --infile Sample2.fasta
blastx --threads 6 --db env_nr --infile Sample3.fasta
blastx --threads 6 --db env_nr --infile Sample4.fasta
blastx --threads 6 --db env_nr --infile Sample5.fasta
...
blastx --threads 6 --db env_nr --infile Sample1000.fasta
```

With both SLURM and PBS we are submitting 10 tasks to a node and running 2
tasks concurrently with 6 threads per task. Slurm handles this a bit
differently than PBS. With SLURM you give the number of concurrent tasks,
ntasks, in this case 2, and the number of cpus in a given task, in this case 6.
With PBS you leave out the ntasks, and just have the cpus_per_task as the
number of concurrent tasks * the number of threads per task. This is only a
consideration when grouping tasks.
