<div>
    <a href="https://travis-ci.org/yoheimuta/Linux-GetPidstat"><img src="https://travis-ci.org/yoheimuta/Linux-GetPidstat.svg?branch=master"></a>
</div>

# NAME

Linux::GetPidstat - Monitor each process metrics avg using each pidfile

# SYNOPSIS

    use Linux::GetPidstat;

    my $stat = Linux::GetPidstat->new;
    $stat->run(%opt);

# DESCRIPTION

Run `pidstat -h -u -r -s -d -w -p $pid $interval $count` commands in parallel to monitor each process metrics avg/1min.

Output to a specified file \[and|or\] `mackerel service` https://mackerel.io.

## Motivation

A batch server runs many batch scripts at the same time.

When this server suffers by a resource short, it's difficult to grasp which processes are heavy quickly.

Running pidstat manually is not appropriate in this situation, because

- the target processes are changed by starting each job.
- the target processes may run child processes recursively.

## Requirements

pidstat
pstree

## Usage

Prepare pid files in a specified directory.

    $ mkdir /tmp/pid_dir
    $ echo 1234 > /tmp/pid_dir/target_script
    $ echo 1235 > /tmp/pid_dir/target_script2
    # In production, this file is made and removed by the batch script itself for instance.

Run the script every 1 mininute.

    # vi /etc/cron.d/linux-get-pidstat
    * * * * * user carton exec -- linux-get-pidstat --no-dry_run --pid_dir=/tmp/pid_dir --res_dir=/tmp/bstat.log

Done, you can monitor the result.

    $ tail -f /tmp/bstat.log
    # start(datetime),start(epoch),pidfilename,name,value
    2016-04-02T19:49:32,1459594172,target_script,cswch_per_sec,19.87
    2016-04-02T19:49:32,1459594172,target_script,stk_ref,25500
    2016-04-02T19:49:32,1459594172,target_script,memory_percent,34.63
    2016-04-02T19:49:32,1459594172,target_script,memory_rss,10881534000
    2016-04-02T19:49:32,1459594172,target_script,stk_size,128500
    2016-04-02T19:49:32,1459594172,target_script,nvcswch_per_sec,30.45
    2016-04-02T19:49:32,1459594172,target_script,cpu,21.2
    2016-04-02T19:49:32,1459594172,target_script,disk_write_per_sec,0
    2016-04-02T19:49:32,1459594172,target_script,disk_read_per_sec,0
    2016-04-02T19:49:32,1459594172,target_script2,memory_rss,65289204000
    2016-04-02T19:49:32,1459594172,target_script2,memory_percent,207.78
    2016-04-02T19:49:32,1459594172,target_script2,stk_ref,153000
    2016-04-02T19:49:32,1459594172,target_script2,cswch_per_sec,119.22
    2016-04-02T19:49:32,1459594172,target_script2,nvcswch_per_sec,182.7
    2016-04-02T19:49:32,1459594172,target_script2,cpu,127.2
    2016-04-02T19:49:32,1459594172,target_script2,disk_read_per_sec,0
    2016-04-02T19:49:32,1459594172,target_script2,disk_write_per_sec,0
    2016-04-02T19:49:32,1459594172,target_script2,stk_size,771000

### Mackerel

Post the results to service metrics.

    $ carton exec -- linux-get-pidstat \
    --no-dry_run \
    --pid_dir=/tmp/pid_dir \
    --mackerel_api_key=yourkey \
    --mackerel_service_name=yourservice

### Help

Display how to use.

    $ carton exec -- linux-get-pidstat --help
    Usage:
            linux-get-pidstat - command description
              Usage: command [options]
              Options:
                --pid_dir                     A directory path for pid files
                --res_file                    A file path to be stored results
                --interval                    Interval second to be given as a pidstat argument (default:1)
                --count                       Count number to be given as a pidstat argument (default:60)
                --dry_run                     Dry run mode. not run the side-effects operation (default:1) (--no-dry_run is also supported)
                --datetime                    Datetime (ex. '2016-06-10 00:00:00') to be recorded
                --include_child               Flag to be enabled to include child process metrics (default:1) (--no-include_child is also suppoted)
                --max_child_limit             Number to be used for limiting pidstat multi processes (default:30) (skip this limit if 0 is specified)
                --mackerel_metric_type        Metric type of mackerel (default:service) (only use one of 'service' or 'host')
                --mackerel_api_key            An api key to be used for posting to mackerel
                --mackerel_service_name       An mackerel service name
                --mackerel_metric_key_prefix  Key prefix of mackerel metric name (default:batch_)
                --mackerel_host_id            An mackerel host id
              Requirement Programs: pidstat and pstree commands

# LICENSE

Copyright (C) yoheimuta.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

yoheimuta <yoheimuta@gmail.com>
