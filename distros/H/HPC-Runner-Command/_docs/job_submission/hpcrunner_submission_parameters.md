```
hpcrunner.pl submit_jobs --help
```

```
	--afterok             afterok switch in slurm. --afterok 123,134 will
                          tell slurm to start this job after 123,134 have
                          exited successfully [Multiple; Split by ","]
    --autocommit          Run a git add -A on dirty build [Flag]
    --config              Path to command config file
    --cpus_per_task       --cpus-per-task switch in slurm [Default:"4";
                          Integer]
    --custom_command      
    --help -h --usage -?  Prints this usage information. [Flag]
    --hpc_plugins         Load hpc_plugins [Multiple; Split by ","]
    --hpc_plugins_opts    Options for hpc_plugins [Key-Value]
    --infile              File of commands separated by newline. The command
                          'wait' indicates all previous commands should
                          finish before starting the next one. [Required]
    --job_plugins         Load job execution plugins [Multiple; Split by ","]
    --job_plugins_opts    Options for job_plugins [Key-Value]
    --job_scheduler_id    This defaults to your current Job Scheduler ID.
                          Ignore this if running on a single node
    --jobname             Specify a job name, each job will be appended with
                          its batch order [Default:"hpcjob_001"]
    --logdir              Directory where logfiles are written. Defaults to
                          current_working_directory/prunner_current_date_time
                          /log1 .. log2 .. log3'
    --logname             [Default:"hpcrunner_logs"]
    --max_array_size      [Default:"200"; Integer]
    --mem                 Supply a memory limit [Default:"10GB"]
    --metastr             Meta str passed from HPC::Runner::Scheduler
    --module              List of modules to load ex. R2, samtools, etc [
                          Multiple; Split by ","]
    --no_submit_to_slurm  Bool value whether or not to submit to slurm. If
                          you are looking to debug your files, or this script
                          you will want to set this to zero. [Flag]
    --nodes_count         Number of nodes requested. You should only use this
                          if submitting parallel jobs. [Default:"1"; Integer
                          ]
    --ntasks              --ntasks switch in slurm. This is equal to the
                          number of concurrent tasks on each node * the
                          number of nodes, not the total number of tasks [
                          Default:"1"; Integer]
    --ntasks_per_node     --ntasks-per-node switch in slurm. total concurrent
                          tasks on a node. [Default:"1"; Integer]
    --outdir              Directory to write out files.
    --partition           Slurm partition to submit jobs to. Defaults to the
                          partition with the most available nodes
    --plugins             Load aplication plugins [Multiple; Split by ","]
    --plugins_opts        Options for application plugins [Key-Value]
    --process_table       
    --procs               Total number of concurrently running jobs allowed
                          at any time. [Default:"1"; Integer]
    --serial              Use this if you wish to run each job run one after
                          another, with each job starting only after the
                          previous has completed successfully [Flag]
    --show_processid      Show the process ID per logging message. This is
                          useful when aggregating logs. [Flag]
    --tags                Tags for the whole submission [Multiple; Split by "
                          ,"]
    --use_batches         Switch to use batches. The default is to use job
                          arrays. Warning! This was the default way of
                          submitting before 3.0, but is not well supported. [
                          Flag]
    --user                This defaults to your current user ID. This can
                          only be changed if running as an admin user
    --version             Submission version. Each version has a
                          corresponding git tag. See the difference between
                          tags with `git diff tag1 tag2`. Tags are always
                          version numbers, starting with 0.01.
    --walltime            [Default:"00:20:00"]
```
