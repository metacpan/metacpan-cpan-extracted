# Quick Start

<!-- toc -->

# Create a New Project

You can create a new project, with a sane directory structure by using

        hpcrunner.pl new MyNewProject

# Submit Workflows

## Simple Example

Our simplest example is a single job type with no dependencies - each task is independent of all other tasks.

### Workflow file

        #preprocess.sh
        
        echo "preprocess" && sleep 10;
        echo "preprocess" && sleep 10;
        echo "preprocess" && sleep 10;

### Submit to the scheduler

        hpcrunner.pl submit_jobs --infile preprocess.sh

### Look at results!

        tree hpc-runner

## Job Type Dependencency Declaration 

Most of the time we have jobs that depend upon other jobs.

### Workflow file

        #blastx.sh
        
        #HPC jobname=unzip
        unzip Sample1.zip
        unzip Sample2.zip
        unzip Sample3.zip

        #HPC jobname=blastx
        #HPC deps=unzip
        blastx --db env_nr --sample Sample1.fasta
        blastx --db env_nr --sample Sample2.fasta
        blastx --db env_nr --sample Sample3.fasta

### Submit to the scheduler

        hpcrunner.pl submit_jobs --infile preprocess.sh

### Look at results!

        tree hpc-runner

## Task Dependencency Declaration 

Within a job type we can declare dependencies on particular tasks.

### Workflow file

        #blastx.sh
        
        #HPC jobname=unzip
        #TASK tags=Sample1
        unzip Sample1.zip
        #TASK tags=Sample2
        unzip Sample2.zip
        #TASK tags=Sample3
        unzip Sample3.zip

        #HPC jobname=blastx
        #HPC deps=unzip
        #TASK tags=Sample1
        blastx --db env_nr --sample Sample1.fasta
        #TASK tags=Sample2
        blastx --db env_nr --sample Sample2.fasta
        #TASK tags=Sample3
        blastx --db env_nr --sample Sample3.fasta

### Submit to the scheduler

        hpcrunner.pl submit_jobs --infile preprocess.sh

### Look at results!

        tree hpc-runner

## Declare Scheduler Variables

Each scheduler has its own set of variables. HPC::Runner::Command has a set of
generalized variables for declaring types across templates. For more
information please see [Job Scheduler Comparison](https://jerowe.gitbooks.io/hpc-runner-command-docs/content/job_submission/comparison.html) 

Additionally, for workflows with a large number of tasks, please see [Considerations for Workflows with a Large Number of Tasks](https://jerowe.gitbooks.io/hpc-runner-command-docs/content/design_workflow.html#considerations-for-workflows-with-a-large-number-of-tasks) for information on how to group tasks together.

### Workflow file

        #blastx.sh
        
        #HPC jobname=unzip
        #HPC cpus_per_task=1
        #HPC partition=serial
        #HPC commands_per_node=1
        #TASK tags=Sample1
        unzip Sample1.zip
        #TASK tags=Sample2
        unzip Sample2.zip
        #TASK tags=Sample3
        unzip Sample3.zip

        #HPC jobname=blastx
        #HPC cpus_per_task=6
        #HPC deps=unzip
        #TASK tags=Sample1
        blastx --threads 6 --db env_nr --sample Sample1.fasta
        #TASK tags=Sample2
        blastx --threads 6 --db env_nr --sample Sample2.fasta
        #TASK tags=Sample3
        blastx --threads 6 --db env_nr --sample Sample3.fasta

### Submit to the scheduler

        hpcrunner.pl submit_jobs --infile preprocess.sh

### Look at results!

        tree hpc-runner

