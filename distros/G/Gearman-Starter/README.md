# NAME

Gearman::Starter - Gearman workers launcher with register functions

# SYNOPSIS

    use Gearman::Starter;
    my $gearman_starter = Gearman::Starter->new(
        server                 => ['127.0.0.1:7003'],
        max_workers            => 3,
        max_requests_per_child => 10,
        module                 => ['MyWorker::Job'],
        scoreboard_dir         => $scoreboard_dir,         # optional
        port                   => 9999,                    # optional
        Reload                 => ['lib/MyWorker/Job.pm'], # optional
        on_fail                => sub { ... },             # optional
    );
    $gearman_starter->run;

# DESCRIPTION

Gearman::Starter is Gearman worker launcher with register functions from specified modules.

This module is Objective backend of [gearman-starter.pl](http://search.cpan.org/perldoc?gearman-starter.pl).

# CONSTRUCTOR

`new` is constructor method.

The following options are available:

- `server`

    Gearman server

- `max_workders`
- `max_requests_per_child`
- `module`

    Modules with job definitions.

    The functions whose name start with `/^job_/` in the modules are dealt with Gearman functions
    and registered to workers automatically.

- `scoreboard_dir`

    If you want to monitor status of workers, scoreboard is available.

- `port`

    You can monitor status of workers through specified TCP port.
    It is easily available by using Telnet or Netcat, etc.

# LICENSE

Copyright (C) Songmu.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHORS

Tokuhiro Matsuno <tokuhirom@gmail.com>

Masahiro Nagano <kazeburo@gmail.com>

Songmu <y.songmu@gmail.com>
