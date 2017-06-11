[![Build Status](https://travis-ci.org/adokoy001/MapReduce-Framework-Simple.svg?branch=master)](https://travis-ci.org/adokoy001/MapReduce-Framework-Simple)
# NAME

MapReduce::Framework::Simple - Simple Framework for MapReduce

# SYNOPSIS

    ## After install this module, you can start MapReduce worker server by this command.
    ## $ perl -MMapReduce::Framework::Simple -e 'MapReduce::Framework::Simple->new->worker("/eval");'
    use MapReduce::Framework::Simple;
    use Data::Dumper;

    my $mfs = MapReduce::Framework::Simple->new;

    ## Generate data for MapReduce manually.
    my $data_map_reduce;
    for(0 .. 2){
        my $tmp_data;
        for(0 .. 10000){
            push(@$tmp_data,rand(10000));
        }
        # Records should be [[<data>,<worker url>],...]
        push(@$data_map_reduce,[$tmp_data,'http://localhost:5000/eval']);
        # If you want to use standalone, Record should be [<data>] as below
        # push(@$data_map_reduce,$tmp_data);
    }


    ## OR, Generate good balanced data for MapReduce automatically.
    my $remote_servers = [
        'http://remote1.local:5000/eval_secret_url',
        'http://remote2.local:5000/eval_secret_url',
        'http://remote3.local:5000/eval_secret_url'
       ];
    my $tmp_data_2;
    for(0 .. 100000){
        push(@$tmp_data_2,rand(10000));
    }
    my $data_auto_assign = $mfs->create_assigned_data(
        $tmp_data_2,
        $remote_servers,
        { chunk_num => 10, method => 'volume_uniform' }
       );

    # mapper code
    my $mapper = sub {
        my $input = shift;
        my $sum = 0;
        my $num = $#$input + 1;
        for(0 .. $#$input){
            $sum += $input->[$_];
        }
        my $avg = $sum / $num;
        return({avg => $avg, sum => $sum, num => $num});
    };

    # reducer code
    my $reducer = sub {
        my $input = shift;
        my $sum = 0;
        my $avg = 0;
        my $total_num = 0;
        for(0 .. $#$input){
            $sum += $input->[$_]->{sum};
            $total_num += $input->[$_]->{num};
        }
        $avg = $sum / $total_num;
        return({avg => $avg, sum => $sum});
    };

    my $result = $mfs->map_reduce(
        $data_map_reduce,
        $mapper,
        $reducer,
        5
       );

    # Stand alone
    # my $result = $mfs->map_reduce(
    #     $data_map_reduce,
    #     $mapper,
    #     $reducer,
    #     5,
    #     {remote => 0}
    #    );

    print Dumper $result;

# DESCRIPTION

MapReduce::Framework::Simple is simple grid computing framework for MapReduce model.
MapReduce is a better programming model for solving highly parallelizable problems like a word-count from large number of documents.

The model requires Map procedure that processes given data with given sub-routine(code reference) parallelly and Reduce procedure that summarizes outputs from Map sub-routine.

This module provides worker server that just computes perl-code and data sent from remote client.
You can start MapReduce worker server by one liner Perl.

# METHODS

## _new_

_new_ creates object.

    my $mfs->MapReduce::Framework::Simple->new(
        verify_hostname => 1, # verify public key fingerprint.
        skip_undef_result => 1, # skip undefined value at reduce step.
        warn_discarded_data => 1, # warn if discarded data exist due to some connection problems.
        die_discarded_data => 0 # die if discarded data exist.
        worker_log => 0 # print worker log when remote client accesses.
        force_plackup => 0 # force to use plackup when starting worker server.
        );

## _create\_assigned\_data_

This method creates MapReduce ready data from data and remote worker server list.
You can set the number of data chunk and balancing method ('volume\_uniform','element\_shuffle','element\_sequential').

    my $tmp_data = [1 .. 1_000_000];
    my $server_list = [
        'http://s1.local:5000/eval',
        'http://s2.local:5000/eval',
        'http://s3.local:5000/eval',
       ];

    my $data = $mfs->create_assigned_data(
        $tmp_data,
        $server_list,
        {
            chunk_num => 10, # number of data chunk.
            method => 'volume_uniform', # balancing method.
           }
       );

## _map\_reduce_

_map\_reduce_ method starts MapReduce processing using Parallel::ForkManager.

    my $result = $mfs->map_reduce(
        $data_map_reduce, # data
        $mapper, # code ref of mapper
        $reducer, # code ref of reducer
        5, # number of fork process
        {remote => 1} # grid computing flag.
       );

## _worker_

_worker_ method starts MapReduce worker server using Starlet HTTP server over Plack when Starlet and Plack::Handler::Starlet is installed (or not, startup by single process plack server).
If you need to startup worker as plackup on the environment that has Starlet installed, please set force\_plackup => 1 when _new_.

Warning: Worker server do eval remote code. Please use this server at secure network.

    $mfs->worker(
        "/yoursecret_eval_path", # path
        4, # number of preforked Starlet worker
        5000 # port number
        );

## _load\_worker\_plack\_app_

If you want to use other HTTP server, you can extract Plack app by _load\_worker\_plack\_app_ method.

    use Plack::Loader;
    my $app = $mfs->load_worker_plack_app("/yoursecret_eval_path");
    my $handler = Plack::Loader->load(
           'YOURFAVORITESERVER',
           ANY => 'FOO'
           );
    $handler->run($app);

# EFFECTIVENESS

Sometimes we regret things we design the programs and routines that process small data.

Please check the current design when you convert to MapReduce model.

## Is this procedure parallelizable?

The problem that you want to solve should be highly-parallelizable if you convert to MapReduce model.

## Are there data size predictable?

If these data size assined to workers are not predictable, acceleration of computing by converting to MapReduce model can not be expected because each workers has unevenness amount of tasks and actual processing time.

## Is overhead relatively small?

Please read some documents related to "Amdahl's law" and "embarrassingly parallel".

# LICENSE

Copyright (C) Toshiaki Yokoda.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Toshiaki Yokoda <adokoy001@gmail.com>
