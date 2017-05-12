#!/bin/bash
#
#SBATCH --share
#SBATCH --get-user-env
#SBATCH --job-name=job_1
#SBATCH --output=/home/jillian/projects/perl/HPC-Runner-Slurm/t/example/test001/subs/2015-12-16-slurm_logs/job_1.log



#SBATCH --cpus-per-task=4







cd /home/jillian/projects/perl/HPC-Runner-Slurm
mcerunner.pl --procs 4 --infile /home/jillian/projects/perl/HPC-Runner-Slurm/t/example/test001/subs/job_1.in --outdir /home/jillian/projects/perl/HPC-Runner-Slurm/t/example/test001/subs --logname job_1 --metastr '{"batch_count":"1/2","commands":8,"jobname":"job","total_processes":"10","job_batches":"1/2","total_batches":"2","batch":"1","command_count":"1-8"}'
