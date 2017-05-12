#!/bin/bash
#
#SBATCH --share
#SBATCH --get-user-env
#SBATCH --job-name=job_1
#SBATCH --output=/home/jillian/projects/perl/HPC-Runner-Slurm/t/example/test002/subs/2015-12-16-slurm_logs/job_1.log



#SBATCH --cpus-per-task=4







cd /home/jillian/projects/perl/HPC-Runner-Slurm
mcerunner.pl --procs 4 --infile /home/jillian/projects/perl/HPC-Runner-Slurm/t/example/test002/subs/job_1.in --outdir /home/jillian/projects/perl/HPC-Runner-Slurm/t/example/test002/subs --logname job_1
