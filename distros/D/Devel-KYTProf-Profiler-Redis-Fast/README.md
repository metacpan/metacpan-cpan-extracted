# NAME

Devel::KYTProf::Profiler::Redis::Fast - KYTProf profiler for Redis::Fast

# SYNOPSIS

    use Devel::KYTProf;
    Devel::KYTProf->apply_prof('Redis::Fast');
    
    my $redis = Redis::Fast->new(server => 'localhost:6379');
    $redis->set('foo' => 'bar');
    $redis->mget('foo', 'bar');
    $redis->info;
    $redis->keys("*");

KYTProf will output profiles as below.

    0.114 ms  [Redis::Fast]  SET foo  | main:5
    0.080 ms  [Redis::Fast]  MGET foo bar  | main:6
    0.155 ms  [Redis::Fast]  info   | main:7
    0.079 ms  [Redis::Fast]  keys *  | main:8

# DESCRIPTION

Devel::KYTProf::Profiler::Redis::Fast is KYTProf profiler for Redis::Fast.

# LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>
