## Changes from 2.0

### New (and hopefully clearer!) Syntax

Instead of calling various shell scripts (slurmrunner.pl for slurm submission, pbsrunner.pl for pbs submission, mcerunner.pl for job execution) now call a single script with commands.

```
hpcrunner.pl new ProjectName
hpcrunner.pl submit_jobs --infile submission_file
hpcrunner.pl execute_job --infile job_file
```


### Nested workflow submission

Previously workflows could only have linear dependencies, with each job depending upon the previous. Now jobs can depend upon any job in the workflow.

### Git versioning of job runs

If chosen each run can be a git version. You can use all the usual git tools to track differences between job submissions, archive certain submissions, create branches of analyses, etc.
