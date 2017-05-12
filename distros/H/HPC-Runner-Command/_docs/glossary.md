# Glossary

The HPC-Runner-Command libraries use certain naming conventions.

### Submission

A submission, in HPC-Runner-Command terms, is the single input given as --infile

```
hpcrunner.pl submit_jobs --infile resequencing.sh
```

### Job Types

A single HPC-Runner-Command submission is comprised of one or more jobtypes, specified as

```
#HPC jobname=gzip
```

### Job Batches

Job types are batched into one or more jobs based on the total number of jobs
and the commands_per_node. If using job arrays, which is the default, there is also
a max array size.

If we have 100 tasks in a submission, with a single jobtype of gzip, and a max
array size of 50, we would submit 2 job arrays of length 50, 001_gzip and
002_gzip.

### Jobs

Jobs are the actual jobs submitted to the cluster. Each 'sbatch' call is a single job.

### Tasks

Job and job batches are made up of one or more tasks.

```
gzip file
```

is a task.

```
 blastx --help
```

is another task.


### Concurrent/Parallel tasks

This is defined as 

```
#HPC procs=X
```

With x as the number of tasks we can run at any given time. It can be thought
of as the amount of multitasking we are able to do.

If you are familiar with gnuparallel, it is very similar to

```
parallel --jobs X :::: infile
```
