HPC-Runner-Command efficiently chunks your HPC workflow into batches of HPC scheduler (PBS, SLURM) jobs. The submission script, supplied by --infile, is split based on the number of commands_per_node.

```
#HPC commands_per_node=2
job_001
job_002
...
job_009
job_010
```

Would be split into 5 HPC job submissions, with 2 commands (job_001-job_002, job003-job004 ... job_009-job010) per job.
