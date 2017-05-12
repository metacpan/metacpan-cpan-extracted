#!/bin/bash
#
#PBS -N 001_job

#PBS -l nodes=1:ppn=4

#PBS -l walltime=04:00:00

#PBS -j oe
#PBS -o localhost:/home/jillian/projects/perl/HPC-Runner-PBS/example/logs/2016-02-21-pbs_logs/001_job.log





    


cd /home/jillian/projects/perl/HPC-Runner-PBS/example
mcerunner.pl --procs 4 --infile /home/jillian/projects/perl/HPC-Runner-PBS/example/logs/001_job.in --outdir /home/jillian/projects/perl/HPC-Runner-PBS/example/logs --logname 001_job
