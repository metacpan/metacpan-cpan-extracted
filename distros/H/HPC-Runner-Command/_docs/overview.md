# Overview

1. Chunk Workflow 
2. Submit jobs to scheduler 
3. Execute jobs

HPC-Runner-Command uses a predefined set of parameters to chunk your commandsV
into HPC scheduler (PBS, SLURM) jobs. This chunking is done based on the number
the job type (qc, alignment, postprocessing), the job dependencies (alignment
should not run until qc has completed), and the number of tasks (if we have a
node with 16 cpus, we should run 16 single threaded processes).  Each of these
jobs is submitted to the the scheduler using that scheduler's standard
template. Each job is then executed, with one or more processes running in
parallel based on availability of resources.

	hpcrunner.pl submit_jobs --infile my_submission_script.sh

Chunks and submits your jobs.

	hpcrunner.pl execute_jobs --infile 001_batch_my_submission_script.sh --procs N

Executes your job on a given node with N processes running in parallel.
