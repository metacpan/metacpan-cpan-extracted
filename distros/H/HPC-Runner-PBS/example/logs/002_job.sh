#!/bin/bash
#
#PBS -N 002_job

#PBS -l nodes=1:ppn=4

#PBS -l walltime=04:00:00

#PBS -j oe
#PBS -o localhost:/home/jillian/projects/perl/HPC-Runner-PBS/example/logs/2016-02-21-pbs_logs/002_job.log

#PBS -l mem=24GB





    
module load module1
    


cd /home/jillian/projects/perl/HPC-Runner-PBS/example
mcerunner.pl --procs 4 --infile /home/jillian/projects/perl/HPC-Runner-PBS/example/logs/002_job.in --outdir /home/jillian/projects/perl/HPC-Runner-PBS/example/logs --logname 002_job
