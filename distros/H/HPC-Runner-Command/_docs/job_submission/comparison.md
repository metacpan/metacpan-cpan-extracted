Side by side comparison of submission parameters by scheduler type

| Variable Name    | HPC Runner Variable                               | Torque/PBS                                    | SLURM                                  |
| --               | --                                                | --                                            | --                                     |
| Job Name         | #HPC jobname=$JOBNAME                             | #PBS -N $JOBNAME                              | #SBATCH --job-name=$JOBNAME            |
| Job Dependencies | #HPC deps=$JOBNAME                                | #PBS -W depend=afterok=$JOBID                 | #SBATCH --dependency=afterok=$JOBID    |
| CPUS             | #HPC cpus_per_task=$CPUS_PER_TASK                 | #PBS -l nodes=$NODES_COUNT:ppn=$CPUS_PER_TASK | #SBATCH --cpus-per-task=$CPUS_PER_TASK |
| Queue/Partition  | #HPC partition=$PARTTION or #HPC queue=$PARTITION | #PBS -q queue=$PARTITION                      | #SBATCH --partition=$PARTITION         |
| ntasks           | #HPC ntasks=$NTASKS                               | NA                                            | #SBATCH --ntasks=$NTASKS               |
| Number of Nodes  | #HPC nodes_count=$NODES                           | #PBS -l nodes=$NODES_COUNT:ppn=$CPUS_PER_TASK | #SBATCH --nodes=$NODES_COUNT           |
| Walltime         | #HPC walltime=$WALLTIME                           | #PBS --walltime=$WALLTIME                     | #SBATCH --time=$WALLTIME               |

### Resources

http://www.sdsc.edu/~hocks/FG/PBS.slurm.html

http://slurm.schedmd.com/sbatch.html - Simple Linux Utility for Resource Management

https://wiki.hpcc.msu.edu/display/hpccdocs/Advanced+Scripting+Using+PBS+Environment+Variables Advanced Scripting Using PBS Environment Variables - HPCC Documentation and User Manual - HPCC Wiki
