[![Build Status](https://travis-ci.org/adokoy001/MapReduce-Framework-Simple.svg?branch=master)](https://travis-ci.org/adokoy001/MapReduce-Framework-Simple)
# NAME

MapReduce::Framework::Simple - Simple Framework for MapReduce

# SYNOPSIS

    ## After install this module, you can start MapReduce worker server by this command.
    ## $ perl -MMapReduce::Framework::Simple -e 'MapReduce::Framework::Simple->new->worker("/eval");'
    ## Prefork HTTP server module "Starlet" is highly recommended for practical uses.

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
Pre-fork HTTP server module "Starlet" will be loaded automatically if it is installed. Starlet installed environment is highly recommended for practical uses.

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
        server_spec => {cores => 4, clock => 2400} # since v0.08, you can give the machine spec.
        );

## _create\_assigned\_data_

This method creates MapReduce ready data from data and remote worker server list.
You can set the number of data chunk and balancing method ('volume\_uniform','element\_shuffle','element\_sequential').

Note: Version >= 0.08, new available method 'element\_server\_cores','element\_server\_workers','element\_server\_core\_clock'

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

### Assign method options

The explanation of assign method below.

#### _volume\_uniform_ (default)

This option balances by data size. Default option.

#### _element\_shuffle_

This option assigns data to workers by random.

#### _element\_sequential_

This option assigns data to workers sequentially.

#### _element\_server\_cores_, _element\_server\_workers_, _element\_server\_core\_clock_

These options are available over v0.08.

It requires worker side preparation to notice server specification for client like below.

    $ perl -MMapReduce::Framework::Simple -e 'MapReduce::Framework::Simple->new(server_spec => {cores => 4, clock => 2400})->worker("/eval",10,5000)'

Please give correct server specification in new(server\_spec => {}) when you use 'element\_server\_cores' or 'element\_server\_core\_clock'.
Then you can distribute the data by computing power of workers.

## _map\_reduce_

_map\_reduce_ method starts MapReduce processing using Parallel::ForkManager.

    my $result = $mfs->map_reduce(
        $data_map_reduce, # data
        $mapper, # code ref of mapper
        $reducer, # code ref of reducer
        5, # number of fork process
        {
          remote => 1,  # grid computing flag.
          storable => 1 # since v0.09, this option enables to insert any objects and code ref by using Storable module.
         }
       );

## _worker_

_worker_ method starts MapReduce worker server using Starlet HTTP server over Plack when Starlet is installed (or not, startup by single process plack server. It is not for practical uses).
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

Example one liner deploy code below (with Starlight the pure Perl pre-fork HTTP server).

    $ perl -MMapReduce::Framework::Simple -MPlack::Loader -e 'Plack::Loader->load("Starlight", port => 12345)->run(MapReduce::Framework::Simple->new->load_worker_plack_app("/eval_secret"))'

# OBJECT AND CODEREF IN DATA

Since v0.09, you can enable to insert CODE references and almost all of objects to data by setting storable option to 1 in map\_reduce method.

    ...

    my $data_tmp = [
        [[1,2,3],$obj,sub { return "hello" }],
        [[4,5,6],$obj2,sub { return "world" }],
        ...
        ];

    ...

    my $result = $mfs->map_reduce(
        $data,
        $mapper,
        $reducer,
        5,
        {storable => 1}
    );

You should use other than 'volume\_uniform' method in create\_assigned\_data.

Here is an complete example.

    # Preparation of worker side:
    # $ perl -MMapReduce::Framework::Simple -MPDL -e 'MapReduce::Framework::Simple->new->worker('/secret_eval')'

    use strict;
    use warnings;
    use MapReduce::Framework::Simple;
    use PDL;

    my $mfs = MapReduce::Framework::Simple->new();
    my $server_list = [
        'http://w1.example.com:5000/secret_eval',
        'http://w2.example.com:5000/secret_eval'
    ];

    # creating many PDL objects.
    my $data_tmp;
    for(0 .. 100){
        my $tmp_mat;
        for(1 .. 20){
            my $tmp_vec;
            for(1 .. 20){
                push(@$tmp_vec,rand(100));
            }
            push(@$tmp_mat,$tmp_vec);
        }
        push(@$data_tmp, pdl $tmp_mat);
    }

    my $data = $mfs->create_assigned_data(
        $data_tmp,
        $server_list,
        {
            chunk_num => 10,
            method => 'element_sequential' # SHOULD BE SET. SHOULD NOT BE 'volume_uniform'
           }
       );

    # mapper code
    my $mapper = sub {
        my $input = shift;
        my $output;
        for(0 .. $#$input){
            my $pdl = $input->[$_];
            my $inv = $pdl->inv;
            push(@$output,$inv);
        }
        return($output);
    };

    # reducer code
    my $reducer = sub {
        my $input = shift;
        return($input);
    };

    my $result = $mfs->map_reduce(
        $data,
        $mapper,
        $reducer,
        10,
        {storable => 1} # SHOULD BE SET storable => 1
       );


    for(0 .. $#$result){
        my $tmp_result = $result->[$_];
        foreach my $pdl (@$tmp_result){
            print $pdl;
        }
    }

# PERFORMANCE

This methodology is suitable for Highly-Parallelizable problems.

## Example: Summation of prime numbers

Normally, we calculate the summation of prime numbers in 1,000,000,001 to 1,000,300,000 like below.

    use strict;
    use warnings;

    my $num_list = [1_000_000_001 .. 1_000_300_000];
    my $sum=0;
    for(@$num_list){
        my $flag = 0;
        for( my $k=2; $k <= int(sqrt($_)); $k++){
            if(($_ % $k) == 0){
                $flag = 1;
                last;
            }
        }
        if($flag == 0){
            $sum += $_;
        }
    }

    print "$sum\n";

I guess this problem will be solved around 1 minute after execute this program.

Here is parallel processing version of this program by using this module. It might be solved in 10 seconds.

    use strict;
    use warnings;
    use MapReduce::Framework::Simple;

    my $mfs = MapReduce::Framework::Simple->new(
        skip_undef_result => 0,
        warn_discarded_data => 1
       );

    my $server_list = [
        'http://remote1.example.com:5000/eval', # 20 cores over remote server.
        'http://remote2.example.com:5000/eval', # 20 cores over remote server.
       ];

    my $data_tmp;

    my $parallel_num = 10;
    for (1_000_000_001 .. 1_000_300_000){
        push(@$data_tmp,$_);
    }

    my $data = $mfs->create_assigned_data(
        $data_tmp,
        $server_list,
        {
            chunk_num => 40,
            method => 'element_shuffle'
           }
       );

    # mapper code
    my $mapper = sub {
        my $input = shift;
        my $sum=0;
        for(0 .. $#$input){
            my $flag = 0;
            for( my $k=2; $k <= int(sqrt($input->[$_])); $k++){
                if(($input->[$_] % $k) == 0){
                    $flag = 1;
                    last;
                }
            }
            if($flag == 0){
                $sum += $input->[$_];
            }
        }
        return($sum);
    };

    # reducer code
    my $reducer = sub {
        my $input = shift;
        my $sum=0;
        foreach my $tmp_input (@$input){
            $sum += $tmp_input;
        }
        return($sum);
    };

    my $result = $mfs->map_reduce(
        $data,
        $mapper,
        $reducer,
        $parallel_num,
        {remote => 1}
       );

    print "$result\n";

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
