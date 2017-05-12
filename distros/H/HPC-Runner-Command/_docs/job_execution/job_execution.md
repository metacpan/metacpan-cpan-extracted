# Job Execution

Each time a job is executed a threadpool is created, with the maximum number of
tasks running concurrently at any time being equal to the number of procs given
(supplied by #HPC procs=N).

Each task is run in isolation in its own thead to keep it from interfering with
other tasks. In this way if one task fails the entire job does not necessarily
fail. Each task has its stdout, stderr, exit code, and duration logged, along
with any task tags.
