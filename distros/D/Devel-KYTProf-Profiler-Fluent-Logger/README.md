# NAME

Devel::KYTProf::Profiler::Fluent::Logger - KYTProf profiler for Fluent::Logger

# SYNOPSIS

    use Devel::KYTProf;
    Devel::KYTProf->apply_prof('Fluent::Logger');
    
    my $logger = Fluent::Logger->new;
    $logger->post("foo" => { bar => "baz" });

KYTProf will output profiles as below.

    1.718 ms  [Fluent::Logger]  _connect host:127.0.0.1 port:24224  | Class::Tiny::Object:139
    0.281 ms  [Fluent::Logger]  _post tag:foo size:20 time:1557152411.095216  | main:5
    0.089 ms  [Fluent::Logger]  close host:127.0.0.1 port:24224  | Class::Tiny::Object:154

By default, a caller package of \_connect and close is "Class::Tiny::Object" because of those methods called from Fluent::Logger internal.

When you want to ignore it and detect the actual caller, set Devel::KYTProf->ignore\_class\_regex and namespace\_regex. For example,

    Devel::KYTProf->ignore_class_regex('Class::Tiny::Object');
    Devel::KYTProf->namespace_regex('.');

Profiles become showed with the true caller.

    1.142 ms  [Fluent::Logger]  _connect host:127.0.0.1 port:24224  | main:6
    0.247 ms  [Fluent::Logger]  _post tag:foo size:20 time:1557153523.967838  | main:7
    0.038 ms  [Fluent::Logger]  close host:127.0.0.1 port:24224  | main:0

# DESCRIPTION

Devel::KYTProf::Profiler::Fluent::Logger is KYTProf profiler add on for Fluent::Logger.

# LICENSE

Copyright (C) FUJIWARA Shunichiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

FUJIWARA Shunichiro <fujiwara.shunichiro@gmail.com>
